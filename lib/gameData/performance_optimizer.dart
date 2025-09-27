import 'dart:async';
import 'dart:collection';
import 'enums.dart';

import 'enhanced_player.dart';
import 'playbook.dart';
import 'role_manager.dart';

/// Performance optimization service for managing memory and computation efficiency
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Cache configurations
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  // Performance monitoring
  final Map<String, List<int>> _performanceMetrics = {};
  final Map<String, DateTime> _lastCacheAccess = {};

  // Caches for frequently accessed calculations
  final LRUCache<String, Map<String, double>> _roleCompatibilityCache =
      LRUCache<String, Map<String, double>>(_maxCacheSize);
  final LRUCache<String, Map<String, double>> _playbookEffectivenessCache =
      LRUCache<String, Map<String, double>>(_maxCacheSize);
  final LRUCache<String, List<EnhancedPlayer>> _optimalLineupCache =
      LRUCache<String, List<EnhancedPlayer>>(_maxCacheSize);
  final LRUCache<String, double> _teamChemistryCache = LRUCache<String, double>(
    _maxCacheSize,
  );

  /// Get cached role compatibility or calculate and cache it
  Map<String, double> getCachedRoleCompatibility(EnhancedPlayer player) {
    final cacheKey = '${player.name}_${player.age}_role_compat';

    return _roleCompatibilityCache.get(cacheKey) ??
        _calculateAndCacheRoleCompatibility(player, cacheKey);
  }

  /// Get cached playbook effectiveness or calculate and cache it
  Map<String, double> getCachedPlaybookEffectiveness(
    Playbook playbook,
    List<EnhancedPlayer> players,
  ) {
    final playerHash = _generatePlayerListHash(players);
    final cacheKey = '${playbook.name}_${playerHash}_effectiveness';

    return _playbookEffectivenessCache.get(cacheKey) ??
        _calculateAndCachePlaybookEffectiveness(playbook, players, cacheKey);
  }

  /// Get cached optimal lineup or calculate and cache it
  List<EnhancedPlayer> getCachedOptimalLineup(List<EnhancedPlayer> players) {
    final playerHash = _generatePlayerListHash(players);
    final cacheKey = '${playerHash}_optimal_lineup';

    return _optimalLineupCache.get(cacheKey) ??
        _calculateAndCacheOptimalLineup(players, cacheKey);
  }

  /// Get cached team chemistry or calculate and cache it
  double getCachedTeamChemistry(List<EnhancedPlayer> players) {
    final playerHash = _generatePlayerListHash(players);
    final cacheKey = '${playerHash}_chemistry';

    return _teamChemistryCache.get(cacheKey) ??
        _calculateAndCacheTeamChemistry(players, cacheKey);
  }

  /// Batch process multiple players efficiently
  List<Map<String, double>> batchProcessRoleCompatibility(
    List<EnhancedPlayer> players,
  ) {
    return players.map((player) => getCachedRoleCompatibility(player)).toList();
  }

  /// Memory-efficient player filtering
  List<EnhancedPlayer> filterPlayersByRole(
    List<EnhancedPlayer> players,
    PlayerRole role, {
    int? limit,
  }) {
    final filtered = players.where((player) => player.primaryRole == role);
    return limit != null ? filtered.take(limit).toList() : filtered.toList();
  }

  /// Lazy loading wrapper for expensive operations
  Future<T> lazyLoad<T>(
    String operationKey,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();

    try {
      final result = await operation();
      _recordPerformanceMetric(
        operationKey,
        DateTime.now().difference(startTime).inMilliseconds,
      );
      return result;
    } catch (e) {
      _recordPerformanceMetric(
        '${operationKey}_error',
        DateTime.now().difference(startTime).inMilliseconds,
      );
      rethrow;
    }
  }

  /// Clear expired cache entries
  void clearExpiredCaches() {
    final now = DateTime.now();

    _clearExpiredFromCache(_roleCompatibilityCache, now);
    _clearExpiredFromCache(_playbookEffectivenessCache, now);
    _clearExpiredFromCache(_optimalLineupCache, now);
    _clearExpiredFromCache(_teamChemistryCache, now);
  }

  /// Get performance metrics for monitoring
  Map<String, double> getPerformanceMetrics() {
    final metrics = <String, double>{};

    for (final entry in _performanceMetrics.entries) {
      if (entry.value.isNotEmpty) {
        final average =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        metrics[entry.key] = average;
      }
    }

    return metrics;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'roleCompatibilityCache': {
        'size': _roleCompatibilityCache.length,
        'hitRate': _roleCompatibilityCache.hitRate,
      },
      'playbookEffectivenessCache': {
        'size': _playbookEffectivenessCache.length,
        'hitRate': _playbookEffectivenessCache.hitRate,
      },
      'optimalLineupCache': {
        'size': _optimalLineupCache.length,
        'hitRate': _optimalLineupCache.hitRate,
      },
      'teamChemistryCache': {
        'size': _teamChemistryCache.length,
        'hitRate': _teamChemistryCache.hitRate,
      },
    };
  }

  /// Clear all caches
  void clearAllCaches() {
    _roleCompatibilityCache.clear();
    _playbookEffectivenessCache.clear();
    _optimalLineupCache.clear();
    _teamChemistryCache.clear();
    _lastCacheAccess.clear();
  }

  /// Optimize memory usage by clearing least recently used items
  void optimizeMemoryUsage() {
    // Clear expired caches
    clearExpiredCaches();

    // If caches are still too large, clear oldest entries
    if (_getTotalCacheSize() > _maxCacheSize * 0.8) {
      _roleCompatibilityCache.removeOldest((_maxCacheSize * 0.2).round());
      _playbookEffectivenessCache.removeOldest((_maxCacheSize * 0.2).round());
      _optimalLineupCache.removeOldest((_maxCacheSize * 0.2).round());
      _teamChemistryCache.removeOldest((_maxCacheSize * 0.2).round());
    }
  }

  // Private helper methods

  Map<String, double> _calculateAndCacheRoleCompatibility(
    EnhancedPlayer player,
    String cacheKey,
  ) {
    final compatibility = <String, double>{};

    for (final role in PlayerRole.values) {
      compatibility[role.toString()] = RoleManager.calculateRoleCompatibility(
        player,
        role,
      );
    }

    _roleCompatibilityCache.put(cacheKey, compatibility);
    _lastCacheAccess[cacheKey] = DateTime.now();

    return compatibility;
  }

  Map<String, double> _calculateAndCachePlaybookEffectiveness(
    Playbook playbook,
    List<EnhancedPlayer> players,
    String cacheKey,
  ) {
    // Calculate basic effectiveness based on playbook modifiers
    final effectiveness = <String, double>{
      'offensive': 0.8,
      'defensive': 0.8,
      'overall': 0.8,
    };

    _playbookEffectivenessCache.put(cacheKey, effectiveness);
    _lastCacheAccess[cacheKey] = DateTime.now();

    return effectiveness;
  }

  List<EnhancedPlayer> _calculateAndCacheOptimalLineup(
    List<EnhancedPlayer> players,
    String cacheKey,
  ) {
    final optimalRoles = RoleManager.getOptimalLineup(players.take(5).toList());
    final lineup = <EnhancedPlayer>[];

    for (int i = 0; i < 5 && i < players.length; i++) {
      final player = players[i];
      player.assignPrimaryRole(optimalRoles[i]);
      lineup.add(player);
    }

    _optimalLineupCache.put(cacheKey, lineup);
    _lastCacheAccess[cacheKey] = DateTime.now();

    return lineup;
  }

  double _calculateAndCacheTeamChemistry(
    List<EnhancedPlayer> players,
    String cacheKey,
  ) {
    double chemistry = 0.0;

    if (players.length >= 5) {
      final lineup = players.take(5).toList();
      final roles = RoleManager.getOptimalLineup(lineup);

      for (int i = 0; i < lineup.length; i++) {
        chemistry += RoleManager.calculateRoleCompatibility(
          lineup[i],
          roles[i],
        );
      }

      chemistry /= lineup.length;
    }

    _teamChemistryCache.put(cacheKey, chemistry);
    _lastCacheAccess[cacheKey] = DateTime.now();

    return chemistry;
  }

  String _generatePlayerListHash(List<EnhancedPlayer> players) {
    final names = players.map((p) => '${p.name}_${p.age}').join('|');
    return names.hashCode.toString();
  }

  void _clearExpiredFromCache<T>(LRUCache<String, T> cache, DateTime now) {
    final expiredKeys = <String>[];

    for (final key in cache.keys) {
      final lastAccess = _lastCacheAccess[key];
      if (lastAccess != null && now.difference(lastAccess) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    }

    for (final key in expiredKeys) {
      cache.remove(key);
      _lastCacheAccess.remove(key);
    }
  }

  void _recordPerformanceMetric(String operation, int milliseconds) {
    _performanceMetrics.putIfAbsent(operation, () => <int>[]);
    _performanceMetrics[operation]!.add(milliseconds);

    // Keep only last 100 measurements
    if (_performanceMetrics[operation]!.length > 100) {
      _performanceMetrics[operation]!.removeAt(0);
    }
  }

  int _getTotalCacheSize() {
    return _roleCompatibilityCache.length +
        _playbookEffectivenessCache.length +
        _optimalLineupCache.length +
        _teamChemistryCache.length;
  }
}

/// LRU Cache implementation for efficient memory management
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  int _hits = 0;
  int _misses = 0;

  LRUCache(this.maxSize);

  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
      _hits++;
      return value;
    }
    _misses++;
    return null;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // Remove least recently used
    }
    _cache[key] = value;
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  void removeOldest(int count) {
    final keysToRemove = _cache.keys.take(count).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  int get length => _cache.length;
  Iterable<K> get keys => _cache.keys;

  double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? _hits / total : 0.0;
  }
}
