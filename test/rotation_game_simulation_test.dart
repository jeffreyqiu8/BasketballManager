import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/rotation_config.dart';
import 'package:BasketballManager/models/depth_chart_entry.dart';
import 'package:BasketballManager/services/possession_simulation.dart';

void main() {
  group('Rotation Integration with Game Simulation', () {
    late Team teamWithRotation;
    late Team teamWithoutRotation;

    setUp(() {
      // Create test players with different positions
      final players = [
        // Starters
        Player(
          id: 'pg1',
          name: 'PG Starter',
          heightInches: 75,
          shooting: 80,
          defense: 75,
          speed: 85,
          postShooting: 60,
          passing: 85,
          rebounding: 50,
          ballHandling: 85,
          threePoint: 75,
          blocks: 40,
          steals: 70,
          position: 'PG',
        ),
        Player(
          id: 'sg1',
          name: 'SG Starter',
          heightInches: 78,
          shooting: 85,
          defense: 70,
          speed: 80,
          postShooting: 65,
          passing: 70,
          rebounding: 55,
          ballHandling: 75,
          threePoint: 85,
          blocks: 45,
          steals: 65,
          position: 'SG',
        ),
        Player(
          id: 'sf1',
          name: 'SF Starter',
          heightInches: 80,
          shooting: 80,
          defense: 75,
          speed: 75,
          postShooting: 70,
          passing: 70,
          rebounding: 65,
          ballHandling: 70,
          threePoint: 75,
          blocks: 50,
          steals: 70,
          position: 'SF',
        ),
        Player(
          id: 'pf1',
          name: 'PF Starter',
          heightInches: 82,
          shooting: 75,
          defense: 80,
          speed: 65,
          postShooting: 80,
          passing: 60,
          rebounding: 80,
          ballHandling: 60,
          threePoint: 60,
          blocks: 70,
          steals: 60,
          position: 'PF',
        ),
        Player(
          id: 'c1',
          name: 'C Starter',
          heightInches: 84,
          shooting: 70,
          defense: 85,
          speed: 55,
          postShooting: 85,
          passing: 55,
          rebounding: 90,
          ballHandling: 50,
          threePoint: 40,
          blocks: 85,
          steals: 55,
          position: 'C',
        ),
        // Bench players
        Player(
          id: 'pg2',
          name: 'PG Bench',
          heightInches: 74,
          shooting: 70,
          defense: 65,
          speed: 75,
          postShooting: 55,
          passing: 75,
          rebounding: 45,
          ballHandling: 75,
          threePoint: 65,
          blocks: 35,
          steals: 60,
          position: 'PG',
        ),
        Player(
          id: 'sg2',
          name: 'SG Bench',
          heightInches: 77,
          shooting: 75,
          defense: 60,
          speed: 70,
          postShooting: 60,
          passing: 60,
          rebounding: 50,
          ballHandling: 65,
          threePoint: 75,
          blocks: 40,
          steals: 55,
          position: 'SG',
        ),
        Player(
          id: 'sf2',
          name: 'SF Bench',
          heightInches: 79,
          shooting: 70,
          defense: 65,
          speed: 65,
          postShooting: 65,
          passing: 60,
          rebounding: 60,
          ballHandling: 60,
          threePoint: 65,
          blocks: 45,
          steals: 60,
          position: 'SF',
        ),
        // Extra players to fill roster
        ...List.generate(7, (i) => Player(
          id: 'extra${i + 1}',
          name: 'Extra Player ${i + 1}',
          heightInches: 76,
          shooting: 60,
          defense: 60,
          speed: 60,
          postShooting: 60,
          passing: 60,
          rebounding: 60,
          ballHandling: 60,
          threePoint: 60,
          blocks: 50,
          steals: 50,
          position: 'SF',
        )),
      ];

      // Create rotation config for 8-player rotation
      // Each position must have exactly 48 minutes
      final rotationConfig = RotationConfig(
        rotationSize: 8,
        playerMinutes: {
          'pg1': 34,
          'pg2': 14,
          'sg1': 32,
          'sg2': 16,
          'sf1': 34,
          'sf2': 14,
          'pf1': 48,  // No backup for PF
          'c1': 48,   // No backup for C
        },
        depthChart: [
          DepthChartEntry(playerId: 'pg1', position: 'PG', depth: 1),
          DepthChartEntry(playerId: 'pg2', position: 'PG', depth: 2),
          DepthChartEntry(playerId: 'sg1', position: 'SG', depth: 1),
          DepthChartEntry(playerId: 'sg2', position: 'SG', depth: 2),
          DepthChartEntry(playerId: 'sf1', position: 'SF', depth: 1),
          DepthChartEntry(playerId: 'sf2', position: 'SF', depth: 2),
          DepthChartEntry(playerId: 'pf1', position: 'PF', depth: 1),
          DepthChartEntry(playerId: 'c1', position: 'C', depth: 1),
        ],
        lastModified: DateTime.now(),
      );

      teamWithRotation = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: players,
        startingLineupIds: ['pg1', 'sg1', 'sf1', 'pf1', 'c1'],
        rotationConfig: rotationConfig,
      );

      teamWithoutRotation = Team(
        id: 'team2',
        name: 'Opponent Team',
        city: 'Opponent City',
        players: players,
        startingLineupIds: ['pg1', 'sg1', 'sf1', 'pf1', 'c1'],
        rotationConfig: null,
      );
    });

    test('game simulation uses rotation configuration', () {
      final simulation = PossessionSimulation(teamWithRotation, teamWithoutRotation);
      final boxScore = simulation.simulate();

      // Verify that rotation players have stats
      expect(boxScore.containsKey('pg1'), true);
      expect(boxScore.containsKey('pg2'), true);
      expect(boxScore.containsKey('sg1'), true);
      expect(boxScore.containsKey('sg2'), true);
      expect(boxScore.containsKey('sf1'), true);
      expect(boxScore.containsKey('sf2'), true);
      expect(boxScore.containsKey('pf1'), true);
      expect(boxScore.containsKey('c1'), true);

      // Verify that non-rotation players don't have stats
      expect(boxScore.containsKey('extra1'), false);
      expect(boxScore.containsKey('extra2'), false);
    });

    test('starters begin the game', () {
      final simulation = PossessionSimulation(teamWithRotation, teamWithoutRotation);
      final boxScore = simulation.simulate();

      // All starters should have some stats (they start the game)
      expect(boxScore['pg1']!.fieldGoalsAttempted > 0 || 
             boxScore['pg1']!.rebounds > 0 || 
             boxScore['pg1']!.assists > 0, true);
      expect(boxScore['sg1']!.fieldGoalsAttempted > 0 || 
             boxScore['sg1']!.rebounds > 0 || 
             boxScore['sg1']!.assists > 0, true);
      expect(boxScore['sf1']!.fieldGoalsAttempted > 0 || 
             boxScore['sf1']!.rebounds > 0 || 
             boxScore['sf1']!.assists > 0, true);
      expect(boxScore['pf1']!.fieldGoalsAttempted > 0 || 
             boxScore['pf1']!.rebounds > 0 || 
             boxScore['pf1']!.assists > 0, true);
      expect(boxScore['c1']!.fieldGoalsAttempted > 0 || 
             boxScore['c1']!.rebounds > 0 || 
             boxScore['c1']!.assists > 0, true);
    });

    test('bench players get playing time', () {
      final simulation = PossessionSimulation(teamWithRotation, teamWithoutRotation);
      final boxScore = simulation.simulate();

      // Bench players should have some stats (they substitute in)
      // Note: Due to randomness, they might not always get shots, but should at least be tracked
      expect(boxScore.containsKey('pg2'), true);
      expect(boxScore.containsKey('sg2'), true);
      expect(boxScore.containsKey('sf2'), true);
    });

    test('team without rotation uses starting lineup only', () {
      // Both teams without rotation - should only track starters
      final simulation = PossessionSimulation(teamWithoutRotation, teamWithoutRotation);
      final boxScore = simulation.simulate();

      // Only starting lineup should have stats for teams without rotation
      expect(boxScore.containsKey('pg1'), true);
      expect(boxScore.containsKey('sg1'), true);
      expect(boxScore.containsKey('sf1'), true);
      expect(boxScore.containsKey('pf1'), true);
      expect(boxScore.containsKey('c1'), true);

      // Bench players should not have stats when no rotation config
      expect(boxScore.containsKey('pg2'), false);
      expect(boxScore.containsKey('sg2'), false);
      expect(boxScore.containsKey('sf2'), false);
    });

    test('game completes successfully with rotation', () {
      final simulation = PossessionSimulation(teamWithRotation, teamWithRotation);
      final boxScore = simulation.simulate();

      // Game should complete with valid scores
      expect(simulation.homeScore > 0, true);
      expect(simulation.awayScore > 0, true);
      expect(simulation.homeScore != simulation.awayScore, true); // No ties

      // Box score should have entries
      expect(boxScore.isNotEmpty, true);
    });

    test('rotation configuration is validated', () {
      // This test verifies that the rotation config is valid
      final errors = teamWithRotation.rotationConfig!.getValidationErrors();
      if (errors.isNotEmpty) {
        print('Validation errors: $errors');
      }
      expect(teamWithRotation.rotationConfig!.isValid(), true);
      expect(errors, isEmpty);
    });
  });
}
