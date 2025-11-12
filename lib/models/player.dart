/// Player model with 8 statistical attributes
/// Represents a basketball player in the game
class Player {
  final String id;
  final String name;
  final int heightInches; // Height in inches (e.g., 72 = 6'0")
  final int shooting; // 0-100: Mid-range and close-range shooting ability
  final int defense; // 0-100: Defensive capability and steal potential
  final int speed; // 0-100: Movement speed and fast-break ability
  final int stamina; // 0-100: Endurance throughout the game
  final int passing; // 0-100: Assist and playmaking ability
  final int rebounding; // 0-100: Ability to secure rebounds
  final int ballHandling; // 0-100: Dribbling and turnover prevention
  final int threePoint; // 0-100: Long-range shooting ability

  Player({
    required this.id,
    required this.name,
    required this.heightInches,
    required this.shooting,
    required this.defense,
    required this.speed,
    required this.stamina,
    required this.passing,
    required this.rebounding,
    required this.ballHandling,
    required this.threePoint,
  });

  /// Get height formatted as feet and inches (e.g., "6'2\"")
  String get heightFormatted {
    final feet = heightInches ~/ 12;
    final inches = heightInches % 12;
    return "$feet'$inches\"";
  }

  /// Calculate overall rating as average of all 8 stats
  int get overallRating {
    return ((shooting +
                defense +
                speed +
                stamina +
                passing +
                rebounding +
                ballHandling +
                threePoint) /
            8)
        .round();
  }

  /// Convert Player to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'heightInches': heightInches,
      'shooting': shooting,
      'defense': defense,
      'speed': speed,
      'stamina': stamina,
      'passing': passing,
      'rebounding': rebounding,
      'ballHandling': ballHandling,
      'threePoint': threePoint,
    };
  }

  /// Create Player from JSON
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      heightInches: json['heightInches'] as int,
      shooting: json['shooting'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      stamina: json['stamina'] as int,
      passing: json['passing'] as int,
      rebounding: json['rebounding'] as int,
      ballHandling: json['ballHandling'] as int,
      threePoint: json['threePoint'] as int,
    );
  }
}
