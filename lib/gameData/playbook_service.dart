import 'playbook.dart';
import 'enhanced_team.dart';
import 'enhanced_player.dart';
import 'enums.dart';

/// Service class for managing playbook creation, modification, and effectiveness calculations
class PlaybookService {
  
  /// Create a new playbook with specified strategies
  static Playbook createPlaybook({
    required String name,
    required OffensiveStrategy offensiveStrategy,
    required DefensiveStrategy defensiveStrategy,
    Map<String, double>? customStrategyWeights,
    List<PlayerRole>? customOptimalRoles,
    Map<String, double>? customTeamRequirements,
  }) {
    return Playbook(
      name: name,
      offensiveStrategy: offensiveStrategy,
      defensiveStrategy: defensiveStrategy,
      strategyWeights: customStrategyWeights,
      optimalRoles: customOptimalRoles,
      teamRequirements: customTeamRequirements,
    );
  }

  /// Calculate strategy effectiveness based on team composition
  static double calculateStrategyEffectiveness(
    Playbook playbook,
    EnhancedTeam team,
  ) {
    Map<String, double> teamStats = team.calculateTeamStats();
    return playbook.calculateEffectiveness(teamStats);
  }

  /// Validate playbook-team compatibility
  static PlaybookCompatibilityResult validatePlaybookCompatibility(
    Playbook playbook,
    EnhancedTeam team,
  ) {
    Map<String, double> teamStats = team.calculateTeamStats();
    List<String> issues = [];
    List<String> recommendations = [];
    double overallCompatibility = 0.0;
    
    // Check team requirements
    for (var requirement in playbook.teamRequirements.entries) {
      String statName = requirement.key;
      double requiredValue = requirement.value;
      double teamValue = teamStats[statName] ?? 0.0;
      
      if (teamValue < requiredValue) {
        double deficit = requiredValue - teamValue;
        double deficitPercentage = (deficit / requiredValue) * 100;
        
        issues.add('Team ${_getStatDisplayName(statName)} is ${deficit.toStringAsFixed(1)} points below requirement (${deficitPercentage.toStringAsFixed(1)}% deficit)');
        
        // Suggest improvements
        recommendations.add(_getImprovementRecommendation(statName, deficit));
      }
    }
    
    // Check optimal roles coverage
    List<PlayerRole> missingOptimalRoles = [];
    for (var optimalRole in playbook.optimalRoles) {
      EnhancedPlayer? assignedPlayer = team.roleAssignments[optimalRole];
      if (assignedPlayer == null) {
        missingOptimalRoles.add(optimalRole);
      } else {
        double compatibility = assignedPlayer.calculateRoleCompatibility(optimalRole);
        if (compatibility < 0.7) {
          issues.add('${assignedPlayer.name} has low compatibility (${(compatibility * 100).toStringAsFixed(1)}%) for ${optimalRole.displayName} position');
          recommendations.add('Consider reassigning ${assignedPlayer.name} or finding a better ${optimalRole.displayName}');
        }
      }
    }
    
    if (missingOptimalRoles.isNotEmpty) {
      issues.add('Missing players for optimal roles: ${missingOptimalRoles.map((r) => r.displayName).join(', ')}');
      recommendations.add('Recruit or assign players to fill missing optimal roles');
    }
    
    // Calculate overall compatibility
    overallCompatibility = playbook.calculateEffectiveness(teamStats);
    
    return PlaybookCompatibilityResult(
      isCompatible: issues.isEmpty,
      overallCompatibility: overallCompatibility,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Get improvement recommendation for a specific stat
  static String _getImprovementRecommendation(String statName, double deficit) {
    switch (statName) {
      case 'averageShooting':
        return 'Recruit better shooters or focus on shooting development in training';
      case 'averageSpeed':
        return 'Recruit faster players or improve conditioning';
      case 'averageBallHandling':
        return 'Develop ball handling skills through training or recruit better ball handlers';
      case 'averagePassing':
        return 'Focus on passing drills and court vision development';
      case 'averagePerimeterDefense':
        return 'Improve perimeter defensive skills through training';
      case 'averagePostDefense':
        return 'Develop interior defensive skills and positioning';
      case 'averageInsideShooting':
        return 'Work on post moves and close-range shooting';
      case 'centerScreening':
        return 'Train your center in screening techniques and positioning';
      case 'guardBallHandling':
        return 'Focus on point guard ball handling development';
      default:
        return 'Focus on improving ${_getStatDisplayName(statName)} through targeted training';
    }
  }

  /// Get display name for stat
  static String _getStatDisplayName(String statName) {
    switch (statName) {
      case 'averageShooting':
        return 'Shooting';
      case 'averageSpeed':
        return 'Speed';
      case 'averageBallHandling':
        return 'Ball Handling';
      case 'averagePassing':
        return 'Passing';
      case 'averagePerimeterDefense':
        return 'Perimeter Defense';
      case 'averagePostDefense':
        return 'Post Defense';
      case 'averageInsideShooting':
        return 'Inside Shooting';
      case 'centerScreening':
        return 'Center Screening';
      case 'guardBallHandling':
        return 'Guard Ball Handling';
      default:
        return statName;
    }
  }

  /// Create default playbook templates for different team styles
  static List<Playbook> createDefaultPlaybookTemplates() {
    return [
      // Fast-paced, high-energy style
      Playbook.createPreset('run_and_gun'),
      
      // Defensive-focused, methodical style
      Playbook.createPreset('defensive_minded'),
      
      // Perimeter-oriented, three-point heavy
      Playbook.createPreset('three_point_shooters'),
      
      // Interior-focused, post-up heavy
      Playbook.createPreset('inside_game'),
      
      // Balanced, versatile approach
      Playbook.createPreset('balanced_attack'),
      
      // Additional specialized templates
      createPlaybook(
        name: 'Small Ball',
        offensiveStrategy: OffensiveStrategy.threePointHeavy,
        defensiveStrategy: DefensiveStrategy.switchDefense,
        customStrategyWeights: {
          'pace': 1.1,
          'shooting': 1.4,
          'spacing': 1.3,
          'versatility': 1.2,
          'speed': 1.2,
        },
        customOptimalRoles: [
          PlayerRole.pointGuard,
          PlayerRole.shootingGuard,
          PlayerRole.smallForward,
        ],
        customTeamRequirements: {
          'averageShooting': 78.0,
          'averageBallHandling': 72.0,
          'averagePerimeterDefense': 70.0,
        },
      ),
      
      createPlaybook(
        name: 'Twin Towers',
        offensiveStrategy: OffensiveStrategy.postUp,
        defensiveStrategy: DefensiveStrategy.zoneDefense,
        customStrategyWeights: {
          'insideShooting': 1.4,
          'rebounding': 1.3,
          'postMoves': 1.4,
          'teamDefense': 1.2,
        },
        customOptimalRoles: [
          PlayerRole.powerForward,
          PlayerRole.center,
        ],
        customTeamRequirements: {
          'averageInsideShooting': 80.0,
          'averageRebounding': 75.0,
          'centerScreening': 85.0,
        },
      ),
      
      createPlaybook(
        name: 'Motion Offense',
        offensiveStrategy: OffensiveStrategy.halfCourt,
        defensiveStrategy: DefensiveStrategy.manToMan,
        customStrategyWeights: {
          'ballMovement': 1.3,
          'spacing': 1.2,
          'basketballIQ': 1.3,
          'individualDefense': 1.1,
        },
        customOptimalRoles: PlayerRole.values,
        customTeamRequirements: {
          'averagePassing': 75.0,
          'averageBallHandling': 78.0,
          'averagePerimeterDefense': 72.0,
        },
      ),
    ];
  }

  /// Recommend playbooks based on team strengths
  static List<PlaybookRecommendation> recommendPlaybooks(EnhancedTeam team) {
    List<Playbook> allPlaybooks = createDefaultPlaybookTemplates();
    List<PlaybookRecommendation> recommendations = [];
    
    for (var playbook in allPlaybooks) {
      double effectiveness = calculateStrategyEffectiveness(playbook, team);
      PlaybookCompatibilityResult compatibility = validatePlaybookCompatibility(playbook, team);
      
      recommendations.add(PlaybookRecommendation(
        playbook: playbook,
        effectiveness: effectiveness,
        compatibility: compatibility,
        reason: _generateRecommendationReason(playbook, team, effectiveness),
      ));
    }
    
    // Sort by effectiveness
    recommendations.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
    
    return recommendations;
  }

  /// Generate recommendation reason based on team composition and playbook effectiveness
  static String _generateRecommendationReason(Playbook playbook, EnhancedTeam team, double effectiveness) {
    Map<String, double> teamStats = team.calculateTeamStats();
    
    if (effectiveness >= 0.8) {
      return 'Excellent fit - your team excels in the areas this playbook emphasizes';
    } else if (effectiveness >= 0.6) {
      return 'Good fit - your team has solid capabilities for this strategy';
    } else if (effectiveness >= 0.4) {
      return 'Moderate fit - some development needed to fully utilize this playbook';
    } else {
      return 'Poor fit - significant improvements needed for this strategy to be effective';
    }
  }

  /// Modify an existing playbook
  static Playbook modifyPlaybook(
    Playbook originalPlaybook, {
    String? newName,
    OffensiveStrategy? newOffensiveStrategy,
    DefensiveStrategy? newDefensiveStrategy,
    Map<String, double>? newStrategyWeights,
    List<PlayerRole>? newOptimalRoles,
    Map<String, double>? newTeamRequirements,
  }) {
    return Playbook(
      name: newName ?? originalPlaybook.name,
      offensiveStrategy: newOffensiveStrategy ?? originalPlaybook.offensiveStrategy,
      defensiveStrategy: newDefensiveStrategy ?? originalPlaybook.defensiveStrategy,
      strategyWeights: newStrategyWeights ?? Map.from(originalPlaybook.strategyWeights),
      optimalRoles: newOptimalRoles ?? List.from(originalPlaybook.optimalRoles),
      teamRequirements: newTeamRequirements ?? Map.from(originalPlaybook.teamRequirements),
    );
  }

  /// Get strategy synergy bonus between offensive and defensive strategies
  static double getStrategySynergy(OffensiveStrategy offensive, DefensiveStrategy defensive) {
    // Define strategy combinations that work well together
    Map<OffensiveStrategy, List<DefensiveStrategy>> synergyMap = {
      OffensiveStrategy.fastBreak: [DefensiveStrategy.pressDefense, DefensiveStrategy.switchDefense],
      OffensiveStrategy.halfCourt: [DefensiveStrategy.manToMan, DefensiveStrategy.zoneDefense],
      OffensiveStrategy.pickAndRoll: [DefensiveStrategy.switchDefense, DefensiveStrategy.manToMan],
      OffensiveStrategy.postUp: [DefensiveStrategy.zoneDefense, DefensiveStrategy.manToMan],
      OffensiveStrategy.threePointHeavy: [DefensiveStrategy.switchDefense, DefensiveStrategy.zoneDefense],
    };
    
    List<DefensiveStrategy>? compatibleDefenses = synergyMap[offensive];
    if (compatibleDefenses != null && compatibleDefenses.contains(defensive)) {
      return 1.1; // 10% synergy bonus
    }
    
    return 1.0; // No bonus
  }
}

/// Result of playbook compatibility validation
class PlaybookCompatibilityResult {
  final bool isCompatible;
  final double overallCompatibility;
  final List<String> issues;
  final List<String> recommendations;

  PlaybookCompatibilityResult({
    required this.isCompatible,
    required this.overallCompatibility,
    required this.issues,
    required this.recommendations,
  });
}

/// Playbook recommendation with effectiveness and reasoning
class PlaybookRecommendation {
  final Playbook playbook;
  final double effectiveness;
  final PlaybookCompatibilityResult compatibility;
  final String reason;

  PlaybookRecommendation({
    required this.playbook,
    required this.effectiveness,
    required this.compatibility,
    required this.reason,
  });
}