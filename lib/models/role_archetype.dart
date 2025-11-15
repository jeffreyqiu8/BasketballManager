import 'player.dart';

/// Represents a specialized role archetype within a basketball position
/// Each archetype emphasizes different attributes and affects gameplay differently
class RoleArchetype {
  final String id;
  final String name;
  final String position; // 'PG', 'SG', 'SF', 'PF', or 'C'
  final Map<String, double> attributeWeights; // attribute name -> weight (0-1)
  final Map<String, double> gameplayModifiers; // modifier type -> multiplier

  const RoleArchetype({
    required this.id,
    required this.name,
    required this.position,
    required this.attributeWeights,
    required this.gameplayModifiers,
  });

  /// Calculate how well a player fits this role archetype
  /// Returns a score from 0-100 based on weighted player attributes
  double calculateFitScore(Player player) {
    double score = 0.0;
    double totalWeight = 0.0;

    attributeWeights.forEach((attribute, weight) {
      final int attributeValue = _getPlayerAttribute(player, attribute);
      score += attributeValue * weight;
      totalWeight += weight;
    });

    // Normalize to 0-100 scale
    if (totalWeight == 0) return 0.0;
    return (score / totalWeight).clamp(0.0, 100.0);
  }

  /// Get the value of a specific attribute from a player
  int _getPlayerAttribute(Player player, String attribute) {
    switch (attribute) {
      case 'shooting':
        return player.shooting;
      case 'threePoint':
        return player.threePoint;
      case 'passing':
        return player.passing;
      case 'ballHandling':
        return player.ballHandling;
      case 'postShooting':
        return player.postShooting;
      case 'defense':
        return player.defense;
      case 'steals':
        return player.steals;
      case 'blocks':
        return player.blocks;
      case 'rebounding':
        return player.rebounding;
      case 'speed':
        return player.speed;
      default:
        return 0;
    }
  }
}
