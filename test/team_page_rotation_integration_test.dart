import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/rotation_config.dart';
import 'package:BasketballManager/models/depth_chart_entry.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/views/team_overview_page.dart';

void main() {
  group('Team Page Rotation Integration', () {
    late LeagueService leagueService;
    late Team testTeam;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      
      // Get the first team from the league
      final teams = leagueService.getAllTeams();
      testTeam = teams.first;
    });

    testWidgets('displays rotation summary section', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamOverviewPage(
            teamId: testTeam.id,
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify rotation section is displayed
      expect(find.text('Rotation'), findsOneWidget);
      expect(find.text('Edit Lineup'), findsOneWidget);
      expect(find.text('Edit Minutes'), findsOneWidget);
      // Teams now have default 8-player rotation, so "No Rotation Set" won't appear
      expect(find.text('8-Player Rotation'), findsOneWidget);
    });

    testWidgets('displays rotation summary with configured rotation', (WidgetTester tester) async {
      // Get player IDs from the team
      final playerIds = testTeam.players.map((p) => p.id).toList();
      
      // Add a rotation config to the team
      final rotationConfig = RotationConfig(
        rotationSize: 8,
        playerMinutes: {
          playerIds[0]: 36,
          playerIds[1]: 32,
          playerIds[2]: 30,
          playerIds[3]: 28,
          playerIds[4]: 30,
          playerIds[5]: 20,
          playerIds[6]: 16,
          playerIds[7]: 14,
        },
        depthChart: [
          DepthChartEntry(playerId: playerIds[0], position: 'PG', depth: 1),
          DepthChartEntry(playerId: playerIds[5], position: 'PG', depth: 2),
          DepthChartEntry(playerId: playerIds[1], position: 'SG', depth: 1),
          DepthChartEntry(playerId: playerIds[6], position: 'SG', depth: 2),
          DepthChartEntry(playerId: playerIds[2], position: 'SF', depth: 1),
          DepthChartEntry(playerId: playerIds[3], position: 'PF', depth: 1),
          DepthChartEntry(playerId: playerIds[7], position: 'PF', depth: 2),
          DepthChartEntry(playerId: playerIds[4], position: 'C', depth: 1),
        ],
        lastModified: DateTime.now(),
      );

      final teamWithRotation = testTeam.copyWith(rotationConfig: rotationConfig);
      await leagueService.updateTeam(teamWithRotation);

      await tester.pumpWidget(
        MaterialApp(
          home: TeamOverviewPage(
            teamId: testTeam.id,
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify rotation summary shows correct info
      expect(find.text('8-Player Rotation'), findsOneWidget);
      expect(find.text('Starting Lineup'), findsOneWidget);
      expect(find.text('Key Rotation Players'), findsOneWidget);
    });

    testWidgets('shows rotation badges on player cards', (WidgetTester tester) async {
      // Get player IDs from the team
      final playerIds = testTeam.players.map((p) => p.id).toList();
      
      // Add a rotation config to the team
      final rotationConfig = RotationConfig(
        rotationSize: 8,
        playerMinutes: {
          playerIds[0]: 36,
          playerIds[1]: 32,
          playerIds[2]: 30,
          playerIds[3]: 28,
          playerIds[4]: 30,
          playerIds[5]: 20,
          playerIds[6]: 16,
          playerIds[7]: 14,
        },
        depthChart: [
          DepthChartEntry(playerId: playerIds[0], position: 'PG', depth: 1),
          DepthChartEntry(playerId: playerIds[5], position: 'PG', depth: 2),
          DepthChartEntry(playerId: playerIds[1], position: 'SG', depth: 1),
          DepthChartEntry(playerId: playerIds[6], position: 'SG', depth: 2),
          DepthChartEntry(playerId: playerIds[2], position: 'SF', depth: 1),
          DepthChartEntry(playerId: playerIds[3], position: 'PF', depth: 1),
          DepthChartEntry(playerId: playerIds[7], position: 'PF', depth: 2),
          DepthChartEntry(playerId: playerIds[4], position: 'C', depth: 1),
        ],
        lastModified: DateTime.now(),
      );

      final teamWithRotation = testTeam.copyWith(rotationConfig: rotationConfig);
      await leagueService.updateTeam(teamWithRotation);

      await tester.pumpWidget(
        MaterialApp(
          home: TeamOverviewPage(
            teamId: testTeam.id,
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify rotation badges are shown for players in rotation
      expect(find.text('36m'), findsWidgets);
      expect(find.text('32m'), findsWidgets);
      expect(find.text('20m'), findsWidgets);
    });

    testWidgets('edit minutes button opens dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TeamOverviewPage(
            teamId: testTeam.id,
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the edit minutes button
      await tester.tap(find.text('Edit Minutes'));
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.text('Edit Minutes'), findsAtLeastNWidgets(2));
      // Also verify rotation size selector is present
      expect(find.text('Rotation Size & Presets'), findsOneWidget);
    });
  });
}
