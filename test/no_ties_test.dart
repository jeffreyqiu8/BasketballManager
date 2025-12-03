import 'package:flutter_test/flutter_test.dart';
import '../lib/services/game_service.dart';
import '../lib/services/league_service.dart';

/// Test to verify that game simulations never produce ties
void main() {
  group('No Ties in Game Simulation', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      gameService = GameService();
      await leagueService.initializeLeague();
    });

    test('simulateGame never produces ties', () {
      final teams = leagueService.getAllTeams();
      
      // Simulate 1000 games to check for ties
      for (int i = 0; i < 1000; i++) {
        final team1 = teams[i % teams.length];
        final team2 = teams[(i + 1) % teams.length];
        
        final game = gameService.simulateGame(team1, team2);
        
        expect(game.homeScore, isNotNull);
        expect(game.awayScore, isNotNull);
        expect(game.homeScore, isNot(equals(game.awayScore)),
            reason: 'Game ${i + 1}: ${team1.city} ${team1.name} vs ${team2.city} ${team2.name} ended in a tie: ${game.homeScore}-${game.awayScore}');
      }
      
      print('✓ Simulated 1000 games with no ties');
    });

    test('simulateGameDetailed never produces ties', () {
      final teams = leagueService.getAllTeams();
      
      // Simulate 100 detailed games to check for ties (fewer because they're slower)
      for (int i = 0; i < 100; i++) {
        final team1 = teams[i % teams.length];
        final team2 = teams[(i + 1) % teams.length];
        
        final game = gameService.simulateGameDetailed(team1, team2);
        
        expect(game.homeScore, isNotNull);
        expect(game.awayScore, isNotNull);
        expect(game.homeScore, isNot(equals(game.awayScore)),
            reason: 'Game ${i + 1}: ${team1.city} ${team1.name} vs ${team2.city} ${team2.name} ended in a tie: ${game.homeScore}-${game.awayScore}');
      }
      
      print('✓ Simulated 100 detailed games with no ties');
    });
  });
}
