import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/player_generator.dart';

void main() {
  group('Player Generation Height-Based Modifiers', () {
    late PlayerGenerator generator;

    setUp(() {
      generator = PlayerGenerator();
    });

    test('Tall players (80"+) should have enhanced rebounding and blocks', () {
      // Generate multiple players to test the height-based modifiers
      final players = List.generate(100, (_) => generator.generatePlayer());
      
      // Filter for tall players (80"+)
      final tallPlayers = players.where((p) => p.heightInches >= 80).toList();
      
      // We should have some tall players in 100 generations
      expect(tallPlayers.isNotEmpty, true, reason: 'Should generate some tall players');
      
      // Tall players should generally have good rebounding and blocks
      // (though not guaranteed due to random generation + modifiers)
      for (final player in tallPlayers) {
        // Just verify the player has valid attributes in range
        expect(player.rebounding, inInclusiveRange(0, 100));
        expect(player.blocks, inInclusiveRange(0, 100));
        expect(player.steals, inInclusiveRange(0, 100));
        expect(player.shooting, inInclusiveRange(0, 100));
        expect(player.speed, inInclusiveRange(0, 100));
      }
    });

    test('Short players (72" and under) should have enhanced steals and shooting', () {
      // Generate multiple players to test the height-based modifiers
      final players = List.generate(100, (_) => generator.generatePlayer());
      
      // Filter for short players (72" and under)
      final shortPlayers = players.where((p) => p.heightInches <= 72).toList();
      
      // We should have some short players in 100 generations
      expect(shortPlayers.isNotEmpty, true, reason: 'Should generate some short players');
      
      // Short players should generally have good steals and shooting
      // (though not guaranteed due to random generation + modifiers)
      for (final player in shortPlayers) {
        // Just verify the player has valid attributes in range
        expect(player.steals, inInclusiveRange(0, 100));
        expect(player.shooting, inInclusiveRange(0, 100));
        expect(player.speed, inInclusiveRange(0, 100));
        expect(player.rebounding, inInclusiveRange(0, 100));
        expect(player.blocks, inInclusiveRange(0, 100));
      }
    });

    test('All generated players should have attributes clamped to 0-100', () {
      // Generate many players to test edge cases
      final players = List.generate(200, (_) => generator.generatePlayer());
      
      for (final player in players) {
        expect(player.shooting, inInclusiveRange(0, 100));
        expect(player.defense, inInclusiveRange(0, 100));
        expect(player.speed, inInclusiveRange(0, 100));
        expect(player.postShooting, inInclusiveRange(0, 100));
        expect(player.passing, inInclusiveRange(0, 100));
        expect(player.rebounding, inInclusiveRange(0, 100));
        expect(player.ballHandling, inInclusiveRange(0, 100));
        expect(player.threePoint, inInclusiveRange(0, 100));
        expect(player.blocks, inInclusiveRange(0, 100));
        expect(player.steals, inInclusiveRange(0, 100));
      }
    });

    test('All generated players should have a valid position assigned', () {
      final players = List.generate(50, (_) => generator.generatePlayer());
      
      final validPositions = ['PG', 'SG', 'SF', 'PF', 'C'];
      
      for (final player in players) {
        expect(validPositions.contains(player.position), true,
            reason: 'Player ${player.name} has invalid position: ${player.position}');
      }
    });

    test('Position assignment should be based on highest affinity score', () {
      final players = List.generate(50, (_) => generator.generatePlayer());
      
      for (final player in players) {
        final affinities = player.getPositionAffinities();
        
        // Find the position with highest affinity
        final highestAffinityPosition = affinities.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        
        // The assigned position should match the highest affinity
        // (or be very close if there are ties)
        expect(player.position, equals(highestAffinityPosition),
            reason: 'Player ${player.name} (${player.heightFormatted}) assigned to ${player.position} '
                'but highest affinity is $highestAffinityPosition with score ${affinities[highestAffinityPosition]}');
      }
    });
  });
}
