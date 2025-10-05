import 'enhanced_coach.dart';
import 'enhanced_player.dart';
import 'enums.dart';

/// Service class to manage coach effects on team performance and player development
class CoachingService {
  
  /// Calculate team performance bonuses based on coach specializations
  static Map<String, double> calculateTeamBonuses(CoachProfile coach) {
    return coach.calculateTeamBonuses();
  }

  /// Apply coaching bonuses to team statistics during game simulation
  static Map<String, double> applyCoachingBonuses(
    Map<String, double> baseStats,
    CoachProfile coach,
  ) {
    final bonuses = coach.calculateTeamBonuses();
    final enhancedStats = Map<String, double>.from(baseStats);

    // Apply offensive bonuses
    if (bonuses.containsKey('offensiveRating')) {
      enhancedStats['offensiveRating'] = 
        (enhancedStats['offensiveRating'] ?? 100.0) * (1.0 + bonuses['offensiveRating']!);
      enhancedStats['fieldGoalPercentage'] = 
        (enhancedStats['fieldGoalPercentage'] ?? 0.45) * (1.0 + bonuses['offensiveRating']! * 0.5);
      enhancedStats['threePointPercentage'] = 
        (enhancedStats['threePointPercentage'] ?? 0.35) * (1.0 + bonuses['offensiveRating']! * 0.3);
    }

    // Apply defensive bonuses
    if (bonuses.containsKey('defensiveRating')) {
      enhancedStats['defensiveRating'] = 
        (enhancedStats['defensiveRating'] ?? 100.0) * (1.0 + bonuses['defensiveRating']!);
      enhancedStats['stealsPerGame'] = 
        (enhancedStats['stealsPerGame'] ?? 8.0) * (1.0 + bonuses['defensiveRating']! * 0.8);
      enhancedStats['blocksPerGame'] = 
        (enhancedStats['blocksPerGame'] ?? 5.0) * (1.0 + bonuses['defensiveRating']! * 0.6);
    }

    // Apply team chemistry bonuses
    if (bonuses.containsKey('teamChemistry')) {
      enhancedStats['assistsPerGame'] = 
        (enhancedStats['assistsPerGame'] ?? 25.0) * (1.0 + bonuses['teamChemistry']!);
      enhancedStats['turnoversPerGame'] = 
        (enhancedStats['turnoversPerGame'] ?? 15.0) * (1.0 - bonuses['teamChemistry']! * 0.5);
    }

    return enhancedStats;
  }

  /// Calculate player development rate modifiers based on coach specialization
  static double calculateDevelopmentRateModifier(
    CoachProfile coach,
    EnhancedPlayer player,
  ) {
    double baseModifier = 1.0;
    final bonuses = coach.calculateTeamBonuses();

    // Development-specialized coaches provide bonus development rates
    if (bonuses.containsKey('developmentRate')) {
      baseModifier += bonuses['developmentRate']!;
    }

    // Additional bonuses based on coach-player compatibility
    if (coach.primarySpecialization == CoachingSpecialization.playerDevelopment) {
      // Young players benefit more from development coaches
      if (player.age < 25) {
        baseModifier += 0.2;
      }
      
      // Players with high potential benefit more
      final potentialBonus = _getPotentialBonus(player.potential);
      baseModifier += potentialBonus;
    }

    // Experience level provides additional development bonuses
    final experienceBonus = (coach.experienceLevel - 1) * 0.05;
    baseModifier += experienceBonus;

    return baseModifier;
  }

  /// Get potential-based development bonus
  static double _getPotentialBonus(dynamic potential) {
    // Higher potential players benefit more from good coaching
    if (potential == null) return 0.0;
    
    try {
      final averagePotential = potential.maxSkills.values
          .fold<double>(0.0, (sum, value) => sum + value) / 
          potential.maxSkills.length;
      
      if (averagePotential >= 90) return 0.15; // Elite potential
      if (averagePotential >= 80) return 0.10; // High potential
      if (averagePotential >= 70) return 0.05; // Good potential
      return 0.0; // Average or below potential
    } catch (e) {
      return 0.0; // Fallback if potential structure is unexpected
    }
  }

  /// Apply coaching effects to player experience gain
  static int applyCoachingToExperience(
    int baseExperience,
    CoachProfile coach,
    EnhancedPlayer player,
  ) {
    final modifier = calculateDevelopmentRateModifier(coach, player);
    return (baseExperience * modifier).round();
  }

  /// Calculate coaching effectiveness rating (0-100)
  static double calculateCoachingEffectiveness(CoachProfile coach) {
    // Base effectiveness from coaching attributes
    final attributeAverage = coach.coachingAttributes.values
        .fold<double>(0.0, (sum, value) => sum + value) / 
        coach.coachingAttributes.length;
    
    // Experience multiplier
    final experienceMultiplier = 1.0 + (coach.experienceLevel - 1) * 0.1;
    
    // Achievement bonus
    final achievementBonus = coach.achievements.length * 2.0;
    
    // Win percentage bonus from history
    final winPercentageBonus = coach.history.winPercentage * 10.0;
    
    final effectiveness = (attributeAverage * experienceMultiplier + 
                          achievementBonus + 
                          winPercentageBonus).clamp(0.0, 100.0);
    
    return effectiveness;
  }

  /// Get coaching recommendations based on team composition
  static List<String> getCoachingRecommendations(
    CoachProfile coach,
    List<EnhancedPlayer> teamRoster,
  ) {
    final recommendations = <String>[];
    
    // Analyze team composition
    final youngPlayers = teamRoster.where((p) => p.age < 25).length;
    final veteranPlayers = teamRoster.where((p) => p.age > 30).length;
    final averageOffensive = teamRoster
        .map((p) => (p.shooting + p.insideShooting + p.ballHandling) / 3.0)
        .fold<double>(0.0, (sum, rating) => sum + rating) / teamRoster.length;
    final averageDefensive = teamRoster
        .map((p) => (p.perimeterDefense + p.postDefense) / 2.0)
        .fold<double>(0.0, (sum, rating) => sum + rating) / teamRoster.length;

    // Provide recommendations based on coach specialization and team needs
    if (coach.primarySpecialization == CoachingSpecialization.playerDevelopment) {
      if (youngPlayers >= 3) {
        recommendations.add('Focus on developing young talent - you have $youngPlayers players under 25');
      }
      if (youngPlayers < 2) {
        recommendations.add('Consider acquiring younger players to maximize your development specialization');
      }
    }

    if (coach.primarySpecialization == CoachingSpecialization.offensive) {
      if (averageOffensive < 75) {
        recommendations.add('Your offensive specialization can help improve team scoring (current avg: ${averageOffensive.toStringAsFixed(1)})');
      }
    }

    if (coach.primarySpecialization == CoachingSpecialization.defensive) {
      if (averageDefensive < 75) {
        recommendations.add('Focus on defensive schemes to improve team defense (current avg: ${averageDefensive.toStringAsFixed(1)})');
      }
    }

    if (coach.primarySpecialization == CoachingSpecialization.teamChemistry) {
      if (veteranPlayers >= 3 && youngPlayers >= 3) {
        recommendations.add('Your chemistry specialization is perfect for blending veterans and young players');
      }
    }

    // Experience-based recommendations
    if (coach.experienceLevel < 3) {
      recommendations.add('Gain more experience to unlock additional coaching bonuses');
    }

    // Achievement-based recommendations
    if (coach.achievements.isEmpty) {
      recommendations.add('Work towards your first coaching achievement to boost effectiveness');
    }

    return recommendations;
  }

  /// Update coach after game completion
  static void updateCoachAfterGame(
    CoachProfile coach,
    bool won,
    int teamPerformanceRating, // 0-100
    List<EnhancedPlayer> developedPlayers,
  ) {
    // Award base experience
    int experienceGained = won ? 50 : 25;
    
    // Bonus experience for good team performance
    if (teamPerformanceRating > 80) {
      experienceGained += 25;
    } else if (teamPerformanceRating > 60) {
      experienceGained += 10;
    }
    
    // Bonus experience for player development (for development coaches)
    if (coach.primarySpecialization == CoachingSpecialization.playerDevelopment) {
      experienceGained += developedPlayers.length * 5;
      
      // Track players developed
      for (final player in developedPlayers) {
        coach.history.playersDeveloped[player.name] = 
          (coach.history.playersDeveloped[player.name] ?? 0) + 1;
      }
    }
    
    coach.awardExperience(experienceGained);
  }

  /// Calculate coaching salary based on effectiveness and experience
  static int calculateCoachingSalary(CoachProfile coach) {
    final basesalary = 500000; // $500k base
    final effectivenessMultiplier = calculateCoachingEffectiveness(coach) / 100.0;
    final experienceMultiplier = 1.0 + (coach.experienceLevel - 1) * 0.15;
    final achievementBonus = coach.achievements.length * 50000;
    final championshipBonus = coach.history.championships * 200000;
    
    final totalSalary = (basesalary * effectivenessMultiplier * experienceMultiplier + 
                        achievementBonus + 
                        championshipBonus).round();
    
    return totalSalary;
  }
}