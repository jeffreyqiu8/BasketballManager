import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/playoff_service.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/utils/playoff_bracket_generator.dart';

void main() {
  group('PlayoffService', () {
    late Map<String, int> seedings;
    late Map<String, String> conferences;

    setUp(() {
      // Create test seedings for 30 teams (15 per conference)
      seedings = {};
      conferences = {};

      // Eastern Conference teams (seeds 1-15)
      for (int i = 1; i <= 15; i++) {
        final teamId = 'east_team_$i';
        seedings[teamId] = i;
        conferences[teamId] = 'east';
      }

      // Western Conference teams (seeds 1-15)
      for (int i = 1; i <= 15; i++) {
        final teamId = 'west_team_$i';
        seedings[teamId] = i;
        conferences[teamId] = 'west';
      }
    });

    group('resolvePlayIn', () {
      test('should resolve play-in games and return seeds 7 and 8', () {
        // Create play-in games
        final playInGames = PlayoffBracketGenerator.generatePlayInGames(
          seedings,
          conferences,
        );

        // Simulate game results for Eastern Conference
        final eastGames = playInGames.where((g) => g.conference == 'east').toList();
        
        // Game 1: 7 vs 8 (let's say 7 wins)
        final game78 = eastGames.firstWhere((g) =>
          (g.homeTeamId == 'east_team_7' || g.awayTeamId == 'east_team_7') &&
          (g.homeTeamId == 'east_team_8' || g.awayTeamId == 'east_team_8'));
        
        var completedGame78 = game78;
        for (int i = 0; i < 4; i++) {
          completedGame78 = completedGame78.copyWithGameResult('game1_$i', 'east_team_7');
        }

        // Game 2: 9 vs 10 (let's say 9 wins)
        final game910 = eastGames.firstWhere((g) =>
          (g.homeTeamId == 'east_team_9' || g.awayTeamId == 'east_team_9') &&
          (g.homeTeamId == 'east_team_10' || g.awayTeamId == 'east_team_10'));
        
        var completedGame910 = game910;
        for (int i = 0; i < 4; i++) {
          completedGame910 = completedGame910.copyWithGameResult('game2_$i', 'east_team_9');
        }

        // Create second play-in game: loser of 7v8 (team 8) vs winner of 9v10 (team 9)
        final secondGame = PlayoffBracketGenerator.createSecondPlayInGame(
          completedGame78,
          completedGame910,
          'east',
        );

        // Let's say team 8 wins the second game
        var completedSecondGame = secondGame;
        for (int i = 0; i < 4; i++) {
          completedSecondGame = completedSecondGame.copyWithGameResult('game3_$i', 'east_team_8');
        }

        // Update play-in games list
        final updatedPlayInGames = [
          completedGame78,
          completedGame910,
          completedSecondGame,
          ...playInGames.where((g) => g.conference == 'west'),
        ];

        // Resolve play-in
        final results = PlayoffService.resolvePlayIn(updatedPlayInGames, 'east');

        expect(results[7], 'east_team_7'); // Winner of 7v8
        expect(results[8], 'east_team_8'); // Winner of second game
      });

      test('should throw error if play-in games are not complete', () {
        final playInGames = PlayoffBracketGenerator.generatePlayInGames(
          seedings,
          conferences,
        );

        expect(
          () => PlayoffService.resolvePlayIn(playInGames, 'east'),
          throwsStateError,
        );
      });
    });

    group('generateFirstRoundSeries', () {
      test('should generate 8 first round series (4 per conference)', () {
        final eastPlayInResults = {7: 'east_team_7', 8: 'east_team_8'};
        final westPlayInResults = {7: 'west_team_7', 8: 'west_team_8'};

        final firstRound = PlayoffService.generateFirstRoundSeries(
          seedings,
          conferences,
          eastPlayInResults,
          westPlayInResults,
        );

        expect(firstRound.length, 8);
      });

      test('should create correct matchups for Eastern Conference', () {
        final eastPlayInResults = {7: 'east_team_7', 8: 'east_team_8'};
        final westPlayInResults = {7: 'west_team_7', 8: 'west_team_8'};

        final firstRound = PlayoffService.generateFirstRoundSeries(
          seedings,
          conferences,
          eastPlayInResults,
          westPlayInResults,
        );

        final eastSeries = firstRound.where((s) => s.conference == 'east').toList();
        expect(eastSeries.length, 4);

        // Verify matchups: 1v8, 2v7, 3v6, 4v5
        final matchups = eastSeries.map((s) {
          final homeSeed = seedings[s.homeTeamId];
          final awaySeed = seedings[s.awayTeamId];
          return [homeSeed, awaySeed]..sort();
        }).toList();

        expect(matchups, containsAll([
          [1, 8],
          [2, 7],
          [3, 6],
          [4, 5],
        ]));
      });

      test('should set round to "first-round"', () {
        final eastPlayInResults = {7: 'east_team_7', 8: 'east_team_8'};
        final westPlayInResults = {7: 'west_team_7', 8: 'west_team_8'};

        final firstRound = PlayoffService.generateFirstRoundSeries(
          seedings,
          conferences,
          eastPlayInResults,
          westPlayInResults,
        );

        for (var series in firstRound) {
          expect(series.round, 'first-round');
        }
      });
    });

    group('generateConferenceSemis', () {
      test('should generate 4 conference semifinals series', () {
        // Create completed first round series
        final firstRound = [
          // East
          _createCompletedSeries('east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          // West
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final semis = PlayoffService.generateConferenceSemis(firstRound);

        expect(semis.length, 4);
      });

      test('should match 1v8 winner with 4v5 winner', () {
        final firstRound = [
          _createCompletedSeries('east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final semis = PlayoffService.generateConferenceSemis(firstRound);
        final eastSemis = semis.where((s) => s.conference == 'east').toList();

        // Find the series with team 1 and team 4
        final series1v4 = eastSemis.firstWhere((s) =>
          (s.homeTeamId == 'east_team_1' || s.awayTeamId == 'east_team_1') &&
          (s.homeTeamId == 'east_team_4' || s.awayTeamId == 'east_team_4'));

        expect(series1v4, isNotNull);
      });

      test('should set round to "conf-semis"', () {
        final firstRound = [
          _createCompletedSeries('east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final semis = PlayoffService.generateConferenceSemis(firstRound);

        for (var series in semis) {
          expect(series.round, 'conf-semis');
        }
      });
    });

    group('generateConferenceFinals', () {
      test('should generate 2 conference finals series', () {
        final semis = [
          _createCompletedSeries('east_team_1', 'east_team_4', 'east_team_1', 'conf-semis', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_3', 'east_team_2', 'conf-semis', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_4', 'west_team_1', 'conf-semis', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_3', 'west_team_2', 'conf-semis', 'west'),
        ];

        final finals = PlayoffService.generateConferenceFinals(semis);

        expect(finals.length, 2);
      });

      test('should match conference semifinals winners', () {
        final semis = [
          _createCompletedSeries('east_team_1', 'east_team_4', 'east_team_1', 'conf-semis', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_3', 'east_team_2', 'conf-semis', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_4', 'west_team_1', 'conf-semis', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_3', 'west_team_2', 'conf-semis', 'west'),
        ];

        final finals = PlayoffService.generateConferenceFinals(semis);
        final eastFinals = finals.firstWhere((s) => s.conference == 'east');

        expect(
          (eastFinals.homeTeamId == 'east_team_1' || eastFinals.awayTeamId == 'east_team_1'),
          true,
        );
        expect(
          (eastFinals.homeTeamId == 'east_team_2' || eastFinals.awayTeamId == 'east_team_2'),
          true,
        );
      });

      test('should set round to "conf-finals"', () {
        final semis = [
          _createCompletedSeries('east_team_1', 'east_team_4', 'east_team_1', 'conf-semis', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_3', 'east_team_2', 'conf-semis', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_4', 'west_team_1', 'conf-semis', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_3', 'west_team_2', 'conf-semis', 'west'),
        ];

        final finals = PlayoffService.generateConferenceFinals(semis);

        for (var series in finals) {
          expect(series.round, 'conf-finals');
        }
      });
    });

    group('generateNBAFinals', () {
      test('should generate NBA Finals series', () {
        final confFinals = [
          _createCompletedSeries('east_team_1', 'east_team_2', 'east_team_1', 'conf-finals', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_2', 'west_team_1', 'conf-finals', 'west'),
        ];

        final nbaFinals = PlayoffService.generateNBAFinals(confFinals);

        expect(nbaFinals, isNotNull);
        expect(nbaFinals.round, 'finals');
        expect(nbaFinals.conference, 'finals');
      });

      test('should match Eastern and Western conference champions', () {
        final confFinals = [
          _createCompletedSeries('east_team_1', 'east_team_2', 'east_team_1', 'conf-finals', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_2', 'west_team_1', 'conf-finals', 'west'),
        ];

        final nbaFinals = PlayoffService.generateNBAFinals(confFinals);

        expect(
          (nbaFinals.homeTeamId == 'east_team_1' || nbaFinals.awayTeamId == 'east_team_1'),
          true,
        );
        expect(
          (nbaFinals.homeTeamId == 'west_team_1' || nbaFinals.awayTeamId == 'west_team_1'),
          true,
        );
      });

      test('should throw error if conference finals are not complete', () {
        final confFinals = [
          PlayoffSeries(
            id: 'series1',
            homeTeamId: 'east_team_1',
            awayTeamId: 'east_team_2',
            homeWins: 2,
            awayWins: 1,
            round: 'conf-finals',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          _createCompletedSeries('west_team_1', 'west_team_2', 'west_team_1', 'conf-finals', 'west'),
        ];

        expect(
          () => PlayoffService.generateNBAFinals(confFinals),
          throwsStateError,
        );
      });
    });

    group('advancePlayoffRound', () {
      test('should not advance if current round is not complete', () {
        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: PlayoffBracketGenerator.generatePlayInGames(seedings, conferences),
          firstRound: [],
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'play-in',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'play-in'); // Should not advance
      });

      test('should advance from play-in to first round when complete', () {
        // Create completed play-in games
        final playInGames = PlayoffBracketGenerator.generatePlayInGames(seedings, conferences);
        
        // Complete all play-in games
        final completedPlayInGames = <PlayoffSeries>[];
        
        // East games
        final eastGames = playInGames.where((g) => g.conference == 'east').toList();
        var game78East = eastGames[0];
        for (int i = 0; i < 4; i++) {
          game78East = game78East.copyWithGameResult('g1_$i', 'east_team_7');
        }
        
        var game910East = eastGames[1];
        for (int i = 0; i < 4; i++) {
          game910East = game910East.copyWithGameResult('g2_$i', 'east_team_9');
        }
        
        var secondGameEast = PlayoffBracketGenerator.createSecondPlayInGame(
          game78East,
          game910East,
          'east',
        );
        for (int i = 0; i < 4; i++) {
          secondGameEast = secondGameEast.copyWithGameResult('g3_$i', 'east_team_8');
        }
        
        completedPlayInGames.addAll([game78East, game910East, secondGameEast]);
        
        // West games
        final westGames = playInGames.where((g) => g.conference == 'west').toList();
        var game78West = westGames[0];
        for (int i = 0; i < 4; i++) {
          game78West = game78West.copyWithGameResult('g4_$i', 'west_team_7');
        }
        
        var game910West = westGames[1];
        for (int i = 0; i < 4; i++) {
          game910West = game910West.copyWithGameResult('g5_$i', 'west_team_9');
        }
        
        var secondGameWest = PlayoffBracketGenerator.createSecondPlayInGame(
          game78West,
          game910West,
          'west',
        );
        for (int i = 0; i < 4; i++) {
          secondGameWest = secondGameWest.copyWithGameResult('g6_$i', 'west_team_8');
        }
        
        completedPlayInGames.addAll([game78West, game910West, secondGameWest]);

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: completedPlayInGames,
          firstRound: [],
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'play-in',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'first-round');
        expect(advanced.firstRound.length, 8);
      });

      test('should advance from first round to conference semis', () {
        final firstRound = [
          _createCompletedSeries('east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'conf-semis');
        expect(advanced.conferenceSemis.length, 4);
      });

      test('should advance from conference semis to conference finals', () {
        final semis = [
          _createCompletedSeries('east_team_1', 'east_team_4', 'east_team_1', 'conf-semis', 'east'),
          _createCompletedSeries('east_team_2', 'east_team_3', 'east_team_2', 'conf-semis', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_4', 'west_team_1', 'conf-semis', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_3', 'west_team_2', 'conf-semis', 'west'),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: [],
          conferenceSemis: semis,
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'conf-semis',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'conf-finals');
        expect(advanced.conferenceFinals.length, 2);
      });

      test('should advance from conference finals to NBA Finals', () {
        final confFinals = [
          _createCompletedSeries('east_team_1', 'east_team_2', 'east_team_1', 'conf-finals', 'east'),
          _createCompletedSeries('west_team_1', 'west_team_2', 'west_team_1', 'conf-finals', 'west'),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: [],
          conferenceSemis: [],
          conferenceFinals: confFinals,
          nbaFinals: null,
          currentRound: 'conf-finals',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'finals');
        expect(advanced.nbaFinals, isNotNull);
      });

      test('should mark playoffs as complete after NBA Finals', () {
        final nbaFinals = _createCompletedSeries(
          'east_team_1',
          'west_team_1',
          'east_team_1',
          'finals',
          'finals',
        );

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: [],
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: nbaFinals,
          currentRound: 'finals',
        );

        final advanced = PlayoffService.advancePlayoffRound(bracket);

        expect(advanced.currentRound, 'complete');
      });
    });

    group('createSecondPlayInGame', () {
      test('should create game between loser of 7v8 and winner of 9v10', () {
        final game78 = PlayoffSeries(
          id: 'game1',
          homeTeamId: 'east_team_7',
          awayTeamId: 'east_team_8',
          homeWins: 4,
          awayWins: 0,
          round: 'play-in',
          conference: 'east',
          gameIds: ['g1'],
          isComplete: true,
        );

        final game910 = PlayoffSeries(
          id: 'game2',
          homeTeamId: 'east_team_9',
          awayTeamId: 'east_team_10',
          homeWins: 4,
          awayWins: 0,
          round: 'play-in',
          conference: 'east',
          gameIds: ['g2'],
          isComplete: true,
        );

        final secondGame = PlayoffService.createSecondPlayInGame(
          game78,
          game910,
          'east',
        );

        // Loser of 7v8 is team 8, winner of 9v10 is team 9
        expect(
          (secondGame.homeTeamId == 'east_team_8' || secondGame.awayTeamId == 'east_team_8'),
          true,
        );
        expect(
          (secondGame.homeTeamId == 'east_team_9' || secondGame.awayTeamId == 'east_team_9'),
          true,
        );
      });

      test('should throw error if games are not complete', () {
        final game78 = PlayoffSeries(
          id: 'game1',
          homeTeamId: 'east_team_7',
          awayTeamId: 'east_team_8',
          homeWins: 2,
          awayWins: 1,
          round: 'play-in',
          conference: 'east',
          gameIds: [],
          isComplete: false,
        );

        final game910 = PlayoffSeries(
          id: 'game2',
          homeTeamId: 'east_team_9',
          awayTeamId: 'east_team_10',
          homeWins: 4,
          awayWins: 0,
          round: 'play-in',
          conference: 'east',
          gameIds: [],
          isComplete: true,
        );

        expect(
          () => PlayoffService.createSecondPlayInGame(game78, game910, 'east'),
          throwsStateError,
        );
      });
    });

    group('simulateNonUserPlayoffGames', () {
      test('should simulate all non-user series in current round', () {
        // Create first round with user team in one series
        final firstRound = [
          // User team series (should not be simulated)
          PlayoffSeries(
            id: 'user_series',
            homeTeamId: 'user_team',
            awayTeamId: 'east_team_8',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          // Non-user series (should be simulated)
          PlayoffSeries(
            id: 'series2',
            homeTeamId: 'east_team_2',
            awayTeamId: 'east_team_7',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          PlayoffSeries(
            id: 'series3',
            homeTeamId: 'east_team_3',
            awayTeamId: 'east_team_6',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        // Mock team getter
        Team getTeam(String teamId) {
          return _createMockTeam(teamId);
        }

        // Mock game simulator (always home team wins)
        Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
          return _createMockGame(homeTeam.id, awayTeam.id, 100, 90);
        }

        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: bracket,
          userTeamId: 'user_team',
          getTeam: getTeam,
          simulateGame: simulateGame,
        );

        // User series should not be simulated
        final userSeries = result.bracket.firstRound.firstWhere((s) => s.id == 'user_series');
        expect(userSeries.isComplete, false);
        expect(userSeries.homeWins, 0);
        expect(userSeries.awayWins, 0);

        // Non-user series should be simulated to completion
        final series2 = result.bracket.firstRound.firstWhere((s) => s.id == 'series2');
        expect(series2.isComplete, true);
        expect(series2.homeWins + series2.awayWins, greaterThanOrEqualTo(4));

        final series3 = result.bracket.firstRound.firstWhere((s) => s.id == 'series3');
        expect(series3.isComplete, true);
        expect(series3.homeWins + series3.awayWins, greaterThanOrEqualTo(4));

        // Game results should be recorded
        expect(result.gameResults.length, 2); // Two non-user series
        expect(result.gameResults.containsKey('series2'), true);
        expect(result.gameResults.containsKey('series3'), true);
      });

      test('should not simulate already completed series', () {
        // Create all 8 first round series (4 per conference)
        final firstRound = [
          // East - Already completed series
          _createCompletedSeries('east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
          // East - Incomplete series
          PlayoffSeries(
            id: 'series2',
            homeTeamId: 'east_team_2',
            awayTeamId: 'east_team_7',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          // East - More completed series to fill out the conference
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          // West - All completed
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        Team getTeam(String teamId) => _createMockTeam(teamId);
        Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
          return _createMockGame(homeTeam.id, awayTeam.id, 100, 90);
        }

        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: bracket,
          userTeamId: 'user_team',
          getTeam: getTeam,
          simulateGame: simulateGame,
        );

        // Only one series should have game results (the incomplete one)
        expect(result.gameResults.length, 1);
        expect(result.gameResults.containsKey('series2'), true);
        
        // The bracket should advance to conference semis since all series are now complete
        expect(result.bracket.currentRound, 'conf-semis');
      });

      test('should advance to next round if all series complete', () {
        // Create all first round series as incomplete (except user team)
        final firstRound = [
          // User team series (incomplete)
          PlayoffSeries(
            id: 'user_series',
            homeTeamId: 'user_team',
            awayTeamId: 'east_team_8',
            homeWins: 2,
            awayWins: 1,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          // All other series will be simulated to completion
          PlayoffSeries(
            id: 'series2',
            homeTeamId: 'east_team_2',
            awayTeamId: 'east_team_7',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        Team getTeam(String teamId) => _createMockTeam(teamId);
        Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
          return _createMockGame(homeTeam.id, awayTeam.id, 100, 90);
        }

        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: bracket,
          userTeamId: 'user_team',
          getTeam: getTeam,
          simulateGame: simulateGame,
        );

        // Round should NOT advance because user series is not complete
        expect(result.bracket.currentRound, 'first-round');
      });

      test('should generate summary of simulated games', () {
        // Create all 8 first round series with one incomplete
        final firstRound = [
          // East - One incomplete series
          PlayoffSeries(
            id: 'series1',
            homeTeamId: 'east_team_1',
            awayTeamId: 'east_team_8',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
          // East - Rest completed
          _createCompletedSeries('east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
          _createCompletedSeries('east_team_3', 'east_team_6', 'east_team_3', 'first-round', 'east'),
          _createCompletedSeries('east_team_4', 'east_team_5', 'east_team_4', 'first-round', 'east'),
          // West - All completed
          _createCompletedSeries('west_team_1', 'west_team_8', 'west_team_1', 'first-round', 'west'),
          _createCompletedSeries('west_team_2', 'west_team_7', 'west_team_2', 'first-round', 'west'),
          _createCompletedSeries('west_team_3', 'west_team_6', 'west_team_3', 'first-round', 'west'),
          _createCompletedSeries('west_team_4', 'west_team_5', 'west_team_4', 'first-round', 'west'),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        Team getTeam(String teamId) => _createMockTeam(teamId);
        Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
          return _createMockGame(homeTeam.id, awayTeam.id, 100, 90);
        }

        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: bracket,
          userTeamId: 'user_team',
          getTeam: getTeam,
          simulateGame: simulateGame,
        );

        final summary = result.getSummary();
        expect(summary, contains('Playoff Games Simulated'));
        expect(summary, isNot(contains('No games were simulated')));
      });

      test('should return empty summary when no games simulated', () {
        final firstRound = [
          // User team series only
          PlayoffSeries(
            id: 'user_series',
            homeTeamId: 'user_team',
            awayTeamId: 'east_team_8',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ];

        final bracket = PlayoffBracket(
          seasonId: 'season1',
          teamSeedings: seedings,
          teamConferences: conferences,
          playInGames: [],
          firstRound: firstRound,
          conferenceSemis: [],
          conferenceFinals: [],
          nbaFinals: null,
          currentRound: 'first-round',
        );

        Team getTeam(String teamId) => _createMockTeam(teamId);
        Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
          return _createMockGame(homeTeam.id, awayTeam.id, 100, 90);
        }

        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: bracket,
          userTeamId: 'user_team',
          getTeam: getTeam,
          simulateGame: simulateGame,
        );

        final summary = result.getSummary();
        expect(summary, contains('No games were simulated'));
      });
    });
  });
}

/// Helper function to create a completed playoff series
PlayoffSeries _createCompletedSeries(
  String homeTeam,
  String awayTeam,
  String winner,
  String round,
  String conference,
) {
  final homeWins = winner == homeTeam ? 4 : 0;
  final awayWins = winner == awayTeam ? 4 : 0;

  return PlayoffSeries(
    id: 'series_${homeTeam}_$awayTeam',
    homeTeamId: homeTeam,
    awayTeamId: awayTeam,
    homeWins: homeWins,
    awayWins: awayWins,
    round: round,
    conference: conference,
    gameIds: ['g1', 'g2', 'g3', 'g4'],
    isComplete: true,
  );
}

/// Helper function to create a mock team for testing
Team _createMockTeam(String teamId) {
  return Team(
    id: teamId,
    name: 'Team',
    city: 'City',
    players: List.generate(15, (i) => _createMockPlayer('player_${teamId}_$i')),
    startingLineupIds: List.generate(5, (i) => 'player_${teamId}_$i'),
  );
}

/// Helper function to create a mock player for testing
Player _createMockPlayer(String playerId) {
  return Player(
    id: playerId,
    name: 'Test Player',
    heightInches: 75,
    shooting: 70,
    defense: 70,
    speed: 70,
    postShooting: 70,
    passing: 70,
    rebounding: 70,
    ballHandling: 70,
    threePoint: 70,
    blocks: 70,
    steals: 70,
    position: 'SG',
  );
}

/// Helper function to create a mock game for testing
Game _createMockGame(String homeTeamId, String awayTeamId, int homeScore, int awayScore) {
  return Game(
    id: 'game_${DateTime.now().millisecondsSinceEpoch}',
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    homeScore: homeScore,
    awayScore: awayScore,
    isPlayed: true,
    scheduledDate: DateTime.now(),
  );
}
