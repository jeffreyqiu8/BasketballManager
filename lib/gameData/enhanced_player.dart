import 'player_class.dart';
import 'enums.dart';
import 'role_manager.dart';
import 'development_system.dart';

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

