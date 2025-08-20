import 'player_class.dart';
import 'enums.dart';

/// Enhanced data models that work alongside existing classes
/// This approach maintains backward compatibility while adding new features

/// Enhanced player data that can be stored alongside regular Player
class PlayerEnhancement {
  String playerId; // Reference to the player
  PlayerRole primaryRole;
  PlayerRole? secondaryRole;
  double roleCompatibility;
  Map<PlayerRole, double> roleExperience;
  PlayerPotential potential;
  DevelopmentTracker development;

  PlayerEnhancement({
    required this.playerId,
    required this.primaryRole,
    this.secondaryRole,
    this.roleCompatibility = 1.0,
    Map<PlayerRole, double>? roleExperience,
    PlayerPotential? potential,
    DevelopmentTracker? development,
  }) : roleExperience = roleExperience ?? {for (var role in PlayerRole.values) role: 0.0},
       potential = potential ?? PlayerPotential.defaultPotential(),
       development = development ?? DevelopmentTracker.initial();

  /// Calculate role compatibility based on player attributes and assigned role
  double calculateRoleCompatibility(Player player, PlayerRole role) {
    switch (role) {
      case PlayerRole.pointGuard:
        return (player.ballHandling * 0.4 + player.passing * 0.4 + player.shooting * 0.2) / 100.0;
      case PlayerRole.shootingGuard:
        return (player.shooting * 0.5 + player.ballHandling * 0.3 + player.perimeterDefense * 0.2) / 100.0;
      case PlayerRole.smallForward:
        return (player.shooting * 0.3 + player.rebounding * 0.3 + player.perimeterDefense * 0.2 + player.ballHandling * 0.2) / 100.0;
      case PlayerRole.powerForward:
        return (player.rebounding * 0.4 + player.insideShooting * 0.3 + player.postDefense * 0.3) / 100.0;
      case PlayerRole.center:
        return (player.rebounding * 0.4 + player.postDefense * 0.4 + player.insideShooting * 0.2) / 100.0;
    }
  }

  /// Get role-based performance bonuses
  Map<String, double> getRoleBonuses() {
    double compatibility = roleCompatibility;
    double bonus = (compatibility - 0.5) * 0.2; // -10% to +10% based on compatibility
    
    return {
      'shooting': primaryRole == PlayerRole.shootingGuard ? bonus : 0.0,
      'rebounding': [PlayerRole.powerForward, PlayerRole.center].contains(primaryRole) ? bonus : 0.0,
      'passing': primaryRole == PlayerRole.pointGuard ? bonus : 0.0,
      'ballHandling': [PlayerRole.pointGuard, PlayerRole.shootingGuard].contains(primaryRole) ? bonus : 0.0,
      'defense': bonus * 0.5, // All positions get some defensive bonus
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'primaryRole': primaryRole.name,
      'secondaryRole': secondaryRole?.name,
      'roleCompatibility': roleCompatibility.toString(),
      'roleExperience': roleExperience.map(
        (role, exp) => MapEntry(role.name, exp.toString())
      ),
      'potential': potential.toMap(),
      'development': development.toMap(),
    };
  }

  factory PlayerEnhancement.fromMap(Map<String, dynamic> map) {
    return PlayerEnhancement(
      playerId: map['playerId'] ?? '',
      primaryRole: PlayerRole.values.firstWhere(
        (role) => role.name == (map['primaryRole'] ?? 'pointGuard'),
        orElse: () => PlayerRole.pointGuard,
      ),
      secondaryRole: map['secondaryRole'] != null 
        ? PlayerRole.values.firstWhere(
            (role) => role.name == map['secondaryRole'],
            orElse: () => PlayerRole.pointGuard,
          )
        : null,
      roleCompatibility: double.tryParse(map['roleCompatibility']?.toString() ?? '1.0') ?? 1.0,
      roleExperience: (map['roleExperience'] as Map<String, dynamic>?)?.map(
        (roleStr, expStr) => MapEntry(
          PlayerRole.values.firstWhere(
            (role) => role.name == roleStr,
            orElse: () => PlayerRole.pointGuard,
          ),
          double.tryParse(expStr.toString()) ?? 0.0,
        )
      ) ?? {},
      potential: map['potential'] != null 
        ? PlayerPotential.fromMap(map['potential'])
        : PlayerPotential.defaultPotential(),
      development: map['development'] != null
        ? DevelopmentTracker.fromMap(map['development'])
        : DevelopmentTracker.initial(),
    );
  }
}

/// Enhanced coach data that can be stored alongside regular Manager
class CoachEnhancement {
  String coachId; // Reference to the manager
  CoachingSpecialization primarySpecialization;
  CoachingSpecialization? secondarySpecialization;
  Map<String, int> coachingAttributes;
  List<Achievement> achievements;
  CoachingHistory history;
  int experienceLevel;
  Map<String, double> teamBonuses;

  CoachEnhancement({
    required this.coachId,
    required this.primarySpecialization,
    this.secondarySpecialization,
    Map<String, int>? coachingAttributes,
    List<Achievement>? achievements,
    CoachingHistory? history,
    this.experienceLevel = 1,
    Map<String, double>? teamBonuses,
  }) : coachingAttributes = coachingAttributes ?? {
         'offensive': 50,
         'defensive': 50,
         'development': 50,
         'chemistry': 50,
       },
       achievements = achievements ?? [],
       history = history ?? CoachingHistory.initial(),
       teamBonuses = teamBonuses ?? {};

  /// Calculate team bonuses based on coaching specializations and attributes
  Map<String, double> calculateTeamBonuses() {
    Map<String, double> bonuses = {};
    
    // Primary specialization bonuses
    switch (primarySpecialization) {
      case CoachingSpecialization.offensive:
        bonuses['offensiveRating'] = (coachingAttributes['offensive']! - 50) * 0.002;
        break;
      case CoachingSpecialization.defensive:
        bonuses['defensiveRating'] = (coachingAttributes['defensive']! - 50) * 0.002;
        break;
      case CoachingSpecialization.playerDevelopment:
        bonuses['developmentRate'] = (coachingAttributes['development']! - 50) * 0.001;
        break;
      case CoachingSpecialization.teamChemistry:
        bonuses['teamChemistry'] = (coachingAttributes['chemistry']! - 50) * 0.001;
        break;
    }
    
    // Secondary specialization bonuses (reduced effect)
    if (secondarySpecialization != null) {
      switch (secondarySpecialization!) {
        case CoachingSpecialization.offensive:
          bonuses['offensiveRating'] = (bonuses['offensiveRating'] ?? 0.0) + 
            (coachingAttributes['offensive']! - 50) * 0.001;
          break;
        case CoachingSpecialization.defensive:
          bonuses['defensiveRating'] = (bonuses['defensiveRating'] ?? 0.0) + 
            (coachingAttributes['defensive']! - 50) * 0.001;
          break;
        case CoachingSpecialization.playerDevelopment:
          bonuses['developmentRate'] = (bonuses['developmentRate'] ?? 0.0) + 
            (coachingAttributes['development']! - 50) * 0.0005;
          break;
        case CoachingSpecialization.teamChemistry:
          bonuses['teamChemistry'] = (bonuses['teamChemistry'] ?? 0.0) + 
            (coachingAttributes['chemistry']! - 50) * 0.0005;
          break;
      }
    }
    
    // Experience level multiplier
    double experienceMultiplier = 1.0 + (experienceLevel - 1) * 0.1;
    bonuses = bonuses.map((key, value) => MapEntry(key, value * experienceMultiplier));
    
    teamBonuses = bonuses;
    return bonuses;
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'primarySpecialization': primarySpecialization.name,
      'secondarySpecialization': secondarySpecialization?.name,
      'coachingAttributes': coachingAttributes.map(
        (attr, value) => MapEntry(attr, value.toString())
      ),
      'achievements': achievements.map((achievement) => achievement.toMap()).toList(),
      'history': history.toMap(),
      'experienceLevel': experienceLevel.toString(),
      'teamBonuses': teamBonuses.map(
        (bonus, value) => MapEntry(bonus, value.toString())
      ),
    };
  }

  factory CoachEnhancement.fromMap(Map<String, dynamic> map) {
    return CoachEnhancement(
      coachId: map['coachId'] ?? '',
      primarySpecialization: CoachingSpecialization.values.firstWhere(
        (spec) => spec.name == (map['primarySpecialization'] ?? 'offensive'),
        orElse: () => CoachingSpecialization.offensive,
      ),
      secondarySpecialization: map['secondarySpecialization'] != null
        ? CoachingSpecialization.values.firstWhere(
            (spec) => spec.name == map['secondarySpecialization'],
            orElse: () => CoachingSpecialization.offensive,
          )
        : null,
      coachingAttributes: (map['coachingAttributes'] as Map<String, dynamic>?)?.map(
        (attr, valueStr) => MapEntry(attr, int.tryParse(valueStr.toString()) ?? 50)
      ) ?? {},
      achievements: (map['achievements'] as List?)?.map(
        (achievementMap) => Achievement.fromMap(achievementMap)
      ).toList() ?? [],
      history: map['history'] != null
        ? CoachingHistory.fromMap(map['history'])
        : CoachingHistory.initial(),
      experienceLevel: int.tryParse(map['experienceLevel']?.toString() ?? '1') ?? 1,
      teamBonuses: (map['teamBonuses'] as Map<String, dynamic>?)?.map(
        (bonus, valueStr) => MapEntry(bonus, double.tryParse(valueStr.toString()) ?? 0.0)
      ) ?? {},
    );
  }
}

/// Enhanced team data that can be stored alongside regular Team
class TeamEnhancement {
  String teamId; // Reference to the team
  PlaybookLibrary playbookLibrary;
  Map<PlayerRole, String?> roleAssignments; // Player IDs assigned to roles
  TeamBranding? branding;
  String? conference;
  String? division;
  TeamHistory? history;

  TeamEnhancement({
    required this.teamId,
    PlaybookLibrary? playbookLibrary,
    Map<PlayerRole, String?>? roleAssignments,
    this.branding,
    this.conference,
    this.division,
    this.history,
  }) : playbookLibrary = playbookLibrary ?? PlaybookLibrary(),
       roleAssignments = roleAssignments ?? {for (var role in PlayerRole.values) role: null} {
    
    // Initialize playbook library with defaults if empty
    if (this.playbookLibrary.playbooks.isEmpty) {
      this.playbookLibrary.initializeWithDefaults();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'playbookLibrary': playbookLibrary.toMap(),
      'roleAssignments': roleAssignments.map(
        (role, playerId) => MapEntry(role.name, playerId)
      ),
      'branding': branding?.toMap(),
      'conference': conference,
      'division': division,
      'history': history?.toMap(),
    };
  }

  factory TeamEnhancement.fromMap(Map<String, dynamic> map) {
    return TeamEnhancement(
      teamId: map['teamId'] ?? '',
      playbookLibrary: map['playbookLibrary'] != null
        ? PlaybookLibrary.fromMap(map['playbookLibrary'])
        : PlaybookLibrary(),
      roleAssignments: (map['roleAssignments'] as Map<String, dynamic>?)?.map(
        (roleStr, playerId) => MapEntry(
          PlayerRole.values.firstWhere(
            (r) => r.name == roleStr,
            orElse: () => PlayerRole.pointGuard,
          ),
          playerId as String?,
        )
      ) ?? {},
      branding: map['branding'] != null
        ? TeamBranding.fromMap(map['branding'])
        : null,
      conference: map['conference'],
      division: map['division'],
      history: map['history'] != null
        ? TeamHistory.fromMap(map['history'])
        : null,
    );
  }
}

/// Playbook system for managing team strategies
class Playbook {
  String name;
  OffensiveStrategy offensiveStrategy;
  DefensiveStrategy defensiveStrategy;
  Map<String, double> strategyWeights;
  List<PlayerRole> optimalRoles;
  Map<String, double> teamRequirements;
  double effectiveness;

  Playbook({
    required this.name,
    required this.offensiveStrategy,
    required this.defensiveStrategy,
    Map<String, double>? strategyWeights,
    List<PlayerRole>? optimalRoles,
    Map<String, double>? teamRequirements,
    this.effectiveness = 0.0,
  }) : strategyWeights = strategyWeights ?? _getDefaultStrategyWeights(offensiveStrategy, defensiveStrategy),
       optimalRoles = optimalRoles ?? _getDefaultOptimalRoles(offensiveStrategy),
       teamRequirements = teamRequirements ?? _getDefaultTeamRequirements(offensiveStrategy, defensiveStrategy);

  /// Get default strategy weights based on offensive and defensive strategies
  static Map<String, double> _getDefaultStrategyWeights(
    OffensiveStrategy offensive, 
    DefensiveStrategy defensive
  ) {
    Map<String, double> weights = {};
    
    // Offensive strategy weights
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        weights['pace'] = 1.2;
        weights['transition'] = 1.3;
        weights['ballHandling'] = 1.1;
        break;
      case OffensiveStrategy.halfCourt:
        weights['pace'] = 0.9;
        weights['ballMovement'] = 1.2;
        weights['patience'] = 1.3;
        break;
      case OffensiveStrategy.pickAndRoll:
        weights['ballHandling'] = 1.2;
        weights['screening'] = 1.3;
        weights['spacing'] = 1.1;
        break;
      case OffensiveStrategy.postUp:
        weights['insideShooting'] = 1.3;
        weights['postMoves'] = 1.4;
        weights['rebounding'] = 1.1;
        break;
      case OffensiveStrategy.threePointHeavy:
        weights['shooting'] = 1.4;
        weights['spacing'] = 1.3;
        weights['ballMovement'] = 1.1;
        break;
    }
    
    // Defensive strategy weights
    switch (defensive) {
      case DefensiveStrategy.manToMan:
        weights['individualDefense'] = 1.2;
        weights['communication'] = 1.1;
        break;
      case DefensiveStrategy.zoneDefense:
        weights['teamDefense'] = 1.3;
        weights['positioning'] = 1.2;
        break;
      case DefensiveStrategy.pressDefense:
        weights['pressure'] = 1.4;
        weights['stamina'] = 1.2;
        weights['speed'] = 1.1;
        break;
      case DefensiveStrategy.switchDefense:
        weights['versatility'] = 1.3;
        weights['communication'] = 1.2;
        break;
    }
    
    return weights;
  }

  /// Get default optimal roles for offensive strategy
  static List<PlayerRole> _getDefaultOptimalRoles(OffensiveStrategy offensive) {
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        return [PlayerRole.pointGuard, PlayerRole.shootingGuard, PlayerRole.smallForward];
      case OffensiveStrategy.halfCourt:
        return PlayerRole.values; // All positions work well
      case OffensiveStrategy.pickAndRoll:
        return [PlayerRole.pointGuard, PlayerRole.center];
      case OffensiveStrategy.postUp:
        return [PlayerRole.powerForward, PlayerRole.center];
      case OffensiveStrategy.threePointHeavy:
        return [PlayerRole.pointGuard, PlayerRole.shootingGuard, PlayerRole.smallForward];
    }
  }

  /// Get default team requirements for strategies
  static Map<String, double> _getDefaultTeamRequirements(
    OffensiveStrategy offensive,
    DefensiveStrategy defensive
  ) {
    Map<String, double> requirements = {};
    
    // Offensive requirements
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        requirements['averageSpeed'] = 70.0;
        requirements['averageBallHandling'] = 65.0;
        break;
      case OffensiveStrategy.halfCourt:
        requirements['averagePassing'] = 70.0;
        requirements['averageBasketballIQ'] = 75.0;
        break;
      case OffensiveStrategy.pickAndRoll:
        requirements['centerScreening'] = 70.0;
        requirements['guardBallHandling'] = 75.0;
        break;
      case OffensiveStrategy.postUp:
        requirements['averageInsideShooting'] = 75.0;
        requirements['centerPostMoves'] = 80.0;
        break;
      case OffensiveStrategy.threePointHeavy:
        requirements['averageShooting'] = 75.0;
        requirements['averageSpacing'] = 70.0;
        break;
    }
    
    return requirements;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'offensiveStrategy': offensiveStrategy.name,
      'defensiveStrategy': defensiveStrategy.name,
      'strategyWeights': strategyWeights.map(
        (key, value) => MapEntry(key, value.toString())
      ),
      'optimalRoles': optimalRoles.map((role) => role.name).toList(),
      'teamRequirements': teamRequirements.map(
        (key, value) => MapEntry(key, value.toString())
      ),
      'effectiveness': effectiveness.toString(),
    };
  }

  factory Playbook.fromMap(Map<String, dynamic> map) {
    return Playbook(
      name: map['name'] ?? 'Unknown Playbook',
      offensiveStrategy: OffensiveStrategy.values.firstWhere(
        (strategy) => strategy.name == (map['offensiveStrategy'] ?? 'halfCourt'),
        orElse: () => OffensiveStrategy.halfCourt,
      ),
      defensiveStrategy: DefensiveStrategy.values.firstWhere(
        (strategy) => strategy.name == (map['defensiveStrategy'] ?? 'manToMan'),
        orElse: () => DefensiveStrategy.manToMan,
      ),
      strategyWeights: (map['strategyWeights'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 1.0)
      ) ?? {},
      optimalRoles: (map['optimalRoles'] as List?)?.map(
        (roleStr) => PlayerRole.values.firstWhere(
          (role) => role.name == roleStr,
          orElse: () => PlayerRole.pointGuard,
        )
      ).toList() ?? [],
      teamRequirements: (map['teamRequirements'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 0.0)
      ) ?? {},
      effectiveness: double.tryParse(map['effectiveness']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

/// Playbook library for managing multiple playbooks
class PlaybookLibrary {
  List<Playbook> playbooks;
  Playbook? activePlaybook;

  PlaybookLibrary({
    List<Playbook>? playbooks,
    this.activePlaybook,
  }) : playbooks = playbooks ?? [];

  /// Initialize with default playbooks
  void initializeWithDefaults() {
    playbooks.clear();
    playbooks.addAll([
      Playbook(name: 'Run and Gun', offensiveStrategy: OffensiveStrategy.fastBreak, defensiveStrategy: DefensiveStrategy.pressDefense),
      Playbook(name: 'Defensive Minded', offensiveStrategy: OffensiveStrategy.halfCourt, defensiveStrategy: DefensiveStrategy.manToMan),
      Playbook(name: 'Three Point Shooters', offensiveStrategy: OffensiveStrategy.threePointHeavy, defensiveStrategy: DefensiveStrategy.zoneDefense),
      Playbook(name: 'Inside Game', offensiveStrategy: OffensiveStrategy.postUp, defensiveStrategy: DefensiveStrategy.manToMan),
      Playbook(name: 'Balanced Attack', offensiveStrategy: OffensiveStrategy.pickAndRoll, defensiveStrategy: DefensiveStrategy.switchDefense),
    ]);
    activePlaybook = playbooks.first;
  }

  Map<String, dynamic> toMap() {
    return {
      'playbooks': playbooks.map((pb) => pb.toMap()).toList(),
      'activePlaybook': activePlaybook?.name,
    };
  }

  factory PlaybookLibrary.fromMap(Map<String, dynamic> map) {
    List<Playbook> loadedPlaybooks = (map['playbooks'] as List?)?.map(
      (playbookMap) => Playbook.fromMap(playbookMap)
    ).toList() ?? [];
    
    String? activePlaybookName = map['activePlaybook'];
    Playbook? active;
    if (activePlaybookName != null) {
      try {
        active = loadedPlaybooks.firstWhere((pb) => pb.name == activePlaybookName);
      } catch (e) {
        active = loadedPlaybooks.isNotEmpty ? loadedPlaybooks.first : null;
      }
    }
    
    return PlaybookLibrary(
      playbooks: loadedPlaybooks,
      activePlaybook: active,
    );
  }
}

// Include all the supporting classes from the previous files
// (PlayerPotential, DevelopmentTracker, etc. - copying from enhanced_player.dart)

/// Player potential tracking for development system
class PlayerPotential {
  PotentialTier tier;
  Map<String, int> maxSkills;
  int overallPotential;
  bool isHidden; // Hidden potential for scouting mechanics

  PlayerPotential({
    required this.tier,
    required this.maxSkills,
    required this.overallPotential,
    this.isHidden = true,
  });

  factory PlayerPotential.defaultPotential() {
    return PlayerPotential(
      tier: PotentialTier.bronze,
      maxSkills: {
        'shooting': 75,
        'rebounding': 75,
        'passing': 75,
        'ballHandling': 75,
        'perimeterDefense': 75,
        'postDefense': 75,
        'insideShooting': 75,
      },
      overallPotential: 75,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier.name,
      'maxSkills': maxSkills.map((skill, max) => MapEntry(skill, max.toString())),
      'overallPotential': overallPotential.toString(),
      'isHidden': isHidden.toString(),
    };
  }

  factory PlayerPotential.fromMap(Map<String, dynamic> map) {
    return PlayerPotential(
      tier: PotentialTier.values.firstWhere(
        (tier) => tier.name == (map['tier'] ?? 'bronze'),
        orElse: () => PotentialTier.bronze,
      ),
      maxSkills: (map['maxSkills'] as Map<String, dynamic>?)?.map(
        (skill, maxStr) => MapEntry(skill, int.tryParse(maxStr.toString()) ?? 75)
      ) ?? {},
      overallPotential: int.tryParse(map['overallPotential']?.toString() ?? '75') ?? 75,
      isHidden: map['isHidden']?.toString().toLowerCase() == 'true',
    );
  }
}

/// Development tracking for player progression
class DevelopmentTracker {
  Map<String, int> skillExperience;
  int totalExperience;
  double developmentRate;
  List<DevelopmentMilestone> milestones;
  AgingCurve agingCurve;

  DevelopmentTracker({
    required this.skillExperience,
    required this.totalExperience,
    required this.developmentRate,
    required this.milestones,
    required this.agingCurve,
  });

  factory DevelopmentTracker.initial() {
    return DevelopmentTracker(
      skillExperience: {
        'shooting': 0,
        'rebounding': 0,
        'passing': 0,
        'ballHandling': 0,
        'perimeterDefense': 0,
        'postDefense': 0,
        'insideShooting': 0,
      },
      totalExperience: 0,
      developmentRate: 1.0,
      milestones: [],
      agingCurve: AgingCurve.standard(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skillExperience': skillExperience.map((skill, exp) => MapEntry(skill, exp.toString())),
      'totalExperience': totalExperience.toString(),
      'developmentRate': developmentRate.toString(),
      'milestones': milestones.map((milestone) => milestone.toMap()).toList(),
      'agingCurve': agingCurve.toMap(),
    };
  }

  factory DevelopmentTracker.fromMap(Map<String, dynamic> map) {
    return DevelopmentTracker(
      skillExperience: (map['skillExperience'] as Map<String, dynamic>?)?.map(
        (skill, expStr) => MapEntry(skill, int.tryParse(expStr.toString()) ?? 0)
      ) ?? {},
      totalExperience: int.tryParse(map['totalExperience']?.toString() ?? '0') ?? 0,
      developmentRate: double.tryParse(map['developmentRate']?.toString() ?? '1.0') ?? 1.0,
      milestones: (map['milestones'] as List?)?.map(
        (milestoneMap) => DevelopmentMilestone.fromMap(milestoneMap)
      ).toList() ?? [],
      agingCurve: map['agingCurve'] != null 
        ? AgingCurve.fromMap(map['agingCurve'])
        : AgingCurve.standard(),
    );
  }
}

/// Development milestones for tracking player progress
class DevelopmentMilestone {
  String name;
  String description;
  int experienceRequired;
  bool isAchieved;
  DateTime? achievedDate;

  DevelopmentMilestone({
    required this.name,
    required this.description,
    required this.experienceRequired,
    this.isAchieved = false,
    this.achievedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'experienceRequired': experienceRequired.toString(),
      'isAchieved': isAchieved.toString(),
      'achievedDate': achievedDate?.toIso8601String(),
    };
  }

  factory DevelopmentMilestone.fromMap(Map<String, dynamic> map) {
    return DevelopmentMilestone(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      experienceRequired: int.tryParse(map['experienceRequired']?.toString() ?? '0') ?? 0,
      isAchieved: map['isAchieved']?.toString().toLowerCase() == 'true',
      achievedDate: map['achievedDate'] != null 
        ? DateTime.tryParse(map['achievedDate'])
        : null,
    );
  }
}

/// Aging curve for player development and decline
class AgingCurve {
  int peakAge;
  int declineStartAge;
  double peakMultiplier;
  double declineRate;

  AgingCurve({
    required this.peakAge,
    required this.declineStartAge,
    required this.peakMultiplier,
    required this.declineRate,
  });

  factory AgingCurve.standard() {
    return AgingCurve(
      peakAge: 27,
      declineStartAge: 30,
      peakMultiplier: 1.2,
      declineRate: 0.02,
    );
  }

  /// Calculate development rate modifier based on age
  double getAgeModifier(int age) {
    if (age < peakAge) {
      // Young players develop faster
      return 1.0 + (peakAge - age) * 0.1;
    } else if (age < declineStartAge) {
      // Peak years
      return peakMultiplier;
    } else {
      // Decline years
      return (1.0 - (age - declineStartAge) * declineRate).clamp(0.1, 1.0);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'peakAge': peakAge.toString(),
      'declineStartAge': declineStartAge.toString(),
      'peakMultiplier': peakMultiplier.toString(),
      'declineRate': declineRate.toString(),
    };
  }

  factory AgingCurve.fromMap(Map<String, dynamic> map) {
    return AgingCurve(
      peakAge: int.tryParse(map['peakAge']?.toString() ?? '27') ?? 27,
      declineStartAge: int.tryParse(map['declineStartAge']?.toString() ?? '30') ?? 30,
      peakMultiplier: double.tryParse(map['peakMultiplier']?.toString() ?? '1.2') ?? 1.2,
      declineRate: double.tryParse(map['declineRate']?.toString() ?? '0.02') ?? 0.02,
    );
  }
}

/// Achievement system for coach progression
class Achievement {
  String name;
  String description;
  AchievementType type;
  DateTime unlockedDate;
  Map<String, dynamic> metadata;

  Achievement({
    required this.name,
    required this.description,
    required this.type,
    required this.unlockedDate,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'unlockedDate': unlockedDate.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: AchievementType.values.firstWhere(
        (type) => type.name == (map['type'] ?? 'experience'),
        orElse: () => AchievementType.experience,
      ),
      unlockedDate: DateTime.tryParse(map['unlockedDate'] ?? '') ?? DateTime.now(),
      metadata: map['metadata'] ?? {},
    );
  }
}

/// Coaching history tracking
class CoachingHistory {
  int totalWins;
  int totalLosses;
  int totalGames;
  int championships;
  int playoffAppearances;
  int totalExperience;
  List<SeasonRecord> seasonRecords;
  Map<String, int> playersDeveloped;

  CoachingHistory({
    required this.totalWins,
    required this.totalLosses,
    required this.totalGames,
    required this.championships,
    required this.playoffAppearances,
    required this.totalExperience,
    required this.seasonRecords,
    required this.playersDeveloped,
  });

  factory CoachingHistory.initial() {
    return CoachingHistory(
      totalWins: 0,
      totalLosses: 0,
      totalGames: 0,
      championships: 0,
      playoffAppearances: 0,
      totalExperience: 0,
      seasonRecords: [],
      playersDeveloped: {},
    );
  }

  /// Calculate win percentage
  double get winPercentage {
    if (totalGames == 0) return 0.0;
    return totalWins / totalGames;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWins': totalWins.toString(),
      'totalLosses': totalLosses.toString(),
      'totalGames': totalGames.toString(),
      'championships': championships.toString(),
      'playoffAppearances': playoffAppearances.toString(),
      'totalExperience': totalExperience.toString(),
      'seasonRecords': seasonRecords.map((record) => record.toMap()).toList(),
      'playersDeveloped': playersDeveloped.map(
        (player, improvements) => MapEntry(player, improvements.toString())
      ),
    };
  }

  factory CoachingHistory.fromMap(Map<String, dynamic> map) {
    return CoachingHistory(
      totalWins: int.tryParse(map['totalWins']?.toString() ?? '0') ?? 0,
      totalLosses: int.tryParse(map['totalLosses']?.toString() ?? '0') ?? 0,
      totalGames: int.tryParse(map['totalGames']?.toString() ?? '0') ?? 0,
      championships: int.tryParse(map['championships']?.toString() ?? '0') ?? 0,
      playoffAppearances: int.tryParse(map['playoffAppearances']?.toString() ?? '0') ?? 0,
      totalExperience: int.tryParse(map['totalExperience']?.toString() ?? '0') ?? 0,
      seasonRecords: (map['seasonRecords'] as List?)?.map(
        (recordMap) => SeasonRecord.fromMap(recordMap)
      ).toList() ?? [],
      playersDeveloped: (map['playersDeveloped'] as Map<String, dynamic>?)?.map(
        (player, improvementsStr) => MapEntry(player, int.tryParse(improvementsStr.toString()) ?? 0)
      ) ?? {},
    );
  }
}

/// Individual season record for coaching history
class SeasonRecord {
  int season;
  int wins;
  int losses;
  bool madePlayoffs;
  bool wonChampionship;
  String? teamName;

  SeasonRecord({
    required this.season,
    required this.wins,
    required this.losses,
    required this.madePlayoffs,
    required this.wonChampionship,
    this.teamName,
  });

  double get winPercentage => (wins + losses) > 0 ? wins / (wins + losses) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'season': season.toString(),
      'wins': wins.toString(),
      'losses': losses.toString(),
      'madePlayoffs': madePlayoffs.toString(),
      'wonChampionship': wonChampionship.toString(),
      'teamName': teamName,
    };
  }

  factory SeasonRecord.fromMap(Map<String, dynamic> map) {
    return SeasonRecord(
      season: int.tryParse(map['season']?.toString() ?? '1') ?? 1,
      wins: int.tryParse(map['wins']?.toString() ?? '0') ?? 0,
      losses: int.tryParse(map['losses']?.toString() ?? '0') ?? 0,
      madePlayoffs: map['madePlayoffs']?.toString().toLowerCase() == 'true',
      wonChampionship: map['wonChampionship']?.toString().toLowerCase() == 'true',
      teamName: map['teamName'],
    );
  }
}

/// Team branding information for real NBA teams
class TeamBranding {
  String primaryColor;
  String secondaryColor;
  String logoUrl;
  String abbreviation;
  String city;
  String mascot;

  TeamBranding({
    required this.primaryColor,
    required this.secondaryColor,
    required this.logoUrl,
    required this.abbreviation,
    required this.city,
    required this.mascot,
  });

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logoUrl': logoUrl,
      'abbreviation': abbreviation,
      'city': city,
      'mascot': mascot,
    };
  }

  factory TeamBranding.fromMap(Map<String, dynamic> map) {
    return TeamBranding(
      primaryColor: map['primaryColor'] ?? '#000000',
      secondaryColor: map['secondaryColor'] ?? '#FFFFFF',
      logoUrl: map['logoUrl'] ?? '',
      abbreviation: map['abbreviation'] ?? '',
      city: map['city'] ?? '',
      mascot: map['mascot'] ?? '',
    );
  }
}

/// Team history tracking
class TeamHistory {
  int foundedYear;
  int championships;
  int playoffAppearances;
  List<String> retiredNumbers;
  List<String> hallOfFamers;
  Map<String, String> rivalries;

  TeamHistory({
    required this.foundedYear,
    required this.championships,
    required this.playoffAppearances,
    required this.retiredNumbers,
    required this.hallOfFamers,
    required this.rivalries,
  });

  Map<String, dynamic> toMap() {
    return {
      'foundedYear': foundedYear.toString(),
      'championships': championships.toString(),
      'playoffAppearances': playoffAppearances.toString(),
      'retiredNumbers': retiredNumbers,
      'hallOfFamers': hallOfFamers,
      'rivalries': rivalries,
    };
  }

  factory TeamHistory.fromMap(Map<String, dynamic> map) {
    return TeamHistory(
      foundedYear: int.tryParse(map['foundedYear']?.toString() ?? '1946') ?? 1946,
      championships: int.tryParse(map['championships']?.toString() ?? '0') ?? 0,
      playoffAppearances: int.tryParse(map['playoffAppearances']?.toString() ?? '0') ?? 0,
      retiredNumbers: List<String>.from(map['retiredNumbers'] ?? []),
      hallOfFamers: List<String>.from(map['hallOfFamers'] ?? []),
      rivalries: Map<String, String>.from(map['rivalries'] ?? {}),
    );
  }
}