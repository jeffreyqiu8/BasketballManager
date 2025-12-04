import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/rotation_config.dart';
import 'package:BasketballManager/models/depth_chart_entry.dart';
import 'package:BasketballManager/services/rotation_service.dart';
import 'package:BasketballManager/services/league_service.dart';

/// Tests for data persistence and compatibility (Task 5)
/// 
/// Validates:
/// - LineupPage saves to RotationConfig correctly
/// - MinutesEditorDialog saves to RotationConfig correctly
/// - Team.startingLineupIds derivation from depth chart
/// - Loading existing rotation configs in new UI
/// - Game simulation compatibility with new UI
/// 
/// Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
void main() {
  group('Data Persistence and Compatibility Tests', () {
    late List<Player> testPlayers;
    late Team testTeam;
    late LeagueService leagueService;

    setUp(() {
      // Create 15 test players
      testPlayers = List.generate(15, (index) {
        return Player(
          id: 'player_$index',
          name: 'Player $index',
          position: ['PG', 'SG', 'SF', 'PF', 'C'][index % 5],
          heightInches: 75 + index,
          shooting: 70,
          defense: 70,
          speed: 70,
          postShooting: 70,
          passing: 70,
          rebounding: 70,
          ballHandling: 70,
          threePoint: 70,
          blocks: 70,
          steals: 70,
        );
      });

      // Create test team with default rotation
      final defaultRotation = RotationService.generateDefaultRotation(testPlayers);
      final startingLineupIds = defaultRotation.depthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toList();

      testTeam = Team(
        id: 'test_team',
        name: 'Test Team',
        city: 'Test City',
        players: testPlayers,
        startingLineupIds: startingLineupIds,
        rotationConfig: defaultRotation,
      );

      leagueService = LeagueService();
    });

    test('Requirement 11.1: Loading existing rotation config displays correctly', () {
      // Given: A team with an existing rotation config
      expect(testTeam.rotationConfig, isNotNull);
      expect(testTeam.rotationConfig!.rotationSize, equals(8));
      expect(testTeam.rotationConfig!.depthChart.length, greaterThan(0));
      expect(testTeam.rotationConfig!.playerMinutes.length, equals(8));

      // When: We load the config (simulating UI load)
      final loadedConfig = testTeam.rotationConfig!;

      // Then: All data should be present and valid
      expect(loadedConfig.rotationSize, equals(8));
      expect(loadedConfig.depthChart.length, greaterThan(0));
      expect(loadedConfig.playerMinutes.length, equals(8));
      
      // Verify each position has a starter
      for (final position in ['PG', 'SG', 'SF', 'PF', 'C']) {
        final hasStarter = loadedConfig.depthChart.any(
          (entry) => entry.position == position && entry.depth == 1,
        );
        expect(hasStarter, isTrue, reason: 'Position $position should have a starter');
      }

      // Verify minutes sum to 240 (48 per position * 5 positions)
      final totalMinutes = loadedConfig.playerMinutes.values.fold<int>(
        0,
        (sum, minutes) => sum + minutes,
      );
      expect(totalMinutes, equals(240));
    });

    test('Requirement 11.2: Saving from LineupPage preserves rotation format', () {
      // Given: A team with existing rotation
      final originalConfig = testTeam.rotationConfig!;

      // When: We simulate LineupPage save by modifying depth chart
      final newDepthChart = List<DepthChartEntry>.from(originalConfig.depthChart);
      
      // Swap two players in the depth chart (simulate reordering)
      final pgEntries = newDepthChart
          .where((entry) => entry.position == 'PG')
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));
      
      if (pgEntries.length >= 2) {
        final firstIndex = newDepthChart.indexWhere(
          (e) => e.playerId == pgEntries[0].playerId && e.position == 'PG',
        );
        final secondIndex = newDepthChart.indexWhere(
          (e) => e.playerId == pgEntries[1].playerId && e.position == 'PG',
        );
        
        newDepthChart[firstIndex] = DepthChartEntry(
          playerId: pgEntries[0].playerId,
          position: 'PG',
          depth: 2,
        );
        newDepthChart[secondIndex] = DepthChartEntry(
          playerId: pgEntries[1].playerId,
          position: 'PG',
          depth: 1,
        );
      }

      final newConfig = RotationConfig(
        rotationSize: originalConfig.rotationSize,
        playerMinutes: originalConfig.playerMinutes,
        depthChart: newDepthChart,
        lastModified: DateTime.now(),
      );

      // Update starting lineup IDs from depth chart
      final newStartingLineupIds = newDepthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toList();

      final updatedTeam = testTeam.copyWith(
        rotationConfig: newConfig,
        startingLineupIds: newStartingLineupIds,
      );

      // Then: The saved data should be in correct format
      expect(updatedTeam.rotationConfig, isNotNull);
      expect(updatedTeam.rotationConfig!.rotationSize, equals(originalConfig.rotationSize));
      expect(updatedTeam.rotationConfig!.playerMinutes, equals(originalConfig.playerMinutes));
      expect(updatedTeam.rotationConfig!.depthChart.length, equals(newDepthChart.length));
      
      // Verify starting lineup IDs match depth chart starters
      expect(updatedTeam.startingLineupIds.length, equals(5));
      for (final starterId in updatedTeam.startingLineupIds) {
        final isStarter = updatedTeam.rotationConfig!.depthChart.any(
          (entry) => entry.playerId == starterId && entry.depth == 1,
        );
        expect(isStarter, isTrue, reason: 'Starter $starterId should have depth 1');
      }
    });

    test('Requirement 11.2: Saving from MinutesEditorDialog preserves rotation format', () {
      // Given: A team with existing rotation
      final originalConfig = testTeam.rotationConfig!;

      // When: We simulate MinutesEditorDialog save by modifying minutes
      final newPlayerMinutes = Map<String, int>.from(originalConfig.playerMinutes);
      
      // Adjust minutes for one player (keeping total at 240)
      final firstPlayerId = newPlayerMinutes.keys.first;
      final originalMinutes = newPlayerMinutes[firstPlayerId]!;
      newPlayerMinutes[firstPlayerId] = originalMinutes + 2;
      
      // Compensate by reducing another player's minutes
      final secondPlayerId = newPlayerMinutes.keys.skip(1).first;
      newPlayerMinutes[secondPlayerId] = newPlayerMinutes[secondPlayerId]! - 2;

      final newConfig = RotationConfig(
        rotationSize: originalConfig.rotationSize,
        playerMinutes: newPlayerMinutes,
        depthChart: originalConfig.depthChart, // Depth chart unchanged
        lastModified: DateTime.now(),
      );

      final updatedTeam = testTeam.copyWith(
        rotationConfig: newConfig,
      );

      // Then: The saved data should be in correct format
      expect(updatedTeam.rotationConfig, isNotNull);
      expect(updatedTeam.rotationConfig!.rotationSize, equals(originalConfig.rotationSize));
      expect(updatedTeam.rotationConfig!.depthChart, equals(originalConfig.depthChart));
      expect(updatedTeam.rotationConfig!.playerMinutes.length, equals(newPlayerMinutes.length));
      
      // Verify minutes were updated correctly
      expect(
        updatedTeam.rotationConfig!.playerMinutes[firstPlayerId],
        equals(originalMinutes + 2),
      );
      expect(
        updatedTeam.rotationConfig!.playerMinutes[secondPlayerId],
        equals(originalConfig.playerMinutes[secondPlayerId]! - 2),
      );
    });

    test('Requirement 11.3: Team.startingLineupIds derived from depth chart', () {
      // Given: A team with rotation config
      expect(testTeam.rotationConfig, isNotNull);

      // When: We get the starting lineup
      final startingLineup = testTeam.startingLineup;

      // Then: Starting lineup should match depth chart starters (depth = 1)
      expect(startingLineup.length, equals(5));
      
      final starterIdsFromDepthChart = testTeam.rotationConfig!.depthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toSet();

      final startingLineupPlayerIds = startingLineup.map((p) => p.id).toSet();
      
      expect(startingLineupPlayerIds, equals(starterIdsFromDepthChart));
    });

    test('Requirement 11.4: Rotation config serialization round-trip', () {
      // Given: A rotation config
      final originalConfig = testTeam.rotationConfig!;

      // When: We serialize and deserialize it
      final json = originalConfig.toJson();
      final deserializedConfig = RotationConfig.fromJson(json);

      // Then: All data should be preserved
      expect(deserializedConfig.rotationSize, equals(originalConfig.rotationSize));
      expect(deserializedConfig.playerMinutes, equals(originalConfig.playerMinutes));
      expect(deserializedConfig.depthChart.length, equals(originalConfig.depthChart.length));
      
      for (int i = 0; i < originalConfig.depthChart.length; i++) {
        expect(
          deserializedConfig.depthChart[i].playerId,
          equals(originalConfig.depthChart[i].playerId),
        );
        expect(
          deserializedConfig.depthChart[i].position,
          equals(originalConfig.depthChart[i].position),
        );
        expect(
          deserializedConfig.depthChart[i].depth,
          equals(originalConfig.depthChart[i].depth),
        );
      }
    });

    test('Requirement 11.5: Team serialization preserves rotation config', () {
      // Given: A team with rotation config
      expect(testTeam.rotationConfig, isNotNull);

      // When: We serialize and deserialize the team
      final json = testTeam.toJson();
      final deserializedTeam = Team.fromJson(json);

      // Then: Rotation config should be preserved
      expect(deserializedTeam.rotationConfig, isNotNull);
      expect(
        deserializedTeam.rotationConfig!.rotationSize,
        equals(testTeam.rotationConfig!.rotationSize),
      );
      expect(
        deserializedTeam.rotationConfig!.playerMinutes,
        equals(testTeam.rotationConfig!.playerMinutes),
      );
      expect(
        deserializedTeam.rotationConfig!.depthChart.length,
        equals(testTeam.rotationConfig!.depthChart.length),
      );
    });

    test('Requirement 11.5: Game simulation can use rotation config from new UI', () {
      // Given: A team with rotation config saved from new UI
      final config = testTeam.rotationConfig!;

      // When: Game simulation accesses the config
      // Simulate what possession_simulation.dart does
      final activePlayerIds = config.getActivePlayerIds();
      final rotationPlayers = testTeam.players
          .where((player) => activePlayerIds.contains(player.id))
          .toList();

      // Get starters from depth chart
      final starterIds = config.depthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toSet();
      final starters = testTeam.players
          .where((player) => starterIds.contains(player.id))
          .toList();

      // Then: Game simulation should work correctly
      expect(rotationPlayers.length, equals(config.rotationSize));
      expect(starters.length, equals(5));
      
      // Verify each position has a starter
      final starterPositions = starters.map((p) => p.position).toSet();
      expect(starterPositions.length, equals(5), 
        reason: 'Should have one starter per position');
      
      // Verify all rotation players have minutes allocated
      for (final player in rotationPlayers) {
        expect(config.playerMinutes.containsKey(player.id), isTrue);
        expect(config.playerMinutes[player.id]! > 0, isTrue);
      }
    });

    test('Requirement 11.1: Loading rotation config with missing data handles gracefully', () {
      // Given: A team without rotation config
      final teamWithoutRotation = Team(
        id: 'test_team_2',
        name: 'Test Team 2',
        city: 'Test City 2',
        players: testPlayers,
        startingLineupIds: testPlayers.take(5).map((p) => p.id).toList(),
        rotationConfig: null,
      );

      // When: We check for rotation config
      // Then: It should handle null gracefully
      expect(teamWithoutRotation.rotationConfig, isNull);
      expect(teamWithoutRotation.startingLineup.length, equals(5));
      
      // UI should be able to generate default rotation
      final defaultRotation = RotationService.generateDefaultRotation(
        teamWithoutRotation.players,
      );
      expect(defaultRotation.rotationSize, equals(8));
      expect(defaultRotation.isValid(), isTrue);
    });

    test('Requirement 11.3: Starting lineup IDs update when depth chart changes', () {
      // Given: A team with rotation config
      final originalStarters = testTeam.startingLineupIds;

      // When: We change the depth chart (promote a bench player)
      final newDepthChart = List<DepthChartEntry>.from(
        testTeam.rotationConfig!.depthChart,
      );
      
      // Find a bench player at PG position
      final pgEntries = newDepthChart
          .where((entry) => entry.position == 'PG')
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));
      
      if (pgEntries.length >= 2) {
        // Swap starter and first bench player
        final starterIndex = newDepthChart.indexWhere(
          (e) => e.playerId == pgEntries[0].playerId && e.position == 'PG',
        );
        final benchIndex = newDepthChart.indexWhere(
          (e) => e.playerId == pgEntries[1].playerId && e.position == 'PG',
        );
        
        newDepthChart[starterIndex] = DepthChartEntry(
          playerId: pgEntries[0].playerId,
          position: 'PG',
          depth: 2,
        );
        newDepthChart[benchIndex] = DepthChartEntry(
          playerId: pgEntries[1].playerId,
          position: 'PG',
          depth: 1,
        );

        final newConfig = RotationConfig(
          rotationSize: testTeam.rotationConfig!.rotationSize,
          playerMinutes: testTeam.rotationConfig!.playerMinutes,
          depthChart: newDepthChart,
          lastModified: DateTime.now(),
        );

        // Derive new starting lineup IDs
        final newStartingLineupIds = newDepthChart
            .where((entry) => entry.depth == 1)
            .map((entry) => entry.playerId)
            .toList();

        final updatedTeam = testTeam.copyWith(
          rotationConfig: newConfig,
          startingLineupIds: newStartingLineupIds,
        );

        // Then: Starting lineup IDs should be updated
        expect(updatedTeam.startingLineupIds, isNot(equals(originalStarters)));
        expect(updatedTeam.startingLineupIds.length, equals(5));
        expect(updatedTeam.startingLineupIds.contains(pgEntries[1].playerId), isTrue);
        expect(updatedTeam.startingLineupIds.contains(pgEntries[0].playerId), isFalse);
      }
    });

    test('Requirement 11.4: LeagueService.updateTeam persists changes', () async {
      // Given: A league service and a team
      await leagueService.initializeLeague();
      final teams = leagueService.getAllTeams();
      final teamToUpdate = teams.first;
      final originalConfig = teamToUpdate.rotationConfig!;

      // When: We update the team's rotation config
      final newPlayerMinutes = Map<String, int>.from(originalConfig.playerMinutes);
      final firstPlayerId = newPlayerMinutes.keys.first;
      newPlayerMinutes[firstPlayerId] = newPlayerMinutes[firstPlayerId]! + 5;
      final secondPlayerId = newPlayerMinutes.keys.skip(1).first;
      newPlayerMinutes[secondPlayerId] = newPlayerMinutes[secondPlayerId]! - 5;

      final newConfig = RotationConfig(
        rotationSize: originalConfig.rotationSize,
        playerMinutes: newPlayerMinutes,
        depthChart: originalConfig.depthChart,
        lastModified: DateTime.now(),
      );

      final updatedTeam = teamToUpdate.copyWith(rotationConfig: newConfig);
      await leagueService.updateTeam(updatedTeam);

      // Then: The changes should be persisted
      final retrievedTeam = leagueService.getTeam(teamToUpdate.id);
      expect(retrievedTeam, isNotNull);
      expect(retrievedTeam!.rotationConfig, isNotNull);
      expect(
        retrievedTeam.rotationConfig!.playerMinutes[firstPlayerId],
        equals(originalConfig.playerMinutes[firstPlayerId]! + 5),
      );
      expect(
        retrievedTeam.rotationConfig!.playerMinutes[secondPlayerId],
        equals(originalConfig.playerMinutes[secondPlayerId]! - 5),
      );
    });
  });
}
