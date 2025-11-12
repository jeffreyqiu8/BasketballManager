import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BasketballManager/models/game_state.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/player_game_stats.dart';
import 'package:BasketballManager/models/player_season_stats.dart';
import 'package:BasketballManager/services/save_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/services/league_service.dart';

/// Comprehensive end-to-end integration tests for advanced basketball features
/// 
/// Tests cover:
/// - Complete flow: create save with team selection → play game → view box score → view season stats
/// - Statistics persistence across save/load cycles
/// - Multiple games accumulating season stats correctly
/// - Backward compatibility with existing saves
/// - Performance requirements (simulation < 3 seconds)
/// - Error handling for edge cases
void main() {
  group('End-to-End Integration Tests', () {
    late SaveService saveService;
    late GameService gameService;
    late LeagueService leagueService;

    setUp(() async {
      saveService = SaveService();
      gameService = GameService();
      leagueService = LeagueService();
      SharedPreferences.setMockInitialValues({});
      
      // Initialize league with 30 teams
      await leagueService.initializeLeague();
    });

    test('Complete flow: create save → play game → verify box score → verify season stats', () async {
      // Step 1: Create save with team selection
      final teams = leagueService.getAllTeams();
      expect(teams.length, 30, reason: 'League should have 30 teams');
      
      final selectedTeam = teams.first;
      final userTeamId = selectedTeam.id;
      
      // Generate 82-game schedule
      final schedule = gameService.generateSchedule(userTeamId, teams);
      expect(schedule.length, 82, reason: 'Season should have 82 games');
      
      final season = Season(
        id: 'season-1',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
      );
      
      final gameState = GameState(
        teams: teams,
        currentSeason: season,
        userTeamId: userTeamId,
      );
      
      // Save the game
      final saveResult = await saveService.saveGame('test_e2e', gameState);
      expect(saveResult, true, reason: 'Save should succeed');
      
      // Step 2: Load the save
      var loadedState = await saveService.loadGame('test_e2e');
      expect(loadedState, isNotNull, reason: 'Save should load successfully');
      expect(loadedState!.userTeamId, userTeamId, reason: 'User team ID should match');
      
      // Step 3: Play a game with detailed simulation
      final nextGame = loadedState.currentSeason.nextGame;
      expect(nextGame, isNotNull, reason: 'Should have next game to play');
      
      final homeTeam = teams.firstWhere((t) => t.id == nextGame!.homeTeamId);
      final awayTeam = teams.firstWhere((t) => t.id == nextGame!.awayTeamId);
      
      // Simulate game and measure performance
      final stopwatch = Stopwatch()..start();
      final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
      stopwatch.stop();
      
      // Verify performance requirement (< 3 seconds)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000),
        reason: 'Simulation should complete within 3 seconds',
      );
      
      // Step 4: Verify box score exists and is valid
      expect(simulatedGame.boxScore, isNotNull, reason: 'Box score should exist');
      expect(simulatedGame.boxScore!.isNotEmpty, true, reason: 'Box score should have player stats');
      
      // Verify box score contains valid statistics
      for (var entry in simulatedGame.boxScore!.entries) {
        final stats = entry.value;
        expect(stats.points, greaterThanOrEqualTo(0), reason: 'Points should be non-negative');
        expect(stats.rebounds, greaterThanOrEqualTo(0), reason: 'Rebounds should be non-negative');
        expect(stats.assists, greaterThanOrEqualTo(0), reason: 'Assists should be non-negative');
        expect(stats.fieldGoalsAttempted, greaterThanOrEqualTo(0));
        expect(stats.threePointersAttempted, greaterThanOrEqualTo(0));
      }
      
      // Step 5: Update season with game results
      final updatedGames = List<Game>.from(loadedState.currentSeason.games);
      final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame!.id);
      updatedGames[gameIndex] = simulatedGame;
      
      var updatedSeason = loadedState.currentSeason.copyWith(games: updatedGames);
      
      // Update season stats
      updatedSeason = updatedSeason.updateSeasonStats(simulatedGame.boxScore!);
      
      // Step 6: Verify season stats were created
      expect(updatedSeason.seasonStats, isNotNull, reason: 'Season stats should exist');
      expect(updatedSeason.seasonStats!.isNotEmpty, true, reason: 'Season stats should have player data');
      
      // Verify season stats contain valid data
      for (var entry in updatedSeason.seasonStats!.entries) {
        final seasonStats = entry.value;
        expect(seasonStats.gamesPlayed, 1, reason: 'Player should have 1 game played');
        expect(seasonStats.totalPoints, greaterThanOrEqualTo(0));
        expect(seasonStats.pointsPerGame, greaterThanOrEqualTo(0));
      }
      
      // Step 7: Save updated game state
      final updatedGameState = GameState(
        teams: loadedState.teams,
        currentSeason: updatedSeason,
        userTeamId: loadedState.userTeamId,
      );
      
      final updateResult = await saveService.saveGame('test_e2e', updatedGameState);
      expect(updateResult, true, reason: 'Updated save should succeed');
      
      // Step 8: Reload and verify persistence
      loadedState = await saveService.loadGame('test_e2e');
      expect(loadedState, isNotNull, reason: 'Reloaded save should exist');
      expect(loadedState!.currentSeason.gamesPlayed, 1, reason: 'Should have 1 game played');
      expect(loadedState.currentSeason.seasonStats, isNotNull, reason: 'Season stats should persist');
      expect(
        loadedState.currentSeason.seasonStats!.isNotEmpty,
        true,
        reason: 'Season stats should persist with data',
      );
    });

    test('Multiple games accumulate season stats correctly', () async {
      // Create initial game state
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      final schedule = gameService.generateSchedule(userTeamId, teams);
      
      var season = Season(
        id: 'season-multi',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
      );
      
      // Play 5 games and accumulate stats
      for (int i = 0; i < 5; i++) {
        final nextGame = season.nextGame;
        expect(nextGame, isNotNull, reason: 'Should have next game');
        
        final homeTeam = teams.firstWhere((t) => t.id == nextGame!.homeTeamId);
        final awayTeam = teams.firstWhere((t) => t.id == nextGame!.awayTeamId);
        
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        
        // Update games list
        final updatedGames = List<Game>.from(season.games);
        final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame!.id);
        updatedGames[gameIndex] = simulatedGame;
        
        // Update season with new game
        season = season.copyWith(games: updatedGames);
        season = season.updateSeasonStats(simulatedGame.boxScore!);
      }
      
      // Verify 5 games were played
      expect(season.gamesPlayed, 5, reason: 'Should have 5 games played');
      
      // Verify season stats accumulated correctly
      expect(season.seasonStats, isNotNull);
      expect(season.seasonStats!.isNotEmpty, true);
      
      // Check that players have accumulated stats from multiple games
      for (var entry in season.seasonStats!.entries) {
        final seasonStats = entry.value;
        expect(
          seasonStats.gamesPlayed,
          greaterThan(0),
          reason: 'Players should have games played',
        );
        expect(
          seasonStats.gamesPlayed,
          lessThanOrEqualTo(5),
          reason: 'Players should not have more than 5 games',
        );
      }
    });

    test('Backward compatibility: old saves without stats load correctly', () async {
      // Create a save without box scores or season stats (simulating old save format)
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      
      // Create games without box scores
      final games = List.generate(
        82,
        (index) => Game(
          id: 'game-$index',
          homeTeamId: userTeamId,
          awayTeamId: teams[1].id,
          homeScore: index < 5 ? 100 : null,
          awayScore: index < 5 ? 95 : null,
          isPlayed: index < 5,
          scheduledDate: DateTime.now().add(Duration(days: index)),
          boxScore: null, // Old format - no box score
        ),
      );
      
      // Create season without season stats
      final season = Season(
        id: 'season-old',
        year: 2024,
        games: games,
        userTeamId: userTeamId,
        seasonStats: null, // Old format - no season stats
      );
      
      final gameState = GameState(
        teams: teams,
        currentSeason: season,
        userTeamId: userTeamId,
      );
      
      // Save old format
      final saveResult = await saveService.saveGame('old_format', gameState);
      expect(saveResult, true, reason: 'Old format save should succeed');
      
      // Load old format
      final loadedState = await saveService.loadGame('old_format');
      expect(loadedState, isNotNull, reason: 'Old format should load');
      expect(loadedState!.currentSeason.gamesPlayed, 5, reason: 'Games played should be correct');
      expect(loadedState.currentSeason.seasonStats, isNull, reason: 'Old saves have no season stats');
      
      // Verify we can play new games with the old save
      final nextGame = loadedState.currentSeason.nextGame;
      expect(nextGame, isNotNull);
      
      final homeTeam = teams.firstWhere((t) => t.id == nextGame!.homeTeamId);
      final awayTeam = teams.firstWhere((t) => t.id == nextGame!.awayTeamId);
      
      final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
      expect(simulatedGame.boxScore, isNotNull, reason: 'New games should have box scores');
      
      // Update season with new game
      final updatedGames = List<Game>.from(loadedState.currentSeason.games);
      final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame!.id);
      updatedGames[gameIndex] = simulatedGame;
      
      var updatedSeason = loadedState.currentSeason.copyWith(games: updatedGames);
      updatedSeason = updatedSeason.updateSeasonStats(simulatedGame.boxScore!);
      
      // Verify season stats were created from scratch
      expect(updatedSeason.seasonStats, isNotNull, reason: 'Season stats should be created');
      expect(updatedSeason.seasonStats!.isNotEmpty, true);
    });

    test('Performance: simulation completes within 3 seconds', () async {
      final teams = leagueService.getAllTeams();
      final homeTeam = teams[0];
      final awayTeam = teams[1];
      
      // Run 10 simulations to ensure consistent performance
      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();
        final game = gameService.simulateGameDetailed(homeTeam, awayTeam);
        stopwatch.stop();
        
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(3000),
          reason: 'Simulation $i should complete within 3 seconds',
        );
        
        expect(game.boxScore, isNotNull);
        expect(game.isPlayed, true);
        expect(game.homeScore, greaterThan(0));
        expect(game.awayScore, greaterThan(0));
      }
    });

    test('Error handling: low attribute players handled gracefully', () async {
      // Create a team with players with low (but not zero) attributes
      final lowAttributePlayer = Player(
        id: 'low-player',
        name: 'Low Attribute Player',
        heightInches: 72,
        shooting: 10, // Low but not zero
        defense: 10,
        speed: 10,
        stamina: 10,
        passing: 10,
        rebounding: 10,
        ballHandling: 10,
        threePoint: 10,
      );
      
      final validPlayer = Player(
        id: 'valid-player',
        name: 'Valid Player',
        heightInches: 75,
        shooting: 80,
        defense: 75,
        speed: 70,
        stamina: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
      );
      
      final players = [
        lowAttributePlayer,
        ...List.generate(4, (i) => validPlayer),
        ...List.generate(10, (i) => validPlayer),
      ];
      
      final team = Team(
        id: 'team-low-attr',
        name: 'Test Team',
        city: 'Test City',
        players: players,
        startingLineupIds: players.take(5).map((p) => p.id).toList(),
      );
      
      final teams = leagueService.getAllTeams();
      final normalTeam = teams.first;
      
      // Simulation should complete without errors
      expect(
        () => gameService.simulateGameDetailed(team, normalTeam),
        returnsNormally,
        reason: 'Simulation should handle low attribute player data',
      );
      
      final game = gameService.simulateGameDetailed(team, normalTeam);
      expect(game.boxScore, isNotNull);
      expect(game.isPlayed, true);
    });

    test('Error handling: missing season stats handled gracefully', () async {
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      final schedule = gameService.generateSchedule(userTeamId, teams);
      
      // Create season without stats
      var season = Season(
        id: 'season-no-stats',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
        seasonStats: null,
      );
      
      // Get player stats should return null
      final stats = season.getPlayerStats('any-player-id');
      expect(stats, isNull, reason: 'Should return null for missing stats');
      
      // Update stats should work even when starting from null
      final mockBoxScore = {
        'player-1': PlayerGameStats(
          playerId: 'player-1',
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
      
      season = season.updateSeasonStats(mockBoxScore);
      expect(season.seasonStats, isNotNull);
      expect(season.seasonStats!.containsKey('player-1'), true);
      
      final playerStats = season.getPlayerStats('player-1');
      expect(playerStats, isNotNull);
      expect(playerStats!.totalPoints, 20);
      expect(playerStats.gamesPlayed, 1);
    });

    test('Statistics accuracy: box score totals match game score', () async {
      final teams = leagueService.getAllTeams();
      final homeTeam = teams[0];
      final awayTeam = teams[1];
      
      final game = gameService.simulateGameDetailed(homeTeam, awayTeam);
      
      // Calculate total points from box score
      int homeBoxScorePoints = 0;
      int awayBoxScorePoints = 0;
      
      for (var entry in game.boxScore!.entries) {
        final playerId = entry.key;
        final stats = entry.value;
        
        // Determine if player is on home or away team
        if (homeTeam.players.any((p) => p.id == playerId)) {
          homeBoxScorePoints += stats.points;
        } else if (awayTeam.players.any((p) => p.id == playerId)) {
          awayBoxScorePoints += stats.points;
        }
      }
      
      // Box score totals should match game scores
      expect(
        homeBoxScorePoints,
        game.homeScore,
        reason: 'Home team box score should match game score',
      );
      expect(
        awayBoxScorePoints,
        game.awayScore,
        reason: 'Away team box score should match game score',
      );
    });

    test('Season stats: per-game averages calculated correctly', () async {
      // Create mock game stats for 3 games
      final playerId = 'test-player';
      
      var seasonStats = PlayerSeasonStats.empty(playerId);
      
      // Game 1: 20 points, 5 rebounds, 3 assists
      seasonStats = seasonStats.addGameStats(PlayerGameStats(
        playerId: playerId,
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
      ));
      
      // Game 2: 15 points, 8 rebounds, 5 assists
      seasonStats = seasonStats.addGameStats(PlayerGameStats(
        playerId: playerId,
        points: 15,
        rebounds: 8,
        assists: 5,
        fieldGoalsMade: 6,
        fieldGoalsAttempted: 12,
        threePointersMade: 1,
        threePointersAttempted: 3,
        turnovers: 1,
        steals: 2,
        blocks: 1,
        fouls: 3,
        freeThrowsMade: 2,
        freeThrowsAttempted: 3,
      ));
      
      // Game 3: 25 points, 7 rebounds, 7 assists
      seasonStats = seasonStats.addGameStats(PlayerGameStats(
        playerId: playerId,
        points: 25,
        rebounds: 7,
        assists: 7,
        fieldGoalsMade: 10,
        fieldGoalsAttempted: 18,
        threePointersMade: 3,
        threePointersAttempted: 7,
        turnovers: 3,
        steals: 0,
        blocks: 2,
        fouls: 1,
        freeThrowsMade: 2,
        freeThrowsAttempted: 2,
      ));
      
      // Verify totals
      expect(seasonStats.gamesPlayed, 3);
      expect(seasonStats.totalPoints, 60);
      expect(seasonStats.totalRebounds, 20);
      expect(seasonStats.totalAssists, 15);
      
      // Verify averages
      expect(seasonStats.pointsPerGame, closeTo(20.0, 0.01));
      expect(seasonStats.reboundsPerGame, closeTo(6.67, 0.01));
      expect(seasonStats.assistsPerGame, closeTo(5.0, 0.01));
      
      // Verify percentages (returned as percentages 0-100, not decimals)
      expect(seasonStats.fieldGoalPercentage, closeTo(53.33, 0.1)); // 24/45 = 53.33%
      expect(seasonStats.threePointPercentage, closeTo(40.0, 0.1)); // 6/15 = 40%
    });

    test('Save/load cycle: complex game state persists correctly', () async {
      // Create complex game state with multiple played games and stats
      final teams = leagueService.getAllTeams();
      final userTeamId = teams.first.id;
      final schedule = gameService.generateSchedule(userTeamId, teams);
      
      var season = Season(
        id: 'complex-season',
        year: 2024,
        games: schedule,
        userTeamId: userTeamId,
      );
      
      // Play 10 games
      for (int i = 0; i < 10; i++) {
        final nextGame = season.nextGame!;
        final homeTeam = teams.firstWhere((t) => t.id == nextGame.homeTeamId);
        final awayTeam = teams.firstWhere((t) => t.id == nextGame.awayTeamId);
        
        final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);
        
        final updatedGames = List<Game>.from(season.games);
        final gameIndex = updatedGames.indexWhere((g) => g.id == nextGame.id);
        updatedGames[gameIndex] = simulatedGame;
        
        season = season.copyWith(games: updatedGames);
        season = season.updateSeasonStats(simulatedGame.boxScore!);
      }
      
      final gameState = GameState(
        teams: teams,
        currentSeason: season,
        userTeamId: userTeamId,
      );
      
      // Save
      await saveService.saveGame('complex_state', gameState);
      
      // Load
      final loadedState = await saveService.loadGame('complex_state');
      
      // Verify everything persisted
      expect(loadedState, isNotNull);
      expect(loadedState!.currentSeason.gamesPlayed, 10);
      expect(loadedState.currentSeason.seasonStats, isNotNull);
      expect(loadedState.currentSeason.seasonStats!.isNotEmpty, true);
      
      // Verify specific game has box score
      final playedGame = loadedState.currentSeason.games.firstWhere((g) => g.isPlayed);
      expect(playedGame.boxScore, isNotNull);
      expect(playedGame.boxScore!.isNotEmpty, true);
      
      // Verify season stats have correct games played
      for (var entry in loadedState.currentSeason.seasonStats!.entries) {
        final stats = entry.value;
        expect(stats.gamesPlayed, greaterThan(0));
        expect(stats.gamesPlayed, lessThanOrEqualTo(10));
      }
    });
  });
}
