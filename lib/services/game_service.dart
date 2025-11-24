import 'dart:math';
import '../models/game.dart';
import '../models/team.dart';
import '../models/playoff_series.dart';
import 'possession_simulation.dart';
import 'package:uuid/uuid.dart';

/// Service for game simulation and schedule management
/// Handles match simulation using team ratings
class GameService {
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  /// Simulate a single game between two teams with detailed possession-by-possession simulation
  /// Returns a Game object with scores and box score populated
  /// Completes within 3 seconds for optimal performance
  Game simulateGameDetailed(Team homeTeam, Team awayTeam) {
    // Create possession simulation
    final simulation = PossessionSimulation(homeTeam, awayTeam);
    
    // Run the simulation to get box score
    final boxScore = simulation.simulate();
    
    // Create and return the completed game with box score
    return Game(
      id: _uuid.v4(),
      homeTeamId: homeTeam.id,
      awayTeamId: awayTeam.id,
      homeScore: simulation.homeScore,
      awayScore: simulation.awayScore,
      isPlayed: true,
      scheduledDate: DateTime.now(),
      boxScore: boxScore,
    );
  }

  /// Simulate a single game between two teams (basic simulation)
  /// Returns a Game object with scores populated
  /// This is a fallback method for quick simulations without detailed stats
  Game simulateGame(Team homeTeam, Team awayTeam) {
    // Calculate team ratings from starting lineups
    final homeRating = homeTeam.teamRating;
    final awayRating = awayTeam.teamRating;

    // Calculate base scores (80-120 range)
    final homeScore = _calculateTeamScore(homeRating);
    final awayScore = _calculateTeamScore(awayRating);

    // Create and return the completed game
    return Game(
      id: _uuid.v4(),
      homeTeamId: homeTeam.id,
      awayTeamId: awayTeam.id,
      homeScore: homeScore,
      awayScore: awayScore,
      isPlayed: true,
      scheduledDate: DateTime.now(),
    );
  }

  /// Calculate team score based on rating with variance
  /// Generates realistic scores in 80-120 range
  int _calculateTeamScore(int teamRating) {
    // Base score starts at 80
    const baseScore = 80;

    // Rating influence: 0-100 rating maps to 0-25 points
    final ratingBonus = (teamRating * 0.25).round();

    // Random variance: ±15 points
    final variance = _random.nextInt(31) - 15; // -15 to +15

    // Calculate final score
    final score = baseScore + ratingBonus + variance;

    // Clamp to realistic range (70-130)
    return score.clamp(70, 130);
  }

  /// Generate 82-game schedule for a team
  /// Returns list of games against various opponents
  List<Game> generateSchedule(String userTeamId, List<Team> allTeams) {
    final schedule = <Game>[];
    final opponents = allTeams.where((team) => team.id != userTeamId).toList();

    // Generate 82 games
    for (int i = 0; i < 82; i++) {
      // Pick a random opponent
      final opponent = opponents[_random.nextInt(opponents.length)];

      // Randomly decide if user team is home or away
      final isHome = _random.nextBool();

      final game = Game(
        id: _uuid.v4(),
        homeTeamId: isHome ? userTeamId : opponent.id,
        awayTeamId: isHome ? opponent.id : userTeamId,
        homeScore: null,
        awayScore: null,
        isPlayed: false,
        scheduledDate: DateTime.now().add(Duration(days: i)),
      );

      schedule.add(game);
    }

    return schedule;
  }

  /// Simulate a playoff game between two teams
  /// Uses existing simulateGameDetailed for possession simulation
  /// Marks game as playoff game with seriesId reference
  /// Returns Game object with playoff metadata and box score
  /// 
  /// Requirements: 23.1, 23.2, 23.3, 23.4, 27.1
  Game simulatePlayoffGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
    // Use existing detailed simulation for possession-by-possession gameplay
    final game = simulateGameDetailed(homeTeam, awayTeam);
    
    // Mark as playoff game with series reference
    return game.copyWith(
      isPlayoffGame: true,
      seriesId: series.id,
    );
  }

  /// Update playoff series with game result
  /// Increments homeWins or awayWins based on winner
  /// Checks if series is complete (team reaches 4 wins)
  /// Returns updated PlayoffSeries
  PlayoffSeries updateSeriesWithResult(PlayoffSeries series, Game game) {
    // Determine winner
    final winnerTeamId = game.homeTeamWon ? game.homeTeamId : game.awayTeamId;
    
    // Update series with game result
    return series.copyWithGameResult(game.id, winnerTeamId);
  }
}
