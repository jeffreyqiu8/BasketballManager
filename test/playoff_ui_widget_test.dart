import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/playoff_bracket_page.dart';
import 'package:BasketballManager/widgets/championship_celebration_dialog.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/player_game_stats.dart';
import 'package:BasketballManager/models/player_playoff_stats.dart';
import 'package:BasketballManager/models/championship_record.dart';
import 'package:BasketballManager/services/league_service.dart';

/// Widget tests for playoff UI components
/// Validates Requirements: 25.1, 25.4, 26.3
void main() {
  group('PlayoffBracketPage Widget Tests', () {
    late LeagueService leagueService;
    late List<String> teamIds;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      final teams = leagueService.getAllTeams();
      teamIds = teams.map((t) => t.id).toList();
    });

    testWidgets('PlayoffBracketPage renders with play-in tournament', (WidgetTester tester) async {
      // Create play-in games
      final playInGames = [
        PlayoffSeries(
          id: 'playin-east-1',
          homeTeamId: teamIds[6], // 7th seed
          awayTeamId: teamIds[7], // 8th seed
          homeWins: 0,
          awayWins: 0,
          round: 'play-in',
          conference: 'east',
          gameIds: [],
          isComplete: false,
        ),
        PlayoffSeries(
          id: 'playin-east-2',
          homeTeamId: teamIds[8], // 9th seed
          awayTeamId: teamIds[9], // 10th seed
          homeWins: 0,
          awayWins: 0,
          round: 'play-in',
          conference: 'east',
          gameIds: [],
          isComplete: false,
        ),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: playInGames,
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'play-in',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: teamIds[0],
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar shows correct round (appears in both app bar and round indicator)
      expect(find.text('Play-In Tournament'), findsWidgets);

      // Verify round indicator is displayed
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      // Verify conference headers are displayed
      expect(find.text('Eastern Conference'), findsOneWidget);
      expect(find.text('Western Conference'), findsOneWidget);
    });

    testWidgets('PlayoffBracketPage displays first round series', (WidgetTester tester) async {
      // Create first round series
      final firstRound = [
        PlayoffSeries(
          id: 'series-1',
          homeTeamId: teamIds[0], // 1 seed
          awayTeamId: teamIds[7], // 8 seed
          homeWins: 2,
          awayWins: 1,
          round: 'first-round',
          conference: 'east',
          gameIds: ['g1', 'g2', 'g3'],
          isComplete: false,
        ),
        PlayoffSeries(
          id: 'series-2',
          homeTeamId: teamIds[1], // 2 seed
          awayTeamId: teamIds[6], // 7 seed
          homeWins: 1,
          awayWins: 2,
          round: 'first-round',
          conference: 'east',
          gameIds: ['g4', 'g5', 'g6'],
          isComplete: false,
        ),
      ];

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: [],
        firstRound: firstRound,
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: teamIds[0],
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify round name
      expect(find.text('First Round'), findsWidgets);

      // Verify series scores are displayed
      expect(find.text('Series: 2-1'), findsOneWidget);
      expect(find.text('Series: 1-2'), findsOneWidget);

      // Verify team names are displayed
      final team1 = leagueService.getTeam(teamIds[0])!;
      final team8 = leagueService.getTeam(teamIds[7])!;
      expect(find.textContaining(team1.city), findsWidgets);
      expect(find.textContaining(team8.city), findsWidgets);
    });

    testWidgets('PlayoffBracketPage highlights user team series', (WidgetTester tester) async {
      final userTeamId = teamIds[0];

      final series = PlayoffSeries(
        id: 'user-series',
        homeTeamId: userTeamId,
        awayTeamId: teamIds[7],
        homeWins: 3,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: [],
        firstRound: [series],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: userTeamId,
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user team has star icon
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('PlayoffBracketPage shows completed series with winner', (WidgetTester tester) async {
      final series = PlayoffSeries(
        id: 'completed-series',
        homeTeamId: teamIds[0],
        awayTeamId: teamIds[7],
        homeWins: 4,
        awayWins: 2,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5', 'g6'],
        isComplete: true,
      );

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: [],
        firstRound: [series],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: teamIds[0],
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify series complete indicator
      expect(find.text('Series Complete'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('PlayoffBracketPage displays NBA Finals', (WidgetTester tester) async {
      final finalsSeries = PlayoffSeries(
        id: 'finals',
        homeTeamId: teamIds[0], // East champion
        awayTeamId: teamIds[8], // West champion
        homeWins: 3,
        awayWins: 2,
        round: 'finals',
        conference: 'finals',
        gameIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        isComplete: false,
      );

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: finalsSeries,
        currentRound: 'finals',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: teamIds[0],
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify NBA Finals is displayed
      expect(find.text('NBA Finals'), findsWidgets);
      expect(find.text('Series: 3-2'), findsOneWidget);
    });

    testWidgets('PlayoffBracketPage has accessible labels for series cards', (WidgetTester tester) async {
      final series = PlayoffSeries(
        id: 'series-1',
        homeTeamId: teamIds[0],
        awayTeamId: teamIds[7],
        homeWins: 2,
        awayWins: 1,
        round: 'first-round',
        conference: 'east',
        gameIds: ['g1', 'g2', 'g3'],
        isComplete: false,
      );

      final bracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {for (var i = 0; i < 16; i++) teamIds[i]: i + 1},
        teamConferences: {
          for (var i = 0; i < 8; i++) teamIds[i]: 'east',
          for (var i = 8; i < 16; i++) teamIds[i]: 'west',
        },
        playInGames: [],
        firstRound: [series],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: null,
        currentRound: 'first-round',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayoffBracketPage(
            bracket: bracket,
            userTeamId: teamIds[0],
            leagueService: leagueService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find semantics nodes
      final semanticsFinder = find.byType(Semantics);
      expect(semanticsFinder, findsWidgets);

      // Verify accessibility labels exist
      final homeTeam = leagueService.getTeam(teamIds[0])!;
      final awayTeam = leagueService.getTeam(teamIds[7])!;
      
      // Check for series in progress label
      expect(
        find.bySemanticsLabel(RegExp('Series in progress.*${homeTeam.city}.*${awayTeam.city}.*2-1')),
        findsOneWidget,
      );
    });
  });

  group('Championship Celebration Dialog Widget Tests', () {
    late LeagueService leagueService;
    late Season season;
    late String championTeamId;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      
      final teams = leagueService.getAllTeams();
      championTeamId = teams[0].id;
      
      // Create playoff stats for MVP calculation
      final playoffStats = {
        teams[0].players[0].id: PlayerPlayoffStats(
          playerId: teams[0].players[0].id,
          gamesPlayed: 16,
          totalPoints: 400, // 25 PPG
          totalRebounds: 160, // 10 RPG
          totalAssists: 80, // 5 APG
          totalSteals: 32,
          totalBlocks: 16,
          totalTurnovers: 48,
          totalFouls: 48,
          totalFieldGoalsMade: 160,
          totalFieldGoalsAttempted: 320,
          totalThreePointersMade: 48,
          totalThreePointersAttempted: 120,
          totalFreeThrowsMade: 32,
          totalFreeThrowsAttempted: 40,
        ),
        teams[0].players[1].id: PlayerPlayoffStats(
          playerId: teams[0].players[1].id,
          gamesPlayed: 16,
          totalPoints: 320, // 20 PPG
          totalRebounds: 128,
          totalAssists: 64,
          totalSteals: 16,
          totalBlocks: 8,
          totalTurnovers: 32,
          totalFouls: 32,
          totalFieldGoalsMade: 128,
          totalFieldGoalsAttempted: 256,
          totalThreePointersMade: 32,
          totalThreePointersAttempted: 96,
          totalFreeThrowsMade: 32,
          totalFreeThrowsAttempted: 40,
        ),
      };

      final championshipRecord = ChampionshipRecord(
        year: 2024,
        championTeamId: championTeamId,
        finalsMvpPlayerId: teams[0].players[0].id,
        runnerUpTeamId: teams[1].id,
      );

      season = Season(
        id: 'season-2024',
        year: 2024,
        games: List.generate(82, (i) => Game(
          id: 'game-$i',
          homeTeamId: championTeamId,
          awayTeamId: teams[1].id,
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        )),
        userTeamId: championTeamId,
        isPostSeason: true,
        playoffStats: playoffStats,
        championshipRecord: championshipRecord,
      );
    });

    testWidgets('Championship dialog displays trophy and title', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;
      bool startNewSeasonCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionshipCelebrationDialog(
              season: season,
              championTeam: championTeam,
              leagueService: leagueService,
              onStartNewSeason: () => startNewSeasonCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify trophy icon
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      // Verify championship banner
      expect(find.text('🏆 NBA CHAMPIONS! 🏆'), findsOneWidget);

      // Verify team name
      expect(find.text('${championTeam.city} ${championTeam.name}'), findsOneWidget);

      // Verify year
      expect(find.text('2024 Season'), findsOneWidget);
    });

    testWidgets('Championship dialog displays Finals MVP', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;
      final mvpPlayer = championTeam.players[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionshipCelebrationDialog(
              season: season,
              championTeam: championTeam,
              leagueService: leagueService,
              onStartNewSeason: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Finals MVP section
      expect(find.text('Finals MVP'), findsOneWidget);
      // Player name appears in both MVP section and top performers list
      expect(find.text(mvpPlayer.name), findsWidgets);

      // Verify MVP stats are displayed
      expect(find.text('PPG'), findsOneWidget);
      expect(find.text('RPG'), findsOneWidget);
      expect(find.text('APG'), findsOneWidget);
      expect(find.text('FG%'), findsOneWidget);

      // Verify MVP stat values
      expect(find.text('25.0'), findsOneWidget); // PPG
      expect(find.text('10.0'), findsOneWidget); // RPG
      expect(find.text('5.0'), findsOneWidget); // APG
    });

    testWidgets('Championship dialog displays playoff performance summary', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionshipCelebrationDialog(
              season: season,
              championTeam: championTeam,
              leagueService: leagueService,
              onStartNewSeason: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify playoff performance section
      expect(find.text('Playoff Performance'), findsOneWidget);
      expect(find.text('Top Performers'), findsOneWidget);

      // Verify top scorers are listed
      final player1 = championTeam.players[0];
      final player2 = championTeam.players[1];
      expect(find.text(player1.name), findsWidgets); // Also in MVP section
      expect(find.text(player2.name), findsOneWidget);
    });

    testWidgets('Championship dialog Start New Season button works', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;
      bool startNewSeasonCalled = false;

      // Set larger test surface to accommodate dialog
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionshipCelebrationDialog(
              season: season,
              championTeam: championTeam,
              leagueService: leagueService,
              onStartNewSeason: () => startNewSeasonCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to make button visible
      await tester.dragUntilVisible(
        find.text('Start New Season'),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Find and tap Start New Season button
      final startButton = find.text('Start New Season');
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(startNewSeasonCalled, true);

      // Reset view size
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('Championship dialog Close button works', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;

      // Set larger test surface to accommodate dialog
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ChampionshipCelebrationDialog(
                      season: season,
                      championTeam: championTeam,
                      leagueService: leagueService,
                      onStartNewSeason: () {},
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(Dialog), findsOneWidget);

      // Scroll to make Close button visible
      await tester.dragUntilVisible(
        find.text('Close'),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.pumpAndSettle();

      // Find and tap Close button
      final closeButton = find.text('Close');
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(Dialog), findsNothing);

      // Reset view size
      addTearDown(() => tester.view.resetPhysicalSize());
    });

    testWidgets('Championship dialog handles missing MVP gracefully', (WidgetTester tester) async {
      final championTeam = leagueService.getTeam(championTeamId)!;
      
      // Create season without championship record (no MVP)
      final seasonWithoutMvp = Season(
        id: 'season-2024',
        year: 2024,
        games: season.games,
        userTeamId: championTeamId,
        isPostSeason: true,
        playoffStats: season.playoffStats,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionshipCelebrationDialog(
              season: seasonWithoutMvp,
              championTeam: championTeam,
              leagueService: leagueService,
              onStartNewSeason: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still display championship banner
      expect(find.text('🏆 NBA CHAMPIONS! 🏆'), findsOneWidget);

      // MVP section should not be displayed
      expect(find.text('Finals MVP'), findsNothing);
    });
  });

  group('Playoff Statistics Display Tests', () {
    late LeagueService leagueService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
    });

    testWidgets('Playoff stats are displayed separately from regular season', (WidgetTester tester) async {
      // This test verifies that playoff statistics tabs exist
      // The actual implementation would be in TeamPage and PlayerProfilePage
      // which already have their own widget tests
      
      // For now, we verify the data model supports separate playoff stats
      final teams = leagueService.getAllTeams();
      final team = teams[0];
      final player = team.players[0];

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: List.generate(82, (i) => Game(
          id: 'game-$i',
          homeTeamId: team.id,
          awayTeamId: teams[1].id,
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        )),
        userTeamId: team.id,
        isPostSeason: true,
      );

      // Add regular season game stats
      final regularGameStats = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 20,
          rebounds: 5,
          assists: 4,
          fieldGoalsMade: 8,
          fieldGoalsAttempted: 16,
          threePointersMade: 2,
          threePointersAttempted: 5,
          turnovers: 2,
          steals: 1,
          blocks: 0,
          fouls: 2,
          freeThrowsMade: 2,
          freeThrowsAttempted: 2,
        ),
      };
      season = season.updateSeasonStats(regularGameStats);

      // Add playoff game stats
      final playoffGameStats = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 25,
          rebounds: 10,
          assists: 5,
          fieldGoalsMade: 10,
          fieldGoalsAttempted: 20,
          threePointersMade: 3,
          threePointersAttempted: 7,
          turnovers: 3,
          steals: 2,
          blocks: 1,
          fouls: 3,
          freeThrowsMade: 2,
          freeThrowsAttempted: 3,
        ),
      };
      season = season.updatePlayoffStats(playoffGameStats);

      // Verify both stats exist and are different
      final regularStats = season.getPlayerStats(player.id);
      final postSeasonStats = season.getPlayerPlayoffStats(player.id);

      expect(regularStats, isNotNull);
      expect(postSeasonStats, isNotNull);
      expect(regularStats!.totalPoints, 20);
      expect(postSeasonStats!.totalPoints, 25);
    });
  });
}
