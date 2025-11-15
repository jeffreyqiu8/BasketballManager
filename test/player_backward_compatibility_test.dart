import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';

void main() {
  group('Player Backward Compatibility', () {
    test('should load player from JSON without blocks and steals attributes', () {
      // Simulate old save format without blocks and steals
      final oldPlayerJson = {
        'id': 'player1',
        'name': 'Legacy Player',
        'heightInches': 75,
        'shooting': 80,
        'defense': 70,
        'speed': 65,
        'stamina': 75,
        'passing': 60,
        'rebounding': 70,
        'ballHandling': 65,
        'threePoint': 75,
        // Note: blocks and steals are missing
      };

      final player = Player.fromJson(oldPlayerJson);

      expect(player.id, 'player1');
      expect(player.name, 'Legacy Player');
      expect(player.heightInches, 75);
      expect(player.shooting, 80);
      expect(player.defense, 70);
      
      // Verify blocks and steals have reasonable default values
      // blocks should be based on defense (60%) and rebounding (40%)
      // Expected: (70 * 0.6 + 70 * 0.4) = 70
      expect(player.blocks, 70);
      
      // steals should be based on defense (70%) and speed (30%)
      // Expected: (70 * 0.7 + 65 * 0.3) = 68.5 ≈ 69
      expect(player.steals, 69);
      
      // Verify position is assigned based on attributes
      expect(player.position, isNotEmpty);
      expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true);
    });

    test('should load player from JSON with blocks and steals attributes', () {
      // New save format with blocks and steals
      final newPlayerJson = {
        'id': 'player2',
        'name': 'Modern Player',
        'heightInches': 78,
        'shooting': 85,
        'defense': 75,
        'speed': 70,
        'stamina': 80,
        'passing': 65,
        'rebounding': 80,
        'ballHandling': 70,
        'threePoint': 80,
        'blocks': 85,
        'steals': 72,
      };

      final player = Player.fromJson(newPlayerJson);

      expect(player.id, 'player2');
      expect(player.name, 'Modern Player');
      expect(player.blocks, 85);
      expect(player.steals, 72);
      
      // Verify position is assigned based on attributes when missing
      expect(player.position, isNotEmpty);
      expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true);
    });

    test('should serialize player with blocks and steals', () {
      final player = Player(
        id: 'player3',
        name: 'Test Player',
        heightInches: 76,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 72,
        steals: 78,
        position: 'SF',
      );

      final json = player.toJson();

      expect(json['id'], 'player3');
      expect(json['name'], 'Test Player');
      expect(json['blocks'], 72);
      expect(json['steals'], 78);
      expect(json['position'], 'SF');
      expect(json.containsKey('blocks'), true);
      expect(json.containsKey('steals'), true);
      expect(json.containsKey('position'), true);
    });

    test('should calculate overall rating with blocks and steals', () {
      final player = Player(
        id: 'player4',
        name: 'Rating Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 80,
        speed: 80,
        postShooting: 80,
        passing: 80,
        rebounding: 80,
        ballHandling: 80,
        threePoint: 80,
        blocks: 80,
        steals: 80,
        position: 'SG',
      );

      // Overall rating should be average of all 10 attributes
      expect(player.overallRating, 80);
    });

    test('should load player from JSON without position attribute', () {
      // Simulate save format without position
      final oldPlayerJson = {
        'id': 'player5',
        'name': 'No Position Player',
        'heightInches': 82,
        'shooting': 60,
        'defense': 80,
        'speed': 50,
        'stamina': 75,
        'passing': 55,
        'rebounding': 90,
        'ballHandling': 50,
        'threePoint': 40,
        'blocks': 85,
        'steals': 60,
        // Note: position is missing
      };

      final player = Player.fromJson(oldPlayerJson);

      expect(player.id, 'player5');
      expect(player.name, 'No Position Player');
      
      // Verify position is assigned based on attributes
      // With high rebounding (90) and blocks (85), should likely be C or PF
      expect(player.position, isNotEmpty);
      expect(['PG', 'SG', 'SF', 'PF', 'C'].contains(player.position), true);
    });

    test('should load player from JSON with position attribute', () {
      // New save format with position
      final newPlayerJson = {
        'id': 'player6',
        'name': 'Position Player',
        'heightInches': 74,
        'shooting': 85,
        'defense': 70,
        'speed': 80,
        'stamina': 75,
        'passing': 90,
        'rebounding': 60,
        'ballHandling': 88,
        'threePoint': 82,
        'blocks': 55,
        'steals': 78,
        'position': 'PG',
      };

      final player = Player.fromJson(newPlayerJson);

      expect(player.id, 'player6');
      expect(player.name, 'Position Player');
      expect(player.position, 'PG');
    });

    test('should copy player with new position', () {
      final player = Player(
        id: 'player7',
        name: 'Copy Test Player',
        heightInches: 78,
        shooting: 75,
        defense: 70,
        speed: 65,
        postShooting: 80,
        passing: 70,
        rebounding: 75,
        ballHandling: 68,
        threePoint: 72,
        blocks: 70,
        steals: 65,
        position: 'SF',
      );

      final copiedPlayer = player.copyWithPosition('PF');

      expect(copiedPlayer.id, player.id);
      expect(copiedPlayer.name, player.name);
      expect(copiedPlayer.heightInches, player.heightInches);
      expect(copiedPlayer.shooting, player.shooting);
      expect(copiedPlayer.position, 'PF');
      expect(player.position, 'SF'); // Original should be unchanged
    });
  });
}
