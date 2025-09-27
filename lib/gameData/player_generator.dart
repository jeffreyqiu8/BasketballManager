import 'dart:math';
import 'enhanced_player.dart';
import 'enums.dart';
import 'development_system.dart';
import 'role_manager.dart';
import 'talent_distribution_system.dart';

/// Advanced player generator with realistic attribute generation and talent distribution
class PlayerGenerator {
  static final Random _random = Random();
  
  // Nationality distributions based on NBA demographics
  static const Map<String, double> _nationalityWeights = {
    'USA': 0.75,
    'Canada': 0.05,
    'France': 0.03,
    'Germany': 0.02,
    'Australia': 0.02,
    'Spain': 0.02,
    'Serbia': 0.015,
    'Greece': 0.015,
    'Lithuania': 0.01,
    'Croatia': 0.01,
    'Slovenia': 0.01,
    'Turkey': 0.01,
    'Brazil': 0.01,
    'Argentina': 0.01,
    'Nigeria': 0.01,
    'Cameroon': 0.005,
    'Other': 0.035,
  };

  // Talent tier distribution for realistic player generation
  static const Map<TalentTier, double> _talentDistribution = {
    TalentTier.superstar: 0.02,    // 2% - Generational talents
    TalentTier.allStar: 0.08,      // 8% - All-Star level players
    TalentTier.starter: 0.25,      // 25% - Solid starters
    TalentTier.rotation: 0.35,     // 35% - Rotation players
    TalentTier.bench: 0.30,        // 30% - Bench/role players
  };

  /// Generate a realistic player with advanced attribute generation
  static EnhancedPlayer generateRealisticPlayer({
    required PlayerRole primaryRole,
    required int age,
    String? nationality,
    TalentTier? talentTier,
    PotentialTier? potentialTier,
    String? teamName,
    Set<String>? usedNames,
  }) {
    // Determine nationality if not provided
    nationality ??= _selectRandomNationality();
    
    // Determine talent tier if not provided
    talentTier ??= _selectTalentTier();
    
    // Determine potential tier based on age and talent
    potentialTier ??= _determinePotentialTier(age, talentTier);
    
    // Generate unique name
    String name = _generateUniqueName(nationality, usedNames ?? {});
    
    // Generate physical attributes
    PhysicalAttributes physical = _generatePhysicalAttributes(primaryRole);
    
    // Generate skill attributes based on role, age, and talent
    Map<String, int> attributes = _generateRoleBasedAttributes(
      primaryRole, 
      talentTier, 
      age
    );
    
    // Generate potential
    PlayerPotential potential = _generatePlayerPotential(
      age, 
      potentialTier, 
      primaryRole
    );
    
    // Generate development tracker
    DevelopmentTracker development = DevelopmentTracker.initial(age: age);
    
    // Calculate experience years
    int experienceYears = _calculateExperienceYears(age);
    
    return EnhancedPlayer(
      name: name,
      age: age,
      team: teamName ?? 'Free Agent',
      experienceYears: experienceYears,
      nationality: nationality,
      currentStatus: 'Active',
      height: physical.height,
      shooting: attributes['shooting']!,
      rebounding: attributes['rebounding']!,
      passing: attributes['passing']!,
      ballHandling: attributes['ballHandling']!,
      perimeterDefense: attributes['perimeterDefense']!,
      postDefense: attributes['postDefense']!,
      insideShooting: attributes['insideShooting']!,
      performances: {},
      primaryRole: primaryRole,
      potential: potential,
      development: development,
    );
  }

  /// Generate a draft prospect with rookie potential
  static EnhancedPlayer generateDraftProspect({
    required PlayerRole primaryRole,
    String? nationality,
    TalentTier? projectedTier,
    Set<String>? usedNames,
  }) {
    // Draft prospects are typically 18-22 years old
    int age = 18 + _random.nextInt(5);
    
    // Rookies have higher potential variance
    TalentTier talentTier = projectedTier ?? _selectRookieTalentTier();
    PotentialTier potentialTier = _selectRookiePotentialTier(talentTier);
    
    return generateRealisticPlayer(
      primaryRole: primaryRole,
      age: age,
      nationality: nationality,
      talentTier: talentTier,
      potentialTier: potentialTier,
      teamName: 'Draft Prospect',
      usedNames: usedNames,
    );
  }

  /// Generate a player with specific archetype (elite shooter, defensive specialist, etc.)
  static EnhancedPlayer generateArchetypePlayer({
    required PlayerRole primaryRole,
    required PlayerArchetype archetype,
    required int age,
    String? nationality,
    Set<String>? usedNames,
  }) {
    nationality ??= _selectRandomNationality();
    String name = _generateUniqueName(nationality, usedNames ?? {});
    
    // Generate base attributes
    TalentTier baseTier = _selectTalentTier();
    Map<String, int> attributes = _generateRoleBasedAttributes(primaryRole, baseTier, age);
    
    // Apply archetype specializations
    attributes = _applyArchetypeModifications(attributes, archetype);
    
    // Generate potential with archetype considerations
    PotentialTier potentialTier = _determinePotentialTier(age, baseTier);
    PlayerPotential potential = _generateArchetypePotential(
      age, 
      potentialTier, 
      primaryRole, 
      archetype
    );
    
    PhysicalAttributes physical = _generatePhysicalAttributes(primaryRole);
    DevelopmentTracker development = DevelopmentTracker.initial(age: age);
    
    return EnhancedPlayer(
      name: name,
      age: age,
      team: 'Free Agent',
      experienceYears: _calculateExperienceYears(age),
      nationality: nationality,
      currentStatus: 'Active',
      height: physical.height,
      shooting: attributes['shooting']!,
      rebounding: attributes['rebounding']!,
      passing: attributes['passing']!,
      ballHandling: attributes['ballHandling']!,
      perimeterDefense: attributes['perimeterDefense']!,
      postDefense: attributes['postDefense']!,
      insideShooting: attributes['insideShooting']!,
      performances: {},
      primaryRole: primaryRole,
      potential: potential,
      development: development,
    );
  }

  /// Generate a realistic player using the enhanced talent distribution system
  static EnhancedPlayer generateEnhancedRealisticPlayer({
    required PlayerRole primaryRole,
    required int age,
    String? nationality,
    TalentTier? talentTier,
    String? teamName,
    Set<String>? usedNames,
    bool isRookie = false,
  }) {
    // Use enhanced talent distribution system
    talentTier ??= TalentDistributionSystem.generateTalentTier(isRookie: isRookie);
    
    // Generate potential using enhanced system
    PotentialTier potentialTier = TalentDistributionSystem.generatePotentialTier(
      talentTier, 
      age, 
      isRookie: isRookie
    );
    
    // Check for rare archetype
    PlayerArchetype? archetype = TalentDistributionSystem.generateRareArchetype(primaryRole);
    
    if (archetype != null) {
      // Generate archetype player
      return generateArchetypePlayer(
        primaryRole: primaryRole,
        archetype: archetype,
        age: age,
        nationality: nationality,
        usedNames: usedNames,
      );
    } else {
      // Generate regular player with enhanced system
      return generateRealisticPlayer(
        primaryRole: primaryRole,
        age: age,
        nationality: nationality,
        talentTier: talentTier,
        potentialTier: potentialTier,
        teamName: teamName,
        usedNames: usedNames,
      );
    }
  }

  /// Generate a draft class with realistic talent distribution
  static List<EnhancedPlayer> generateDraftClass({
    required int draftSize,
    Map<PlayerRole, double>? positionWeights,
    List<String>? preferredNationalities,
    Set<String>? usedNames,
  }) {
    // Generate talent distribution for draft class
    List<TalentTier> talentDistribution = TalentDistributionSystem.generateDraftClassDistribution(draftSize);
    
    // Default position weights if not provided
    positionWeights ??= {
      PlayerRole.pointGuard: 0.15,
      PlayerRole.shootingGuard: 0.25,
      PlayerRole.smallForward: 0.30,
      PlayerRole.powerForward: 0.20,
      PlayerRole.center: 0.10,
    };
    
    List<EnhancedPlayer> draftClass = [];
    Set<String> allUsedNames = Set.from(usedNames ?? {});
    
    for (int i = 0; i < draftSize; i++) {
      // Select position based on weights
      PlayerRole position = _selectWeightedPosition(positionWeights);
      
      // Select nationality
      String nationality = preferredNationalities?.isNotEmpty == true
          ? preferredNationalities![_random.nextInt(preferredNationalities.length)]
          : _selectRandomNationality();
      
      // Generate rookie with specific talent tier
      TalentTier talentTier = talentDistribution[i];
      
      EnhancedPlayer prospect;
      
      // Check for rare archetype
      PlayerArchetype? archetype = TalentDistributionSystem.generateRareArchetype(position);
      
      if (archetype != null) {
        // Generate archetype player
        prospect = generateArchetypePlayer(
          primaryRole: position,
          archetype: archetype,
          age: 18 + _random.nextInt(4),
          nationality: nationality,
          usedNames: allUsedNames,
        );
        // Update team name for draft prospect
        prospect = EnhancedPlayer(
          name: prospect.name,
          age: prospect.age,
          team: 'Draft Prospect',
          experienceYears: prospect.experienceYears,
          nationality: prospect.nationality,
          currentStatus: prospect.currentStatus,
          height: prospect.height,
          shooting: prospect.shooting,
          rebounding: prospect.rebounding,
          passing: prospect.passing,
          ballHandling: prospect.ballHandling,
          perimeterDefense: prospect.perimeterDefense,
          postDefense: prospect.postDefense,
          insideShooting: prospect.insideShooting,
          performances: prospect.performances,
          primaryRole: prospect.primaryRole,
          potential: prospect.potential,
          development: prospect.development,
        );
      } else {
        // Generate regular player
        prospect = generateRealisticPlayer(
          primaryRole: position,
          age: 18 + _random.nextInt(4),
          nationality: nationality,
          talentTier: talentTier,
          teamName: 'Draft Prospect',
          usedNames: allUsedNames,
        );
      }
      
      draftClass.add(prospect);
      allUsedNames.add(prospect.name);
    }
    
    return draftClass;
  }

  /// Generate multiple players with realistic talent distribution
  static List<EnhancedPlayer> generatePlayerPool({
    required int count,
    Map<PlayerRole, int>? roleDistribution,
    int? averageAge,
    List<String>? nationalities,
    Set<String>? usedNames,
  }) {
    List<EnhancedPlayer> players = [];
    Set<String> allUsedNames = Set.from(usedNames ?? {});
    
    // Default role distribution if not provided
    if (roleDistribution == null) {
      roleDistribution = {};
      int remaining = count;
      
      // Distribute players across positions
      roleDistribution[PlayerRole.pointGuard] = (count * 0.2).round();
      remaining -= roleDistribution[PlayerRole.pointGuard]!;
      
      roleDistribution[PlayerRole.shootingGuard] = (remaining * 0.3125).round(); // 25% of original
      remaining -= roleDistribution[PlayerRole.shootingGuard]!;
      
      roleDistribution[PlayerRole.smallForward] = (remaining * 0.3125).round(); // 25% of original
      remaining -= roleDistribution[PlayerRole.smallForward]!;
      
      roleDistribution[PlayerRole.powerForward] = (remaining * 0.5).round(); // Split remaining
      remaining -= roleDistribution[PlayerRole.powerForward]!;
      
      roleDistribution[PlayerRole.center] = remaining; // Give rest to centers
    }
    
    averageAge ??= 25;
    
    for (PlayerRole role in PlayerRole.values) {
      int roleCount = roleDistribution[role] ?? 0;
      
      for (int i = 0; i < roleCount; i++) {
        // Generate age with variation around average
        int age = (averageAge + _random.nextInt(10) - 5).clamp(18, 40);
        
        // Select nationality
        String nationality = nationalities?.isNotEmpty == true
            ? nationalities![_random.nextInt(nationalities.length)]
            : _selectRandomNationality();
        
        EnhancedPlayer player = generateRealisticPlayer(
          primaryRole: role,
          age: age,
          nationality: nationality,
          usedNames: allUsedNames,
        );
        
        players.add(player);
        allUsedNames.add(player.name);
      }
    }
    
    return players;
  }

  /// Select random nationality based on weighted distribution
  static String _selectRandomNationality() {
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<String, double> entry in _nationalityWeights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }
    
    return 'USA'; // Fallback
  }

  /// Select talent tier based on realistic distribution
  static TalentTier _selectTalentTier() {
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<TalentTier, double> entry in _talentDistribution.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }
    
    return TalentTier.bench; // Fallback
  }

  /// Select talent tier for rookie with different distribution
  static TalentTier _selectRookieTalentTier() {
    // Rookies have more variance and potential for higher tiers
    Map<TalentTier, double> rookieDistribution = {
      TalentTier.superstar: 0.05,    // 5% - Higher chance for rookies
      TalentTier.allStar: 0.15,      // 15% - More potential stars
      TalentTier.starter: 0.30,      // 30% - Solid prospects
      TalentTier.rotation: 0.35,     // 35% - Role players
      TalentTier.bench: 0.15,        // 15% - Lower tier prospects
    };
    
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<TalentTier, double> entry in rookieDistribution.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }
    
    return TalentTier.rotation;
  }

  /// Determine potential tier based on age and talent
  static PotentialTier _determinePotentialTier(int age, TalentTier talentTier) {
    // Younger players have higher potential
    double ageFactor = (30 - age) / 12.0; // 0.0 to 1.5
    ageFactor = ageFactor.clamp(0.0, 1.5);
    
    // Base potential by talent tier
    Map<TalentTier, List<PotentialTier>> tierPotentials = {
      TalentTier.superstar: [PotentialTier.elite, PotentialTier.gold],
      TalentTier.allStar: [PotentialTier.gold, PotentialTier.silver],
      TalentTier.starter: [PotentialTier.silver, PotentialTier.bronze],
      TalentTier.rotation: [PotentialTier.silver, PotentialTier.bronze],
      TalentTier.bench: [PotentialTier.bronze],
    };
    
    List<PotentialTier> possibleTiers = tierPotentials[talentTier]!;
    
    // Age influences potential tier selection
    if (age < 23 && possibleTiers.length > 1) {
      // Young players get higher potential
      return possibleTiers.first;
    } else if (age > 28 && possibleTiers.length > 1) {
      // Older players get lower potential
      return possibleTiers.last;
    } else {
      // Random selection from possible tiers
      return possibleTiers[_random.nextInt(possibleTiers.length)];
    }
  }

  /// Select potential tier for rookies with hidden potential system
  static PotentialTier _selectRookiePotentialTier(TalentTier talentTier) {
    // Rookies have more potential variance and hidden potential
    switch (talentTier) {
      case TalentTier.superstar:
        return _random.nextDouble() < 0.7 ? PotentialTier.elite : PotentialTier.gold;
      case TalentTier.allStar:
        return _random.nextDouble() < 0.6 ? PotentialTier.gold : PotentialTier.silver;
      case TalentTier.starter:
        return _random.nextDouble() < 0.5 ? PotentialTier.silver : PotentialTier.bronze;
      case TalentTier.rotation:
        return _random.nextDouble() < 0.3 ? PotentialTier.silver : PotentialTier.bronze;
      case TalentTier.bench:
        return _random.nextDouble() < 0.1 ? PotentialTier.silver : PotentialTier.bronze;
    }
  }

  /// Generate realistic physical attributes based on player role
  static PhysicalAttributes _generatePhysicalAttributes(PlayerRole role) {
    Map<PlayerRole, Map<String, int>> physicalRanges = {
      PlayerRole.pointGuard: {
        'heightMin': 175, 'heightMax': 195, 'heightAvg': 185,
        'weightMin': 70, 'weightMax': 90, 'weightAvg': 80,
        'wingspanMin': 180, 'wingspanMax': 200, 'wingspanAvg': 190,
        'verticalMin': 75, 'verticalMax': 110, 'verticalAvg': 90,
      },
      PlayerRole.shootingGuard: {
        'heightMin': 185, 'heightMax': 205, 'heightAvg': 195,
        'weightMin': 80, 'weightMax': 105, 'weightAvg': 92,
        'wingspanMin': 190, 'wingspanMax': 215, 'wingspanAvg': 202,
        'verticalMin': 70, 'verticalMax': 105, 'verticalAvg': 85,
      },
      PlayerRole.smallForward: {
        'heightMin': 195, 'heightMax': 210, 'heightAvg': 203,
        'weightMin': 90, 'weightMax': 115, 'weightAvg': 102,
        'wingspanMin': 200, 'wingspanMax': 220, 'wingspanAvg': 210,
        'verticalMin': 65, 'verticalMax': 100, 'verticalAvg': 80,
      },
      PlayerRole.powerForward: {
        'heightMin': 200, 'heightMax': 215, 'heightAvg': 208,
        'weightMin': 100, 'weightMax': 130, 'weightAvg': 115,
        'wingspanMin': 210, 'wingspanMax': 230, 'wingspanAvg': 220,
        'verticalMin': 60, 'verticalMax': 95, 'verticalAvg': 75,
      },
      PlayerRole.center: {
        'heightMin': 205, 'heightMax': 225, 'heightAvg': 213,
        'weightMin': 110, 'weightMax': 150, 'weightAvg': 130,
        'wingspanMin': 215, 'wingspanMax': 240, 'wingspanAvg': 227,
        'verticalMin': 55, 'verticalMax': 90, 'verticalAvg': 70,
      },
    };

    Map<String, int> ranges = physicalRanges[role]!;
    
    // Generate height with normal distribution around average
    int height = _generateNormalDistribution(
      ranges['heightAvg']!, 
      ranges['heightMin']!, 
      ranges['heightMax']!
    );
    
    // Weight correlates with height
    int baseWeight = ranges['weightAvg']!;
    int heightDiff = height - ranges['heightAvg']!;
    int weight = (baseWeight + heightDiff * 0.3).round();
    weight = weight.clamp(ranges['weightMin']!, ranges['weightMax']!);
    
    // Wingspan typically longer than height
    int wingspan = height + (_random.nextInt(15) - 5); // -5 to +10 cm
    wingspan = wingspan.clamp(ranges['wingspanMin']!, ranges['wingspanMax']!);
    
    // Vertical leap with some randomness
    int verticalLeap = _generateNormalDistribution(
      ranges['verticalAvg']!, 
      ranges['verticalMin']!, 
      ranges['verticalMax']!
    );

    return PhysicalAttributes(
      height: height,
      weight: weight,
      wingspan: wingspan,
      verticalLeap: verticalLeap,
    );
  }

  /// Generate role-based attributes with realistic distributions
  static Map<String, int> _generateRoleBasedAttributes(
    PlayerRole role, 
    TalentTier talentTier, 
    int age
  ) {
    // Base attribute ranges by talent tier
    Map<TalentTier, Map<String, int>> tierRanges = {
      TalentTier.superstar: {'min': 85, 'max': 99, 'average': 92},
      TalentTier.allStar: {'min': 75, 'max': 95, 'average': 85},
      TalentTier.starter: {'min': 65, 'max': 85, 'average': 75},
      TalentTier.rotation: {'min': 55, 'max': 75, 'average': 65},
      TalentTier.bench: {'min': 45, 'max': 65, 'average': 55},
    };

    Map<String, int> tierRange = tierRanges[talentTier]!;
    Map<String, int> attributes = {};
    
    // Get role requirements and weights
    Map<String, int> roleRequirements = RoleManager.roleRequirements[role]!;
    Map<String, double> roleWeights = RoleManager.roleWeights[role]!;
    
    // Age affects attribute generation (prime vs young vs old)
    double ageModifier = _getAgeModifier(age);
    
    // Generate each attribute
    for (String attribute in ['shooting', 'rebounding', 'passing', 'ballHandling', 
                             'perimeterDefense', 'postDefense', 'insideShooting']) {
      
      double weight = roleWeights[attribute] ?? 1.0;
      int baseValue = tierRange['average']!;
      
      // Apply role weight modifications
      if (weight >= 2.0) {
        // Primary skill - significant boost
        baseValue = (baseValue * 1.2).round();
      } else if (weight >= 1.5) {
        // Important skill - moderate boost
        baseValue = (baseValue * 1.1).round();
      } else if (weight <= 0.5) {
        // Weak skill - significant reduction
        baseValue = (baseValue * 0.7).round();
      } else if (weight <= 0.8) {
        // Below average skill - moderate reduction
        baseValue = (baseValue * 0.85).round();
      }
      
      // Apply age modifier
      baseValue = (baseValue * ageModifier).round();
      
      // Add realistic variation
      int variation = (tierRange['max']! - tierRange['min']!) ~/ 6;
      int finalValue = baseValue + (_random.nextInt(variation * 2) - variation);
      
      // Clamp to tier limits
      finalValue = finalValue.clamp(tierRange['min']!, tierRange['max']!);
      
      attributes[attribute] = finalValue;
    }
    
    return attributes;
  }

  /// Generate player potential with role and archetype considerations
  static PlayerPotential _generatePlayerPotential(
    int age, 
    PotentialTier tier, 
    PlayerRole role
  ) {
    return PlayerPotential.fromTier(tier, isHidden: true);
  }

  /// Generate archetype-specific potential
  static PlayerPotential _generateArchetypePotential(
    int age,
    PotentialTier tier,
    PlayerRole role,
    PlayerArchetype archetype
  ) {
    PlayerPotential basePotential = PlayerPotential.fromTier(tier, isHidden: true);
    
    // Modify potential caps based on archetype
    Map<String, int> modifiedCaps = Map.from(basePotential.maxSkills);
    
    switch (archetype) {
      case PlayerArchetype.eliteShooter:
        modifiedCaps['shooting'] = (modifiedCaps['shooting']! + 10).clamp(50, 99);
        modifiedCaps['insideShooting'] = (modifiedCaps['insideShooting']! - 5).clamp(50, 99);
        break;
      case PlayerArchetype.defensiveSpecialist:
        modifiedCaps['perimeterDefense'] = (modifiedCaps['perimeterDefense']! + 10).clamp(50, 99);
        modifiedCaps['postDefense'] = (modifiedCaps['postDefense']! + 8).clamp(50, 99);
        modifiedCaps['shooting'] = (modifiedCaps['shooting']! - 8).clamp(50, 99);
        break;
      case PlayerArchetype.playmaker:
        modifiedCaps['passing'] = (modifiedCaps['passing']! + 12).clamp(50, 99);
        modifiedCaps['ballHandling'] = (modifiedCaps['ballHandling']! + 10).clamp(50, 99);
        modifiedCaps['rebounding'] = (modifiedCaps['rebounding']! - 5).clamp(50, 99);
        break;
      case PlayerArchetype.athleticFinisher:
        modifiedCaps['insideShooting'] = (modifiedCaps['insideShooting']! + 12).clamp(50, 99);
        modifiedCaps['rebounding'] = (modifiedCaps['rebounding']! + 8).clamp(50, 99);
        modifiedCaps['shooting'] = (modifiedCaps['shooting']! - 10).clamp(50, 99);
        break;
      case PlayerArchetype.stretchBig:
        modifiedCaps['shooting'] = (modifiedCaps['shooting']! + 15).clamp(50, 99);
        modifiedCaps['rebounding'] = (modifiedCaps['rebounding']! + 5).clamp(50, 99);
        modifiedCaps['ballHandling'] = (modifiedCaps['ballHandling']! - 8).clamp(50, 99);
        break;
      case PlayerArchetype.lockdownDefender:
        modifiedCaps['perimeterDefense'] = (modifiedCaps['perimeterDefense']! + 15).clamp(50, 99);
        modifiedCaps['passing'] = (modifiedCaps['passing']! - 5).clamp(50, 99);
        break;
      case PlayerArchetype.floorGeneral:
        modifiedCaps['passing'] = (modifiedCaps['passing']! + 8).clamp(50, 99);
        modifiedCaps['ballHandling'] = (modifiedCaps['ballHandling']! + 6).clamp(50, 99);
        modifiedCaps['perimeterDefense'] = (modifiedCaps['perimeterDefense']! + 4).clamp(50, 99);
        break;
      case PlayerArchetype.energizer:
        // Balanced improvements across all skills
        for (String skill in modifiedCaps.keys) {
          modifiedCaps[skill] = (modifiedCaps[skill]! + 3).clamp(50, 99);
        }
        break;
    }
    
    return PlayerPotential(
      tier: tier,
      maxSkills: modifiedCaps,
      overallPotential: basePotential.overallPotential,
      isHidden: true,
    );
  }

  /// Apply archetype modifications to base attributes
  static Map<String, int> _applyArchetypeModifications(
    Map<String, int> baseAttributes, 
    PlayerArchetype archetype
  ) {
    Map<String, int> modified = Map.from(baseAttributes);
    
    switch (archetype) {
      case PlayerArchetype.eliteShooter:
        modified['shooting'] = (modified['shooting']! + 15).clamp(50, 99);
        modified['insideShooting'] = (modified['insideShooting']! - 8).clamp(50, 99);
        break;
      case PlayerArchetype.defensiveSpecialist:
        modified['perimeterDefense'] = (modified['perimeterDefense']! + 20).clamp(70, 99);
        modified['postDefense'] = (modified['postDefense']! + 18).clamp(70, 99);
        modified['shooting'] = (modified['shooting']! - 10).clamp(50, 99);
        break;
      case PlayerArchetype.playmaker:
        modified['passing'] = (modified['passing']! + 15).clamp(50, 99);
        modified['ballHandling'] = (modified['ballHandling']! + 12).clamp(50, 99);
        modified['rebounding'] = (modified['rebounding']! - 5).clamp(50, 99);
        break;
      case PlayerArchetype.athleticFinisher:
        modified['insideShooting'] = (modified['insideShooting']! + 15).clamp(50, 99);
        modified['rebounding'] = (modified['rebounding']! + 10).clamp(50, 99);
        modified['shooting'] = (modified['shooting']! - 12).clamp(50, 99);
        break;
      case PlayerArchetype.stretchBig:
        modified['shooting'] = (modified['shooting']! + 18).clamp(50, 99);
        modified['rebounding'] = (modified['rebounding']! + 8).clamp(50, 99);
        modified['ballHandling'] = (modified['ballHandling']! - 10).clamp(50, 99);
        break;
      case PlayerArchetype.lockdownDefender:
        modified['perimeterDefense'] = (modified['perimeterDefense']! + 18).clamp(50, 99);
        modified['passing'] = (modified['passing']! - 8).clamp(50, 99);
        break;
      case PlayerArchetype.floorGeneral:
        modified['passing'] = (modified['passing']! + 10).clamp(50, 99);
        modified['ballHandling'] = (modified['ballHandling']! + 8).clamp(50, 99);
        modified['perimeterDefense'] = (modified['perimeterDefense']! + 6).clamp(50, 99);
        break;
      case PlayerArchetype.energizer:
        // Moderate improvements across all skills
        for (String skill in modified.keys) {
          modified[skill] = (modified[skill]! + 5).clamp(50, 99);
        }
        break;
    }
    
    return modified;
  }

  /// Generate unique name avoiding duplicates
  static String _generateUniqueName(String nationality, Set<String> usedNames) {
    String name;
    int attempts = 0;
    
    do {
      name = _generateRealisticName(nationality);
      attempts++;
      
      // If we can't find unique name after many attempts, add suffix
      if (attempts > 50) {
        name = '$name ${attempts - 50}';
        break;
      }
    } while (usedNames.contains(name));
    
    return name;
  }

  /// Generate realistic names by nationality with expanded name pools
  static String _generateRealisticName(String nationality) {
    Map<String, List<String>> firstNamesByNationality = {
      'USA': ['Michael', 'LeBron', 'Stephen', 'Kevin', 'James', 'Chris', 'Russell', 'Damian', 'Anthony', 'Kyle',
              'Jayson', 'Devin', 'Donovan', 'Trae', 'Zion', 'Ja', 'Tyler', 'Brandon', 'CJ', 'Kemba'],
      'Canada': ['Jamal', 'Andrew', 'Tristan', 'Cory', 'Kelly', 'Dwight', 'Nik', 'Trey', 'RJ', 'Shai',
                 'Chris', 'Dillon', 'Luguentz', 'Khem', 'Melvin', 'Anthony', 'Nickeil', 'Oshae', 'Karim', 'Brandon'],
      'France': ['Tony', 'Nicolas', 'Rudy', 'Evan', 'Frank', 'Timothe', 'Sekou', 'Theo', 'Killian', 'Moussa',
                 'Vincent', 'Nando', 'Guerschon', 'Petr', 'Adam', 'Mathias', 'Axel', 'Paul', 'Elie', 'Yakuba'],
      'Germany': ['Dirk', 'Dennis', 'Maxi', 'Daniel', 'Moritz', 'Isaiah', 'Franz', 'Moe', 'Paul', 'Johannes',
                  'Robin', 'Tibor', 'Niels', 'Andreas', 'Joshiko', 'Ariel', 'Leon', 'Justus', 'Bennet', 'David'],
      'Australia': ['Ben', 'Joe', 'Patty', 'Matthew', 'Aron', 'Ryan', 'Dante', 'Josh', 'Dyson', 'Jock',
                    'Nathan', 'Cameron', 'Mitch', 'Isaac', 'Deng', 'Xavier', 'Will', 'Keanu', 'Samson', 'Jack'],
      'Spain': ['Pau', 'Marc', 'Ricky', 'Jose', 'Sergio', 'Juan', 'Willy', 'Juancho', 'Santi', 'Usman',
                'Alex', 'Alberto', 'Carlos', 'Victor', 'Xavi', 'Dario', 'Guillem', 'Joel', 'Jaime', 'Ruben'],
      'Serbia': ['Nikola', 'Bogdan', 'Nemanja', 'Milos', 'Boban', 'Marko', 'Aleksej', 'Stefan', 'Vasilije', 'Ognjen',
                 'Nikola', 'Marko', 'Dusan', 'Luka', 'Petar', 'Milan', 'Dragan', 'Aleksandar', 'Mihailo', 'Vanja'],
      'Greece': ['Giannis', 'Thanasis', 'Kostas', 'Tyler', 'Georgios', 'Ioannis', 'Nikos', 'Dimitrios', 'Andreas', 'Vassilis',
                 'Panagiotis', 'Christos', 'Michalis', 'Antonis', 'Lefteris', 'Yannis', 'Stavros', 'Manolis', 'Takis', 'Spiros'],
    };
    
    Map<String, List<String>> lastNamesByNationality = {
      'USA': ['Johnson', 'Williams', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas',
              'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark', 'Rodriguez'],
      'Canada': ['Murray', 'Wiggins', 'Thompson', 'Joseph', 'Olynyk', 'Powell', 'Stauskas', 'Lyles', 'Barrett', 'Alexander',
                 'Brooks', 'Clarke', 'Dort', 'Birch', 'Ejim', 'Bennett', 'Walker', 'Boucher', 'Mfiondu', 'Clarke'],
      'France': ['Parker', 'Batum', 'Gobert', 'Fournier', 'Ntilikina', 'Luwawu-Cabarrot', 'Doumbouya', 'Maledon', 'Hayes', 'Diabate',
                 'Poirier', 'De Colo', 'Yabusele', 'Lessort', 'Toupane', 'Heurtel', 'Ouattara', 'Lacombe', 'Okobo', 'Ousmane'],
      'Germany': ['Nowitzki', 'Schroder', 'Kleber', 'Theis', 'Wagner', 'Hartenstein', 'Wagner', 'Wagner', 'Zipser', 'Voigtmann',
                  'Benzing', 'Pleiss', 'Saibou', 'Obst', 'Heckmann', 'Happ', 'Giffey', 'Hollins', 'Weiler-Babb', 'Wank'],
      'Australia': ['Simmons', 'Ingles', 'Mills', 'Dellavedova', 'Baynes', 'Broekhoff', 'Exum', 'Green', 'Daniels', 'Landale',
                    'Sobey', 'Gliddon', 'Creek', 'Adel', 'Maker', 'Cooks', 'Magnay', 'Kay', 'Pinder', 'White'],
      'Spain': ['Gasol', 'Gasol', 'Rubio', 'Calderon', 'Rodriguez', 'Hernangomez', 'Hernangomez', 'Hernangomez', 'Aldama', 'Garuba',
                'Abrines', 'Oriola', 'Sastre', 'Prepelic', 'Lopez-Arostegui', 'Brizuela', 'Pradilla', 'Parra', 'Vives', 'Deck'],
      'Serbia': ['Jokic', 'Bogdanovic', 'Bjelica', 'Teodosic', 'Marjanovic', 'Guduric', 'Pokusevski', 'Petrusev', 'Micic', 'Avramovic',
                 'Kalinic', 'Raduljica', 'Simonovic', 'Davidovac', 'Milutinov', 'Lucic', 'Zagorac', 'Smailagic', 'Dobrić', 'Pecarski'],
      'Greece': ['Antetokounmpo', 'Antetokounmpo', 'Antetokounmpo', 'Dorsey', 'Papagiannis', 'Calathes', 'Sloukas', 'Mitoglou', 'Toliopoulos', 'Kalaitzakis',
                 'Papanikolaou', 'Printezis', 'Bourousis', 'Koufos', 'Larentzakis', 'Mantzaris', 'Kavaliauskas', 'Agravanis', 'Bochoridis', 'Charalampopoulos'],
    };
    
    List<String> firstNames = firstNamesByNationality[nationality] ?? firstNamesByNationality['USA']!;
    List<String> lastNames = lastNamesByNationality[nationality] ?? lastNamesByNationality['USA']!;
    
    String firstName = firstNames[_random.nextInt(firstNames.length)];
    String lastName = lastNames[_random.nextInt(lastNames.length)];
    
    return '$firstName $lastName';
  }

  /// Calculate experience years based on age with realistic distribution
  static int _calculateExperienceYears(int age) {
    if (age <= 19) return 0; // Rookie
    if (age <= 22) return _random.nextInt(3); // 0-2 years
    if (age <= 25) return 1 + _random.nextInt(5); // 1-5 years
    if (age <= 30) return 3 + _random.nextInt(8); // 3-10 years
    return 8 + _random.nextInt(12); // 8-19 years for veterans
  }

  /// Get age modifier for attribute generation
  static double _getAgeModifier(int age) {
    if (age < 22) {
      // Young players - lower current attributes but high potential
      return 0.85;
    } else if (age >= 22 && age <= 29) {
      // Prime years - peak attributes
      return 1.0;
    } else if (age >= 30 && age <= 33) {
      // Early decline - still good but slightly lower
      return 0.95;
    } else {
      // Veteran decline - noticeably lower attributes
      return 0.85;
    }
  }

  /// Generate value with normal distribution
  static int _generateNormalDistribution(int average, int min, int max) {
    // Simple approximation of normal distribution using multiple random values
    double sum = 0.0;
    for (int i = 0; i < 6; i++) {
      sum += _random.nextDouble();
    }
    double normalValue = (sum - 3.0) / 3.0; // Normalize to roughly -1 to 1
    
    int range = max - min;
    int value = average + (normalValue * range / 4).round();
    
    return value.clamp(min, max);
  }

  /// Select position based on weighted probabilities
  static PlayerRole _selectWeightedPosition(Map<PlayerRole, double> weights) {
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<PlayerRole, double> entry in weights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }
    
    return PlayerRole.shootingGuard; // Fallback
  }
}

/// Talent tier classification for realistic player generation
enum TalentTier {
  superstar,   // Generational talents (2%)
  allStar,     // All-Star level players (8%)
  starter,     // Solid starters (25%)
  rotation,    // Rotation players (35%)
  bench,       // Bench/role players (30%)
}

/// Player archetypes for specialized generation
enum PlayerArchetype {
  eliteShooter,        // Exceptional 3-point and mid-range shooting
  defensiveSpecialist, // Elite perimeter and post defense
  playmaker,          // Exceptional passing and ball handling
  athleticFinisher,   // High inside shooting and rebounding
  stretchBig,         // Big man with shooting ability
  lockdownDefender,   // Perimeter defense specialist
  floorGeneral,       // High basketball IQ and leadership
  energizer,          // High energy role player
}

/// Physical attributes for player generation
class PhysicalAttributes {
  final int height;
  final int weight;
  final int wingspan;
  final int verticalLeap;

  PhysicalAttributes({
    required this.height,
    required this.weight,
    required this.wingspan,
    required this.verticalLeap,
  });
}