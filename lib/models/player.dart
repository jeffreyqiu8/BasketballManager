import '../utils/position_affinity.dart';

/// Player model with 10 statistical attributes
/// Represents a basketball player in the game
class Player {
  final String id;
  final String name;
  final int heightInches; // Height in inches (e.g., 72 = 6'0")
  final int shooting; // 0-100: Mid-range and close-range shooting ability
  final int defense; // 0-100: Defensive capability
  final int speed; // 0-100: Movement speed and fast-break ability
  final int stamina; // 0-100: Endurance throughout the game
  final int passing; // 0-100: Assist and playmaking ability
  final int rebounding; // 0-100: Ability to secure rebounds
  final int ballHandling; // 0-100: Dribbling and turnover prevention
  final int threePoint; // 0-100: Long-range shooting ability
  final int blocks; // 0-100: Shot blocking ability
  final int steals; // 0-100: Ability to steal the ball from opponents
  final String position; // Position role: 'PG', 'SG', 'SF', 'PF', 'C'

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
    required this.blocks,
    required this.steals,
    required this.position,
  });

  /// Get height formatted as feet and inches (e.g., "6'2\"")
  String get heightFormatted {
    final feet = heightInches ~/ 12;
    final inches = heightInches % 12;
    return "$feet'$inches\"";
  }

  /// Calculate overall rating as average of all 10 stats
  int get overallRating {
    return ((shooting +
                defense +
                speed +
                stamina +
                passing +
                rebounding +
                ballHandling +
                threePoint +
                blocks +
                steals) /
            10)
        .round();
  }

  /// Calculate position-adjusted rating (0-100)
  /// Takes into account how well the player's attributes match their assigned position
  int get positionAdjustedRating {
    final baseRating = overallRating;
    final affinities = getPositionAffinities();
    final positionAffinity = affinities[position] ?? 50.0;
    
    // Affinity ranges from 0-100
    // If affinity is 100 (perfect fit), add up to +10 to rating
    // If affinity is 50 (neutral), no change
    // If affinity is 0 (poor fit), subtract up to -10 from rating
    final affinityBonus = ((positionAffinity - 50) / 5).round();
    
    // Clamp the result between 0 and 100
    return (baseRating + affinityBonus).clamp(0, 100);
  }

  /// Get star rating (1-5 stars) relative to team roster
  /// The best player on the team gets 5 stars, worst gets 1-2 stars
  /// Requires list of all team players for comparison
  double getStarRating(List<Player> teamPlayers) {
    if (teamPlayers.isEmpty) return 3.0;
    
    // Get all position-adjusted ratings for the team
    final ratings = teamPlayers.map((p) => p.positionAdjustedRating).toList();
    final myRating = positionAdjustedRating;
    
    // Find min and max ratings on the team
    final minRating = ratings.reduce((a, b) => a < b ? a : b);
    final maxRating = ratings.reduce((a, b) => a > b ? a : b);
    
    // If all players have same rating, return 3 stars
    if (maxRating == minRating) return 3.0;
    
    // Normalize rating to 0-1 scale relative to team
    final normalizedRating = (myRating - minRating) / (maxRating - minRating);
    
    // Map to 1-5 star scale
    // Bottom 20% of team: 1-2 stars
    // Next 20%: 2-3 stars
    // Middle 20%: 3-3.5 stars
    // Next 20%: 3.5-4.5 stars
    // Top 20%: 4.5-5 stars
    
    if (normalizedRating < 0.2) {
      return 1.0 + normalizedRating * 5.0; // 1.0 to 2.0
    } else if (normalizedRating < 0.4) {
      return 2.0 + (normalizedRating - 0.2) * 5.0; // 2.0 to 3.0
    } else if (normalizedRating < 0.6) {
      return 3.0 + (normalizedRating - 0.4) * 2.5; // 3.0 to 3.5
    } else if (normalizedRating < 0.8) {
      return 3.5 + (normalizedRating - 0.6) * 5.0; // 3.5 to 4.5
    } else {
      return 4.5 + (normalizedRating - 0.8) * 2.5; // 4.5 to 5.0
    }
  }

  /// Get star rating rounded to nearest half star (for display)
  /// Requires list of all team players for comparison
  double getStarRatingRounded(List<Player> teamPlayers) {
    final rating = getStarRating(teamPlayers);
    return (rating * 2).round() / 2; // Round to nearest 0.5
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
      'blocks': blocks,
      'steals': steals,
      'position': position,
    };
  }

  /// Create Player from JSON
  /// Handles backward compatibility for saves without blocks/steals/position attributes
  factory Player.fromJson(Map<String, dynamic> json) {
    // Calculate reasonable defaults based on existing attributes if blocks/steals are missing
    final int defaultBlocks = json['blocks'] as int? ?? 
        ((json['defense'] as int) * 0.6 + (json['rebounding'] as int) * 0.4).round();
    final int defaultSteals = json['steals'] as int? ?? 
        ((json['defense'] as int) * 0.7 + (json['speed'] as int) * 0.3).round();
    
    // Assign default position based on attributes if missing
    final String defaultPosition = json['position'] as String? ?? 
        _assignPositionBasedOnAttributes(
          json['heightInches'] as int,
          json['passing'] as int,
          json['ballHandling'] as int,
          json['shooting'] as int,
          json['threePoint'] as int,
          json['rebounding'] as int,
          defaultBlocks,
          json['defense'] as int,
          json['speed'] as int,
          json['stamina'] as int,
        );
    
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
      blocks: defaultBlocks,
      steals: defaultSteals,
      position: defaultPosition,
    );
  }

  /// Assign position based on player attributes and height
  /// Used for backward compatibility with saves that don't have position data
  static String _assignPositionBasedOnAttributes(
    int height,
    int passing,
    int ballHandling,
    int shooting,
    int threePoint,
    int rebounding,
    int blocks,
    int defense,
    int speed,
    int stamina,
  ) {
    // Calculate affinity scores for each position
    final pgScore = (passing * 0.4) + (ballHandling * 0.3) + (speed * 0.2) - ((height - 72) * 0.5);
    final sgScore = (shooting * 0.35) + (threePoint * 0.35) + (speed * 0.2) + 
                    ((height >= 73 && height <= 78) ? 10 : 0);
    final athleticism = (speed + stamina) / 2;
    final sfScore = (shooting * 0.25) + (defense * 0.25) + (athleticism * 0.25) + 
                    ((height >= 76 && height <= 80) ? 25 : 0);
    final pfScore = (rebounding * 0.35) + (defense * 0.25) + (shooting * 0.2) + ((height - 76) * 1.0);
    final cScore = (rebounding * 0.35) + (blocks * 0.3) + (defense * 0.25) + ((height - 78) * 1.5);
    
    // Find position with highest affinity
    final scores = {
      'PG': pgScore,
      'SG': sgScore,
      'SF': sfScore,
      'PF': pfScore,
      'C': cScore,
    };
    
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Create a copy of this Player with a new position
  Player copyWithPosition(String newPosition) {
    return Player(
      id: id,
      name: name,
      heightInches: heightInches,
      shooting: shooting,
      defense: defense,
      speed: speed,
      stamina: stamina,
      passing: passing,
      rebounding: rebounding,
      ballHandling: ballHandling,
      threePoint: threePoint,
      blocks: blocks,
      steals: steals,
      position: newPosition,
    );
  }

  /// Get position affinity scores for all five positions
  /// Returns a map with position abbreviations as keys and affinity scores (0-100) as values
  /// Higher scores indicate better fit for that position
  Map<String, double> getPositionAffinities() {
    return PositionAffinity.calculateAllAffinities(this);
  }
}
