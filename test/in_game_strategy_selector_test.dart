import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/widgets/in_game_strategy_selector.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('InGameStrategySelector Tests', () {
    late EnhancedTeam mockTeam;

    setUp(() {
      List<EnhancedPlayer> mockPlayers = [];
      mockTeam = EnhancedTeam(
        name: 'Test Team',
        reputation: 50,
        playerCount: 0,
        teamSize: 15,
        players: mockPlayers,
        conference: 'Eastern',
        division: 'Atlantic',
      );
    });

    testWidgets('should display strategy selector with header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Should show strategy header
      expect(find.text('Strategy'), findsOneWidget);
      expect(find.byIcon(Icons.sports_basketball), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should expand and show content when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Initially collapsed
      expect(find.text('Quick Adjustments'), findsNothing);

      // Tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should show expanded content
      expect(find.text('Quick Adjustments'), findsOneWidget);
      expect(find.text('Available Playbooks'), findsOneWidget);
      expect(find.text('AI Recommendations'), findsOneWidget);
    });

    testWidgets('should show quick strategy buttons when expanded', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Expand the selector
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should show quick strategy buttons
      expect(find.text('Aggressive'), findsOneWidget);
      expect(find.text('Defensive'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Fast Pace'), findsOneWidget);
    });

    testWidgets('should show active playbook information', (WidgetTester tester) async {
      // Add a playbook to the team
      Playbook testPlaybook = Playbook(
        name: 'Test Strategy',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.pressDefense,
      );
      mockTeam.playbookLibrary.addPlaybook(testPlaybook);
      mockTeam.playbookLibrary.setActivePlaybook('Test Strategy');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Should show active playbook name
      expect(find.text('Test Strategy'), findsOneWidget);
      expect(find.text('Fast Break • Press Defense'), findsOneWidget);
    });

    testWidgets('should handle strategy change callback', (WidgetTester tester) async {
      Playbook? changedPlaybook;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(
              team: mockTeam,
              onStrategyChanged: (playbook) {
                changedPlaybook = playbook;
              },
            ),
          ),
        ),
      );

      // Expand and tap a quick strategy button
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aggressive'));
      await tester.pumpAndSettle();

      // Should have called the callback
      expect(changedPlaybook, isNotNull);
      expect(changedPlaybook?.name, 'Run and Gun');
    });

    testWidgets('should show game active indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(
              team: mockTeam,
              isGameActive: true,
            ),
          ),
        ),
      );

      // Should show orange border/indicators when game is active
      Container container = tester.widget(find.byType(Container).first);
      BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('should display effectiveness indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Expand to see effectiveness indicators
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should show percentage indicators
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('should show snackbar when strategy changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: mockTeam),
          ),
        ),
      );

      // Expand and change strategy
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Balanced'));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Strategy changed'), findsOneWidget);
    });

    testWidgets('should handle empty playbook library', (WidgetTester tester) async {
      // Create team with empty playbook library
      EnhancedTeam emptyTeam = EnhancedTeam(
        name: 'Empty Team',
        reputation: 50,
        playerCount: 0,
        teamSize: 15,
        players: [],
        conference: 'Eastern',
        division: 'Atlantic',
      );
      emptyTeam.playbookLibrary = PlaybookLibrary(); // Empty library

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InGameStrategySelector(team: emptyTeam),
          ),
        ),
      );

      // Should handle empty state gracefully
      expect(find.text('Strategy'), findsOneWidget);
      expect(find.text('No Strategy'), findsOneWidget);
    });
  });
}