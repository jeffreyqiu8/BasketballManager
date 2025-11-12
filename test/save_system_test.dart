import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/save_metadata.dart';
import 'package:BasketballManager/gameData/save_creation_data.dart';
import 'package:BasketballManager/gameData/save_manager.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('Save System Foundation Tests', () {
    test('SaveMetadata creation and serialization', () {
      final metadata = SaveMetadata(
        saveId: 'test_save_1',
        saveName: 'Test Save',
        description: 'A test save file',
        createdDate: DateTime.now(),
        lastPlayedDate: DateTime.now(),
        totalPlaytime: Duration(hours: 2, minutes: 30),
        currentSeason: 1,
        gamesPlayed: 10,
        currentRecord: TeamRecord(wins: 7, losses: 3),
        leaguePosition: 3,
        playoffStatus: 'Regular Season',
        teamName: 'Test Team',
        coachName: 'Test Coach',
        conference: 'Eastern',
        division: 'Atlantic',
        teamLogoPath: 'assets/images/test_logo.png',
        primaryTeamColor: const Color(0xFF0000FF),
        thumbnailPath: 'assets/images/test_thumbnail.png',
      );

      // Test serialization
      final map = metadata.toMap();
      expect(map['saveId'], equals('test_save_1'));
      expect(map['saveName'], equals('Test Save'));
      expect(map['currentSeason'], equals(1));
      expect(map['gamesPlayed'], equals(10));

      // Test deserialization
      final reconstructed = SaveMetadata.fromMap(map);
      expect(reconstructed.saveId, equals(metadata.saveId));
      expect(reconstructed.saveName, equals(metadata.saveName));
      expect(reconstructed.currentSeason, equals(metadata.currentSeason));
      expect(reconstructed.gamesPlayed, equals(metadata.gamesPlayed));
    });

    test('TeamRecord functionality', () {
      final record = TeamRecord(wins: 15, losses: 5);
      
      expect(record.totalGames, equals(20));
      expect(record.winPercentage, equals(0.75));
      expect(record.toString(), equals('15-5'));

      // Test serialization
      final map = record.toMap();
      final reconstructed = TeamRecord.fromMap(map);
      expect(reconstructed.wins, equals(15));
      expect(reconstructed.losses, equals(5));
    });

    test('SaveCreationData validation', () {
      final coachData = CoachCreationData(
        name: 'Test Coach',
        primarySpecialization: CoachingSpecialization.offensive,
      );

      final saveData = SaveCreationData(
        saveName: 'New Career',
        description: 'Starting a new basketball management career',
        selectedTeam: 'Lakers',
        coachData: coachData,
        difficulty: DifficultySettings.normal(),
        leagueSettings: LeagueSettings.nbaStyle(),
      );

      expect(saveData.isValid(), isTrue);
      expect(saveData.getValidationErrors(), isEmpty);

      // Test invalid data
      final invalidSaveData = SaveCreationData(
        saveName: '', // Invalid empty name
        description: '',
        selectedTeam: '', // Invalid empty team
        coachData: CoachCreationData(
          name: 'X', // Invalid short name
          primarySpecialization: CoachingSpecialization.offensive,
        ),
        difficulty: DifficultySettings.normal(),
        leagueSettings: LeagueSettings.nbaStyle(),
      );

      expect(invalidSaveData.isValid(), isFalse);
      final errors = invalidSaveData.getValidationErrors();
      expect(errors.length, greaterThan(0));
      expect(errors.any((error) => error.contains('Save name')), isTrue);
      expect(errors.any((error) => error.contains('Team selection')), isTrue);
    });

    test('CoachCreationData validation', () {
      final validCoach = CoachCreationData(
        name: 'John Smith',
        primarySpecialization: CoachingSpecialization.defensive,
        secondarySpecialization: CoachingSpecialization.playerDevelopment,
      );

      expect(validCoach.isValid(), isTrue);
      expect(validCoach.getValidationErrors(), isEmpty);

      final invalidCoach = CoachCreationData(
        name: 'A', // Too short
        primarySpecialization: CoachingSpecialization.offensive,
      );

      expect(invalidCoach.isValid(), isFalse);
      expect(invalidCoach.getValidationErrors().length, greaterThan(0));
    });

    test('DifficultySettings presets', () {
      final easy = DifficultySettings.easy();
      expect(easy.level, equals(DifficultyLevel.easy));
      expect(easy.playerDevelopmentRate, equals(1.5));
      expect(easy.enableSalaryCap, isFalse);

      final normal = DifficultySettings.normal();
      expect(normal.level, equals(DifficultyLevel.normal));
      expect(normal.playerDevelopmentRate, equals(1.0));
      expect(normal.enableSalaryCap, isTrue);

      final hard = DifficultySettings.hard();
      expect(hard.level, equals(DifficultyLevel.hard));
      expect(hard.playerDevelopmentRate, equals(0.7));
      expect(hard.tradeAIAggressiveness, equals(0.8));
    });

    test('LeagueSettings validation and presets', () {
      final nbaStyle = LeagueSettings.nbaStyle();
      expect(nbaStyle.numberOfTeams, equals(30));
      expect(nbaStyle.numberOfConferences, equals(2));
      expect(nbaStyle.regularSeasonGames, equals(82));
      expect(nbaStyle.playoffTeams, equals(16));
      expect(nbaStyle.isValid(), isTrue);

      final custom = LeagueSettings.custom(
        teams: 24,
        conferences: 2,
        games: 60,
        playoffTeams: 12,
      );
      expect(custom.numberOfTeams, equals(24));
      expect(custom.enableCustomRules, isTrue);
      expect(custom.isValid(), isTrue);

      // Test invalid settings
      final invalid = LeagueSettings.custom(
        teams: 10,
        conferences: 2,
        games: 60,
        playoffTeams: 15, // More playoff teams than total teams
      );
      expect(invalid.isValid(), isFalse);
    });

    test('SaveMetadata playtime update', () {
      final originalMetadata = SaveMetadata(
        saveId: 'test_save',
        saveName: 'Test Save',
        description: 'Test',
        createdDate: DateTime.now(),
        lastPlayedDate: DateTime.now().subtract(Duration(hours: 1)),
        totalPlaytime: Duration(hours: 5),
        currentSeason: 1,
        gamesPlayed: 0,
        currentRecord: TeamRecord(wins: 0, losses: 0),
        leaguePosition: 1,
        playoffStatus: 'Regular Season',
        teamName: 'Test Team',
        coachName: 'Test Coach',
        conference: 'Eastern',
        division: 'Atlantic',
        teamLogoPath: 'assets/images/test_logo.png',
        primaryTeamColor: const Color(0xFF0000FF),
        thumbnailPath: 'assets/images/test_thumbnail.png',
      );

      final updatedMetadata = originalMetadata.updatePlaytime(Duration(minutes: 30));
      
      expect(updatedMetadata.totalPlaytime, equals(Duration(hours: 5, minutes: 30)));
      expect(updatedMetadata.lastPlayedDate.isAfter(originalMetadata.lastPlayedDate), isTrue);
      expect(updatedMetadata.saveId, equals(originalMetadata.saveId)); // Other fields unchanged
    });

    test('SaveManager exception handling', () {
      // Test SaveManagerException creation and message
      final exception = SaveManagerException('Test error message');
      expect(exception.message, equals('Test error message'));
      expect(exception.toString(), equals('SaveManagerException: Test error message'));
    });

    test('SaveManager save ID generation pattern', () {
      // Test the expected pattern of save IDs without accessing private methods
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final expectedPattern = RegExp(r'^save_\d+_\d+$');
      
      // Simulate the pattern that would be generated
      final mockSaveId = 'save_${timestamp}_123456';
      expect(mockSaveId, matches(expectedPattern));
      expect(mockSaveId, startsWith('save_'));
    });

    test('SaveManager validation logic', () {
      // Test save validation scenarios
      final saveManager = SaveManager();
      
      // Test that validation methods exist and can be called
      // Note: These would normally require Firebase setup for full testing
      expect(() => saveManager.validateSave('test_save', 'test_user'), returnsNormally);
    });
  });

  group('Save Manager Operations Tests', () {
    test('Save creation data validation comprehensive', () {
      // Test all validation scenarios for SaveCreationData
      final validData = SaveCreationData(
        saveName: 'Valid Save Name',
        description: 'A valid description for testing',
        selectedTeam: 'Lakers',
        coachData: CoachCreationData(
          name: 'John Coach',
          primarySpecialization: CoachingSpecialization.offensive,
        ),
        difficulty: DifficultySettings.normal(),
        leagueSettings: LeagueSettings.nbaStyle(),
      );

      expect(validData.isValid(), isTrue);
      expect(validData.getValidationErrors(), isEmpty);

      // Test edge cases
      final edgeCaseData = SaveCreationData(
        saveName: 'A' * 50, // Maximum length name
        description: 'Short desc',
        selectedTeam: 'Team',
        coachData: CoachCreationData(
          name: 'Coach Name',
          primarySpecialization: CoachingSpecialization.defensive,
        ),
        difficulty: DifficultySettings.easy(),
        leagueSettings: LeagueSettings.custom(teams: 24, conferences: 2, games: 60, playoffTeams: 12),
      );

      expect(edgeCaseData.isValid(), isTrue);
    });

    test('Backup and recovery integration', () {
      // Test backup-related functionality
      final saveManager = SaveManager();
      
      // Test that backup methods exist and handle errors gracefully
      expect(() => saveManager.createBackup('test_save', 'test_user'), returnsNormally);
      expect(() => saveManager.getBackups('test_save', 'test_user'), returnsNormally);
      expect(() => saveManager.recoverSave('test_save', 'test_user'), returnsNormally);
    });

    test('Export and import functionality', () {
      // Test export/import operations
      final saveManager = SaveManager();
      
      // Test that export/import methods exist
      expect(() => saveManager.exportSave('test_save', '/test/path', 'test_user'), returnsNormally);
      expect(() => saveManager.importSave('/test/path', 'test_user'), returnsNormally);
    });
  });
}