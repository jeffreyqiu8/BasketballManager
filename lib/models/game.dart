import 'player_game_stats.dart';

/// Game model with score tracking
/// Represents a single basketball game between two teams
class Game {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore; // Nullable: null indicates unplayed game
  final int? awayScore; // Nullable: null indicates unplayed game
  final bool isPlayed;
  final DateTime scheduledDate;
  final Map<String, PlayerGameStats>? boxScore; // Optional: player stats by playerId
  final bool isPlayoffGame; // Whether this is a playoff game
  final String? seriesId; // Reference to PlayoffSeries if this is a playoff game

  Game({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    required this.isPlayed,
    required this.scheduledDate,
    this.boxScore,
    this.isPlayoffGame = false,
    this.seriesId,
  });

  /// Check if the home team won
  bool get homeTeamWon {
    if (!isPlayed || homeScore == null || awayScore == null) return false;
    return homeScore! > awayScore!;
  }

  /// Check if the away team won
  bool get awayTeamWon {
    if (!isPlayed || homeScore == null || awayScore == null) return false;
    return awayScore! > homeScore!;
  }

  /// Convert Game to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'isPlayed': isPlayed,
      'scheduledDate': scheduledDate.toIso8601String(),
      'boxScore': boxScore?.map((key, value) => MapEntry(key, value.toJson())),
      'isPlayoffGame': isPlayoffGame,
      'seriesId': seriesId,
    };
  }

  /// Create Game from JSON
  factory Game.fromJson(Map<String, dynamic> json) {
    Map<String, PlayerGameStats>? boxScore;
    if (json['boxScore'] != null) {
      final boxScoreJson = json['boxScore'] as Map<String, dynamic>;
      boxScore = boxScoreJson.map(
        (key, value) => MapEntry(key, PlayerGameStats.fromJson(value as Map<String, dynamic>)),
      );
    }

    return Game(
      id: json['id'] as String,
      homeTeamId: json['homeTeamId'] as String,
      awayTeamId: json['awayTeamId'] as String,
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
      isPlayed: json['isPlayed'] as bool,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      boxScore: boxScore,
      isPlayoffGame: json['isPlayoffGame'] as bool? ?? false,
      seriesId: json['seriesId'] as String?,
    );
  }

  /// Create a copy of the game with updated scores
  Game copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    int? homeScore,
    int? awayScore,
    bool? isPlayed,
    DateTime? scheduledDate,
    Map<String, PlayerGameStats>? boxScore,
    bool? isPlayoffGame,
    String? seriesId,
  }) {
    return Game(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      isPlayed: isPlayed ?? this.isPlayed,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      boxScore: boxScore ?? this.boxScore,
      isPlayoffGame: isPlayoffGame ?? this.isPlayoffGame,
      seriesId: seriesId ?? this.seriesId,
    );
  }

  /// Create a copy of the game with box score
  Game copyWithBoxScore(Map<String, PlayerGameStats> boxScore) {
    return copyWith(boxScore: boxScore);
  }
}
