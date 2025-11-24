import 'package:uuid/uuid.dart';
import '../models/playoff_bracket.dart';
import '../models/playoff_series.dart';
import '../models/game.dart';
import '../models/team.dart';

/// Service for managing playoff bracket progression and round advancement
/// Handles resolving play-in games and generating subsequent playoff rounds
class PlayoffService {
  static const _uuid = Uuid();

  /// Resolve play-in tournament games to determine seeds 7 and 8
  /// 
  /// Play-in structure:
  /// - Game 1: 7 seed vs 8 seed (winner gets 7th seed)
  /// - Game 2: 9 seed vs 10 seed
  /// - Game 3: Loser of Game 1 vs Winner of Game 2 (winner gets 8th seed)
  /// 
  /// Returns a map of seed number -> team ID for seeds 7 and 8
  /// Requirements: 22.4, 22.5, 22.6
  static Map<int, String> resolvePlayIn(
    List<PlayoffSeries> playInGames,
    String conference,
  ) {
    // Find completed play-in games for this conference
    final conferenceGames = playInGames
        .where((s) => s.conference == conference && s.isComplete)
        .toList();

    if (conferenceGames.length < 3) {
      throw StateError(
          'All three play-in games must be complete for $conference conference');
    }

    // Find the final play-in game (the one where both teams appear in other games)
    PlayoffSeries? finalGame;
    
    for (var game in conferenceGames) {
      final homeInOtherGames = conferenceGames
          .where((g) => g.id != game.id)
          .where((g) =>
              g.homeTeamId == game.homeTeamId || g.awayTeamId == game.homeTeamId)
          .length;
      final awayInOtherGames = conferenceGames
          .where((g) => g.id != game.id)
          .where((g) =>
              g.homeTeamId == game.awayTeamId || g.awayTeamId == game.awayTeamId)
          .length;

      if (homeInOtherGames > 0 && awayInOtherGames > 0) {
        // This is the final game (both teams from earlier games)
        finalGame = game;
        break;
      }
    }

    if (finalGame == null) {
      throw StateError('Could not identify final play-in game');
    }

    // Seed 8 is the winner of the final game
    final seed8 = finalGame.winnerId!;

    // Find seed 7: the winner of a game who is NOT in the final game
    final otherGames = conferenceGames.where((g) => g.id != finalGame!.id).toList();
    
    String? seed7;
    for (var game in otherGames) {
      final winner = game.winnerId!;
      // Check if this winner is NOT in the final game
      if (finalGame.homeTeamId != winner && finalGame.awayTeamId != winner) {
        // This winner is not in the final game, so they must be seed 7
        seed7 = winner;
        break;
      }
    }

    if (seed7 == null) {
      throw StateError('Could not determine seed 7 from play-in results');
    }

    return {
      7: seed7,
      8: seed8,
    };
  }

  /// Generate first round playoff series (1v8, 2v7, 3v6, 4v5) for both conferences
  /// 
  /// Requirements: 22.4, 24.1
  static List<PlayoffSeries> generateFirstRoundSeries(
    Map<String, int> seedings,
    Map<String, String> conferences,
    Map<int, String> eastPlayInResults,
    Map<int, String> westPlayInResults,
  ) {
    final firstRoundSeries = <PlayoffSeries>[];

    // Get teams by conference and seed
    final eastTeams = _getTeamsByConferenceAndSeed(seedings, conferences, 'east');
    final westTeams = _getTeamsByConferenceAndSeed(seedings, conferences, 'west');

    // Update seeds 7 and 8 with play-in results
    eastTeams[7] = eastPlayInResults[7]!;
    eastTeams[8] = eastPlayInResults[8]!;
    westTeams[7] = westPlayInResults[7]!;
    westTeams[8] = westPlayInResults[8]!;

    // Eastern Conference first round matchups
    firstRoundSeries.add(_createSeries(eastTeams[1]!, eastTeams[8]!, 'first-round', 'east')); // 1v8
    firstRoundSeries.add(_createSeries(eastTeams[2]!, eastTeams[7]!, 'first-round', 'east')); // 2v7
    firstRoundSeries.add(_createSeries(eastTeams[3]!, eastTeams[6]!, 'first-round', 'east')); // 3v6
    firstRoundSeries.add(_createSeries(eastTeams[4]!, eastTeams[5]!, 'first-round', 'east')); // 4v5

    // Western Conference first round matchups
    firstRoundSeries.add(_createSeries(westTeams[1]!, westTeams[8]!, 'first-round', 'west')); // 1v8
    firstRoundSeries.add(_createSeries(westTeams[2]!, westTeams[7]!, 'first-round', 'west')); // 2v7
    firstRoundSeries.add(_createSeries(westTeams[3]!, westTeams[6]!, 'first-round', 'west')); // 3v6
    firstRoundSeries.add(_createSeries(westTeams[4]!, westTeams[5]!, 'first-round', 'west')); // 4v5

    return firstRoundSeries;
  }

  /// Generate conference semifinals series by matching first round winners
  /// 
  /// Matchups:
  /// - Winner of 1v8 vs Winner of 4v5
  /// - Winner of 2v7 vs Winner of 3v6
  /// 
  /// Requirements: 24.2
  static List<PlayoffSeries> generateConferenceSemis(
    List<PlayoffSeries> firstRoundSeries,
  ) {
    final semisSeries = <PlayoffSeries>[];

    // Process each conference separately
    for (var conference in ['east', 'west']) {
      final conferenceSeries = firstRoundSeries
          .where((s) => s.conference == conference && s.isComplete)
          .toList();

      if (conferenceSeries.length != 4) {
        throw StateError(
            'All first round series must be complete for $conference conference');
      }

      // Find winners by matchup type
      // We need to match: (1v8 winner) vs (4v5 winner) and (2v7 winner) vs (3v6 winner)
      // Since we don't have seed info in the series, we'll match by position in the list
      // The series are created in order: 1v8, 2v7, 3v6, 4v5

      final series1v8 = conferenceSeries[0]; // 1v8
      final series2v7 = conferenceSeries[1]; // 2v7
      final series3v6 = conferenceSeries[2]; // 3v6
      final series4v5 = conferenceSeries[3]; // 4v5

      // Matchup 1: Winner of 1v8 vs Winner of 4v5
      semisSeries.add(_createSeries(
        series1v8.winnerId!,
        series4v5.winnerId!,
        'conf-semis',
        conference,
      ));

      // Matchup 2: Winner of 2v7 vs Winner of 3v6
      semisSeries.add(_createSeries(
        series2v7.winnerId!,
        series3v6.winnerId!,
        'conf-semis',
        conference,
      ));
    }

    return semisSeries;
  }

  /// Generate conference finals series by matching conference semifinals winners
  /// 
  /// Requirements: 24.3
  static List<PlayoffSeries> generateConferenceFinals(
    List<PlayoffSeries> conferenceSemisSeries,
  ) {
    final finalsSeries = <PlayoffSeries>[];

    // Process each conference separately
    for (var conference in ['east', 'west']) {
      final conferenceSeries = conferenceSemisSeries
          .where((s) => s.conference == conference && s.isComplete)
          .toList();

      if (conferenceSeries.length != 2) {
        throw StateError(
            'Both conference semifinals must be complete for $conference conference');
      }

      // Match the two winners
      finalsSeries.add(_createSeries(
        conferenceSeries[0].winnerId!,
        conferenceSeries[1].winnerId!,
        'conf-finals',
        conference,
      ));
    }

    return finalsSeries;
  }

  /// Generate NBA Finals series by matching conference champions
  /// 
  /// Requirements: 24.4
  static PlayoffSeries generateNBAFinals(
    List<PlayoffSeries> conferenceFinalsSeries,
  ) {
    if (conferenceFinalsSeries.length != 2) {
      throw StateError('Both conference finals must exist');
    }

    final eastFinals = conferenceFinalsSeries.firstWhere((s) => s.conference == 'east');
    final westFinals = conferenceFinalsSeries.firstWhere((s) => s.conference == 'west');

    if (!eastFinals.isComplete || !westFinals.isComplete) {
      throw StateError('Both conference finals must be complete');
    }

    return _createSeries(
      eastFinals.winnerId!,
      westFinals.winnerId!,
      'finals',
      'finals',
    );
  }

  /// Advance the playoff bracket to the next round
  /// Checks if current round is complete and generates next round series
  /// 
  /// Requirements: 24.1, 24.2, 24.3, 24.4
  static PlayoffBracket advancePlayoffRound(PlayoffBracket bracket) {
    if (!bracket.isRoundComplete()) {
      // Current round is not complete, cannot advance
      return bracket;
    }

    switch (bracket.currentRound) {
      case 'play-in':
        return _advanceFromPlayIn(bracket);
      case 'first-round':
        return _advanceFromFirstRound(bracket);
      case 'conf-semis':
        return _advanceFromConferenceSemis(bracket);
      case 'conf-finals':
        return _advanceFromConferenceFinals(bracket);
      case 'finals':
        return _completePlayoffs(bracket);
      default:
        return bracket;
    }
  }

  /// Advance from play-in round to first round
  static PlayoffBracket _advanceFromPlayIn(PlayoffBracket bracket) {
    // Resolve play-in games to determine seeds 7 and 8
    final eastPlayInResults = resolvePlayIn(bracket.playInGames, 'east');
    final westPlayInResults = resolvePlayIn(bracket.playInGames, 'west');

    // Generate first round series
    final firstRoundSeries = generateFirstRoundSeries(
      bracket.teamSeedings,
      bracket.teamConferences,
      eastPlayInResults,
      westPlayInResults,
    );

    return PlayoffBracket(
      seasonId: bracket.seasonId,
      teamSeedings: bracket.teamSeedings,
      teamConferences: bracket.teamConferences,
      playInGames: bracket.playInGames,
      firstRound: firstRoundSeries,
      conferenceSemis: bracket.conferenceSemis,
      conferenceFinals: bracket.conferenceFinals,
      nbaFinals: bracket.nbaFinals,
      currentRound: 'first-round',
    );
  }

  /// Advance from first round to conference semifinals
  static PlayoffBracket _advanceFromFirstRound(PlayoffBracket bracket) {
    final semisSeries = generateConferenceSemis(bracket.firstRound);

    return PlayoffBracket(
      seasonId: bracket.seasonId,
      teamSeedings: bracket.teamSeedings,
      teamConferences: bracket.teamConferences,
      playInGames: bracket.playInGames,
      firstRound: bracket.firstRound,
      conferenceSemis: semisSeries,
      conferenceFinals: bracket.conferenceFinals,
      nbaFinals: bracket.nbaFinals,
      currentRound: 'conf-semis',
    );
  }

  /// Advance from conference semifinals to conference finals
  static PlayoffBracket _advanceFromConferenceSemis(PlayoffBracket bracket) {
    final finalsSeries = generateConferenceFinals(bracket.conferenceSemis);

    return PlayoffBracket(
      seasonId: bracket.seasonId,
      teamSeedings: bracket.teamSeedings,
      teamConferences: bracket.teamConferences,
      playInGames: bracket.playInGames,
      firstRound: bracket.firstRound,
      conferenceSemis: bracket.conferenceSemis,
      conferenceFinals: finalsSeries,
      nbaFinals: bracket.nbaFinals,
      currentRound: 'conf-finals',
    );
  }

  /// Advance from conference finals to NBA Finals
  static PlayoffBracket _advanceFromConferenceFinals(PlayoffBracket bracket) {
    final nbaFinals = generateNBAFinals(bracket.conferenceFinals);

    return PlayoffBracket(
      seasonId: bracket.seasonId,
      teamSeedings: bracket.teamSeedings,
      teamConferences: bracket.teamConferences,
      playInGames: bracket.playInGames,
      firstRound: bracket.firstRound,
      conferenceSemis: bracket.conferenceSemis,
      conferenceFinals: bracket.conferenceFinals,
      nbaFinals: nbaFinals,
      currentRound: 'finals',
    );
  }

  /// Complete the playoffs after NBA Finals
  static PlayoffBracket _completePlayoffs(PlayoffBracket bracket) {
    return PlayoffBracket(
      seasonId: bracket.seasonId,
      teamSeedings: bracket.teamSeedings,
      teamConferences: bracket.teamConferences,
      playInGames: bracket.playInGames,
      firstRound: bracket.firstRound,
      conferenceSemis: bracket.conferenceSemis,
      conferenceFinals: bracket.conferenceFinals,
      nbaFinals: bracket.nbaFinals,
      currentRound: 'complete',
    );
  }

  /// Get teams organized by conference and seed number
  /// Returns a map of seed number -> team ID for the specified conference
  static Map<int, String> _getTeamsByConferenceAndSeed(
    Map<String, int> seedings,
    Map<String, String> conferences,
    String targetConference,
  ) {
    final result = <int, String>{};

    seedings.forEach((teamId, seed) {
      final conference = conferences[teamId];
      if (conference == targetConference) {
        result[seed] = teamId;
      }
    });

    return result;
  }

  /// Create a playoff series with the given parameters
  static PlayoffSeries _createSeries(
    String team1,
    String team2,
    String round,
    String conference,
  ) {
    return PlayoffSeries(
      id: _uuid.v4(),
      homeTeamId: team1,
      awayTeamId: team2,
      homeWins: 0,
      awayWins: 0,
      round: round,
      conference: conference,
      gameIds: [],
      isComplete: false,
    );
  }

  /// Create the second play-in game between loser of 7v8 and winner of 9v10
  /// 
  /// Requirements: 22.5
  static PlayoffSeries createSecondPlayInGame(
    PlayoffSeries game78,
    PlayoffSeries game910,
    String conference,
  ) {
    if (!game78.isComplete || !game910.isComplete) {
      throw StateError('Both initial play-in games must be complete');
    }

    final winner78 = game78.winnerId!;
    final loser78 = game78.homeTeamId == winner78 ? game78.awayTeamId : game78.homeTeamId;
    final winner910 = game910.winnerId!;

    return _createSeries(loser78, winner910, 'play-in', conference);
  }

  /// Simulate all non-user playoff games in the current round
  /// 
  /// This method simulates all games for series that don't involve the user's team.
  /// It uses batch simulation for performance and updates all series with results.
  /// After simulation, it checks if the round is complete and advances if needed.
  /// 
  /// Parameters:
  /// - bracket: The current playoff bracket
  /// - userTeamId: The ID of the user's team
  /// - getTeam: Function to retrieve a team by ID
  /// - simulateGame: Function to simulate a single game between two teams
  /// 
  /// Returns:
  /// - Updated PlayoffBracket with simulated game results
  /// - Map of series ID to game results summary
  /// 
  /// Requirements: 27.2, 27.3
  static PlayoffBracketSimulationResult simulateNonUserPlayoffGames({
    required PlayoffBracket bracket,
    required String userTeamId,
    required Team Function(String teamId) getTeam,
    required Game Function(Team homeTeam, Team awayTeam, PlayoffSeries series) simulateGame,
  }) {
    // Get all series in the current round
    final currentRoundSeries = bracket.getCurrentRoundSeries();
    
    // Filter out series involving the user's team
    final nonUserSeries = currentRoundSeries.where((series) {
      return series.homeTeamId != userTeamId && series.awayTeamId != userTeamId;
    }).toList();

    // Track updated series and game results
    final updatedSeries = <PlayoffSeries>[];
    final gameResults = <String, List<GameResult>>{}; // series ID -> list of game results

    // Simulate all non-user series to completion
    for (var series in nonUserSeries) {
      if (series.isComplete) {
        // Series already complete, no need to simulate
        updatedSeries.add(series);
        continue;
      }

      // Simulate games until series is complete (first to 4 wins)
      var currentSeries = series;
      final seriesGameResults = <GameResult>[];

      while (!currentSeries.isComplete) {
        // Get teams
        final homeTeam = getTeam(currentSeries.homeTeamId);
        final awayTeam = getTeam(currentSeries.awayTeamId);

        // Simulate the game
        final game = simulateGame(homeTeam, awayTeam, currentSeries);

        // Determine winner
        final winnerTeamId = game.homeTeamWon ? game.homeTeamId : game.awayTeamId;
        final winnerName = game.homeTeamWon 
            ? '${homeTeam.city} ${homeTeam.name}' 
            : '${awayTeam.city} ${awayTeam.name}';

        // Update series with game result
        currentSeries = currentSeries.copyWithGameResult(game.id, winnerTeamId);

        // Record game result
        seriesGameResults.add(GameResult(
          gameId: game.id,
          homeTeamId: game.homeTeamId,
          awayTeamId: game.awayTeamId,
          homeScore: game.homeScore!,
          awayScore: game.awayScore!,
          winnerTeamId: winnerTeamId,
          winnerName: winnerName,
        ));
      }

      updatedSeries.add(currentSeries);
      gameResults[currentSeries.id] = seriesGameResults;
    }

    // Update the bracket with the simulated series
    var updatedBracket = _updateBracketWithSeries(bracket, updatedSeries);

    // Check if the round is complete and advance if needed
    if (updatedBracket.isRoundComplete()) {
      updatedBracket = advancePlayoffRound(updatedBracket);
    }

    return PlayoffBracketSimulationResult(
      bracket: updatedBracket,
      gameResults: gameResults,
    );
  }

  /// Update the bracket with the updated series
  static PlayoffBracket _updateBracketWithSeries(
    PlayoffBracket bracket,
    List<PlayoffSeries> updatedSeries,
  ) {
    // Create a map of series ID to updated series for quick lookup
    final seriesMap = {for (var series in updatedSeries) series.id: series};

    // Update the appropriate round based on current round
    switch (bracket.currentRound) {
      case 'play-in':
        final updatedPlayInGames = bracket.playInGames.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: updatedPlayInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'first-round':
        final updatedFirstRound = bracket.firstRound.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: updatedFirstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'conf-semis':
        final updatedConferenceSemis = bracket.conferenceSemis.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: updatedConferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'conf-finals':
        final updatedConferenceFinals = bracket.conferenceFinals.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: updatedConferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'finals':
        final updatedNbaFinals = bracket.nbaFinals != null && seriesMap.containsKey(bracket.nbaFinals!.id)
            ? seriesMap[bracket.nbaFinals!.id]
            : bracket.nbaFinals;
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: updatedNbaFinals,
          currentRound: bracket.currentRound,
        );

      default:
        return bracket;
    }
  }
}

/// Result of simulating non-user playoff games
class PlayoffBracketSimulationResult {
  final PlayoffBracket bracket;
  final Map<String, List<GameResult>> gameResults; // series ID -> list of game results

  PlayoffBracketSimulationResult({
    required this.bracket,
    required this.gameResults,
  });

  /// Get a summary of all simulated games
  String getSummary() {
    if (gameResults.isEmpty) {
      return 'No games were simulated.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Playoff Games Simulated:');
    buffer.writeln();

    for (var entry in gameResults.entries) {
      final seriesResults = entry.value;
      if (seriesResults.isEmpty) continue;

      // Get series info from first game
      final firstGame = seriesResults.first;
      buffer.writeln('Series: ${firstGame.homeTeamId} vs ${firstGame.awayTeamId}');

      for (var result in seriesResults) {
        buffer.writeln('  ${result.winnerName} won ${result.homeScore}-${result.awayScore}');
      }

      // Show final series winner
      final lastGame = seriesResults.last;
      buffer.writeln('  Series Winner: ${lastGame.winnerName}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Result of a single playoff game
class GameResult {
  final String gameId;
  final String homeTeamId;
  final String awayTeamId;
  final int homeScore;
  final int awayScore;
  final String winnerTeamId;
  final String winnerName;

  GameResult({
    required this.gameId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.winnerTeamId,
    required this.winnerName,
  });
}
