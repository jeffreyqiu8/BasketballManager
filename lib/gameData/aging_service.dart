import 'enhanced_player.dart';
import 'development_system.dart';
import 'enums.dart';

/// Service class for managing player aging and skill degradation
class AgingService {
  
  /// Process aging for a player (called at the end of each season)
  static AgingResult processPlayerAging(EnhancedPlayer player) {
    final agingResult = AgingResult(
      playerName: player.name,
      previousAge: player.age,
      skillChanges: {},
      shouldRetire: false,
      retirementReason: null,
    );

    // Age the player
    player.age++;
    agingResult.newAge = player.age;

    // Apply skill degradation based on age
    final degradationRate = player.development.agingCurve.getSkillDegradationRate(player.age);
    
    if (degradationRate > 0) {
      _applySkillDegradation(player, degradationRate, agingResult);
    }

    // Check for retirement
    _checkRetirement(player, agingResult);

    return agingResult;
  }

  /// Process aging for multiple players (batch processing)
  static List<AgingResult> processTeamAging(List<EnhancedPlayer> players) {
    return players.map((player) => processPlayerAging(player)).toList();
  }

  /// Apply gradual skill degradation for aging players
  static void _applySkillDegradation(EnhancedPlayer player, double degradationRate, AgingResult result) {
    final skills = ['shooting', 'rebounding', 'passing', 'ballHandling', 
                   'perimeterDefense', 'postDefense', 'insideShooting'];

    for (String skill in skills) {
      final currentValue = _getCurrentSkillValue(player, skill);
      final degradationAmount = _calculateSkillDegradation(skill, currentValue, degradationRate, player.age);
      
      if (degradationAmount > 0) {
        final newValue = (currentValue - degradationAmount).clamp(30, 99); // Minimum skill of 30
        _setSkillValue(player, skill, newValue);
        
        result.skillChanges[skill] = SkillChange(
          previousValue: currentValue,
          newValue: newValue,
          change: newValue - currentValue,
        );
      }
    }
  }

  /// Calculate skill degradation amount for a specific skill
  static int _calculateSkillDegradation(String skill, int currentValue, double baseRate, int age) {
    // Different skills degrade at different rates
    double skillMultiplier = _getSkillDegradationMultiplier(skill);
    
    // Higher skills degrade faster (elite players lose more)
    double valueMultiplier = currentValue > 80 ? 1.5 : 
                           currentValue > 70 ? 1.2 : 
                           currentValue > 60 ? 1.0 : 0.8;
    
    // Age-based multiplier (older players degrade faster)
    double ageMultiplier = age > 35 ? 2.0 :
                          age > 32 ? 1.5 :
                          age > 30 ? 1.0 : 0.5;
    
    double totalDegradation = baseRate * skillMultiplier * valueMultiplier * ageMultiplier * 100;
    
    // Add some randomness (±25%)
    final randomFactor = 0.75 + (DateTime.now().microsecond % 50) / 100.0;
    totalDegradation *= randomFactor;
    
    return totalDegradation.round().clamp(0, 3); // Maximum 3 points per year
  }

  /// Get skill-specific degradation multiplier
  static double _getSkillDegradationMultiplier(String skill) {
    switch (skill) {
      case 'shooting':
        return 0.8; // Shooting skills tend to last longer
      case 'rebounding':
        return 1.2; // Physical skills degrade faster
      case 'passing':
        return 0.6; // Mental skills degrade slower
      case 'ballHandling':
        return 0.9; // Moderate degradation
      case 'perimeterDefense':
        return 1.3; // Requires speed and agility
      case 'postDefense':
        return 1.1; // Physical but also positional
      case 'insideShooting':
        return 0.9; // Moderate degradation
      default:
        return 1.0;
    }
  }

  /// Check if player should retire
  static void _checkRetirement(EnhancedPlayer player, AgingResult result) {
    final overallSkill = _calculateOverallSkill(player);
    final agingCurve = player.development.agingCurve;
    
    // Mandatory retirement age
    if (player.age >= agingCurve.retirementAge + 2) {
      result.shouldRetire = true;
      result.retirementReason = RetirementReason.age;
      return;
    }

    // Performance-based retirement
    if (player.age >= agingCurve.declineStartAge + 3) {
      if (overallSkill < 45) {
        result.shouldRetire = true;
        result.retirementReason = RetirementReason.performance;
        return;
      }
    }

    // Injury-prone retirement (simulated)
    if (player.age >= agingCurve.retirementAge - 2) {
      final injuryChance = DateTime.now().millisecond % 100;
      if (injuryChance < 5) { // 5% chance
        result.shouldRetire = true;
        result.retirementReason = RetirementReason.injury;
        return;
      }
    }

    // Voluntary retirement for older players with declining skills
    if (player.age >= agingCurve.retirementAge - 1 && overallSkill < 60) {
      final retirementChance = DateTime.now().millisecond % 100;
      if (retirementChance < 15) { // 15% chance
        result.shouldRetire = true;
        result.retirementReason = RetirementReason.voluntary;
        return;
      }
    }
  }

  /// Create realistic aging curves for different player types
  static AgingCurve createCustomAgingCurve({
    required PlayerRole role,
    required int currentAge,
    required double overallSkill,
  }) {
    // Base aging curve
    int peakAge = 27;
    int declineStartAge = 30;
    double peakMultiplier = 1.2;
    double declineRate = 0.02;
    int retirementAge = 38;

    // Role-based adjustments
    switch (role) {
      case PlayerRole.pointGuard:
        // Point guards can play longer due to basketball IQ
        peakAge = 28;
        declineStartAge = 31;
        retirementAge = 39;
        declineRate = 0.018;
        break;
      case PlayerRole.shootingGuard:
        // Standard aging
        break;
      case PlayerRole.smallForward:
        // Versatile players, slightly longer careers
        retirementAge = 39;
        declineRate = 0.019;
        break;
      case PlayerRole.powerForward:
        // Physical position, earlier decline
        peakAge = 26;
        declineStartAge = 29;
        retirementAge = 37;
        declineRate = 0.022;
        break;
      case PlayerRole.center:
        // Most physical position, shortest careers
        peakAge = 25;
        declineStartAge = 28;
        retirementAge = 36;
        declineRate = 0.025;
        break;
    }

    // Skill-based adjustments
    if (overallSkill > 85) {
      // Elite players can extend careers
      retirementAge += 2;
      declineRate *= 0.9;
    } else if (overallSkill < 60) {
      // Lower skill players retire earlier
      retirementAge -= 2;
      declineRate *= 1.1;
    }

    // Age-based adjustments
    if (currentAge > 30) {
      // Already old, accelerate decline
      declineRate *= 1.2;
      retirementAge = (retirementAge - (currentAge - 30)).clamp(currentAge + 1, 45);
    }

    return AgingCurve(
      peakAge: peakAge,
      declineStartAge: declineStartAge,
      peakMultiplier: peakMultiplier,
      declineRate: declineRate,
      retirementAge: retirementAge,
    );
  }

  /// Simulate career progression for scouting/projection purposes
  static List<ProjectedSeason> projectCareerProgression(EnhancedPlayer player, int seasonsToProject) {
    final projections = <ProjectedSeason>[];
    final tempPlayer = EnhancedPlayer.fromPlayer(player); // Create a copy
    
    for (int season = 1; season <= seasonsToProject; season++) {
      final agingResult = processPlayerAging(tempPlayer);
      
      projections.add(ProjectedSeason(
        season: season,
        age: tempPlayer.age,
        projectedOverall: _calculateOverallSkill(tempPlayer),
        skillChanges: Map.from(agingResult.skillChanges),
        retirementProbability: _calculateRetirementProbability(tempPlayer),
      ));
      
      if (agingResult.shouldRetire) {
        break;
      }
    }
    
    return projections;
  }

  /// Calculate retirement probability for a player
  static double _calculateRetirementProbability(EnhancedPlayer player) {
    final agingCurve = player.development.agingCurve;
    final overallSkill = _calculateOverallSkill(player);
    
    if (player.age < agingCurve.declineStartAge) {
      return 0.0;
    }
    
    if (player.age >= agingCurve.retirementAge) {
      return 0.8 + (player.age - agingCurve.retirementAge) * 0.1;
    }
    
    // Base probability increases with age
    double baseProbability = (player.age - agingCurve.declineStartAge) * 0.05;
    
    // Skill-based adjustment
    if (overallSkill < 50) {
      baseProbability += 0.2;
    } else if (overallSkill > 80) {
      baseProbability -= 0.1;
    }
    
    return baseProbability.clamp(0.0, 0.95);
  }

  // Helper methods

  /// Get current skill value for a player
  static int _getCurrentSkillValue(EnhancedPlayer player, String skill) {
    switch (skill) {
      case 'shooting':
        return player.shooting;
      case 'rebounding':
        return player.rebounding;
      case 'passing':
        return player.passing;
      case 'ballHandling':
        return player.ballHandling;
      case 'perimeterDefense':
        return player.perimeterDefense;
      case 'postDefense':
        return player.postDefense;
      case 'insideShooting':
        return player.insideShooting;
      default:
        return 50;
    }
  }

  /// Set skill value for a player
  static void _setSkillValue(EnhancedPlayer player, String skill, int value) {
    switch (skill) {
      case 'shooting':
        player.shooting = value;
        break;
      case 'rebounding':
        player.rebounding = value;
        break;
      case 'passing':
        player.passing = value;
        break;
      case 'ballHandling':
        player.ballHandling = value;
        break;
      case 'perimeterDefense':
        player.perimeterDefense = value;
        break;
      case 'postDefense':
        player.postDefense = value;
        break;
      case 'insideShooting':
        player.insideShooting = value;
        break;
    }
  }

  /// Calculate overall skill rating for a player
  static double _calculateOverallSkill(EnhancedPlayer player) {
    return (player.shooting + 
            player.rebounding + 
            player.passing + 
            player.ballHandling + 
            player.perimeterDefense + 
            player.postDefense + 
            player.insideShooting) / 7.0;
  }
}

/// Result of aging process for a player
class AgingResult {
  String playerName;
  int previousAge;
  int newAge;
  Map<String, SkillChange> skillChanges;
  bool shouldRetire;
  RetirementReason? retirementReason;

  AgingResult({
    required this.playerName,
    required this.previousAge,
    this.newAge = 0,
    required this.skillChanges,
    required this.shouldRetire,
    this.retirementReason,
  });

  /// Get total skill points lost
  int get totalSkillLoss {
    return skillChanges.values
        .map((change) => change.change)
        .where((change) => change < 0)
        .fold(0, (sum, change) => sum + change.abs());
  }

  /// Get skills that declined
  List<String> get declinedSkills {
    return skillChanges.entries
        .where((entry) => entry.value.change < 0)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Individual skill change during aging
class SkillChange {
  int previousValue;
  int newValue;
  int change;

  SkillChange({
    required this.previousValue,
    required this.newValue,
    required this.change,
  });
}

/// Retirement reasons
enum RetirementReason {
  age('Reached retirement age'),
  performance('Performance decline'),
  injury('Injury concerns'),
  voluntary('Voluntary retirement');

  const RetirementReason(this.description);
  final String description;
}

/// Projected season for career progression
class ProjectedSeason {
  int season;
  int age;
  double projectedOverall;
  Map<String, SkillChange> skillChanges;
  double retirementProbability;

  ProjectedSeason({
    required this.season,
    required this.age,
    required this.projectedOverall,
    required this.skillChanges,
    required this.retirementProbability,
  });
}