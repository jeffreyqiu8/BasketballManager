import 'player.dart';

/// Team model with 15-player roster and starting lineup management
/// Represents a basketball team in the league
class Team {
  final String id;
  final String name;
  final String city;
  final List<Player> players; // Always 15 players
  final List<String> startingLineupIds; // 5 player IDs

  Team({
    required this.id,
    required this.name,
    required this.city,
    required this.players,
    required this.startingLineupIds,
  }) : assert(players.length == 15, 'Team must have exactly 15 players'),
       assert(
         startingLineupIds.length == 5,
         'Starting lineup must have exactly 5 players',
       );

  /// Get the starting lineup players
  List<Player> get startingLineup {
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
  int get teamRating {
    if (startingLineup.isEmpty) return 0;

    final totalRating = startingLineup.fold<int>(
      0,
      (sum, player) => sum + player.overallRating,
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
    );
  }

  /// Create a copy of the team with updated starting lineup
  Team copyWith({
    String? id,
    String? name,
    String? city,
    List<Player>? players,
    List<String>? startingLineupIds,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      players: players ?? this.players,
      startingLineupIds: startingLineupIds ?? this.startingLineupIds,
    );
  }
}
