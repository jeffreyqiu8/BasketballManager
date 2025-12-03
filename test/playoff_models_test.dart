import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';

void main() {
  group('PlayoffSeries Model Tests', () {
    test('should create a new playoff series with initial state', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );

      expect(series.id, 'series1');
      expect(series.homeTeamId, 'team1');
      expect(series.awayTeamId, 'team2');
      expect(series.homeWins, 0);
      expect(series.awayWins, 0);
      expect(series.round, 'first-round');
      expect(series.conference, 'east');
      expect(series.gameIds, isEmpty);
      expect(series.isComplete, false);
    });

    test('winnerId should return null when series is not complete', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 2,
        awayWins: 1,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3'],
        isComplete: false,
      );

      expect(series.winnerId, isNull);
    });

    test('winnerId should return home team ID when home team wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 4,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6'],
        isComplete: true,
      );

      expect(series.winnerId, 'team1');
    });

    test('winnerId should return away team ID when away team wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 1,
        awayWins: 4,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: true,
      );

      expect(series.winnerId, 'team2');
    });

    test('seriesScore should return correct format', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 3,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      expect(series.seriesScore, '3-2');
    });

    test('copyWithGameResult should increment home wins when home team wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 2,
        awayWins: 1,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3'],
        isComplete: false,
      );

      final updated = series.copyWithGameResult('g4', 'team1');

      expect(updated.homeWins, 3);
      expect(updated.awayWins, 1);
      expect(updated.gameIds, ['g1', 'g2', 'g3', 'g4']);
      expect(updated.isComplete, false);
    });

    test('copyWithGameResult should increment away wins when away team wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 2,
        awayWins: 1,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3'],
        isComplete: false,
      );

      final updated = series.copyWithGameResult('g4', 'team2');

      expect(updated.homeWins, 2);
      expect(updated.awayWins, 2);
      expect(updated.gameIds, ['g1', 'g2', 'g3', 'g4']);
      expect(updated.isComplete, false);
    });

    test('copyWithGameResult should mark series complete when home team reaches 4 wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 3,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      final updated = series.copyWithGameResult('g6', 'team1');

      expect(updated.homeWins, 4);
      expect(updated.awayWins, 2);
      expect(updated.isComplete, true);
      expect(updated.winnerId, 'team1');
    });

    test('copyWithGameResult should mark series complete when away team reaches 4 wins', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 2,
        awayWins: 3,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      final updated = series.copyWithGameResult('g6', 'team2');

      expect(updated.homeWins, 2);
      expect(updated.awayWins, 4);
      expect(updated.isComplete, true);
      expect(updated.winnerId, 'team2');
    });

    test('series can go to 7 games', () {
      var series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );

      // Simulate a 7-game series: team1 wins 4-3
      series = series.copyWithGameResult('g1', 'team1'); // 1-0
      series = series.copyWithGameResult('g2', 'team2'); // 1-1
      series = series.copyWithGameResult('g3', 'team1'); // 2-1
      series = series.copyWithGameResult('g4', 'team2'); // 2-2
      series = series.copyWithGameResult('g5', 'team1'); // 3-2
      series = series.copyWithGameResult('g6', 'team2'); // 3-3

      expect(series.isComplete, false);
      expect(series.homeWins, 3);
      expect(series.awayWins, 3);

      series = series.copyWithGameResult('g7', 'team1'); // 4-3

      expect(series.isComplete, true);
      expect(series.homeWins, 4);
      expect(series.awayWins, 3);
      expect(series.winnerId, 'team1');
      expect(series.gameIds.length, 7);
    });

    test('series can end in 4 games (sweep)', () {
      var series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );

      series = series.copyWithGameResult('g1', 'team1');
      series = series.copyWithGameResult('g2', 'team1');
      series = series.copyWithGameResult('g3', 'team1');
      series = series.copyWithGameResult('g4', 'team1');

      expect(series.isComplete, true);
      expect(series.homeWins, 4);
      expect(series.awayWins, 0);
      expect(series.winnerId, 'team1');
      expect(series.gameIds.length, 4);
    });

    test('toJson should serialize all fields correctly', () {
      final series = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 3,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      final json = series.toJson();

      expect(json['id'], 'series1');
      expect(json['homeTeamId'], 'team1');
      expect(json['awayTeamId'], 'team2');
      expect(json['homeWins'], 3);
      expect(json['awayWins'], 2);
      expect(json['round'], 'first-round');
      expect(json['conference'], 'east');
      expect(json['gameIds'], ['g1', 'g2', 'g3', 'g4', 'g5']);
      expect(json['isComplete'], false);
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'id': 'series1',
        'homeTeamId': 'team1',
        'awayTeamId': 'team2',
        'homeWins': 3,
        'awayWins': 2,
        'round': 'first-round',
        'conference': 'east',
        'gameIds': ['g1', 'g2', 'g3', 'g4', 'g5'],
        'isComplete': false,
      };

      final series = PlayoffSeries.fromJson(json);

      expect(series.id, 'series1');
      expect(series.homeTeamId, 'team1');
      expect(series.awayTeamId, 'team2');
      expect(series.homeWins, 3);
      expect(series.awayWins, 2);
      expect(series.round, 'first-round');
      expect(series.conference, 'east');
      expect(series.gameIds, ['g1', 'g2', 'g3', 'g4', 'g5']);
      expect(series.isComplete, false);
    });

    test('serialization round trip preserves all data', () {
      final original = PlayoffSeries(
        id: 'series1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeWins: 4,
        awayWins: 3,
        round: 'conf-finals',
        conference: 'west',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7'],
        isComplete: true,
      );

      final json = original.toJson();
      final deserialized = PlayoffSeries.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.homeTeamId, original.homeTeamId);
      expect(deserialized.awayTeamId, original.awayTeamId);
      expect(deserialized.homeWins, original.homeWins);
      expect(deserialized.awayWins, original.awayWins);
      expect(deserialized.round, original.round);
      expect(deserialized.conference, original.conference);
      expect(deserialized.gameIds, original.gameIds);
      expect(deserialized.isComplete, original.isComplete);
      expect(deserialized.winnerId, original.winnerId);
    });
  });

  group('PlayoffBracket Model Tests', () {
    late Map<String, int> seedings;
    late Map<String, String> conferences;

    setUp(() {
      seedings = {};
      conferences = {};

      // Create 30 teams (15 per conference)
      for (int i = 1; i <= 15; i++) {
        seedings['east_team_$i'] = i;
        conferences['east_team_$i'] = 'east';
        seedings['west_team_$i'] = i;
        conferences['west_team_$i'] = 'west';
      }
    });

    test('should create a new playoff bracket with initial state', () {
      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      expect(bracket.seasonId, 'season1');
      expect(bracket.teamSeedings.length, 30);
      expect(bracket.teamConferences.length, 30);
      expect(bracket.currentRound, 'play-in');
      expect(bracket.nbaFinals, isNull);
    });

    test('getCurrentRoundSeries should return play-in games when in play-in round', () {
      final playInGames = [
        _createSeries('series1', 'east_team_7', 'east_team_8', 'play-in', 'east'),
        _createSeries('series2', 'east_team_9', 'east_team_10', 'play-in', 'east'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries.length, 2);
      expect(currentSeries, playInGames);
    });

    test('getCurrentRoundSeries should return first round series when in first round', () {
      final firstRound = [
        _createSeries('series1', 'east_team_1', 'east_team_8', 'first-round', 'east'),
        _createSeries('series2', 'east_team_2', 'east_team_7', 'first-round', 'east'),
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

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries.length, 2);
      expect(currentSeries, firstRound);
    });

    test('getCurrentRoundSeries should return conference semis when in conf-semis round', () {
      final semis = [
        _createSeries('series1', 'east_team_1', 'east_team_4', 'conf-semis', 'east'),
        _createSeries('series2', 'east_team_2', 'east_team_3', 'conf-semis', 'east'),
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

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries.length, 2);
      expect(currentSeries, semis);
    });

    test('getCurrentRoundSeries should return conference finals when in conf-finals round', () {
      final finals = [
        _createSeries('series1', 'east_team_1', 'east_team_2', 'conf-finals', 'east'),
        _createSeries('series2', 'west_team_1', 'west_team_2', 'conf-finals', 'west'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: finals,
        nbaFinals: null,
        currentRound: 'conf-finals',
      );

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries.length, 2);
      expect(currentSeries, finals);
    });

    test('getCurrentRoundSeries should return NBA Finals when in finals round', () {
      final nbaFinals = _createSeries('finals', 'east_team_1', 'west_team_1', 'finals', 'finals');

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

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries.length, 1);
      expect(currentSeries.first, nbaFinals);
    });

    test('getCurrentRoundSeries should return empty list when playoffs are complete', () {
      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'complete',
      );

      final currentSeries = bracket.getCurrentRoundSeries();
      expect(currentSeries, isEmpty);
    });

    test('getUserTeamSeries should return series containing user team', () {
      final firstRound = [
        _createSeries('series1', 'user_team', 'east_team_8', 'first-round', 'east'),
        _createSeries('series2', 'east_team_2', 'east_team_7', 'first-round', 'east'),
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

      final userSeries = bracket.getUserTeamSeries('user_team');
      expect(userSeries, isNotNull);
      expect(userSeries!.id, 'series1');
      expect(userSeries.homeTeamId, 'user_team');
    });

    test('getUserTeamSeries should return null when user team is not in current round', () {
      final firstRound = [
        _createSeries('series1', 'east_team_1', 'east_team_8', 'first-round', 'east'),
        _createSeries('series2', 'east_team_2', 'east_team_7', 'first-round', 'east'),
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

      final userSeries = bracket.getUserTeamSeries('user_team');
      expect(userSeries, isNull);
    });

    test('isTeamEliminated should return false for team that has not lost', () {
      final firstRound = [
        _createCompletedSeries('series1', 'east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
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

      expect(bracket.isTeamEliminated('east_team_1'), false);
    });

    test('isTeamEliminated should return true for team that lost in first round', () {
      final firstRound = [
        _createCompletedSeries('series1', 'east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
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

      expect(bracket.isTeamEliminated('east_team_8'), true);
    });

    test('isTeamEliminated should return true for team that lost in conference semis', () {
      final semis = [
        _createCompletedSeries('series1', 'east_team_1', 'east_team_4', 'east_team_1', 'conf-semis', 'east'),
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

      expect(bracket.isTeamEliminated('east_team_4'), true);
    });

    test('isTeamEliminated should return true for team that lost in conference finals', () {
      final confFinals = [
        _createCompletedSeries('series1', 'east_team_1', 'east_team_2', 'east_team_1', 'conf-finals', 'east'),
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

      expect(bracket.isTeamEliminated('east_team_2'), true);
    });

    test('isTeamEliminated should return true for team that lost NBA Finals', () {
      final nbaFinals = _createCompletedSeries('finals', 'east_team_1', 'west_team_1', 'east_team_1', 'finals', 'finals');

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: nbaFinals,
        currentRound: 'complete',
      );

      expect(bracket.isTeamEliminated('west_team_1'), true);
    });

    test('isTeamEliminated should return false for NBA champion', () {
      final nbaFinals = _createCompletedSeries('finals', 'east_team_1', 'west_team_1', 'east_team_1', 'finals', 'finals');

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: nbaFinals,
        currentRound: 'complete',
      );

      expect(bracket.isTeamEliminated('east_team_1'), false);
    });

    test('isTeamEliminated should handle play-in elimination correctly', () {
      // Team that lost play-in and didn't make first round
      final playInGames = [
        _createCompletedSeries('series1', 'east_team_7', 'east_team_8', 'east_team_7', 'play-in', 'east'),
        _createCompletedSeries('series2', 'east_team_9', 'east_team_10', 'east_team_9', 'play-in', 'east'),
        _createCompletedSeries('series3', 'east_team_8', 'east_team_9', 'east_team_8', 'play-in', 'east'),
      ];

      final firstRound = [
        _createSeries('series4', 'east_team_1', 'east_team_8', 'first-round', 'east'),
        _createSeries('series5', 'east_team_2', 'east_team_7', 'first-round', 'east'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: firstRound,
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      // Team 9 and 10 lost play-in and didn't make first round
      expect(bracket.isTeamEliminated('east_team_9'), true);
      expect(bracket.isTeamEliminated('east_team_10'), true);
      
      // Teams 7 and 8 made it to first round
      expect(bracket.isTeamEliminated('east_team_7'), false);
      expect(bracket.isTeamEliminated('east_team_8'), false);
    });

    test('isRoundComplete should return false when series are not complete', () {
      final firstRound = [
        _createSeries('series1', 'east_team_1', 'east_team_8', 'first-round', 'east'),
        _createSeries('series2', 'east_team_2', 'east_team_7', 'first-round', 'east'),
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

      expect(bracket.isRoundComplete(), false);
    });

    test('isRoundComplete should return true when all series are complete', () {
      final firstRound = [
        _createCompletedSeries('series1', 'east_team_1', 'east_team_8', 'east_team_1', 'first-round', 'east'),
        _createCompletedSeries('series2', 'east_team_2', 'east_team_7', 'east_team_2', 'first-round', 'east'),
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

      expect(bracket.isRoundComplete(), true);
    });

    test('isRoundComplete should return false for play-in with only 4 games', () {
      final playInGames = [
        _createCompletedSeries('series1', 'east_team_7', 'east_team_8', 'east_team_7', 'play-in', 'east'),
        _createCompletedSeries('series2', 'east_team_9', 'east_team_10', 'east_team_9', 'play-in', 'east'),
        _createCompletedSeries('series3', 'west_team_7', 'west_team_8', 'west_team_7', 'play-in', 'west'),
        _createCompletedSeries('series4', 'west_team_9', 'west_team_10', 'west_team_9', 'play-in', 'west'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      expect(bracket.isRoundComplete(), false);
    });

    test('isRoundComplete should return true for play-in with all 6 games complete', () {
      final playInGames = [
        _createCompletedSeries('series1', 'east_team_7', 'east_team_8', 'east_team_7', 'play-in', 'east'),
        _createCompletedSeries('series2', 'east_team_9', 'east_team_10', 'east_team_9', 'play-in', 'east'),
        _createCompletedSeries('series3', 'east_team_8', 'east_team_9', 'east_team_8', 'play-in', 'east'),
        _createCompletedSeries('series4', 'west_team_7', 'west_team_8', 'west_team_7', 'play-in', 'west'),
        _createCompletedSeries('series5', 'west_team_9', 'west_team_10', 'west_team_9', 'play-in', 'west'),
        _createCompletedSeries('series6', 'west_team_8', 'west_team_9', 'west_team_8', 'play-in', 'west'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      expect(bracket.isRoundComplete(), true);
    });

    test('needsSecondPlayInGames should return true when 4 initial games are complete', () {
      final playInGames = [
        _createCompletedSeries('series1', 'east_team_7', 'east_team_8', 'east_team_7', 'play-in', 'east'),
        _createCompletedSeries('series2', 'east_team_9', 'east_team_10', 'east_team_9', 'play-in', 'east'),
        _createCompletedSeries('series3', 'west_team_7', 'west_team_8', 'west_team_7', 'play-in', 'west'),
        _createCompletedSeries('series4', 'west_team_9', 'west_team_10', 'west_team_9', 'play-in', 'west'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      expect(bracket.needsSecondPlayInGames(), true);
    });

    test('needsSecondPlayInGames should return false when not in play-in round', () {
      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      expect(bracket.needsSecondPlayInGames(), false);
    });

    test('needsSecondPlayInGames should return false when already have 6 games', () {
      final playInGames = [
        _createCompletedSeries('series1', 'east_team_7', 'east_team_8', 'east_team_7', 'play-in', 'east'),
        _createCompletedSeries('series2', 'east_team_9', 'east_team_10', 'east_team_9', 'play-in', 'east'),
        _createCompletedSeries('series3', 'east_team_8', 'east_team_9', 'east_team_8', 'play-in', 'east'),
        _createCompletedSeries('series4', 'west_team_7', 'west_team_8', 'west_team_7', 'play-in', 'west'),
        _createCompletedSeries('series5', 'west_team_9', 'west_team_10', 'west_team_9', 'play-in', 'west'),
        _createCompletedSeries('series6', 'west_team_8', 'west_team_9', 'west_team_8', 'play-in', 'west'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      expect(bracket.needsSecondPlayInGames(), false);
    });

    test('toJson should serialize all fields correctly', () {
      final playInGames = [
        _createSeries('series1', 'east_team_7', 'east_team_8', 'play-in', 'east'),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      final json = bracket.toJson();

      expect(json['seasonId'], 'season1');
      expect(json['teamSeedings'], seedings);
      expect(json['teamConferences'], conferences);
      expect(json['playInGames'], isA<List>());
      expect(json['playInGames'].length, 1);
      expect(json['firstRound'], isEmpty);
      expect(json['conferenceSemis'], isEmpty);
      expect(json['conferenceFinals'], isEmpty);
      expect(json['nbaFinals'], isNull);
      expect(json['currentRound'], 'play-in');
    });

    test('fromJson should deserialize all fields correctly', () {
      final json = {
        'seasonId': 'season1',
        'teamSeedings': seedings,
        'teamConferences': conferences,
        'playInGames': [
          {
            'id': 'series1',
            'homeTeamId': 'east_team_7',
            'awayTeamId': 'east_team_8',
            'homeWins': 0,
            'awayWins': 0,
            'round': 'play-in',
            'conference': 'east',
            'gameIds': [],
            'isComplete': false,
          }
        ],
        'firstRound': [],
        'conferenceSemis': [],
        'conferenceFinals': [],
        'nbaFinals': null,
        'currentRound': 'play-in',
      };

      final bracket = PlayoffBracket.fromJson(json);

      expect(bracket.seasonId, 'season1');
      expect(bracket.teamSeedings.length, 30);
      expect(bracket.teamConferences.length, 30);
      expect(bracket.playInGames.length, 1);
      expect(bracket.firstRound, isEmpty);
      expect(bracket.conferenceSemis, isEmpty);
      expect(bracket.conferenceFinals, isEmpty);
      expect(bracket.nbaFinals, isNull);
      expect(bracket.currentRound, 'play-in');
    });

    test('serialization round trip preserves all data', () {
      final playInGames = [
        _createSeries('series1', 'east_team_7', 'east_team_8', 'play-in', 'east'),
      ];

      final firstRound = [
        _createSeries('series2', 'east_team_1', 'east_team_8', 'first-round', 'east'),
      ];

      final original = PlayoffBracket(
        seasonId: 'season1',
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: playInGames,
        firstRound: firstRound,
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      final json = original.toJson();
      final deserialized = PlayoffBracket.fromJson(json);

      expect(deserialized.seasonId, original.seasonId);
      expect(deserialized.teamSeedings, original.teamSeedings);
      expect(deserialized.teamConferences, original.teamConferences);
      expect(deserialized.playInGames.length, original.playInGames.length);
      expect(deserialized.firstRound.length, original.firstRound.length);
      expect(deserialized.conferenceSemis.length, original.conferenceSemis.length);
      expect(deserialized.conferenceFinals.length, original.conferenceFinals.length);
      expect(deserialized.nbaFinals, original.nbaFinals);
      expect(deserialized.currentRound, original.currentRound);
    });
  });
}

/// Helper function to create a playoff series
PlayoffSeries _createSeries(
  String id,
  String homeTeam,
  String awayTeam,
  String round,
  String conference,
) {
  return PlayoffSeries(
    id: id,
    homeTeamId: homeTeam,
    awayTeamId: awayTeam,
    homeWins: 0,
    awayWins: 0,
    round: round,
    conference: conference,
    gameIds: [],
    isComplete: false,
  );
}

/// Helper function to create a completed playoff series
PlayoffSeries _createCompletedSeries(
  String id,
  String homeTeam,
  String awayTeam,
  String winner,
  String round,
  String conference,
) {
  final homeWins = winner == homeTeam ? 4 : 2;
  final awayWins = winner == awayTeam ? 4 : 2;

  return PlayoffSeries(
    id: id,
    homeTeamId: homeTeam,
    awayTeamId: awayTeam,
    homeWins: homeWins,
    awayWins: awayWins,
    round: round,
    conference: conference,
    gameIds: List.generate(homeWins + awayWins, (i) => 'g${i + 1}'),
    isComplete: true,
  );
}
