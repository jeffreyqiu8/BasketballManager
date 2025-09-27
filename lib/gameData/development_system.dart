import 'enums.dart';

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

  /// Create default potential for new players
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

  /// Create potential based on tier
  factory PlayerPotential.fromTier(PotentialTier tier, {bool isHidden = true}) {
    Map<String, int> maxSkills;
    int overallPotential;

    switch (tier) {
      case PotentialTier.bronze:
        overallPotential = 70 + (DateTime.now().millisecond % 10); // 70-79
        maxSkills = _generateSkillCaps(overallPotential, 5);
        break;
      case PotentialTier.silver:
        overallPotential = 80 + (DateTime.now().millisecond % 10); // 80-89
        maxSkills = _generateSkillCaps(overallPotential, 8);
        break;
      case PotentialTier.gold:
        overallPotential = 90 + (DateTime.now().millisecond % 8); // 90-97
        maxSkills = _generateSkillCaps(overallPotential, 10);
        break;
      case PotentialTier.elite:
        overallPotential = 95 + (DateTime.now().millisecond % 5); // 95-99
        maxSkills = _generateSkillCaps(overallPotential, 12);
        break;
    }

    return PlayerPotential(
      tier: tier,
      maxSkills: maxSkills,
      overallPotential: overallPotential,
      isHidden: isHidden,
    );
  }

  /// Generate skill caps based on overall potential
  static Map<String, int> _generateSkillCaps(int overallPotential, int variance) {
    final skills = ['shooting', 'rebounding', 'passing', 'ballHandling', 
                   'perimeterDefense', 'postDefense', 'insideShooting'];
    final Map<String, int> skillCaps = {};

    for (String skill in skills) {
      // Add some randomness to skill caps while keeping them around overall potential
      int cap = overallPotential + (DateTime.now().microsecond % (variance * 2)) - variance;
      skillCaps[skill] = cap.clamp(50, 99);
    }

    return skillCaps;
  }

  /// Check if a skill can be improved
  bool canImproveSkill(String skill, int currentValue) {
    return currentValue < (maxSkills[skill] ?? 99);
  }

  /// Get remaining potential for a skill
  int getRemainingPotential(String skill, int currentValue) {
    return ((maxSkills[skill] ?? 99) - currentValue).clamp(0, 99);
  }

  /// Reveal hidden potential (for scouting)
  void revealPotential() {
    isHidden = false;
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
      ) ?? PlayerPotential.defaultPotential().maxSkills,
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
  DateTime lastDevelopmentUpdate;

  DevelopmentTracker({
    required this.skillExperience,
    required this.totalExperience,
    required this.developmentRate,
    required this.milestones,
    required this.agingCurve,
    DateTime? lastDevelopmentUpdate,
  }) : lastDevelopmentUpdate = lastDevelopmentUpdate ?? DateTime.now();

  /// Create initial development tracker for new players
  factory DevelopmentTracker.initial({int? age}) {
    final agingCurve = age != null ? AgingCurve.forAge(age) : AgingCurve.standard();
    
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
      milestones: _createInitialMilestones(),
      agingCurve: agingCurve,
    );
  }

  /// Create initial milestones for player development
  static List<DevelopmentMilestone> _createInitialMilestones() {
    return [
      DevelopmentMilestone(
        name: 'First Steps',
        description: 'Gain your first 100 experience points',
        experienceRequired: 100,
      ),
      DevelopmentMilestone(
        name: 'Rising Talent',
        description: 'Accumulate 500 experience points',
        experienceRequired: 500,
      ),
      DevelopmentMilestone(
        name: 'Experienced Player',
        description: 'Reach 1000 experience points',
        experienceRequired: 1000,
      ),
      DevelopmentMilestone(
        name: 'Veteran',
        description: 'Achieve 2500 experience points',
        experienceRequired: 2500,
      ),
      DevelopmentMilestone(
        name: 'Elite Performer',
        description: 'Accumulate 5000 experience points',
        experienceRequired: 5000,
      ),
    ];
  }

  /// Add experience to a specific skill
  void addSkillExperience(String skill, int experience) {
    skillExperience[skill] = (skillExperience[skill] ?? 0) + experience;
    totalExperience += experience;
    lastDevelopmentUpdate = DateTime.now();
    
    // Check for milestone achievements
    _checkMilestones();
  }

  /// Add general experience (distributed across skills)
  void addGeneralExperience(int experience) {
    final skills = skillExperience.keys.toList();
    final experiencePerSkill = experience ~/ skills.length;
    final remainder = experience % skills.length;

    for (int i = 0; i < skills.length; i++) {
      int skillExp = experiencePerSkill;
      if (i < remainder) skillExp++; // Distribute remainder
      
      addSkillExperience(skills[i], skillExp);
    }
  }

  /// Check and update milestone achievements
  void _checkMilestones() {
    for (var milestone in milestones) {
      if (!milestone.isAchieved && totalExperience >= milestone.experienceRequired) {
        milestone.achieve();
      }
    }
  }

  /// Get experience required for next skill point in a specific skill
  int getExperienceForNextSkillPoint(String skill) {
    final currentExp = skillExperience[skill] ?? 0;
    // Experience required increases with each skill point (quadratic growth)
    final currentLevel = (currentExp / 100).floor();
    final nextLevel = currentLevel + 1;
    return nextLevel * 100;
  }

  /// Check if player has enough experience to upgrade a skill
  bool hasEnoughExperienceForUpgrade(String skill) {
    final currentExp = skillExperience[skill] ?? 0;
    // First upgrade costs 100, second costs 200, etc.
    // So if player has 100 exp, they can do first upgrade
    // If they have 300 exp, they can do second upgrade (100 + 200)
    return currentExp >= 100;
  }

  /// Check if a skill can be upgraded
  bool canUpgradeSkill(String skill, PlayerPotential potential, int currentSkillValue) {
    final hasExperience = hasEnoughExperienceForUpgrade(skill);
    final withinPotential = potential.canImproveSkill(skill, currentSkillValue);
    
    return hasExperience && withinPotential;
  }

  /// Consume experience to upgrade a skill
  bool upgradeSkill(String skill, PlayerPotential potential, int currentSkillValue) {
    if (!canUpgradeSkill(skill, potential, currentSkillValue)) {
      return false;
    }

    final currentExp = skillExperience[skill] ?? 0;
    final currentLevel = (currentExp / 100).floor();
    final expToConsume = (currentLevel + 1) * 100;
    skillExperience[skill] = currentExp - expToConsume;
    return true;
  }

  /// Get current development rate based on age and other factors
  double getCurrentDevelopmentRate(int age, {double coachBonus = 0.0}) {
    final ageModifier = agingCurve.getAgeModifier(age);
    return (developmentRate * ageModifier + coachBonus).clamp(0.1, 3.0);
  }

  /// Update development rate based on external factors
  void updateDevelopmentRate(double newRate) {
    developmentRate = newRate.clamp(0.1, 2.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'skillExperience': skillExperience.map((skill, exp) => MapEntry(skill, exp.toString())),
      'totalExperience': totalExperience.toString(),
      'developmentRate': developmentRate.toString(),
      'milestones': milestones.map((milestone) => milestone.toMap()).toList(),
      'agingCurve': agingCurve.toMap(),
      'lastDevelopmentUpdate': lastDevelopmentUpdate.toIso8601String(),
    };
  }

  factory DevelopmentTracker.fromMap(Map<String, dynamic> map) {
    return DevelopmentTracker(
      skillExperience: (map['skillExperience'] as Map<String, dynamic>?)?.map(
        (skill, expStr) => MapEntry(skill, int.tryParse(expStr.toString()) ?? 0)
      ) ?? DevelopmentTracker.initial().skillExperience,
      totalExperience: int.tryParse(map['totalExperience']?.toString() ?? '0') ?? 0,
      developmentRate: double.tryParse(map['developmentRate']?.toString() ?? '1.0') ?? 1.0,
      milestones: (map['milestones'] as List?)?.map(
        (milestoneMap) => DevelopmentMilestone.fromMap(milestoneMap)
      ).toList() ?? _createInitialMilestones(),
      agingCurve: map['agingCurve'] != null 
        ? AgingCurve.fromMap(map['agingCurve'])
        : AgingCurve.standard(),
      lastDevelopmentUpdate: map['lastDevelopmentUpdate'] != null
        ? DateTime.tryParse(map['lastDevelopmentUpdate']) ?? DateTime.now()
        : DateTime.now(),
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

  /// Mark milestone as achieved
  void achieve() {
    if (!isAchieved) {
      isAchieved = true;
      achievedDate = DateTime.now();
    }
  }

  /// Reset milestone (for testing purposes)
  void reset() {
    isAchieved = false;
    achievedDate = null;
  }

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
  int retirementAge;

  AgingCurve({
    required this.peakAge,
    required this.declineStartAge,
    required this.peakMultiplier,
    required this.declineRate,
    required this.retirementAge,
  });

  /// Create standard aging curve
  factory AgingCurve.standard() {
    return AgingCurve(
      peakAge: 27,
      declineStartAge: 30,
      peakMultiplier: 1.2,
      declineRate: 0.02,
      retirementAge: 38,
    );
  }

  /// Create aging curve optimized for a specific age
  factory AgingCurve.forAge(int age) {
    if (age < 22) {
      // Young player - longer development period
      return AgingCurve(
        peakAge: 28,
        declineStartAge: 32,
        peakMultiplier: 1.3,
        declineRate: 0.015,
        retirementAge: 40,
      );
    } else if (age > 30) {
      // Older player - shorter peak, faster decline
      return AgingCurve(
        peakAge: 25,
        declineStartAge: 28,
        peakMultiplier: 1.1,
        declineRate: 0.03,
        retirementAge: 35,
      );
    } else {
      return AgingCurve.standard();
    }
  }

  /// Calculate development rate modifier based on age
  double getAgeModifier(int age) {
    if (age < peakAge) {
      // Young players develop faster (linear increase to peak)
      double youngBonus = (peakAge - age) * 0.05;
      return (1.0 + youngBonus).clamp(1.0, 2.0);
    } else if (age < declineStartAge) {
      // Peak years - maximum development rate
      return peakMultiplier;
    } else if (age < retirementAge) {
      // Decline years - decreasing development rate
      double yearsInDecline = (age - declineStartAge).toDouble();
      return (peakMultiplier - (yearsInDecline * declineRate)).clamp(0.1, peakMultiplier);
    } else {
      // Post-retirement age - minimal development
      return 0.1;
    }
  }

  /// Calculate skill degradation rate for aging players
  double getSkillDegradationRate(int age) {
    if (age < declineStartAge) {
      return 0.0; // No degradation before decline starts
    } else if (age < retirementAge) {
      // Gradual degradation during decline years
      double yearsInDecline = (age - declineStartAge).toDouble();
      return (yearsInDecline * declineRate * 0.5).clamp(0.0, 0.1);
    } else {
      // Rapid degradation post-retirement age
      return 0.15;
    }
  }

  /// Check if player should consider retirement
  bool shouldConsiderRetirement(int age, double overallSkill) {
    if (age >= retirementAge) return true;
    if (age >= declineStartAge + 5 && overallSkill < 50) return true;
    return false;
  }

  Map<String, dynamic> toMap() {
    return {
      'peakAge': peakAge.toString(),
      'declineStartAge': declineStartAge.toString(),
      'peakMultiplier': peakMultiplier.toString(),
      'declineRate': declineRate.toString(),
      'retirementAge': retirementAge.toString(),
    };
  }

  factory AgingCurve.fromMap(Map<String, dynamic> map) {
    return AgingCurve(
      peakAge: int.tryParse(map['peakAge']?.toString() ?? '27') ?? 27,
      declineStartAge: int.tryParse(map['declineStartAge']?.toString() ?? '30') ?? 30,
      peakMultiplier: double.tryParse(map['peakMultiplier']?.toString() ?? '1.2') ?? 1.2,
      declineRate: double.tryParse(map['declineRate']?.toString() ?? '0.02') ?? 0.02,
      retirementAge: int.tryParse(map['retirementAge']?.toString() ?? '38') ?? 38,
    );
  }
}