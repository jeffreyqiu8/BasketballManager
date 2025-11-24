/// Championship record model
/// Tracks championship wins for historical purposes
class ChampionshipRecord {
  final int year;
  final String championTeamId;
  final String? finalsMvpPlayerId;
  final String? runnerUpTeamId;

  ChampionshipRecord({
    required this.year,
    required this.championTeamId,
    this.finalsMvpPlayerId,
    this.runnerUpTeamId,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'championTeamId': championTeamId,
      'finalsMvpPlayerId': finalsMvpPlayerId,
      'runnerUpTeamId': runnerUpTeamId,
    };
  }

  /// Create from JSON
  factory ChampionshipRecord.fromJson(Map<String, dynamic> json) {
    return ChampionshipRecord(
      year: json['year'] as int,
      championTeamId: json['championTeamId'] as String,
      finalsMvpPlayerId: json['finalsMvpPlayerId'] as String?,
      runnerUpTeamId: json['runnerUpTeamId'] as String?,
    );
  }
}
