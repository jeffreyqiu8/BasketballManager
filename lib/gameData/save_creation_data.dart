import 'enums.dart';

/// Data class for new save configuration during save creation
class SaveCreationData {
  String saveName;
  String description;
  String selectedTeam;
  CoachCreationData coachData;
  DifficultySettings difficulty;
  LeagueSettings leagueSettings;
  bool useRealTeams;
  int startingSeason;

  SaveCreationData({
    required this.saveName,
    required this.description,
    required this.selectedTeam,
    required this.coachData,
    required this.difficulty,
    required this.leagueSettings,
    this.useRealTeams = true,
    this.startingSeason = 1,
  });

  /// Convert to map for storage or processing
  Map<String, dynamic> toMap() {
    return {
      'saveName': saveName,
      'description': description,
      'selectedTeam': selectedTeam,
      'coachData': coachData.toMap(),
      'difficulty': difficulty.toMap(),
      'leagueSettings': leagueSettings.toMap(),
      'useRealTeams': useRealTeams,
      'startingSeason': startingSeason,
    };
  }

  /// Create from map
  factory SaveCreationData.fromMap(Map<String, dynamic> map) {
    return SaveCreationData(
      saveName: map['saveName'] ?? 'New Save',
      description: map['description'] ?? '',
      selectedTeam: map['selectedTeam'] ?? '',
      coachData: CoachCreationData.fromMap(map['coachData'] ?? {}),
      difficulty: DifficultySettings.fromMap(map['difficulty'] ?? {}),
      leagueSettings: LeagueSettings.fromMap(map['leagueSettings'] ?? {}),
      useRealTeams: map['useRealTeams'] ?? true,
      startingSeason: map['startingSeason'] ?? 1,
    );
  }

  /// Validate the save creation data
  bool isValid() {
    return saveName.isNotEmpty &&
           selectedTeam.isNotEmpty &&
           coachData.isValid() &&
           startingSeason > 0;
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    List<String> errors = [];
    
    if (saveName.isEmpty) {
      errors.add('Save name is required');
    }
    
    if (selectedTeam.isEmpty) {
      errors.add('Team selection is required');
    }
    
    if (!coachData.isValid()) {
      errors.addAll(coachData.getValidationErrors());
    }
    
    if (startingSeason <= 0) {
      errors.add('Starting season must be greater than 0');
    }
    
    return errors;
  }
}

/// Coach creation data for new saves
class CoachCreationData {
  String name;
  String appearance;
  CoachingSpecialization primarySpecialization;
  CoachingSpecialization? secondarySpecialization;
  Map<String, int> initialAttributes;

  CoachCreationData({
    required this.name,
    this.appearance = 'default',
    required this.primarySpecialization,
    this.secondarySpecialization,
    Map<String, int>? initialAttributes,
  }) : initialAttributes = initialAttributes ?? {
         'offensive': 50,
         'defensive': 50,
         'development': 50,
         'chemistry': 50,
       };

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'appearance': appearance,
      'primarySpecialization': primarySpecialization.name,
      'secondarySpecialization': secondarySpecialization?.name,
      'initialAttributes': initialAttributes.map(
        (attr, value) => MapEntry(attr, value.toString())
      ),
    };
  }

  /// Create from map
  factory CoachCreationData.fromMap(Map<String, dynamic> map) {
    return CoachCreationData(
      name: map['name'] ?? 'Coach',
      appearance: map['appearance'] ?? 'default',
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
      initialAttributes: (map['initialAttributes'] as Map<String, dynamic>?)?.map(
        (attr, valueStr) => MapEntry(attr, int.tryParse(valueStr.toString()) ?? 50)
      ) ?? {},
    );
  }

  /// Validate coach data
  bool isValid() {
    return name.isNotEmpty && name.length >= 2;
  }

  /// Get validation errors
  List<String> getValidationErrors() {
    List<String> errors = [];
    
    if (name.isEmpty) {
      errors.add('Coach name is required');
    } else if (name.length < 2) {
      errors.add('Coach name must be at least 2 characters');
    }
    
    return errors;
  }
}

/// Difficulty settings for game configuration
class DifficultySettings {
  DifficultyLevel level;
  double playerDevelopmentRate;
  double injuryRate;
  double tradeAIAggressiveness;
  bool enableSalaryCap;
  bool enableDraftLottery;

  DifficultySettings({
    this.level = DifficultyLevel.normal,
    this.playerDevelopmentRate = 1.0,
    this.injuryRate = 0.1,
    this.tradeAIAggressiveness = 0.5,
    this.enableSalaryCap = true,
    this.enableDraftLottery = true,
  });

  /// Create preset difficulty settings
  factory DifficultySettings.easy() {
    return DifficultySettings(
      level: DifficultyLevel.easy,
      playerDevelopmentRate: 1.5,
      injuryRate: 0.05,
      tradeAIAggressiveness: 0.3,
      enableSalaryCap: false,
      enableDraftLottery: false,
    );
  }

  factory DifficultySettings.normal() {
    return DifficultySettings(
      level: DifficultyLevel.normal,
      playerDevelopmentRate: 1.0,
      injuryRate: 0.1,
      tradeAIAggressiveness: 0.5,
      enableSalaryCap: true,
      enableDraftLottery: true,
    );
  }

  factory DifficultySettings.hard() {
    return DifficultySettings(
      level: DifficultyLevel.hard,
      playerDevelopmentRate: 0.7,
      injuryRate: 0.15,
      tradeAIAggressiveness: 0.8,
      enableSalaryCap: true,
      enableDraftLottery: true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'playerDevelopmentRate': playerDevelopmentRate,
      'injuryRate': injuryRate,
      'tradeAIAggressiveness': tradeAIAggressiveness,
      'enableSalaryCap': enableSalaryCap,
      'enableDraftLottery': enableDraftLottery,
    };
  }

  /// Create from map
  factory DifficultySettings.fromMap(Map<String, dynamic> map) {
    return DifficultySettings(
      level: DifficultyLevel.values.firstWhere(
        (level) => level.name == (map['level'] ?? 'normal'),
        orElse: () => DifficultyLevel.normal,
      ),
      playerDevelopmentRate: map['playerDevelopmentRate']?.toDouble() ?? 1.0,
      injuryRate: map['injuryRate']?.toDouble() ?? 0.1,
      tradeAIAggressiveness: map['tradeAIAggressiveness']?.toDouble() ?? 0.5,
      enableSalaryCap: map['enableSalaryCap'] ?? true,
      enableDraftLottery: map['enableDraftLottery'] ?? true,
    );
  }
}

/// League settings for save configuration
class LeagueSettings {
  int numberOfTeams;
  int numberOfConferences;
  int regularSeasonGames;
  int playoffTeams;
  bool enableRealTeams;
  bool enableCustomRules;
  Map<String, dynamic> customRules;

  LeagueSettings({
    this.numberOfTeams = 30,
    this.numberOfConferences = 2,
    this.regularSeasonGames = 82,
    this.playoffTeams = 16,
    this.enableRealTeams = true,
    this.enableCustomRules = false,
    Map<String, dynamic>? customRules,
  }) : customRules = customRules ?? {};

  /// Create NBA-style league settings
  factory LeagueSettings.nbaStyle() {
    return LeagueSettings(
      numberOfTeams: 30,
      numberOfConferences: 2,
      regularSeasonGames: 82,
      playoffTeams: 16,
      enableRealTeams: true,
      enableCustomRules: false,
    );
  }

  /// Create custom league settings
  factory LeagueSettings.custom({
    required int teams,
    required int conferences,
    required int games,
    required int playoffTeams,
  }) {
    return LeagueSettings(
      numberOfTeams: teams,
      numberOfConferences: conferences,
      regularSeasonGames: games,
      playoffTeams: playoffTeams,
      enableRealTeams: false,
      enableCustomRules: true,
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'numberOfTeams': numberOfTeams,
      'numberOfConferences': numberOfConferences,
      'regularSeasonGames': regularSeasonGames,
      'playoffTeams': playoffTeams,
      'enableRealTeams': enableRealTeams,
      'enableCustomRules': enableCustomRules,
      'customRules': customRules,
    };
  }

  /// Create from map
  factory LeagueSettings.fromMap(Map<String, dynamic> map) {
    return LeagueSettings(
      numberOfTeams: map['numberOfTeams'] ?? 30,
      numberOfConferences: map['numberOfConferences'] ?? 2,
      regularSeasonGames: map['regularSeasonGames'] ?? 82,
      playoffTeams: map['playoffTeams'] ?? 16,
      enableRealTeams: map['enableRealTeams'] ?? true,
      enableCustomRules: map['enableCustomRules'] ?? false,
      customRules: Map<String, dynamic>.from(map['customRules'] ?? {}),
    );
  }

  /// Validate league settings
  bool isValid() {
    return numberOfTeams > 0 &&
           numberOfConferences > 0 &&
           regularSeasonGames > 0 &&
           playoffTeams > 0 &&
           playoffTeams <= numberOfTeams;
  }
}

/// Difficulty levels for game configuration
enum DifficultyLevel {
  easy('Easy', 'Relaxed gameplay with faster development'),
  normal('Normal', 'Balanced gameplay experience'),
  hard('Hard', 'Challenging gameplay with realistic constraints');

  const DifficultyLevel(this.displayName, this.description);
  
  final String displayName;
  final String description;
}