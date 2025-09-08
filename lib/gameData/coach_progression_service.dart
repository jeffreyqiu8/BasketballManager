import 'enhanced_coach.dart';
import 'enums.dart';

/// Service for managing coach progression, achievements, and career statistics
class CoachProgressionService {
  
  /// All available achievements that coaches can unlock
  static List<AchievementDefinition> getAllAchievementDefinitions() {
    return [
      // Experience-based achievements
      AchievementDefinition(
        name: 'Rookie Coach',
        description: 'Complete your first season as a coach',
        type: AchievementType.experience,
        unlockCondition: (coach) => coach.history.seasonRecords.isNotEmpty,
        experienceReward: 100,
      ),
      AchievementDefinition(
        name: 'Experienced Coach',
        description: 'Reached coaching level 5',
        type: AchievementType.experience,
        unlockCondition: (coach) => coach.experienceLevel >= 5,
        experienceReward: 250,
      ),
      AchievementDefinition(
        name: 'Veteran Coach',
        description: 'Reached coaching level 10',
        type: AchievementType.experience,
        unlockCondition: (coach) => coach.experienceLevel >= 10,
        experienceReward: 500,
      ),
      AchievementDefinition(
        name: 'Master Coach',
        description: 'Reached coaching level 15',
        type: AchievementType.experience,
        unlockCondition: (coach) => coach.experienceLevel >= 15,
        experienceReward: 1000,
      ),
      
      // Wins-based achievements
      AchievementDefinition(
        name: 'First Victory',
        description: 'Win your first game as a coach',
        type: AchievementType.wins,
        unlockCondition: (coach) => coach.history.totalWins >= 1,
        experienceReward: 50,
      ),
      AchievementDefinition(
        name: 'Winning Ways',
        description: 'Achieve 25 career wins',
        type: AchievementType.wins,
        unlockCondition: (coach) => coach.history.totalWins >= 25,
        experienceReward: 150,
      ),
      AchievementDefinition(
        name: 'Century Mark',
        description: 'Achieved 100 career wins',
        type: AchievementType.wins,
        unlockCondition: (coach) => coach.history.totalWins >= 100,
        experienceReward: 300,
      ),
      AchievementDefinition(
        name: 'Legendary Coach',
        description: 'Achieved 500 career wins',
        type: AchievementType.wins,
        unlockCondition: (coach) => coach.history.totalWins >= 500,
        experienceReward: 1000,
      ),
      
      // Championship achievements
      AchievementDefinition(
        name: 'Champion',
        description: 'Win your first championship',
        type: AchievementType.championships,
        unlockCondition: (coach) => coach.history.championships >= 1,
        experienceReward: 500,
      ),
      AchievementDefinition(
        name: 'Dynasty Builder',
        description: 'Win 3 championships',
        type: AchievementType.championships,
        unlockCondition: (coach) => coach.history.championships >= 3,
        experienceReward: 1000,
      ),
      AchievementDefinition(
        name: 'GOAT Coach',
        description: 'Win 5 championships',
        type: AchievementType.championships,
        unlockCondition: (coach) => coach.history.championships >= 5,
        experienceReward: 2000,
      ),
      
      // Development achievements
      AchievementDefinition(
        name: 'Player Developer',
        description: 'Help develop 10 players significantly',
        type: AchievementType.development,
        unlockCondition: (coach) => coach.history.playersDeveloped.length >= 10,
        experienceReward: 300,
      ),
      AchievementDefinition(
        name: 'Talent Guru',
        description: 'Help develop 25 players significantly',
        type: AchievementType.development,
        unlockCondition: (coach) => coach.history.playersDeveloped.length >= 25,
        experienceReward: 600,
      ),
      AchievementDefinition(
        name: 'Development Master',
        description: 'Help develop 50 players significantly',
        type: AchievementType.development,
        unlockCondition: (coach) => coach.history.playersDeveloped.length >= 50,
        experienceReward: 1200,
      ),
      
      // Special achievements
      AchievementDefinition(
        name: 'Perfect Season',
        description: 'Complete an undefeated regular season',
        type: AchievementType.wins,
        unlockCondition: (coach) => coach.history.seasonRecords.any(
          (record) => record.losses == 0 && record.wins >= 50
        ),
        experienceReward: 1000,
      ),
      AchievementDefinition(
        name: 'Comeback Kid',
        description: 'Win a championship after a losing season',
        type: AchievementType.championships,
        unlockCondition: (coach) => _hasComeback(coach),
        experienceReward: 750,
      ),
      AchievementDefinition(
        name: 'Playoff Streak',
        description: 'Make playoffs for 5 consecutive seasons',
        type: AchievementType.wins,
        unlockCondition: (coach) => _hasPlayoffStreak(coach, 5),
        experienceReward: 500,
      ),
    ];
  }

  /// Check for comeback achievement (championship after losing season)
  static bool _hasComeback(CoachProfile coach) {
    final records = coach.history.seasonRecords;
    if (records.length < 2) return false;
    
    for (int i = 1; i < records.length; i++) {
      final previousSeason = records[i - 1];
      final currentSeason = records[i];
      
      if (previousSeason.winPercentage < 0.5 && currentSeason.wonChampionship) {
        return true;
      }
    }
    return false;
  }

  /// Check for playoff streak achievement
  static bool _hasPlayoffStreak(CoachProfile coach, int streakLength) {
    final records = coach.history.seasonRecords;
    if (records.length < streakLength) return false;
    
    int currentStreak = 0;
    int maxStreak = 0;
    
    for (final record in records.reversed) {
      if (record.madePlayoffs) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return maxStreak >= streakLength;
  }

  /// Check and unlock all available achievements for a coach
  static List<Achievement> checkAndUnlockAchievements(CoachProfile coach) {
    final newAchievements = <Achievement>[];
    final definitions = getAllAchievementDefinitions();
    
    for (final definition in definitions) {
      if (!coach.hasAchievement(definition.name) && definition.unlockCondition(coach)) {
        final achievement = Achievement(
          name: definition.name,
          description: definition.description,
          type: definition.type,
          unlockedDate: DateTime.now(),
          metadata: {'experienceReward': definition.experienceReward},
        );
        
        coach.achievements.add(achievement);
        coach.awardExperience(definition.experienceReward);
        newAchievements.add(achievement);
      }
    }
    
    return newAchievements;
  }

  /// Calculate experience gain based on game performance
  static int calculateGameExperience(
    bool won,
    int teamPerformanceRating, // 0-100
    bool wasUpset, // beating a much better team
    bool wasBlowout, // winning by large margin
    CoachingSpecialization specialization,
  ) {
    int baseExperience = won ? 50 : 25;
    
    // Performance bonuses
    if (teamPerformanceRating > 90) {
      baseExperience += 30;
    } else if (teamPerformanceRating > 80) {
      baseExperience += 20;
    } else if (teamPerformanceRating > 70) {
      baseExperience += 10;
    }
    
    // Special situation bonuses
    if (wasUpset) {
      baseExperience += 25; // Bonus for beating better teams
    }
    
    if (wasBlowout && won) {
      baseExperience += 15; // Bonus for dominant wins
    }
    
    // Specialization bonuses (coaches get more experience in their area)
    switch (specialization) {
      case CoachingSpecialization.offensive:
        if (teamPerformanceRating > 80) baseExperience += 10;
        break;
      case CoachingSpecialization.defensive:
        if (teamPerformanceRating > 80) baseExperience += 10;
        break;
      case CoachingSpecialization.playerDevelopment:
        baseExperience += 5; // Always get bonus for development focus
        break;
      case CoachingSpecialization.teamChemistry:
        if (!wasBlowout && won) baseExperience += 10; // Bonus for close wins
        break;
    }
    
    return baseExperience;
  }

  /// Calculate experience gain for season completion
  static int calculateSeasonExperience(
    int wins,
    int losses,
    bool madePlayoffs,
    bool wonChampionship,
    int playoffWins,
    CoachingSpecialization specialization,
  ) {
    int baseExperience = 200; // Base season completion bonus
    
    // Win percentage bonus
    final winPercentage = wins / (wins + losses);
    if (winPercentage > 0.7) {
      baseExperience += 150;
    } else if (winPercentage > 0.6) {
      baseExperience += 100;
    } else if (winPercentage > 0.5) {
      baseExperience += 50;
    }
    
    // Playoff bonuses
    if (madePlayoffs) {
      baseExperience += 100;
      baseExperience += playoffWins * 25; // Bonus per playoff win
    }
    
    if (wonChampionship) {
      baseExperience += 500;
    }
    
    // Specialization season bonuses
    switch (specialization) {
      case CoachingSpecialization.offensive:
        if (winPercentage > 0.6) baseExperience += 50;
        break;
      case CoachingSpecialization.defensive:
        if (winPercentage > 0.6) baseExperience += 50;
        break;
      case CoachingSpecialization.playerDevelopment:
        baseExperience += 100; // Always get development bonus
        break;
      case CoachingSpecialization.teamChemistry:
        if (madePlayoffs) baseExperience += 75;
        break;
    }
    
    return baseExperience;
  }

  /// Get coaching abilities unlocked at each level
  static Map<int, List<CoachingAbility>> getCoachingAbilities() {
    return {
      1: [], // Starting level
      2: [
        CoachingAbility(
          name: 'Basic Motivation',
          description: 'Small boost to team chemistry',
          effect: {'teamChemistry': 0.02},
        ),
      ],
      3: [
        CoachingAbility(
          name: 'Timeout Management',
          description: 'Better timeout usage in close games',
          effect: {'clutchPerformance': 0.05},
        ),
      ],
      5: [
        CoachingAbility(
          name: 'Advanced Scouting',
          description: 'Better preparation against opponents',
          effect: {'gamePreparation': 0.1},
        ),
      ],
      7: [
        CoachingAbility(
          name: 'Player Rotation',
          description: 'Improved player rotation and rest management',
          effect: {'playerStamina': 0.1},
        ),
      ],
      10: [
        CoachingAbility(
          name: 'Master Tactician',
          description: 'Significant boost to all coaching bonuses',
          effect: {'allBonuses': 0.15},
        ),
      ],
      15: [
        CoachingAbility(
          name: 'Legendary Presence',
          description: 'Maximum coaching effectiveness',
          effect: {'allBonuses': 0.25, 'playerDevelopment': 0.2},
        ),
      ],
    };
  }

  /// Get abilities available to a coach at their current level
  static List<CoachingAbility> getAvailableAbilities(CoachProfile coach) {
    final abilities = <CoachingAbility>[];
    final abilityMap = getCoachingAbilities();
    
    for (final entry in abilityMap.entries) {
      if (coach.experienceLevel >= entry.key) {
        abilities.addAll(entry.value);
      }
    }
    
    return abilities;
  }

  /// Calculate total coaching effectiveness including abilities
  static double calculateTotalEffectiveness(CoachProfile coach) {
    double baseEffectiveness = coach.coachingAttributes.values
        .fold<double>(0.0, (sum, value) => sum + value) / 
        coach.coachingAttributes.length;
    
    // Experience multiplier
    final experienceMultiplier = 1.0 + (coach.experienceLevel - 1) * 0.1;
    
    // Achievement bonus
    final achievementBonus = coach.achievements.length * 2.0;
    
    // Win percentage bonus
    final winPercentageBonus = coach.history.winPercentage * 10.0;
    
    // Ability bonuses
    final abilities = getAvailableAbilities(coach);
    double abilityBonus = 0.0;
    for (final ability in abilities) {
      if (ability.effect.containsKey('allBonuses')) {
        abilityBonus += ability.effect['allBonuses']! * 100;
      }
    }
    
    final totalEffectiveness = (baseEffectiveness * experienceMultiplier + 
                              achievementBonus + 
                              winPercentageBonus + 
                              abilityBonus).clamp(0.0, 100.0);
    
    return totalEffectiveness;
  }

  /// Process end of season for coach progression
  static void processSeasonEnd(
    CoachProfile coach,
    int wins,
    int losses,
    bool madePlayoffs,
    bool wonChampionship,
    int playoffWins,
    List<String> developedPlayers,
  ) {
    // Add season record
    coach.history.addSeasonRecord(wins, losses, madePlayoffs, wonChampionship);
    
    // Award season experience
    final seasonExperience = calculateSeasonExperience(
      wins,
      losses,
      madePlayoffs,
      wonChampionship,
      playoffWins,
      coach.primarySpecialization,
    );
    coach.awardExperience(seasonExperience);
    
    // Track developed players
    for (final playerName in developedPlayers) {
      coach.history.playersDeveloped[playerName] = 
        (coach.history.playersDeveloped[playerName] ?? 0) + 1;
    }
    
    // Check for new achievements
    checkAndUnlockAchievements(coach);
  }
}

/// Definition for achievements that can be unlocked
class AchievementDefinition {
  String name;
  String description;
  AchievementType type;
  bool Function(CoachProfile coach) unlockCondition;
  int experienceReward;

  AchievementDefinition({
    required this.name,
    required this.description,
    required this.type,
    required this.unlockCondition,
    required this.experienceReward,
  });
}

/// Coaching abilities unlocked through progression
class CoachingAbility {
  String name;
  String description;
  Map<String, double> effect;

  CoachingAbility({
    required this.name,
    required this.description,
    required this.effect,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'effect': effect.map((key, value) => MapEntry(key, value.toString())),
    };
  }

  factory CoachingAbility.fromMap(Map<String, dynamic> map) {
    return CoachingAbility(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      effect: (map['effect'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 0.0)
      ) ?? {},
    );
  }
}