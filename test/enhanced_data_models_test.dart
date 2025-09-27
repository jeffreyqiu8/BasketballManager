import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/enhanced_data_models.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('Enhanced Data Models Tests', () {
    late Player testPlayer;
    late PlayerEnhancement playerEnhancement;
    late CoachEnhancement coachEnhancement;
    late TeamEnhancement teamEnhancement;

    setUp(() {
      testPlayer = Player(
        name: 'Test Player',
        age: 25,
        team: 'Test Team',
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 195,
        shooting: 70,
        rebounding: 60,
        passing: 65,
        ballHandling: 60,
        perimeterDefense: 65,
        postDefense: 55,
        insideShooting: 60,
        performances: {},
      );

      playerEnhancement = PlayerEnhancement(
        playerId: 'test-player-1',
        primaryRole: PlayerRole.smallForward,
      );

      coachEnhancement = CoachEnhancement(
        coachId: 'test-coach-1',
        primarySpecialization: CoachingSpecialization.offensive,
      );

      teamEnhancement = TeamEnhancement(
        teamId: 'test-team-1',
      );
    });

    group('PlayerEnhancement Tests', () {
      test('should create with default values', () {
        expect(playerEnhancement.playerId, equals('test-player-1'));
        expect(playerEnhancement.primaryRole, equals(PlayerRole.smallForward));
        expect(playerEnhancement.roleCompatibility, equals(1.0));
        expect(playerEnhancement.roleExperience, isNotEmpty);
        expect(playerEnhancement.potential, isNotNull);
        expect(playerEnhancement.development, isNotNull);
      });

      test('should calculate role compatibility correctly', () {
        final compatibility = playerEnhancement.calculateRoleCompatibility(testPlayer, PlayerRole.pointGuard);
        
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should provide role bonuses based on position', () {
        playerEnhancement.primaryRole = PlayerRole.shootingGuard;
        final bonuses = playerEnhancement.getRoleBonuses();
        
        expect(bonuses, isA<Map<String, double>>());
        expect(bonuses.containsKey('shooting'), isTrue);
        expect(bonuses.containsKey('defense'), isTrue);
      });

      test('should serialize and deserialize correctly', () {
        final map = playerEnhancement.toMap();
        final deserialized = PlayerEnhancement.fromMap(map);
        
        expect(deserialized.playerId, equals(playerEnhancement.playerId));
        expect(deserialized.primaryRole, equals(playerEnhancement.primaryRole));
        expect(deserialized.secondaryRole, equals(playerEnhancement.secondaryRole));
        expect(deserialized.roleCompatibility, equals(playerEnhancement.roleCompatibility));
      });

      test('should handle missing data in deserialization', () {
        final minimalMap = {'playerId': 'test'};
        final deserialized = PlayerEnhancement.fromMap(minimalMap);
        
        expect(deserialized.playerId, equals('test'));
        expect(deserialized.primaryRole, equals(PlayerRole.pointGuard)); // Default
        expect(deserialized.potential, isNotNull);
        expect(deserialized.development, isNotNull);
      });
    });

    group('CoachEnhancement Tests', () {
      test('should create with default values', () {
        expect(coachEnhancement.coachId, equals('test-coach-1'));
        expect(coachEnhancement.primarySpecialization, equals(CoachingSpecialization.offensive));
        expect(coachEnhancement.coachingAttributes, isNotEmpty);
        expect(coachEnhancement.achievements, isEmpty);
        expect(coachEnhancement.history, isNotNull);
        expect(coachEnhancement.experienceLevel, equals(1));
      });

      test('should calculate team bonuses correctly', () {
        coachEnhancement.coachingAttributes['offensive'] = 80;
        final bonuses = coachEnhancement.calculateTeamBonuses();
        
        expect(bonuses, isNotEmpty);
        expect(bonuses.containsKey('offensiveRating'), isTrue);
        expect(bonuses['offensiveRating'], greaterThan(0.0));
      });

      test('should apply experience level multiplier', () {
        coachEnhancement.experienceLevel = 5;
        coachEnhancement.coachingAttributes['offensive'] = 80;
        
        final bonuses = coachEnhancement.calculateTeamBonuses();
        expect(bonuses['offensiveRating'], greaterThan(0.06)); // Should be multiplied by experience
      });

      test('should handle secondary specialization bonuses', () {
        coachEnhancement.secondarySpecialization = CoachingSpecialization.defensive;
        coachEnhancement.coachingAttributes['defensive'] = 70;
        
        final bonuses = coachEnhancement.calculateTeamBonuses();
        expect(bonuses.containsKey('defensiveRating'), isTrue);
      });

      test('should serialize and deserialize correctly', () {
        final map = coachEnhancement.toMap();
        final deserialized = CoachEnhancement.fromMap(map);
        
        expect(deserialized.coachId, equals(coachEnhancement.coachId));
        expect(deserialized.primarySpecialization, equals(coachEnhancement.primarySpecialization));
        expect(deserialized.experienceLevel, equals(coachEnhancement.experienceLevel));
      });
    });

    group('TeamEnhancement Tests', () {
      test('should create with default values', () {
        expect(teamEnhancement.teamId, equals('test-team-1'));
        expect(teamEnhancement.playbookLibrary, isNotNull);
        expect(teamEnhancement.roleAssignments, isNotEmpty);
        expect(teamEnhancement.roleAssignments.length, equals(PlayerRole.values.length));
      });

      test('should initialize playbook library with defaults', () {
        expect(teamEnhancement.playbookLibrary.playbooks, isNotEmpty);
        expect(teamEnhancement.playbookLibrary.activePlaybook, isNotNull);
      });

      test('should serialize and deserialize correctly', () {
        final map = teamEnhancement.toMap();
        final deserialized = TeamEnhancement.fromMap(map);
        
        expect(deserialized.teamId, equals(teamEnhancement.teamId));
        expect(deserialized.playbookLibrary.playbooks.length, 
               equals(teamEnhancement.playbookLibrary.playbooks.length));
      });
    });

    group('Playbook Tests', () {
      test('should create with default strategy weights', () {
        final playbook = Playbook(
          name: 'Test Playbook',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.pressDefense,
        );
        
        expect(playbook.strategyWeights, isNotEmpty);
        expect(playbook.optimalRoles, isNotEmpty);
        expect(playbook.teamRequirements, isNotEmpty);
      });

      test('should have different weights for different strategies', () {
        final fastBreakPlaybook = Playbook(
          name: 'Fast Break',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );
        
        final postUpPlaybook = Playbook(
          name: 'Post Up',
          offensiveStrategy: OffensiveStrategy.postUp,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );
        
        expect(fastBreakPlaybook.strategyWeights, isNot(equals(postUpPlaybook.strategyWeights)));
      });

      test('should serialize and deserialize correctly', () {
        final playbook = Playbook(
          name: 'Test Playbook',
          offensiveStrategy: OffensiveStrategy.pickAndRoll,
          defensiveStrategy: DefensiveStrategy.zoneDefense,
        );
        
        final map = playbook.toMap();
        final deserialized = Playbook.fromMap(map);
        
        expect(deserialized.name, equals(playbook.name));
        expect(deserialized.offensiveStrategy, equals(playbook.offensiveStrategy));
        expect(deserialized.defensiveStrategy, equals(playbook.defensiveStrategy));
      });
    });

    group('PlaybookLibrary Tests', () {
      test('should initialize with default playbooks', () {
        final library = PlaybookLibrary();
        library.initializeWithDefaults();
        
        expect(library.playbooks, isNotEmpty);
        expect(library.playbooks.length, equals(5));
        expect(library.activePlaybook, isNotNull);
      });

      test('should serialize and deserialize correctly', () {
        final library = PlaybookLibrary();
        library.initializeWithDefaults();
        
        final map = library.toMap();
        final deserialized = PlaybookLibrary.fromMap(map);
        
        expect(deserialized.playbooks.length, equals(library.playbooks.length));
        expect(deserialized.activePlaybook?.name, equals(library.activePlaybook?.name));
      });

      test('should handle missing active playbook gracefully', () {
        final library = PlaybookLibrary();
        library.initializeWithDefaults();
        
        final map = library.toMap();
        map['activePlaybook'] = 'Non-existent Playbook';
        
        final deserialized = PlaybookLibrary.fromMap(map);
        expect(deserialized.activePlaybook, isNotNull); // Should fallback to first playbook
      });
    });

    group('PlayerPotential Tests', () {
      test('should create default potential correctly', () {
        final potential = PlayerPotential.defaultPotential();
        
        expect(potential.tier, equals(PotentialTier.bronze));
        expect(potential.maxSkills, isNotEmpty);
        expect(potential.overallPotential, equals(75));
        expect(potential.isHidden, isTrue);
      });

      test('should serialize and deserialize correctly', () {
        final potential = PlayerPotential.defaultPotential();
        final map = potential.toMap();
        final deserialized = PlayerPotential.fromMap(map);
        
        expect(deserialized.tier, equals(potential.tier));
        expect(deserialized.overallPotential, equals(potential.overallPotential));
        expect(deserialized.isHidden, equals(potential.isHidden));
      });

      test('should handle missing data in deserialization', () {
        final minimalMap = <String, dynamic>{};
        final deserialized = PlayerPotential.fromMap(minimalMap);
        
        expect(deserialized.tier, equals(PotentialTier.bronze));
        expect(deserialized.overallPotential, equals(75));
      });
    });

    group('DevelopmentTracker Tests', () {
      test('should create initial tracker correctly', () {
        final tracker = DevelopmentTracker.initial();
        
        expect(tracker.skillExperience, isNotEmpty);
        expect(tracker.totalExperience, equals(0));
        expect(tracker.developmentRate, equals(1.0));
        expect(tracker.milestones, isEmpty);
        expect(tracker.agingCurve, isNotNull);
      });

      test('should serialize and deserialize correctly', () {
        final tracker = DevelopmentTracker.initial();
        final map = tracker.toMap();
        final deserialized = DevelopmentTracker.fromMap(map);
        
        expect(deserialized.totalExperience, equals(tracker.totalExperience));
        expect(deserialized.developmentRate, equals(tracker.developmentRate));
        expect(deserialized.milestones.length, equals(tracker.milestones.length));
      });
    });

    group('AgingCurve Tests', () {
      test('should create standard curve correctly', () {
        final curve = AgingCurve.standard();
        
        expect(curve.peakAge, equals(27));
        expect(curve.declineStartAge, equals(30));
        expect(curve.peakMultiplier, equals(1.2));
        expect(curve.declineRate, equals(0.02));
      });

      test('should calculate age modifiers correctly', () {
        final curve = AgingCurve.standard();
        
        // Young player should have bonus
        final youngModifier = curve.getAgeModifier(22);
        expect(youngModifier, greaterThan(1.0));
        
        // Peak age player should have peak multiplier
        final peakModifier = curve.getAgeModifier(27);
        expect(peakModifier, equals(1.2));
        
        // Old player should have penalty
        final oldModifier = curve.getAgeModifier(35);
        expect(oldModifier, lessThan(1.0));
        expect(oldModifier, greaterThanOrEqualTo(0.1)); // Should not go below minimum
      });

      test('should serialize and deserialize correctly', () {
        final curve = AgingCurve.standard();
        final map = curve.toMap();
        final deserialized = AgingCurve.fromMap(map);
        
        expect(deserialized.peakAge, equals(curve.peakAge));
        expect(deserialized.declineStartAge, equals(curve.declineStartAge));
        expect(deserialized.peakMultiplier, equals(curve.peakMultiplier));
        expect(deserialized.declineRate, equals(curve.declineRate));
      });
    });

    group('Achievement Tests', () {
      test('should create achievement correctly', () {
        final achievement = Achievement(
          name: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.wins,
          unlockedDate: DateTime.now(),
        );
        
        expect(achievement.name, equals('Test Achievement'));
        expect(achievement.type, equals(AchievementType.wins));
        expect(achievement.metadata, isEmpty);
      });

      test('should serialize and deserialize correctly', () {
        final achievement = Achievement(
          name: 'Test Achievement',
          description: 'Test Description',
          type: AchievementType.experience,
          unlockedDate: DateTime.now(),
          metadata: {'level': 5},
        );
        
        final map = achievement.toMap();
        final deserialized = Achievement.fromMap(map);
        
        expect(deserialized.name, equals(achievement.name));
        expect(deserialized.type, equals(achievement.type));
        expect(deserialized.metadata['level'], equals(5));
      });
    });

    group('CoachingHistory Tests', () {
      test('should create initial history correctly', () {
        final history = CoachingHistory.initial();
        
        expect(history.totalWins, equals(0));
        expect(history.totalLosses, equals(0));
        expect(history.totalGames, equals(0));
        expect(history.winPercentage, equals(0.0));
        expect(history.seasonRecords, isEmpty);
      });

      test('should calculate win percentage correctly', () {
        final history = CoachingHistory.initial();
        history.addSeasonRecord(60, 22, true, false);
        
        expect(history.winPercentage, closeTo(0.732, 0.001));
        expect(history.totalGames, equals(82));
        expect(history.playoffAppearances, equals(1));
      });

      test('should serialize and deserialize correctly', () {
        final history = CoachingHistory.initial();
        history.addSeasonRecord(50, 32, true, true);
        
        final map = history.toMap();
        final deserialized = CoachingHistory.fromMap(map);
        
        expect(deserialized.totalWins, equals(history.totalWins));
        expect(deserialized.championships, equals(history.championships));
        expect(deserialized.seasonRecords.length, equals(history.seasonRecords.length));
      });
    });

    group('SeasonRecord Tests', () {
      test('should create season record correctly', () {
        final record = SeasonRecord(
          season: 1,
          wins: 60,
          losses: 22,
          madePlayoffs: true,
          wonChampionship: false,
        );
        
        expect(record.winPercentage, closeTo(0.732, 0.001));
        expect(record.madePlayoffs, isTrue);
        expect(record.wonChampionship, isFalse);
      });

      test('should serialize and deserialize correctly', () {
        final record = SeasonRecord(
          season: 2,
          wins: 45,
          losses: 37,
          madePlayoffs: false,
          wonChampionship: false,
          teamName: 'Test Team',
        );
        
        final map = record.toMap();
        final deserialized = SeasonRecord.fromMap(map);
        
        expect(deserialized.season, equals(record.season));
        expect(deserialized.wins, equals(record.wins));
        expect(deserialized.teamName, equals(record.teamName));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('should handle extreme attribute values in role compatibility', () {
        final extremePlayer = Player(
          name: 'Extreme Player',
          age: 25,
          team: 'Test Team',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 195,
          shooting: 100, // Maximum
          rebounding: 1,  // Minimum
          passing: 100,   // Maximum
          ballHandling: 1, // Minimum
          perimeterDefense: 50,
          postDefense: 50,
          insideShooting: 50,
          performances: {},
        );
        
        final enhancement = PlayerEnhancement(
          playerId: 'extreme-player',
          primaryRole: PlayerRole.pointGuard,
        );
        
        final compatibility = enhancement.calculateRoleCompatibility(extremePlayer, PlayerRole.pointGuard);
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should handle zero experience in aging curve', () {
        final curve = AgingCurve.standard();
        final modifier = curve.getAgeModifier(18); // Very young
        
        expect(modifier, greaterThan(1.0));
        expect(modifier.isFinite, isTrue);
      });

      test('should handle very old players in aging curve', () {
        final curve = AgingCurve.standard();
        final modifier = curve.getAgeModifier(45); // Very old
        
        expect(modifier, greaterThanOrEqualTo(0.1)); // Should not go below minimum
        expect(modifier, lessThan(1.0));
      });

      test('should handle empty playbook library gracefully', () {
        final library = PlaybookLibrary(playbooks: []);
        
        final map = library.toMap();
        final deserialized = PlaybookLibrary.fromMap(map);
        
        expect(deserialized.playbooks, isEmpty);
        expect(deserialized.activePlaybook, isNull);
      });

      test('should handle invalid enum values in deserialization', () {
        final map = {
          'playerId': 'test',
          'primaryRole': 'invalidRole',
          'potential': {'tier': 'invalidTier'},
        };
        
        final enhancement = PlayerEnhancement.fromMap(map);
        expect(enhancement.primaryRole, equals(PlayerRole.pointGuard)); // Should fallback to default
        expect(enhancement.potential.tier, equals(PotentialTier.bronze)); // Should fallback to default
      });
    });
  });
}