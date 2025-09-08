import 'package:flutter_test/flutter_test.dart';
import '../lib/gameData/coaching_service.dart';
import '../lib/gameData/enhanced_coach.dart';
import '../lib/gameData/enhanced_player.dart';
import '../lib/gameData/enums.dart';

void main() {
  group('CoachingService Tests', () {
    late CoachProfile offensiveCoach;
    late CoachProfile defensiveCoach;
    late CoachProfile developmentCoach;
    late EnhancedPlayer youngPlayer;
    late EnhancedPlayer veteranPlayer;

    setUp(() {
      offensiveCoach = CoachProfile(
        name: 'Offensive Coach',
        age: 45,
        team: 1,
        experienceYears: 5,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
        coachingAttributes: {
          'offensive': 80,
          'defensive': 60,
          'development': 50,
          'chemistry': 55,
        },
        experienceLevel: 3,
      );

      defensiveCoach = CoachProfile(
        name: 'Defensive Coach',
        age: 50,
        team: 2,
        experienceYears: 8,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.defensive,
        coachingAttributes: {
          'offensive': 55,
          'defensive': 85,
          'development': 60,
          'chemistry': 50,
        },
        experienceLevel: 4,
      );

      developmentCoach = CoachProfile(
        name: 'Development Coach',
        age: 40,
        team: 3,
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 60,
          'defensive': 55,
          'development': 90,
          'chemistry': 65,
        },
        experienceLevel: 2,
      );

      youngPlayer = EnhancedPlayer(
        name: 'Young Player',
        age: 22,
        team: '1',
        experienceYears: 2,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 185,
        shooting: 75,
        rebounding: 60,
        passing: 80,
        ballHandling: 85,
        perimeterDefense: 70,
        postDefense: 50,
        insideShooting: 65,
        performances: {},
        primaryRole: PlayerRole.pointGuard,
      );

      veteranPlayer = EnhancedPlayer(
        name: 'Veteran Player',
        age: 32,
        team: '1',
        experienceYears: 12,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 210,
        shooting: 60,
        rebounding: 90,
        passing: 65,
        ballHandling: 50,
        perimeterDefense: 75,
        postDefense: 95,
        insideShooting: 85,
        performances: {},
        primaryRole: PlayerRole.center,
      );
    });

    test('should calculate team bonuses correctly', () {
      final bonuses = CoachingService.calculateTeamBonuses(offensiveCoach);
      
      // Should have offensive bonus from primary specialization
      expect(bonuses.containsKey('offensiveRating'), isTrue);
      expect(bonuses['offensiveRating'], greaterThan(0.0));
    });

    test('should apply coaching bonuses to team stats', () {
      final baseStats = {
        'offensiveRating': 100.0,
        'defensiveRating': 100.0,
        'fieldGoalPercentage': 0.45,
        'assistsPerGame': 25.0,
      };

      final enhancedStats = CoachingService.applyCoachingBonuses(baseStats, offensiveCoach);

      // Offensive coach should improve offensive stats
      expect(enhancedStats['offensiveRating'], greaterThan(baseStats['offensiveRating']!));
      expect(enhancedStats['fieldGoalPercentage'], greaterThan(baseStats['fieldGoalPercentage']!));
    });

    test('should calculate development rate modifier for development coach', () {
      final modifier = CoachingService.calculateDevelopmentRateModifier(
        developmentCoach,
        youngPlayer,
      );

      // Development coach with young player should have bonus modifier
      expect(modifier, greaterThan(1.0));
    });

    test('should calculate higher development rate for young players', () {
      final youngModifier = CoachingService.calculateDevelopmentRateModifier(
        developmentCoach,
        youngPlayer,
      );
      
      final veteranModifier = CoachingService.calculateDevelopmentRateModifier(
        developmentCoach,
        veteranPlayer,
      );

      // Young players should get higher development rate
      expect(youngModifier, greaterThan(veteranModifier));
    });

    test('should apply coaching to experience gain', () {
      const baseExperience = 100;
      
      final enhancedExperience = CoachingService.applyCoachingToExperience(
        baseExperience,
        developmentCoach,
        youngPlayer,
      );

      // Development coach should increase experience gain
      expect(enhancedExperience, greaterThan(baseExperience));
    });

    test('should calculate coaching effectiveness', () {
      final effectiveness = CoachingService.calculateCoachingEffectiveness(offensiveCoach);
      
      expect(effectiveness, greaterThanOrEqualTo(0.0));
      expect(effectiveness, lessThanOrEqualTo(100.0));
    });

    test('should provide coaching recommendations', () {
      final teamRoster = [youngPlayer, veteranPlayer];
      
      final recommendations = CoachingService.getCoachingRecommendations(
        developmentCoach,
        teamRoster,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations, isA<List<String>>());
    });

    test('should update coach after game', () {
      final initialExperience = developmentCoach.history.totalExperience;
      
      CoachingService.updateCoachAfterGame(
        developmentCoach,
        true, // won
        85, // high performance rating
        [youngPlayer], // developed players
      );

      expect(developmentCoach.history.totalExperience, greaterThan(initialExperience));
    });

    test('should calculate coaching salary based on effectiveness', () {
      final salary = CoachingService.calculateCoachingSalary(offensiveCoach);
      
      expect(salary, greaterThan(0));
      expect(salary, isA<int>());
    });

    test('should give higher salary to more effective coaches', () {
      // Create a highly effective coach
      final eliteCoach = CoachProfile(
        name: 'Elite Coach',
        age: 55,
        team: 4,
        experienceYears: 15,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
        coachingAttributes: {
          'offensive': 95,
          'defensive': 90,
          'development': 85,
          'chemistry': 90,
        },
        experienceLevel: 10,
      );
      
      // Add some achievements and wins
      eliteCoach.history.addSeasonRecord(60, 22, true, true);
      eliteCoach.awardExperience(5000);

      final regularSalary = CoachingService.calculateCoachingSalary(offensiveCoach);
      final eliteSalary = CoachingService.calculateCoachingSalary(eliteCoach);

      expect(eliteSalary, greaterThan(regularSalary));
    });

    test('should provide different bonuses for different specializations', () {
      final offensiveBonuses = CoachingService.calculateTeamBonuses(offensiveCoach);
      final defensiveBonuses = CoachingService.calculateTeamBonuses(defensiveCoach);

      // Offensive coach should have offensive bonuses
      expect(offensiveBonuses.containsKey('offensiveRating'), isTrue);
      
      // Defensive coach should have defensive bonuses
      expect(defensiveBonuses.containsKey('defensiveRating'), isTrue);
    });

    test('should track player development for development coaches', () {
      final initialDeveloped = developmentCoach.history.playersDeveloped.length;
      
      CoachingService.updateCoachAfterGame(
        developmentCoach,
        true,
        75,
        [youngPlayer, veteranPlayer],
      );

      expect(developmentCoach.history.playersDeveloped.length, 
             greaterThanOrEqualTo(initialDeveloped));
      expect(developmentCoach.history.playersDeveloped.containsKey(youngPlayer.name), 
             isTrue);
    });
  });
}