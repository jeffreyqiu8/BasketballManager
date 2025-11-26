import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/season.dart';

/// Integration test to verify league-wide simulation works end-to-end
void main() {
  group('League Simulation Integration Tests', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
    });

    test('New season initializes with league schedule and all teams have games', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Create user's schedule
      final userGames = gameService.generateSchedule(userTeam.id, teams);

      // Create season
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
      );

      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);

      // Verify league schedule exists
      expect(season.leagueSchedule, isNotNull);
      expect(season.leagueSchedule!.allGames.isNotEmpty, true);

      // Verify all 30 teams have games
      expect(season.leagueSchedule!.teamGameIds.length, 30);

      // Verify user's games are in the league schedule
      for (var userGame in season.games) {
        final foundInSchedule = season.leagueSchedule!.allGames
            .any((g) => g.id == userGame.id);
        expect(foundInSchedule, true, reason: 'User game ${userGame.id} should be in league schedule');
      }
    });

    test('Simulating user season also simulates league games', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final userGames = gameService.generateSchedule(userTeam.id, teams);

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
      );

      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);

      // Verify no games are played initially
      expect(season.leagueSchedule!.gamesPlayed, 0);

      // Simulate the user's season
      season = leagueService.simulateEntireRegularSeason(season, gameService, updateStats: false);

      // Verify league games were also simulated
      expect(season.leagueSchedule, isNotNull);
      expect(season.leagueSchedule!.gamesPlayed, greaterThan(0));

      // Verify all teams have records
      final allRecords = season.leagueSchedule!.getAllTeamRecords();
      expect(allRecords.length, 30);

      // Verify each team has played games
      for (var teamId in allRecords.keys) {
        final record = allRecords[teamId]!;
        final totalGames = record['wins']! + record['losses']!;
        expect(totalGames, greaterThan(0), 
            reason: 'Team $teamId should have played games');
      }
    });

    test('All teams have realistic records after full season simulation', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final userGames = gameService.generateSchedule(userTeam.id, teams);

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
      );

      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);

      // Simulate the entire season
      season = leagueService.simulateEntireRegularSeason(season, gameService, updateStats: false);

      // Get all team records
      final allRecords = season.leagueSchedule!.getAllTeamRecords();

      // Verify all 30 teams have records
      expect(allRecords.length, 30);

      // Verify records are realistic
      int teamsWithGames = 0;
      for (var teamId in allRecords.keys) {
        final record = allRecords[teamId]!;
        final wins = record['wins']!;
        final losses = record['losses']!;
        final totalGames = wins + losses;

        if (totalGames > 0) {
          teamsWithGames++;
          
          // Verify wins and losses are reasonable
          expect(wins, greaterThanOrEqualTo(0));
          expect(wins, lessThanOrEqualTo(82));
          expect(losses, greaterThanOrEqualTo(0));
          expect(losses, lessThanOrEqualTo(82));
        }
      }

      // At least most teams should have played games
      expect(teamsWithGames, greaterThan(20));
    });

    test('User games stay in sync with league schedule', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final userGames = gameService.generateSchedule(userTeam.id, teams);

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
      );

      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);

      // Simulate the season
      season = leagueService.simulateEntireRegularSeason(season, gameService, updateStats: false);

      // Verify user's games are all played
      expect(season.gamesPlayed, 82);

      // Verify user's games match the league schedule
      for (var userGame in season.games) {
        final leagueGame = season.leagueSchedule!.allGames
            .firstWhere((g) => g.id == userGame.id);
        
        expect(leagueGame.isPlayed, userGame.isPlayed);
        expect(leagueGame.homeScore, userGame.homeScore);
        expect(leagueGame.awayScore, userGame.awayScore);
      }
    });
  });
}
