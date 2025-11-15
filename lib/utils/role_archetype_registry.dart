import '../models/role_archetype.dart';

/// Registry for all role archetypes in the game
/// Manages the collection of specialized roles for each position
class RoleArchetypeRegistry {
  // Private constructor to prevent instantiation
  RoleArchetypeRegistry._();

  /// All role archetypes organized by position
  static final Map<String, List<RoleArchetype>> _archetypesByPosition = {
    'PG': _pointGuardArchetypes,
    'SG': _shootingGuardArchetypes,
    'SF': _smallForwardArchetypes,
    'PF': _powerForwardArchetypes,
    'C': _centerArchetypes,
  };

  // ==================== POINT GUARD ARCHETYPES ====================

  static final List<RoleArchetype> _pointGuardArchetypes = [
    const RoleArchetype(
      id: 'pg_allaround',
      name: 'All-Around PG',
      position: 'PG',
      attributeWeights: {
        'passing': 0.25,
        'shooting': 0.20,
        'ballHandling': 0.25,
        'speed': 0.20,
        'threePoint': 0.10,
      },
      gameplayModifiers: {}, // Standard PG modifiers
    ),
    const RoleArchetype(
      id: 'pg_floor_general',
      name: 'Floor General',
      position: 'PG',
      attributeWeights: {
        'passing': 0.45,
        'ballHandling': 0.30,
        'speed': 0.15,
        'defense': 0.10,
      },
      gameplayModifiers: {
        'assistProbability': 1.20,
        'shotAttemptProbability': 0.85,
      },
    ),
    const RoleArchetype(
      id: 'pg_slashing_playmaker',
      name: 'Slashing Playmaker',
      position: 'PG',
      attributeWeights: {
        'postShooting': 0.35,
        'speed': 0.25,
        'ballHandling': 0.20,
        'passing': 0.20,
      },
      gameplayModifiers: {
        'postShootingAttemptProbability': 1.25,
        'threePointAttemptProbability': 0.80,
      },
    ),
    const RoleArchetype(
      id: 'pg_offensive_point',
      name: 'Offensive Point',
      position: 'PG',
      attributeWeights: {
        'shooting': 0.35,
        'threePoint': 0.30,
        'passing': 0.20,
        'ballHandling': 0.15,
      },
      gameplayModifiers: {
        'shotAttemptProbability': 1.15,
        'assistProbability': 0.90,
      },
    ),
  ];

  // ==================== SHOOTING GUARD ARCHETYPES ====================

  static final List<RoleArchetype> _shootingGuardArchetypes = [
    const RoleArchetype(
      id: 'sg_three_level_scorer',
      name: 'Three-Level Scorer',
      position: 'SG',
      attributeWeights: {
        'shooting': 0.35,
        'threePoint': 0.30,
        'ballHandling': 0.25,
        'speed': 0.10,
      },
      gameplayModifiers: {
        'shotCreationProbability': 1.20,
        'assistProbability': 0.85,
      },
    ),
    const RoleArchetype(
      id: 'sg_3_and_d',
      name: '3-and-D',
      position: 'SG',
      attributeWeights: {
        'threePoint': 0.40,
        'defense': 0.30,
        'steals': 0.20,
        'shooting': 0.10,
      },
      gameplayModifiers: {
        'threePointAttemptProbability': 1.30,
        'stealProbability': 1.25,
        'defensiveImpact': 1.20,
      },
    ),
    const RoleArchetype(
      id: 'sg_microwave_shooter',
      name: 'Microwave Shooter',
      position: 'SG',
      attributeWeights: {
        'shooting': 0.45,
        'threePoint': 0.40,
        'speed': 0.10,
        'defense': 0.05,
      },
      gameplayModifiers: {
        'catchAndShootProbability': 1.35,
        'ballHandlingUsage': 0.75,
      },
    ),
  ];

  // ==================== SMALL FORWARD ARCHETYPES ====================

  static final List<RoleArchetype> _smallForwardArchetypes = [
    const RoleArchetype(
      id: 'sf_point_forward',
      name: 'Point Forward',
      position: 'SF',
      attributeWeights: {
        'passing': 0.35,
        'ballHandling': 0.25,
        'shooting': 0.20,
        'speed': 0.20,
      },
      gameplayModifiers: {
        'assistProbability': 1.25,
        'postShootingAttemptProbability': 0.80,
      },
    ),
    const RoleArchetype(
      id: 'sf_3_and_d_wing',
      name: '3-and-D Wing',
      position: 'SF',
      attributeWeights: {
        'threePoint': 0.30,
        'defense': 0.25,
        'steals': 0.20,
        'blocks': 0.15,
        'rebounding': 0.10,
      },
      gameplayModifiers: {
        'threePointAttemptProbability': 1.25,
        'stealProbability': 1.20,
        'blockProbability': 1.15,
        'reboundProbability': 1.10,
      },
    ),
    const RoleArchetype(
      id: 'sf_athletic_finisher',
      name: 'Athletic Finisher',
      position: 'SF',
      attributeWeights: {
        'postShooting': 0.40,
        'speed': 0.25,
        'rebounding': 0.20,
        'defense': 0.15,
      },
      gameplayModifiers: {
        'postShootingAttemptProbability': 1.30,
        'threePointAttemptProbability': 0.70,
      },
    ),
  ];

  // ==================== POWER FORWARD ARCHETYPES ====================

  static final List<RoleArchetype> _powerForwardArchetypes = [
    const RoleArchetype(
      id: 'pf_playmaking_big',
      name: 'Playmaking Big',
      position: 'PF',
      attributeWeights: {
        'passing': 0.35,
        'rebounding': 0.30,
        'postShooting': 0.20,
        'defense': 0.15,
      },
      gameplayModifiers: {
        'assistProbability': 1.20,
        'threePointAttemptProbability': 0.75,
      },
    ),
    const RoleArchetype(
      id: 'pf_stretch_four',
      name: 'Stretch Four',
      position: 'PF',
      attributeWeights: {
        'threePoint': 0.35,
        'shooting': 0.30,
        'rebounding': 0.25,
        'defense': 0.10,
      },
      gameplayModifiers: {
        'threePointAttemptProbability': 1.25,
      },
    ),
    const RoleArchetype(
      id: 'pf_rim_runner',
      name: 'Rim Runner',
      position: 'PF',
      attributeWeights: {
        'postShooting': 0.40,
        'rebounding': 0.35,
        'blocks': 0.20,
        'speed': 0.05,
      },
      gameplayModifiers: {
        'postShootingAttemptProbability': 1.35,
        'reboundProbability': 1.20,
        'threePointAttemptProbability': 0.10,
      },
    ),
  ];

  // ==================== CENTER ARCHETYPES ====================

  static final List<RoleArchetype> _centerArchetypes = [
    const RoleArchetype(
      id: 'c_paint_beast',
      name: 'Paint Beast',
      position: 'C',
      attributeWeights: {
        'postShooting': 0.35,
        'blocks': 0.30,
        'rebounding': 0.25,
        'defense': 0.10,
      },
      gameplayModifiers: {
        'postShootingAttemptProbability': 1.30,
        'blockProbability': 1.35,
        'threePointAttemptProbability': 0.0,
      },
    ),
    const RoleArchetype(
      id: 'c_stretch_five',
      name: 'Stretch Five',
      position: 'C',
      attributeWeights: {
        'threePoint': 0.35,
        'shooting': 0.25,
        'rebounding': 0.25,
        'defense': 0.15,
      },
      gameplayModifiers: {
        'threePointAttemptProbability': 1.30,
        'reboundProbability': 1.0,
      },
    ),
    const RoleArchetype(
      id: 'c_standard_center',
      name: 'Standard Center',
      position: 'C',
      attributeWeights: {
        'rebounding': 0.30,
        'postShooting': 0.25,
        'blocks': 0.25,
        'defense': 0.20,
      },
      gameplayModifiers: {
        'postShootingAttemptProbability': 1.15,
        'reboundProbability': 1.15,
        'blockProbability': 1.15,
      },
    ),
  ];

  // ==================== PUBLIC METHODS ====================

  /// Get all role archetypes for a specific position
  /// Returns an empty list if position is invalid
  static List<RoleArchetype> getArchetypesForPosition(String position) {
    return _archetypesByPosition[position] ?? [];
  }

  /// Get a specific role archetype by its ID
  /// Returns null if archetype is not found
  static RoleArchetype? getArchetypeById(String id) {
    for (final archetypes in _archetypesByPosition.values) {
      for (final archetype in archetypes) {
        if (archetype.id == id) return archetype;
      }
    }
    return null;
  }

  /// Get all role archetypes across all positions
  static List<RoleArchetype> getAllArchetypes() {
    return _archetypesByPosition.values.expand((list) => list).toList();
  }

  /// Get all position abbreviations that have archetypes
  static List<String> getAllPositions() {
    return _archetypesByPosition.keys.toList();
  }
}
