import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';

/// Tests for simulating entire regular seasons
void main() {
  group('Season Simulation Tests', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
    });

    test('simulateEntireRegularSeason simulates all 82 games', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create a season with 82 unplayed games
      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Verify all games are unplayed
      expect(season.gamesPlayed, 0);
      expect(season.gamesRemaining, 82);

      // Simulate the entire season
      season = leagueService.simulateEntireRegularSeason(season, gameService);

      // Verify all games are now played
      expect(season.gamesPlayed, 82);
      expect(season.gamesRemaining, 0);
      
      // Verify all games have scores
      for (var game in season.games) {
        expect(game.isPlayed, true);
        expect(game.homeScore, isNotNull);
        expect(game.awayScore, isNotNull);
        expect(game.homeScore, greaterThan(0));
        expect(game.awayScore, greaterThan(0));
      }
    });

    test('simulateEntireRegularSeason updates season statistics', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Simulate the entire season with stats
      season = leagueService.simulateEntireRegularSeason(
        season,
        gameService,
        updateStats: true,
      );

      // Verify season statistics were accumulated
      expect(season.seasonStats, isNotNull);
      expect(season.seasonStats!.isNotEmpty, true);
      
      // Verify players have stats
      for (var player in userTeam.players) {
        final stats = season.getPlayerStats(player.id);
        if (stats != null) {
          expect(stats.gamesPlayed, greaterThan(0));
          expect(stats.gamesPlayed, lessThanOrEqualTo(82));
        }
      }
    });


    test('simulateRemainingRegularSeasonGames only simulates unplayed games', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Play first 40 games manually
      final updatedGames = List<Game>.from(season.games);
      for (int i = 0; i < 40; i++) {
        final game = updatedGames[i];
        final homeTeam = leagueService.getTeam(game.homeTeamId)!;
        final awayTeam = leagueService.getTeam(game.awayTeamId)!;
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        updatedGames[i] = simulatedGame.copyWith(
          id: game.id,
          scheduledDate: game.scheduledDate,
        );
      }

      season = Season(
        id: season.id,
        year: season.year,
        games: updatedGames,
        userTeamId: season.userTeamId,
      );

      expect(season.gamesPlayed, 40);
      expect(season.gamesRemaining, 42);

      // Simulate remaining games
      season = leagueService.simulateRemainingRegularSeasonGames(season, gameService);

      // Verify all games are now played
      expect(season.gamesPlayed, 82);
      expect(season.gamesRemaining, 0);
    });

    test('simulateEntireRegularSeason throws error for post-season', () async {
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

      // Try to simulate regular season (should throw error)
      expect(
        () => leagueService.simulateEntireRegularSeason(season, gameService),
        throwsStateError,
      );
    });

    test('simulateEntireRegularSeason completes in reasonable time', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      final stopwatch = Stopwatch()..start();
      
      season = leagueService.simulateEntireRegularSeason(season, gameService);
      
      stopwatch.stop();

      // Should complete within 5 minutes (82 games * 3 seconds max = 246 seconds)
      // Allow extra buffer for overhead
      expect(stopwatch.elapsedMilliseconds, lessThan(300000)); // 5 minutes
      
      // Verify completion
      expect(season.gamesPlayed, 82);
    });

    test('simulateEntireRegularSeason produces realistic win-loss records', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Simulate the entire season
      season = leagueService.simulateEntireRegularSeason(season, gameService);

      // Verify win-loss record is realistic (between 0 and 82)
      expect(season.wins, greaterThanOrEqualTo(0));
      expect(season.wins, lessThanOrEqualTo(82));
      expect(season.losses, greaterThanOrEqualTo(0));
      expect(season.losses, lessThanOrEqualTo(82));
      expect(season.wins + season.losses, 82);
    });

    test('simulateRemainingRegularSeasonGames preserves existing game results', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Play first 10 games manually
      final updatedGames = List<Game>.from(season.games);
      final playedGameScores = <String, Map<String, int>>{};
      
      for (int i = 0; i < 10; i++) {
        final game = updatedGames[i];
        final homeTeam = leagueService.getTeam(game.homeTeamId)!;
        final awayTeam = leagueService.getTeam(game.awayTeamId)!;
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        updatedGames[i] = simulatedGame.copyWith(
          id: game.id,
          scheduledDate: game.scheduledDate,
        );
        
        // Store the scores
        playedGameScores[game.id] = {
          'home': simulatedGame.homeScore!,
          'away': simulatedGame.awayScore!,
        };
      }

      season = Season(
        id: season.id,
        year: season.year,
        games: updatedGames,
        userTeamId: season.userTeamId,
      );

      // Simulate remaining games
      season = leagueService.simulateRemainingRegularSeasonGames(season, gameService);

      // Verify the first 10 games still have the same scores
      for (int i = 0; i < 10; i++) {
        final game = season.games[i];
        final originalScores = playedGameScores[game.id]!;
        expect(game.homeScore, originalScores['home']);
        expect(game.awayScore, originalScores['away']);
      }
    });

    test('simulateEntireRegularSeason can be disabled for stats updates', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Simulate without updating stats
      season = leagueService.simulateEntireRegularSeason(
        season,
        gameService,
        updateStats: false,
      );

      // Verify all games are played
      expect(season.gamesPlayed, 82);
      
      // Verify stats were not accumulated (or are minimal)
      // Note: Some stats might still exist from initialization
      if (season.seasonStats != null) {
        // If stats exist, they should be minimal or empty
        expect(season.seasonStats!.isEmpty, true);
      }
    });
  });
}
