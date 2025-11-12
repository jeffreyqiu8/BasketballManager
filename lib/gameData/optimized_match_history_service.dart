import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_result.dart';
import 'match_history_service.dart';
import 'performance_optimizer.dart';
import 'memory_manager.dart';
import 'performance_profiler.dart';

/// Enhanced match history service with performance optimizations for large datasets
class OptimizedMatchHistoryService extends MatchHistoryService {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  final MemoryManager _memoryManager = MemoryManager();
  final PerformanceProfiler _profiler = PerformanceProfiler();

  static const int _defaultPageSize = 50;
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get paginated match history with caching
  Future<List<GameResult>> getPaginatedMatchHistory(
    String teamName, {
    int? season,
    int offset = 0,
    int limit = _defaultPageSize,
    String? sortBy,
    bool descending = true,
  }) async {
    return _profiler.profileAsyncFunction(
      'getPaginatedMatchHistory',
      () => _getPaginatedMatchHistoryImpl(teamName, season, offset, limit, sortBy, descending),
      metadata: {
        'teamName': teamName,
        'season': season,
        'offset': offset,
        'limit': limit,
      },
    );
  }

  Future<List<GameResult>> _getPaginatedMatchHistoryImpl(
    String teamName,
    int? season,
    int offset,
    int limit,
    String? sortBy,
    bool descending,
  ) async {
    // Check cache first
    final cached = _optimizer.getCachedMatchHistory(
      teamName,
      season ?? 0,
      offset: offset,
      limit: limit,
    );
    
    if (cached.isNotEmpty) {
      return cached.map((item) => GameResult.fromMap(item)).toList();
    }

    // Build query
    Query query = FirebaseFirestore.instance.collection('match_history');
    
    // Filter by season if provided
    if (season != null) {
      query = query.where('season', isEqualTo: season);
    }

    // Apply sorting
    final sortField = sortBy ?? 'gameDate';
    query = query.orderBy(sortField, descending: descending);

    // Get games where team is either home or away
    final homeGamesQuery = query.where('homeTeam', isEqualTo: teamName);
    final awayGamesQuery = query.where('awayTeam', isEqualTo: teamName);

    // Execute queries in parallel
    final futures = [
      _executePaginatedQuery(homeGamesQuery, offset, limit),
      _executePaginatedQuery(awayGamesQuery, offset, limit),
    ];

    final results = await Future.wait(futures);
    final allGames = <GameResult>[];
    
    // Combine and deduplicate results
    final seenGameIds = <String>{};
    for (final gameList in results) {
      for (final game in gameList) {
        if (!seenGameIds.contains(game.gameId)) {
          seenGameIds.add(game.gameId);
          allGames.add(game);
        }
      }
    }

    // Sort combined results
    allGames.sort((a, b) => descending 
        ? b.gameDate.compareTo(a.gameDate)
        : a.gameDate.compareTo(b.gameDate));

    // Apply pagination to combined results
    final paginatedGames = allGames.skip(offset).take(limit).toList();

    // Cache the results
    _optimizer.cacheMatchHistory(
      teamName,
      season ?? 0,
      paginatedGames.map((game) => game.toMap()).toList(),
      offset: offset,
      limit: limit,
    );

    return paginatedGames;
  }

  /// Execute paginated query with optimization
  Future<List<GameResult>> _executePaginatedQuery(
    Query query,
    int offset,
    int limit,
  ) async {
    // Apply pagination
    if (offset > 0) {
      final offsetSnapshot = await query.limit(offset).get();
      if (offsetSnapshot.docs.isNotEmpty) {
        query = query.startAfterDocument(offsetSnapshot.docs.last);
      }
    }

    final querySnapshot = await query.limit(limit).get();
    return querySnapshot.docs
        .map((doc) => GameResult.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get cached season statistics with lazy loading
  Future<Map<String, dynamic>> getCachedSeasonStats(String teamName, int season) async {
    return _profiler.profileAsyncFunction(
      'getCachedSeasonStats',
      () => _getCachedSeasonStatsImpl(teamName, season),
      metadata: {'teamName': teamName, 'season': season},
    );
  }

  Future<Map<String, dynamic>> _getCachedSeasonStatsImpl(String teamName, int season) async {
    // Check cache first
    final cached = _optimizer.getCachedSeasonStats(teamName, season);
    if (cached.isNotEmpty) {
      return cached;
    }

    // Calculate stats from match history
    final seasonGames = await getPaginatedMatchHistory(
      teamName,
      season: season,
      limit: 1000, // Get all games for the season
    );

    final stats = _calculateSeasonStats(teamName, seasonGames);
    
    // Cache the results
    _optimizer.cacheSeasonStats(teamName, season, stats);
    
    return stats;
  }

  /// Calculate comprehensive season statistics
  Map<String, dynamic> _calculateSeasonStats(String teamName, List<GameResult> games) {
    if (games.isEmpty) {
      return _getEmptySeasonStats();
    }

    int wins = 0;
    int losses = 0;
    int homeWins = 0;
    int homeLosses = 0;
    int awayWins = 0;
    int awayLosses = 0;
    int totalPointsScored = 0;
    int totalPointsAllowed = 0;
    int playoffGames = 0;
    int playoffWins = 0;

    final monthlyStats = <String, Map<String, int>>{};
    final opponentStats = <String, Map<String, int>>{};

    for (final game in games) {
      final isWin = game.getResultForTeam(teamName) == 'W';
      final isHome = game.isHomeGameForTeam(teamName);
      
      // Basic win/loss tracking
      if (isWin) {
        wins++;
        if (isHome) {
          homeWins++;
        } else {
          awayWins++;
        }
      } else {
        losses++;
        if (isHome) {
          homeLosses++;
        } else {
          awayLosses++;
        }
      }

      // Points tracking
      if (isHome) {
        totalPointsScored += game.homeScore;
        totalPointsAllowed += game.awayScore;
      } else {
        totalPointsScored += game.awayScore;
        totalPointsAllowed += game.homeScore;
      }

      // Playoff tracking
      if (game.isPlayoffGame) {
        playoffGames++;
        if (isWin) playoffWins++;
      }

      // Monthly stats
      final month = '${game.gameDate.year}-${game.gameDate.month.toString().padLeft(2, '0')}';
      monthlyStats.putIfAbsent(month, () => {'wins': 0, 'losses': 0});
      monthlyStats[month]![isWin ? 'wins' : 'losses'] = 
          (monthlyStats[month]![isWin ? 'wins' : 'losses'] ?? 0) + 1;

      // Opponent stats
      final opponent = isHome ? game.awayTeam : game.homeTeam;
      opponentStats.putIfAbsent(opponent, () => {'wins': 0, 'losses': 0});
      opponentStats[opponent]![isWin ? 'wins' : 'losses'] = 
          (opponentStats[opponent]![isWin ? 'wins' : 'losses'] ?? 0) + 1;
    }

    final totalGames = games.length;
    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'winPercentage': totalGames > 0 ? (wins / totalGames) * 100 : 0.0,
      'homeRecord': '$homeWins-$homeLosses',
      'awayRecord': '$awayWins-$awayLosses',
      'averagePointsScored': totalGames > 0 ? totalPointsScored / totalGames : 0.0,
      'averagePointsAllowed': totalGames > 0 ? totalPointsAllowed / totalGames : 0.0,
      'pointsDifferential': totalPointsScored - totalPointsAllowed,
      'playoffGames': playoffGames,
      'playoffWins': playoffWins,
      'playoffWinPercentage': playoffGames > 0 ? (playoffWins / playoffGames) * 100 : 0.0,
      'monthlyStats': monthlyStats,
      'opponentStats': opponentStats,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Get optimized head-to-head history with caching
  @override
  Future<List<GameResult>> getHeadToHeadHistory(String team1, String team2) async {
    return _profiler.profileAsyncFunction(
      'getHeadToHeadHistory',
      () => _getHeadToHeadHistoryImpl(team1, team2),
      metadata: {'team1': team1, 'team2': team2},
    );
  }

  Future<List<GameResult>> _getHeadToHeadHistoryImpl(String team1, String team2) async {
    // Check cache first
    final cached = _optimizer.getCachedHeadToHead(team1, team2);
    if (cached.isNotEmpty) {
      return cached.map((item) => GameResult.fromMap(item)).toList();
    }

    // Execute the original query
    final games = await super.getHeadToHeadHistory(team1, team2);
    
    // Cache the results
    _optimizer.cacheHeadToHead(
      team1,
      team2,
      games.map((game) => game.toMap()).toList(),
    );

    return games;
  }

  /// Batch process multiple team statistics efficiently
  Future<Map<String, Map<String, dynamic>>> batchGetSeasonStats(
    List<String> teamNames,
    int season,
  ) async {
    return _profiler.profileAsyncFunction(
      'batchGetSeasonStats',
      () => _batchGetSeasonStatsImpl(teamNames, season),
      metadata: {'teamCount': teamNames.length, 'season': season},
    );
  }

  Future<Map<String, Map<String, dynamic>>> _batchGetSeasonStatsImpl(
    List<String> teamNames,
    int season,
  ) async {
    return _memoryManager.processBatchedTeams(
      teamNames,
      (teamName) async {
        final stats = await getCachedSeasonStats(teamName, season);
        return MapEntry(teamName, stats);
      },
    ).then((results) => Map.fromEntries(results));
  }

  /// Stream large match history datasets efficiently
  Stream<GameResult> streamMatchHistory(
    String teamName, {
    int? season,
    int batchSize = 100,
  }) async* {
    int offset = 0;
    bool hasMore = true;

    while (hasMore) {
      final batch = await getPaginatedMatchHistory(
        teamName,
        season: season,
        offset: offset,
        limit: batchSize,
      );

      if (batch.isEmpty) {
        hasMore = false;
        break;
      }

      for (final game in batch) {
        yield game;
      }

      offset += batchSize;
      hasMore = batch.length == batchSize;

      // Allow other operations between batches
      await Future.delayed(Duration.zero);
    }
  }

  /// Record game result with cache invalidation
  @override
  Future<void> recordGameResult(GameResult result) async {
    await _profiler.profileAsyncFunction(
      'recordGameResult',
      () => _recordGameResultImpl(result),
      metadata: {'gameId': result.gameId, 'season': result.season},
    );
  }

  Future<void> _recordGameResultImpl(GameResult result) async {
    // Record the game
    await super.recordGameResult(result);
    
    // Invalidate related caches
    _optimizer.invalidateRelatedCaches('match_history', result.homeTeam);
    _optimizer.invalidateRelatedCaches('match_history', result.awayTeam);
    _optimizer.invalidateRelatedCaches('match_history', result.season.toString());
  }

  /// Get performance and memory statistics
  Map<String, dynamic> getPerformanceStatistics() {
    return {
      'cache': _optimizer.getCacheStatistics(),
      'memory': _memoryManager.getMemoryStatistics(),
      'performance': _profiler.getAllStats(),
    };
  }

  /// Optimize performance and clear expired caches
  void optimizePerformance() {
    _optimizer.optimizeMemoryUsage();
    _memoryManager.performCleanup();
  }

  /// Preload frequently accessed match history data
  Future<void> preloadMatchHistoryData(List<String> teamNames, int currentSeason) async {
    await _profiler.profileAsyncFunction(
      'preloadMatchHistoryData',
      () => _preloadMatchHistoryDataImpl(teamNames, currentSeason),
      metadata: {'teamCount': teamNames.length, 'season': currentSeason},
    );
  }

  Future<void> _preloadMatchHistoryDataImpl(List<String> teamNames, int currentSeason) async {
    // Preload recent games for each team
    const batchSize = 5;
    for (int i = 0; i < teamNames.length; i += batchSize) {
      final batch = teamNames.skip(i).take(batchSize);
      final futures = batch.map((teamName) => 
          getPaginatedMatchHistory(teamName, season: currentSeason, limit: 20));
      
      await Future.wait(futures);
      
      // Allow other operations between batches
      await Future.delayed(Duration.zero);
    }
  }

  /// Get empty season stats template
  Map<String, dynamic> _getEmptySeasonStats() {
    return {
      'totalGames': 0,
      'wins': 0,
      'losses': 0,
      'winPercentage': 0.0,
      'homeRecord': '0-0',
      'awayRecord': '0-0',
      'averagePointsScored': 0.0,
      'averagePointsAllowed': 0.0,
      'pointsDifferential': 0,
      'playoffGames': 0,
      'playoffWins': 0,
      'playoffWinPercentage': 0.0,
      'monthlyStats': <String, Map<String, int>>{},
      'opponentStats': <String, Map<String, int>>{},
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources and clear caches
  void dispose() {
    _optimizer.clearAllCaches();
    _memoryManager.clearAll();
    _profiler.clear();
  }
}