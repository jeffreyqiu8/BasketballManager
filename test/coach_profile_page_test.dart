import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/pages/coach_profile_page.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('CoachProfilePage Tests', () {
    late CoachProfile testCoach;

    setUp(() {
      testCoach = CoachProfile(
        name: 'Test Coach',
        age: 45,
        team: 1,
        experienceYears: 10,
        nationality: 'American',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.offensive,
        secondarySpecialization: CoachingSpecialization.playerDevelopment,
        coachingAttributes: {
          'offensive': 75,
          'defensive': 60,
          'development': 80,
          'chemistry': 65,
        },
        experienceLevel: 3,
      );

      // Add some test achievements
      testCoach.achievements.add(Achievement(
        name: 'First Win',
        description: 'Won your first game as a coach',
        type: AchievementType.wins,
        unlockedDate: DateTime.now().subtract(const Duration(days: 30)),
      ));

      // Add some test season records
      testCoach.history.addSeasonRecord(45, 37, true, false);
      testCoach.history.addSeasonRecord(52, 30, true, true);
    });

    testWidgets('should display coach profile page with basic information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Verify coach name in app bar
      expect(find.text('Test Coach'), findsOneWidget);

      // Verify tab buttons
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Verify basic information is displayed
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('45'), findsOneWidget); // Age
      expect(find.text('10 years'), findsOneWidget); // Experience
      expect(find.text('American'), findsOneWidget); // Nationality
    });

    testWidgets('should display coaching specializations correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Verify specializations section
      expect(find.text('Coaching Specializations'), findsOneWidget);
      expect(find.text('Primary Specialization'), findsOneWidget);
      expect(find.text('Secondary Specialization'), findsOneWidget);
      expect(find.text('Offensive'), findsOneWidget);
      expect(find.text('Player Development'), findsWidgets);
    });

    testWidgets('should display coaching attributes with progress bars', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Verify coaching attributes section
      expect(find.text('Coaching Attributes'), findsOneWidget);
      expect(find.text('Offensive Coaching'), findsOneWidget);
      expect(find.text('Defensive Coaching'), findsOneWidget);
      expect(find.text('Player Development'), findsWidgets);
      expect(find.text('Team Chemistry'), findsOneWidget);

      // Verify attribute values
      expect(find.text('75'), findsOneWidget); // Offensive
      expect(find.text('60'), findsOneWidget); // Defensive
      expect(find.text('80'), findsOneWidget); // Development
      expect(find.text('65'), findsOneWidget); // Chemistry
    });

    testWidgets('should display experience level and progress', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Verify experience section
      expect(find.text('Experience & Level'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
    });

    testWidgets('should switch to achievements tab and display achievements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Tap on achievements tab
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      // Verify achievements content
      expect(find.text('Achievement Overview'), findsOneWidget);
      expect(find.text('First Win'), findsOneWidget);
      expect(find.text('Won your first game as a coach'), findsOneWidget);
    });

    testWidgets('should switch to history tab and display career stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Tap on history tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify history content
      expect(find.text('Career Statistics'), findsOneWidget);
      expect(find.text('Season History'), findsOneWidget);
      expect(find.text('97'), findsOneWidget); // Total wins (45 + 52)
      expect(find.text('67'), findsOneWidget); // Total losses (37 + 30)
    });

    testWidgets('should display team bonuses when calculated', (WidgetTester tester) async {
      // Calculate team bonuses
      testCoach.calculateTeamBonuses();

      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Verify team bonuses section
      expect(find.text('Team Bonuses'), findsOneWidget);
    });

    testWidgets('should show edit dialog when edit button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: testCoach),
        ),
      );

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Verify dialog appears
      expect(find.text('Edit Coach Profile'), findsOneWidget);
      expect(find.text('Coach profile editing will be available in a future update.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle coach with no achievements gracefully', (WidgetTester tester) async {
      // Create coach with no achievements
      CoachProfile emptyCoach = CoachProfile(
        name: 'Empty Coach',
        age: 30,
        team: 1,
        experienceYears: 1,
        nationality: 'American',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.defensive,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: emptyCoach),
        ),
      );

      // Switch to achievements tab
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No achievements yet'), findsOneWidget);
      expect(find.text('Keep coaching to unlock achievements!'), findsOneWidget);
    });

    testWidgets('should handle coach with no season history gracefully', (WidgetTester tester) async {
      // Create coach with no season history
      CoachProfile newCoach = CoachProfile(
        name: 'New Coach',
        age: 25,
        team: 1,
        experienceYears: 0,
        nationality: 'American',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.teamChemistry,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoachProfilePage(coach: newCoach),
        ),
      );

      // Switch to history tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No season history yet'), findsOneWidget);
      expect(find.text('Complete a season to see your coaching history!'), findsOneWidget);
    });
  });
}