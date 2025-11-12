// Stub file for game result converter
// TODO: Implement proper game result converter

import 'game_result.dart';

class GameResultConverter {
  // Stub implementation
  static GameResult convertSimulationResult(Map<String, dynamic> result) {
    return GameResult(
      homeTeam: '',
      awayTeam: '',
      homeScore: 0,
      awayScore: 0,
      gameDate: DateTime.now(),
      season: 1,
      gameType: 'regular',
      homeTeamStats: null,
      awayTeamStats: null,
    );
  }
}
