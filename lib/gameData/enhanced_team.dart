import 'team_class.dart';
import 'enhanced_player.dart';
import 'enhanced_coach.dart';
import 'playbook.dart';
import 'enums.dart';
import 'package:BasketballManager/gameData/player_class.dart';

/// Enhanced team class that extends the base Team with role management and playbooks
class EnhancedTeam extends Team {
  PlaybookLibrary playbookLibrary;
  Map<PlayerRole, EnhancedPlayer?> roleAssignments;
  CoachProfile? coach;
  TeamBranding? branding;
  String? conference;
  String? division;
  TeamHistory? history;

  EnhancedTeam({
    required super.name,
    required super.reputation,
    required super.playerCount,
    required super.teamSize,
    required super.players,
    super.wins = 0,
    super.losses = 0,
    super.starters,
    
    // Enhanced properties
    PlaybookLibrary? playbookLibrary,
    Map<PlayerRole, EnhancedPlayer?>? roleAssignments,
    this.coach,
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
    
    // Auto-assign roles if not provided
    if (roleAssignments == null) {
      _autoAssignRoles();
    }
  }

  /// Automatically assign roles to players based on their attributes
  void _autoAssignRoles() {
    List<EnhancedPlayer> enhancedPlayers = players
        .whereType<EnhancedPlayer>()
        .cast<EnhancedPlayer>()
        .toList();
    
    if (enhancedPlayers.isEmpty) return;
    
    // Sort players by role compatibility for each position
    for (var role in PlayerRole.values) {
      if (roleAssignments[role] == null) {
        // Find best unassigned player for this role
        EnhancedPlayer? bestPlayer;
        double bestCompatibility = 0.0;
        
        for (var player in enhancedPlayers) {
          if (!roleAssignments.values.contains(player)) {
            double compatibility = player.calculateRoleCompatibility(role);
            if (compatibility > bestCompatibility) {
              bestCompatibility = compatibility;
              bestPlayer = player;
            }
          }
        }
        
        if (bestPlayer != null) {
          assignPlayerToRole(bestPlayer, role);
        }
      }
    }
  }

  /// Assign a player to a specific role
  bool assignPlayerToRole(EnhancedPlayer player, PlayerRole role) {
    if (!players.contains(player)) return false;
    
    // Remove player from previous role assignment
    roleAssignments.forEach((key, value) {
      if (value == player) {
        roleAssignments[key] = null;
      }
    });
    
    // Assign to new role
    roleAssignments[role] = player;
    player.primaryRole = role;
    player.roleCompatibility = player.calculateRoleCompatibility(role);
    
    return true;
  }

  /// Get starting lineup based on role assignments
  List<EnhancedPlayer> getStartingLineup() {
    List<EnhancedPlayer> lineup = [];
    
    for (var role in PlayerRole.values) {
      EnhancedPlayer? player = roleAssignments[role];
      if (player != null) {
        lineup.add(player);
      }
    }
    
    return lineup;
  }

  /// Validate that all positions are filled
  bool isLineupValid() {
    return roleAssignments.values.every((player) => player != null);
  }

  /// Calculate team statistics for playbook effectiveness
  Map<String, double> calculateTeamStats() {
    if (players.isEmpty) return {};
    
    List<EnhancedPlayer> enhancedPlayers = players
        .whereType<EnhancedPlayer>()
        .cast<EnhancedPlayer>()
        .toList();
    
    if (enhancedPlayers.isEmpty) return {};
    
    Map<String, double> stats = {};
    
    // Calculate average attributes
    stats['averageShooting'] = enhancedPlayers
        .map((p) => p.shooting.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averageRebounding'] = enhancedPlayers
        .map((p) => p.rebounding.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averagePassing'] = enhancedPlayers
        .map((p) => p.passing.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averageBallHandling'] = enhancedPlayers
        .map((p) => p.ballHandling.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averagePerimeterDefense'] = enhancedPlayers
        .map((p) => p.perimeterDefense.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averagePostDefense'] = enhancedPlayers
        .map((p) => p.postDefense.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    stats['averageInsideShooting'] = enhancedPlayers
        .map((p) => p.insideShooting.toDouble())
        .reduce((a, b) => a + b) / enhancedPlayers.length;
    
    // Calculate role-specific stats
    EnhancedPlayer? center = roleAssignments[PlayerRole.center];
    if (center != null) {
      stats['centerScreening'] = center.rebounding.toDouble(); // Use rebounding as proxy
      stats['centerPostMoves'] = center.insideShooting.toDouble();
    }
    
    EnhancedPlayer? pointGuard = roleAssignments[PlayerRole.pointGuard];
    if (pointGuard != null) {
      stats['guardBallHandling'] = pointGuard.ballHandling.toDouble();
    }
    
    return stats;
  }

  /// Update playbook effectiveness based on current roster
  void updatePlaybookEffectiveness() {
    Map<String, double> teamStats = calculateTeamStats();
    
    for (var playbook in playbookLibrary.playbooks) {
      playbook.calculateEffectiveness(teamStats);
    }
  }

  @override
  Map<String, dynamic> toMap() {
    var baseMap = super.toMap();
    baseMap.addAll({
      'playbookLibrary': playbookLibrary.toMap(),
      'roleAssignments': roleAssignments.map(
        (role, player) => MapEntry(role.name, player?.toMap())
      ),
      'branding': branding?.toMap(),
      'conference': conference,
      'division': division,
      'history': history?.toMap(),
    });
    return baseMap;
  }

  factory EnhancedTeam.fromMap(Map<String, dynamic> map) {
    // Create base team first
    var baseTeam = Team.fromMap(map);
    
    // Convert players to enhanced players if they aren't already
    List<EnhancedPlayer> enhancedPlayers = baseTeam.players.map((player) {
      if (player is EnhancedPlayer) {
        return player;
      } else {
        // Convert regular player to enhanced player
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
          primaryRole: PlayerRole.pointGuard, // Default role
        );
      }
    }).cast<EnhancedPlayer>().toList();
    
    // Parse role assignments
    Map<PlayerRole, EnhancedPlayer?> roleAssignments = {};
    if (map['roleAssignments'] != null) {
      (map['roleAssignments'] as Map<String, dynamic>).forEach((roleStr, playerMap) {
        PlayerRole role = PlayerRole.values.firstWhere(
          (r) => r.name == roleStr,
          orElse: () => PlayerRole.pointGuard,
        );
        
        if (playerMap != null) {
          // Find the corresponding enhanced player
          EnhancedPlayer? player = enhancedPlayers.firstWhere(
            (p) => p.name == playerMap['name'],
            orElse: () => enhancedPlayers.first,
          );
          roleAssignments[role] = player;
        } else {
          roleAssignments[role] = null;
        }
      });
    }
    
    return EnhancedTeam(
      name: baseTeam.name,
      reputation: baseTeam.reputation,
      playerCount: baseTeam.playerCount,
      teamSize: baseTeam.teamSize,
      players: List<Player>.from(enhancedPlayers),
      wins: baseTeam.wins,
      losses: baseTeam.losses,
      starters: List<Player>.from(enhancedPlayers.take(5)),
      
      // Enhanced properties
      playbookLibrary: map['playbookLibrary'] != null
        ? PlaybookLibrary.fromMap(map['playbookLibrary'])
        : PlaybookLibrary(),
      roleAssignments: roleAssignments,
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