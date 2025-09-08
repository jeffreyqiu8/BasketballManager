import 'enums.dart';
import 'player_class.dart';

/// Manages player role assignments, compatibility calculations, and role-based bonuses
class RoleManager {
  /// Attribute weights for each player role (importance multipliers)
  static const Map<PlayerRole, Map<String, double>> roleWeights = {
    PlayerRole.pointGuard: {
      'ballHandling': 2.0,
      'passing': 2.0,
      'shooting': 1.2,
      'perimeterDefense': 1.3,
      'height': 1.0,
    },
    PlayerRole.shootingGuard: {
      'shooting': 2.0,
      'ballHandling': 1.3,
      'perimeterDefense': 1.5,
      'passing': 1.0,
      'height': 1.0,
    },
    PlayerRole.smallForward: {
      'shooting': 1.5,
      'perimeterDefense': 1.5,
      'rebounding': 1.3,
      'ballHandling': 1.2,
      'height': 1.0,
    },
    PlayerRole.powerForward: {
      'rebounding': 2.0,
      'insideShooting': 1.5,
      'postDefense': 1.8,
      'shooting': 1.0,
      'height': 1.2,
    },
    PlayerRole.center: {
      'rebounding': 2.5,
      'postDefense': 2.5,
      'insideShooting': 2.0,
      'perimeterDefense': 0.3,
      'height': 2.0,
    },
  };

  /// Attribute requirements for each player role (minimum recommended values)
  static const Map<PlayerRole, Map<String, int>> roleRequirements = {
    PlayerRole.pointGuard: {
      'ballHandling': 70,
      'passing': 75,
      'shooting': 60,
      'perimeterDefense': 65,
      'height': 185, // cm
    },
    PlayerRole.shootingGuard: {
      'shooting': 80,
      'ballHandling': 65,
      'perimeterDefense': 70,
      'passing': 55,
      'height': 195, // cm
    },
    PlayerRole.smallForward: {
      'shooting': 70,
      'perimeterDefense': 70,
      'rebounding': 60,
      'ballHandling': 60,
      'height': 200, // cm
    },
    PlayerRole.powerForward: {
      'rebounding': 75,
      'insideShooting': 65,
      'postDefense': 70,
      'shooting': 55,
      'height': 205, // cm
    },
    PlayerRole.center: {
      'rebounding': 90,
      'postDefense': 85,
      'insideShooting': 80,
      'perimeterDefense': 25,
      'height': 218, // cm
    },
  };

  /// Performance bonuses applied when player plays in their optimal role
  static const Map<PlayerRole, Map<String, double>> roleBonuses = {
    PlayerRole.pointGuard: {
      'passing': 1.15,
      'ballHandling': 1.10,
      'assists': 1.20,
      'turnovers': 0.85, // fewer turnovers
    },
    PlayerRole.shootingGuard: {
      'shooting': 1.15,
      'threePointShooting': 1.20,
      'points': 1.10,
      'steals': 1.05,
    },
    PlayerRole.smallForward: {
      'shooting': 1.08,
      'rebounding': 1.05,
      'versatility': 1.15,
      'steals': 1.10,
    },
    PlayerRole.powerForward: {
      'rebounding': 1.15,
      'insideShooting': 1.12,
      'blocks': 1.08,
      'postDefense': 1.10,
    },
    PlayerRole.center: {
      'rebounding': 1.20,
      'blocks': 1.25,
      'insideShooting': 1.15,
      'postDefense': 1.15,
    },
  };

  /// Performance penalties applied when player plays significantly out of position
  static const Map<PlayerRole, Map<String, double>> outOfPositionPenalties = {
    PlayerRole.pointGuard: {
      'rebounding': 0.70,
      'insideShooting': 0.75,
      'blocks': 0.60,
    },
    PlayerRole.shootingGuard: {
      'rebounding': 0.80,
      'assists': 0.85,
      'blocks': 0.70,
    },
    PlayerRole.smallForward: {
      'assists': 0.90,
      'blocks': 0.85,
    },
    PlayerRole.powerForward: {
      'assists': 0.75,
      'ballHandling': 0.80,
      'threePointShooting': 0.85,
    },
    PlayerRole.center: {
      'assists': 0.65,
      'ballHandling': 0.70,
      'threePointShooting': 0.75,
      'steals': 0.80,
    },
  };

  /// Calculate how compatible a player is with a specific role (0.0 to 1.0)
  static double calculateRoleCompatibility(Player player, PlayerRole role) {
    final requirements = roleRequirements[role]!;
    final weights = roleWeights[role]!;
    double totalWeightedCompatibility = 0.0;
    double totalWeight = 0.0;

    // Check each attribute requirement
    for (final entry in requirements.entries) {
      final attribute = entry.key;
      final requiredValue = entry.value;
      final weight = weights[attribute] ?? 1.0;
      
      double playerValue = 0.0;
      
      // Get player's attribute value
      switch (attribute) {
        case 'ballHandling':
          playerValue = player.ballHandling.toDouble();
          break;
        case 'passing':
          playerValue = player.passing.toDouble();
          break;
        case 'shooting':
          playerValue = player.shooting.toDouble();
          break;
        case 'perimeterDefense':
          playerValue = player.perimeterDefense.toDouble();
          break;
        case 'rebounding':
          playerValue = player.rebounding.toDouble();
          break;
        case 'insideShooting':
          playerValue = player.insideShooting.toDouble();
          break;
        case 'postDefense':
          playerValue = player.postDefense.toDouble();
          break;
        case 'height':
          playerValue = player.height.toDouble();
          break;
        default:
          continue; // Skip unknown attributes
      }

      // Calculate compatibility for this attribute (0.0 to 1.0)
      double attributeCompatibility;
      if (attribute == 'height') {
        // Height compatibility uses a different calculation
        attributeCompatibility = _calculateHeightCompatibility(playerValue, requiredValue.toDouble());
      } else {
        // Skill attributes: 1.0 if meets requirement, scaled down if below
        attributeCompatibility = (playerValue / requiredValue).clamp(0.0, 1.0);
        // Bonus for exceeding requirements (up to 1.15x)
        if (playerValue > requiredValue) {
          attributeCompatibility = (1.0 + (playerValue - requiredValue) / (100 - requiredValue) * 0.15).clamp(0.0, 1.15);
        }
      }

      totalWeightedCompatibility += attributeCompatibility * weight;
      totalWeight += weight;
    }

    // Return weighted average compatibility across all attributes
    return totalWeight > 0 ? (totalWeightedCompatibility / totalWeight).clamp(0.0, 1.0) : 0.0;
  }

  /// Calculate height compatibility for a role
  static double _calculateHeightCompatibility(double playerHeight, double idealHeight) {
    const double heightTolerance = 10.0; // cm tolerance
    final double heightDifference = (playerHeight - idealHeight).abs();
    
    if (heightDifference <= heightTolerance) {
      return 1.0; // Perfect height match
    } else {
      // Gradual decrease in compatibility as height difference increases
      return (1.0 - (heightDifference - heightTolerance) / 30.0).clamp(0.3, 1.0);
    }
  }

  /// Get the best role for a player based on compatibility scores
  static PlayerRole getBestRole(Player player) {
    PlayerRole bestRole = PlayerRole.pointGuard;
    double bestCompatibility = 0.0;

    for (final role in PlayerRole.values) {
      final compatibility = calculateRoleCompatibility(player, role);
      if (compatibility > bestCompatibility) {
        bestCompatibility = compatibility;
        bestRole = role;
      }
    }

    return bestRole;
  }

  /// Get compatibility scores for all roles for a player
  static Map<PlayerRole, double> getAllRoleCompatibilities(Player player) {
    final Map<PlayerRole, double> compatibilities = {};
    
    for (final role in PlayerRole.values) {
      compatibilities[role] = calculateRoleCompatibility(player, role);
    }

    return compatibilities;
  }

  /// Get role-based performance bonuses for a player in a specific role
  static Map<String, double> getRoleBonuses(Player player, PlayerRole role) {
    final compatibility = calculateRoleCompatibility(player, role);
    final baseBonuses = roleBonuses[role] ?? {};
    final Map<String, double> adjustedBonuses = {};

    // Apply bonuses based on compatibility level
    for (final entry in baseBonuses.entries) {
      final bonusKey = entry.key;
      final bonusValue = entry.value;
      
      // Scale bonus based on compatibility (minimum 50% of bonus at 0 compatibility)
      final scaledBonus = 1.0 + (bonusValue - 1.0) * (0.5 + compatibility * 0.5);
      adjustedBonuses[bonusKey] = scaledBonus;
    }

    return adjustedBonuses;
  }

  /// Get out-of-position penalties for a player playing a mismatched role
  static Map<String, double> getOutOfPositionPenalties(Player player, PlayerRole assignedRole) {
    final compatibility = calculateRoleCompatibility(player, assignedRole);
    
    // Only apply penalties if compatibility is below threshold
    if (compatibility >= 0.7) {
      return {}; // No penalties for good compatibility
    }

    final basePenalties = outOfPositionPenalties[assignedRole] ?? {};
    final Map<String, double> adjustedPenalties = {};

    // Apply penalties based on how poor the compatibility is
    final penaltyMultiplier = (0.7 - compatibility) / 0.7; // 0.0 to 1.0

    for (final entry in basePenalties.entries) {
      final penaltyKey = entry.key;
      final penaltyValue = entry.value;
      
      // Scale penalty based on compatibility (worse compatibility = stronger penalty)
      final scaledPenalty = 1.0 - (1.0 - penaltyValue) * penaltyMultiplier;
      adjustedPenalties[penaltyKey] = scaledPenalty;
    }

    return adjustedPenalties;
  }

  /// Validate that a starting lineup has all required positions filled
  static bool validateLineup(List<Player> players, List<PlayerRole> assignedRoles) {
    if (players.length != 5 || assignedRoles.length != 5) {
      return false;
    }

    // Check that all five positions are represented
    final Set<PlayerRole> requiredPositions = PlayerRole.values.toSet();
    final Set<PlayerRole> assignedPositions = assignedRoles.toSet();

    return assignedPositions.containsAll(requiredPositions);
  }

  /// Get recommended role assignments for a list of players
  static List<PlayerRole> getOptimalLineup(List<Player> players) {
    if (players.length != 5) {
      throw ArgumentError('Lineup must contain exactly 5 players');
    }

    // Calculate compatibility matrix
    final List<List<double>> compatibilityMatrix = [];
    for (int i = 0; i < players.length; i++) {
      final List<double> playerCompatibilities = [];
      for (final role in PlayerRole.values) {
        playerCompatibilities.add(calculateRoleCompatibility(players[i], role));
      }
      compatibilityMatrix.add(playerCompatibilities);
    }

    // Simple greedy assignment (can be improved with Hungarian algorithm)
    final List<PlayerRole> assignments = List.filled(5, PlayerRole.pointGuard);
    final List<bool> roleAssigned = List.filled(5, false);
    final List<bool> playerAssigned = List.filled(5, false);

    // Assign roles greedily based on highest compatibility
    for (int round = 0; round < 5; round++) {
      double bestCompatibility = -1.0;
      int bestPlayer = -1;
      int bestRole = -1;

      for (int player = 0; player < 5; player++) {
        if (playerAssigned[player]) continue;
        
        for (int role = 0; role < 5; role++) {
          if (roleAssigned[role]) continue;
          
          if (compatibilityMatrix[player][role] > bestCompatibility) {
            bestCompatibility = compatibilityMatrix[player][role];
            bestPlayer = player;
            bestRole = role;
          }
        }
      }

      if (bestPlayer >= 0 && bestRole >= 0) {
        assignments[bestPlayer] = PlayerRole.values[bestRole];
        playerAssigned[bestPlayer] = true;
        roleAssigned[bestRole] = true;
      }
    }

    return assignments;
  }
}