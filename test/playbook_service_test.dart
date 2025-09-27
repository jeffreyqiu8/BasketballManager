import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/playbook_service.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('PlaybookService Tests', () {

    test('should create playbook with specified strategies', () {
      final playbook = PlaybookService.createPlaybook(
        name: 'Test Playbook',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.pressDefense,
      );

      expect(playbook.name, equals('Test Playbook'));
      expect(playbook.offensiveStrategy, equals(OffensiveStrategy.fastBreak));
      expect(playbook.defensiveStrategy, equals(DefensiveStrategy.pressDefense));
      expect(playbook.strategyWeights.isNotEmpty, isTrue);
    });

    test('should create default playbook templates', () {
      final templates = PlaybookService.createDefaultPlaybookTemplates();

      expect(templates.length, greaterThan(5));
      expect(templates.every((p) => p.name.isNotEmpty), isTrue);
      expect(templates.every((p) => p.strategyWeights.isNotEmpty), isTrue);
    });

    test('should modify existing playbook', () {
      final originalPlaybook = Playbook.createPreset('balanced_attack');
      final modifiedPlaybook = PlaybookService.modifyPlaybook(
        originalPlaybook,
        newName: 'Modified Balanced Attack',
        newOffensiveStrategy: OffensiveStrategy.threePointHeavy,
      );

      expect(modifiedPlaybook.name, equals('Modified Balanced Attack'));
      expect(modifiedPlaybook.offensiveStrategy, equals(OffensiveStrategy.threePointHeavy));
      expect(modifiedPlaybook.defensiveStrategy, equals(originalPlaybook.defensiveStrategy));
    });

    test('should calculate strategy synergy bonus', () {
      // Test synergistic combination
      final synergyBonus1 = PlaybookService.getStrategySynergy(
        OffensiveStrategy.fastBreak,
        DefensiveStrategy.pressDefense,
      );
      expect(synergyBonus1, equals(1.1));

      // Test non-synergistic combination
      final synergyBonus2 = PlaybookService.getStrategySynergy(
        OffensiveStrategy.postUp,
        DefensiveStrategy.pressDefense,
      );
      expect(synergyBonus2, equals(1.0));
    });
  });
}