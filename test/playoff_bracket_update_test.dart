import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/player_game_stats.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/playoff_service.dart';
import 'package:uuid/uuid.dart';

/// Tests for playoff bracket update after each game
/// Validates Requirements: 25.5, 27.3
void main() {
  group('Playoff Bracket Update Tests', () {
    late GameService gameService;
    late LeagueService leagueService;
    const uuid = Uuid();

    setUp(() async {
      gameService = GameService();
      leagueService = LeagueService();
      await leagueService.initializeLeague();
    });

    test('Playoff bracket updates after user plays a playoff game', () {
      // Create two teams for testing
      final teams = leagueService.getAllTeams();
      final team1 = teams[0];
      final team2 = teams[1];

      // Create a playoff series
      final series = PlayoffSeries(
        id: uuid.v4(),
        homeTeamId: team1.id,
        awayTeamId: team2.id,
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );

      // Create a playoff bracket with the series
      final bracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {team1.id: 1, team2.id: 8},
        teamConferences: {team1.id: 'east', team2.id: 'east'},
        playInGames: [],
        firstRound: [series],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      // Create a season with the playoff bracket
      var season = Season(
        id: 'season-1',
        year: 2024,
        games: List.generate(82, (i) => Game(
          id: uuid.v4(),
          homeTeamId: team1.id,
          awayTeamId: team2.id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        )),
        userTeamId: team1.id,
        isPostSeason: true,
      );
      season = season.startPostSeason(bracket);

      // Simulate a playoff game
      final game = gameService.simulatePlayoffGame(team1, team2, series);
      expect(game.isPlayoffGame, true);
      expect(game.seriesId, series.id);

      // Update the series with the game result
      final updatedSeries = gameService.updateSeriesWithResult(series, game);
      
      // Verify series was updated
      expect(updatedSeries.gameIds.length, 1);
      if (game.homeTeamWon) {
        expect(updatedSeries.homeWins, 1);
        expect(updatedSeries.awayWins, 0);
      } else {
        expect(updatedSeries.homeWins, 0);
        expect(updatedSeries.awayWins, 1);
      }

      // Update the bracket with the updated series
      final updatedBracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: [updatedSeries],
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Update the season with the new bracket
      season = season.updatePlayoffBracket(updatedBracket);

      // Verify the season has the updated bracket
      expect(season.playoffBracket, isNotNull);
      expect(season.playoffBracket!.firstRound.length, 1);
      expect(season.playoffBracket!.firstRound[0].gameIds.length, 1);
    });

    test('Playoff bracket advances to next round when current round is complete', () {
      // Create teams for testing
      final teams = leagueService.getAllTeams();
      
      // Create completed first round series (4 series per conference)
      final eastSeries = List.generate(4, (i) => PlayoffSeries(
        id: uuid.v4(),
        homeTeamId: teams[i * 2].id,
        awayTeamId: teams[i * 2 + 1].id,
        homeWins: 4,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: List.generate(6, (_) => uuid.v4()),
        isComplete: true,
      ));

      final westSeries = List.generate(4, (i) => PlayoffSeries(
        id: uuid.v4(),
        homeTeamId: teams[8 + i * 2].id,
        awayTeamId: teams[8 + i * 2 + 1].id,
        homeWins: 4,
        awayWins: 1,
        round: 'first-round',
        conference: 'west',
        gameIds: List.generate(5, (_) => uuid.v4()),
        isComplete: true,
      ));

      final allFirstRoundSeries = [...eastSeries, ...westSeries];

      // Create a playoff bracket with completed first round
      var bracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {for (var i = 0; i < 16; i++) teams[i].id: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teams[i].id: 'east',
          for (var i = 8; i < 16; i++) teams[i].id: 'west',
        },
        playInGames: [],
        firstRound: allFirstRoundSeries,
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      // Verify round is complete
      expect(bracket.isRoundComplete(), true);

      // Advance to next round
      bracket = PlayoffService.advancePlayoffRound(bracket);

      // Verify bracket advanced to conference semifinals
      expect(bracket.currentRound, 'conf-semis');
      expect(bracket.conferenceSemis.length, 4); // 2 per conference
      expect(bracket.conferenceSemis.every((s) => !s.isComplete), true);
    });

    test('Series completion is detected correctly', () {
      // Create a series that needs one more win to complete
      final series = PlayoffSeries(
        id: uuid.v4(),
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 3,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: List.generate(5, (_) => uuid.v4()),
        isComplete: false,
      );

      expect(series.isComplete, false);

      // Simulate home team winning to complete the series
      final gameId = uuid.v4();
      final updatedSeries = series.copyWithGameResult(gameId, 'team1');

      expect(updatedSeries.homeWins, 4);
      expect(updatedSeries.awayWins, 2);
      expect(updatedSeries.isComplete, true);
      expect(updatedSeries.winnerId, 'team1');
    });

    test('Playoff statistics are updated separately from regular season', () {
      // Create a team and season
      final teams = leagueService.getAllTeams();
      final team = teams[0];
      final player = team.players[0];

      // Create a season with both regular season and playoff stats
      var season = Season(
        id: 'season-1',
        year: 2024,
        games: List.generate(82, (i) => Game(
          id: uuid.v4(),
          homeTeamId: team.id,
          awayTeamId: teams[1].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        )),
        userTeamId: team.id,
        isPostSeason: true,
      );

      // Add some regular season stats
      final regularSeasonStats = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 20,
          rebounds: 5,
          assists: 3,
          fieldGoalsMade: 8,
          fieldGoalsAttempted: 15,
          threePointersMade: 2,
          threePointersAttempted: 5,
          turnovers: 2,
          steals: 1,
          blocks: 0,
          fouls: 2,
          freeThrowsMade: 2,
          freeThrowsAttempted: 2,
        ),
      };
      season = season.updateSeasonStats(regularSeasonStats);

      // Add some playoff stats
      final playoffStats = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 25,
          rebounds: 8,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 18,
          threePointersMade: 3,
          threePointersAttempted: 7,
          turnovers: 1,
          steals: 2,
          blocks: 1,
          fouls: 3,
          freeThrowsMade: 2,
          freeThrowsAttempted: 3,
        ),
      };
      season = season.updatePlayoffStats(playoffStats);

      // Verify both stats exist and are different
      final regularStats = season.getPlayerStats(player.id);
      final postSeasonStats = season.getPlayerPlayoffStats(player.id);

      expect(regularStats, isNotNull);
      expect(postSeasonStats, isNotNull);
      expect(regularStats!.totalPoints, 20);
      expect(postSeasonStats!.totalPoints, 25);
    });
  });
}
