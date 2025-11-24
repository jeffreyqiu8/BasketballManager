import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/views/home_page.dart';

void main() {
  group('HomePage Playoff Mode Tests', () {
    late LeagueService leagueService;
    late List<Game> games;
    late String userTeamId;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      
      final teams = leagueService.getAllTeams();
      userTeamId = teams[0].id;
      
      // Create 82 completed games
      games = List.generate(82, (index) {
        return Game(
          id: 'game-$index',
          homeTeamId: userTeamId,
          awayTeamId: teams[1].id,
          homeScore: 100,
          awayScore: 90,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: index)),
        );
      });
    });

    testWidgets('HomePage displays playoff status when in post-season', (WidgetTester tester) async {
      // Create a playoff bracket
      final playoffBracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {userTeamId: 1},
        teamConferences: {userTeamId: 'east'},
        playInGames: [],
        firstRound: [
          PlayoffSeries(
            id: 'series-1',
            homeTeamId: userTeamId,
            awayTeamId: leagueService.getAllTeams()[1].id,
            homeWins: 2,
            awayWins: 1,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeamId,
        isPostSeason: true,
        playoffBracket: playoffBracket,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeamId,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify playoff status is displayed
      expect(find.text('First Round'), findsOneWidget);
      expect(find.text('Play Next Playoff Game'), findsOneWidget);
    });

    testWidgets('HomePage displays championship celebration when user wins', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      
      // Create a completed finals series where user won
      final playoffBracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {userTeamId: 1},
        teamConferences: {userTeamId: 'east'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: PlayoffSeries(
          id: 'finals',
          homeTeamId: userTeamId,
          awayTeamId: teams[1].id,
          homeWins: 4,
          awayWins: 2,
          round: 'finals',
          conference: 'finals',
          gameIds: [],
          isComplete: true,
        ),
        currentRound: 'complete',
      );

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeamId,
        isPostSeason: true,
        playoffBracket: playoffBracket,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeamId,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify championship celebration is displayed (both in card and dialog)
      expect(find.text('🏆 NBA CHAMPIONS! 🏆'), findsNWidgets(2)); // Card + Dialog
      expect(find.text('Start New Season'), findsWidgets); // At least one
      
      // Verify dialog is shown
      expect(find.byType(Dialog), findsOneWidget);
      
      // Verify team name is shown in dialog
      expect(find.text('${teams[0].city} ${teams[0].name}'), findsWidgets);
    });

    testWidgets('HomePage displays elimination message when user is eliminated', (WidgetTester tester) async {
      final teams = leagueService.getAllTeams();
      
      // Create a bracket where user's team is not in current round (eliminated)
      final playoffBracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {userTeamId: 8, teams[1].id: 1},
        teamConferences: {userTeamId: 'east', teams[1].id: 'east'},
        playInGames: [],
        firstRound: [
          // User's team is not in this series (they were eliminated)
          PlayoffSeries(
            id: 'series-1',
            homeTeamId: teams[1].id,
            awayTeamId: teams[2].id,
            homeWins: 2,
            awayWins: 1,
            round: 'first-round',
            conference: 'east',
            gameIds: [],
            isComplete: false,
          ),
        ],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: userTeamId,
        isPostSeason: true,
        playoffBracket: playoffBracket,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeamId,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify elimination message is displayed
      expect(find.text('Team Eliminated'), findsAtLeastNWidgets(1));
    });

    testWidgets('HomePage displays regular season status when not in playoffs', (WidgetTester tester) async {
      // Create incomplete season (not in playoffs)
      final incompleteGames = <Game>[
        ...List.generate(50, (index) {
          return Game(
            id: 'game-$index',
            homeTeamId: userTeamId,
            awayTeamId: leagueService.getAllTeams()[1].id,
            homeScore: 100,
            awayScore: 90,
            isPlayed: true,
            scheduledDate: DateTime.now().add(Duration(days: index)),
          );
        }),
        // Add unplayed games
        ...List.generate(32, (index) {
          return Game(
            id: 'game-${50 + index}',
            homeTeamId: userTeamId,
            awayTeamId: leagueService.getAllTeams()[1].id,
            homeScore: null,
            awayScore: null,
            isPlayed: false,
            scheduledDate: DateTime.now().add(Duration(days: 50 + index)),
          );
        }),
      ];

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: incompleteGames,
        userTeamId: userTeamId,
        isPostSeason: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            leagueService: leagueService,
            initialSeason: season,
            initialUserTeamId: userTeamId,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify regular season status is displayed
      expect(find.text('Season 2024'), findsOneWidget);
      expect(find.text('Play Next Game'), findsOneWidget);
    });
  });
}
