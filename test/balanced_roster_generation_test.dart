import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/player_generator.dart';

void main() {
  group('Balanced Roster Generation', () {
    late PlayerGenerator generator;

    setUp(() {
      generator = PlayerGenerator();
    });

    test('generateTeamRoster should create balanced 15-player roster', () {
      final roster = generator.generateTeamRoster(15);

      // Count players by position
      final positionCounts = <String, int>{
        'PG': 0,
        'SG': 0,
        'SF': 0,
        'PF': 0,
        'C': 0,
      };

      for (var player in roster) {
        positionCounts[player.position] = 
            (positionCounts[player.position] ?? 0) + 1;
      }

      // Verify we have exactly 3 players at each position
      expect(positionCounts['PG'], equals(3), 
          reason: 'Should have 3 Point Guards');
      expect(positionCounts['SG'], equals(3), 
          reason: 'Should have 3 Shooting Guards');
      expect(positionCounts['SF'], equals(3), 
          reason: 'Should have 3 Small Forwards');
      expect(positionCounts['PF'], equals(3), 
          reason: 'Should have 3 Power Forwards');
      expect(positionCounts['C'], equals(3), 
          reason: 'Should have 3 Centers');

      // Verify total roster size
      expect(roster.length, equals(15), 
          reason: 'Roster should have exactly 15 players');
    });

    test('generateTeamRoster should create balanced roster consistently', () {
      // Generate multiple rosters to ensure consistency
      for (var i = 0; i < 5; i++) {
        final roster = generator.generateTeamRoster(15);

        final positionCounts = <String, int>{
          'PG': 0,
          'SG': 0,
          'SF': 0,
          'PF': 0,
          'C': 0,
        };

        for (var player in roster) {
          positionCounts[player.position] = 
              (positionCounts[player.position] ?? 0) + 1;
        }

        // All positions should have exactly 3 players
        expect(positionCounts.values.every((count) => count == 3), isTrue,
            reason: 'Roster $i should have 3 players at each position');
      }
    });

    test('Non-standard roster sizes should still work', () {
      final roster = generator.generateTeamRoster(10);
      
      expect(roster.length, equals(10), 
          reason: 'Should generate requested number of players');
      
      // Verify all players have valid positions
      for (var player in roster) {
        expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), isTrue,
            reason: 'Player ${player.name} should have a valid position');
      }
    });

    test('Name generation should produce minimal duplicates across multiple rosters', () {
      // Generate 30 teams (450 players total) to simulate a full league
      final allPlayers = <String>[];
      for (var i = 0; i < 30; i++) {
        final roster = generator.generateTeamRoster(15);
        allPlayers.addAll(roster.map((p) => p.name));
      }

      // Count unique names
      final uniqueNames = allPlayers.toSet();
      final duplicateCount = allPlayers.length - uniqueNames.length;
      final duplicatePercentage = (duplicateCount / allPlayers.length) * 100;

      // With 200+ first names and 200+ last names, we have 40,000+ possible combinations
      // For 450 players, we should have very few duplicates (< 10%)
      expect(duplicatePercentage, lessThan(10.0),
          reason: 'Duplicate names should be less than 10% of total players. '
              'Found $duplicateCount duplicates out of ${allPlayers.length} players '
              '(${duplicatePercentage.toStringAsFixed(1)}%)');

      // Verify we have at least 400 unique names out of 450 players
      expect(uniqueNames.length, greaterThan(400),
          reason: 'Should have at least 400 unique names out of 450 players. '
              'Found ${uniqueNames.length} unique names.');
    });

    test('Name combinations should create realistic player names', () {
      // Generate a sample of players and verify names are properly formatted
      final players = List.generate(50, (_) => generator.generatePlayer());

      for (var player in players) {
        // Name should have at least two parts (first and last name)
        final nameParts = player.name.split(' ');
        expect(nameParts.length, greaterThanOrEqualTo(2),
            reason: 'Player name "${player.name}" should have at least first and last name');

        // Name should not be empty
        expect(player.name.trim().isNotEmpty, isTrue,
            reason: 'Player name should not be empty');

        // Name should start with a capital letter
        expect(player.name[0].toUpperCase(), equals(player.name[0]),
            reason: 'Player name "${player.name}" should start with a capital letter');
      }
    });
  });
}
