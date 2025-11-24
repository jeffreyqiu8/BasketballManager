import 'game.dart';
import 'player_season_stats.dart';
import 'player_game_stats.dart';
import 'player_playoff_stats.dart';
import 'playoff_bracket.dart';
import 'championship_record.dart';

/// Season model with 82-game tracking
/// Manages season progression and statistics for the user's team
class Season {
  final String id;
  final int year;
  final List<Game> games; // 82 games for user's team
  final String userTeamId;
  final Map<String, PlayerSeasonStats>? seasonStats; // Season stats by playerId
  final PlayoffBracket? playoffBracket; // Playoff bracket structure
  final Map<String, PlayerPlayoffStats>? playoffStats; // Playoff stats by playerId
  final bool isPostSeason; // Whether the season is in post-season mode
  final ChampionshipRecord? championshipRecord; // Championship record if playoffs completed

  Season({
    required this.id,
    required this.year,
    required this.games,
    required this.userTeamId,
    this.seasonStats,
    this.playoffBracket,
    this.playoffStats,
    this.isPostSeason = false,
    this.championshipRecord,
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

  /// Start the post-season by initializing the playoff bracket
  /// This method should be called when the regular season is complete
  Season startPostSeason(PlayoffBracket bracket) {
    return copyWith(
      playoffBracket: bracket,
      isPostSeason: true,
      playoffStats: {}, // Initialize empty playoff stats
    );
  }

  /// Update playoff statistics with game stats
  Season updatePlayoffStats(Map<String, PlayerGameStats> gameStats) {
    final updatedStats = Map<String, PlayerPlayoffStats>.from(playoffStats ?? {});
    
    for (var entry in gameStats.entries) {
      final playerId = entry.key;
      final gamePlayerStats = entry.value;
      
      if (updatedStats.containsKey(playerId)) {
        // Update existing player playoff stats
        updatedStats[playerId] = updatedStats[playerId]!.addGameStats(gamePlayerStats);
      } else {
        // Create new player playoff stats
        updatedStats[playerId] = PlayerPlayoffStats.empty(playerId).addGameStats(gamePlayerStats);
      }
    }
    
    return copyWith(playoffStats: updatedStats);
  }

  /// Get player playoff statistics
  PlayerPlayoffStats? getPlayerPlayoffStats(String playerId) {
    return playoffStats?[playerId];
  }

  /// Update the playoff bracket with a new bracket state
  /// This is typically called after a playoff game is played to update series results
  Season updatePlayoffBracket(PlayoffBracket updatedBracket) {
    return copyWith(playoffBracket: updatedBracket);
  }

  /// Calculate the Finals MVP based on playoff statistics
  /// Returns the player ID with the best playoff performance
  /// Uses a simple scoring system: points + rebounds + assists
  String? calculateFinalsMvp(String championTeamId) {
    if (playoffStats == null || playoffStats!.isEmpty) return null;

    String? mvpPlayerId;
    double bestScore = 0.0;

    for (var entry in playoffStats!.entries) {
      final playerId = entry.key;
      final stats = entry.value;

      // Only consider players from the championship team
      // We'll need to check this in the calling code since we don't have team info here
      
      // Calculate MVP score: PPG + RPG + APG + (SPG * 2) + (BPG * 2)
      final score = stats.pointsPerGame +
          stats.reboundsPerGame +
          stats.assistsPerGame +
          (stats.stealsPerGame * 2) +
          (stats.blocksPerGame * 2);

      if (score > bestScore) {
        bestScore = score;
        mvpPlayerId = playerId;
      }
    }

    return mvpPlayerId;
  }

  /// Complete the playoffs and record the championship
  /// This should be called when the NBA Finals are complete
  Season completePlayoffs(String championTeamId, String? runnerUpTeamId) {
    if (playoffBracket == null || playoffBracket!.currentRound != 'complete') {
      return this;
    }

    // Calculate Finals MVP
    final mvpPlayerId = calculateFinalsMvp(championTeamId);

    // Create championship record
    final record = ChampionshipRecord(
      year: year,
      championTeamId: championTeamId,
      finalsMvpPlayerId: mvpPlayerId,
      runnerUpTeamId: runnerUpTeamId,
    );

    return copyWith(championshipRecord: record);
  }

  /// Convert Season to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'games': games.map((game) => game.toJson()).toList(),
      'userTeamId': userTeamId,
      'seasonStats': seasonStats?.map((key, value) => MapEntry(key, value.toJson())),
      'playoffBracket': playoffBracket?.toJson(),
      'playoffStats': playoffStats?.map((key, value) => MapEntry(key, value.toJson())),
      'isPostSeason': isPostSeason,
      'championshipRecord': championshipRecord?.toJson(),
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

    // Handle backward compatibility - playoff fields may not exist in old saves
    PlayoffBracket? playoffBracket;
    if (json.containsKey('playoffBracket') && json['playoffBracket'] != null) {
      playoffBracket = PlayoffBracket.fromJson(json['playoffBracket'] as Map<String, dynamic>);
    }

    Map<String, PlayerPlayoffStats>? playoffStats;
    if (json.containsKey('playoffStats') && json['playoffStats'] != null) {
      final playoffStatsJson = json['playoffStats'] as Map<String, dynamic>;
      playoffStats = playoffStatsJson.map(
        (key, value) => MapEntry(
          key,
          PlayerPlayoffStats.fromJson(value as Map<String, dynamic>),
        ),
      );
    }

    bool isPostSeason = false;
    if (json.containsKey('isPostSeason') && json['isPostSeason'] != null) {
      isPostSeason = json['isPostSeason'] as bool;
    }

    ChampionshipRecord? championshipRecord;
    if (json.containsKey('championshipRecord') && json['championshipRecord'] != null) {
      championshipRecord = ChampionshipRecord.fromJson(json['championshipRecord'] as Map<String, dynamic>);
    }
    
    return Season(
      id: json['id'] as String,
      year: json['year'] as int,
      games: (json['games'] as List)
          .map((gameJson) => Game.fromJson(gameJson as Map<String, dynamic>))
          .toList(),
      userTeamId: json['userTeamId'] as String,
      seasonStats: seasonStats,
      playoffBracket: playoffBracket,
      playoffStats: playoffStats,
      isPostSeason: isPostSeason,
      championshipRecord: championshipRecord,
    );
  }

  /// Create a copy of the season with updated games
  Season copyWith({
    String? id,
    int? year,
    List<Game>? games,
    String? userTeamId,
    Map<String, PlayerSeasonStats>? seasonStats,
    PlayoffBracket? playoffBracket,
    Map<String, PlayerPlayoffStats>? playoffStats,
    bool? isPostSeason,
    ChampionshipRecord? championshipRecord,
  }) {
    return Season(
      id: id ?? this.id,
      year: year ?? this.year,
      games: games ?? this.games,
      userTeamId: userTeamId ?? this.userTeamId,
      seasonStats: seasonStats ?? this.seasonStats,
      playoffBracket: playoffBracket ?? this.playoffBracket,
      playoffStats: playoffStats ?? this.playoffStats,
      isPostSeason: isPostSeason ?? this.isPostSeason,
      championshipRecord: championshipRecord ?? this.championshipRecord,
    );
  }
}
