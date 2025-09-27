import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('Playbook Integration Tests', () {

    test('should create playbook with game modifiers', () {
      final playbook = Playbook.createPreset('run_and_gun');
      final modifiers = playbook.getGameModifiers();

      expect(modifiers, isA<Map<String, double>>());
      expect(modifiers.isNotEmpty, isTrue);
    });

    test('should calculate effectiveness for different strategies', () {
      final playbook = Playbook.createPreset('three_point_shooters');
      
      // Mock team stats that favor three-point shooting
      final teamStats = {
        'averageShooting': 85.0,
        'averageSpacing': 80.0,
        'averageRebounding': 60.0,
      };

      final effectiveness = playbook.calculateEffectiveness(teamStats);
      
      expect(effectiveness, isA<double>());
      expect(effectiveness, greaterThanOrEqualTo(0.0));
      expect(effectiveness, lessThanOrEqualTo(1.0));
    });

    test('should provide different modifiers for different strategies', () {
      final fastBreakPlaybook = Playbook.createPreset('run_and_gun');
      final insidePlaybook = Playbook.createPreset('inside_game');

      final fastBreakModifiers = fastBreakPlaybook.getGameModifiers();
      final insideModifiers = insidePlaybook.getGameModifiers();

      // Should have different modifier sets
      expect(fastBreakModifiers, isNot(equals(insideModifiers)));
      
      // Fast break should have pace modifiers
      expect(fastBreakModifiers.containsKey('pace'), isTrue);
      
      // Inside game should have inside shooting modifiers
      expect(insideModifiers.containsKey('insideShooting'), isTrue);
    });
  });
}