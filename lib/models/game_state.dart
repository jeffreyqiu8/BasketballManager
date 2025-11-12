import 'team.dart';
import 'season.dart';

/// GameState model for save system
/// Encapsulates all game state data for serialization
class GameState {
  final List<Team> teams;
  final Season currentSeason;
  final String userTeamId;

  GameState({
    required this.teams,
    required this.currentSeason,
    required this.userTeamId,
  });

  /// Convert GameState to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'teams': teams.map((team) => team.toJson()).toList(),
      'currentSeason': currentSeason.toJson(),
      'userTeamId': userTeamId,
    };
  }

  /// Create GameState from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      teams: (json['teams'] as List)
          .map((teamJson) => Team.fromJson(teamJson as Map<String, dynamic>))
          .toList(),
      currentSeason: Season.fromJson(json['currentSeason'] as Map<String, dynamic>),
      userTeamId: json['userTeamId'] as String,
    );
  }
}
