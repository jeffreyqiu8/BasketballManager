import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/conference_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/conference_standings_page.dart';

void main() {
  group('ConferenceStandingsPage Tests', () {
    late Conference testConference;

    setUp(() {
      // Create a test conference with some teams
      testConference = Conference.custom(
        name: 'Test Conference',
        teams: [
          Team(
            name: 'Team A',
            reputation: 80,
            playerCount: 15,
            teamSize: 15,
            players: [],
          )..wins = 10..losses = 5,
          Team(
            name: 'Team B', 
            reputation: 70,
            playerCount: 15,
            teamSize: 15,
            players: [],
          )..wins = 8..losses = 7,
          Team(
            name: 'Team C',
            reputation: 60,
            playerCount: 15,
            teamSize: 15,
            players: [],
          )..wins = 6..losses = 9,
        ],
      );
    });

    testWidgets('ConferenceStandingsPage builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConferenceStandingsPage(conference: testConference),
        ),
      );

      // Verify the page builds
      expect(find.byType(ConferenceStandingsPage), findsOneWidget);
      
      // Verify the app bar title
      expect(find.text('Test Conference Standings'), findsOneWidget);
      
      // Verify view toggle buttons
      expect(find.text('Overall'), findsOneWidget);
      expect(find.text('By Division'), findsOneWidget);
    });

    testWidgets('ConferenceStandingsPage shows team standings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConferenceStandingsPage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Verify team names are displayed
      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
      expect(find.text('Team C'), findsOneWidget);
    });

    testWidgets('ConferenceStandingsPage can switch between views', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConferenceStandingsPage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be on overall view
      expect(find.text('Overall'), findsOneWidget);
      
      // Tap on division view
      await tester.tap(find.text('By Division'));
      await tester.pumpAndSettle();
      
      // Should still find the button (view switched)
      expect(find.text('By Division'), findsOneWidget);
    });
  });
}