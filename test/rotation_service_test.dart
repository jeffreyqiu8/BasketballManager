import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/rotation_config.dart';
import 'package:BasketballManager/models/depth_chart_entry.dart';
import 'package:BasketballManager/services/rotation_service.dart';

void main() {
  group('RotationService', () {
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

    group('generatePreset', () {
      test('generates valid 8-player rotation', () {
        final config = RotationService.generatePreset(8, testPlayers);
        
        expect(config.rotationSize, 8);
        expect(config.playerMinutes.length, 8);
        expect(config.depthChart.length, 8);
        
        // Verify total minutes is 240
        final totalMinutes = config.playerMinutes.values.reduce((a, b) => a + b);
        expect(totalMinutes, 240);
      });

      test('generates valid 10-player rotation', () {
        final config = RotationService.generatePreset(10, testPlayers);
        
        expect(config.rotationSize, 10);
        expect(config.playerMinutes.length, 10);
        expect(config.depthChart.length, 10);
      });

      test('generates valid 6-player rotation', () {
        final config = RotationService.generatePreset(6, testPlayers);
        
        expect(config.rotationSize, 6);
        expect(config.playerMinutes.length, 6);
        expect(config.depthChart.length, 6);
      });

      test('throws error for invalid rotation size', () {
        expect(
          () => RotationService.generatePreset(5, testPlayers),
          throwsArgumentError,
        );
        expect(
          () => RotationService.generatePreset(11, testPlayers),
          throwsArgumentError,
        );
      });

      test('throws error with insufficient players', () {
        final fewPlayers = testPlayers.sublist(0, 5);
        expect(
          () => RotationService.generatePreset(8, fewPlayers),
          throwsArgumentError,
        );
      });
    });

    group('generateDefaultRotation', () {
      test('generates 8-player rotation by default', () {
        final config = RotationService.generateDefaultRotation(testPlayers);
        
        expect(config.rotationSize, 8);
        expect(config.playerMinutes.length, 8);
      });

      test('throws error with insufficient players', () {
        final fewPlayers = testPlayers.sublist(0, 7);
        expect(
          () => RotationService.generateDefaultRotation(fewPlayers),
          throwsArgumentError,
        );
      });
    });

    group('getStartingLineup', () {
      test('returns players with depth 1', () {
        final config = RotationService.generatePreset(8, testPlayers);
        final starters = RotationService.getStartingLineup(config);
        
        expect(starters.length, 5);
        
        // Verify all returned players have depth 1
        for (final playerId in starters) {
          final entry = config.depthChart.firstWhere(
            (e) => e.playerId == playerId,
          );
          expect(entry.depth, 1);
        }
      });
    });

    group('groupPlayersByPosition', () {
      test('groups players correctly by position', () {
        final config = RotationService.generatePreset(8, testPlayers);
        final grouped = RotationService.groupPlayersByPosition(config);
        
        // Should have all 5 positions
        expect(grouped.keys.length, 5);
        expect(grouped.containsKey('PG'), true);
        expect(grouped.containsKey('SG'), true);
        expect(grouped.containsKey('SF'), true);
        expect(grouped.containsKey('PF'), true);
        expect(grouped.containsKey('C'), true);
        
        // Each position should have at least one player
        for (final position in grouped.keys) {
          expect(grouped[position]!.isNotEmpty, true);
        }
      });

      test('orders players by depth within each position', () {
        final config = RotationService.generatePreset(10, testPlayers);
        final grouped = RotationService.groupPlayersByPosition(config);
        
        // Check that players are ordered by depth
        for (final position in grouped.keys) {
          final playerIds = grouped[position]!;
          if (playerIds.length > 1) {
            // Get depth values for these players
            final depths = playerIds.map((id) {
              return config.depthChart
                  .firstWhere((e) => e.playerId == id)
                  .depth;
            }).toList();
            
            // Verify depths are in ascending order
            for (int i = 0; i < depths.length - 1; i++) {
              expect(depths[i] <= depths[i + 1], true);
            }
          }
        }
      });
    });

    group('validateRotation', () {
      test('returns empty list for valid rotation', () {
        final config = RotationService.generatePreset(8, testPlayers);
        final errors = RotationService.validateRotation(config, testPlayers);
        
        expect(errors, isEmpty);
      });

      test('detects player not in team roster', () {
        final config = RotationService.generatePreset(8, testPlayers);
        
        // Create a modified config with a non-existent player
        final badConfig = RotationConfig(
          rotationSize: config.rotationSize,
          playerMinutes: {
            ...config.playerMinutes,
            'nonexistent': 10,
          },
          depthChart: config.depthChart,
          lastModified: config.lastModified,
        );
        
        final errors = RotationService.validateRotation(badConfig, testPlayers);
        expect(errors.any((e) => e.contains('nonexistent')), true);
      });

      test('detects invalid minute distribution', () {
        // Create config with invalid minutes
        final badConfig = RotationConfig(
          rotationSize: 8,
          playerMinutes: {
            'player0': 30,
            'player1': 30,
            'player2': 30,
            'player3': 30,
            'player4': 30,
            'player5': 20,
            'player6': 20,
            'player7': 20,
          },
          depthChart: [
            DepthChartEntry(playerId: 'player0', position: 'PG', depth: 1),
            DepthChartEntry(playerId: 'player5', position: 'PG', depth: 2),
            DepthChartEntry(playerId: 'player1', position: 'SG', depth: 1),
            DepthChartEntry(playerId: 'player6', position: 'SG', depth: 2),
            DepthChartEntry(playerId: 'player2', position: 'SF', depth: 1),
            DepthChartEntry(playerId: 'player3', position: 'PF', depth: 1),
            DepthChartEntry(playerId: 'player7', position: 'PF', depth: 2),
            DepthChartEntry(playerId: 'player4', position: 'C', depth: 1),
          ],
          lastModified: DateTime.now(),
        );
        
        final errors = RotationService.validateRotation(badConfig, testPlayers);
        expect(errors.isNotEmpty, true);
        expect(errors.any((e) => e.contains('48 minutes')), true);
      });
    });

    group('hasAllPositionsCovered', () {
      test('returns true when all positions have players', () {
        final config = RotationService.generatePreset(8, testPlayers);
        expect(RotationService.hasAllPositionsCovered(config), true);
      });

      test('returns false when a position is missing', () {
        final config = RotationConfig(
          rotationSize: 4,
          playerMinutes: {
            'player0': 48,
            'player1': 48,
            'player2': 48,
            'player3': 48,
          },
          depthChart: [
            DepthChartEntry(playerId: 'player0', position: 'PG', depth: 1),
            DepthChartEntry(playerId: 'player1', position: 'SG', depth: 1),
            DepthChartEntry(playerId: 'player2', position: 'SF', depth: 1),
            DepthChartEntry(playerId: 'player3', position: 'PF', depth: 1),
            // Missing C position
          ],
          lastModified: DateTime.now(),
        );
        
        expect(RotationService.hasAllPositionsCovered(config), false);
      });
    });

    group('hasValidMinuteDistribution', () {
      test('returns true when all positions have 48 minutes', () {
        final config = RotationService.generatePreset(8, testPlayers);
        expect(RotationService.hasValidMinuteDistribution(config), true);
      });

      test('returns false when a position has incorrect minutes', () {
        final config = RotationConfig(
          rotationSize: 5,
          playerMinutes: {
            'player0': 40,
            'player1': 40,
            'player2': 40,
            'player3': 40,
            'player4': 40,
          },
          depthChart: [
            DepthChartEntry(playerId: 'player0', position: 'PG', depth: 1),
            DepthChartEntry(playerId: 'player1', position: 'SG', depth: 1),
            DepthChartEntry(playerId: 'player2', position: 'SF', depth: 1),
            DepthChartEntry(playerId: 'player3', position: 'PF', depth: 1),
            DepthChartEntry(playerId: 'player4', position: 'C', depth: 1),
          ],
          lastModified: DateTime.now(),
        );
        
        expect(RotationService.hasValidMinuteDistribution(config), false);
      });
    });
  });
}
