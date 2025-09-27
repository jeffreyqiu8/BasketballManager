import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/pages/coaching_effectiveness_dashboard.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('CoachingEffectivenessDashboard Tests', () {
    late CoachProfile testCoach;
    late EnhancedTeam testTeam;
    late List<EnhancedPlayer> testPlayers;

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

      // Add some test achievements and history
      testCoach.achievements.add(Achievement(
        name: 'First Win',
        description: 'Won your first game as a coach',
        type: AchievementType.wins,
        unlockedDate: DateTime.now().subtract(const Duration(days: 15)),
      ));

      testCoach.history.addSeasonRecord(45, 37, true, false);
      testCoach.history.addSeasonRecord(52, 30, true, true);

      // Create test team
      testTeam = EnhancedTeam(
        name: 'Test Team',
        reputation: 75,
        playerCount: 15,
        teamSize: 15,
        players: [],
        conference: 'Eastern',
        division: 'Atlantic',
      );

      // Create test players
      testPlayers = [
        EnhancedPlayer(
          name: 'Test Player 1',
          age: 25,
          team: 'Test Team',
          experienceYears: 3,
          nationality: 'American',
          currentStatus: 'Active',
          height: 185,
          shooting: 75,
          rebounding: 60,
          passing: 80,
          ballHandling: 75,
          perimeterDefense: 65,
          postDefense: 55,
          insideShooting: 70,
          performances: {},
          primaryRole: PlayerRole.pointGuard,
        ),
        EnhancedPlayer(
          name: 'Test Player 2',
          age: 28,
          team: 'Test Team',
          experienceYears: 6,
          nationality: 'American',
          currentStatus: 'Active',
          height: 190,
          shooting: 85,
          rebounding: 55,
          passing: 60,
          ballHandling: 70,
          perimeterDefense: 70,
          postDefense: 60,
          insideShooting: 75,
          performances: {},
          primaryRole: PlayerRole.shootingGuard,
        ),
      ];
    });

    testWidgets('should display dashboard with performance overview', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify app bar
      expect(find.text('Coaching Effectiveness'), findsOneWidget);

      // Verify performance overview section
      expect(find.text('Performance Overview'), findsOneWidget);
      expect(find.text('Win Rate'), findsOneWidget);
      expect(find.text('Total Wins'), findsOneWidget);
      expect(find.text('Championships'), findsOneWidget);
    });

    testWidgets('should display team improvement metrics when team is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify team improvement section
      expect(find.text('Team Performance Impact'), findsOneWidget);
      expect(find.text('Offensive Rating'), findsOneWidget);
      expect(find.text('Defensive Rating'), findsOneWidget);
      expect(find.text('Team Chemistry'), findsOneWidget);
      expect(find.text('Player Development Rate'), findsOneWidget);
    });

    testWidgets('should display coaching bonuses visualization', (WidgetTester tester) async {
      // Calculate bonuses first
      testCoach.calculateTeamBonuses();

      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify coaching bonuses section
      expect(find.text('Active Coaching Bonuses'), findsOneWidget);
    });

    testWidgets('should display player development impact', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify player development section
      expect(find.text('Player Development Impact'), findsOneWidget);
      expect(find.text('Development Bonus'), findsOneWidget);
      expect(find.text('Current Team Development Progress'), findsOneWidget);
    });

    testWidgets('should display strategy effectiveness', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify strategy effectiveness section
      expect(find.text('Strategy Effectiveness'), findsOneWidget);
      expect(find.text('Strategy Recommendations'), findsOneWidget);
    });

    testWidgets('should display career milestones', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify career milestones section
      expect(find.text('Career Milestones & Progress'), findsOneWidget);
      expect(find.text('Next Milestones'), findsOneWidget);
      expect(find.text('Recent Achievements (Last 30 Days)'), findsOneWidget);
    });

    testWidgets('should handle coach without current team gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            // No current team provided
          ),
        ),
      );

      // Verify empty state for team performance
      expect(find.text('No current team assigned'), findsOneWidget);
      expect(find.text('Assign to a team to see performance impact'), findsOneWidget);
    });

    testWidgets('should change timeframe when filter is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify default timeframe
      expect(find.text('Current Season'), findsOneWidget);

      // Tap filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Select career timeframe
      await tester.tap(find.text('Career'));
      await tester.pumpAndSettle();

      // Verify timeframe changed
      expect(find.text('Career'), findsOneWidget);
    });

    testWidgets('should display recent achievements when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
            currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify recent achievement is displayed
      expect(find.text('First Win'), findsOneWidget);
    });

    testWidgets('should handle coach with no recent achievements', (WidgetTester tester) async {
      // Create coach with no recent achievements
      CoachProfile coachWithoutRecentAchievements = CoachProfile(
        name: 'Clean Coach',
        age: 30,
        team: 1,
        experienceYears: 1,
        nationality: 'American',
        currentStatus: 'Active',
        primarySpecialization: CoachingSpecialization.defensive,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: coachWithoutRecentAchievements,
          ),
        ),
      );

      // Verify empty state for recent achievements
      expect(find.text('No recent achievements'), findsOneWidget);
    });

    testWidgets('should display player development progress for team players', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CoachingEffectivenessDashboard(
            coach: testCoach,
          currentTeam: testTeam,
            teamPlayers: testPlayers,
          ),
        ),
      );

      // Verify player names are displayed
      expect(find.text('Test Player 1'), findsOneWidget);
      expect(find.text('Test Player 2'), findsOneWidget);

      // Verify player roles are displayed
      expect(find.text('Point Guard • Age 25'), findsOneWidget);
      expect(find.text('Shooting Guard • Age 28'), findsOneWidget);
    });
  });
}