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

  /// Check if a team has been eliminated from the playoffs
  /// Returns true if the team lost a series in any completed round
  bool isTeamEliminated(String teamId) {
    // Check all completed rounds to see if team lost a series
    
    // Check play-in games
    // In play-in, you can lose one game and still have another chance
    // You're only eliminated if you lost a game AND you're not in any other play-in games
    final lostPlayInGames = playInGames.where((series) =>
      series.isComplete && 
      (series.homeTeamId == teamId || series.awayTeamId == teamId) &&
      series.winnerId != teamId
    ).toList();
    
    if (lostPlayInGames.isNotEmpty) {
      if (currentRound == 'play-in') {
        // Still in play-in round - check if team has another game
        final hasAnotherPlayInGame = playInGames.any((series) =>
          !series.isComplete &&
          (series.homeTeamId == teamId || series.awayTeamId == teamId)
        );
        
        if (!hasAnotherPlayInGame) {
          // Lost a play-in game and has no more play-in games - eliminated
          return true;
        }
      } else {
        // Past play-in round - check if team made it to first round
        final inFirstRound = firstRound.any((s) => 
          s.homeTeamId == teamId || s.awayTeamId == teamId);
        if (!inFirstRound) {
          return true; // Eliminated in play-in
        }
      }
    }
    
    // Check first round
    for (var series in firstRound) {
      if (series.isComplete && 
          (series.homeTeamId == teamId || series.awayTeamId == teamId) &&
          series.winnerId != teamId) {
        return true; // Lost in first round
      }
    }
    
    // Check conference semifinals
    for (var series in conferenceSemis) {
      if (series.isComplete && 
          (series.homeTeamId == teamId || series.awayTeamId == teamId) &&
          series.winnerId != teamId) {
        return true; // Lost in conference semis
      }
    }
    
    // Check conference finals
    for (var series in conferenceFinals) {
      if (series.isComplete && 
          (series.homeTeamId == teamId || series.awayTeamId == teamId) &&
          series.winnerId != teamId) {
        return true; // Lost in conference finals
      }
    }
    
    // Check NBA Finals
    if (nbaFinals != null && nbaFinals!.isComplete &&
        (nbaFinals!.homeTeamId == teamId || nbaFinals!.awayTeamId == teamId) &&
        nbaFinals!.winnerId != teamId) {
      return true; // Lost in NBA Finals
    }
    
    return false; // Team is still alive or won championship
  }

  /// Check if all series in the current round are complete
  bool isRoundComplete() {
    final currentSeries = getCurrentRoundSeries();
    if (currentSeries.isEmpty) return false;
    
    // Special handling for play-in round
    // Play-in needs 6 games total (3 per conference)
    // Initial: 7v8 and 9v10 for each conference (4 games)
    // Then: loser of 7v8 vs winner of 9v10 for each conference (2 more games)
    if (currentRound == 'play-in') {
      // Check if we have all 6 games
      if (currentSeries.length < 6) {
        // We don't have all games yet, check if initial games are complete
        // If we have exactly 4 games and they're all complete, we need to create the final 2
        return false;
      }
      // If we have 6 games, check if they're all complete
      return currentSeries.every((series) => series.isComplete);
    }
    
    return currentSeries.every((series) => series.isComplete);
  }

  /// Check if we need to create the second round of play-in games
  /// Returns true if we have 4 complete play-in games but haven't created the final 2 yet
  bool needsSecondPlayInGames() {
    if (currentRound != 'play-in') return false;
    if (playInGames.length != 4) return false;
    
    // Check if all 4 initial games are complete
    return playInGames.every((series) => series.isComplete);
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
