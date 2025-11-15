import 'player_game_stats.dart';

/// Player playoff statistics model
/// Accumulates player statistics across all playoff games
/// Structure mirrors PlayerSeasonStats but tracks playoff performance separately
class PlayerPlayoffStats {
  final String playerId;
  final int gamesPlayed;
  final int totalPoints;
  final int totalRebounds;
  final int totalAssists;
  final int totalFieldGoalsMade;
  final int totalFieldGoalsAttempted;
  final int totalThreePointersMade;
  final int totalThreePointersAttempted;
  final int totalTurnovers;
  final int totalSteals;
  final int totalBlocks;
  final int totalFouls;
  final int totalFreeThrowsMade;
  final int totalFreeThrowsAttempted;

  PlayerPlayoffStats({
    required this.playerId,
    required this.gamesPlayed,
    required this.totalPoints,
    required this.totalRebounds,
    required this.totalAssists,
    required this.totalFieldGoalsMade,
    required this.totalFieldGoalsAttempted,
    required this.totalThreePointersMade,
    required this.totalThreePointersAttempted,
    this.totalTurnovers = 0,
    this.totalSteals = 0,
    this.totalBlocks = 0,
    this.totalFouls = 0,
    this.totalFreeThrowsMade = 0,
    this.totalFreeThrowsAttempted = 0,
  });

  /// Calculate points per game average
  double get pointsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalPoints / gamesPlayed;
  }

  /// Calculate rebounds per game average
  double get reboundsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalRebounds / gamesPlayed;
  }

  /// Calculate assists per game average
  double get assistsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalAssists / gamesPlayed;
  }

  /// Calculate field goal percentage
  double get fieldGoalPercentage {
    if (totalFieldGoalsAttempted == 0) return 0.0;
    return (totalFieldGoalsMade / totalFieldGoalsAttempted) * 100;
  }

  /// Calculate three-point percentage
  double get threePointPercentage {
    if (totalThreePointersAttempted == 0) return 0.0;
    return (totalThreePointersMade / totalThreePointersAttempted) * 100;
  }

  /// Calculate turnovers per game average
  double get turnoversPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalTurnovers / gamesPlayed;
  }

  /// Calculate steals per game average
  double get stealsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalSteals / gamesPlayed;
  }

  /// Calculate blocks per game average
  double get blocksPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalBlocks / gamesPlayed;
  }

  /// Calculate fouls per game average
  double get foulsPerGame {
    if (gamesPlayed == 0) return 0.0;
    return totalFouls / gamesPlayed;
  }

  /// Calculate free throw percentage
  double get freeThrowPercentage {
    if (totalFreeThrowsAttempted == 0) return 0.0;
    return (totalFreeThrowsMade / totalFreeThrowsAttempted) * 100;
  }

  /// Add game statistics to playoff totals
  PlayerPlayoffStats addGameStats(PlayerGameStats gameStats) {
    return PlayerPlayoffStats(
      playerId: playerId,
      gamesPlayed: gamesPlayed + 1,
      totalPoints: totalPoints + gameStats.points,
      totalRebounds: totalRebounds + gameStats.rebounds,
      totalAssists: totalAssists + gameStats.assists,
      totalFieldGoalsMade: totalFieldGoalsMade + gameStats.fieldGoalsMade,
      totalFieldGoalsAttempted:
          totalFieldGoalsAttempted + gameStats.fieldGoalsAttempted,
      totalThreePointersMade:
          totalThreePointersMade + gameStats.threePointersMade,
      totalThreePointersAttempted:
          totalThreePointersAttempted + gameStats.threePointersAttempted,
      totalTurnovers: totalTurnovers + gameStats.turnovers,
      totalSteals: totalSteals + gameStats.steals,
      totalBlocks: totalBlocks + gameStats.blocks,
      totalFouls: totalFouls + gameStats.fouls,
      totalFreeThrowsMade: totalFreeThrowsMade + gameStats.freeThrowsMade,
      totalFreeThrowsAttempted:
          totalFreeThrowsAttempted + gameStats.freeThrowsAttempted,
    );
  }

  /// Convert PlayerPlayoffStats to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'gamesPlayed': gamesPlayed,
      'totalPoints': totalPoints,
      'totalRebounds': totalRebounds,
      'totalAssists': totalAssists,
      'totalFieldGoalsMade': totalFieldGoalsMade,
      'totalFieldGoalsAttempted': totalFieldGoalsAttempted,
      'totalThreePointersMade': totalThreePointersMade,
      'totalThreePointersAttempted': totalThreePointersAttempted,
      'totalTurnovers': totalTurnovers,
      'totalSteals': totalSteals,
      'totalBlocks': totalBlocks,
      'totalFouls': totalFouls,
      'totalFreeThrowsMade': totalFreeThrowsMade,
      'totalFreeThrowsAttempted': totalFreeThrowsAttempted,
    };
  }

  /// Create PlayerPlayoffStats from JSON
  factory PlayerPlayoffStats.fromJson(Map<String, dynamic> json) {
    return PlayerPlayoffStats(
      playerId: json['playerId'] as String,
      gamesPlayed: json['gamesPlayed'] as int,
      totalPoints: json['totalPoints'] as int,
      totalRebounds: json['totalRebounds'] as int,
      totalAssists: json['totalAssists'] as int,
      totalFieldGoalsMade: json['totalFieldGoalsMade'] as int,
      totalFieldGoalsAttempted: json['totalFieldGoalsAttempted'] as int,
      totalThreePointersMade: json['totalThreePointersMade'] as int,
      totalThreePointersAttempted: json['totalThreePointersAttempted'] as int,
      totalTurnovers: json['totalTurnovers'] as int? ?? 0,
      totalSteals: json['totalSteals'] as int? ?? 0,
      totalBlocks: json['totalBlocks'] as int? ?? 0,
      totalFouls: json['totalFouls'] as int? ?? 0,
      totalFreeThrowsMade: json['totalFreeThrowsMade'] as int? ?? 0,
      totalFreeThrowsAttempted: json['totalFreeThrowsAttempted'] as int? ?? 0,
    );
  }

  /// Create initial empty playoff stats for a player
  factory PlayerPlayoffStats.empty(String playerId) {
    return PlayerPlayoffStats(
      playerId: playerId,
      gamesPlayed: 0,
      totalPoints: 0,
      totalRebounds: 0,
      totalAssists: 0,
      totalFieldGoalsMade: 0,
      totalFieldGoalsAttempted: 0,
      totalThreePointersMade: 0,
      totalThreePointersAttempted: 0,
      totalTurnovers: 0,
      totalSteals: 0,
      totalBlocks: 0,
      totalFouls: 0,
      totalFreeThrowsMade: 0,
      totalFreeThrowsAttempted: 0,
    );
  }
}
