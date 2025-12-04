import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/depth_chart_entry.dart';
import 'package:BasketballManager/models/rotation_config.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/utils/rotation_presets.dart';

void main() {
  group('DepthChartEntry', () {
    test('creates valid entry', () {
      final entry = DepthChartEntry(
        playerId: 'player1',
        position: 'PG',
        depth: 1,
      );

      expect(entry.playerId, 'player1');
      expect(entry.position, 'PG');
      expect(entry.depth, 1);
    });

    test('validates position values', () {
      expect(
        () => DepthChartEntry(playerId: 'p1', position: 'INVALID', depth: 1),
        throwsArgumentError,
      );
    });

    test('validates depth is at least 1', () {
      expect(
        () => DepthChartEntry(playerId: 'p1', position: 'PG', depth: 0),
        throwsArgumentError,
      );
    });

    test('serializes to JSON', () {
      final entry = DepthChartEntry(
        playerId: 'player1',
        position: 'SG',
        depth: 2,
      );

      final json = entry.toJson();
      expect(json['playerId'], 'player1');
      expect(json['position'], 'SG');
      expect(json['depth'], 2);
    });

    test('deserializes from JSON', () {
      final json = {
        'playerId': 'player1',
        'position': 'SF',
        'depth': 1,
      };

      final entry = DepthChartEntry.fromJson(json);
      expect(entry.playerId, 'player1');
      expect(entry.position, 'SF');
      expect(entry.depth, 1);
    });
  });

  group('RotationConfig', () {
    late RotationConfig validConfig;

    setUp(() {
      validConfig = RotationConfig(
        rotationSize: 8,
        playerMinutes: {
          'p1': 36,
          'p2': 32,
          'p3': 28,
          'p4': 24,
          'p5': 30,
          'p6': 20,
          'p7': 16,
          'p8': 14,
        },
        depthChart: [
          DepthChartEntry(playerId: 'p1', position: 'PG', depth: 1),
          DepthChartEntry(playerId: 'p6', position: 'PG', depth: 2),
          DepthChartEntry(playerId: 'p2', position: 'SG', depth: 1),
          DepthChartEntry(playerId: 'p7', position: 'SG', depth: 2),
          DepthChartEntry(playerId: 'p3', position: 'SF', depth: 1),
          DepthChartEntry(playerId: 'p4', position: 'PF', depth: 1),
          DepthChartEntry(playerId: 'p8', position: 'PF', depth: 2),
          DepthChartEntry(playerId: 'p5', position: 'C', depth: 1),
        ],
        lastModified: DateTime(2025, 12, 3),
      );
    });

    test('getActivePlayerIds returns players with non-zero minutes', () {
      final activeIds = validConfig.getActivePlayerIds();
      expect(activeIds.length, 8);
      expect(activeIds, contains('p1'));
      expect(activeIds, contains('p8'));
    });

    test('getTotalMinutesForPosition calculates correctly', () {
      expect(validConfig.getTotalMinutesForPosition('PG'), 56); // 36 + 20
      expect(validConfig.getTotalMinutesForPosition('SG'), 48); // 32 + 16
      expect(validConfig.getTotalMinutesForPosition('PF'), 38); // 24 + 14
    });

    test('getPlayersForPosition returns correct players', () {
      final pgPlayers = validConfig.getPlayersForPosition('PG');
      expect(pgPlayers.length, 2);
      expect(pgPlayers, contains('p1'));
      expect(pgPlayers, contains('p6'));
    });

    test('isValid returns false for invalid config', () {
      expect(validConfig.isValid(), false); // Minutes don't add up to 48 per position
    });

    test('getValidationErrors detects position minute issues', () {
      final errors = validConfig.getValidationErrors();
      expect(errors.any((e) => e.contains('PG') && e.contains('56')), true);
    });

    test('serializes to JSON', () {
      final json = validConfig.toJson();
      expect(json['rotationSize'], 8);
      expect(json['playerMinutes'], isA<Map>());
      expect(json['depthChart'], isA<List>());
      expect(json['lastModified'], isA<String>());
    });

    test('deserializes from JSON', () {
      final json = validConfig.toJson();
      final restored = RotationConfig.fromJson(json);
      
      expect(restored.rotationSize, validConfig.rotationSize);
      expect(restored.playerMinutes, validConfig.playerMinutes);
      expect(restored.depthChart.length, validConfig.depthChart.length);
    });
  });

  group('RotationPresets', () {
    late List<Player> testPlayers;

    setUp(() {
      // Create 15 test players with varying ratings
      testPlayers = List.generate(15, (i) {
        return Player(
          id: 'player$i',
          name: 'Player $i',
          heightInches: 75,
          shooting: 70 - i * 2,
          defense: 70 - i * 2,
          speed: 70 - i * 2,
          postShooting: 70 - i * 2,
          passing: 70 - i * 2,
          rebounding: 70 - i * 2,
          ballHandling: 70 - i * 2,
          threePoint: 70 - i * 2,
          blocks: 70 - i * 2,
          steals: 70 - i * 2,
          position: 'PG',
        );
      });
    });

    test('rankPlayersByRating sorts players correctly', () {
      final ranked = RotationPresets.rankPlayersByRating(testPlayers);
      
      // First player should have highest rating
      expect(ranked[0].overallRating >= ranked[1].overallRating, true);
      expect(ranked[1].overallRating >= ranked[2].overallRating, true);
      
      // Last player should have lowest rating
      expect(ranked[13].overallRating >= ranked[14].overallRating, true);
    });

    test('get10PlayerPreset creates valid configuration', () {
      final preset = RotationPresets.get10PlayerPreset(testPlayers);
      
      final playerMinutes = preset['playerMinutes'] as Map<String, int>;
      final depthChart = preset['depthChart'] as List<DepthChartEntry>;
      
      // Should have 10 players
      expect(playerMinutes.length, 10);
      expect(depthChart.length, 10);
      
      // Total minutes should be 240
      final totalMinutes = playerMinutes.values.reduce((a, b) => a + b);
      expect(totalMinutes, 240);
      
      // First 5 players should have 30 minutes (starters)
      final ranked = RotationPresets.rankPlayersByRating(testPlayers);
      for (int i = 0; i < 5; i++) {
        expect(playerMinutes[ranked[i].id], 30);
      }
      
      // Next 5 players should have 18 minutes (bench)
      for (int i = 5; i < 10; i++) {
        expect(playerMinutes[ranked[i].id], 18);
      }
    });

    test('get9PlayerPreset creates valid configuration', () {
      final preset = RotationPresets.get9PlayerPreset(testPlayers);
      
      final playerMinutes = preset['playerMinutes'] as Map<String, int>;
      final depthChart = preset['depthChart'] as List<DepthChartEntry>;
      
      // Should have 9 players
      expect(playerMinutes.length, 9);
      expect(depthChart.length, 9);
      
      // Total minutes should be 240
      final totalMinutes = playerMinutes.values.reduce((a, b) => a + b);
      expect(totalMinutes, 240);
    });

    test('get8PlayerPreset creates valid configuration', () {
      final preset = RotationPresets.get8PlayerPreset(testPlayers);
      
      final playerMinutes = preset['playerMinutes'] as Map<String, int>;
      final depthChart = preset['depthChart'] as List<DepthChartEntry>;
      
      // Should have 8 players
      expect(playerMinutes.length, 8);
      expect(depthChart.length, 8);
      
      // Total minutes should be 240
      final totalMinutes = playerMinutes.values.reduce((a, b) => a + b);
      expect(totalMinutes, 240);
    });

    test('get7PlayerPreset creates valid configuration', () {
      final preset = RotationPresets.get7PlayerPreset(testPlayers);
      
      final playerMinutes = preset['playerMinutes'] as Map<String, int>;
      final depthChart = preset['depthChart'] as List<DepthChartEntry>;
      
      // Should have 7 players
      expect(playerMinutes.length, 7);
      expect(depthChart.length, 7);
      
      // Total minutes should be 240
      final totalMinutes = playerMinutes.values.reduce((a, b) => a + b);
      expect(totalMinutes, 240);
    });

    test('get6PlayerPreset creates valid configuration', () {
      final preset = RotationPresets.get6PlayerPreset(testPlayers);
      
      final playerMinutes = preset['playerMinutes'] as Map<String, int>;
      final depthChart = preset['depthChart'] as List<DepthChartEntry>;
      
      // Should have 6 players
      expect(playerMinutes.length, 6);
      expect(depthChart.length, 6);
      
      // Total minutes should be 240
      final totalMinutes = playerMinutes.values.reduce((a, b) => a + b);
      expect(totalMinutes, 240);
    });

    test('presets throw error with insufficient players', () {
      final fewPlayers = testPlayers.sublist(0, 5);
      
      expect(
        () => RotationPresets.get10PlayerPreset(fewPlayers),
        throwsArgumentError,
      );
      expect(
        () => RotationPresets.get6PlayerPreset(fewPlayers),
        throwsArgumentError,
      );
    });
  });
}
