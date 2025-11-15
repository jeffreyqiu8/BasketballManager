import 'playoff_series.dart';

/// Playoff bracket model
/// Represents the complete playoff tournament structure
class PlayoffBracket {
  final String seasonId;
  final Map<String, int> teamSeedings; // teamId -> seed (1-15 per conference)
  final Map<String, String> teamConferences; // teamId -> 'east' or 'west'
  final List<PlayoffSeries> playInGames;
  final List<PlayoffSeries> firstRound;
  final List<PlayoffSeries> conferenceSemis;
  final List<PlayoffSeries> conferenceFinals;
  final PlayoffSeries? nbaFinals;
  final String currentRound; // 'play-in', 'first-round', 'conf-semis', 'conf-finals', 'finals', 'complete'

  PlayoffBracket({
    required this.seasonId,
    required this.teamSeedings,
    required this.teamConferences,
    required this.playInGames,
    required this.firstRound,
    required this.conferenceSemis,
    required this.conferenceFinals,
    this.nbaFinals,
    required this.currentRound,
  });

  /// Get all series for the current playoff round
  List<PlayoffSeries> getCurrentRoundSeries() {
    switch (currentRound) {
      case 'play-in':
        return playInGames;
      case 'first-round':
        return firstRound;
      case 'conf-semis':
        return conferenceSemis;
      case 'conf-finals':
        return conferenceFinals;
      case 'finals':
        return nbaFinals != null ? [nbaFinals!] : [];
      case 'complete':
        return [];
      default:
        return [];
    }
  }

  /// Get the playoff series that includes the user's team
  /// Returns null if the user's team is not in the current round
  PlayoffSeries? getUserTeamSeries(String userTeamId) {
    final currentSeries = getCurrentRoundSeries();
    try {
      return currentSeries.firstWhere(
        (series) =>
            series.homeTeamId == userTeamId || series.awayTeamId == userTeamId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if all series in the current round are complete
  bool isRoundComplete() {
    final currentSeries = getCurrentRoundSeries();
    if (currentSeries.isEmpty) return false;
    return currentSeries.every((series) => series.isComplete);
  }

  /// Convert PlayoffBracket to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'seasonId': seasonId,
      'teamSeedings': teamSeedings,
      'teamConferences': teamConferences,
      'playInGames': playInGames.map((s) => s.toJson()).toList(),
      'firstRound': firstRound.map((s) => s.toJson()).toList(),
      'conferenceSemis': conferenceSemis.map((s) => s.toJson()).toList(),
      'conferenceFinals': conferenceFinals.map((s) => s.toJson()).toList(),
      'nbaFinals': nbaFinals?.toJson(),
      'currentRound': currentRound,
    };
  }

  /// Create PlayoffBracket from JSON
  factory PlayoffBracket.fromJson(Map<String, dynamic> json) {
    return PlayoffBracket(
      seasonId: json['seasonId'] as String,
      teamSeedings: (json['teamSeedings'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
      teamConferences: (json['teamConferences'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      playInGames: (json['playInGames'] as List<dynamic>)
          .map((s) => PlayoffSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
      firstRound: (json['firstRound'] as List<dynamic>)
          .map((s) => PlayoffSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
      conferenceSemis: (json['conferenceSemis'] as List<dynamic>)
          .map((s) => PlayoffSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
      conferenceFinals: (json['conferenceFinals'] as List<dynamic>)
          .map((s) => PlayoffSeries.fromJson(s as Map<String, dynamic>))
          .toList(),
      nbaFinals: json['nbaFinals'] != null
          ? PlayoffSeries.fromJson(json['nbaFinals'] as Map<String, dynamic>)
          : null,
      currentRound: json['currentRound'] as String,
    );
  }
}
