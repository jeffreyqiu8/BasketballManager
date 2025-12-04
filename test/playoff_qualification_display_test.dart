import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/views/home_page.dart';
import '../lib/models/season.dart';
import '../lib/models/game.dart';
import '../lib/models/playoff_bracket.dart';
import '../lib/services/league_service.dart';

/// Test to verify that playoff qualification is displayed correctly
void main() {
  group('Playoff Qualification Display', () {
    late LeagueService leagueService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
    });

    testWidgets('Shows "Made Playoffs" for seed 6 team', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create a season with 82 completed games
      final games = List.generate(82, (i) => Game(
        id: 'game-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: 100,
        awayScore: 90,
        isPlayed: true,
        scheduledDate: DateTime.now().subtract(Duration(days: 82 - i)),
      ));
      
      var season = Season(
        id: 'test-season',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );
      
      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      // Create playoff bracket with user team as seed 6 (should make playoffs)
      final seedings = <String, int>{};
      final conferences = <String, String>{};
      
      for (int i = 0; i < teams.length; i++) {
        seedings[teams[i].id] = i + 1; // User team gets seed 1
        conferences[teams[i].id] = i < 15 ? 'east' : 'west';
      }
      
      // Set user team to seed 6
      seedings[userTeam.id] = 6;
      conferences[userTeam.id] = 'east';
      
      final bracket = PlayoffBracket(
        seasonId: season.id,
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );
      
      season = season.startPostSeason(bracket);
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeam.id,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should NOT show "Missed Playoffs"
      expect(find.text('Missed Playoffs'), findsNothing);
      
      // Should show playoff bracket button
      expect(find.text('View Playoff Bracket'), findsOneWidget);
    });

    testWidgets('Shows "Missed Playoffs" for seed 11 team', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create a season with 82 completed games
      final games = List.generate(82, (i) => Game(
        id: 'game-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: 90,
        awayScore: 100,
        isPlayed: true,
        scheduledDate: DateTime.now().subtract(Duration(days: 82 - i)),
      ));
      
      var season = Season(
        id: 'test-season',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );
      
      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      // Create playoff bracket with user team as seed 11 (missed playoffs)
      final seedings = <String, int>{};
      final conferences = <String, String>{};
      
      for (int i = 0; i < teams.length; i++) {
        seedings[teams[i].id] = i + 1;
        conferences[teams[i].id] = i < 15 ? 'east' : 'west';
      }
      
      // Set user team to seed 11 (missed playoffs)
      seedings[userTeam.id] = 11;
      conferences[userTeam.id] = 'east';
      
      final bracket = PlayoffBracket(
        seasonId: season.id,
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );
      
      season = season.startPostSeason(bracket);
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeam.id,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should show "Missed Playoffs"
      expect(find.text('Missed Playoffs'), findsOneWidget);
      expect(find.text('Your team did not qualify for the playoffs this season'), findsOneWidget);
    });

    testWidgets('Shows correct status for seed 10 team (play-in)', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create a season with 82 completed games
      final games = List.generate(82, (i) => Game(
        id: 'game-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: 95,
        awayScore: 93,
        isPlayed: true,
        scheduledDate: DateTime.now().subtract(Duration(days: 82 - i)),
      ));
      
      var season = Season(
        id: 'test-season',
        year: 2024,
        games: games,
        userTeamId: userTeam.id,
      );
      
      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      // Create playoff bracket with user team as seed 10 (play-in)
      final seedings = <String, int>{};
      final conferences = <String, String>{};
      
      for (int i = 0; i < teams.length; i++) {
        seedings[teams[i].id] = i + 1;
        conferences[teams[i].id] = i < 15 ? 'east' : 'west';
      }
      
      // Set user team to seed 10 (play-in tournament)
      seedings[userTeam.id] = 10;
      conferences[userTeam.id] = 'east';
      
      final bracket = PlayoffBracket(
        seasonId: season.id,
        teamSeedings: seedings,
        teamConferences: conferences,
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );
      
      season = season.startPostSeason(bracket);
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeam.id,
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should NOT show "Missed Playoffs" - seed 10 makes play-in
      expect(find.text('Missed Playoffs'), findsNothing);
    });
  });
}
