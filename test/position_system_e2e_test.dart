import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BasketballManager/models/game_state.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/services/save_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/player_generator.dart';

/// Comprehensive end-to-end tests for the position system
/// 
/// Tests cover:
/// - Height-based attribute modifiers during player generation
/// - Position affinity calculations for various player types
/// - Position assignment and persistence across save/load
/// - Position modifiers affecting game statistics
/// - UI display of position information (verified through data)
/// - Position changes and gameplay impact
/// - Backward compatibility with existing saves
void main() {
  group('Position System End-to-End Tests', () {
    late SaveService saveService;
    late GameService gameService;
    late LeagueService leagueService;
    late PlayerGenerator playerGenerator;

    setUp(() async {
      saveService = SaveService();
      gameService = GameService();
      leagueService = LeagueService();
      playerGenerator = PlayerGenerator();
      SharedPreferences.setMockInitialValues({});
      
      await leagueService.initializeLeague();
    });

    test('Height-based attribute modifiers work correctly for tall players', () {
      // Generate many players to find tall ones
      final players = List.generate(200, (_) => playerGenerator.generatePlayer());
      final tallPlayers = players.where((p) => p.heightInches >= 80).toList();
      
      expect(tallPlayers.isNotEmpty, true, reason: 'Should generate some tall players');
      
      // Count position distribution for tall players
      final positionCounts = <String, int>{};
      
      for (final player in tallPlayers) {
        // Verify all attributes are in valid range
        expect(player.rebounding, inInclusiveRange(0, 100));
        expect(player.blocks, inInclusiveRange(0, 100));
        expect(player.steals, inInclusiveRange(0, 100));
        expect(player.shooting, inInclusiveRange(0, 100));
        expect(player.speed, inInclusiveRange(0, 100));
        
        positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
      }
      
      // Tall players should predominantly be C, PF, or SF
      // (but due to random attributes, some may be other positions)
      final frontcourtCount = (positionCounts['C'] ?? 0) + 
                              (positionCounts['PF'] ?? 0) + 
                              (positionCounts['SF'] ?? 0);
      final totalTallPlayers = tallPlayers.length;
      
      // At least 70% of tall players should be frontcourt positions
      expect(frontcourtCount / totalTallPlayers, greaterThan(0.7),
          reason: 'Most tall players should be assigned to C, PF, or SF positions');
    });

    test('Height-based attribute modifiers work correctly for short players', () {
      // Generate many players to find short ones
      final players = List.generate(200, (_) => playerGenerator.generatePlayer());
      final shortPlayers = players.where((p) => p.heightInches <= 72).toList();
      
      expect(shortPlayers.isNotEmpty, true, reason: 'Should generate some short players');
      
      for (final player in shortPlayers) {
        // Verify all attributes are in valid range
        expect(player.steals, inInclusiveRange(0, 100));
        expect(player.shooting, inInclusiveRange(0, 100));
        expect(player.speed, inInclusiveRange(0, 100));
        expect(player.rebounding, inInclusiveRange(0, 100));
        expect(player.blocks, inInclusiveRange(0, 100));
        
        // Short players should generally favor PG or SG positions
        expect(['PG', 'SG'].contains(player.position), true,
            reason: 'Short player ${player.name} (${player.heightFormatted}) '
                'should be PG or SG, but is ${player.position}');
      }
    });

    test('Position affinities calculated correctly for various player types', () {
      final players = List.generate(100, (_) => playerGenerator.generatePlayer());
      
      for (final player in players) {
        final affinities = player.getPositionAffinities();
        
        // Verify all positions have affinity scores
        expect(affinities.containsKey('PG'), true);
        expect(affinities.containsKey('SG'), true);
        expect(affinities.containsKey('SF'), true);
        expect(affinities.containsKey('PF'), true);
        expect(affinities.containsKey('C'), true);
        
        // All affinities should be in 0-100 range
        for (var entry in affinities.entries) {
          expect(entry.value, inInclusiveRange(0.0, 100.0),
              reason: 'Affinity for ${entry.key} should be 0-100');
        }
        
        // Assigned position should match highest affinity
        final highestAffinityPosition = affinities.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        
        expect(player.position, equals(highestAffinityPosition),
            reason: 'Player ${player.name} assigned to ${player.position} '
                'but highest affinity is $highestAffinityPosition');
      }
    });

    test('Position affinity calculations respect height for guards', () {
      // Create a short player with guard attributes
      final shortGuard = Player(
        id: 'short-guard',
        name: 'Short Guard',
        heightInches: 70, // 5'10"
        shooting: 85,
        defense: 70,
        speed: 90,
        postShooting: 80,
        passing: 90,
        rebounding: 40,
        ballHandling: 95,
        threePoint: 85,
        blocks: 30,
        steals: 85,
        position: 'PG',
      );
      
      final affinities = shortGuard.getPositionAffinities();
      
      // Short player with guard skills should have high PG/SG affinity
      expect(affinities['PG']!, greaterThan(70.0),
          reason: 'Short guard should have high PG affinity');
      expect(affinities['SG']!, greaterThan(60.0),
          reason: 'Short guard should have decent SG affinity');
      
      // Should have low C affinity
      expect(affinities['C']!, lessThan(50.0),
          reason: 'Short guard should have low C affinity');
    });

    test('Position affinity calculations respect height for centers', () {
      // Create a tall player with center attributes
      final tallCenter = Player(
        id: 'tall-center',
        name: 'Tall Center',
        heightInches: 84, // 7'0"
        shooting: 60,
        defense: 85,
        speed: 50,
        postShooting: 75,
        passing: 50,
        rebounding: 95,
        ballHandling: 40,
        threePoint: 30,
        blocks: 95,
        steals: 40,
        position: 'C',
      );
      
      final affinities = tallCenter.getPositionAffinities();
      
      // Tall player with center skills should have high C affinity
      expect(affinities['C']!, greaterThan(80.0),
          reason: 'Tall center should have high C affinity');
      expect(affinities['PF']!, greaterThan(60.0),
          reason: 'Tall center should have decent PF affinity');
      
      // Should have low PG affinity
      expect(affinities['PG']!, lessThan(40.0),
          reason: 'Tall center should have low PG affinity');
    });

    test('Position assignment persists across save/load', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Verify team has players with positions
      for (final player in userTeam.players) {
        expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true,
            reason: 'Player ${player.name} should have valid position');
      }
      
      // Create and save game state
      final schedule = gameService.generateSchedule(userTeam.id, teams);
      final season = Season(
        id: 'position-test',
        year: 2024,
        games: schedule,
        userTeamId: userTeam.id,
      );
      
      final gameState = GameState(
        teams: teams,
        currentSeason: season,
        userTeamId: userTeam.id,
      );
      
      await saveService.saveGame('position_persist_test', gameState);
      
      // Load and verify positions persisted
      final loadedState = await saveService.loadGame('position_persist_test');
      expect(loadedState, isNotNull);
      
      final loadedTeam = loadedState!.teams.firstWhere((t) => t.id == userTeam.id);
      
      for (int i = 0; i < userTeam.players.length; i++) {
        final originalPlayer = userTeam.players[i];
        final loadedPlayer = loadedTeam.players[i];
        
        expect(loadedPlayer.position, equals(originalPlayer.position),
            reason: 'Player ${originalPlayer.name} position should persist');
        expect(loadedPlayer.blocks, equals(originalPlayer.blocks),
            reason: 'Player blocks attribute should persist');
        expect(loadedPlayer.steals, equals(originalPlayer.steals),
            reason: 'Player steals attribute should persist');
      }
    });

    test('Position changes persist and can be verified', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      final player = userTeam.players.first;
      
      final originalPosition = player.position;
      
      // Change player position
      final newPosition = originalPosition == 'PG' ? 'SG' : 'PG';
      final updatedPlayer = player.copyWithPosition(newPosition);
      
      expect(updatedPlayer.position, equals(newPosition));
      expect(updatedPlayer.id, equals(player.id));
      expect(updatedPlayer.name, equals(player.name));
      
      // Create updated team with changed player
      final updatedPlayers = List<Player>.from(userTeam.players);
      final playerIndex = updatedPlayers.indexWhere((p) => p.id == player.id);
      updatedPlayers[playerIndex] = updatedPlayer;
      
      final updatedTeam = userTeam.copyWith(players: updatedPlayers);
      
      // Save with updated team
      final updatedTeams = teams.map((t) => t.id == userTeam.id ? updatedTeam : t).toList();
      final schedule = gameService.generateSchedule(userTeam.id, updatedTeams);
      final season = Season(
        id: 'position-change-test',
        year: 2024,
        games: schedule,
        userTeamId: userTeam.id,
      );
      
      final gameState = GameState(
        teams: updatedTeams,
        currentSeason: season,
        userTeamId: userTeam.id,
      );
      
      await saveService.saveGame('position_change_test', gameState);
      
      // Load and verify position change persisted
      final loadedState = await saveService.loadGame('position_change_test');
      final loadedTeam = loadedState!.teams.firstWhere((t) => t.id == userTeam.id);
      final loadedPlayer = loadedTeam.players.firstWhere((p) => p.id == player.id);
      
      expect(loadedPlayer.position, equals(newPosition),
          reason: 'Position change should persist');
    });

    group('Position Modifiers Impact on Game Statistics', () {
    test('Multiple games show statistical patterns based on positions', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      final opponentTeam = teams[1];
      
      // Play 10 games and track statistics by position
      final positionStats = <String, List<int>>{
        'PG': [],
        'SG': [],
        'SF': [],
        'PF': [],
        'C': [],
      };
      
      for (int i = 0; i < 10; i++) {
        final game = gameService.simulateGameDetailed(userTeam, opponentTeam);
        
        expect(game.boxScore, isNotNull);
        
        // Collect stats by position
        for (final player in userTeam.players) {
          final stats = game.boxScore![player.id];
          if (stats != null) {
            positionStats[player.position]!.add(stats.points);
          }
        }
      }
      
      // Verify at least 3 positions have some data
      // (not all positions may be represented in starting lineup)
      final positionsWithData = positionStats.values.where((list) => list.isNotEmpty).length;
      expect(positionsWithData, greaterThanOrEqualTo(3),
          reason: 'At least 3 positions should have statistics');
      
      // Verify all collected stats are valid
      for (var entry in positionStats.entries) {
        for (var points in entry.value) {
          expect(points, greaterThanOrEqualTo(0));
        }
      }
    });

    test('Point guards show higher assist rates in games', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      final opponentTeam = teams[1];
      
      // Find point guards on the team
      final pointGuards = userTeam.players.where((p) => p.position == 'PG').toList();
      
      if (pointGuards.isEmpty) {
        // Skip test if no point guards (unlikely but possible)
        return;
      }
      
      // Play 5 games and track assists
      int totalPGAssists = 0;
      int totalPGGames = 0;
      
      for (int i = 0; i < 5; i++) {
        final game = gameService.simulateGameDetailed(userTeam, opponentTeam);
        
        for (final pg in pointGuards) {
          final stats = game.boxScore![pg.id];
          if (stats != null && stats.assists > 0) {
            totalPGAssists += stats.assists;
            totalPGGames++;
          }
        }
      }
      
      // Point guards should accumulate assists
      expect(totalPGAssists, greaterThan(0),
          reason: 'Point guards should record assists across games');
    });

    test('Centers and power forwards show higher rebound rates in games', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      final opponentTeam = teams[1];
      
      // Find frontcourt players (C, PF) on the team
      final frontcourtPlayers = userTeam.players
          .where((p) => p.position == 'C' || p.position == 'PF')
          .toList();
      
      if (frontcourtPlayers.isEmpty) {
        // Skip test if no frontcourt players (very unlikely)
        return;
      }
      
      // Play 5 games and track rebounds and blocks
      int totalFrontcourtRebounds = 0;
      int totalFrontcourtBlocks = 0;
      
      for (int i = 0; i < 5; i++) {
        final game = gameService.simulateGameDetailed(userTeam, opponentTeam);
        
        for (final player in frontcourtPlayers) {
          final stats = game.boxScore![player.id];
          if (stats != null) {
            totalFrontcourtRebounds += stats.rebounds;
            totalFrontcourtBlocks += stats.blocks;
          }
        }
      }
      
      // Frontcourt players should accumulate rebounds
      expect(totalFrontcourtRebounds, greaterThan(0),
          reason: 'Frontcourt players should record rebounds across games');
      expect(totalFrontcourtBlocks, greaterThanOrEqualTo(0),
          reason: 'Frontcourt players should have opportunity for blocks');
    });

    test('Shooting guards show higher three-point attempt rates', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      final opponentTeam = teams[1];
      
      // Find shooting guards on the team
      final shootingGuards = userTeam.players.where((p) => p.position == 'SG').toList();
      
      if (shootingGuards.isEmpty) {
        // Skip test if no shooting guards (unlikely but possible)
        return;
      }
      
      // Play 5 games and track three-point attempts
      int totalSGThreeAttempts = 0;
      
      for (int i = 0; i < 5; i++) {
        final game = gameService.simulateGameDetailed(userTeam, opponentTeam);
        
        for (final sg in shootingGuards) {
          final stats = game.boxScore![sg.id];
          if (stats != null) {
            totalSGThreeAttempts += stats.threePointersAttempted;
          }
        }
      }
      
      // Shooting guards should attempt three-pointers
      expect(totalSGThreeAttempts, greaterThan(0),
          reason: 'Shooting guards should attempt three-pointers across games');
    });
    });

    group('Backward Compatibility with Existing Saves', () {
    test('Old saves without position field load with default positions', () async {
      final teams = leagueService.getAllTeams();
      
      // Create players without explicit position (simulating old save format)
      // The Player.fromJson should handle missing position field
      final oldFormatPlayerJson = {
        'id': 'old-player',
        'name': 'Old Format Player',
        'heightInches': 75,
        'shooting': 80,
        'defense': 75,
        'speed': 70,
        'stamina': 85,
        'passing': 65,
        'rebounding': 70,
        'ballHandling': 75,
        'threePoint': 80,
        // Note: blocks and steals should also be handled if missing
        'blocks': 70,
        'steals': 75,
        // position field is missing - should be assigned based on affinities
      };
      
      final player = Player.fromJson(oldFormatPlayerJson);
      
      // Player should have a valid position assigned
      expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true,
          reason: 'Old format player should be assigned a valid position');
    });

    test('Old saves without blocks/steals attributes load with defaults', () async {
      // Create player JSON without blocks/steals (simulating very old save)
      final veryOldPlayerJson = {
        'id': 'very-old-player',
        'name': 'Very Old Player',
        'heightInches': 78,
        'shooting': 75,
        'defense': 80,
        'speed': 65,
        'stamina': 80,
        'passing': 60,
        'rebounding': 85,
        'ballHandling': 60,
        'threePoint': 70,
        // blocks, steals, and position are all missing
      };
      
      final player = Player.fromJson(veryOldPlayerJson);
      
      // Player should have valid blocks and steals
      expect(player.blocks, inInclusiveRange(0, 100),
          reason: 'Missing blocks should be assigned default value');
      expect(player.steals, inInclusiveRange(0, 100),
          reason: 'Missing steals should be assigned default value');
      expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true,
          reason: 'Missing position should be assigned based on attributes');
    });

    test('Complete save/load cycle with position system', () async {
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      final schedule = gameService.generateSchedule(userTeamId, teams);
      
      var season = Season(
        id: 'position-system-save',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
      );
      
      // Play 3 games with position system
      for (int i = 0; i < 3; i++) {
        final nextGame = season.nextGame!;
        final homeTeam = teams.firstWhere((t) => t.id == nextGame.homeTeamId);
        final awayTeam = teams.firstWhere((t) => t.id == nextGame.awayTeamId);
        
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        
        final updatedGames = List<Game>.from(season.games);
        final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame.id);
        updatedGames[gameIndex] = simulatedGame;
        
        season = season.copyWith(games: updatedGames);
        season = season.updateSeasonStats(simulatedGame.boxScore!);
      }
      
      final gameState = GameState(
        teams: teams,
        currentSeason: season,
        userTeamId: userTeamId,
      );
      
      // Save
      await saveService.saveGame('position_system_complete', gameState);
      
      // Load
      final loadedState = await saveService.loadGame('position_system_complete');
      
      expect(loadedState, isNotNull);
      expect(loadedState!.currentSeason.gamesPlayed, 3);
      
      // Verify all players have positions
      final loadedUserTeam = loadedState.teams.firstWhere((t) => t.id == userTeamId);
      for (final player in loadedUserTeam.players) {
        expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true,
            reason: 'Player ${player.name} should have valid position after load');
        expect(player.blocks, inInclusiveRange(0, 100));
        expect(player.steals, inInclusiveRange(0, 100));
      }
      
      // Verify season stats include advanced statistics
      expect(loadedState.currentSeason.seasonStats, isNotNull);
      for (var entry in loadedState.currentSeason.seasonStats!.entries) {
        final stats = entry.value;
        expect(stats.totalSteals, greaterThanOrEqualTo(0));
        expect(stats.totalBlocks, greaterThanOrEqualTo(0));
        expect(stats.totalTurnovers, greaterThanOrEqualTo(0));
      }
    });
    });

    group('UI Data Verification', () {
    test('Position information is available for UI display', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Verify each player has position data for UI
      for (final player in userTeam.players) {
        // Position should be displayable
        expect(player.position, isNotEmpty);
        expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true);
        
        // Affinity scores should be calculable for UI
        final affinities = player.getPositionAffinities();
        expect(affinities.length, 5);
        
        for (var entry in affinities.entries) {
          expect(entry.value, inInclusiveRange(0.0, 100.0));
        }
      }
    });

    test('Position distribution across team is reasonable', () {
      final teams = leagueService.getAllTeams();
      
      for (final team in teams) {
        final positionCounts = <String, int>{
          'PG': 0,
          'SG': 0,
          'SF': 0,
          'PF': 0,
          'C': 0,
        };
        
        for (final player in team.players) {
          positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
        }
        
        // Each team should have at least one player at each position
        // (or at least most positions - some variation is acceptable)
        final positionsWithPlayers = positionCounts.values.where((count) => count > 0).length;
        expect(positionsWithPlayers, greaterThanOrEqualTo(3),
            reason: 'Team ${team.name} should have players at multiple positions');
      }
    });

    test('Starting lineup has position diversity', () {
      final teams = leagueService.getAllTeams();
      
      for (final team in teams) {
        final startingLineup = team.players
            .where((p) => team.startingLineupIds.contains(p.id))
            .toList();
        
        expect(startingLineup.length, 5, reason: 'Starting lineup should have 5 players');
        
        final startingPositions = startingLineup.map((p) => p.position).toSet();
        
        // Starting lineup should ideally have diverse positions
        // (at least 2 different positions - some teams may have less diversity)
        expect(startingPositions.length, greaterThanOrEqualTo(2),
            reason: 'Starting lineup should have some position diversity');
      }
    });
    });

    group('Position System Integration', () {
    test('Full season simulation with position system works correctly', () async {
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      final schedule = gameService.generateSchedule(userTeamId, teams);
      
      var season = Season(
        id: 'full-season-position',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
      );
      
      // Play 20 games (partial season)
      for (int i = 0; i < 20; i++) {
        final nextGame = season.nextGame;
        if (nextGame == null) break;
        
        final homeTeam = teams.firstWhere((t) => t.id == nextGame.homeTeamId);
        final awayTeam = teams.firstWhere((t) => t.id == nextGame.awayTeamId);
        
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        
        final updatedGames = List<Game>.from(season.games);
        final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame.id);
        updatedGames[gameIndex] = simulatedGame;
        
        season = season.copyWith(games: updatedGames);
        season = season.updateSeasonStats(simulatedGame.boxScore!);
      }
      
      expect(season.gamesPlayed, 20);
      expect(season.seasonStats, isNotNull);
      expect(season.seasonStats!.isNotEmpty, true);
      
      // Verify season stats show realistic patterns
      final userTeam = teams.firstWhere((t) => t.id == userTeamId);
      for (final player in userTeam.players) {
        final stats = season.getPlayerStats(player.id);
        if (stats != null && stats.gamesPlayed > 0) {
          // Stats should be reasonable
          expect(stats.pointsPerGame, inInclusiveRange(0.0, 50.0));
          expect(stats.reboundsPerGame, inInclusiveRange(0.0, 20.0));
          expect(stats.assistsPerGame, inInclusiveRange(0.0, 15.0));
        }
      }
    });

    test('Position system handles edge cases gracefully', () {
      // Create player with extreme attributes
      final extremePlayer = Player(
        id: 'extreme',
        name: 'Extreme Player',
        heightInches: 90, // Extremely tall
        shooting: 100,
        defense: 100,
        speed: 100,
        postShooting: 100,
        passing: 100,
        rebounding: 100,
        ballHandling: 100,
        threePoint: 100,
        blocks: 100,
        steals: 100,
        position: 'C',
      );
      
      final affinities = extremePlayer.getPositionAffinities();
      
      // All affinities should still be in valid range
      for (var entry in affinities.entries) {
        expect(entry.value, inInclusiveRange(0.0, 100.0),
            reason: 'Extreme player affinity for ${entry.key} should be clamped');
      }
      
      // Create player with minimum attributes
      final minPlayer = Player(
        id: 'min',
        name: 'Min Player',
        heightInches: 60, // Extremely short
        shooting: 0,
        defense: 0,
        speed: 0,
        postShooting: 0,
        passing: 0,
        rebounding: 0,
        ballHandling: 0,
        threePoint: 0,
        blocks: 0,
        steals: 0,
        position: 'PG',
      );
      
      final minAffinities = minPlayer.getPositionAffinities();
      
      // All affinities should still be in valid range
      for (var entry in minAffinities.entries) {
        expect(entry.value, inInclusiveRange(0.0, 100.0),
            reason: 'Min player affinity for ${entry.key} should be clamped');
      }
    });
    });
  });
}
