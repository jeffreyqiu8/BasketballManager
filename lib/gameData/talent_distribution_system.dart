import 'dart:math';
import 'enums.dart';
import 'player_generator.dart';
import 'development_system.dart';

/// Advanced talent distribution system for realistic player generation
class TalentDistributionSystem {
  static final Random _random = Random();

  // Realistic talent distribution curves based on NBA statistics
  static const Map<TalentTier, TalentDistributionCurve> _talentCurves = {
    TalentTier.superstar: TalentDistributionCurve(
      percentage: 0.02,
      attributeRange: AttributeRange(min: 85, max: 99, average: 92),
      potentialBias: 0.8, // 80% chance for elite/gold potential
    ),
    TalentTier.allStar: TalentDistributionCurve(
      percentage: 0.08,
      attributeRange: AttributeRange(min: 75, max: 95, average: 85),
      potentialBias: 0.6, // 60% chance for gold/silver potential
    ),
    TalentTier.starter: TalentDistributionCurve(
      percentage: 0.25,
      attributeRange: AttributeRange(min: 65, max: 85, average: 75),
      potentialBias: 0.4, // 40% chance for silver potential
    ),
    TalentTier.rotation: TalentDistributionCurve(
      percentage: 0.35,
      attributeRange: AttributeRange(min: 55, max: 75, average: 65),
      potentialBias: 0.2, // 20% chance for silver potential
    ),
    TalentTier.bench: TalentDistributionCurve(
      percentage: 0.30,
      attributeRange: AttributeRange(min: 45, max: 65, average: 55),
      potentialBias: 0.1, // 10% chance for silver potential
    ),
  };

  // Position-specific attribute specializations and ranges
  static const Map<PlayerRole, PositionSpecialization> _positionSpecs = {
    PlayerRole.pointGuard: PositionSpecialization(
      primaryAttributes: ['passing', 'ballHandling'],
      secondaryAttributes: ['perimeterDefense', 'shooting'],
      weakAttributes: ['rebounding', 'postDefense'],
      heightRange: HeightRange(min: 175, max: 195, average: 185),
      rareArchetypes: [
        PlayerArchetype.playmaker,
        PlayerArchetype.floorGeneral,
        PlayerArchetype.lockdownDefender,
      ],
    ),
    PlayerRole.shootingGuard: PositionSpecialization(
      primaryAttributes: ['shooting', 'perimeterDefense'],
      secondaryAttributes: ['ballHandling', 'passing'],
      weakAttributes: ['rebounding', 'postDefense'],
      heightRange: HeightRange(min: 185, max: 205, average: 195),
      rareArchetypes: [
        PlayerArchetype.eliteShooter,
        PlayerArchetype.lockdownDefender,
        PlayerArchetype.athleticFinisher,
      ],
    ),
    PlayerRole.smallForward: PositionSpecialization(
      primaryAttributes: ['shooting', 'rebounding'],
      secondaryAttributes: ['perimeterDefense', 'passing'],
      weakAttributes: ['postDefense'],
      heightRange: HeightRange(min: 195, max: 210, average: 203),
      rareArchetypes: [
        PlayerArchetype.eliteShooter,
        PlayerArchetype.defensiveSpecialist,
        PlayerArchetype.playmaker,
        PlayerArchetype.athleticFinisher,
      ],
    ),
    PlayerRole.powerForward: PositionSpecialization(
      primaryAttributes: ['rebounding', 'insideShooting'],
      secondaryAttributes: ['postDefense', 'shooting'],
      weakAttributes: ['ballHandling', 'passing'],
      heightRange: HeightRange(min: 200, max: 215, average: 208),
      rareArchetypes: [
        PlayerArchetype.stretchBig,
        PlayerArchetype.athleticFinisher,
        PlayerArchetype.defensiveSpecialist,
      ],
    ),
    PlayerRole.center: PositionSpecialization(
      primaryAttributes: ['rebounding', 'postDefense', 'insideShooting'],
      secondaryAttributes: ['perimeterDefense'],
      weakAttributes: ['ballHandling', 'passing', 'shooting'],
      heightRange: HeightRange(min: 205, max: 225, average: 213),
      rareArchetypes: [
        PlayerArchetype.stretchBig,
        PlayerArchetype.defensiveSpecialist,
        PlayerArchetype.athleticFinisher,
      ],
    ),
  };

  // Rare archetype generation probabilities
  static const Map<PlayerArchetype, double> _archetypeProbabilities = {
    PlayerArchetype.eliteShooter: 0.05,        // 5% - Elite 3-point shooters
    PlayerArchetype.defensiveSpecialist: 0.08,  // 8% - Lockdown defenders
    PlayerArchetype.playmaker: 0.04,           // 4% - Elite playmakers
    PlayerArchetype.athleticFinisher: 0.06,    // 6% - Athletic finishers
    PlayerArchetype.stretchBig: 0.03,          // 3% - Shooting big men
    PlayerArchetype.lockdownDefender: 0.05,    // 5% - Perimeter specialists
    PlayerArchetype.floorGeneral: 0.02,        // 2% - High IQ leaders
    PlayerArchetype.energizer: 0.10,           // 10% - High energy players
  };

  /// Generate talent tier based on realistic distribution curves
  static TalentTier generateTalentTier({bool isRookie = false}) {
    Map<TalentTier, double> distribution = isRookie 
        ? _getRookieDistribution() 
        : _getStandardDistribution();
    
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<TalentTier, double> entry in distribution.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }
    
    return TalentTier.bench; // Fallback
  }

  /// Generate potential tier with hidden potential system for rookies
  static PotentialTier generatePotentialTier(
    TalentTier talentTier, 
    int age, {
    bool isRookie = false,
    bool forceHidden = false,
  }) {
    // Age factor affects potential (younger = higher potential)
    double ageFactor = isRookie ? 1.2 : (30 - age) / 12.0;
    ageFactor = ageFactor.clamp(0.5, 1.5);
    
    // Strong correlation between talent tier and potential tier
    double random = _random.nextDouble();
    PotentialTier tier;
    
    switch (talentTier) {
      case TalentTier.superstar:
        if (random < 0.6) {
          tier = PotentialTier.elite;
        } else if (random < 0.9) {
          tier = PotentialTier.gold;
        } else {
          tier = PotentialTier.silver;
        }
        break;
      case TalentTier.allStar:
        if (random < 0.4) {
          tier = PotentialTier.gold;
        } else if (random < 0.8) {
          tier = PotentialTier.silver;
        } else {
          tier = PotentialTier.bronze;
        }
        break;
      case TalentTier.starter:
        if (random < 0.3) {
          tier = PotentialTier.silver;
        } else if (random < 0.7) {
          tier = PotentialTier.bronze;
        } else {
          tier = PotentialTier.silver;
        }
        break;
      case TalentTier.rotation:
        if (random < 0.2) {
          tier = PotentialTier.silver;
        } else {
          tier = PotentialTier.bronze;
        }
        break;
      case TalentTier.bench:
        if (random < 0.1) {
          tier = PotentialTier.silver;
        } else {
          tier = PotentialTier.bronze;
        }
        break;
    }
    
    // Age factor can boost potential for young players
    if (ageFactor > 1.1 && _random.nextDouble() < 0.3) {
      switch (tier) {
        case PotentialTier.bronze:
          tier = PotentialTier.silver;
          break;
        case PotentialTier.silver:
          tier = PotentialTier.gold;
          break;
        case PotentialTier.gold:
          tier = PotentialTier.elite;
          break;
        case PotentialTier.elite:
          break; // Already at max
      }
    }
    
    // Rookies have additional variance
    if (isRookie && _random.nextDouble() < 0.2) {
      // 20% chance to bump up potential tier for rookies
      switch (tier) {
        case PotentialTier.bronze:
          tier = PotentialTier.silver;
          break;
        case PotentialTier.silver:
          tier = PotentialTier.gold;
          break;
        case PotentialTier.gold:
          tier = PotentialTier.elite;
          break;
        case PotentialTier.elite:
          break; // Already at max
      }
    }
    
    return tier;
  }

  /// Generate rare player archetype based on position and probabilities
  static PlayerArchetype? generateRareArchetype(PlayerRole position) {
    PositionSpecialization spec = _positionSpecs[position]!;
    
    // Check if this player should have a rare archetype
    double archetypeChance = _random.nextDouble();
    if (archetypeChance > 0.15) return null; // 85% chance for no special archetype
    
    // Select from position-appropriate archetypes
    List<PlayerArchetype> availableArchetypes = spec.rareArchetypes;
    if (availableArchetypes.isEmpty) return null;
    
    // Weight by archetype probability
    List<WeightedArchetype> weightedArchetypes = [];
    for (PlayerArchetype archetype in availableArchetypes) {
      double weight = _archetypeProbabilities[archetype] ?? 0.01;
      weightedArchetypes.add(WeightedArchetype(archetype, weight));
    }
    
    // Select weighted random archetype
    double totalWeight = weightedArchetypes.fold(0.0, (sum, wa) => sum + wa.weight);
    double random = _random.nextDouble() * totalWeight;
    double cumulative = 0.0;
    
    for (WeightedArchetype wa in weightedArchetypes) {
      cumulative += wa.weight;
      if (random <= cumulative) {
        return wa.archetype;
      }
    }
    
    return availableArchetypes.first; // Fallback
  }

  /// Generate position-specific attribute ranges with specializations
  static Map<String, AttributeRange> generatePositionAttributeRanges(
    PlayerRole position,
    TalentTier talentTier,
  ) {
    PositionSpecialization spec = _positionSpecs[position]!;
    TalentDistributionCurve curve = _talentCurves[talentTier]!;
    
    Map<String, AttributeRange> ranges = {};
    
    // All basketball attributes
    List<String> allAttributes = [
      'shooting', 'rebounding', 'passing', 'ballHandling',
      'perimeterDefense', 'postDefense', 'insideShooting'
    ];
    
    for (String attribute in allAttributes) {
      AttributeRange baseRange = curve.attributeRange;
      
      if (spec.primaryAttributes.contains(attribute)) {
        // Primary attributes get significant boost
        ranges[attribute] = AttributeRange(
          min: (baseRange.min * 1.1).round(),
          max: (baseRange.max * 1.05).round(),
          average: (baseRange.average * 1.25).round(), // Increased boost
        );
      } else if (spec.secondaryAttributes.contains(attribute)) {
        // Secondary attributes get moderate boost
        ranges[attribute] = AttributeRange(
          min: (baseRange.min * 1.05).round(),
          max: baseRange.max,
          average: (baseRange.average * 1.12).round(), // Increased boost
        );
      } else if (spec.weakAttributes.contains(attribute)) {
        // Weak attributes get penalty
        ranges[attribute] = AttributeRange(
          min: (baseRange.min * 0.7).round(), // Increased penalty
          max: (baseRange.max * 0.85).round(),
          average: (baseRange.average * 0.65).round(), // Increased penalty
        );
      } else {
        // Neutral attributes use base range
        ranges[attribute] = baseRange;
      }
      
      // Ensure ranges stay within valid bounds and maintain order
      int clampedMin = ranges[attribute]!.min.clamp(30, 90);
      int clampedMax = ranges[attribute]!.max.clamp(50, 99);
      int clampedAverage = ranges[attribute]!.average.clamp(40, 95);
      
      // Ensure min <= average <= max
      clampedMin = clampedMin.clamp(30, clampedAverage);
      clampedMax = clampedMax.clamp(clampedAverage, 99);
      clampedAverage = clampedAverage.clamp(clampedMin, clampedMax);
      
      ranges[attribute] = AttributeRange(
        min: clampedMin,
        max: clampedMax,
        average: clampedAverage,
      );
    }
    
    return ranges;
  }

  /// Create rookie potential system with hidden ratings
  static RookiePotentialProfile generateRookiePotential(
    PlayerRole position,
    TalentTier projectedTier,
  ) {
    // Generate base potential
    PotentialTier potentialTier = generatePotentialTier(
      projectedTier, 
      20, // Assume 20 years old for rookies
      isRookie: true,
    );
    
    // Generate hidden potential variance
    double hiddenVariance = _random.nextDouble() * 0.3 - 0.15; // -15% to +15%
    
    // Generate development curve steepness
    double developmentRate = 0.8 + _random.nextDouble() * 0.6; // 0.8 to 1.4
    
    // Generate ceiling and floor projections
    int ceilingProjection = _calculateCeilingProjection(potentialTier, hiddenVariance);
    int floorProjection = _calculateFloorProjection(potentialTier, hiddenVariance);
    
    // Generate bust/boom probability
    double bustProbability = _calculateBustProbability(projectedTier);
    double boomProbability = _calculateBoomProbability(projectedTier);
    
    return RookiePotentialProfile(
      potentialTier: potentialTier,
      hiddenVariance: hiddenVariance,
      developmentRate: developmentRate,
      ceilingProjection: ceilingProjection,
      floorProjection: floorProjection,
      bustProbability: bustProbability,
      boomProbability: boomProbability,
      isHidden: true,
    );
  }

  /// Generate talent distribution for a draft class
  static List<TalentTier> generateDraftClassDistribution(int draftSize) {
    List<TalentTier> draftClass = [];
    
    // Use rookie distribution
    Map<TalentTier, double> distribution = _getRookieDistribution();
    
    for (int i = 0; i < draftSize; i++) {
      // Early picks have higher chance of better talent
      double pickBonus = (draftSize - i) / draftSize * 0.2; // Up to 20% bonus for early picks
      
      Map<TalentTier, double> adjustedDistribution = {};
      for (MapEntry<TalentTier, double> entry in distribution.entries) {
        double adjustedChance = entry.value;
        
        // Boost higher tiers for early picks
        if (entry.key == TalentTier.superstar || entry.key == TalentTier.allStar) {
          adjustedChance += pickBonus;
        } else if (entry.key == TalentTier.bench) {
          adjustedChance -= pickBonus * 0.5;
        }
        
        adjustedDistribution[entry.key] = adjustedChance.clamp(0.0, 1.0);
      }
      
      // Normalize distribution
      double total = adjustedDistribution.values.reduce((a, b) => a + b);
      adjustedDistribution.updateAll((key, value) => value / total);
      
      // Select talent tier
      double random = _random.nextDouble();
      double cumulative = 0.0;
      
      TalentTier selectedTier = TalentTier.bench;
      for (MapEntry<TalentTier, double> entry in adjustedDistribution.entries) {
        cumulative += entry.value;
        if (random <= cumulative) {
          selectedTier = entry.key;
          break;
        }
      }
      
      draftClass.add(selectedTier);
    }
    
    return draftClass;
  }

  /// Get standard talent distribution
  static Map<TalentTier, double> _getStandardDistribution() {
    return {
      TalentTier.superstar: 0.02,
      TalentTier.allStar: 0.08,
      TalentTier.starter: 0.25,
      TalentTier.rotation: 0.35,
      TalentTier.bench: 0.30,
    };
  }

  /// Get rookie-specific talent distribution (more variance)
  static Map<TalentTier, double> _getRookieDistribution() {
    return {
      TalentTier.superstar: 0.05,  // Higher chance for rookies
      TalentTier.allStar: 0.15,    // More potential stars
      TalentTier.starter: 0.30,    // Solid prospects
      TalentTier.rotation: 0.35,   // Role players
      TalentTier.bench: 0.15,      // Fewer guaranteed bench players
    };
  }

  /// Calculate ceiling projection for rookie
  static int _calculateCeilingProjection(PotentialTier tier, double variance) {
    Map<PotentialTier, int> baseCeilings = {
      PotentialTier.bronze: 75,
      PotentialTier.silver: 85,
      PotentialTier.gold: 92,
      PotentialTier.elite: 97,
    };
    
    int baseCeiling = baseCeilings[tier]!;
    return (baseCeiling + variance * 10).round().clamp(70, 99);
  }

  /// Calculate floor projection for rookie
  static int _calculateFloorProjection(PotentialTier tier, double variance) {
    Map<PotentialTier, int> baseFloors = {
      PotentialTier.bronze: 55,
      PotentialTier.silver: 65,
      PotentialTier.gold: 75,
      PotentialTier.elite: 80,
    };
    
    int baseFloor = baseFloors[tier]!;
    return (baseFloor + variance * 8).round().clamp(45, 85);
  }

  /// Calculate bust probability
  static double _calculateBustProbability(TalentTier tier) {
    Map<TalentTier, double> bustRates = {
      TalentTier.superstar: 0.05,  // 5% bust rate
      TalentTier.allStar: 0.15,    // 15% bust rate
      TalentTier.starter: 0.25,    // 25% bust rate
      TalentTier.rotation: 0.35,   // 35% bust rate
      TalentTier.bench: 0.50,      // 50% bust rate
    };
    
    return bustRates[tier]!;
  }

  /// Calculate boom probability (exceeding projections)
  static double _calculateBoomProbability(TalentTier tier) {
    Map<TalentTier, double> boomRates = {
      TalentTier.superstar: 0.20,  // 20% boom rate
      TalentTier.allStar: 0.15,    // 15% boom rate
      TalentTier.starter: 0.10,    // 10% boom rate
      TalentTier.rotation: 0.08,   // 8% boom rate
      TalentTier.bench: 0.05,      // 5% boom rate
    };
    
    return boomRates[tier]!;
  }
}

/// Talent distribution curve for each tier
class TalentDistributionCurve {
  final double percentage;
  final AttributeRange attributeRange;
  final double potentialBias;

  const TalentDistributionCurve({
    required this.percentage,
    required this.attributeRange,
    required this.potentialBias,
  });
}

/// Attribute range definition
class AttributeRange {
  final int min;
  final int max;
  final int average;

  const AttributeRange({
    required this.min,
    required this.max,
    required this.average,
  });
}

/// Position specialization definition
class PositionSpecialization {
  final List<String> primaryAttributes;
  final List<String> secondaryAttributes;
  final List<String> weakAttributes;
  final HeightRange heightRange;
  final List<PlayerArchetype> rareArchetypes;

  const PositionSpecialization({
    required this.primaryAttributes,
    required this.secondaryAttributes,
    required this.weakAttributes,
    required this.heightRange,
    required this.rareArchetypes,
  });
}

/// Height range for positions
class HeightRange {
  final int min;
  final int max;
  final int average;

  const HeightRange({
    required this.min,
    required this.max,
    required this.average,
  });
}

/// Weighted archetype for selection
class WeightedArchetype {
  final PlayerArchetype archetype;
  final double weight;

  WeightedArchetype(this.archetype, this.weight);
}

/// Rookie potential profile with hidden ratings
class RookiePotentialProfile {
  final PotentialTier potentialTier;
  final double hiddenVariance;
  final double developmentRate;
  final int ceilingProjection;
  final int floorProjection;
  final double bustProbability;
  final double boomProbability;
  final bool isHidden;

  RookiePotentialProfile({
    required this.potentialTier,
    required this.hiddenVariance,
    required this.developmentRate,
    required this.ceilingProjection,
    required this.floorProjection,
    required this.bustProbability,
    required this.boomProbability,
    required this.isHidden,
  });

  /// Convert to PlayerPotential for use in player generation
  PlayerPotential toPlayerPotential() {
    return PlayerPotential.fromTier(potentialTier, isHidden: isHidden);
  }
}