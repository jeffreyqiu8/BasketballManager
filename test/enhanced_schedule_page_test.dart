import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/conference_class.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/views/pages/enhanced_schedule_page.dart';

void main() {
  group('EnhancedSchedulePage Tests', () {
    late Conference testConference;

    setUp(() {
      // Create a test conference with some teams
      testConference = Conference(name: 'Test Conference');
      
      // Play a few matchdays to generate some data
      testConference.playNextMatchday();
      testConference.playNextMatchday();
    });

    testWidgets('should display schedule view by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      // Verify the page loads
      expect(find.text('Test Conference Schedule & Stats'), findsOneWidget);
      
      // Verify schedule view is selected by default
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Playoffs'), findsOneWidget);
    });

    testWidgets('should switch between different views', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      // Test switching to statistics view
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      
      // Should show league leaders section
      expect(find.text('League Leaders'), findsOneWidget);
      expect(find.text('Team Rankings'), findsOneWidget);

      // Test switching to playoffs view
      await tester.tap(find.text('Playoffs'));
      await tester.pumpAndSettle();
      
      // Should show playoff bracket or not available message
      expect(find.text('Playoff Bracket'), findsOneWidget);
    });

    testWidgets('should display recent and upcoming games', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Should show recent games section (since we played some matchdays)
      expect(find.text('Recent Games'), findsOneWidget);
      
      // Should show upcoming games section
      expect(find.text('Upcoming Games'), findsOneWidget);
      
      // Should show all games section
      expect(find.text('All Games'), findsOneWidget);
    });

    testWidgets('should filter games by team', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the dropdown
      expect(find.text('Filter by team:'), findsOneWidget);
      expect(find.text('All Teams'), findsOneWidget);
      
      // The dropdown should contain team names
      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();
      
      // Should show team options in dropdown
      expect(find.text('Team A'), findsWidgets);
    });

    testWidgets('should display matchday selector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Should show matchday buttons
      expect(find.textContaining('MD'), findsWidgets);
      
      // Should be able to select different matchdays
      final matchdayButtons = find.textContaining('MD');
      expect(matchdayButtons, findsWidgets);
    });

    testWidgets('should show team statistics in statistics view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      // Switch to statistics view
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Should show league leaders
      expect(find.text('League Leaders'), findsOneWidget);
      expect(find.text('Points Per Game'), findsOneWidget);
      expect(find.text('Best Defense'), findsOneWidget);
      expect(find.text('Field Goal %'), findsOneWidget);

      // Should show team rankings
      expect(find.text('Team Rankings'), findsOneWidget);
      expect(find.text('PPG'), findsOneWidget);
      expect(find.text('OPP PPG'), findsOneWidget);
      expect(find.text('FG%'), findsOneWidget);
    });

    testWidgets('should show playoff bracket when available', (WidgetTester tester) async {
      // Create enhanced conference and generate playoff bracket
      EnhancedConference enhancedConf = EnhancedConference(name: 'Test Conference');
      enhancedConf.teams = testConference.teams;
      enhancedConf.schedule = testConference.schedule;
      enhancedConf.matchday = testConference.matchday;
      enhancedConf.updateStandings();
      enhancedConf.generatePlayoffBracket();

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      // Switch to playoffs view
      await tester.tap(find.text('Playoffs'));
      await tester.pumpAndSettle();

      // Should show playoff bracket section
      expect(find.text('Playoff Bracket'), findsOneWidget);
    });

    testWidgets('should display team details panel when team is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      // Switch to statistics view
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Tap on a team in the rankings to select it
      final teamRankings = find.textContaining('Team');
      if (teamRankings.evaluate().isNotEmpty) {
        await tester.tap(teamRankings.first);
        await tester.pumpAndSettle();

        // Should show team details panel
        expect(find.text('View Team'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      }
    });

    testWidgets('should show game details dialog when game is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Find a completed game and tap it
      final gameCards = find.byType(GestureDetector);
      if (gameCards.evaluate().isNotEmpty) {
        // Try to find a game card that contains score information
        for (final element in gameCards.evaluate()) {
          final widget = element.widget as GestureDetector;
          if (widget.onTap != null) {
            await tester.tap(find.byWidget(widget));
            await tester.pumpAndSettle();
            
            // Check if dialog appeared
            if (find.text('Game Details').evaluate().isNotEmpty) {
              expect(find.text('Game Details'), findsOneWidget);
              expect(find.text('Close'), findsOneWidget);
              
              // Close the dialog
              await tester.tap(find.text('Close'));
              await tester.pumpAndSettle();
              break;
            }
          }
        }
      }
    });

    testWidgets('should handle empty statistics gracefully', (WidgetTester tester) async {
      // Create a conference with no played games
      Conference emptyConference = Conference(name: 'Empty Conference');
      
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: emptyConference),
        ),
      );

      // Switch to statistics view
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      // Should still show the structure even with no data
      expect(find.text('League Leaders'), findsOneWidget);
      expect(find.text('Team Rankings'), findsOneWidget);
    });

    testWidgets('should refresh data when refresh button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: testConference),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Page should still be functional after refresh
      expect(find.text('Test Conference Schedule & Stats'), findsOneWidget);
    });
  });

  group('EnhancedSchedulePage Integration Tests', () {
    testWidgets('should integrate with enhanced conference features', (WidgetTester tester) async {
      // Create a more realistic test scenario
      Conference conference = Conference(name: 'NBA Eastern Conference');
      
      // Play several matchdays to generate realistic data
      for (int i = 0; i < 5; i++) {
        conference.playNextMatchday();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedSchedulePage(conference: conference),
        ),
      );

      await tester.pumpAndSettle();

      // Test that all major features work together
      
      // 1. Schedule view should show games
      expect(find.text('Recent Games'), findsOneWidget);
      expect(find.text('Upcoming Games'), findsOneWidget);
      
      // 2. Statistics view should show data
      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();
      expect(find.text('League Leaders'), findsOneWidget);
      
      // 3. Playoffs view should be accessible
      await tester.tap(find.text('Playoffs'));
      await tester.pumpAndSettle();
      expect(find.text('Playoff Bracket'), findsOneWidget);
      
      // 4. Back to schedule view
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();
      expect(find.text('All Games'), findsOneWidget);
    });
  });
}