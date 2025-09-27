import 'dart:async';
import 'dart:collection';
import 'dart:math';

/// Performance profiler for monitoring application performance
class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final Map<String, List<ProfileEntry>> _profiles = {};
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, double> _memoryUsage = {};
  
  bool _isEnabled = true;
  static const int _maxEntriesPerOperation = 1000;

  /// Start profiling an operation
  void startOperation(String operationName) {
    if (!_isEnabled) return;
    
    final stopwatch = Stopwatch()..start();
    _activeTimers[operationName] = stopwatch;
    
    // Track operation count
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
  }

  /// End profiling an operation
  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return;
    
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) return;
    
    stopwatch.stop();
    
    final entry = ProfileEntry(
      operationName: operationName,
      duration: stopwatch.elapsedMicroseconds,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    
    _profiles.putIfAbsent(operationName, () => <ProfileEntry>[]);
    _profiles[operationName]!.add(entry);
    
    // Limit entries to prevent memory growth
    if (_profiles[operationName]!.length > _maxEntriesPerOperation) {
      _profiles[operationName]!.removeAt(0);
    }
  }

  /// Profile a function execution
  T profileFunction<T>(String operationName, T Function() function, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return function();
    
    startOperation(operationName);
    try {
      final result = function();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  /// Profile an async function execution
  Future<T> profileAsyncFunction<T>(
    String operationName, 
    Future<T> Function() function, 
    {Map<String, dynamic>? metadata}
  ) async {
    if (!_isEnabled) return await function();
    
    startOperation(operationName);
    try {
      final result = await function();
      endOperation(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endOperation(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  /// Record memory usage for an operation
  void recordMemoryUsage(String operationName, double memoryMB) {
    if (!_isEnabled) return;
    _memoryUsage[operationName] = memoryMB;
  }

  /// Get performance statistics for an operation
  PerformanceStats? getStats(String operationName) {
    final entries = _profiles[operationName];
    if (entries == null || entries.isEmpty) return null;
    
    final durations = entries.map((e) => e.duration).toList();
    durations.sort();
    
    final count = durations.length;
    final sum = durations.reduce((a, b) => a + b);
    final average = sum / count;
    
    final median = count % 2 == 0
        ? (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2
        : durations[count ~/ 2].toDouble();
    
    final p95Index = (count * 0.95).ceil() - 1;
    final p95 = durations[p95Index].toDouble();
    
    final p99Index = (count * 0.99).ceil() - 1;
    final p99 = durations[p99Index].toDouble();
    
    final min = durations.first.toDouble();
    final max = durations.last.toDouble();
    
    // Calculate standard deviation
    final variance = durations
        .map((d) => pow(d - average, 2))
        .reduce((a, b) => a + b) / count;
    final stdDev = sqrt(variance);
    
    return PerformanceStats(
      operationName: operationName,
      count: count,
      totalDurationMicros: sum,
      averageDurationMicros: average,
      medianDurationMicros: median,
      minDurationMicros: min,
      maxDurationMicros: max,
      p95DurationMicros: p95,
      p99DurationMicros: p99,
      standardDeviation: stdDev,
      memoryUsageMB: _memoryUsage[operationName],
      operationCount: _operationCounts[operationName] ?? 0,
    );
  }

  /// Get all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    
    for (final operationName in _profiles.keys) {
      final operationStats = getStats(operationName);
      if (operationStats != null) {
        stats[operationName] = operationStats;
      }
    }
    
    return stats;
  }

  /// Get performance report
  PerformanceReport getReport() {
    final allStats = getAllStats();
    
    // Find slowest operations
    final slowestOps = allStats.entries
        .where((e) => e.value.count > 0)
        .toList()
      ..sort((a, b) => b.value.averageDurationMicros.compareTo(a.value.averageDurationMicros));
    
    // Find most frequent operations
    final frequentOps = allStats.entries
        .where((e) => e.value.count > 0)
        .toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));
    
    // Find operations with high variance
    final highVarianceOps = allStats.entries
        .where((e) => e.value.count > 0)
        .toList()
      ..sort((a, b) => b.value.standardDeviation.compareTo(a.value.standardDeviation));
    
    return PerformanceReport(
      totalOperations: _operationCounts.values.fold(0, (a, b) => a + b),
      uniqueOperations: allStats.length,
      slowestOperations: slowestOps.take(10).map((e) => e.value).toList(),
      mostFrequentOperations: frequentOps.take(10).map((e) => e.value).toList(),
      highVarianceOperations: highVarianceOps.take(10).map((e) => e.value).toList(),
      allStats: allStats,
    );
  }

  /// Get recent entries for an operation
  List<ProfileEntry> getRecentEntries(String operationName, {int limit = 100}) {
    final entries = _profiles[operationName];
    if (entries == null) return [];
    
    final recentEntries = entries.reversed.take(limit).toList();
    return recentEntries.reversed.toList();
  }

  /// Clear all profiling data
  void clear() {
    _profiles.clear();
    _activeTimers.clear();
    _operationCounts.clear();
    _memoryUsage.clear();
  }

  /// Clear data for specific operation
  void clearOperation(String operationName) {
    _profiles.remove(operationName);
    _activeTimers.remove(operationName);
    _operationCounts.remove(operationName);
    _memoryUsage.remove(operationName);
  }

  /// Enable or disable profiling
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _activeTimers.clear();
    }
  }

  /// Check if profiling is enabled
  bool get isEnabled => _isEnabled;

  /// Get memory usage summary
  Map<String, double> getMemoryUsageSummary() {
    return Map.from(_memoryUsage);
  }

  /// Detect performance bottlenecks
  List<PerformanceBottleneck> detectBottlenecks() {
    final bottlenecks = <PerformanceBottleneck>[];
    final allStats = getAllStats();
    
    for (final stats in allStats.values) {
      // Slow operations (> 100ms average)
      if (stats.averageDurationMicros > 100000) {
        bottlenecks.add(PerformanceBottleneck(
          operationName: stats.operationName,
          type: BottleneckType.slowOperation,
          severity: _calculateSeverity(stats.averageDurationMicros, 100000, 1000000),
          description: 'Operation takes ${(stats.averageDurationMicros / 1000).toStringAsFixed(1)}ms on average',
          recommendation: 'Consider optimizing this operation or adding caching',
        ));
      }
      
      // High variance operations
      if (stats.standardDeviation > stats.averageDurationMicros * 0.5) {
        bottlenecks.add(PerformanceBottleneck(
          operationName: stats.operationName,
          type: BottleneckType.highVariance,
          severity: _calculateSeverity(stats.standardDeviation, stats.averageDurationMicros * 0.5, stats.averageDurationMicros * 2),
          description: 'Operation has high performance variance (σ=${stats.standardDeviation.toStringAsFixed(1)}μs)',
          recommendation: 'Investigate inconsistent performance patterns',
        ));
      }
      
      // Frequent operations that could benefit from optimization
      if (stats.count > 1000 && stats.averageDurationMicros > 10000) {
        bottlenecks.add(PerformanceBottleneck(
          operationName: stats.operationName,
          type: BottleneckType.frequentSlow,
          severity: _calculateSeverity(stats.count * stats.averageDurationMicros, 10000000, 100000000),
          description: 'Frequent operation (${stats.count} calls) with moderate duration',
          recommendation: 'High impact optimization target due to frequency',
        ));
      }
    }
    
    // Sort by severity
    bottlenecks.sort((a, b) => b.severity.compareTo(a.severity));
    
    return bottlenecks;
  }

  double _calculateSeverity(double value, double threshold, double maxValue) {
    if (value <= threshold) return 0.0;
    return ((value - threshold) / (maxValue - threshold)).clamp(0.0, 1.0);
  }
}

/// Profile entry for a single operation execution
class ProfileEntry {
  final String operationName;
  final int duration; // microseconds
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ProfileEntry({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  double get durationMs => duration / 1000.0;
}

/// Performance statistics for an operation
class PerformanceStats {
  final String operationName;
  final int count;
  final int totalDurationMicros;
  final double averageDurationMicros;
  final double medianDurationMicros;
  final double minDurationMicros;
  final double maxDurationMicros;
  final double p95DurationMicros;
  final double p99DurationMicros;
  final double standardDeviation;
  final double? memoryUsageMB;
  final int operationCount;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.totalDurationMicros,
    required this.averageDurationMicros,
    required this.medianDurationMicros,
    required this.minDurationMicros,
    required this.maxDurationMicros,
    required this.p95DurationMicros,
    required this.p99DurationMicros,
    required this.standardDeviation,
    this.memoryUsageMB,
    required this.operationCount,
  });

  double get averageDurationMs => averageDurationMicros / 1000.0;
  double get medianDurationMs => medianDurationMicros / 1000.0;
  double get p95DurationMs => p95DurationMicros / 1000.0;
  double get p99DurationMs => p99DurationMicros / 1000.0;
}

/// Performance report containing analysis of all operations
class PerformanceReport {
  final int totalOperations;
  final int uniqueOperations;
  final List<PerformanceStats> slowestOperations;
  final List<PerformanceStats> mostFrequentOperations;
  final List<PerformanceStats> highVarianceOperations;
  final Map<String, PerformanceStats> allStats;

  PerformanceReport({
    required this.totalOperations,
    required this.uniqueOperations,
    required this.slowestOperations,
    required this.mostFrequentOperations,
    required this.highVarianceOperations,
    required this.allStats,
  });
}

/// Performance bottleneck detection
class PerformanceBottleneck {
  final String operationName;
  final BottleneckType type;
  final double severity; // 0.0 to 1.0
  final String description;
  final String recommendation;

  PerformanceBottleneck({
    required this.operationName,
    required this.type,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

enum BottleneckType {
  slowOperation,
  highVariance,
  frequentSlow,
  memoryIntensive,
}