import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/services/game_service.dart';

void main() {
  group('Season Model Tests', () {
    test('Season tracks games played correctly', () {
      final games = List.generate(
        82,
        (index) => Game(
          id: 'game-$index',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: null,
          awayScore: null,
          isPlayed: index < 10, // First 10 games played
          scheduledDate: DateTime.now().add(Duration(days: index)),
        ),
      );

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
      );

      expect(season.gamesPlayed, 10);
      expect(season.gamesRemaining, 72);
      expect(season.isComplete, false);
    });

    test('Season calculates wins and losses correctly', () {
      final games = [
        // Win as home team
        Game(
          id: 'game-1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
        // Loss as away team
        Game(
          id: 'game-2',
          homeTeamId: 'team-2',
          awayTeamId: 'team-1',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
        // Win as away team
        Game(
          id: 'game-3',
          homeTeamId: 'team-2',
          awayTeamId: 'team-1',
          homeScore: 85,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
        // Unplayed game
        ...List.generate(
          79,
          (index) => Game(
            id: 'game-${index + 4}',
            homeTeamId: 'team-1',
            awayTeamId: 'team-2',
            homeScore: null,
            awayScore: null,
            isPlayed: false,
            scheduledDate: DateTime.now(),
          ),
        ),
      ];

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
      );

      expect(season.wins, 2);
      expect(season.losses, 1);
      expect(season.gamesPlayed, 3);
    });

    test('Season identifies next unplayed game', () {
      final games = [
        Game(
          id: 'game-1',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
        Game(
          id: 'game-2',
          homeTeamId: 'team-1',
          awayTeamId: 'team-3',
          homeScore: null,
          awayScore: null,
          isPlayed: false,
          scheduledDate: DateTime.now(),
        ),
        ...List.generate(
          80,
          (index) => Game(
            id: 'game-${index + 3}',
            homeTeamId: 'team-1',
            awayTeamId: 'team-2',
            homeScore: null,
            awayScore: null,
            isPlayed: false,
            scheduledDate: DateTime.now(),
          ),
        ),
      ];

      final season = Season(
        id: 'season-1',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
      );

      final nextGame = season.nextGame;
      expect(nextGame, isNotNull);
      expect(nextGame!.id, 'game-2');
      expect(nextGame.isPlayed, false);
    });

    test('Season completion is detected correctly', () {
      final games = List.generate(
        82,
        (index) => Game(
          id: 'game-$index',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
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
        userTeamId: 'team-1',
      );

      expect(season.isComplete, true);
      expect(season.gamesPlayed, 82);
      expect(season.gamesRemaining, 0);
      expect(season.nextGame, isNull);
    });
  });

  group('GameService Schedule Generation Tests', () {
    test('GameService generates 82-game schedule', () {
      final gameService = GameService();
      
      // Create dummy teams
      final teams = List.generate(
        30,
        (index) => Team(
          id: 'team-$index',
          name: 'Team $index',
          city: 'City $index',
          players: List.generate(
            15,
            (pIndex) => Player(
              id: 'player-$index-$pIndex',
              name: 'Player $pIndex',
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
              position: 'SF',
            ),
          ),
          startingLineupIds: List.generate(5, (i) => 'player-$index-$i'),
        ),
      );

      final schedule = gameService.generateSchedule('team-0', teams);

      expect(schedule.length, 82);
      
      // Verify all games involve the user's team
      for (final game in schedule) {
        expect(
          game.homeTeamId == 'team-0' || game.awayTeamId == 'team-0',
          true,
        );
        expect(game.isPlayed, false);
        expect(game.homeScore, isNull);
        expect(game.awayScore, isNull);
      }
    });
  });
}
