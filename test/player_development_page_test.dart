import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/pages/player_development_page.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('PlayerDevelopmentPage Tests', () {
    late EnhancedPlayer testPlayer;
    late CoachProfile testCoach;

    setUp(() {
      // Create test player
      testPlayer = EnhancedPlayer(
        name: 'Test Player',
        age: 22,
        team: '1',
        experienceYears: 2,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 78,
        shooting: 75,
        rebounding: 70,
        passing: 80,
        ballHandling: 85,
        perimeterDefense: 65,
        postDefense: 60,
        insideShooting: 70,
        performances: {},
        primaryRole: PlayerRole.pointGuard,
        potential: PlayerPotential.fromTier(PotentialTier.gold),
        development: DevelopmentTracker.initial(age: 22),
      );

      // Add some experience to the player
      testPlayer.development.addSkillExperience('shooting', 150);
      testPlayer.development.addSkillExperience('passing', 200);

      // Create test coach
      testCoach = CoachProfile(
        name: 'Test Coach',
        age: 45,
        team: 1,
        experienceYears: 10,
        nationality: 'USA',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 75,
          'defensive': 70,
          'development': 90,
          'chemistry': 80,
        },
      );
    });

    testWidgets('PlayerDevelopmentPage displays player information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Verify player name is displayed
      expect(find.text('Test Player Development'), findsOneWidget);
      expect(find.text('Test Player'), findsOneWidget);
      
      // Verify player role and age are displayed
      expect(find.text('Point Guard • Age 22'), findsOneWidget);
      
      // Verify potential tier is displayed
      expect(find.text('Gold Potential'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage shows coaching influence when coach is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Verify coaching influence section is displayed
      expect(find.text('Coaching Influence'), findsOneWidget);
      expect(find.text('Test Coach'), findsOneWidget);
      expect(find.text('Player Development'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage displays skill development progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Verify skill development section is displayed
      expect(find.text('Skill Development Progress'), findsOneWidget);
      
      // Verify individual skills are displayed
      expect(find.text('Shooting'), findsOneWidget);
      expect(find.text('Passing'), findsOneWidget);
      expect(find.text('Ball Handling'), findsOneWidget);
      expect(find.text('Rebounding'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage shows upgrade buttons for skills with enough experience', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Look for upgrade indicators (UP badges)
      expect(find.text('UP'), findsOneWidget);
      
      // Look for skill point allocation section
      expect(find.text('Skill Point Allocation'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage potential tab shows potential breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Tap on potential tab
      await tester.tap(find.text('Potential'));
      await tester.pumpAndSettle();

      // Verify potential information is displayed
      expect(find.text('Player Potential'), findsOneWidget);
      expect(find.text('Skill Potential Breakdown'), findsOneWidget);
      expect(find.text('Development Curve'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage milestones tab shows development milestones', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Tap on milestones tab
      await tester.tap(find.text('Milestones'));
      await tester.pumpAndSettle();

      // Verify milestones information is displayed
      expect(find.text('Development Milestones'), findsOneWidget);
      expect(find.text('Milestone List'), findsOneWidget);
      
      // Verify some default milestones are shown
      expect(find.text('First Steps'), findsOneWidget);
      expect(find.text('Rising Talent'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage handles skill upgrade correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Find and tap an upgrade button if available
      final upgradeButtons = find.text('Upgrade');
      if (upgradeButtons.evaluate().isNotEmpty) {
        await tester.tap(upgradeButtons.first);
        await tester.pumpAndSettle();

        // Verify success message is shown
        expect(find.byType(SnackBar), findsOneWidget);
      }
    });

    testWidgets('PlayerDevelopmentPage shows no coach message when coach is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: null,
          ),
        ),
      );

      // Verify coaching influence section is not displayed
      expect(find.text('Coaching Influence'), findsNothing);
    });

    testWidgets('PlayerDevelopmentPage displays correct age phase information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Navigate to potential tab to see aging curve
      await tester.tap(find.text('Potential'));
      await tester.pumpAndSettle();

      // Verify age phase information is displayed
      expect(find.text('Development Phase'), findsOneWidget);
      expect(find.text('Peak Age'), findsOneWidget);
      expect(find.text('Decline Starts'), findsOneWidget);
      expect(find.text('Retirement Age'), findsOneWidget);
    });

    testWidgets('PlayerDevelopmentPage shows skill details when skill is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlayerDevelopmentPage(
            player: testPlayer,
            coach: testCoach,
          ),
        ),
      );

      // Find and tap on a skill to select it
      await tester.tap(find.text('Shooting').first);
      await tester.pumpAndSettle();

      // Verify skill details are shown
      expect(find.text('Skill Details'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Potential'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
    });
  });
}