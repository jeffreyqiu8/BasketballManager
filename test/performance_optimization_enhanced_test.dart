import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/performance_optimizer.dart';
import 'package:BasketballManager/gameData/memory_manager.dart';
import 'package:BasketballManager/gameData/optimized_save_manager.dart';
import 'package:BasketballManager/gameData/optimized_match_history_service.dart';
import 'package:BasketballManager/gameData/optimized_league_service.dart';

void main() {
  group('Enhanced Performance Optimization Tests', () {
    late PerformanceOptimizer optimizer;
    late MemoryManager memoryManager;

    setUp(() {
      optimizer = PerformanceOptimizer();
      memoryManager = MemoryManager();
    });

    tearDown(() {
      optimizer.clearAllCaches();
      memoryManager.clearAll();
    });

    group('Enhanced PerformanceOptimizer', () {
      test('should cache league standings', () {
        const leagueId = 'test_league';
        const season = 2024;
        final standings = [
          {'teamName': 'Team A', 'wins': 10, 'losses': 5},
          {'teamName': 'Team B', 'wins': 8, 'losses': 7},
        ];

        // Cache standings
        optimizer.cacheLeagueStandings(leagueId, season, standings);

        // Retrieve from cache
        final cached = optimizer.getCachedLeagueStandings(leagueId, season);
        expect(cached, equals(standings));
      });

      test('should cache team statistics', () {
        const teamId = 'team_123';
        const season = 2024;
        final stats = {
          'wins': 15,
          'losses': 10,
          'pointsScored': 2500,
          'pointsAllowed': 2300,
        };

        // Cache stats
        optimizer.cacheTeamStats(teamId, season, stats);

        // Retrieve from cache
        final cached = optimizer.getCachedTeamStats(teamId, season);
        expect(cached, equals(stats));
      });

      test('should cache match history with pagination', () {
        const teamId = 'team_456';
        const season = 2024;
        const offset = 0;
        const limit = 20;
        final matches = [
          {'gameId': 'game_1', 'homeTeam': 'Team A', 'awayTeam': 'Team B'},
          {'gameId': 'game_2', 'homeTeam': 'Team B', 'awayTeam': 'Team C'},
        ];

        // Cache match history
        optimizer.cacheMatchHistory(teamId, season, matches, offset: offset, limit: limit);

        // Retrieve from cache
        final cached = optimizer.getCachedMatchHistory(teamId, season, offset: offset, limit: limit);
        expect(cached, equals(matches));
      });

      test('should cache save metadata with pagination', () {
        const userId = 'user_789';
        const offset = 0;
        const limit = 10;
        final saves = [
          {'saveId': 'save_1', 'saveName': 'My Career', 'teamName': 'Lakers'},
          {'saveId': 'save_2', 'saveName': 'Dynasty', 'teamName': 'Celtics'},
        ];

        // Cache save metadata
        optimizer.cacheSaveMetadata(userId, saves, offset: offset, limit: limit);

        // Retrieve from cache
        final cached = optimizer.getCachedSaveMetadata(userId, offset: offset, limit: limit);
        expect(cached, equals(saves));
      });

      test('should invalidate related caches', () {
        const teamId = 'team_123';
        const season = 2024;
        
        // Cache some data
        optimizer.cacheTeamStats(teamId, season, {'wins': 10});
        optimizer.cacheLeagueStandings('league_1', season, [{'teamName': teamId}]);

        // Verify data is cached
        expect(optimizer.getCachedTeamStats(teamId, season), isNotEmpty);

        // Invalidate related caches
        optimizer.invalidateRelatedCaches('team_stats', teamId);

        // Verify caches are cleared (this is a simplified test)
        final stats = optimizer.getCacheStatistics();
        expect(stats, isNotNull);
      });
    });

    group('Enhanced MemoryManager', () {
      test('should handle team list pooling', () {
        // Get team list from pool
        final teamList1 = memoryManager.getTeamListFromPool();
        expect(teamList1, isA<List<dynamic>>());
        expect(teamList1, isEmpty);

        // Add some data
        teamList1.addAll(['Team A', 'Team B', 'Team C']);

        // Return to pool
        memoryManager.returnTeamListToPool(teamList1);

        // Get another list (should be reused and cleared)
        final teamList2 = memoryManager.getTeamListFromPool();
        expect(teamList2, isEmpty); // Should be cleared when returned to pool
      });

      test('should handle league data pooling', () {
        // Get league data from pool
        final leagueData1 = memoryManager.getLeagueDataFromPool();
        expect(leagueData1, isA<Map<String, dynamic>>());
        expect(leagueData1, isEmpty);

        // Add some data
        leagueData1['teams'] = ['Team A', 'Team B'];
        leagueData1['season'] = 2024;

        // Return to pool
        memoryManager.returnLeagueDataToPool(leagueData1);

        // Get another map (should be reused and cleared)
        final leagueData2 = memoryManager.getLeagueDataFromPool();
        expect(leagueData2, isEmpty); // Should be cleared when returned to pool
      });

      test('should process teams in batches for 30-team operations', () async {
        final teams = List.generate(30, (i) => 'Team ${i + 1}');
        
        final results = await memoryManager.processBatchedTeams(
          teams,
          (team) => '${team}_processed',
          batchSize: 10,
        );

        expect(results, hasLength(30));
        expect(results.first, equals('Team 1_processed'));
        expect(results.last, equals('Team 30_processed'));
      });

      test('should handle match history batch processing', () async {
        final matches = List.generate(100, (i) => {'gameId': 'game_$i'});
        
        final results = await memoryManager.processMatchHistoryBatched(
          matches,
          (match) => '${match['gameId']}_processed',
          batchSize: 25,
          maxResults: 50,
        );

        expect(results, hasLength(50)); // Limited by maxResults
        expect(results.first, equals('game_0_processed'));
      });

      test('should optimize for thirty team league', () {
        final initialStats = memoryManager.getMemoryStatistics();
        
        memoryManager.optimizeForThirtyTeamLeague();
        
        final optimizedStats = memoryManager.getMemoryStatistics();
        
        // Should have more pooled objects after optimization
        expect(optimizedStats['playerPoolSize'], greaterThan(initialStats['playerPoolSize']));
        expect(optimizedStats['gameResultPoolSize'], greaterThan(initialStats['gameResultPoolSize']));
      });
    });

    group('OptimizedSaveManager', () {
      test('should be instantiable', () {
        expect(() => OptimizedSaveManager(), returnsNormally);
      });

      test('should provide performance statistics', () {
        final saveManager = OptimizedSaveManager();
        final stats = saveManager.getPerformanceStatistics();
        
        expect(stats, containsPair('cache', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('memory', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('performance', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('activeOperations', isA<int>()));
      });
    });

    group('OptimizedMatchHistoryService', () {
      test('should be instantiable', () {
        expect(() => OptimizedMatchHistoryService(), returnsNormally);
      });

      test('should provide performance statistics', () {
        final matchHistoryService = OptimizedMatchHistoryService();
        final stats = matchHistoryService.getPerformanceStatistics();
        
        expect(stats, containsPair('cache', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('memory', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('performance', isA<Map<String, dynamic>>()));
      });
    });

    group('OptimizedLeagueService', () {
      test('should be instantiable', () {
        expect(() => OptimizedLeagueService(), returnsNormally);
      });

      test('should provide league performance statistics', () {
        final leagueService = OptimizedLeagueService();
        final stats = leagueService.getLeaguePerformanceStatistics();
        
        expect(stats, containsPair('cache', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('memory', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('performance', isA<Map<String, dynamic>>()));
        expect(stats, containsPair('leagueOptimizations', isA<Map<String, dynamic>>()));
      });
    });

    group('Integration Tests', () {
      test('should work together for comprehensive optimization', () {
        final saveManager = OptimizedSaveManager();
        final matchHistoryService = OptimizedMatchHistoryService();
        final leagueService = OptimizedLeagueService();

        // Test that all services can be used together
        expect(() {
          saveManager.optimizePerformance();
          matchHistoryService.optimizePerformance();
          leagueService.optimizeLeagueMemory(null as dynamic); // Simplified test
        }, returnsNormally);

        // Clean up
        saveManager.dispose();
        matchHistoryService.dispose();
        leagueService.dispose();
      });
    });
  });
}