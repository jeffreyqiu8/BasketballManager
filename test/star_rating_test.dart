import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';

void main() {
  group('Star Rating System - Relative to Team', () {
    test('Best player on team gets 5 stars, worst gets 1-2 stars', () {
      // Create a team with varying skill levels
      final players = [
        // Worst player
        Player(
          id: '1',
          name: 'Worst',
          heightInches: 72,
          shooting: 30,
          defense: 30,
          speed: 30,
          stamina: 30,
          passing: 30,
          rebounding: 30,
          ballHandling: 30,
          threePoint: 30,
          blocks: 30,
          steals: 30,
          position: 'SG',
        ),
        // Average player
        Player(
          id: '2',
          name: 'Average',
          heightInches: 76,
          shooting: 60,
          defense: 60,
          speed: 60,
          stamina: 60,
          passing: 60,
          rebounding: 60,
          ballHandling: 60,
          threePoint: 60,
          blocks: 60,
          steals: 60,
          position: 'SF',
        ),
        // Best player
        Player(
          id: '3',
          name: 'Best',
          heightInches: 78,
          shooting: 95,
          defense: 95,
          speed: 90,
          stamina: 90,
          passing: 90,
          rebounding: 95,
          ballHandling: 90,
          threePoint: 95,
          blocks: 95,
          steals: 95,
          position: 'SF',
        ),
      ];

      final worstStars = players[0].getStarRating(players);
      final avgStars = players[1].getStarRating(players);
      final bestStars = players[2].getStarRating(players);

      // Worst player should get 1-2 stars
      expect(worstStars, greaterThanOrEqualTo(1.0));
      expect(worstStars, lessThanOrEqualTo(2.0));

      // Average player should get around 3 stars
      expect(avgStars, greaterThanOrEqualTo(2.5));
      expect(avgStars, lessThanOrEqualTo(3.5));

      // Best player should get close to 5 stars
      expect(bestStars, greaterThanOrEqualTo(4.5));
      expect(bestStars, lessThanOrEqualTo(5.0));

      // Stars should be ordered
      expect(worstStars, lessThan(avgStars));
      expect(avgStars, lessThan(bestStars));
    });

    test('Player with poor position fit gets lower adjusted rating', () {
      // Create a center with PG position (poor fit)
      final misfit = Player(
        id: '2',
        name: 'Misfit Center',
        heightInches: 84, // 7'0" - too tall for PG
        shooting: 60,
        defense: 85,
        speed: 50, // Slow for PG
        stamina: 75,
        passing: 55, // Low passing for PG
        rebounding: 90,
        ballHandling: 45, // Low ball handling for PG
        threePoint: 40,
        blocks: 90,
        steals: 60,
        position: 'PG', // Assigned as PG but has center attributes
      );

      // Position-adjusted rating should be lower than base rating
      expect(misfit.positionAdjustedRating, lessThanOrEqualTo(misfit.overallRating));
    });

    test('Star rating is relative within team context', () {
      // Create a team of all similar players
      final similarPlayers = List.generate(
        5,
        (i) => Player(
          id: '$i',
          name: 'Player $i',
          heightInches: 76,
          shooting: 70,
          defense: 70,
          speed: 70,
          stamina: 70,
          passing: 70,
          rebounding: 70,
          ballHandling: 70,
          threePoint: 70,
          blocks: 70,
          steals: 70,
          position: 'SF',
        ),
      );

      // All players should get around 3 stars (middle of range)
      for (var player in similarPlayers) {
        final stars = player.getStarRating(similarPlayers);
        expect(stars, equals(3.0));
      }
    });

    test('Rounded star rating uses half-star increments', () {
      final players = [
        Player(
          id: '1',
          name: 'Player 1',
          heightInches: 72,
          shooting: 50,
          defense: 50,
          speed: 50,
          stamina: 50,
          passing: 50,
          rebounding: 50,
          ballHandling: 50,
          threePoint: 50,
          blocks: 50,
          steals: 50,
          position: 'SG',
        ),
        Player(
          id: '2',
          name: 'Player 2',
          heightInches: 76,
          shooting: 80,
          defense: 80,
          speed: 80,
          stamina: 80,
          passing: 80,
          rebounding: 80,
          ballHandling: 80,
          threePoint: 80,
          blocks: 80,
          steals: 80,
          position: 'SF',
        ),
      ];

      final rounded = players[0].getStarRatingRounded(players);
      
      // Should be divisible by 0.5
      expect(rounded * 2 % 1, equals(0));
      
      // Should be between 1 and 5
      expect(rounded, greaterThanOrEqualTo(1.0));
      expect(rounded, lessThanOrEqualTo(5.0));
    });

    test('Position affinity affects rating appropriately', () {
      // Create a player with balanced stats
      final player = Player(
        id: '5',
        name: 'Balanced',
        heightInches: 78,
        shooting: 70,
        defense: 70,
        speed: 70,
        stamina: 70,
        passing: 70,
        rebounding: 70,
        ballHandling: 70,
        threePoint: 70,
        blocks: 70,
        steals: 70,
        position: 'SF',
      );

      final baseRating = player.overallRating;
      final adjustedRating = player.positionAdjustedRating;

      // Adjusted rating should be within reasonable range of base
      expect((adjustedRating - baseRating).abs(), lessThanOrEqualTo(10));

      // Both should be around 70
      expect(baseRating, equals(70));
    });
  });
}
