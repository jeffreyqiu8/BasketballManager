import 'package:uuid/uuid.dart';
import '../models/playoff_series.dart';

/// Utility class for generating playoff bracket structures
/// Handles play-in tournament generation and playoff round matchups
class PlayoffBracketGenerator {
  static const _uuid = Uuid();

  /// Generate play-in tournament games for both conferences
  /// Creates 4 play-in series total:
  /// - Eastern Conference: 7 vs 8 seed, 9 vs 10 seed
  /// - Western Conference: 7 vs 8 seed, 9 vs 10 seed
  /// 
  /// Only teams seeded 7-10 qualify for the play-in tournament.
  /// Teams seeded 11-15 have missed the playoffs entirely.
  /// 
  /// Requirements: 22.1, 22.2, 22.3
  static List<PlayoffSeries> generatePlayInGames(
    Map<String, int> seedings,
    Map<String, String> conferences,
  ) {
    final playInGames = <PlayoffSeries>[];

    // Get teams by conference and seed
    final eastTeams = _getTeamsByConferenceAndSeed(seedings, conferences, 'east');
    final westTeams = _getTeamsByConferenceAndSeed(seedings, conferences, 'west');

    // Validate that seeds 7-10 exist for Eastern Conference
    if (!eastTeams.containsKey(7) || !eastTeams.containsKey(8) ||
        !eastTeams.containsKey(9) || !eastTeams.containsKey(10)) {
      throw StateError(
          'Eastern Conference must have teams seeded 7-10 for play-in tournament');
    }

    // Validate that seeds 7-10 exist for Western Conference
    if (!westTeams.containsKey(7) || !westTeams.containsKey(8) ||
        !westTeams.containsKey(9) || !westTeams.containsKey(10)) {
      throw StateError(
          'Western Conference must have teams seeded 7-10 for play-in tournament');
    }

    // Eastern Conference play-in games
    // 7 vs 8 seed matchup
    playInGames.add(_createSeries(
      eastTeams[7]!, // seed 7
      eastTeams[8]!, // seed 8
      'play-in',
      'east',
    ));

    // 9 vs 10 seed matchup
    playInGames.add(_createSeries(
      eastTeams[9]!, // seed 9
      eastTeams[10]!, // seed 10
      'play-in',
      'east',
    ));

    // Western Conference play-in games
    // 7 vs 8 seed matchup
    playInGames.add(_createSeries(
      westTeams[7]!, // seed 7
      westTeams[8]!, // seed 8
      'play-in',
      'west',
    ));

    // 9 vs 10 seed matchup
    playInGames.add(_createSeries(
      westTeams[9]!, // seed 9
      westTeams[10]!, // seed 10
      'play-in',
      'west',
    ));

    return playInGames;
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
}
