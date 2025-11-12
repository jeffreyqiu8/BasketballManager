import 'game.dart';

/// Season model with 82-game tracking
/// Manages season progression and statistics for the user's team
class Season {
  final String id;
  final int year;
  final List<Game> games; // 82 games for user's team
  final String userTeamId;

  Season({
    required this.id,
    required this.year,
    required this.games,
    required this.userTeamId,
  }) : assert(games.length == 82, 'Season must have exactly 82 games');

  /// Get number of games played
  int get gamesPlayed {
    return games.where((game) => game.isPlayed).length;
  }

  /// Get number of games remaining
  int get gamesRemaining {
    return 82 - gamesPlayed;
  }

  /// Get number of wins for user's team
  int get wins {
    return games.where((game) {
      if (!game.isPlayed) return false;
      
      // Check if user's team is home or away and if they won
      if (game.homeTeamId == userTeamId) {
        return game.homeTeamWon;
      } else if (game.awayTeamId == userTeamId) {
        return game.awayTeamWon;
      }
      
      return false;
    }).length;
  }

  /// Get number of losses for user's team
  int get losses {
    return gamesPlayed - wins;
  }

  /// Get the next unplayed game
  Game? get nextGame {
    try {
      return games.firstWhere((game) => !game.isPlayed);
    } catch (e) {
      return null; // No unplayed games
    }
  }

  /// Check if season is complete
  bool get isComplete {
    return gamesPlayed == 82;
  }

  /// Convert Season to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'games': games.map((game) => game.toJson()).toList(),
      'userTeamId': userTeamId,
    };
  }

  /// Create Season from JSON
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as String,
      year: json['year'] as int,
      games: (json['games'] as List)
          .map((gameJson) => Game.fromJson(gameJson as Map<String, dynamic>))
          .toList(),
      userTeamId: json['userTeamId'] as String,
    );
  }

  /// Create a copy of the season with updated games
  Season copyWith({
    String? id,
    int? year,
    List<Game>? games,
    String? userTeamId,
  }) {
    return Season(
      id: id ?? this.id,
      year: year ?? this.year,
      games: games ?? this.games,
      userTeamId: userTeamId ?? this.userTeamId,
    );
  }
}
