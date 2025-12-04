/// Player game statistics model
/// Tracks individual player performance in a single game
class PlayerGameStats {
  final String playerId;
  final int points;
  final int rebounds;
  final int assists;
  final int fieldGoalsMade;
  final int fieldGoalsAttempted;
  final int threePointersMade;
  final int threePointersAttempted;
  final int turnovers;
  final int steals;
  final int blocks;
  final int fouls;
  final int freeThrowsMade;
  final int freeThrowsAttempted;
  final double minutesPlayed;

  PlayerGameStats({
    required this.playerId,
    required this.points,
    required this.rebounds,
    required this.assists,
    required this.fieldGoalsMade,
    required this.fieldGoalsAttempted,
    required this.threePointersMade,
    required this.threePointersAttempted,
    this.turnovers = 0,
    this.steals = 0,
    this.blocks = 0,
    this.fouls = 0,
    this.freeThrowsMade = 0,
    this.freeThrowsAttempted = 0,
    this.minutesPlayed = 0.0,
  });

  /// Calculate field goal percentage
  double get fieldGoalPercentage {
    if (fieldGoalsAttempted == 0) return 0.0;
    return (fieldGoalsMade / fieldGoalsAttempted) * 100;
  }

  /// Calculate three-point percentage
  double get threePointPercentage {
    if (threePointersAttempted == 0) return 0.0;
    return (threePointersMade / threePointersAttempted) * 100;
  }

  /// Calculate free throw percentage
  double get freeThrowPercentage {
    if (freeThrowsAttempted == 0) return 0.0;
    return (freeThrowsMade / freeThrowsAttempted) * 100;
  }

  /// Convert PlayerGameStats to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'points': points,
      'rebounds': rebounds,
      'assists': assists,
      'fieldGoalsMade': fieldGoalsMade,
      'fieldGoalsAttempted': fieldGoalsAttempted,
      'threePointersMade': threePointersMade,
      'threePointersAttempted': threePointersAttempted,
      'turnovers': turnovers,
      'steals': steals,
      'blocks': blocks,
      'fouls': fouls,
      'freeThrowsMade': freeThrowsMade,
      'freeThrowsAttempted': freeThrowsAttempted,
      'minutesPlayed': minutesPlayed,
    };
  }

  /// Create PlayerGameStats from JSON
  /// Handles backward compatibility for old saves without new stats
  factory PlayerGameStats.fromJson(Map<String, dynamic> json) {
    return PlayerGameStats(
      playerId: json['playerId'] as String,
      points: json['points'] as int,
      rebounds: json['rebounds'] as int,
      assists: json['assists'] as int,
      fieldGoalsMade: json['fieldGoalsMade'] as int,
      fieldGoalsAttempted: json['fieldGoalsAttempted'] as int,
      threePointersMade: json['threePointersMade'] as int,
      threePointersAttempted: json['threePointersAttempted'] as int,
      turnovers: json['turnovers'] as int? ?? 0,
      steals: json['steals'] as int? ?? 0,
      blocks: json['blocks'] as int? ?? 0,
      fouls: json['fouls'] as int? ?? 0,
      freeThrowsMade: json['freeThrowsMade'] as int? ?? 0,
      freeThrowsAttempted: json['freeThrowsAttempted'] as int? ?? 0,
      minutesPlayed: (json['minutesPlayed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
