import 'enhanced_player.dart';
import 'development_system.dart';
import 'enhanced_coach.dart';
import 'enums.dart';

/// Service class for managing player development and experience
class DevelopmentService {
  
  /// Award experience to a player based on game performance
  static void awardGameExperience(EnhancedPlayer player, Map<String, int> gameStats) {
    final baseExperience = _calculateBaseExperience(gameStats);
    final ageModifier = player.development.agingCurve.getAgeModifier(player.age);
    final totalExperience = (baseExperience * ageModifier).round();
    
    // Distribute experience based on performance
    _distributeExperienceByPerformance(player, gameStats, totalExperience);
  }

  /// Award experience with coaching bonuses
  static void awardExperienceWithCoaching(
    EnhancedPlayer player, 
    Map<String, int> gameStats, 
    CoachProfile? coach
  ) {
    final baseExperience = _calculateBaseExperience(gameStats);
    final ageModifier = player.development.agingCurve.getAgeModifier(player.age);
    final coachBonus = coach?.getDevelopmentBonus() ?? 0.0;
    
    final totalExperience = (baseExperience * ageModifier * (1.0 + coachBonus)).round();
    
    // Distribute experience based on performance
    _distributeExperienceByPerformance(player, gameStats, totalExperience);
  }

  /// Award training experience (focused on specific skills)
  static void awardTrainingExperience(
    EnhancedPlayer player, 
    String focusSkill, 
    int trainingIntensity,
    CoachProfile? coach
  ) {
    final baseExp = trainingIntensity * 10; // Base experience from training
    final ageModifier = player.development.agingCurve.getAgeModifier(player.age);
    final coachBonus = coach?.getDevelopmentBonus() ?? 0.0;
    
    final totalExp = (baseExp * ageModifier * (1.0 + coachBonus)).round();
    
    // Award 70% to focus skill, 30% distributed to related skills
    final focusExp = (totalExp * 0.7).round();
    final distributedExp = totalExp - focusExp;
    
    player.development.addSkillExperience(focusSkill, focusExp);
    
    // Distribute remaining experience to related skills
    final relatedSkills = _getRelatedSkills(focusSkill);
    final expPerRelated = distributedExp ~/ relatedSkills.length;
    
    for (String skill in relatedSkills) {
      player.development.addSkillExperience(skill, expPerRelated);
    }
  }

  /// Process skill development for a player (upgrade skills with available experience)
  static List<String> processSkillDevelopment(EnhancedPlayer player) {
    final upgradedSkills = <String>[];
    
    // Try to upgrade each skill if possible
    for (String skill in player.development.skillExperience.keys) {
      final currentSkillValue = _getCurrentSkillValue(player, skill);
      
      while (player.development.canUpgradeSkill(skill, player.potential, currentSkillValue)) {
        if (player.development.upgradeSkill(skill, player.potential, currentSkillValue)) {
          _applySkillUpgrade(player, skill);
          upgradedSkills.add(skill);
        } else {
          break; // Can't upgrade anymore
        }
      }
    }
    
    return upgradedSkills;
  }

  /// Apply age-based development rate modifiers
  static void updateDevelopmentRate(EnhancedPlayer player, CoachProfile? coach) {
    final baseRate = 1.0;
    final ageModifier = player.development.agingCurve.getAgeModifier(player.age);
    final coachBonus = coach?.getDevelopmentBonus() ?? 0.0;
    
    final newRate = (baseRate * ageModifier + coachBonus).clamp(0.1, 3.0);
    player.development.updateDevelopmentRate(newRate);
  }

  /// Calculate potential tier based on player attributes and age
  static PotentialTier calculatePotentialTier(EnhancedPlayer player) {
    final overallSkill = _calculateOverallSkill(player);
    final age = player.age;
    
    // Younger players have higher potential ceiling
    if (age <= 22) {
      if (overallSkill >= 85) return PotentialTier.elite;
      if (overallSkill >= 75) return PotentialTier.gold;
      if (overallSkill >= 65) return PotentialTier.silver;
      return PotentialTier.bronze;
    } else if (age <= 26) {
      if (overallSkill >= 90) return PotentialTier.elite;
      if (overallSkill >= 80) return PotentialTier.gold;
      if (overallSkill >= 70) return PotentialTier.silver;
      return PotentialTier.bronze;
    } else {
      // Older players have limited potential
      if (overallSkill >= 95) return PotentialTier.gold;
      if (overallSkill >= 85) return PotentialTier.silver;
      return PotentialTier.bronze;
    }
  }

  /// Generate realistic potential for a new player
  static PlayerPotential generatePlayerPotential(int age, PlayerRole role) {
    final tier = _generatePotentialTier(age);
    final potential = PlayerPotential.fromTier(tier);
    
    // Adjust potential based on role
    _adjustPotentialForRole(potential, role);
    
    return potential;
  }

  // Private helper methods

  /// Calculate base experience from game statistics
  static int _calculateBaseExperience(Map<String, int> gameStats) {
    int experience = 0;
    
    // Base experience for playing
    experience += 20;
    
    // Bonus experience for good performance
    experience += (gameStats['points'] ?? 0) * 2;
    experience += (gameStats['rebounds'] ?? 0) * 3;
    experience += (gameStats['assists'] ?? 0) * 4;
    experience += (gameStats['FGM'] ?? 0) * 2;
    experience += (gameStats['3PM'] ?? 0) * 3;
    
    // Penalty for poor shooting
    final fga = gameStats['FGA'] ?? 1;
    final fgm = gameStats['FGM'] ?? 0;
    if (fga > 0 && (fgm / fga) < 0.3) {
      experience -= 10; // Penalty for poor shooting
    }
    
    return experience.clamp(10, 200); // Minimum 10, maximum 200 per game
  }

  /// Distribute experience based on performance in different areas
  static void _distributeExperienceByPerformance(
    EnhancedPlayer player, 
    Map<String, int> gameStats, 
    int totalExperience
  ) {
    final distribution = <String, double>{};
    
    // Calculate performance weights
    final points = gameStats['points'] ?? 0;
    final rebounds = gameStats['rebounds'] ?? 0;
    final assists = gameStats['assists'] ?? 0;
    final fgm = gameStats['FGM'] ?? 0;
    final threePM = gameStats['3PM'] ?? 0;
    
    // Shooting experience
    distribution['shooting'] = (points * 0.3 + fgm * 0.4 + threePM * 0.3);
    distribution['insideShooting'] = (points * 0.2 + (fgm - threePM) * 0.8);
    
    // Rebounding experience
    distribution['rebounding'] = rebounds * 1.0;
    
    // Passing experience
    distribution['passing'] = assists * 1.0;
    
    // Ball handling (based on assists and role)
    distribution['ballHandling'] = assists * 0.5;
    if (player.primaryRole == PlayerRole.pointGuard) {
      distribution['ballHandling'] = (distribution['ballHandling']! + 0.3) * 1.5;
    }
    
    // Defense experience (base amount for playing)
    distribution['perimeterDefense'] = 0.3;
    distribution['postDefense'] = 0.2;
    
    // Normalize and apply experience
    final totalWeight = distribution.values.reduce((a, b) => a + b);
    if (totalWeight > 0) {
      for (String skill in distribution.keys) {
        final skillExp = (totalExperience * distribution[skill]! / totalWeight).round();
        player.development.addSkillExperience(skill, skillExp);
      }
    } else {
      // Fallback: distribute evenly
      player.development.addGeneralExperience(totalExperience);
    }
  }

  /// Get skills related to a focus skill for training
  static List<String> _getRelatedSkills(String focusSkill) {
    switch (focusSkill) {
      case 'shooting':
        return ['insideShooting', 'ballHandling'];
      case 'insideShooting':
        return ['shooting', 'postDefense'];
      case 'rebounding':
        return ['postDefense', 'perimeterDefense'];
      case 'passing':
        return ['ballHandling', 'shooting'];
      case 'ballHandling':
        return ['passing', 'perimeterDefense'];
      case 'perimeterDefense':
        return ['ballHandling', 'rebounding'];
      case 'postDefense':
        return ['rebounding', 'insideShooting'];
      default:
        return ['shooting', 'rebounding']; // Default related skills
    }
  }

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
        return 50; // Default value
    }
  }

  /// Apply skill upgrade to player
  static void _applySkillUpgrade(EnhancedPlayer player, String skill) {
    switch (skill) {
      case 'shooting':
        player.shooting = (player.shooting + 1).clamp(0, 99);
        break;
      case 'rebounding':
        player.rebounding = (player.rebounding + 1).clamp(0, 99);
        break;
      case 'passing':
        player.passing = (player.passing + 1).clamp(0, 99);
        break;
      case 'ballHandling':
        player.ballHandling = (player.ballHandling + 1).clamp(0, 99);
        break;
      case 'perimeterDefense':
        player.perimeterDefense = (player.perimeterDefense + 1).clamp(0, 99);
        break;
      case 'postDefense':
        player.postDefense = (player.postDefense + 1).clamp(0, 99);
        break;
      case 'insideShooting':
        player.insideShooting = (player.insideShooting + 1).clamp(0, 99);
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

  /// Generate potential tier based on age
  static PotentialTier _generatePotentialTier(int age) {
    final random = DateTime.now().millisecond % 100;
    
    if (age <= 20) {
      // Young players have higher chance for elite potential
      if (random < 15) return PotentialTier.elite;
      if (random < 40) return PotentialTier.gold;
      if (random < 70) return PotentialTier.silver;
      return PotentialTier.bronze;
    } else if (age <= 25) {
      // Prime age players
      if (random < 8) return PotentialTier.elite;
      if (random < 30) return PotentialTier.gold;
      if (random < 65) return PotentialTier.silver;
      return PotentialTier.bronze;
    } else {
      // Older players have limited potential
      if (random < 3) return PotentialTier.elite;
      if (random < 15) return PotentialTier.gold;
      if (random < 50) return PotentialTier.silver;
      return PotentialTier.bronze;
    }
  }

  /// Adjust potential based on player role
  static void _adjustPotentialForRole(PlayerPotential potential, PlayerRole role) {
    switch (role) {
      case PlayerRole.pointGuard:
        // Point guards excel at ball handling and passing
        potential.maxSkills['ballHandling'] = 
            (potential.maxSkills['ballHandling']! + 5).clamp(50, 99);
        potential.maxSkills['passing'] = 
            (potential.maxSkills['passing']! + 5).clamp(50, 99);
        break;
      case PlayerRole.shootingGuard:
        // Shooting guards excel at shooting
        potential.maxSkills['shooting'] = 
            (potential.maxSkills['shooting']! + 5).clamp(50, 99);
        potential.maxSkills['perimeterDefense'] = 
            (potential.maxSkills['perimeterDefense']! + 3).clamp(50, 99);
        break;
      case PlayerRole.smallForward:
        // Small forwards are versatile
        potential.maxSkills['shooting'] = 
            (potential.maxSkills['shooting']! + 3).clamp(50, 99);
        potential.maxSkills['rebounding'] = 
            (potential.maxSkills['rebounding']! + 3).clamp(50, 99);
        break;
      case PlayerRole.powerForward:
        // Power forwards excel at rebounding and inside play
        potential.maxSkills['rebounding'] = 
            (potential.maxSkills['rebounding']! + 5).clamp(50, 99);
        potential.maxSkills['insideShooting'] = 
            (potential.maxSkills['insideShooting']! + 3).clamp(50, 99);
        break;
      case PlayerRole.center:
        // Centers excel at rebounding and post defense
        potential.maxSkills['rebounding'] = 
            (potential.maxSkills['rebounding']! + 5).clamp(50, 99);
        potential.maxSkills['postDefense'] = 
            (potential.maxSkills['postDefense']! + 5).clamp(50, 99);
        potential.maxSkills['insideShooting'] = 
            (potential.maxSkills['insideShooting']! + 3).clamp(50, 99);
        break;
    }
  }
}