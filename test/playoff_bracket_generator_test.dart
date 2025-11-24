import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/utils/playoff_bracket_generator.dart';

void main() {
  group('PlayoffBracketGenerator', () {
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

    test('should generate exactly 4 play-in games', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      expect(playInGames.length, 4);
    });

    test('should create 2 play-in games for Eastern Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final eastGames = playInGames.where((g) => g.conference == 'east').toList();
      expect(eastGames.length, 2);
    });

    test('should create 2 play-in games for Western Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final westGames = playInGames.where((g) => g.conference == 'west').toList();
      expect(westGames.length, 2);
    });

    test('should create 7 vs 8 seed matchup for Eastern Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final eastGames = playInGames.where((g) => g.conference == 'east').toList();
      
      // Find the 7 vs 8 game
      final game78 = eastGames.firstWhere((g) =>
        (g.homeTeamId == 'east_team_7' && g.awayTeamId == 'east_team_8') ||
        (g.homeTeamId == 'east_team_8' && g.awayTeamId == 'east_team_7'));

      expect(game78, isNotNull);
      expect(game78.round, 'play-in');
    });

    test('should create 9 vs 10 seed matchup for Eastern Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final eastGames = playInGames.where((g) => g.conference == 'east').toList();
      
      // Find the 9 vs 10 game
      final game910 = eastGames.firstWhere((g) =>
        (g.homeTeamId == 'east_team_9' && g.awayTeamId == 'east_team_10') ||
        (g.homeTeamId == 'east_team_10' && g.awayTeamId == 'east_team_9'));

      expect(game910, isNotNull);
      expect(game910.round, 'play-in');
    });

    test('should create 7 vs 8 seed matchup for Western Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final westGames = playInGames.where((g) => g.conference == 'west').toList();
      
      // Find the 7 vs 8 game
      final game78 = westGames.firstWhere((g) =>
        (g.homeTeamId == 'west_team_7' && g.awayTeamId == 'west_team_8') ||
        (g.homeTeamId == 'west_team_8' && g.awayTeamId == 'west_team_7'));

      expect(game78, isNotNull);
      expect(game78.round, 'play-in');
    });

    test('should create 9 vs 10 seed matchup for Western Conference', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final westGames = playInGames.where((g) => g.conference == 'west').toList();
      
      // Find the 9 vs 10 game
      final game910 = westGames.firstWhere((g) =>
        (g.homeTeamId == 'west_team_9' && g.awayTeamId == 'west_team_10') ||
        (g.homeTeamId == 'west_team_10' && g.awayTeamId == 'west_team_9'));

      expect(game910, isNotNull);
      expect(game910.round, 'play-in');
    });

    test('should initialize all series with 0 wins', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      for (var series in playInGames) {
        expect(series.homeWins, 0);
        expect(series.awayWins, 0);
        expect(series.isComplete, false);
      }
    });

    test('should initialize all series with empty game IDs', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      for (var series in playInGames) {
        expect(series.gameIds, isEmpty);
      }
    });

    test('should assign unique IDs to each series', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      final ids = playInGames.map((s) => s.id).toSet();
      expect(ids.length, 4); // All IDs should be unique
    });

    test('should set round to "play-in" for all series', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      for (var series in playInGames) {
        expect(series.round, 'play-in');
      }
    });

    test('should handle missing seeds gracefully', () {
      // Remove some seeds to test error handling
      final incompleteSeedings = <String, int>{
        'east_team_7': 7,
        'east_team_8': 8,
        // Missing 9 and 10 for east
        'west_team_7': 7,
        'west_team_8': 8,
        'west_team_9': 9,
        'west_team_10': 10,
      };

      final incompleteConferences = <String, String>{
        'east_team_7': 'east',
        'east_team_8': 'east',
        'west_team_7': 'west',
        'west_team_8': 'west',
        'west_team_9': 'west',
        'west_team_10': 'west',
      };

      // This should throw an error or handle gracefully
      expect(
        () => PlayoffBracketGenerator.generatePlayInGames(
          incompleteSeedings,
          incompleteConferences,
        ),
        throwsA(anything),
      );
    });

    test('should correctly match teams from seedings map', () {
      final playInGames = PlayoffBracketGenerator.generatePlayInGames(
        seedings,
        conferences,
      );

      // Verify all teams in play-in games are from seeds 7-10
      for (var series in playInGames) {
        final homeSeed = seedings[series.homeTeamId];
        final awaySeed = seedings[series.awayTeamId];

        expect(homeSeed, greaterThanOrEqualTo(7));
        expect(homeSeed, lessThanOrEqualTo(10));
        expect(awaySeed, greaterThanOrEqualTo(7));
        expect(awaySeed, lessThanOrEqualTo(10));
      }
    });
  });
}
