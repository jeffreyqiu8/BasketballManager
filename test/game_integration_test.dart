import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/enhanced_game_simulation.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/gameData/player_class.dart';

void main() {
  group('Game Integration Tests', () {
    late EnhancedTeam homeTeam;
    late EnhancedTeam awayTeam;
    late CoachProfile homeCoach;
    late CoachProfile awayCoach;

    setUp(() {
      // Create enhanced players for home team
      final homePlayers = List.generate(5, (index) => EnhancedPlayer(
        name: 'Home Player ${index + 1}',
        age: 25 + index,
        team: '0',
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 200 + index * 5,
        shooting: 75 + index * 2,
        rebounding: 70 + index * 3,
        passing: 65 + index * 2,
        ballHandling: 70 + index * 2,
        perimeterDefense: 75 + index,
        postDefense: 70 + index * 2,
        insideShooting: 72 + index * 2,
        performances: {},
        primaryRole: PlayerRole.values[index],
        potential: PlayerPotential.fromTier(PotentialTier.gold),
        development: DevelopmentTracker.initial(age: 25 + index),
      ));

      // Create enhanced players for away team
      final awayPlayers = List.generate(5, (index) => EnhancedPlayer(
        name: 'Away Player ${index + 1}',
        age: 24 + index,
        team: '1',
        experienceYears: 2,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 198 + index * 5,
        shooting: 73 + index * 2,
        rebounding: 68 + index * 3,
        passing: 63 + index * 2,
        ballHandling: 68 + index * 2,
        perimeterDefense: 73 + index,
        postDefense: 68 + index * 2,
        insideShooting: 70 + index * 2,
        performances: {},
        primaryRole: PlayerRole.values[index],
        potential: PlayerPotential.fromTier(PotentialTier.silver),
        development: DevelopmentTracker.initial(age: 24 + index),
      ));

      // Create enhanced teams
      homeTeam = EnhancedTeam(
        name: 'Home Team',
        reputation: 80,
        playerCount: 5,
        teamSize: 5,
        players: homePlayers.cast<Player>(),
      );

      awayTeam = EnhancedTeam(
        name: 'Away Team',
        reputation: 75,
        playerCount: 5,
        teamSize: 5,
        players: awayPlayers.cast<Player>(),
      );

      // Create coaches
      homeCoach = CoachProfile(
        name: 'Home Coach',
        age: 45,
        team: 0,
        experienceYears: 10,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
        secondarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 85,
          'defensive': 70,
          'development': 80,
          'chemistry': 75,
        },
        experienceLevel: 5,
      );

      awayCoach = CoachProfile(
        name: 'Away Coach',
        age: 50,
        team: 1,
        experienceYears: 15,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.defensive,
        secondarySpecialization: CoachingSpecialization.teamChemistry,
        coachingAttributes: {
          'offensive': 70,
          'defensive': 90,
          'development': 65,
          'chemistry': 85,
        },
        experienceLevel: 7,
      );

      // Set up playbooks
      final homePlaybook = Playbook(
        name: 'Fast Break Offense',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.manToMan,
        strategyWeights: {'pace': 0.2, 'shooting': 0.1},
        teamRequirements: {'ballHandling': 75, 'shooting': 70},
      );
      homeTeam.playbookLibrary.addPlaybook(homePlaybook);
      homeTeam.playbookLibrary.setActivePlaybook(homePlaybook.name);

      final awayPlaybook = Playbook(
        name: 'Defensive Focus',
        offensiveStrategy: OffensiveStrategy.halfCourt,
        defensiveStrategy: DefensiveStrategy.zoneDefense,
        strategyWeights: {'defense': 0.2, 'rebounding': 0.1},
        teamRequirements: {'defense': 80, 'rebounding': 75},
      );
      awayTeam.playbookLibrary.addPlaybook(awayPlaybook);
      awayTeam.playbookLibrary.setActivePlaybook(awayPlaybook.name);
    });

    test('should integrate all systems in game simulation', () {
      // Run game simulation with all systems
      final result = EnhancedGameSimulation.simulateGame(
        homeTeam,
        awayTeam,
        1,
        homeCoach: homeCoach,
        awayCoach: awayCoach,
      );

      // Verify basic game results
      expect(result['homeScore'], isA<int>());
      expect(result['awayScore'], isA<int>());
      expect(result['homeBoxScore'], isA<Map<String, Map<String, int>>>());
      expect(result['awayBoxScore'], isA<Map<String, Map<String, int>>>());

      // Verify coaching effectiveness is calculated
      expect(result['homeCoachingEffectiveness'], isA<double>());
      expect(result['awayCoachingEffectiveness'], isA<double>());
      expect(result['homeCoachingEffectiveness'], greaterThan(0.0));
      expect(result['awayCoachingEffectiveness'], greaterThan(0.0));

      // Verify scores are realistic
      final homeScore = result['homeScore'] as int;
      final awayScore = result['awayScore'] as int;
      expect(homeScore, greaterThan(60));
      expect(homeScore, lessThan(150));
      expect(awayScore, greaterThan(60));
      expect(awayScore, lessThan(150));
    });

    test('should award player development experience', () {
      // Get initial experience levels
      final homePlayer = homeTeam.players.first as EnhancedPlayer;
      final initialExperience = homePlayer.development.totalExperience;

      // Run simulation
      EnhancedGameSimulation.simulateGame(
        homeTeam,
        awayTeam,
        1,
        homeCoach: homeCoach,
        awayCoach: awayCoach,
      );

      // Verify experience was awarded
      expect(homePlayer.development.totalExperience, greaterThan(initialExperience));
    });

    test('should update coach progression', () {
      // Get initial coach experience
      final initialCoachExperience = homeCoach.history.totalExperience;

      // Run simulation
      EnhancedGameSimulation.simulateGame(
        homeTeam,
        awayTeam,
        1,
        homeCoach: homeCoach,
        awayCoach: awayCoach,
      );

      // Verify coach gained experience
      expect(homeCoach.history.totalExperience, greaterThan(initialCoachExperience));
    });

    test('should apply coaching bonuses to game simulation', () {
      // Create a coach with very high offensive bonuses
      final superOffensiveCoach = CoachProfile(
        name: 'Super Offensive Coach',
        age: 55,
        team: 0,
        experienceYears: 20,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
        coachingAttributes: {
          'offensive': 99,
          'defensive': 50,
          'development': 50,
          'chemistry': 50,
        },
        experienceLevel: 15,
      );

      // Run multiple simulations to get average scores
      int totalHomeScoreWithCoach = 0;
      int totalHomeScoreWithoutCoach = 0;
      const simulations = 10;

      for (int i = 0; i < simulations; i++) {
        // With coach
        final resultWithCoach = EnhancedGameSimulation.simulateGame(
          homeTeam,
          awayTeam,
          i + 1,
          homeCoach: superOffensiveCoach,
        );
        totalHomeScoreWithCoach += resultWithCoach['homeScore'] as int;

        // Without coach
        final resultWithoutCoach = EnhancedGameSimulation.simulateGame(
          homeTeam,
          awayTeam,
          i + 1,
        );
        totalHomeScoreWithoutCoach += resultWithoutCoach['homeScore'] as int;
      }

      final avgScoreWithCoach = totalHomeScoreWithCoach / simulations;
      final avgScoreWithoutCoach = totalHomeScoreWithoutCoach / simulations;

      // Offensive coach should generally lead to higher scores
      // (This is probabilistic, so we allow some variance)
      expect(avgScoreWithCoach, greaterThanOrEqualTo(avgScoreWithoutCoach * 0.95));
    });

    test('should integrate playbook effects with coaching bonuses', () {
      // Set up a three-point heavy playbook
      final threePointPlaybook = Playbook(
        name: 'Three Point Heavy',
        offensiveStrategy: OffensiveStrategy.threePointHeavy,
        defensiveStrategy: DefensiveStrategy.manToMan,
        strategyWeights: {'threePointShooting': 0.3, 'spacing': 0.2},
        teamRequirements: {'shooting': 80},
      );
      homeTeam.playbookLibrary.addPlaybook(threePointPlaybook);
      homeTeam.playbookLibrary.setActivePlaybook(threePointPlaybook.name);

      // Run simulation
      final result = EnhancedGameSimulation.simulateGame(
        homeTeam,
        awayTeam,
        1,
        homeCoach: homeCoach,
        awayCoach: awayCoach,
      );

      // Verify the simulation completed successfully
      expect(result['homeScore'], isA<int>());
      expect(result['awayScore'], isA<int>());

      // Check that box scores include three-point attempts
      final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
      int total3PA = 0;
      for (final playerStats in homeBoxScore.values) {
        total3PA += playerStats['3PA'] ?? 0;
      }
      
      // Should have some three-point attempts with three-point heavy strategy
      expect(total3PA, greaterThan(0));
    });

    test('should handle role-based performance modifiers', () {
      // Assign optimal roles to all players
      for (int i = 0; i < homeTeam.players.length; i++) {
        final player = homeTeam.players[i] as EnhancedPlayer;
        player.assignPrimaryRole(PlayerRole.values[i]);
      }

      // Run simulation
      final result = EnhancedGameSimulation.simulateGame(
        homeTeam,
        awayTeam,
        1,
        homeCoach: homeCoach,
        awayCoach: awayCoach,
      );

      // Verify role experience was awarded
      final homePlayer = homeTeam.players.first as EnhancedPlayer;
      expect(homePlayer.roleExperience[homePlayer.primaryRole], greaterThan(0.0));
    });
  });
}