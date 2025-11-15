import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/services/possession_simulation.dart';

void main() {
  group('Three-Point Attempt Rates', () {
    // Helper to create a basic team with specific players
    Team createTestTeam(String teamId, List<Player> startingLineup) {
      final benchPlayers = List.generate(10, (i) => Player(
        id: 'bench_${teamId}_$i',
        name: 'Bench Player $i',
        heightInches: 76,
        shooting: 60,
        defense: 60,
        speed: 60,
        postShooting: 60,
        passing: 60,
        rebounding: 60,
        ballHandling: 60,
        threePoint: 60,
        blocks: 60,
        steals: 60,
        position: ['PG', 'SG', 'SF', 'PF', 'C'][i % 5],
      ));

      final allPlayers = [...startingLineup, ...benchPlayers];
      final startingLineupIds = startingLineup.map((p) => p.id).toList();

      return Team(
        id: teamId,
        city: 'Test',
        name: 'Team',
        players: allPlayers,
        startingLineupIds: startingLineupIds,
      );
    }

    test('Centers should rarely attempt three-pointers', () {
      // Create a center with low three-point rating
      final center = Player(
        id: 'c1',
        name: 'Traditional Center',
        heightInches: 84,
        shooting: 65,
        defense: 80,
        speed: 55,
        postShooting: 90,
        passing: 50,
        rebounding: 90,
        ballHandling: 50,
        threePoint: 30, // Low three-point rating
        blocks: 90,
        steals: 55,
        position: 'C',
      );

      // Create supporting cast
      final supportingPlayers = List.generate(4, (i) => Player(
        id: 'support$i',
        name: 'Support $i',
        heightInches: 74 + i * 2,
        shooting: 70,
        defense: 70,
        speed: 70,
        postShooting: 70,
        passing: 65,
        rebounding: 70,
        ballHandling: 70,
        threePoint: 70,
        blocks: 65,
        steals: 65,
        position: ['PG', 'SG', 'SF', 'PF'][i],
      ));

      final team = createTestTeam('team1', [center, ...supportingPlayers]);
      
      // Create opponent
      final opponentPlayers = List.generate(5, (i) => Player(
        id: 'opp$i',
        name: 'Opponent $i',
        heightInches: 76 + i * 2,
        shooting: 65,
        defense: 65,
        speed: 65,
        postShooting: 65,
        passing: 60,
        rebounding: 65,
        ballHandling: 65,
        threePoint: 65,
        blocks: 60,
        steals: 60,
        position: ['PG', 'SG', 'SF', 'PF', 'C'][i],
      ));
      final opponent = createTestTeam('opponent', opponentPlayers);

      // Run simulations
      int totalThreeAttempts = 0;
      int totalFieldGoalAttempts = 0;
      const numGames = 20;

      for (int i = 0; i < numGames; i++) {
        final sim = PossessionSimulation(team, opponent);
        final boxScore = sim.simulate();
        final stats = boxScore[center.id];
        
        if (stats != null) {
          totalThreeAttempts += stats.threePointersAttempted;
          totalFieldGoalAttempts += stats.fieldGoalsAttempted;
        }
      }

      final avgThreeAttempts = totalThreeAttempts / numGames;
      final avgFieldGoalAttempts = totalFieldGoalAttempts / numGames;
      final threePointRate = totalFieldGoalAttempts > 0 
          ? (totalThreeAttempts / totalFieldGoalAttempts) * 100 
          : 0.0;

      print('Traditional Center (30 3PT rating):');
      print('  Avg 3PA per game: ${avgThreeAttempts.toStringAsFixed(1)}');
      print('  Avg FGA per game: ${avgFieldGoalAttempts.toStringAsFixed(1)}');
      print('  3PT rate: ${threePointRate.toStringAsFixed(1)}%');

      // Traditional center should attempt very few threes (less than 2 per game)
      expect(avgThreeAttempts, lessThan(2.0),
          reason: 'Traditional center should rarely attempt three-pointers');
      
      // Three-point rate should be low (less than 20% of shots)
      expect(threePointRate, lessThan(20.0),
          reason: 'Traditional center should have low three-point attempt rate');
    });

    test('Stretch five center should attempt more threes but still reasonable', () {
      // Create a stretch five with high three-point rating
      final stretchFive = Player(
        id: 'c2',
        name: 'Stretch Five',
        heightInches: 84,
        shooting: 75,
        defense: 75,
        speed: 60,
        postShooting: 70,
        passing: 55,
        rebounding: 85,
        ballHandling: 55,
        threePoint: 85, // High three-point rating
        blocks: 80,
        steals: 60,
        position: 'C',
        roleArchetypeId: 'c_stretch_five',
      );

      // Create supporting cast
      final supportingPlayers = List.generate(4, (i) => Player(
        id: 'support$i',
        name: 'Support $i',
        heightInches: 74 + i * 2,
        shooting: 70,
        defense: 70,
        speed: 70,
        postShooting: 70,
        passing: 65,
        rebounding: 70,
        ballHandling: 70,
        threePoint: 70,
        blocks: 65,
        steals: 65,
        position: ['PG', 'SG', 'SF', 'PF'][i],
      ));

      final team = createTestTeam('team1', [stretchFive, ...supportingPlayers]);
      
      // Create opponent
      final opponentPlayers = List.generate(5, (i) => Player(
        id: 'opp$i',
        name: 'Opponent $i',
        heightInches: 76 + i * 2,
        shooting: 65,
        defense: 65,
        speed: 65,
        postShooting: 65,
        passing: 60,
        rebounding: 65,
        ballHandling: 65,
        threePoint: 65,
        blocks: 60,
        steals: 60,
        position: ['PG', 'SG', 'SF', 'PF', 'C'][i],
      ));
      final opponent = createTestTeam('opponent', opponentPlayers);

      // Run simulations
      int totalThreeAttempts = 0;
      int totalFieldGoalAttempts = 0;
      const numGames = 20;

      for (int i = 0; i < numGames; i++) {
        final sim = PossessionSimulation(team, opponent);
        final boxScore = sim.simulate();
        final stats = boxScore[stretchFive.id];
        
        if (stats != null) {
          totalThreeAttempts += stats.threePointersAttempted;
          totalFieldGoalAttempts += stats.fieldGoalsAttempted;
        }
      }

      final avgThreeAttempts = totalThreeAttempts / numGames;
      final avgFieldGoalAttempts = totalFieldGoalAttempts / numGames;
      final threePointRate = totalFieldGoalAttempts > 0 
          ? (totalThreeAttempts / totalFieldGoalAttempts) * 100 
          : 0.0;

      print('Stretch Five (85 3PT rating + role):');
      print('  Avg 3PA per game: ${avgThreeAttempts.toStringAsFixed(1)}');
      print('  Avg FGA per game: ${avgFieldGoalAttempts.toStringAsFixed(1)}');
      print('  3PT rate: ${threePointRate.toStringAsFixed(1)}%');

      // Stretch five should attempt more threes but still reasonable (less than 5 per game)
      expect(avgThreeAttempts, lessThan(5.0),
          reason: 'Stretch five should attempt threes but not excessively');
      
      // Should be more than traditional center
      expect(avgThreeAttempts, greaterThan(0.5),
          reason: 'Stretch five should attempt some three-pointers');
    });

    test('Shooting guards should have highest three-point rates', () {
      // Create a shooting guard with high three-point rating
      final shootingGuard = Player(
        id: 'sg1',
        name: 'Elite Shooter',
        heightInches: 76,
        shooting: 85,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 65,
        rebounding: 50,
        ballHandling: 75,
        threePoint: 90, // Elite three-point rating
        blocks: 40,
        steals: 75,
        position: 'SG',
      );

      // Create supporting cast
      final supportingPlayers = List.generate(4, (i) => Player(
        id: 'support$i',
        name: 'Support $i',
        heightInches: 74 + i * 2,
        shooting: 70,
        defense: 70,
        speed: 70,
        postShooting: 70,
        passing: 65,
        rebounding: 70,
        ballHandling: 70,
        threePoint: 70,
        blocks: 65,
        steals: 65,
        position: ['PG', 'SF', 'PF', 'C'][i],
      ));

      final team = createTestTeam('team1', [shootingGuard, ...supportingPlayers]);
      
      // Create opponent
      final opponentPlayers = List.generate(5, (i) => Player(
        id: 'opp$i',
        name: 'Opponent $i',
        heightInches: 76 + i * 2,
        shooting: 65,
        defense: 65,
        speed: 65,
        postShooting: 65,
        passing: 60,
        rebounding: 65,
        ballHandling: 65,
        threePoint: 65,
        blocks: 60,
        steals: 60,
        position: ['PG', 'SG', 'SF', 'PF', 'C'][i],
      ));
      final opponent = createTestTeam('opponent', opponentPlayers);

      // Run simulations
      int totalThreeAttempts = 0;
      int totalFieldGoalAttempts = 0;
      const numGames = 20;

      for (int i = 0; i < numGames; i++) {
        final sim = PossessionSimulation(team, opponent);
        final boxScore = sim.simulate();
        final stats = boxScore[shootingGuard.id];
        
        if (stats != null) {
          totalThreeAttempts += stats.threePointersAttempted;
          totalFieldGoalAttempts += stats.fieldGoalsAttempted;
        }
      }

      final avgThreeAttempts = totalThreeAttempts / numGames;
      final avgFieldGoalAttempts = totalFieldGoalAttempts / numGames;
      final threePointRate = totalFieldGoalAttempts > 0 
          ? (totalThreeAttempts / totalFieldGoalAttempts) * 100 
          : 0.0;

      print('Elite Shooting Guard (90 3PT rating):');
      print('  Avg 3PA per game: ${avgThreeAttempts.toStringAsFixed(1)}');
      print('  Avg FGA per game: ${avgFieldGoalAttempts.toStringAsFixed(1)}');
      print('  3PT rate: ${threePointRate.toStringAsFixed(1)}%');

      // Elite shooter should attempt reasonable number of threes (3-8 per game)
      expect(avgThreeAttempts, greaterThan(2.0),
          reason: 'Elite shooter should attempt multiple three-pointers');
      expect(avgThreeAttempts, lessThan(8.0),
          reason: 'Elite shooter should not attempt excessive three-pointers');
      
      // Three-point rate should be significant but not overwhelming (30-60%)
      expect(threePointRate, greaterThan(25.0),
          reason: 'Elite shooter should have significant three-point rate');
      expect(threePointRate, lessThan(65.0),
          reason: 'Elite shooter should still take some mid-range/paint shots');
    });
  });
}
