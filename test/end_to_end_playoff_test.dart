import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/services/playoff_service.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';

/// End-to-end test for the complete post-season system
/// Validates Requirements: 21.1-21.5, 22.1-22.7, 23.1-23.5, 24.1-24.5, 25.1-25.5, 26.1-26.5, 27.1-27.5
void main() {
  group('Post-Season System End-to-End Tests', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
    });

    test('Complete regular season triggers post-season', () async {
      // Get all teams
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create a season with 82 completed games
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100 + (i % 20),
          awayScore: 90 + (i % 15),
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Verify regular season is complete
      expect(leagueService.isRegularSeasonComplete(season), true);

      // Trigger post-season
      final postSeasonSeason = leagueService.checkAndStartPostSeason(season);

      // Verify post-season was triggered
      expect(postSeasonSeason, isNotNull);
      expect(postSeasonSeason!.isPostSeason, true);
      expect(postSeasonSeason.playoffBracket, isNotNull);
      expect(postSeasonSeason.playoffBracket!.currentRound, 'play-in');
      expect(postSeasonSeason.playoffStats, isNotNull);
      expect(postSeasonSeason.playoffStats!.isEmpty, true);
    });

    test('Playoff seeding is correct based on regular season records', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create exactly 82 games for the user's team with varying results
      final games = List<Game>.generate(
        82,
        (i) {
          // User team wins most games (60 out of 82)
          final userWins = i < 60;
          return Game(
            id: 'game-$i',
            homeTeamId: userTeam.id,
            awayTeamId: teams[(i + 1) % teams.length].id,
            homeScore: userWins ? 100 : 90,
            awayScore: userWins ? 90 : 100,
            isPlayed: true,
            scheduledDate: DateTime.now().add(Duration(days: i)),
          );
        },
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Start post-season
      final postSeasonSeason = leagueService.checkAndStartPostSeason(season);
      expect(postSeasonSeason, isNotNull);

      final bracket = postSeasonSeason!.playoffBracket!;
      
      // Verify seedings were generated for all teams
      expect(bracket.teamSeedings.length, 30);
      
      // Verify each team has a seed between 1 and 15
      for (var seed in bracket.teamSeedings.values) {
        expect(seed, greaterThanOrEqualTo(1));
        expect(seed, lessThanOrEqualTo(15));
      }
      
      // Verify conferences were assigned
      expect(bracket.teamConferences.length, 30);
    });

    test('Play-in tournament games are generated correctly', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final postSeasonSeason = leagueService.checkAndStartPostSeason(season);
      expect(postSeasonSeason, isNotNull);

      final bracket = postSeasonSeason!.playoffBracket!;
      
      // Verify play-in games were generated (4 total: 2 per conference)
      expect(bracket.playInGames.length, 4);
      
      // Verify all play-in games are for the correct round
      for (var game in bracket.playInGames) {
        expect(game.round, 'play-in');
        expect(game.isComplete, false);
        expect(game.homeWins, 0);
        expect(game.awayWins, 0);
      }
      
      // Verify 2 games per conference
      final eastGames = bracket.playInGames.where((g) => g.conference == 'east').length;
      final westGames = bracket.playInGames.where((g) => g.conference == 'west').length;
      expect(eastGames, 2);
      expect(westGames, 2);
    });

    test('Play through all playoff rounds and verify bracket progression', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create completed regular season
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      expect(season.playoffBracket!.currentRound, 'play-in');

      // Complete play-in games (need to complete all 3 games per conference)
      var bracket = season.playoffBracket!;
      
      // The play-in structure requires completing the initial 2 games per conference,
      // then generating and completing the second play-in game
      // For simplicity in this test, we'll use the PlayoffService to handle this
      
      // Simulate completing all play-in games by simulating games
      final completedPlayInGames = <PlayoffSeries>[];
      for (var game in bracket.playInGames) {
        var completedGame = game;
        for (int i = 0; i < 4; i++) {
          completedGame = completedGame.copyWithGameResult('g${game.id}_$i', game.homeTeamId);
        }
        completedPlayInGames.add(completedGame);
      }
      
      // Now we need to generate the second play-in games for each conference
      final eastGames = completedPlayInGames.where((g) => g.conference == 'east').toList();
      final westGames = completedPlayInGames.where((g) => g.conference == 'west').toList();
      
      // Generate second play-in game for East
      final eastSecondGame = PlayoffService.createSecondPlayInGame(
        eastGames[0], // 7v8 game
        eastGames[1], // 9v10 game
        'east',
      );
      var completedEastSecondGame = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecondGame = completedEastSecondGame.copyWithGameResult('g_east_2nd_$i', eastSecondGame.homeTeamId);
      }
      
      // Generate second play-in game for West
      final westSecondGame = PlayoffService.createSecondPlayInGame(
        westGames[0], // 7v8 game
        westGames[1], // 9v10 game
        'west',
      );
      var completedWestSecondGame = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecondGame = completedWestSecondGame.copyWithGameResult('g_west_2nd_$i', westSecondGame.homeTeamId);
      }
      
      completedPlayInGames.add(completedEastSecondGame);
      completedPlayInGames.add(completedWestSecondGame);
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedPlayInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to first round
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'first-round');
      expect(bracket.firstRound.length, 8); // 4 per conference

      // Complete first round
      final completedFirstRound = bracket.firstRound.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('g${series.id}_$i', series.homeTeamId);
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: completedFirstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to conference semifinals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'conf-semis');
      expect(bracket.conferenceSemis.length, 4); // 2 per conference

      // Complete conference semifinals
      final completedSemis = bracket.conferenceSemis.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('g${series.id}_$i', series.homeTeamId);
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: completedSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to conference finals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'conf-finals');
      expect(bracket.conferenceFinals.length, 2); // 1 per conference

      // Complete conference finals
      final completedFinals = bracket.conferenceFinals.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('g${series.id}_$i', series.homeTeamId);
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: completedFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to NBA Finals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'finals');
      expect(bracket.nbaFinals, isNotNull);

      // Complete NBA Finals
      var nbaFinals = bracket.nbaFinals!;
      for (int i = 0; i < 4; i++) {
        nbaFinals = nbaFinals.copyWithGameResult('g_finals_$i', nbaFinals.homeTeamId);
      }
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to complete
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'complete');
      expect(bracket.nbaFinals!.isComplete, true);
    });

    test('Best-of-seven series logic works correctly', () async {
      final teams = leagueService.getAllTeams();
      final team1 = teams[0];
      final team2 = teams[1];

      var series = PlayoffSeries(
        id: 'test-series',
        homeTeamId: team1.id,
        awayTeamId: team2.id,
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );

      // Simulate games until one team reaches 4 wins
      int gameCount = 0;
      while (!series.isComplete && gameCount < 7) {
        final winnerId = gameCount % 2 == 0 ? team1.id : team2.id;
        series = series.copyWithGameResult('game_$gameCount', winnerId);
        gameCount++;
      }

      // Verify series completed when team reached 4 wins
      expect(series.isComplete, true);
      expect(series.homeWins + series.awayWins, greaterThanOrEqualTo(4));
      expect(series.homeWins + series.awayWins, lessThanOrEqualTo(7));
      
      // Verify winner has exactly 4 wins
      if (series.winnerId == team1.id) {
        expect(series.homeWins, 4);
      } else {
        expect(series.awayWins, 4);
      }
    });

    test('Playoff statistics are tracked separately from regular season', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];
      final player = userTeam.players[0];

      // Create season with regular season games
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[1].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;

      // Simulate a playoff game and update stats
      final team2 = teams[1];
      final series = season.playoffBracket!.playInGames.first;
      
      // Create mock playoff game stats
      final playoffGameStats = {
        player.id: gameService.simulatePlayoffGame(userTeam, team2, series).boxScore![player.id]!,
      };

      // Update playoff stats
      season = season.updatePlayoffStats(playoffGameStats);

      // Verify playoff stats exist and are separate
      final playoffStats = season.getPlayerPlayoffStats(player.id);
      expect(playoffStats, isNotNull);
      expect(playoffStats!.gamesPlayed, 1);
      
      // Regular season stats should be null or different
      final regularStats = season.getPlayerStats(player.id);
      if (regularStats != null) {
        expect(regularStats.gamesPlayed, isNot(equals(playoffStats.gamesPlayed)));
      }
    });

    test('Non-user playoff games simulate correctly', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create completed regular season
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      var bracket = season.playoffBracket!;

      // Complete play-in games (need all 3 per conference)
      final completedPlayInGames = bracket.playInGames.map((game) {
        var completed = game;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('g${game.id}_$i', game.homeTeamId);
        }
        return completed;
      }).toList();
      
      // Generate second play-in games
      final eastGames = completedPlayInGames.where((g) => g.conference == 'east').toList();
      final westGames = completedPlayInGames.where((g) => g.conference == 'west').toList();
      
      final eastSecondGame = PlayoffService.createSecondPlayInGame(eastGames[0], eastGames[1], 'east');
      var completedEastSecondGame = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecondGame = completedEastSecondGame.copyWithGameResult('g_east_2nd_$i', eastSecondGame.homeTeamId);
      }
      
      final westSecondGame = PlayoffService.createSecondPlayInGame(westGames[0], westGames[1], 'west');
      var completedWestSecondGame = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecondGame = completedWestSecondGame.copyWithGameResult('g_west_2nd_$i', westSecondGame.homeTeamId);
      }
      
      completedPlayInGames.add(completedEastSecondGame);
      completedPlayInGames.add(completedWestSecondGame);
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedPlayInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      // Advance to first round
      bracket = PlayoffService.advancePlayoffRound(bracket);

      // Simulate non-user playoff games
      final result = PlayoffService.simulateNonUserPlayoffGames(
        bracket: bracket,
        userTeamId: userTeam.id,
        getTeam: (teamId) => teams.firstWhere((t) => t.id == teamId),
        simulateGame: (home, away, series) => gameService.simulatePlayoffGame(home, away, series),
      );

      // Verify non-user series were simulated
      expect(result.gameResults.isNotEmpty, true);
      
      // Verify user's series was not simulated (if they're in the playoffs)
      final userSeries = result.bracket.getUserTeamSeries(userTeam.id);
      if (userSeries != null) {
        expect(userSeries.isComplete, false);
      }
    });

    test('Playoff bracket displays correctly at all stages', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      var bracket = season.playoffBracket!;

      // Verify play-in stage
      expect(bracket.currentRound, 'play-in');
      expect(bracket.getCurrentRoundSeries().length, greaterThan(0));
      expect(bracket.isRoundComplete(), false);

      // Complete play-in and advance
      final completedPlayInGames = bracket.playInGames.map((game) {
        var completed = game;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('g${game.id}_$i', game.homeTeamId);
        }
        return completed;
      }).toList();
      
      // Generate second play-in games
      final eastGames = completedPlayInGames.where((g) => g.conference == 'east').toList();
      final westGames = completedPlayInGames.where((g) => g.conference == 'west').toList();
      
      final eastSecondGame = PlayoffService.createSecondPlayInGame(eastGames[0], eastGames[1], 'east');
      var completedEastSecondGame = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecondGame = completedEastSecondGame.copyWithGameResult('g_east_2nd_$i', eastSecondGame.homeTeamId);
      }
      
      final westSecondGame = PlayoffService.createSecondPlayInGame(westGames[0], westGames[1], 'west');
      var completedWestSecondGame = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecondGame = completedWestSecondGame.copyWithGameResult('g_west_2nd_$i', westSecondGame.homeTeamId);
      }
      
      completedPlayInGames.add(completedEastSecondGame);
      completedPlayInGames.add(completedWestSecondGame);
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedPlayInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );

      bracket = PlayoffService.advancePlayoffRound(bracket);

      // Verify first round stage
      expect(bracket.currentRound, 'first-round');
      expect(bracket.firstRound.length, 8);
      expect(bracket.getCurrentRoundSeries().length, 8);
    });

    test('Championship celebration when winning NBA Finals', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];
      final opponentTeam = teams[1];

      // Create completed regular season
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Create a completed NBA Finals where user won
      final nbaFinals = PlayoffSeries(
        id: 'finals',
        homeTeamId: userTeam.id,
        awayTeamId: opponentTeam.id,
        homeWins: 4,
        awayWins: 2,
        round: 'finals',
        conference: 'finals',
        gameIds: List.generate(6, (i) => 'finals_game_$i'),
        isComplete: true,
      );

      final bracket = PlayoffBracket(
        seasonId: season.id,
        teamSeedings: {userTeam.id: 1, opponentTeam.id: 2},
        teamConferences: {userTeam.id: 'east', opponentTeam.id: 'west'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: nbaFinals,
        currentRound: 'complete',
      );

      season = season.startPostSeason(bracket);

      // Complete playoffs
      season = season.completePlayoffs(userTeam.id, opponentTeam.id);

      // Verify championship record was created
      expect(season.championshipRecord, isNotNull);
      expect(season.championshipRecord!.championTeamId, userTeam.id);
      expect(season.championshipRecord!.runnerUpTeamId, opponentTeam.id);
      expect(season.championshipRecord!.year, 2024);
    });

    test('Backward compatibility with saves without playoff data', () async {
      // Create a season JSON without playoff fields (old save format)
      final json = {
        'id': 'season-2024',
        'year': 2024,
        'games': List.generate(82, (i) => {
          'id': 'game-$i',
          'homeTeamId': 'team1',
          'awayTeamId': 'team2',
          'homeScore': 100,
          'awayScore': 90,
          'isPlayed': true,
          'scheduledDate': DateTime.now().toIso8601String(),
        }),
        'userTeamId': 'team1',
        // No playoff fields
      };

      // Should load without error
      final season = Season.fromJson(json);

      // Verify defaults
      expect(season.isPostSeason, false);
      expect(season.playoffBracket, isNull);
      expect(season.playoffStats, isNull);
      expect(season.championshipRecord, isNull);
    });

    test('Starting new season after playoffs complete', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create a completed season with championship
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Complete playoffs
      final nbaFinals = PlayoffSeries(
        id: 'finals',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeWins: 4,
        awayWins: 2,
        round: 'finals',
        conference: 'finals',
        gameIds: [],
        isComplete: true,
      );

      final bracket = PlayoffBracket(
        seasonId: season.id,
        teamSeedings: {userTeam.id: 1},
        teamConferences: {userTeam.id: 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: nbaFinals,
        currentRound: 'complete',
      );

      season = season.startPostSeason(bracket);
      season = season.completePlayoffs(userTeam.id, teams[1].id);

      // Start new season (with 82 empty games)
      final newSeasonGames = List<Game>.generate(
        82,
        (i) => Game(
          id: 'new_game-$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: null,
          awayScore: null,
          isPlayed: false,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );
      
      final newSeason = Season(
        id: 'season-2025',
        year: 2025,
        games: newSeasonGames,
        userTeamId: userTeam.id,
      );

      // Verify new season is clean
      expect(newSeason.isPostSeason, false);
      expect(newSeason.playoffBracket, isNull);
      expect(newSeason.playoffStats, isNull);
      expect(newSeason.championshipRecord, isNull);
      expect(newSeason.year, 2025);
    });
  });
}
