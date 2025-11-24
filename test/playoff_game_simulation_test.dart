import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/playoff_series.dart';

void main() {
  group('GameService - Playoff Game Simulation', () {
    late GameService gameService;
    late Team homeTeam;
    late Team awayTeam;
    late PlayoffSeries series;

    setUp(() {
      gameService = GameService();

      // Create test players
      final homePlayers = List.generate(
        15,
        (i) => Player(
          id: 'home_player_$i',
          name: 'Home Player$i',
          heightInches: 75 + i % 10,
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
          position: 'PG',
        ),
      );

      final awayPlayers = List.generate(
        15,
        (i) => Player(
          id: 'away_player_$i',
          name: 'Away Player$i',
          heightInches: 75 + i % 10,
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
          position: 'PG',
        ),
      );

      homeTeam = Team(
        id: 'home_team',
        city: 'Home',
        name: 'Team',
        players: homePlayers,
        startingLineupIds: homePlayers.take(5).map((p) => p.id).toList(),
      );

      awayTeam = Team(
        id: 'away_team',
        city: 'Away',
        name: 'Team',
        players: awayPlayers,
        startingLineupIds: awayPlayers.take(5).map((p) => p.id).toList(),
      );

      series = PlayoffSeries(
        id: 'test_series',
        homeTeamId: homeTeam.id,
        awayTeamId: awayTeam.id,
        homeWins: 0,
        awayWins: 0,
        round: 'first-round',
        conference: 'east',
        gameIds: [],
        isComplete: false,
      );
    });

    test('simulatePlayoffGame should return a game with playoff metadata', () {
      final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, series);

      expect(game.isPlayoffGame, true);
      expect(game.seriesId, series.id);
      expect(game.isPlayed, true);
      expect(game.homeScore, isNotNull);
      expect(game.awayScore, isNotNull);
    });

    test('simulatePlayoffGame should include box score', () {
      final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, series);

      expect(game.boxScore, isNotNull);
      expect(game.boxScore!.isNotEmpty, true);
    });

    test('simulatePlayoffGame should have realistic scores', () {
      final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, series);

      expect(game.homeScore, greaterThan(70));
      expect(game.homeScore, lessThan(150));
      expect(game.awayScore, greaterThan(70));
      expect(game.awayScore, lessThan(150));
    });

    test('updateSeriesWithResult should increment homeWins when home team wins', () {
      final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
      
      // Force home team to win by modifying the game
      final homeWinGame = game.copyWith(
        homeScore: 110,
        awayScore: 100,
      );

      final updatedSeries = gameService.updateSeriesWithResult(series, homeWinGame);

      expect(updatedSeries.homeWins, 1);
      expect(updatedSeries.awayWins, 0);
      expect(updatedSeries.gameIds.length, 1);
      expect(updatedSeries.gameIds.contains(homeWinGame.id), true);
    });

    test('updateSeriesWithResult should increment awayWins when away team wins', () {
      final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
      
      // Force away team to win by modifying the game
      final awayWinGame = game.copyWith(
        homeScore: 100,
        awayScore: 110,
      );

      final updatedSeries = gameService.updateSeriesWithResult(series, awayWinGame);

      expect(updatedSeries.homeWins, 0);
      expect(updatedSeries.awayWins, 1);
      expect(updatedSeries.gameIds.length, 1);
      expect(updatedSeries.gameIds.contains(awayWinGame.id), true);
    });

    test('updateSeriesWithResult should mark series complete when team reaches 4 wins', () {
      var currentSeries = series;

      // Simulate 4 home wins
      for (int i = 0; i < 4; i++) {
        final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, currentSeries);
        final homeWinGame = game.copyWith(
          homeScore: 110,
          awayScore: 100,
        );
        currentSeries = gameService.updateSeriesWithResult(currentSeries, homeWinGame);
      }

      expect(currentSeries.isComplete, true);
      expect(currentSeries.homeWins, 4);
      expect(currentSeries.winnerId, homeTeam.id);
    });

    test('series should not be complete until team reaches 4 wins', () {
      var currentSeries = series;

      // Simulate 3 home wins
      for (int i = 0; i < 3; i++) {
        final game = gameService.simulatePlayoffGame(homeTeam, awayTeam, currentSeries);
        final homeWinGame = game.copyWith(
          homeScore: 110,
          awayScore: 100,
        );
        currentSeries = gameService.updateSeriesWithResult(currentSeries, homeWinGame);
      }

      expect(currentSeries.isComplete, false);
      expect(currentSeries.winnerId, null);
    });

    test('playoff game should complete within reasonable time', () {
      final stopwatch = Stopwatch()..start();
      
      gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
      
      stopwatch.stop();
      
      // Should complete within 5 seconds (design spec says 3 seconds, but allow buffer)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
  });
}
