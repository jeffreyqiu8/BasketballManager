import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/enhanced_data_models.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('Basic Playbook System Tests', () {
    late Playbook fastBreakPlaybook;
    late Playbook postUpPlaybook;
    late Playbook threePointPlaybook;
    late PlaybookLibrary library;

    setUp(() {
      fastBreakPlaybook = Playbook(
        name: 'Fast Break Attack',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.pressDefense,
      );

      postUpPlaybook = Playbook(
        name: 'Inside Dominance',
        offensiveStrategy: OffensiveStrategy.postUp,
        defensiveStrategy: DefensiveStrategy.manToMan,
      );

      threePointPlaybook = Playbook(
        name: 'Three Point Barrage',
        offensiveStrategy: OffensiveStrategy.threePointHeavy,
        defensiveStrategy: DefensiveStrategy.zoneDefense,
      );

      library = PlaybookLibrary();
    });

    group('Playbook Creation and Validation', () {
      test('should create playbook with correct default values', () {
        expect(fastBreakPlaybook.name, equals('Fast Break Attack'));
        expect(fastBreakPlaybook.offensiveStrategy, equals(OffensiveStrategy.fastBreak));
        expect(fastBreakPlaybook.defensiveStrategy, equals(DefensiveStrategy.pressDefense));
        expect(fastBreakPlaybook.strategyWeights, isNotEmpty);
        expect(fastBreakPlaybook.optimalRoles, isNotEmpty);
        expect(fastBreakPlaybook.teamRequirements, isNotEmpty);
      });

      test('should have different strategy weights for different offensive strategies', () {
        expect(fastBreakPlaybook.strategyWeights.containsKey('pace'), isTrue);
        expect(fastBreakPlaybook.strategyWeights['pace'], greaterThan(1.0));
        
        expect(postUpPlaybook.strategyWeights.containsKey('insideShooting'), isTrue);
        expect(postUpPlaybook.strategyWeights['insideShooting'], greaterThan(1.0));
        
        expect(threePointPlaybook.strategyWeights.containsKey('shooting'), isTrue);
        expect(threePointPlaybook.strategyWeights['shooting'], greaterThan(1.0));
      });

      test('should have appropriate optimal roles for each strategy', () {
        // Fast break should favor guards and forwards
        expect(fastBreakPlaybook.optimalRoles.contains(PlayerRole.pointGuard), isTrue);
        expect(fastBreakPlaybook.optimalRoles.contains(PlayerRole.shootingGuard), isTrue);
        
        // Post up should favor big men
        expect(postUpPlaybook.optimalRoles.contains(PlayerRole.powerForward), isTrue);
        expect(postUpPlaybook.optimalRoles.contains(PlayerRole.center), isTrue);
        
        // Three point should favor perimeter players
        expect(threePointPlaybook.optimalRoles.contains(PlayerRole.pointGuard), isTrue);
        expect(threePointPlaybook.optimalRoles.contains(PlayerRole.shootingGuard), isTrue);
      });

      test('should validate playbook requirements', () {
        expect(fastBreakPlaybook.teamRequirements.containsKey('averageSpeed'), isTrue);
        expect(postUpPlaybook.teamRequirements.containsKey('averageInsideShooting'), isTrue);
        expect(threePointPlaybook.teamRequirements.containsKey('averageShooting'), isTrue);
      });
    });

    group('Playbook Library Management', () {
      test('should initialize with default playbooks', () {
        library.initializeWithDefaults();
        
        expect(library.playbooks, isNotEmpty);
        expect(library.playbooks.length, equals(5));
        expect(library.activePlaybook, isNotNull);
      });

      test('should manage active playbook correctly', () {
        library.initializeWithDefaults();
        final originalActive = library.activePlaybook;
        
        library.activePlaybook = library.playbooks.last;
        expect(library.activePlaybook, isNot(equals(originalActive)));
        expect(library.activePlaybook, equals(library.playbooks.last));
      });
    });

    group('Playbook Serialization', () {
      test('should serialize and deserialize playbook correctly', () {
        final customPlaybook = Playbook(
          name: 'Custom Strategy',
          offensiveStrategy: OffensiveStrategy.pickAndRoll,
          defensiveStrategy: DefensiveStrategy.switchDefense,
          strategyWeights: {
            'ballHandling': 1.3,
            'screening': 1.4,
            'versatility': 1.2,
          },
          teamRequirements: {
            'averageBallHandling': 70.0,
            'averageVersatility': 65.0,
          },
          effectiveness: 0.85,
        );

        final map = customPlaybook.toMap();
        final deserialized = Playbook.fromMap(map);

        expect(deserialized.name, equals(customPlaybook.name));
        expect(deserialized.offensiveStrategy, equals(customPlaybook.offensiveStrategy));
        expect(deserialized.defensiveStrategy, equals(customPlaybook.defensiveStrategy));
        expect(deserialized.effectiveness, equals(customPlaybook.effectiveness));
        expect(deserialized.strategyWeights['ballHandling'], equals(1.3));
      });

      test('should serialize playbook library correctly', () {
        library.initializeWithDefaults();
        library.activePlaybook = library.playbooks[2];

        final map = library.toMap();
        final deserialized = PlaybookLibrary.fromMap(map);

        expect(deserialized.playbooks.length, equals(library.playbooks.length));
        expect(deserialized.activePlaybook?.name, equals(library.activePlaybook?.name));
      });

      test('should handle corrupted playbook data gracefully', () {
        final corruptedMap = {
          'name': 'Corrupted Playbook',
          'offensiveStrategy': 'invalidStrategy',
          'defensiveStrategy': 'invalidDefense',
          'strategyWeights': 'not a map',
          'effectiveness': 'not a number',
        };

        final playbook = Playbook.fromMap(corruptedMap);
        
        expect(playbook.name, equals('Corrupted Playbook'));
        expect(playbook.offensiveStrategy, equals(OffensiveStrategy.halfCourt)); // Default
        expect(playbook.defensiveStrategy, equals(DefensiveStrategy.manToMan)); // Default
        expect(playbook.effectiveness, equals(0.0)); // Default
      });
    });

    group('Strategy Weight Validation', () {
      test('should have consistent strategy weights across similar strategies', () {
        final fastBreak1 = Playbook(
          name: 'Fast Break 1',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );

        final fastBreak2 = Playbook(
          name: 'Fast Break 2',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.pressDefense,
        );

        // Both should have pace bonuses since they use fast break
        expect(fastBreak1.strategyWeights.containsKey('pace'), isTrue);
        expect(fastBreak2.strategyWeights.containsKey('pace'), isTrue);
        expect(fastBreak1.strategyWeights['pace'], equals(fastBreak2.strategyWeights['pace']));
      });

      test('should have different weights for different offensive strategies', () {
        final strategies = [
          OffensiveStrategy.fastBreak,
          OffensiveStrategy.halfCourt,
          OffensiveStrategy.pickAndRoll,
          OffensiveStrategy.postUp,
          OffensiveStrategy.threePointHeavy,
        ];

        final playbooks = strategies.map((strategy) => Playbook(
          name: 'Test ${strategy.name}',
          offensiveStrategy: strategy,
          defensiveStrategy: DefensiveStrategy.manToMan,
        )).toList();

        // Each playbook should have unique strategy weights
        for (int i = 0; i < playbooks.length; i++) {
          for (int j = i + 1; j < playbooks.length; j++) {
            expect(playbooks[i].strategyWeights, isNot(equals(playbooks[j].strategyWeights)));
          }
        }
      });

      test('should validate strategy weight ranges', () {
        final allPlaybooks = [fastBreakPlaybook, postUpPlaybook, threePointPlaybook];
        
        for (final playbook in allPlaybooks) {
          for (final weight in playbook.strategyWeights.values) {
            expect(weight, greaterThan(0.0));
            expect(weight, lessThan(2.0)); // Reasonable upper bound
          }
        }
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle empty playbook library gracefully', () {
        final emptyLibrary = PlaybookLibrary(playbooks: []);
        
        final map = emptyLibrary.toMap();
        final deserialized = PlaybookLibrary.fromMap(map);
        
        expect(deserialized.playbooks, isEmpty);
        expect(deserialized.activePlaybook, isNull);
      });

      test('should handle missing active playbook in library', () {
        library.initializeWithDefaults();
        
        final map = library.toMap();
        map['activePlaybook'] = 'Non-existent Playbook';
        
        final deserialized = PlaybookLibrary.fromMap(map);
        expect(deserialized.activePlaybook, isNotNull); // Should fallback to first playbook
      });

      test('should handle null values in playbook creation', () {
        final playbook = Playbook(
          name: 'Minimal Playbook',
          offensiveStrategy: OffensiveStrategy.halfCourt,
          defensiveStrategy: DefensiveStrategy.manToMan,
          // All optional parameters are null
        );

        expect(playbook.strategyWeights, isNotEmpty); // Should use defaults
        expect(playbook.optimalRoles, isNotEmpty); // Should use defaults
        expect(playbook.teamRequirements, isNotEmpty); // Should use defaults
      });
    });
  });
}