import 'game.dart';
import 'player_season_stats.dart';
import 'player_game_stats.dart';

/// Season model with 82-game tracking
/// Manages season progression and statistics for the user's team
class Season {
  final String id;
  final int year;
  final List<Game> games; // 82 games for user's team
  final String userTeamId;
  final Map<String, PlayerSeasonStats>? seasonStats; // Season stats by playerId

  Season({
    required this.id,
    required this.year,
    required this.games,
    required this.userTeamId,
    this.seasonStats,
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

  /// Update season statistics with game stats
  Season updateSeasonStats(Map<String, PlayerGameStats> gameStats) {
    final updatedStats = Map<String, PlayerSeasonStats>.from(seasonStats ?? {});
    
    for (var entry in gameStats.entries) {
      final playerId = entry.key;
      final gamePlayerStats = entry.value;
      
      if (updatedStats.containsKey(playerId)) {
        // Update existing player stats
        updatedStats[playerId] = updatedStats[playerId]!.addGameStats(gamePlayerStats);
      } else {
        // Create new player stats
        updatedStats[playerId] = PlayerSeasonStats.empty(playerId).addGameStats(gamePlayerStats);
      }
    }
    
    return copyWith(seasonStats: updatedStats);
  }

  /// Get player season statistics
  PlayerSeasonStats? getPlayerStats(String playerId) {
    return seasonStats?[playerId];
  }

  /// Convert Season to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'games': games.map((game) => game.toJson()).toList(),
      'userTeamId': userTeamId,
      'seasonStats': seasonStats?.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Create Season from JSON
  factory Season.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility - seasonStats may not exist in old saves
    Map<String, PlayerSeasonStats>? seasonStats;
    if (json.containsKey('seasonStats') && json['seasonStats'] != null) {
      final statsJson = json['seasonStats'] as Map<String, dynamic>;
      seasonStats = statsJson.map(
        (key, value) => MapEntry(
          key,
          PlayerSeasonStats.fromJson(value as Map<String, dynamic>),
        ),
      );
    }
    
    return Season(
      id: json['id'] as String,
      year: json['year'] as int,
      games: (json['games'] as List)
          .map((gameJson) => Game.fromJson(gameJson as Map<String, dynamic>))
          .toList(),
      userTeamId: json['userTeamId'] as String,
      seasonStats: seasonStats,
    );
  }

  /// Create a copy of the season with updated games
  Season copyWith({
    String? id,
    int? year,
    List<Game>? games,
    String? userTeamId,
    Map<String, PlayerSeasonStats>? seasonStats,
  }) {
    return Season(
      id: id ?? this.id,
      year: year ?? this.year,
      games: games ?? this.games,
      userTeamId: userTeamId ?? this.userTeamId,
      seasonStats: seasonStats ?? this.seasonStats,
    );
  }
}
