import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/player_game_stats.dart';
import 'package:BasketballManager/services/league_service.dart';

void main() {
  group('Season Playoff Support Tests', () {
    test('Season can be initialized without playoff data (backward compatibility)', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 0,
          awayScore: 0,
          isPlayed: false,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      );

      expect(season.isPostSeason, false);
      expect(season.playoffBracket, isNull);
      expect(season.playoffStats, isNull);
    });

    test('Season can start post-season with playoff bracket', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1, 'team2': 8},
        teamConferences: {'team1': 'east', 'team2': 'east'},
        playInGames: [],
        firstRound: [
          PlayoffSeries(
            id: 'series-1',
            homeTeamId: 'team1',
            awayTeamId: 'team2',
            homeWins: 0,
            awayWins: 0,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      final postSeasonSeason = season.startPostSeason(playoffBracket);

      expect(postSeasonSeason.isPostSeason, true);
      expect(postSeasonSeason.playoffBracket, isNotNull);
      expect(postSeasonSeason.playoffBracket!.seasonId, 'season-1');
      expect(postSeasonSeason.playoffStats, isNotNull);
      expect(postSeasonSeason.playoffStats!.isEmpty, true);
    });

    test('Season can update playoff statistics', () {
      final games = List.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1},
        teamConferences: {'team1': 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      ).startPostSeason(playoffBracket);

      final gameStats = {
        'player1': PlayerGameStats(
          playerId: 'player1',
          points: 25,
          rebounds: 8,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 20,
          threePointersMade: 3,
          threePointersAttempted: 8,
        ),
      };

      final updatedSeason = season.updatePlayoffStats(gameStats);

      expect(updatedSeason.playoffStats, isNotNull);
      expect(updatedSeason.playoffStats!.containsKey('player1'), true);
      
      final playerStats = updatedSeason.playoffStats!['player1']!;
      expect(playerStats.gamesPlayed, 1);
      expect(playerStats.totalPoints, 25);
      expect(playerStats.totalRebounds, 8);
      expect(playerStats.totalAssists, 5);
      expect(playerStats.pointsPerGame, 25.0);
    });

    test('Season can accumulate playoff statistics across multiple games', () {
      final games = List.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1},
        teamConferences: {'team1': 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      var season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      ).startPostSeason(playoffBracket);

      // Game 1
      final game1Stats = {
        'player1': PlayerGameStats(
          playerId: 'player1',
          points: 25,
          rebounds: 8,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 20,
          threePointersMade: 3,
          threePointersAttempted: 8,
        ),
      };
      season = season.updatePlayoffStats(game1Stats);

      // Game 2
      final game2Stats = {
        'player1': PlayerGameStats(
          playerId: 'player1',
          points: 30,
          rebounds: 10,
          assists: 7,
          fieldGoalsMade: 12,
          fieldGoalsAttempted: 22,
          threePointersMade: 4,
          threePointersAttempted: 10,
        ),
      };
      season = season.updatePlayoffStats(game2Stats);

      final playerStats = season.playoffStats!['player1']!;
      expect(playerStats.gamesPlayed, 2);
      expect(playerStats.totalPoints, 55);
      expect(playerStats.totalRebounds, 18);
      expect(playerStats.totalAssists, 12);
      expect(playerStats.pointsPerGame, 27.5);
      expect(playerStats.reboundsPerGame, 9.0);
      expect(playerStats.assistsPerGame, 6.0);
    });

    test('Season can retrieve player playoff statistics', () {
      final games = List.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1},
        teamConferences: {'team1': 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      ).startPostSeason(playoffBracket);

      final gameStats = {
        'player1': PlayerGameStats(
          playerId: 'player1',
          points: 25,
          rebounds: 8,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 20,
          threePointersMade: 3,
          threePointersAttempted: 8,
        ),
      };

      final updatedSeason = season.updatePlayoffStats(gameStats);

      final playerStats = updatedSeason.getPlayerPlayoffStats('player1');
      expect(playerStats, isNotNull);
      expect(playerStats!.playerId, 'player1');
      expect(playerStats.totalPoints, 25);

      final nonExistentStats = updatedSeason.getPlayerPlayoffStats('player999');
      expect(nonExistentStats, isNull);
    });

    test('Season serialization includes playoff data', () {
      final games = List.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1},
        teamConferences: {'team1': 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      ).startPostSeason(playoffBracket);

      final gameStats = {
        'player1': PlayerGameStats(
          playerId: 'player1',
          points: 25,
          rebounds: 8,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 20,
          threePointersMade: 3,
          threePointersAttempted: 8,
        ),
      };

      final updatedSeason = season.updatePlayoffStats(gameStats);

      final json = updatedSeason.toJson();
      expect(json['isPostSeason'], true);
      expect(json['playoffBracket'], isNotNull);
      expect(json['playoffStats'], isNotNull);

      final deserializedSeason = Season.fromJson(json);
      expect(deserializedSeason.isPostSeason, true);
      expect(deserializedSeason.playoffBracket, isNotNull);
      expect(deserializedSeason.playoffStats, isNotNull);
      expect(deserializedSeason.playoffStats!.containsKey('player1'), true);
      expect(deserializedSeason.playoffStats!['player1']!.totalPoints, 25);
    });

    test('Season deserialization handles missing playoff data (backward compatibility)', () {
      final json = {
        'id': 'season-1',
        'year': 2024,
        'games': List.generate(
          82,
          (i) => {
            'id': 'game-$i',
            'homeTeamId': 'team1',
            'awayTeamId': 'team2',
            'homeScore': 100,
            'awayScore': 90,
            'isPlayed': true,
            'scheduledDate': DateTime.now().toIso8601String(),
          },
        ),
        'userTeamId': 'team1',
        // No playoff fields
      };

      final season = Season.fromJson(json);
      expect(season.isPostSeason, false);
      expect(season.playoffBracket, isNull);
      expect(season.playoffStats, isNull);
    });
  });

  group('LeagueService Season Completion Tests', () {
    late LeagueService leagueService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
    });

    test('isRegularSeasonComplete returns false when season has not played all 82 games', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 0,
          awayScore: 0,
          isPlayed: i < 50, // Only 50 games played
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      );

      expect(leagueService.isRegularSeasonComplete(season), false);
    });

    test('isRegularSeasonComplete returns true when all 82 games are played', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true, // All games played
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      );

      expect(leagueService.isRegularSeasonComplete(season), true);
    });

    test('checkAndStartPostSeason returns null when season is not complete', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 0,
          awayScore: 0,
          isPlayed: i < 50, // Only 50 games played
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      );

      final result = leagueService.checkAndStartPostSeason(season);
      expect(result, isNull);
    });

    test('checkAndStartPostSeason returns null when already in post-season', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team1',
          awayTeamId: 'team2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-1',
        teamSeedings: {'team1': 1},
        teamConferences: {'team1': 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team1',
      ).startPostSeason(playoffBracket);

      final result = leagueService.checkAndStartPostSeason(season);
      expect(result, isNull);
    });

    test('checkAndStartPostSeason starts post-season when regular season is complete', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[i % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final result = leagueService.checkAndStartPostSeason(season);
      
      expect(result, isNotNull);
      expect(result!.isPostSeason, true);
      expect(result.playoffBracket, isNotNull);
      expect(result.playoffBracket!.currentRound, 'play-in');
      expect(result.playoffStats, isNotNull);
      expect(result.playoffStats!.isEmpty, true);
    });

    test('checkAndStartPostSeason generates playoff seedings correctly', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[i % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final result = leagueService.checkAndStartPostSeason(season);
      
      expect(result, isNotNull);
      final bracket = result!.playoffBracket!;
      
      // Check that seedings were generated for all teams
      expect(bracket.teamSeedings.length, 30);
      
      // Check that conferences were assigned
      expect(bracket.teamConferences.length, 30);
      
      // Check that each team has a seed between 1 and 15
      for (var seed in bracket.teamSeedings.values) {
        expect(seed, greaterThanOrEqualTo(1));
        expect(seed, lessThanOrEqualTo(15));
      }
    });

    test('checkAndStartPostSeason generates play-in games correctly', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[i % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final result = leagueService.checkAndStartPostSeason(season);
      
      expect(result, isNotNull);
      final bracket = result!.playoffBracket!;
      
      // Should have 4 play-in games (2 per conference)
      expect(bracket.playInGames.length, 4);
      
      // Check that play-in games are for the correct round
      for (var game in bracket.playInGames) {
        expect(game.round, 'play-in');
        expect(game.isComplete, false);
        expect(game.homeWins, 0);
        expect(game.awayWins, 0);
      }
      
      // Check that we have 2 games per conference
      final eastGames = bracket.playInGames.where((g) => g.conference == 'east').length;
      final westGames = bracket.playInGames.where((g) => g.conference == 'west').length;
      expect(eastGames, 2);
      expect(westGames, 2);
    });

    test('checkAndStartPostSeason initializes empty playoff stats', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[i % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final result = leagueService.checkAndStartPostSeason(season);
      
      expect(result, isNotNull);
      expect(result!.playoffStats, isNotNull);
      expect(result.playoffStats!.isEmpty, true);
    });
  });
}
