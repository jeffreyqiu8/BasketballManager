import 'player.dart';
import 'rotation_config.dart';

/// Team model with 15-player roster and starting lineup management
/// Represents a basketball team in the league
class Team {
  final String id;
  final String name;
  final String city;
  final List<Player> players; // Always 15 players
  final List<String> startingLineupIds; // 5 player IDs
  final RotationConfig? rotationConfig; // Optional rotation configuration

  Team({
    required this.id,
    required this.name,
    required this.city,
    required this.players,
    required this.startingLineupIds,
    this.rotationConfig,
  }) : assert(players.length == 15, 'Team must have exactly 15 players'),
       assert(
         startingLineupIds.length == 5,
         'Starting lineup must have exactly 5 players',
       );

  /// Get the starting lineup players
  /// If rotation config exists, uses depth chart (depth = 1)
  /// Otherwise falls back to startingLineupIds
  List<Player> get startingLineup {
    if (rotationConfig != null) {
      // Get starters from rotation config (depth = 1)
      final starterIds = rotationConfig!.depthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toSet();
      
      return players
          .where((player) => starterIds.contains(player.id))
          .toList();
    }
    
    // Fallback to startingLineupIds if no rotation config
    return players
        .where((player) => startingLineupIds.contains(player.id))
        .toList();
  }

  /// Get the bench players
  List<Player> get bench {
    return players
        .where((player) => !startingLineupIds.contains(player.id))
        .toList();
  }

  /// Calculate team rating based on starting lineup
  /// Uses position-adjusted ratings for more accurate team strength
  int get teamRating {
    if (startingLineup.isEmpty) return 0;

    final totalRating = startingLineup.fold<int>(
      0,
      (sum, player) => sum + player.positionAdjustedRating,
    );

    return (totalRating / startingLineup.length).round();
  }

  /// Convert Team to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'players': players.map((player) => player.toJson()).toList(),
      'startingLineupIds': startingLineupIds,
      if (rotationConfig != null) 'rotationConfig': rotationConfig!.toJson(),
    };
  }

  /// Create Team from JSON
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      players:
          (json['players'] as List)
              .map(
                (playerJson) =>
                    Player.fromJson(playerJson as Map<String, dynamic>),
              )
              .toList(),
      startingLineupIds: List<String>.from(json['startingLineupIds'] as List),
      rotationConfig: json['rotationConfig'] != null
          ? RotationConfig.fromJson(json['rotationConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Create a copy of the team with updated starting lineup
  Team copyWith({
    String? id,
    String? name,
    String? city,
    List<Player>? players,
    List<String>? startingLineupIds,
    RotationConfig? rotationConfig,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      players: players ?? this.players,
      startingLineupIds: startingLineupIds ?? this.startingLineupIds,
      rotationConfig: rotationConfig ?? this.rotationConfig,
    );
  }
}
