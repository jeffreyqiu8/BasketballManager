import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/pages/role_assignment_page.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('RoleAssignmentPage Tests', () {
    late EnhancedTeam testTeam;
    late List<EnhancedPlayer> testPlayers;

    setUp(() {
      // Create test players
      testPlayers = [
        EnhancedPlayer(
          name: 'Point Guard Player',
          age: 25,
          team: '1',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 74,
          shooting: 80,
          rebounding: 60,
          passing: 90,
          ballHandling: 95,
          perimeterDefense: 75,
          postDefense: 50,
          insideShooting: 65,
          performances: {},
          primaryRole: PlayerRole.pointGuard,
          potential: PlayerPotential.fromTier(PotentialTier.gold),
          development: DevelopmentTracker.initial(age: 25),
        ),
        EnhancedPlayer(
          name: 'Shooting Guard Player',
          age: 23,
          team: '1',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 76,
          shooting: 95,
          rebounding: 65,
          passing: 70,
          ballHandling: 80,
          perimeterDefense: 85,
          postDefense: 60,
          insideShooting: 75,
          performances: {},
          primaryRole: PlayerRole.shootingGuard,
          potential: PlayerPotential.fromTier(PotentialTier.elite),
          development: DevelopmentTracker.initial(age: 23),
        ),
        EnhancedPlayer(
          name: 'Center Player',
          age: 27,
          team: '1',
          experienceYears: 5,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 84,
          shooting: 60,
          rebounding: 95,
          passing: 55,
          ballHandling: 45,
          perimeterDefense: 60,
          postDefense: 90,
          insideShooting: 85,
          performances: {},
          primaryRole: PlayerRole.center,
          potential: PlayerPotential.fromTier(PotentialTier.silver),
          development: DevelopmentTracker.initial(age: 27),
        ),
        EnhancedPlayer(
          name: 'Forward Player',
          age: 24,
          team: '1',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 80,
          shooting: 75,
          rebounding: 80,
          passing: 65,
          ballHandling: 70,
          perimeterDefense: 75,
          postDefense: 80,
          insideShooting: 80,
          performances: {},
          primaryRole: PlayerRole.powerForward,
          potential: PlayerPotential.fromTier(PotentialTier.gold),
          development: DevelopmentTracker.initial(age: 24),
        ),
        EnhancedPlayer(
          name: 'Small Forward Player',
          age: 26,
          team: '1',
          experienceYears: 4,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 78,
          shooting: 85,
          rebounding: 70,
          passing: 75,
          ballHandling: 80,
          perimeterDefense: 80,
          postDefense: 70,
          insideShooting: 75,
          performances: {},
          primaryRole: PlayerRole.smallForward,
          potential: PlayerPotential.fromTier(PotentialTier.gold),
          development: DevelopmentTracker.initial(age: 26),
        ),
      ];

      // Create test team
      testTeam = EnhancedTeam(
        name: 'Test Team',
        reputation: 75,
        playerCount: testPlayers.length,
        teamSize: testPlayers.length,
        players: testPlayers,
        roleAssignments: {},
      );
    });

    testWidgets('RoleAssignmentPage displays team name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Verify team name is displayed
      expect(find.text('Test Team Lineup'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage shows lineup validation status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Should show validation status (initially invalid since no assignments)
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage displays all position slots', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Verify all position abbreviations are displayed
      expect(find.text('PG'), findsOneWidget);
      expect(find.text('SG'), findsOneWidget);
      expect(find.text('SF'), findsOneWidget);
      expect(find.text('PF'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage shows available players', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Verify available players section is displayed
      expect(find.text('Available Players'), findsOneWidget);
      expect(find.text('5 players'), findsOneWidget);
      
      // Verify some player names are displayed
      expect(find.text('Point Guard Player'), findsOneWidget);
      expect(find.text('Shooting Guard Player'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage roles tab shows compatibility matrix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Tap on roles tab
      await tester.tap(find.text('Roles'));
      await tester.pumpAndSettle();

      // Verify role compatibility matrix is displayed
      expect(find.text('Role Compatibility Matrix'), findsOneWidget);
      expect(find.text('Player Role Assignments'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage analysis tab shows lineup analysis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Tap on analysis tab
      await tester.tap(find.text('Analysis'));
      await tester.pumpAndSettle();

      // Verify analysis sections are displayed
      expect(find.text('Lineup Analysis'), findsOneWidget);
      expect(find.text('Optimization Suggestions'), findsOneWidget);
      expect(find.text('Performance Prediction'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage auto-optimize button works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Tap the auto-optimize button
      await tester.tap(find.byIcon(Icons.auto_fix_high));
      await tester.pumpAndSettle();

      // Verify success message is shown
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage shows player selection dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Tap the add button for a position
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage displays compatibility percentages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Navigate to roles tab to see compatibility matrix
      await tester.tap(find.text('Roles'));
      await tester.pumpAndSettle();

      // Should find percentage indicators in the compatibility matrix
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('RoleAssignmentPage shows performance predictions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Navigate to analysis tab
      await tester.tap(find.text('Analysis'));
      await tester.pumpAndSettle();

      // Verify performance prediction categories are displayed
      expect(find.text('Offensive Rating'), findsOneWidget);
      expect(find.text('Defensive Rating'), findsOneWidget);
      expect(find.text('Team Chemistry'), findsOneWidget);
      expect(find.text('Overall Performance'), findsOneWidget);
    });

    testWidgets('RoleAssignmentPage handles empty lineup correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Verify empty slots show appropriate messages
      expect(find.text('Drag a player here'), findsWidgets);
    });

    testWidgets('RoleAssignmentPage shows optimization suggestions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RoleAssignmentPage(
            team: testTeam,
            players: testPlayers,
          ),
        ),
      );

      // Navigate to analysis tab
      await tester.tap(find.text('Analysis'));
      await tester.pumpAndSettle();

      // Verify optimization suggestions section exists
      expect(find.text('Optimization Suggestions'), findsOneWidget);
      expect(find.text('Auto-Optimize Lineup'), findsOneWidget);
    });
  });
}