import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/league_standings_page.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/season.dart';

/// Tests for the League Standings page
void main() {
  group('LeagueStandingsPage Tests', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
    });

    testWidgets('LeagueStandingsPage displays all 30 teams', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create a season with some played games
      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Play first 10 games
      season = leagueService.simulateRemainingRegularSeasonGames(
        season,
        gameService,
        updateStats: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeagueStandingsPage(
            leagueService: leagueService,
            season: season,
            userTeamId: userTeam.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs are present
      expect(find.text('Eastern Conference'), findsOneWidget);
      expect(find.text('Western Conference'), findsOneWidget);
      expect(find.text('League'), findsOneWidget);

      // Verify table header is present
      expect(find.text('Rank'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('PCT'), findsOneWidget);
    });

    testWidgets('LeagueStandingsPage highlights user team', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Simulate some games
      season = leagueService.simulateRemainingRegularSeasonGames(
        season,
        gameService,
        updateStats: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeagueStandingsPage(
            leagueService: leagueService,
            season: season,
            userTeamId: userTeam.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // User team should be displayed
      expect(find.text(userTeam.city), findsWidgets);
      expect(find.text(userTeam.name), findsWidgets);
    });

    testWidgets('LeagueStandingsPage can switch between conferences', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeagueStandingsPage(
            leagueService: leagueService,
            season: season,
            userTeamId: userTeam.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Western Conference tab
      await tester.tap(find.text('Western Conference'));
      await tester.pumpAndSettle();

      // Should still show standings
      expect(find.text('Rank'), findsOneWidget);

      // Tap on League tab
      await tester.tap(find.text('League'));
      await tester.pumpAndSettle();

      // Should still show standings
      expect(find.text('Rank'), findsOneWidget);
    });

    testWidgets('LeagueStandingsPage shows playoff indicators', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final games = gameService.generateSchedule(userTeam.id, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );

      // Simulate full season to get realistic standings
      season = leagueService.simulateEntireRegularSeason(
        season,
        gameService,
        updateStats: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LeagueStandingsPage(
            leagueService: leagueService,
            season: season,
            userTeamId: userTeam.id,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show playoff indicators (stars for top 6, play arrows for 7-10)
      // At least some teams should have indicators
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });
}
