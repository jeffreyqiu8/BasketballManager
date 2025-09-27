import 'dart:async';
import 'dart:collection';
import 'enhanced_player.dart';
import 'enhanced_team.dart';
import 'enums.dart';
import 'development_system.dart';

/// Memory management service for optimizing large dataset handling
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Object pools for reusing expensive objects
  final Queue<EnhancedPlayer> _playerPool = Queue<EnhancedPlayer>();
  final Queue<Map<String, dynamic>> _gameResultPool =
      Queue<Map<String, dynamic>>();
  final Queue<Map<String, int>> _boxScorePool = Queue<Map<String, int>>();

  // Weak references for large objects
  final Map<String, WeakReference<EnhancedTeam>> _teamReferences = {};
  final Map<String, WeakReference<List<EnhancedPlayer>>> _rosterReferences = {};

  // Memory usage tracking
  int _allocatedObjects = 0;
  int _pooledObjects = 0;
  DateTime _lastCleanup = DateTime.now();

  static const int _maxPoolSize = 100;
  static const Duration _cleanupInterval = Duration(minutes: 5);

  /// Get a player object from pool or create new one
  EnhancedPlayer getPlayerFromPool() {
    if (_playerPool.isNotEmpty) {
      _pooledObjects++;
      return _playerPool.removeFirst();
    }

    _allocatedObjects++;
    return _createEmptyPlayer();
  }

  /// Return player object to pool for reuse
  void returnPlayerToPool(EnhancedPlayer player) {
    if (_playerPool.length < _maxPoolSize) {
      _resetPlayer(player);
      _playerPool.add(player);
    }
  }

  /// Get game result map from pool or create new one
  Map<String, dynamic> getGameResultFromPool() {
    if (_gameResultPool.isNotEmpty) {
      _pooledObjects++;
      return _gameResultPool.removeFirst();
    }

    _allocatedObjects++;
    return <String, dynamic>{};
  }

  /// Return game result map to pool for reuse
  void returnGameResultToPool(Map<String, dynamic> result) {
    if (_gameResultPool.length < _maxPoolSize) {
      result.clear();
      _gameResultPool.add(result);
    }
  }

  /// Get box score map from pool or create new one
  Map<String, int> getBoxScoreFromPool() {
    if (_boxScorePool.isNotEmpty) {
      _pooledObjects++;
      return _boxScorePool.removeFirst();
    }

    _allocatedObjects++;
    return <String, int>{};
  }

  /// Return box score map to pool for reuse
  void returnBoxScoreToPool(Map<String, int> boxScore) {
    if (_boxScorePool.length < _maxPoolSize) {
      boxScore.clear();
      _boxScorePool.add(boxScore);
    }
  }

  /// Store team with weak reference to allow garbage collection
  void storeTeamReference(String teamId, EnhancedTeam team) {
    _teamReferences[teamId] = WeakReference(team);
  }

  /// Get team from weak reference if still available
  EnhancedTeam? getTeamReference(String teamId) {
    final ref = _teamReferences[teamId];
    return ref?.target;
  }

  /// Store roster with weak reference
  void storeRosterReference(String rosterId, List<EnhancedPlayer> roster) {
    _rosterReferences[rosterId] = WeakReference(roster);
  }

  /// Get roster from weak reference if still available
  List<EnhancedPlayer>? getRosterReference(String rosterId) {
    final ref = _rosterReferences[rosterId];
    return ref?.target;
  }

  /// Process large player datasets in batches to avoid memory spikes
  Future<List<T>> processBatchedPlayers<T>(
    List<EnhancedPlayer> players,
    T Function(EnhancedPlayer) processor, {
    int batchSize = 50,
  }) async {
    final results = <T>[];

    for (int i = 0; i < players.length; i += batchSize) {
      final batch = players.skip(i).take(batchSize);
      final batchResults = batch.map(processor).toList();
      results.addAll(batchResults);

      // Allow other operations to run between batches
      if (i + batchSize < players.length) {
        await Future.delayed(Duration.zero);
      }
    }

    return results;
  }

  /// Stream-based processing for very large datasets
  Stream<T> streamProcessPlayers<T>(
    List<EnhancedPlayer> players,
    T Function(EnhancedPlayer) processor,
  ) async* {
    for (final player in players) {
      yield processor(player);

      // Periodic cleanup during streaming
      if (_shouldPerformCleanup()) {
        performCleanup();
      }
    }
  }

  /// Lazy loading iterator for memory-efficient iteration
  Iterable<EnhancedPlayer> lazyPlayerIterable(
    List<EnhancedPlayer> players,
  ) sync* {
    for (final player in players) {
      yield player;
    }
  }

  /// Compress player data for storage
  Map<String, dynamic> compressPlayerData(EnhancedPlayer player) {
    return {
      'n': player.name,
      'a': player.age,
      't': player.team,
      'h': player.height,
      's': player.shooting,
      'r': player.rebounding,
      'p': player.passing,
      'b': player.ballHandling,
      'pd': player.perimeterDefense,
      'po': player.postDefense,
      'i': player.insideShooting,
      'pr': player.primaryRole.index,
      // Only store essential data
    };
  }

  /// Decompress player data from storage
  EnhancedPlayer decompressPlayerData(Map<String, dynamic> data) {
    final player = getPlayerFromPool();

    player.name = data['n'] ?? '';
    player.age = data['a'] ?? 25;
    player.team = data['t'] ?? '';
    player.height = data['h'] ?? 180;
    player.shooting = data['s'] ?? 50;
    player.rebounding = data['r'] ?? 50;
    player.passing = data['p'] ?? 50;
    player.ballHandling = data['b'] ?? 50;
    player.perimeterDefense = data['pd'] ?? 50;
    player.postDefense = data['po'] ?? 50;
    player.insideShooting = data['i'] ?? 50;
    player.primaryRole = PlayerRole.values[data['pr'] ?? 0];

    return player;
  }

  /// Perform memory cleanup
  void performCleanup() {
    _lastCleanup = DateTime.now();

    // Clean up weak references
    _cleanupWeakReferences();

    // Limit pool sizes
    _limitPoolSizes();

    // Reset counters periodically
    if (_allocatedObjects > 10000) {
      _allocatedObjects = 0;
      _pooledObjects = 0;
    }
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStatistics() {
    return {
      'allocatedObjects': _allocatedObjects,
      'pooledObjects': _pooledObjects,
      'playerPoolSize': _playerPool.length,
      'gameResultPoolSize': _gameResultPool.length,
      'boxScorePoolSize': _boxScorePool.length,
      'teamReferences': _teamReferences.length,
      'rosterReferences': _rosterReferences.length,
      'lastCleanup': _lastCleanup.toIso8601String(),
      'poolEfficiency': _pooledObjects / (_allocatedObjects + _pooledObjects),
    };
  }

  /// Clear all pools and references
  void clearAll() {
    _playerPool.clear();
    _gameResultPool.clear();
    _boxScorePool.clear();
    _teamReferences.clear();
    _rosterReferences.clear();
    _allocatedObjects = 0;
    _pooledObjects = 0;
  }

  /// Optimize memory for large roster operations
  void optimizeForLargeRosters() {
    // Increase pool sizes for large operations
    while (_playerPool.length < _maxPoolSize) {
      _playerPool.add(_createEmptyPlayer());
    }

    while (_gameResultPool.length < _maxPoolSize) {
      _gameResultPool.add(<String, dynamic>{});
    }

    while (_boxScorePool.length < _maxPoolSize) {
      _boxScorePool.add(<String, int>{});
    }
  }

  // Private helper methods

  EnhancedPlayer _createEmptyPlayer() {
    return EnhancedPlayer(
      name: '',
      age: 25,
      team: '',
      experienceYears: 0,
      nationality: 'USA',
      currentStatus: 'Active',
      height: 180,
      shooting: 50,
      rebounding: 50,
      passing: 50,
      ballHandling: 50,
      perimeterDefense: 50,
      postDefense: 50,
      insideShooting: 50,
      performances: {},
      primaryRole: PlayerRole.pointGuard,
      potential: PlayerPotential.fromTier(PotentialTier.bronze),
      development: DevelopmentTracker.initial(age: 25),
    );
  }

  void _resetPlayer(EnhancedPlayer player) {
    player.name = '';
    player.age = 25;
    player.team = '';
    player.experienceYears = 0;
    player.nationality = 'USA';
    player.currentStatus = 'Active';
    player.height = 180;
    player.shooting = 50;
    player.rebounding = 50;
    player.passing = 50;
    player.ballHandling = 50;
    player.perimeterDefense = 50;
    player.postDefense = 50;
    player.insideShooting = 50;
    player.performances.clear();
    player.primaryRole = PlayerRole.pointGuard;
  }

  void _cleanupWeakReferences() {
    // Remove dead weak references
    _teamReferences.removeWhere((key, ref) => ref.target == null);
    _rosterReferences.removeWhere((key, ref) => ref.target == null);
  }

  void _limitPoolSizes() {
    // Ensure pools don't grow too large
    while (_playerPool.length > _maxPoolSize) {
      _playerPool.removeFirst();
    }

    while (_gameResultPool.length > _maxPoolSize) {
      _gameResultPool.removeFirst();
    }

    while (_boxScorePool.length > _maxPoolSize) {
      _boxScorePool.removeFirst();
    }
  }

  bool _shouldPerformCleanup() {
    return DateTime.now().difference(_lastCleanup) > _cleanupInterval;
  }
}

/// Weak reference implementation for Dart
class WeakReference<T extends Object> {
  final T _target;

  WeakReference(this._target);

  T? get target => _target;
}
