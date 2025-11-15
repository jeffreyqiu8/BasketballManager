import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/services/possession_simulation.dart';

void main() {
  group('Role Archetype Modifiers in Possession Simulation', () {
    // Helper to create a basic team with specific players
    Team createTestTeam(String teamId, List<Player> startingLineup) {
      // Create bench players to fill out the 15-player roster
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

    test('Floor General role increases assists compared to no role', () {
      // Create a point guard with high passing
      final pgWithoutRole = Player(
        id: 'pg1',
        name: 'PG Without Role',
        heightInches: 74,
        shooting: 70,
        defense: 65,
        speed: 75,
        postShooting: 60,
        passing: 90, // High passing
        rebounding: 45,
        ballHandling: 85,
        threePoint: 70,
        blocks: 35,
        steals: 70,
        position: 'PG',
        roleArchetypeId: null, // No role assigned
      );

      final pgWithFloorGeneral = pgWithoutRole.copyWithRoleArchetype('pg_floor_general');

      // Create supporting cast (same for both teams)
      final supportingPlayers = [
        Player(
          id: 'sg1',
          name: 'SG',
          heightInches: 76,
          shooting: 75,
          defense: 65,
          speed: 70,
          postShooting: 60,
          passing: 60,
          rebounding: 50,
          ballHandling: 70,
          threePoint: 80,
          blocks: 40,
          steals: 65,
          position: 'SG',
        ),
        Player(
          id: 'sf1',
          name: 'SF',
          heightInches: 78,
          shooting: 70,
          defense: 70,
          speed: 68,
          postShooting: 65,
          passing: 55,
          rebounding: 60,
          ballHandling: 65,
          threePoint: 70,
          blocks: 50,
          steals: 60,
          position: 'SF',
        ),
        Player(
          id: 'pf1',
          name: 'PF',
          heightInches: 80,
          shooting: 65,
          defense: 75,
          speed: 60,
          postShooting: 75,
          passing: 50,
          rebounding: 80,
          ballHandling: 55,
          threePoint: 60,
          blocks: 70,
          steals: 55,
          position: 'PF',
        ),
        Player(
          id: 'c1',
          name: 'C',
          heightInches: 83,
          shooting: 60,
          defense: 80,
          speed: 55,
          postShooting: 85,
          passing: 45,
          rebounding: 90,
          ballHandling: 50,
          threePoint: 40,
          blocks: 85,
          steals: 50,
          position: 'C',
        ),
      ];

      // Create teams
      final teamWithoutRole = createTestTeam('team1', [pgWithoutRole, ...supportingPlayers]);
      final teamWithRole = createTestTeam('team2', [pgWithFloorGeneral, ...supportingPlayers]);

      // Create opponent team (same for both simulations)
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

      // Run multiple simulations to get average statistics
      int totalAssistsWithoutRole = 0;
      int totalAssistsWithRole = 0;
      const numSimulations = 50;

      for (int i = 0; i < numSimulations; i++) {
        // Simulate game without role
        final simWithoutRole = PossessionSimulation(teamWithoutRole, opponent);
        final boxScoreWithoutRole = simWithoutRole.simulate();
        totalAssistsWithoutRole += boxScoreWithoutRole[pgWithoutRole.id]?.assists ?? 0;

        // Simulate game with Floor General role
        final simWithRole = PossessionSimulation(teamWithRole, opponent);
        final boxScoreWithRole = simWithRole.simulate();
        totalAssistsWithRole += boxScoreWithRole[pgWithFloorGeneral.id]?.assists ?? 0;
      }

      final avgAssistsWithoutRole = totalAssistsWithoutRole / numSimulations;
      final avgAssistsWithRole = totalAssistsWithRole / numSimulations;

      // Floor General should have more assists on average (20% boost)
      // Allow for some variance due to randomness
      expect(avgAssistsWithRole, greaterThan(avgAssistsWithoutRole * 1.05),
          reason: 'Floor General role should increase assists by ~20%');
    });

    test('3-and-D role increases three-point attempts and steals', () {
      // Create a shooting guard
      final sgWithoutRole = Player(
        id: 'sg1',
        name: 'SG Without Role',
        heightInches: 76,
        shooting: 75,
        defense: 75,
        speed: 70,
        postShooting: 60,
        passing: 60,
        rebounding: 50,
        ballHandling: 70,
        threePoint: 85, // High three-point
        blocks: 40,
        steals: 80, // High steals
        position: 'SG',
        roleArchetypeId: null,
      );

      final sgWith3AndD = sgWithoutRole.copyWithRoleArchetype('sg_3_and_d');

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

      final teamWithoutRole = createTestTeam('team1', [sgWithoutRole, ...supportingPlayers]);
      final teamWithRole = createTestTeam('team2', [sgWith3AndD, ...supportingPlayers]);

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
      int totalThreePointAttemptsWithoutRole = 0;
      int totalThreePointAttemptsWithRole = 0;
      int totalStealsWithoutRole = 0;
      int totalStealsWithRole = 0;
      const numSimulations = 50;

      for (int i = 0; i < numSimulations; i++) {
        final simWithoutRole = PossessionSimulation(teamWithoutRole, opponent);
        final boxScoreWithoutRole = simWithoutRole.simulate();
        final statsWithoutRole = boxScoreWithoutRole[sgWithoutRole.id];
        totalThreePointAttemptsWithoutRole += statsWithoutRole?.threePointersAttempted ?? 0;
        totalStealsWithoutRole += statsWithoutRole?.steals ?? 0;

        final simWithRole = PossessionSimulation(teamWithRole, opponent);
        final boxScoreWithRole = simWithRole.simulate();
        final statsWithRole = boxScoreWithRole[sgWith3AndD.id];
        totalThreePointAttemptsWithRole += statsWithRole?.threePointersAttempted ?? 0;
        totalStealsWithRole += statsWithRole?.steals ?? 0;
      }

      final avgThreePointAttemptsWithoutRole = totalThreePointAttemptsWithoutRole / numSimulations;
      final avgThreePointAttemptsWithRole = totalThreePointAttemptsWithRole / numSimulations;
      final avgStealsWithoutRole = totalStealsWithoutRole / numSimulations;
      final avgStealsWithRole = totalStealsWithRole / numSimulations;

      // 3-and-D should have more three-point attempts (+30%) and steals (+25%)
      expect(avgThreePointAttemptsWithRole, greaterThan(avgThreePointAttemptsWithoutRole * 1.1),
          reason: '3-and-D role should increase three-point attempts by ~30%');
      expect(avgStealsWithRole, greaterThan(avgStealsWithoutRole * 1.05),
          reason: '3-and-D role should increase steals by ~25%');
    });

    test('Paint Beast role increases blocks and eliminates three-point attempts', () {
      // Create a center
      final centerWithoutRole = Player(
        id: 'c1',
        name: 'C Without Role',
        heightInches: 84,
        shooting: 65,
        defense: 80,
        speed: 55,
        postShooting: 90, // High post shooting
        passing: 50,
        rebounding: 90,
        ballHandling: 50,
        threePoint: 30,
        blocks: 90, // High blocks
        steals: 55,
        position: 'C',
        roleArchetypeId: null,
      );

      final centerWithPaintBeast = centerWithoutRole.copyWithRoleArchetype('c_paint_beast');

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

      final teamWithoutRole = createTestTeam('team1', [centerWithoutRole, ...supportingPlayers]);
      final teamWithRole = createTestTeam('team2', [centerWithPaintBeast, ...supportingPlayers]);

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
      int totalBlocksWithoutRole = 0;
      int totalBlocksWithRole = 0;
      int totalThreePointAttemptsWithoutRole = 0;
      int totalThreePointAttemptsWithRole = 0;
      const numSimulations = 50;

      for (int i = 0; i < numSimulations; i++) {
        final simWithoutRole = PossessionSimulation(opponent, teamWithoutRole);
        final boxScoreWithoutRole = simWithoutRole.simulate();
        final statsWithoutRole = boxScoreWithoutRole[centerWithoutRole.id];
        totalBlocksWithoutRole += statsWithoutRole?.blocks ?? 0;
        totalThreePointAttemptsWithoutRole += statsWithoutRole?.threePointersAttempted ?? 0;

        final simWithRole = PossessionSimulation(opponent, teamWithRole);
        final boxScoreWithRole = simWithRole.simulate();
        final statsWithRole = boxScoreWithRole[centerWithPaintBeast.id];
        totalBlocksWithRole += statsWithRole?.blocks ?? 0;
        totalThreePointAttemptsWithRole += statsWithRole?.threePointersAttempted ?? 0;
      }

      final avgBlocksWithoutRole = totalBlocksWithoutRole / numSimulations;
      final avgBlocksWithRole = totalBlocksWithRole / numSimulations;
      final avgThreePointAttemptsWithoutRole = totalThreePointAttemptsWithoutRole / numSimulations;
      final avgThreePointAttemptsWithRole = totalThreePointAttemptsWithRole / numSimulations;

      // Paint Beast should have more blocks (+35%)
      expect(avgBlocksWithRole, greaterThan(avgBlocksWithoutRole * 1.1),
          reason: 'Paint Beast role should increase blocks by ~35%');
      
      // Paint Beast should have virtually no three-point attempts (0.0 modifier)
      expect(avgThreePointAttemptsWithRole, lessThan(avgThreePointAttemptsWithoutRole * 0.3),
          reason: 'Paint Beast role should eliminate three-point attempts');
    });
  });
}
