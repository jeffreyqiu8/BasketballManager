import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/enhanced_game_simulation.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/gameData/player_class.dart';

void main() {
  group('Simple Integration Tests', () {
    test('should run enhanced game simulation without coaches', () {
      // Create simple teams with regular players
      final homeTeam = Team(
        name: 'Home Team',
        reputation: 80,
        playerCount: 5,
        teamSize: 5,
        players: List.generate(5, (index) => Player(
          name: 'Home Player ${index + 1}',
          age: 25,
          team: 'Home Team',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 200,
          shooting: 75,
          rebounding: 70,
          passing: 65,
          ballHandling: 70,
          perimeterDefense: 75,
          postDefense: 70,
          insideShooting: 72,
          performances: {},
        )),
      );

      final awayTeam = Team(
        name: 'Away Team',
        reputation: 75,
        playerCount: 5,
        teamSize: 5,
        players: List.generate(5, (index) => Player(
          name: 'Away Player ${index + 1}',
          age: 24,
          team: 'Away Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 198,
          shooting: 73,
          rebounding: 68,
          passing: 63,
          ballHandling: 68,
          perimeterDefense: 73,
          postDefense: 68,
          insideShooting: 70,
          performances: {},
        )),
      );

      // Run simulation
      final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);

      // Verify basic results
      expect(result['homeScore'], isA<int>());
      expect(result['awayScore'], isA<int>());
      expect(result['homeBoxScore'], isA<Map<String, Map<String, int>>>());
      expect(result['awayBoxScore'], isA<Map<String, Map<String, int>>>());

      // Verify scores are realistic
      final homeScore = result['homeScore'] as int;
      final awayScore = result['awayScore'] as int;
      expect(homeScore, greaterThan(60));
      expect(homeScore, lessThan(150));
      expect(awayScore, greaterThan(60));
      expect(awayScore, lessThan(150));

      print('Game Result: Home $homeScore - Away $awayScore');
    });

    test('should handle multiple simulations consistently', () {
      final homeTeam = Team(
        name: 'Home Team',
        reputation: 85,
        playerCount: 5,
        teamSize: 5,
        players: List.generate(5, (index) => Player(
          name: 'Home Player ${index + 1}',
          age: 25,
          team: 'Home Team',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 200,
          shooting: 80,
          rebounding: 75,
          passing: 70,
          ballHandling: 75,
          perimeterDefense: 80,
          postDefense: 75,
          insideShooting: 77,
          performances: {},
        )),
      );

      final awayTeam = Team(
        name: 'Away Team',
        reputation: 70,
        playerCount: 5,
        teamSize: 5,
        players: List.generate(5, (index) => Player(
          name: 'Away Player ${index + 1}',
          age: 24,
          team: 'Away Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 198,
          shooting: 70,
          rebounding: 65,
          passing: 60,
          ballHandling: 65,
          perimeterDefense: 70,
          postDefense: 65,
          insideShooting: 67,
          performances: {},
        )),
      );

      // Run multiple simulations
      final results = <Map<String, dynamic>>[];
      for (int i = 0; i < 5; i++) {
        final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
        results.add(result);
      }

      // Verify all simulations completed successfully
      expect(results.length, equals(5));
      
      for (final result in results) {
        expect(result['homeScore'], isA<int>());
        expect(result['awayScore'], isA<int>());
        
        final homeScore = result['homeScore'] as int;
        final awayScore = result['awayScore'] as int;
        expect(homeScore, greaterThan(50));
        expect(homeScore, lessThan(160));
        expect(awayScore, greaterThan(50));
        expect(awayScore, lessThan(160));
      }

      print('All 5 simulations completed successfully');
    });
  });
}