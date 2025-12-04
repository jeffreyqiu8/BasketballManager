import 'package:flutter_test/flutter_test.dart';
import '../lib/models/season.dart';
import '../lib/models/game.dart';
import '../lib/services/league_service.dart';
import '../lib/services/game_service.dart';
import '../lib/services/playoff_service.dart';

/// Test to verify play-in tournament simulation works correctly
void main() {
  group('Play-In Tournament Simulation', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      gameService = GameService();
      await leagueService.initializeLeague();
    });

    test('Can simulate play-in tournament when user is seeded 1-6', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create dummy games
      final dummyGames = List<Game>.generate(82, (i) => Game(
        id: 'dummy-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: null,
        awayScore: null,
        isPlayed: false,
        scheduledDate: DateTime.now().add(Duration(days: i)),
      ));
      
      var season = Season(
        id: 'test-season',
        year: 2024,
        games: dummyGames,
        userTeamId: userTeam.id,
      );

      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      season = leagueService.simulateEntireRegularSeason(season, gameService);
      
      // Start post-season
      final postSeasonResult = leagueService.checkAndStartPostSeason(season);
      expect(postSeasonResult, isNotNull);
      season = postSeasonResult!;
      
      expect(season.isPostSeason, true);
      expect(season.playoffBracket, isNotNull);
      
      final bracket = season.playoffBracket!;
      print('\nUser team seed: ${bracket.teamSeedings[userTeam.id]}');
      print('Current round: ${bracket.currentRound}');
      print('Play-in games: ${bracket.playInGames.length}');
      
      // Try to simulate play-in tournament
      print('\n=== SIMULATING PLAY-IN ===');
      var updatedBracket = bracket;
      int iterations = 0;
      const maxIterations = 20;
      
      while (updatedBracket.currentRound == 'play-in' && iterations < maxIterations) {
        iterations++;
        print('\nIteration $iterations:');
        print('  Play-in games: ${updatedBracket.playInGames.length}');
        print('  Complete games: ${updatedBracket.playInGames.where((s) => s.isComplete).length}');
        
        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: updatedBracket,
          userTeamId: userTeam.id,
          getTeam: (teamId) => leagueService.getTeam(teamId)!,
          simulateGame: (homeTeam, awayTeam, series) {
            return gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
          },
        );
        
        updatedBracket = result.bracket;
        print('  After simulation - Round: ${updatedBracket.currentRound}');
        
        // Check if we're stuck
        if (updatedBracket.currentRound == 'play-in' && 
            updatedBracket.playInGames.length == bracket.playInGames.length &&
            updatedBracket.playInGames.every((s) => s.isComplete)) {
          print('  WARNING: All games complete but still in play-in round!');
          break;
        }
      }
      
      print('\n=== SIMULATION COMPLETE ===');
      print('Final round: ${updatedBracket.currentRound}');
      print('Iterations: $iterations');
      print('Play-in games: ${updatedBracket.playInGames.length}');
      
      // Should have advanced past play-in
      expect(updatedBracket.currentRound, isNot('play-in'),
          reason: 'Should have advanced past play-in round');
      expect(iterations, lessThan(maxIterations),
          reason: 'Should not hit iteration limit');
    });
  });
}
