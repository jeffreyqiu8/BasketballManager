import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/development_service.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('DevelopmentService Tests', () {
    late EnhancedPlayer testPlayer;
    late CoachProfile testCoach;

    setUp(() {
      testPlayer = EnhancedPlayer(
        name: 'Test Player',
        age: 22,
        team: 'Test Team',
        experienceYears: 2,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 200,
        shooting: 70,
        rebounding: 65,
        passing: 60,
        ballHandling: 55,
        perimeterDefense: 60,
        postDefense: 70,
        insideShooting: 75,
        performances: {},
        primaryRole: PlayerRole.powerForward,
        potential: PlayerPotential.fromTier(PotentialTier.gold),
        development: DevelopmentTracker.initial(age: 22),
      );

      testCoach = CoachProfile(
        name: 'Test Coach',
        age: 45,
        team: 1,
        experienceYears: 10,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 70,
          'defensive': 60,
          'development': 85,
          'chemistry': 65,
        },
        experienceLevel: 3,
      );
    });

    test('should award game experience correctly', () {
      final gameStats = {
        'points': 20,
        'rebounds': 10,
        'assists': 5,
        'FGM': 8,
        'FGA': 15,
        '3PM': 2,
        '3PA': 5,
      };

      final initialExp = testPlayer.development.totalExperience;
      
      DevelopmentService.awardGameExperience(testPlayer, gameStats);
      
      expect(testPlayer.development.totalExperience, greaterThan(initialExp));
      expect(testPlayer.development.skillExperience['shooting'], greaterThan(0));
      expect(testPlayer.development.skillExperience['rebounding'], greaterThan(0));
    });

    test('should award experience with coaching bonuses', () {
      final gameStats = {
        'points': 15,
        'rebounds': 8,
        'assists': 3,
        'FGM': 6,
        'FGA': 12,
        '3PM': 1,
        '3PA': 3,
      };

      final initialExp = testPlayer.development.totalExperience;
      
      DevelopmentService.awardExperienceWithCoaching(testPlayer, gameStats, testCoach);
      
      expect(testPlayer.development.totalExperience, greaterThan(initialExp));
      
      // Award same stats without coach
      final player2 = EnhancedPlayer.fromPlayer(testPlayer);
      DevelopmentService.awardGameExperience(player2, gameStats);
      
      // Player with coach should have more experience
      expect(testPlayer.development.totalExperience, greaterThan(player2.development.totalExperience));
    });

    test('should award training experience correctly', () {
      final initialShootingExp = testPlayer.development.skillExperience['shooting']!;
      
      DevelopmentService.awardTrainingExperience(
        testPlayer, 
        'shooting', 
        5, // training intensity
        testCoach
      );
      
      expect(testPlayer.development.skillExperience['shooting'], greaterThan(initialShootingExp));
      expect(testPlayer.development.totalExperience, greaterThan(0));
    });

    test('should process skill development correctly', () {
      // Give player enough experience to upgrade
      testPlayer.development.addSkillExperience('shooting', 200);
      
      final initialShooting = testPlayer.shooting;
      final upgradedSkills = DevelopmentService.processSkillDevelopment(testPlayer);
      
      expect(upgradedSkills, contains('shooting'));
      expect(testPlayer.shooting, greaterThan(initialShooting));
    });

    test('should update development rate correctly', () {
      final initialRate = testPlayer.development.developmentRate;
      
      DevelopmentService.updateDevelopmentRate(testPlayer, testCoach);
      
      expect(testPlayer.development.developmentRate, greaterThan(initialRate));
    });

    test('should calculate potential tier correctly', () {
      // Test young high-skill player
      testPlayer.shooting = 85;
      testPlayer.rebounding = 85;
      testPlayer.passing = 80;
      testPlayer.ballHandling = 75;
      testPlayer.perimeterDefense = 80;
      testPlayer.postDefense = 85;
      testPlayer.insideShooting = 90;
      testPlayer.age = 20;
      
      final tier = DevelopmentService.calculatePotentialTier(testPlayer);
      expect(tier, isIn([PotentialTier.gold, PotentialTier.elite]));
      
      // Test older lower-skill player
      testPlayer.age = 30;
      testPlayer.shooting = 60;
      testPlayer.rebounding = 60;
      testPlayer.passing = 55;
      testPlayer.ballHandling = 50;
      testPlayer.perimeterDefense = 55;
      testPlayer.postDefense = 60;
      testPlayer.insideShooting = 65;
      
      final olderTier = DevelopmentService.calculatePotentialTier(testPlayer);
      expect(olderTier, isIn([PotentialTier.bronze, PotentialTier.silver]));
    });

    test('should generate realistic player potential', () {
      final potential = DevelopmentService.generatePlayerPotential(20, PlayerRole.center);
      
      expect(potential.tier, isNotNull);
      expect(potential.maxSkills.length, 7);
      expect(potential.overallPotential, greaterThan(50));
      
      // Centers should have higher rebounding and post defense potential
      expect(potential.maxSkills['rebounding']!, greaterThanOrEqualTo(potential.maxSkills['ballHandling']!));
      expect(potential.maxSkills['postDefense']!, greaterThanOrEqualTo(potential.maxSkills['passing']!));
    });

    test('should distribute experience based on performance', () {
      final gameStats = {
        'points': 25, // High scoring
        'rebounds': 2, // Low rebounding
        'assists': 8, // High assists
        'FGM': 10,
        'FGA': 18,
        '3PM': 3,
        '3PA': 7,
      };

      DevelopmentService.awardGameExperience(testPlayer, gameStats);
      
      // Should have more shooting and passing experience due to high points and assists
      expect(testPlayer.development.skillExperience['shooting'], greaterThan(0));
      expect(testPlayer.development.skillExperience['passing'], greaterThan(0));
      expect(testPlayer.development.skillExperience['ballHandling'], greaterThan(0));
    });

    test('should apply age-based development modifiers', () {
      // Young player should develop faster
      final youngPlayer = EnhancedPlayer.fromPlayer(testPlayer);
      youngPlayer.age = 19;
      
      // Old player should develop slower
      final oldPlayer = EnhancedPlayer.fromPlayer(testPlayer);
      oldPlayer.age = 35;
      
      final gameStats = {
        'points': 15,
        'rebounds': 8,
        'assists': 3,
        'FGM': 6,
        'FGA': 12,
        '3PM': 1,
        '3PA': 3,
      };

      DevelopmentService.awardGameExperience(youngPlayer, gameStats);
      DevelopmentService.awardGameExperience(oldPlayer, gameStats);
      
      expect(youngPlayer.development.totalExperience, greaterThan(oldPlayer.development.totalExperience));
    });

    test('should handle role-specific potential adjustments', () {
      final pgPotential = DevelopmentService.generatePlayerPotential(22, PlayerRole.pointGuard);
      final centerPotential = DevelopmentService.generatePlayerPotential(22, PlayerRole.center);
      
      // Point guards should have higher ball handling and passing potential
      expect(pgPotential.maxSkills['ballHandling']!, greaterThanOrEqualTo(centerPotential.maxSkills['ballHandling']!));
      expect(pgPotential.maxSkills['passing']!, greaterThanOrEqualTo(centerPotential.maxSkills['passing']!));
      
      // Centers should have higher rebounding and post defense potential
      expect(centerPotential.maxSkills['rebounding']!, greaterThanOrEqualTo(pgPotential.maxSkills['rebounding']!));
      expect(centerPotential.maxSkills['postDefense']!, greaterThanOrEqualTo(pgPotential.maxSkills['postDefense']!));
    });

    test('should respect potential limits when upgrading skills', () {
      // Set a low potential for shooting
      testPlayer.potential.maxSkills['shooting'] = 72;
      testPlayer.shooting = 71;
      
      // Give lots of experience
      testPlayer.development.addSkillExperience('shooting', 500);
      
      final upgradedSkills = DevelopmentService.processSkillDevelopment(testPlayer);
      
      // Should only upgrade once due to potential limit
      expect(testPlayer.shooting, lessThanOrEqualTo(72));
    });

    test('should calculate coach development bonus correctly', () {
      final developmentCoach = CoachProfile(
        name: 'Dev Coach',
        age: 50,
        team: 1,
        experienceYears: 15,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 60,
          'defensive': 55,
          'development': 90,
          'chemistry': 70,
        },
        experienceLevel: 5,
      );

      final bonus = developmentCoach.getDevelopmentBonus();
      expect(bonus, greaterThan(0.0));
      expect(bonus, lessThanOrEqualTo(0.5)); // Should not exceed 50%
    });
  });
}