import '../models/player.dart';

/// Utility class for calculating position affinity scores
/// Position affinity indicates how well-suited a player is for each basketball position
/// based on their attributes and physical characteristics
class PositionAffinity {
  /// Calculate Point Guard (PG) affinity
  /// Weights: passing (40%), ballHandling (30%), speed (20%), height penalty
  /// Shorter players are better suited for PG
  static double calculatePGAffinity(Player player) {
    double baseScore = (player.passing * 0.4) +
        (player.ballHandling * 0.3) +
        (player.speed * 0.2);
    double heightPenalty = (player.heightInches - 72) * 0.5;
    return (baseScore - heightPenalty).clamp(0.0, 100.0);
  }

  /// Calculate Shooting Guard (SG) affinity
  /// Weights: shooting (35%), threePoint (35%), speed (20%), height bonus for 73-78"
  /// Ideal height range for shooting guards
  static double calculateSGAffinity(Player player) {
    double baseScore = (player.shooting * 0.35) +
        (player.threePoint * 0.35) +
        (player.speed * 0.2);
    double heightBonus =
        (player.heightInches >= 73 && player.heightInches <= 78) ? 10.0 : 0.0;
    return (baseScore + heightBonus).clamp(0.0, 100.0);
  }

  /// Calculate Small Forward (SF) affinity
  /// Weights: shooting (25%), defense (25%), athleticism (25%), height bonus for 76-80"
  /// Athleticism is calculated as average of speed and stamina
  static double calculateSFAffinity(Player player) {
    double athleticism = (player.speed + player.stamina) / 2.0;
    double baseScore = (player.shooting * 0.25) +
        (player.defense * 0.25) +
        (athleticism * 0.25);
    double heightBonus =
        (player.heightInches >= 76 && player.heightInches <= 80) ? 25.0 : 0.0;
    return (baseScore + heightBonus).clamp(0.0, 100.0);
  }

  /// Calculate Power Forward (PF) affinity
  /// Weights: rebounding (35%), defense (25%), shooting (20%), height bonus
  /// Taller players are better suited for PF
  static double calculatePFAffinity(Player player) {
    double baseScore = (player.rebounding * 0.35) +
        (player.defense * 0.25) +
        (player.shooting * 0.2);
    double heightBonus = (player.heightInches - 76) * 1.0;
    return (baseScore + heightBonus).clamp(0.0, 100.0);
  }

  /// Calculate Center (C) affinity
  /// Weights: rebounding (35%), blocks (30%), defense (25%), height bonus
  /// Tallest players are best suited for C
  static double calculateCAffinity(Player player) {
    double baseScore = (player.rebounding * 0.35) +
        (player.blocks * 0.3) +
        (player.defense * 0.25);
    double heightBonus = (player.heightInches - 78) * 1.5;
    return (baseScore + heightBonus).clamp(0.0, 100.0);
  }

  /// Calculate all position affinities for a player
  /// Returns a map with position abbreviations as keys and affinity scores (0-100) as values
  static Map<String, double> calculateAllAffinities(Player player) {
    return {
      'PG': calculatePGAffinity(player),
      'SG': calculateSGAffinity(player),
      'SF': calculateSFAffinity(player),
      'PF': calculatePFAffinity(player),
      'C': calculateCAffinity(player),
    };
  }
}
