import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/performance_optimizer.dart';
import 'package:BasketballManager/gameData/performance_profiler.dart';
import 'package:BasketballManager/gameData/memory_manager.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/gameData/development_system.dart';

void main() {
  group('Performance Optimization Tests', () {
    late PerformanceOptimizer optimizer;
    late PerformanceProfiler profiler;
    late MemoryManager memoryManager;

    setUp(() {
      optimizer = PerformanceOptimizer();
      profiler = PerformanceProfiler();
      memoryManager = MemoryManager();
      
      // Clear any existing data
      optimizer.clearAllCaches();
      profiler.clear();
      memoryManager.clearAll();
    });

    group('PerformanceOptimizer', () {
      test('should cache role compatibility calculations', () {
        final player = _createTestPlayer('Test Player');
        
        // First call should calculate and cache
        final compatibility1 = optimizer.getCachedRoleCompatibility(player);
        expect(compatibility1, isNotEmpty);
        
        // Second call should use cache
        final compatibility2 = optimizer.getCachedRoleCompatibility(player);
        expect(compatibility2, equals(compatibility1));
        
        // Verify cache statistics
        final stats = optimizer.getCacheStatistics();
        expect(stats['roleCompatibilityCache']['size'], greaterThan(0));
      });

      test('should cache playbook effectiveness', () {
        final playbook = _createTestPlaybook();
        final players = [_createTestPlayer('Player 1'), _createTestPlayer('Player 2')];
        
        // First call should calculate and cache
        final effectiveness1 = optimizer.getCachedPlaybookEffectiveness(playbook, players);
        expect(effectiveness1, isNotEmpty);
        
        // Second call should use cache
        final effectiveness2 = optimizer.getCachedPlaybookEffectiveness(playbook, players);
        expect(effectiveness2, equals(effectiveness1));
      });

      test('should cache optimal lineup calculations', () {
        final players = List.generate(5, (i) => _createTestPlayer('Player $i'));
        
        // First call should calculate and cache
        final lineup1 = optimizer.getCachedOptimalLineup(players);
        expect(lineup1.length, equals(5));
        
        // Second call should use cache
        final lineup2 = optimizer.getCachedOptimalLineup(players);
        expect(lineup2.length, equals(lineup1.length));
      });

      test('should batch process players efficiently', () {
        final players = List.generate(10, (i) => _createTestPlayer('Player $i'));
        
        final compatibilities = optimizer.batchProcessRoleCompatibility(players);
        expect(compatibilities.length, equals(players.length));
        
        for (final compatibility in compatibilities) {
          expect(compatibility, isNotEmpty);
        }
      });

      test('should filter players by role efficiently', () {
        final players = [
          _createTestPlayer('PG', role: PlayerRole.pointGuard),
          _createTestPlayer('SG', role: PlayerRole.shootingGuard),
          _createTestPlayer('SF', role: PlayerRole.smallForward),
          _createTestPlayer('PF', role: PlayerRole.powerForward),
          _createTestPlayer('C', role: PlayerRole.center),
        ];
        
        final guards = optimizer.filterPlayersByRole(players, PlayerRole.pointGuard);
        expect(guards.length, equals(1));
        expect(guards.first.name, equals('PG'));
        
        final limitedPlayers = optimizer.filterPlayersByRole(players, PlayerRole.shootingGuard, limit: 1);
        expect(limitedPlayers.length, equals(1));
      });

      test('should clear expired caches', () {
        final player = _createTestPlayer('Test Player');
        
        // Add to cache
        optimizer.getCachedRoleCompatibility(player);
        
        // Verify cache has data
        var stats = optimizer.getCacheStatistics();
        expect(stats['roleCompatibilityCache']['size'], greaterThan(0));
        
        // Clear expired caches
        optimizer.clearExpiredCaches();
        
        // Cache should still have data (not expired yet)
        stats = optimizer.getCacheStatistics();
        expect(stats['roleCompatibilityCache']['size'], greaterThan(0));
      });

      test('should optimize memory usage', () {
        // Fill caches with data
        for (int i = 0; i < 50; i++) {
          final player = _createTestPlayer('Player $i');
          optimizer.getCachedRoleCompatibility(player);
        }
        
        final statsBefore = optimizer.getCacheStatistics();
        
        // Optimize memory
        optimizer.optimizeMemoryUsage();
        
        final statsAfter = optimizer.getCacheStatistics();
        
        // Should have cleaned up some entries
        expect(statsAfter['roleCompatibilityCache']['size'], 
               lessThanOrEqualTo(statsBefore['roleCompatibilityCache']['size']));
      });
    });

    group('PerformanceProfiler', () {
      test('should profile function execution', () {
        final result = profiler.profileFunction('test_operation', () {
          // Simulate some work
          var sum = 0;
          for (int i = 0; i < 1000; i++) {
            sum += i;
          }
          return sum;
        });
        
        expect(result, equals(499500)); // Sum of 0 to 999
        
        final stats = profiler.getStats('test_operation');
        expect(stats, isNotNull);
        expect(stats!.count, equals(1));
        expect(stats.averageDurationMicros, greaterThan(0));
      });

      test('should profile async function execution', () async {
        final result = await profiler.profileAsyncFunction('async_test_operation', () async {
          await Future.delayed(Duration(milliseconds: 10));
          return 'completed';
        });
        
        expect(result, equals('completed'));
        
        final stats = profiler.getStats('async_test_operation');
        expect(stats, isNotNull);
        expect(stats!.count, equals(1));
        expect(stats.averageDurationMicros, greaterThan(10000)); // At least 10ms
      });

      test('should calculate performance statistics correctly', () {
        // Profile multiple executions
        for (int i = 0; i < 10; i++) {
          profiler.profileFunction('multi_test', () {
            // Variable work to create different durations
            var sum = 0;
            for (int j = 0; j < (i + 1) * 100; j++) {
              sum += j;
            }
            return sum;
          });
        }
        
        final stats = profiler.getStats('multi_test');
        expect(stats, isNotNull);
        expect(stats!.count, equals(10));
        expect(stats.averageDurationMicros, greaterThan(0));
        expect(stats.minDurationMicros, lessThanOrEqualTo(stats.maxDurationMicros));
        expect(stats.medianDurationMicros, greaterThan(0));
        expect(stats.p95DurationMicros, greaterThan(0));
        expect(stats.p99DurationMicros, greaterThan(0));
      });

      test('should detect performance bottlenecks', () {
        // Create a slow operation
        profiler.profileFunction('slow_operation', () {
          // Simulate slow work
          var sum = 0;
          for (int i = 0; i < 100000; i++) {
            sum += i;
          }
          return sum;
        });
        
        // Create a fast but frequent operation
        for (int i = 0; i < 1500; i++) {
          profiler.profileFunction('frequent_operation', () {
            return i * 2;
          });
        }
        
        final bottlenecks = profiler.detectBottlenecks();
        expect(bottlenecks, isNotEmpty);
        
        // Should detect the frequent operation as a bottleneck
        final frequentBottleneck = bottlenecks.firstWhere(
          (b) => b.operationName == 'frequent_operation',
          orElse: () => bottlenecks.first,
        );
        expect(frequentBottleneck.type, equals(BottleneckType.frequentSlow));
      });

      test('should generate performance report', () {
        // Add some test operations
        profiler.profileFunction('fast_op', () => 1);
        profiler.profileFunction('slow_op', () {
          var sum = 0;
          for (int i = 0; i < 10000; i++) {
            sum += i;
          }
          return sum;
        });
        
        final report = profiler.getReport();
        expect(report.totalOperations, equals(2));
        expect(report.uniqueOperations, equals(2));
        expect(report.slowestOperations, isNotEmpty);
        expect(report.allStats, hasLength(2));
      });

      test('should handle errors in profiled functions', () {
        expect(() {
          profiler.profileFunction('error_operation', () {
            throw Exception('Test error');
          });
        }, throwsException);
        
        final stats = profiler.getStats('error_operation');
        expect(stats, isNotNull);
        expect(stats!.count, equals(1));
      });
    });

    group('MemoryManager', () {
      test('should reuse player objects from pool', () {
        final player1 = memoryManager.getPlayerFromPool();
        expect(player1, isNotNull);
        
        // Return to pool
        memoryManager.returnPlayerToPool(player1);
        
        // Get another player (should be the same object)
        final player2 = memoryManager.getPlayerFromPool();
        expect(player2, same(player1));
        
        final stats = memoryManager.getMemoryStatistics();
        expect(stats['pooledObjects'], greaterThan(0));
      });

      test('should reuse game result maps from pool', () {
        final result1 = memoryManager.getGameResultFromPool();
        result1['test'] = 'value';
        
        // Return to pool
        memoryManager.returnGameResultToPool(result1);
        
        // Get another result (should be the same object, but cleared)
        final result2 = memoryManager.getGameResultFromPool();
        expect(result2, same(result1));
        expect(result2, isEmpty); // Should be cleared
      });

      test('should process players in batches', () async {
        final players = List.generate(100, (i) => _createTestPlayer('Player $i'));
        
        final results = await memoryManager.processBatchedPlayers(
          players,
          (player) => player.name.length,
          batchSize: 25,
        );
        
        expect(results.length, equals(100));
        expect(results.every((r) => r > 0), isTrue);
      });

      test('should stream process players', () async {
        final players = List.generate(10, (i) => _createTestPlayer('Player $i'));
        
        final results = <String>[];
        await for (final name in memoryManager.streamProcessPlayers(players, (p) => p.name)) {
          results.add(name);
        }
        
        expect(results.length, equals(10));
        expect(results.first, equals('Player 0'));
      });

      test('should compress and decompress player data', () {
        final originalPlayer = _createTestPlayer('Test Player');
        
        final compressed = memoryManager.compressPlayerData(originalPlayer);
        expect(compressed, isMap);
        expect(compressed['n'], equals('Test Player'));
        
        final decompressed = memoryManager.decompressPlayerData(compressed);
        expect(decompressed.name, equals(originalPlayer.name));
        expect(decompressed.age, equals(originalPlayer.age));
      });

      test('should store and retrieve weak references', () {
        final team = _createTestTeam();
        
        // Store weak reference
        memoryManager.storeTeamReference('test_team', team);
        
        // Retrieve reference
        final retrievedTeam = memoryManager.getTeamReference('test_team');
        expect(retrievedTeam, same(team));
      });

      test('should optimize for large rosters', () {
        final statsBefore = memoryManager.getMemoryStatistics();
        
        memoryManager.optimizeForLargeRosters();
        
        final statsAfter = memoryManager.getMemoryStatistics();
        
        // Pool sizes should have increased
        expect(statsAfter['playerPoolSize'], greaterThan(statsBefore['playerPoolSize']));
        expect(statsAfter['gameResultPoolSize'], greaterThan(statsBefore['gameResultPoolSize']));
      });
    });

    group('Integration Tests', () {
      test('should work together for game simulation optimization', () {
        final players = List.generate(10, (i) => _createTestPlayer('Player $i'));
        
        // Use optimizer to get cached lineup
        final lineup = optimizer.getCachedOptimalLineup(players.take(5).toList());
        expect(lineup.length, equals(5));
        
        // Profile the operation
        final result = profiler.profileFunction('integration_test', () {
          return optimizer.getCachedTeamChemistry(lineup);
        });
        
        expect(result, greaterThanOrEqualTo(0));
        
        final stats = profiler.getStats('integration_test');
        expect(stats, isNotNull);
        expect(stats!.count, equals(1));
      });

      test('should handle memory cleanup during intensive operations', () {
        // Simulate intensive operations
        for (int i = 0; i < 100; i++) {
          final player = _createTestPlayer('Player $i');
          optimizer.getCachedRoleCompatibility(player);
          
          profiler.profileFunction('intensive_op_$i', () {
            return player.shooting + player.rebounding;
          });
        }
        
        // Perform cleanup
        optimizer.optimizeMemoryUsage();
        memoryManager.performCleanup();
        
        // Should still function correctly
        final newPlayer = _createTestPlayer('New Player');
        final compatibility = optimizer.getCachedRoleCompatibility(newPlayer);
        expect(compatibility, isNotEmpty);
      });
    });
  });
}

// Helper functions for creating test objects
EnhancedPlayer _createTestPlayer(String name, {PlayerRole? role}) {
  return EnhancedPlayer(
    name: name,
    age: 25,
    team: 'Test Team',
    experienceYears: 3,
    nationality: 'USA',
    currentStatus: 'Active',
    height: 185,
    shooting: 75,
    rebounding: 70,
    passing: 65,
    ballHandling: 68,
    perimeterDefense: 72,
    postDefense: 60,
    insideShooting: 65,
    performances: {},
    primaryRole: role ?? PlayerRole.shootingGuard,
    potential: PlayerPotential.fromTier(PotentialTier.silver),
    development: DevelopmentTracker.initial(age: 25),
  );
}

Playbook _createTestPlaybook() {
  return Playbook(
    name: 'Test Playbook',
    offensiveStrategy: OffensiveStrategy.halfCourt,
    defensiveStrategy: DefensiveStrategy.manToMan,
  );
}

EnhancedTeam _createTestTeam() {
  final players = List.generate(5, (i) => _createTestPlayer('Player $i'));
  return EnhancedTeam(
    name: 'Test Team',
    reputation: 75,
    playerCount: 5,
    teamSize: 15,
    players: players,
    wins: 0,
    losses: 0,
    starters: players,
  );
}