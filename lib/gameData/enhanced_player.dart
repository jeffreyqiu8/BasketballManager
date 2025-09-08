import 'player_class.dart';
import 'enums.dart';
import 'role_manager.dart';

/// Enhanced player class that extends the base Player with role and development features
class EnhancedPlayer extends Player {
  // Role-related properties
  PlayerRole primaryRole;
  PlayerRole? secondaryRole;
  double roleCompatibility;
  Map<PlayerRole, double> roleExperience;
  
  // Development-related properties
  PlayerPotential potential;
  DevelopmentTracker development;

  EnhancedPlayer({
    // Base Player properties
    required super.name,
    required super.age,
    required super.team,
    required super.experienceYears,
    required super.nationality,
    required super.currentStatus,
    required super.height,
    required super.shooting,
    required super.rebounding,
    required super.passing,
    required super.ballHandling,
    required super.perimeterDefense,
    required super.postDefense,
    required super.insideShooting,
    required super.performances,
    super.points = 0,
    super.rebounds = 0,
    super.assists = 0,
    super.gamesPlayed = 0,
    
    // Enhanced properties
    PlayerRole? primaryRole,
    this.secondaryRole,
    double? roleCompatibility,
    Map<PlayerRole, double>? roleExperience,
    PlayerPotential? potential,
    DevelopmentTracker? development,
  }) : roleExperience = roleExperience ?? {for (var role in PlayerRole.values) role: 0.0},
       potential = potential ?? PlayerPotential.defaultPotential(),
       development = development ?? DevelopmentTracker.initial(),
       primaryRole = primaryRole ?? PlayerRole.pointGuard,
       roleCompatibility = 0.0 {
    // If no primary role was specified, assign the best role
    if (primaryRole == null) {
      this.primaryRole = getBestRole();
    }
    
    // Calculate role compatibility after initialization
    this.roleCompatibility = roleCompatibility ?? calculateRoleCompatibility(this.primaryRole);
  }

  /// Calculate role compatibility based on player attributes and assigned role
  double calculateRoleCompatibility(PlayerRole role) {
    return RoleManager.calculateRoleCompatibility(this, role);
  }

  /// Get all role compatibilities for this player
  Map<PlayerRole, double> getAllRoleCompatibilities() {
    return RoleManager.getAllRoleCompatibilities(this);
  }

  /// Get the best role for this player
  PlayerRole getBestRole() {
    return RoleManager.getBestRole(this);
  }

  /// Validate role assignment
  bool isValidRoleAssignment(PlayerRole role) {
    final compatibility = calculateRoleCompatibility(role);
    return compatibility >= 0.6; // Minimum compatibility threshold
  }

  /// Assign a new primary role with validation
  bool assignPrimaryRole(PlayerRole newRole) {
    if (isValidRoleAssignment(newRole)) {
      primaryRole = newRole;
      roleCompatibility = calculateRoleCompatibility(newRole);
      return true;
    }
    return false;
  }

  /// Assign a secondary role with validation
  bool assignSecondaryRole(PlayerRole newRole) {
    if (newRole != primaryRole && isValidRoleAssignment(newRole)) {
      secondaryRole = newRole;
      return true;
    }
    return false;
  }

  /// Get role-based performance bonuses
  Map<String, double> getRoleBonuses() {
    return RoleManager.getRoleBonuses(this, primaryRole);
  }

  /// Get out-of-position penalties
  Map<String, double> getOutOfPositionPenalties() {
    return RoleManager.getOutOfPositionPenalties(this, primaryRole);
  }

  /// Calculate role-based performance modifiers for game simulation
  Map<String, double> calculateRoleBasedModifiers() {
    final bonuses = getRoleBonuses();
    final penalties = getOutOfPositionPenalties();
    
    // Combine bonuses and penalties
    final Map<String, double> modifiers = {};
    
    // Apply bonuses
    for (final entry in bonuses.entries) {
      modifiers[entry.key] = entry.value;
    }
    
    // Apply penalties (multiply with existing bonuses)
    for (final entry in penalties.entries) {
      modifiers[entry.key] = (modifiers[entry.key] ?? 1.0) * entry.value;
    }
    
    return modifiers;
  }

  /// Award experience for playing in a specific role
  void awardRoleExperience(PlayerRole role, double experience) {
    roleExperience[role] = (roleExperience[role] ?? 0.0) + experience;
    
    // Update role compatibility based on experience
    if (role == primaryRole) {
      roleCompatibility = (roleCompatibility + experience * 0.01).clamp(0.0, 1.0);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    var baseMap = super.toMap();
    baseMap.addAll({
      'primaryRole': primaryRole.name,
      'secondaryRole': secondaryRole?.name,
      'roleCompatibility': roleCompatibility.toString(),
      'roleExperience': roleExperience.map(
        (role, exp) => MapEntry(role.name, exp.toString())
      ),
      'potential': potential.toMap(),
      'development': development.toMap(),
    });
    return baseMap;
  }

  /// Create an EnhancedPlayer from a regular Player
  factory EnhancedPlayer.fromPlayer(Player player, {
    PlayerRole? primaryRole,
    PlayerRole? secondaryRole,
    PlayerPotential? potential,
    DevelopmentTracker? development,
  }) {
    return EnhancedPlayer(
      name: player.name,
      age: player.age,
      team: player.team,
      experienceYears: player.experienceYears,
      nationality: player.nationality,
      currentStatus: player.currentStatus,
      height: player.height,
      shooting: player.shooting,
      rebounding: player.rebounding,
      passing: player.passing,
      ballHandling: player.ballHandling,
      perimeterDefense: player.perimeterDefense,
      postDefense: player.postDefense,
      insideShooting: player.insideShooting,
      performances: player.performances,
      points: player.points,
      rebounds: player.rebounds,
      assists: player.assists,
      gamesPlayed: player.gamesPlayed,
      primaryRole: primaryRole,
      secondaryRole: secondaryRole,
      potential: potential,
      development: development,
    );
  }

  factory EnhancedPlayer.fromMap(Map<String, dynamic> map) {
    // Create base player first
    var basePlayer = Player.fromMap(map);
    
    return EnhancedPlayer(
      name: basePlayer.name,
      age: basePlayer.age,
      team: basePlayer.team,
      experienceYears: basePlayer.experienceYears,
      nationality: basePlayer.nationality,
      currentStatus: basePlayer.currentStatus,
      height: basePlayer.height,
      shooting: basePlayer.shooting,
      rebounding: basePlayer.rebounding,
      passing: basePlayer.passing,
      ballHandling: basePlayer.ballHandling,
      perimeterDefense: basePlayer.perimeterDefense,
      postDefense: basePlayer.postDefense,
      insideShooting: basePlayer.insideShooting,
      performances: basePlayer.performances,
      points: basePlayer.points,
      rebounds: basePlayer.rebounds,
      assists: basePlayer.assists,
      gamesPlayed: basePlayer.gamesPlayed,
      
      // Enhanced properties
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