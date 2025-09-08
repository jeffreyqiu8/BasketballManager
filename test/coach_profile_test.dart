import 'package:flutter_test/flutter_test.dart';
import '../lib/gameData/enhanced_coach.dart';
import '../lib/gameData/enums.dart';

void main() {
  group('CoachProfile Tests', () {
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
        secondarySpecialization: CoachingSpecialization.defensive,
      );
    });

    test('should create CoachProfile with default values', () {
      expect(testCoach.name, equals('Test Coach'));
      expect(testCoach.primarySpecialization, equals(CoachingSpecialization.offensive));
      expect(testCoach.secondarySpecialization, equals(CoachingSpecialization.defensive));
      expect(testCoach.experienceLevel, equals(1));
      expect(testCoach.coachingAttributes['offensive'], equals(50));
      expect(testCoach.coachingAttributes['defensive'], equals(50));
      expect(testCoach.coachingAttributes['development'], equals(50));
      expect(testCoach.coachingAttributes['chemistry'], equals(50));
      expect(testCoach.achievements, isEmpty);
    });

    test('should calculate team bonuses correctly for offensive specialization', () {
      testCoach.coachingAttributes['offensive'] = 70;
      testCoach.coachingAttributes['defensive'] = 60;
      
      final bonuses = testCoach.calculateTeamBonuses();
      
      // Primary offensive bonus: (70 - 50) * 0.002 = 0.04
      expect(bonuses['offensiveRating'], closeTo(0.04, 0.001));
      // Secondary defensive bonus: (60 - 50) * 0.001 = 0.01
      expect(bonuses['defensiveRating'], closeTo(0.01, 0.001));
    });

    test('should calculate team bonuses with experience multiplier', () {
      testCoach.coachingAttributes['offensive'] = 60;
      testCoach.experienceLevel = 3; // 1.0 + (3-1) * 0.1 = 1.2 multiplier
      
      final bonuses = testCoach.calculateTeamBonuses();
      
      // Base bonus: (60 - 50) * 0.002 = 0.02
      // With multiplier: 0.02 * 1.2 = 0.024
      expect(bonuses['offensiveRating'], closeTo(0.024, 0.001));
    });

    test('should award experience and level up correctly', () {
      expect(testCoach.experienceLevel, equals(1));
      expect(testCoach.history.totalExperience, equals(0));
      
      // Award 1500 experience (should level up to level 2)
      testCoach.awardExperience(1500);
      
      expect(testCoach.history.totalExperience, equals(1500));
      expect(testCoach.experienceLevel, equals(2));
    });

    test('should unlock achievements based on experience level', () {
      expect(testCoach.achievements, isEmpty);
      
      // Award enough experience to reach level 5
      testCoach.awardExperience(4500); // Level 5
      
      expect(testCoach.experienceLevel, equals(5));
      expect(testCoach.hasAchievement('Experienced Coach'), isTrue);
      expect(testCoach.achievements.length, equals(1));
    });

    test('should unlock achievements based on wins', () {
      expect(testCoach.achievements, isEmpty);
      
      // Add enough wins and trigger achievement check
      testCoach.history.totalWins = 100;
      testCoach.checkForNewAchievements();
      
      expect(testCoach.hasAchievement('Century Mark'), isTrue);
    });

    test('should serialize and deserialize correctly', () {
      testCoach.coachingAttributes['offensive'] = 75;
      testCoach.experienceLevel = 3;
      testCoach.awardExperience(2000);
      
      final map = testCoach.toMap();
      final deserializedCoach = CoachProfile.fromMap(map);
      
      expect(deserializedCoach.name, equals(testCoach.name));
      expect(deserializedCoach.primarySpecialization, equals(testCoach.primarySpecialization));
      expect(deserializedCoach.secondarySpecialization, equals(testCoach.secondarySpecialization));
      expect(deserializedCoach.coachingAttributes['offensive'], equals(75));
      expect(deserializedCoach.experienceLevel, equals(3));
      expect(deserializedCoach.history.totalExperience, equals(2000));
    });
  });

  group('Achievement Tests', () {
    test('should create achievement with correct properties', () {
      final achievement = Achievement(
        name: 'Test Achievement',
        description: 'Test Description',
        type: AchievementType.wins,
        unlockedDate: DateTime(2024, 1, 1),
      );

      expect(achievement.name, equals('Test Achievement'));
      expect(achievement.description, equals('Test Description'));
      expect(achievement.type, equals(AchievementType.wins));
      expect(achievement.unlockedDate, equals(DateTime(2024, 1, 1)));
    });

    test('should serialize and deserialize achievement correctly', () {
      final achievement = Achievement(
        name: 'Test Achievement',
        description: 'Test Description',
        type: AchievementType.experience,
        unlockedDate: DateTime(2024, 1, 1),
        metadata: {'value': 100},
      );

      final map = achievement.toMap();
      final deserializedAchievement = Achievement.fromMap(map);

      expect(deserializedAchievement.name, equals(achievement.name));
      expect(deserializedAchievement.description, equals(achievement.description));
      expect(deserializedAchievement.type, equals(achievement.type));
      expect(deserializedAchievement.unlockedDate, equals(achievement.unlockedDate));
      expect(deserializedAchievement.metadata['value'], equals(100));
    });
  });

  group('CoachingHistory Tests', () {
    late CoachingHistory history;

    setUp(() {
      history = CoachingHistory.initial();
    });

    test('should initialize with zero values', () {
      expect(history.totalWins, equals(0));
      expect(history.totalLosses, equals(0));
      expect(history.totalGames, equals(0));
      expect(history.championships, equals(0));
      expect(history.playoffAppearances, equals(0));
      expect(history.winPercentage, equals(0.0));
    });

    test('should add season record correctly', () {
      history.addSeasonRecord(50, 32, true, false);
      
      expect(history.totalWins, equals(50));
      expect(history.totalLosses, equals(32));
      expect(history.totalGames, equals(82));
      expect(history.playoffAppearances, equals(1));
      expect(history.championships, equals(0));
      expect(history.seasonRecords.length, equals(1));
      expect(history.winPercentage, closeTo(0.609, 0.001));
    });

    test('should track championships correctly', () {
      history.addSeasonRecord(60, 22, true, true);
      
      expect(history.championships, equals(1));
      expect(history.playoffAppearances, equals(1));
      expect(history.seasonRecords.first.wonChampionship, isTrue);
    });

    test('should serialize and deserialize correctly', () {
      history.addSeasonRecord(45, 37, true, false);
      history.totalExperience = 1500;
      history.playersDeveloped['Player1'] = 5;
      
      final map = history.toMap();
      final deserializedHistory = CoachingHistory.fromMap(map);
      
      expect(deserializedHistory.totalWins, equals(45));
      expect(deserializedHistory.totalLosses, equals(37));
      expect(deserializedHistory.totalExperience, equals(1500));
      expect(deserializedHistory.playersDeveloped['Player1'], equals(5));
      expect(deserializedHistory.seasonRecords.length, equals(1));
    });
  });

  group('SeasonRecord Tests', () {
    test('should create season record with correct properties', () {
      final record = SeasonRecord(
        season: 1,
        wins: 50,
        losses: 32,
        madePlayoffs: true,
        wonChampionship: false,
        teamName: 'Test Team',
      );

      expect(record.season, equals(1));
      expect(record.wins, equals(50));
      expect(record.losses, equals(32));
      expect(record.madePlayoffs, isTrue);
      expect(record.wonChampionship, isFalse);
      expect(record.teamName, equals('Test Team'));
      expect(record.winPercentage, closeTo(0.609, 0.001));
    });

    test('should serialize and deserialize correctly', () {
      final record = SeasonRecord(
        season: 2,
        wins: 60,
        losses: 22,
        madePlayoffs: true,
        wonChampionship: true,
        teamName: 'Champions',
      );

      final map = record.toMap();
      final deserializedRecord = SeasonRecord.fromMap(map);

      expect(deserializedRecord.season, equals(2));
      expect(deserializedRecord.wins, equals(60));
      expect(deserializedRecord.losses, equals(22));
      expect(deserializedRecord.madePlayoffs, isTrue);
      expect(deserializedRecord.wonChampionship, isTrue);
      expect(deserializedRecord.teamName, equals('Champions'));
    });
  });
}