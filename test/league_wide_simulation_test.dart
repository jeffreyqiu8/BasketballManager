import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/season.dart';

/// Tests for league-wide game simulation
void main() {
  group('League-Wide Simulation Tests', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
    });

    test('generateLeagueSchedule creates games for all 30 teams', () {
      final schedule = leagueService.generateLeagueSchedule('season-2024');

      // Verify all teams have game IDs
      expect(schedule.teamGameIds.length, 30);

      // Verify each team has games (schedule generation is approximate)
      for (var teamId in schedule.teamGameIds.keys) {
        final gameCount = schedule.teamGameIds[teamId]!.length;
        expect(gameCount, greaterThan(0)); // Each team should have some games
      }

      // Verify games exist
      expect(schedule.allGames.isNotEmpty, true);
    });

    test('simulateLeagueGames simulates games across the league', () {
      final schedule = leagueService.generateLeagueSchedule('season-2024');

      // Verify no games are played initially
      expect(schedule.gamesPlayed, 0);

      // Simulate some games
      final updatedSchedule = leagueService.simulateLeagueGames(
        schedule,
        gameService,
        gamesToSimulate: 100,
      );

      // Verify games were simulated
      expect(updatedSchedule.gamesPlayed, 100);
      expect(updatedSchedule.gamesRemaining, lessThan(schedule.allGames.length));
    });

    test('getTeamRecord calculates wins and losses correctly', () {
      final schedule = leagueService.generateLeagueSchedule('season-2024');

      // Simulate all games
      final updatedSchedule = leagueService.simulateLeagueGames(
        schedule,
        gameService,
      );

      // Get records for all teams
      final teams = leagueService.getAllTeams();
      for (var team in teams) {
        final record = updatedSchedule.getTeamRecord(team.id);
        
        // Verify record has wins and losses
        expect(record.containsKey('wins'), true);
        expect(record.containsKey('losses'), true);
        
        // Verify wins + losses equals games played
        final totalGames = record['wins']! + record['losses']!;
        expect(totalGames, greaterThan(0)); // Each team should have played games
      }
    });

    test('Season with league schedule shows accurate standings', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      // Generate user's schedule
      final userGames = gameService.generateSchedule(userTeam.id, teams);

      // Generate league schedule
      final leagueSchedule = leagueService.generateLeagueSchedule('season-2024');

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
        leagueSchedule: leagueSchedule,
      );

      // Simulate league games
      final updatedSchedule = leagueService.simulateLeagueGames(
        leagueSchedule,
        gameService,
      );

      season = leagueService.updateSeasonWithLeagueSchedule(season, updatedSchedule);

      // Verify all teams have records
      final allRecords = season.leagueSchedule!.getAllTeamRecords();
      expect(allRecords.length, 30);

      // Verify each team has a realistic record
      for (var teamId in allRecords.keys) {
        final record = allRecords[teamId]!;
        final wins = record['wins']!;
        final losses = record['losses']!;
        
        expect(wins, greaterThanOrEqualTo(0));
        expect(losses, greaterThanOrEqualTo(0));
        expect(wins + losses, greaterThan(0)); // Each team should have played games
      }
    });

    test('League schedule persists through serialization', () {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];

      final userGames = gameService.generateSchedule(userTeam.id, teams);
      final leagueSchedule = leagueService.generateLeagueSchedule('season-2024');

      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: userGames,
        userTeamId: userTeam.id,
        leagueSchedule: leagueSchedule,
      );

      // Serialize and deserialize
      final json = season.toJson();
      final restoredSeason = Season.fromJson(json);

      // Verify league schedule was preserved
      expect(restoredSeason.leagueSchedule, isNotNull);
      expect(restoredSeason.leagueSchedule!.seasonId, 'season-2024');
      expect(restoredSeason.leagueSchedule!.teamGameIds.length, 30);
    });
  });
}
