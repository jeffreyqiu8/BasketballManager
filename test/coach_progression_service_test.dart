import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/coach_progression_service.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('CoachProgressionService Tests', () {
    late CoachProfile testCoach;

    setUp(() {
      testCoach = CoachProfile(
        name: 'Test Coach',
        age: 45,
        team: 1,
        experienceYears: 5,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
      );
    });

    test('should return all achievement definitions', () {
      final definitions = CoachProgressionService.getAllAchievementDefinitions();
      
      expect(definitions, isNotEmpty);
      expect(definitions.length, greaterThan(10));
      
      // Check for specific achievements
      final achievementNames = definitions.map((def) => def.name).toList();
      expect(achievementNames, contains('Rookie Coach'));
      expect(achievementNames, contains('Century Mark'));
      expect(achievementNames, contains('Champion'));
    });

    test('should unlock rookie coach achievement after first season', () {
      expect(testCoach.hasAchievement('Rookie Coach'), isFalse);
      
      // Add a season record
      testCoach.history.addSeasonRecord(45, 37, false, false);
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(newAchievements, isNotEmpty);
      expect(testCoach.hasAchievement('Rookie Coach'), isTrue);
    });

    test('should unlock experience-based achievements', () {
      // Create a fresh coach to avoid conflicts with existing achievement system
      final freshCoach = CoachProfile(
        name: 'Fresh Coach',
        age: 40,
        team: 2,
        experienceYears: 2,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.defensive,
        experienceLevel: 5, // Set level directly
      );
      
      expect(freshCoach.hasAchievement('Experienced Coach'), isFalse);
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(freshCoach);
      
      expect(freshCoach.hasAchievement('Experienced Coach'), isTrue);
      expect(newAchievements.any((ach) => ach.name == 'Experienced Coach'), isTrue);
    });

    test('should unlock wins-based achievements', () {
      expect(testCoach.hasAchievement('Century Mark'), isFalse);
      
      // Add enough wins
      testCoach.history.totalWins = 100;
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Century Mark'), isTrue);
    });

    test('should unlock championship achievements', () {
      expect(testCoach.hasAchievement('Champion'), isFalse);
      
      // Add a championship
      testCoach.history.addSeasonRecord(60, 22, true, true);
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Champion'), isTrue);
    });

    test('should calculate game experience correctly', () {
      final experience = CoachProgressionService.calculateGameExperience(
        true, // won
        85, // high performance
        false, // not upset
        true, // blowout
        CoachingSpecialization.offensive,
      );
      
      expect(experience, greaterThan(50)); // Base win experience
    });

    test('should give bonus experience for upsets', () {
      final normalExperience = CoachProgressionService.calculateGameExperience(
        true, 75, false, false, CoachingSpecialization.offensive,
      );
      
      final upsetExperience = CoachProgressionService.calculateGameExperience(
        true, 75, true, false, CoachingSpecialization.offensive,
      );
      
      expect(upsetExperience, greaterThan(normalExperience));
    });

    test('should calculate season experience correctly', () {
      final experience = CoachProgressionService.calculateSeasonExperience(
        55, // wins
        27, // losses
        true, // made playoffs
        false, // didn't win championship
        3, // playoff wins
        CoachingSpecialization.offensive,
      );
      
      expect(experience, greaterThan(200)); // Base season experience
    });

    test('should give championship bonus experience', () {
      final regularExperience = CoachProgressionService.calculateSeasonExperience(
        60, 22, true, false, 8, CoachingSpecialization.offensive,
      );
      
      final championshipExperience = CoachProgressionService.calculateSeasonExperience(
        60, 22, true, true, 16, CoachingSpecialization.offensive,
      );
      
      expect(championshipExperience, greaterThan(regularExperience + 400));
    });

    test('should return coaching abilities for different levels', () {
      final abilities = CoachProgressionService.getCoachingAbilities();
      
      expect(abilities, isNotEmpty);
      expect(abilities.containsKey(1), isTrue);
      expect(abilities.containsKey(5), isTrue);
      expect(abilities.containsKey(10), isTrue);
    });

    test('should return available abilities for coach level', () {
      testCoach.experienceLevel = 5;
      
      final abilities = CoachProgressionService.getAvailableAbilities(testCoach);
      
      expect(abilities, isNotEmpty);
      // Should have abilities from levels 1-5
      expect(abilities.length, greaterThanOrEqualTo(3));
    });

    test('should calculate total effectiveness with abilities', () {
      testCoach.experienceLevel = 10;
      testCoach.coachingAttributes['offensive'] = 80;
      
      final effectiveness = CoachProgressionService.calculateTotalEffectiveness(testCoach);
      
      expect(effectiveness, greaterThan(0.0));
      expect(effectiveness, lessThanOrEqualTo(100.0));
    });

    test('should process season end correctly', () {
      final initialExperience = testCoach.history.totalExperience;
      final initialSeasons = testCoach.history.seasonRecords.length;
      
      CoachProgressionService.processSeasonEnd(
        testCoach,
        50, // wins
        32, // losses
        true, // made playoffs
        false, // didn't win championship
        4, // playoff wins
        ['Player1', 'Player2'], // developed players
      );
      
      expect(testCoach.history.totalExperience, greaterThan(initialExperience));
      expect(testCoach.history.seasonRecords.length, equals(initialSeasons + 1));
      expect(testCoach.history.playersDeveloped.containsKey('Player1'), isTrue);
      expect(testCoach.history.playersDeveloped.containsKey('Player2'), isTrue);
    });

    test('should unlock perfect season achievement', () {
      expect(testCoach.hasAchievement('Perfect Season'), isFalse);
      
      // Add perfect season record
      testCoach.history.addSeasonRecord(82, 0, true, true);
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Perfect Season'), isTrue);
    });

    test('should unlock playoff streak achievement', () {
      expect(testCoach.hasAchievement('Playoff Streak'), isFalse);
      
      // Add 5 consecutive playoff seasons
      for (int i = 0; i < 5; i++) {
        testCoach.history.addSeasonRecord(50, 32, true, false);
      }
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Playoff Streak'), isTrue);
    });

    test('should unlock comeback achievement', () {
      expect(testCoach.hasAchievement('Comeback Kid'), isFalse);
      
      // Add losing season followed by championship
      testCoach.history.addSeasonRecord(30, 52, false, false); // Losing season
      testCoach.history.addSeasonRecord(60, 22, true, true); // Championship season
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Comeback Kid'), isTrue);
    });

    test('should give development coaches bonus experience', () {
      final developmentCoach = CoachProfile(
        name: 'Development Coach',
        age: 40,
        team: 2,
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.playerDevelopment,
      );
      
      final devExperience = CoachProgressionService.calculateGameExperience(
        true, 75, false, false, CoachingSpecialization.playerDevelopment,
      );
      
      final offensiveExperience = CoachProgressionService.calculateGameExperience(
        true, 75, false, false, CoachingSpecialization.offensive,
      );
      
      expect(devExperience, greaterThan(offensiveExperience));
    });

    test('should unlock development achievements', () {
      expect(testCoach.hasAchievement('Player Developer'), isFalse);
      
      // Add developed players
      for (int i = 0; i < 10; i++) {
        testCoach.history.playersDeveloped['Player$i'] = 1;
      }
      
      final newAchievements = CoachProgressionService.checkAndUnlockAchievements(testCoach);
      
      expect(testCoach.hasAchievement('Player Developer'), isTrue);
    });
  });

  group('CoachingAbility Tests', () {
    test('should create coaching ability with correct properties', () {
      final ability = CoachingAbility(
        name: 'Test Ability',
        description: 'Test Description',
        effect: {'teamChemistry': 0.1, 'playerDevelopment': 0.05},
      );

      expect(ability.name, equals('Test Ability'));
      expect(ability.description, equals('Test Description'));
      expect(ability.effect['teamChemistry'], equals(0.1));
      expect(ability.effect['playerDevelopment'], equals(0.05));
    });

    test('should serialize and deserialize coaching ability correctly', () {
      final ability = CoachingAbility(
        name: 'Master Tactician',
        description: 'Boosts all coaching bonuses',
        effect: {'allBonuses': 0.15, 'gamePreparation': 0.1},
      );

      final map = ability.toMap();
      final deserializedAbility = CoachingAbility.fromMap(map);

      expect(deserializedAbility.name, equals(ability.name));
      expect(deserializedAbility.description, equals(ability.description));
      expect(deserializedAbility.effect['allBonuses'], equals(0.15));
      expect(deserializedAbility.effect['gamePreparation'], equals(0.1));
    });
  });
}