import 'coach_class.dart';
import 'enums.dart';

/// Enhanced coach profile that extends the base Manager with coaching specializations
class CoachProfile extends Manager {
  CoachingSpecialization primarySpecialization;
  CoachingSpecialization? secondarySpecialization;
  Map<String, int> coachingAttributes;
  List<Achievement> achievements;
  CoachingHistory history;
  int experienceLevel;
  Map<String, double> teamBonuses;

  CoachProfile({
    // Base Manager properties
    required super.name,
    required super.age,
    required super.team,
    required super.experienceYears,
    required super.nationality,
    required super.currentStatus,
    
    // Enhanced coaching properties
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

  /// Award experience and potentially level up
  void awardExperience(int experience) {
    history.totalExperience += experience;
    
    // Check for level up (every 1000 experience points)
    int newLevel = (history.totalExperience / 1000).floor() + 1;
    if (newLevel > experienceLevel) {
      experienceLevel = newLevel;
      _checkForNewAchievements();
    }
  }

  /// Check and unlock new achievements
  void _checkForNewAchievements() {
    // Check for experience-based achievements
    if (experienceLevel >= 5 && !hasAchievement('Experienced Coach')) {
      achievements.add(Achievement(
        name: 'Experienced Coach',
        description: 'Reached coaching level 5',
        type: AchievementType.experience,
        unlockedDate: DateTime.now(),
      ));
    }
    
    // Check for wins-based achievements
    if (history.totalWins >= 100 && !hasAchievement('Century Mark')) {
      achievements.add(Achievement(
        name: 'Century Mark',
        description: 'Achieved 100 career wins',
        type: AchievementType.wins,
        unlockedDate: DateTime.now(),
      ));
    }
  }

  /// Check if coach has a specific achievement
  bool hasAchievement(String achievementName) {
    return achievements.any((achievement) => achievement.name == achievementName);
  }

  @override
  Map<String, dynamic> toMap() {
    var baseMap = super.toMap();
    baseMap.addAll({
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
    });
    return baseMap;
  }

  factory CoachProfile.fromMap(Map<String, dynamic> map) {
    // Create base manager first
    var baseManager = Manager.fromMap(map);
    
    return CoachProfile(
      name: baseManager.name,
      age: baseManager.age,
      team: baseManager.team,
      experienceYears: baseManager.experienceYears,
      nationality: baseManager.nationality,
      currentStatus: baseManager.currentStatus,
      
      // Enhanced properties
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

  /// Add a season record
  void addSeasonRecord(int wins, int losses, bool madePlayoffs, bool wonChampionship) {
    seasonRecords.add(SeasonRecord(
      wins: wins,
      losses: losses,
      madePlayoffs: madePlayoffs,
      wonChampionship: wonChampionship,
      season: seasonRecords.length + 1,
    ));
    
    totalWins += wins;
    totalLosses += losses;
    totalGames += wins + losses;
    
    if (madePlayoffs) playoffAppearances++;
    if (wonChampionship) championships++;
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