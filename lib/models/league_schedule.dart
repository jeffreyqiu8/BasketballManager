import 'game.dart';

/// League-wide schedule tracking all games across the 30-team league
/// Each team plays 82 games, resulting in 1230 total games (30 teams * 82 / 2)
class LeagueSchedule {
  final String seasonId;
  final List<Game> allGames; // All 1230 games across the league
  final Map<String, List<String>> teamGameIds; // teamId -> list of game IDs

  LeagueSchedule({
    required this.seasonId,
    required this.allGames,
    required this.teamGameIds,
  });

  /// Get all games for a specific team
  List<Game> getTeamGames(String teamId) {
    final gameIds = teamGameIds[teamId] ?? [];
    return allGames.where((game) => gameIds.contains(game.id)).toList();
  }

  /// Get team's record (wins and losses)
  Map<String, int> getTeamRecord(String teamId) {
    int wins = 0;
    int losses = 0;

    for (var game in allGames) {
      if (!game.isPlayed) continue;

      if (game.homeTeamId == teamId) {
        if (game.homeTeamWon) {
          wins++;
        } else {
          losses++;
        }
      } else if (game.awayTeamId == teamId) {
        if (!game.homeTeamWon) {
          wins++;
        } else {
          losses++;
        }
      }
    }

    return {'wins': wins, 'losses': losses};
  }

  /// Get all team records
  Map<String, Map<String, int>> getAllTeamRecords() {
    final records = <String, Map<String, int>>{};
    
    for (var teamId in teamGameIds.keys) {
      records[teamId] = getTeamRecord(teamId);
    }
    
    return records;
  }

  /// Get number of games played league-wide
  int get gamesPlayed {
    return allGames.where((game) => game.isPlayed).length;
  }

  /// Get number of games remaining league-wide
  int get gamesRemaining {
    return allGames.length - gamesPlayed;
  }

  /// Check if the regular season is complete
  bool get isComplete {
    return gamesPlayed >= allGames.length;
  }

  /// Create a copy with updated games
  LeagueSchedule copyWith({
    List<Game>? allGames,
    Map<String, List<String>>? teamGameIds,
  }) {
    return LeagueSchedule(
      seasonId: seasonId,
      allGames: allGames ?? this.allGames,
      teamGameIds: teamGameIds ?? this.teamGameIds,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'seasonId': seasonId,
      'allGames': allGames.map((g) => g.toJson()).toList(),
      'teamGameIds': teamGameIds,
    };
  }

  /// Create from JSON
  factory LeagueSchedule.fromJson(Map<String, dynamic> json) {
    return LeagueSchedule(
      seasonId: json['seasonId'] as String,
      allGames: (json['allGames'] as List)
          .map((g) => Game.fromJson(g as Map<String, dynamic>))
          .toList(),
      teamGameIds: Map<String, List<String>>.from(
        (json['teamGameIds'] as Map).map(
          (key, value) => MapEntry(
            key as String,
            List<String>.from(value as List),
          ),
        ),
      ),
    );
  }
}
