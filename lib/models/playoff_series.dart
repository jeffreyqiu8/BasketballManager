/// Playoff series model
/// Represents a best-of-seven playoff matchup between two teams
class PlayoffSeries {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeWins;
  final int awayWins;
  final String round; // 'play-in', 'first-round', 'conf-semis', 'conf-finals', 'finals'
  final String conference; // 'east', 'west', or 'finals'
  final List<String> gameIds; // References to Game objects
  final bool isComplete;

  PlayoffSeries({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeWins,
    required this.awayWins,
    required this.round,
    required this.conference,
    required this.gameIds,
    required this.isComplete,
  });

  /// Get the winner's team ID if series is complete
  /// Returns null if series is not yet complete
  String? get winnerId {
    if (!isComplete) return null;
    return homeWins > awayWins ? homeTeamId : awayTeamId;
  }

  /// Get the series score as a string (e.g., "3-2")
  String get seriesScore => '$homeWins-$awayWins';

  /// Create a copy of this series with updated game result
  /// Increments the win count for the winning team and checks if series is complete
  PlayoffSeries copyWithGameResult(String gameId, String winnerTeamId) {
    final newGameIds = [...gameIds, gameId];
    final newHomeWins = winnerTeamId == homeTeamId ? homeWins + 1 : homeWins;
    final newAwayWins = winnerTeamId == awayTeamId ? awayWins + 1 : awayWins;
    final newIsComplete = newHomeWins >= 4 || newAwayWins >= 4;

    return PlayoffSeries(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeWins: newHomeWins,
      awayWins: newAwayWins,
      round: round,
      conference: conference,
      gameIds: newGameIds,
      isComplete: newIsComplete,
    );
  }

  /// Convert PlayoffSeries to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeWins': homeWins,
      'awayWins': awayWins,
      'round': round,
      'conference': conference,
      'gameIds': gameIds,
      'isComplete': isComplete,
    };
  }

  /// Create PlayoffSeries from JSON
  factory PlayoffSeries.fromJson(Map<String, dynamic> json) {
    return PlayoffSeries(
      id: json['id'] as String,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      homeWins: json['homeWins'] as int,
      awayWins: json['awayWins'] as int,
      round: json['round'] as String,
      conference: json['conference'] as String,
      gameIds: (json['gameIds'] as List<dynamic>).cast<String>(),
      isComplete: json['isComplete'] as bool,
    );
  }
}
