import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BasketballManager/models/game_state.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/services/save_service.dart';

void main() {
  group('SaveService', () {
    late SaveService saveService;

    setUp(() {
      saveService = SaveService();
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    test('should save and load game state successfully', () async {
      // Create test data
      final player = Player(
        id: 'player1',
        name: 'Test Player',
        heightInches: 72,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 70,
        steals: 75,
        position: 'PG',
      );

      final team = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: List.generate(15, (i) => player),
        startingLineupIds: List.generate(5, (i) => 'player1'),
      );

      final game = Game(
        id: 'game1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeScore: 100,
        awayScore: 95,
        isPlayed: true,
        scheduledDate: DateTime.now(),
      );

      final season = Season(
        id: 'season1',
        year: 2024,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final gameState = GameState(
        teams: [team],
        currentSeason: season,
        userTeamId: 'team1',
      );

      // Save the game
      final saveResult = await saveService.saveGame('test_save', gameState);
      expect(saveResult, true);

      // Load the game
      final loadedState = await saveService.loadGame('test_save');
      expect(loadedState, isNotNull);
      expect(loadedState!.userTeamId, 'team1');
      expect(loadedState.teams.length, 1);
      expect(loadedState.teams[0].name, 'Test Team');
      expect(loadedState.currentSeason.year, 2024);
      expect(loadedState.currentSeason.games.length, 82);
    });

    test('should list all saves', () async {
      // Create and save multiple games
      final player = Player(
        id: 'player1',
        name: 'Test Player',
        heightInches: 72,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 70,
        steals: 75,
        position: 'PG',
      );

      final team = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: List.generate(15, (i) => player),
        startingLineupIds: List.generate(5, (i) => 'player1'),
      );

      final game = Game(
        id: 'game1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        isPlayed: false,
        scheduledDate: DateTime.now(),
      );

      final season = Season(
        id: 'season1',
        year: 2024,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final gameState = GameState(
        teams: [team],
        currentSeason: season,
        userTeamId: 'team1',
      );

      await saveService.saveGame('save1', gameState);
      await saveService.saveGame('save2', gameState);
      await saveService.saveGame('save3', gameState);

      final saves = await saveService.listSaves();
      expect(saves.length, 3);
      expect(saves, contains('save1'));
      expect(saves, contains('save2'));
      expect(saves, contains('save3'));
    });

    test('should delete save successfully', () async {
      // Create and save a game
      final player = Player(
        id: 'player1',
        name: 'Test Player',
        heightInches: 72,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 70,
        steals: 75,
        position: 'PG',
      );

      final team = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: List.generate(15, (i) => player),
        startingLineupIds: List.generate(5, (i) => 'player1'),
      );

      final game = Game(
        id: 'game1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        isPlayed: false,
        scheduledDate: DateTime.now(),
      );

      final season = Season(
        id: 'season1',
        year: 2024,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final gameState = GameState(
        teams: [team],
        currentSeason: season,
        userTeamId: 'team1',
      );

      await saveService.saveGame('test_delete', gameState);

      // Verify save exists
      var saves = await saveService.listSaves();
      expect(saves, contains('test_delete'));

      // Delete the save
      final deleteResult = await saveService.deleteSave('test_delete');
      expect(deleteResult, true);

      // Verify save is gone
      saves = await saveService.listSaves();
      expect(saves, isNot(contains('test_delete')));

      // Try to load deleted save
      final loadedState = await saveService.loadGame('test_delete');
      expect(loadedState, isNull);
    });

    test('should return null when loading non-existent save', () async {
      final loadedState = await saveService.loadGame('non_existent');
      expect(loadedState, isNull);
    });

    test('should check if save exists', () async {
      final player = Player(
        id: 'player1',
        name: 'Test Player',
        heightInches: 72,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 70,
        steals: 75,
        position: 'PG',
      );

      final team = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: List.generate(15, (i) => player),
        startingLineupIds: List.generate(5, (i) => 'player1'),
      );

      final game = Game(
        id: 'game1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        isPlayed: false,
        scheduledDate: DateTime.now(),
      );

      final season = Season(
        id: 'season1',
        year: 2024,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final gameState = GameState(
        teams: [team],
        currentSeason: season,
        userTeamId: 'team1',
      );

      // Check non-existent save
      var exists = await saveService.saveExists('test_exists');
      expect(exists, false);

      // Save and check again
      await saveService.saveGame('test_exists', gameState);
      exists = await saveService.saveExists('test_exists');
      expect(exists, true);
    });

    test('should update existing save with new data', () async {
      // Create initial save
      final player = Player(
        id: 'player1',
        name: 'Test Player',
        heightInches: 72,
        shooting: 80,
        defense: 75,
        speed: 70,
        postShooting: 85,
        passing: 65,
        rebounding: 70,
        ballHandling: 75,
        threePoint: 80,
        blocks: 70,
        steals: 75,
        position: 'PG',
      );

      final team = Team(
        id: 'team1',
        name: 'Test Team',
        city: 'Test City',
        players: List.generate(15, (i) => player),
        startingLineupIds: List.generate(5, (i) => 'player1'),
      );

      final game = Game(
        id: 'game1',
        homeTeamId: 'team1',
        awayTeamId: 'team2',
        homeScore: 100,
        awayScore: 95,
        isPlayed: true,
        scheduledDate: DateTime.now(),
      );

      final season = Season(
        id: 'season1',
        year: 2024,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final gameState = GameState(
        teams: [team],
        currentSeason: season,
        userTeamId: 'team1',
      );

      // Save initial state
      await saveService.saveGame('test_update', gameState);

      // Load and verify initial state
      var loadedState = await saveService.loadGame('test_update');
      expect(loadedState, isNotNull);
      expect(loadedState!.currentSeason.year, 2024);

      // Create updated game state with different year
      final updatedSeason = Season(
        id: 'season2',
        year: 2025,
        games: List.generate(82, (i) => game),
        userTeamId: 'team1',
      );

      final updatedGameState = GameState(
        teams: [team],
        currentSeason: updatedSeason,
        userTeamId: 'team1',
      );

      // Update the save
      await saveService.saveGame('test_update', updatedGameState);

      // Load and verify updated state
      loadedState = await saveService.loadGame('test_update');
      expect(loadedState, isNotNull);
      expect(loadedState!.currentSeason.year, 2025);

      // Verify saves list still has only one entry
      final saves = await saveService.listSaves();
      expect(saves.where((s) => s == 'test_update').length, 1);
    });
  });
}
