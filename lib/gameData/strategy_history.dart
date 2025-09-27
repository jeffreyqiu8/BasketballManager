import 'playbook.dart';

/// Tracks strategy performance and history during games
class StrategyHistory {
  List<StrategyPerformanceEntry> entries;
  Map<String, StrategyStats> playbookStats;

  StrategyHistory({
    List<StrategyPerformanceEntry>? entries,
    Map<String, StrategyStats>? playbookStats,
  }) : entries = entries ?? [],
       playbookStats = playbookStats ?? {};

  /// Record a strategy change during a game
  void recordStrategyChange(
    Playbook playbook,
    int gameId,
    int quarter,
    int timeRemaining,
    String reason,
  ) {
    entries.add(StrategyPerformanceEntry(
      playbookName: playbook.name,
      gameId: gameId,
      quarter: quarter,
      timeRemaining: timeRemaining,
      timestamp: DateTime.now(),
      reason: reason,
    ));
  }

  /// Record performance metrics for a strategy during a game segment
  void recordPerformance(
    String playbookName,
    int gameId,
    GameSegmentStats stats,
  ) {
    // Find the corresponding entry
    int entryIndex = entries.indexWhere(
      (entry) => entry.playbookName == playbookName && entry.gameId == gameId
    );
    
    if (entryIndex != -1) {
      entries[entryIndex].performance = stats;
    }
    
    // Update overall playbook stats
    if (!playbookStats.containsKey(playbookName)) {
      playbookStats[playbookName] = StrategyStats(playbookName: playbookName);
    }
    
    playbookStats[playbookName]!.addPerformance(stats);
  }

  /// Get strategy recommendations based on historical performance
  List<StrategyRecommendation> getRecommendations({
    int? opponentId,
    int? quarter,
    int? scoreDifferential,
  }) {
    List<StrategyRecommendation> recommendations = [];
    
    // Analyze historical performance for similar situations
    for (var playbookStat in playbookStats.values) {
      double effectiveness = _calculateSituationalEffectiveness(
        playbookStat,
        quarter: quarter,
        scoreDifferential: scoreDifferential,
      );
      
      if (effectiveness > 0.6) {
        recommendations.add(StrategyRecommendation(
          playbookName: playbookStat.playbookName,
          effectiveness: effectiveness,
          reason: _generateRecommendationReason(playbookStat, quarter, scoreDifferential),
          confidence: _calculateConfidence(playbookStat),
        ));
      }
    }
    
    // Sort by effectiveness
    recommendations.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
    
    return recommendations.take(3).toList();
  }

  /// Calculate effectiveness for a specific situation
  double _calculateSituationalEffectiveness(
    StrategyStats stats, {
    int? quarter,
    int? scoreDifferential,
  }) {
    double baseEffectiveness = stats.averageEffectiveness;
    double situationalModifier = 1.0;
    
    // Adjust based on quarter
    if (quarter != null) {
      switch (quarter) {
        case 1:
        case 2:
          // Early game - favor balanced strategies
          if (stats.averagePointsScored > stats.averagePointsAllowed) {
            situationalModifier += 0.1;
          }
          break;
        case 3:
          // Third quarter - favor aggressive strategies
          if (stats.averageTurnovers < 3.0) {
            situationalModifier += 0.15;
          }
          break;
        case 4:
          // Fourth quarter - depends on score differential
          if (scoreDifferential != null) {
            if (scoreDifferential.abs() <= 5) {
              // Close game - favor reliable strategies
              if (stats.gamesUsed >= 3) {
                situationalModifier += 0.2;
              }
            } else if (scoreDifferential > 5) {
              // Leading - favor defensive strategies
              if (stats.averagePointsAllowed < 25.0) {
                situationalModifier += 0.15;
              }
            } else {
              // Trailing - favor aggressive strategies
              if (stats.averagePointsScored > 25.0) {
                situationalModifier += 0.15;
              }
            }
          }
          break;
      }
    }
    
    return (baseEffectiveness * situationalModifier).clamp(0.0, 1.0);
  }

  String _generateRecommendationReason(
    StrategyStats stats,
    int? quarter,
    int? scoreDifferential,
  ) {
    if (quarter == 4 && scoreDifferential != null) {
      if (scoreDifferential.abs() <= 5) {
        return 'Proven effective in close games (${stats.gamesUsed} games)';
      } else if (scoreDifferential > 5) {
        return 'Strong defensive performance (${stats.averagePointsAllowed.toStringAsFixed(1)} pts allowed)';
      } else {
        return 'High scoring potential (${stats.averagePointsScored.toStringAsFixed(1)} pts scored)';
      }
    }
    
    return 'Consistent performance (${(stats.averageEffectiveness * 100).toStringAsFixed(0)}% effectiveness)';
  }

  double _calculateConfidence(StrategyStats stats) {
    // Confidence based on sample size and consistency
    double sampleSizeConfidence = (stats.gamesUsed / 10.0).clamp(0.0, 1.0);
    double consistencyConfidence = 1.0 - (stats.effectivenessVariance / 0.25).clamp(0.0, 1.0);
    
    return (sampleSizeConfidence + consistencyConfidence) / 2.0;
  }

  /// Get performance summary for a specific playbook
  StrategyStats? getPlaybookStats(String playbookName) {
    return playbookStats[playbookName];
  }

  /// Get recent strategy changes
  List<StrategyPerformanceEntry> getRecentChanges({int limit = 10}) {
    List<StrategyPerformanceEntry> sortedEntries = List.from(entries);
    sortedEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedEntries.take(limit).toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((e) => e.toMap()).toList(),
      'playbookStats': playbookStats.map(
        (key, value) => MapEntry(key, value.toMap())
      ),
    };
  }

  factory StrategyHistory.fromMap(Map<String, dynamic> map) {
    return StrategyHistory(
      entries: (map['entries'] as List?)?.map(
        (e) => StrategyPerformanceEntry.fromMap(e)
      ).toList() ?? [],
      playbookStats: (map['playbookStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, StrategyStats.fromMap(value))
      ) ?? {},
    );
  }
}

/// Individual strategy performance entry
class StrategyPerformanceEntry {
  String playbookName;
  int gameId;
  int quarter;
  int timeRemaining;
  DateTime timestamp;
  String reason;
  GameSegmentStats? performance;

  StrategyPerformanceEntry({
    required this.playbookName,
    required this.gameId,
    required this.quarter,
    required this.timeRemaining,
    required this.timestamp,
    required this.reason,
    this.performance,
  });

  Map<String, dynamic> toMap() {
    return {
      'playbookName': playbookName,
      'gameId': gameId,
      'quarter': quarter,
      'timeRemaining': timeRemaining,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'reason': reason,
      'performance': performance?.toMap(),
    };
  }

  factory StrategyPerformanceEntry.fromMap(Map<String, dynamic> map) {
    return StrategyPerformanceEntry(
      playbookName: map['playbookName'] ?? '',
      gameId: map['gameId'] ?? 0,
      quarter: map['quarter'] ?? 1,
      timeRemaining: map['timeRemaining'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      reason: map['reason'] ?? '',
      performance: map['performance'] != null 
        ? GameSegmentStats.fromMap(map['performance'])
        : null,
    );
  }
}

/// Statistics for a specific strategy/playbook
class StrategyStats {
  String playbookName;
  int gamesUsed;
  double averageEffectiveness;
  double effectivenessVariance;
  double averagePointsScored;
  double averagePointsAllowed;
  double averageTurnovers;
  double averageRebounds;
  List<double> effectivenessHistory;

  StrategyStats({
    required this.playbookName,
    this.gamesUsed = 0,
    this.averageEffectiveness = 0.0,
    this.effectivenessVariance = 0.0,
    this.averagePointsScored = 0.0,
    this.averagePointsAllowed = 0.0,
    this.averageTurnovers = 0.0,
    this.averageRebounds = 0.0,
    List<double>? effectivenessHistory,
  }) : effectivenessHistory = effectivenessHistory ?? [];

  void addPerformance(GameSegmentStats stats) {
    gamesUsed++;
    
    // Update running averages
    averagePointsScored = _updateAverage(averagePointsScored, stats.pointsScored, gamesUsed);
    averagePointsAllowed = _updateAverage(averagePointsAllowed, stats.pointsAllowed, gamesUsed);
    averageTurnovers = _updateAverage(averageTurnovers, stats.turnovers, gamesUsed);
    averageRebounds = _updateAverage(averageRebounds, stats.rebounds, gamesUsed);
    
    // Calculate effectiveness for this game segment
    double effectiveness = _calculateEffectiveness(stats);
    effectivenessHistory.add(effectiveness);
    
    // Update average effectiveness
    averageEffectiveness = _updateAverage(averageEffectiveness, effectiveness, gamesUsed);
    
    // Update variance
    _updateVariance();
  }

  double _updateAverage(double currentAverage, double newValue, int count) {
    return ((currentAverage * (count - 1)) + newValue) / count;
  }

  double _calculateEffectiveness(GameSegmentStats stats) {
    // Simple effectiveness calculation based on point differential and efficiency
    double pointDifferential = stats.pointsScored - stats.pointsAllowed;
    double efficiency = stats.pointsScored / (stats.turnovers + 1); // Avoid division by zero
    
    // Normalize to 0-1 scale
    double effectiveness = ((pointDifferential + 10) / 20.0) * 0.7 + (efficiency / 30.0) * 0.3;
    return effectiveness.clamp(0.0, 1.0);
  }

  void _updateVariance() {
    if (effectivenessHistory.length < 2) {
      effectivenessVariance = 0.0;
      return;
    }
    
    double sumSquaredDifferences = 0.0;
    for (double effectiveness in effectivenessHistory) {
      double difference = effectiveness - averageEffectiveness;
      sumSquaredDifferences += difference * difference;
    }
    
    effectivenessVariance = sumSquaredDifferences / effectivenessHistory.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'playbookName': playbookName,
      'gamesUsed': gamesUsed,
      'averageEffectiveness': averageEffectiveness,
      'effectivenessVariance': effectivenessVariance,
      'averagePointsScored': averagePointsScored,
      'averagePointsAllowed': averagePointsAllowed,
      'averageTurnovers': averageTurnovers,
      'averageRebounds': averageRebounds,
      'effectivenessHistory': effectivenessHistory,
    };
  }

  factory StrategyStats.fromMap(Map<String, dynamic> map) {
    return StrategyStats(
      playbookName: map['playbookName'] ?? '',
      gamesUsed: map['gamesUsed'] ?? 0,
      averageEffectiveness: map['averageEffectiveness']?.toDouble() ?? 0.0,
      effectivenessVariance: map['effectivenessVariance']?.toDouble() ?? 0.0,
      averagePointsScored: map['averagePointsScored']?.toDouble() ?? 0.0,
      averagePointsAllowed: map['averagePointsAllowed']?.toDouble() ?? 0.0,
      averageTurnovers: map['averageTurnovers']?.toDouble() ?? 0.0,
      averageRebounds: map['averageRebounds']?.toDouble() ?? 0.0,
      effectivenessHistory: (map['effectivenessHistory'] as List?)?.map(
        (e) => (e as num).toDouble()
      ).toList() ?? [],
    );
  }
}

/// Game segment statistics for strategy performance tracking
class GameSegmentStats {
  double pointsScored;
  double pointsAllowed;
  double turnovers;
  double rebounds;
  double assists;
  double steals;
  int possessions;

  GameSegmentStats({
    required this.pointsScored,
    required this.pointsAllowed,
    required this.turnovers,
    required this.rebounds,
    this.assists = 0.0,
    this.steals = 0.0,
    this.possessions = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'pointsScored': pointsScored,
      'pointsAllowed': pointsAllowed,
      'turnovers': turnovers,
      'rebounds': rebounds,
      'assists': assists,
      'steals': steals,
      'possessions': possessions,
    };
  }

  factory GameSegmentStats.fromMap(Map<String, dynamic> map) {
    return GameSegmentStats(
      pointsScored: map['pointsScored']?.toDouble() ?? 0.0,
      pointsAllowed: map['pointsAllowed']?.toDouble() ?? 0.0,
      turnovers: map['turnovers']?.toDouble() ?? 0.0,
      rebounds: map['rebounds']?.toDouble() ?? 0.0,
      assists: map['assists']?.toDouble() ?? 0.0,
      steals: map['steals']?.toDouble() ?? 0.0,
      possessions: map['possessions'] ?? 1,
    );
  }
}

/// Strategy recommendation based on historical performance
class StrategyRecommendation {
  String playbookName;
  double effectiveness;
  String reason;
  double confidence;

  StrategyRecommendation({
    required this.playbookName,
    required this.effectiveness,
    required this.reason,
    required this.confidence,
  });
}