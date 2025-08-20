import 'enums.dart';

/// Playbook system for managing team strategies
class Playbook {
  String name;
  OffensiveStrategy offensiveStrategy;
  DefensiveStrategy defensiveStrategy;
  Map<String, double> strategyWeights;
  List<PlayerRole> optimalRoles;
  Map<String, double> teamRequirements;
  double effectiveness;

  Playbook({
    required this.name,
    required this.offensiveStrategy,
    required this.defensiveStrategy,
    Map<String, double>? strategyWeights,
    List<PlayerRole>? optimalRoles,
    Map<String, double>? teamRequirements,
    this.effectiveness = 0.0,
  }) : strategyWeights = strategyWeights ?? _getDefaultStrategyWeights(offensiveStrategy, defensiveStrategy),
       optimalRoles = optimalRoles ?? _getDefaultOptimalRoles(offensiveStrategy),
       teamRequirements = teamRequirements ?? _getDefaultTeamRequirements(offensiveStrategy, defensiveStrategy);

  /// Get default strategy weights based on offensive and defensive strategies
  static Map<String, double> _getDefaultStrategyWeights(
    OffensiveStrategy offensive, 
    DefensiveStrategy defensive
  ) {
    Map<String, double> weights = {};
    
    // Offensive strategy weights
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        weights['pace'] = 1.2;
        weights['transition'] = 1.3;
        weights['ballHandling'] = 1.1;
        break;
      case OffensiveStrategy.halfCourt:
        weights['pace'] = 0.9;
        weights['ballMovement'] = 1.2;
        weights['patience'] = 1.3;
        break;
      case OffensiveStrategy.pickAndRoll:
        weights['ballHandling'] = 1.2;
        weights['screening'] = 1.3;
        weights['spacing'] = 1.1;
        break;
      case OffensiveStrategy.postUp:
        weights['insideShooting'] = 1.3;
        weights['postMoves'] = 1.4;
        weights['rebounding'] = 1.1;
        break;
      case OffensiveStrategy.threePointHeavy:
        weights['shooting'] = 1.4;
        weights['spacing'] = 1.3;
        weights['ballMovement'] = 1.1;
        break;
    }
    
    // Defensive strategy weights
    switch (defensive) {
      case DefensiveStrategy.manToMan:
        weights['individualDefense'] = 1.2;
        weights['communication'] = 1.1;
        break;
      case DefensiveStrategy.zoneDefense:
        weights['teamDefense'] = 1.3;
        weights['positioning'] = 1.2;
        break;
      case DefensiveStrategy.pressDefense:
        weights['pressure'] = 1.4;
        weights['stamina'] = 1.2;
        weights['speed'] = 1.1;
        break;
      case DefensiveStrategy.switchDefense:
        weights['versatility'] = 1.3;
        weights['communication'] = 1.2;
        break;
    }
    
    return weights;
  }

  /// Get default optimal roles for offensive strategy
  static List<PlayerRole> _getDefaultOptimalRoles(OffensiveStrategy offensive) {
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        return [PlayerRole.pointGuard, PlayerRole.shootingGuard, PlayerRole.smallForward];
      case OffensiveStrategy.halfCourt:
        return PlayerRole.values; // All positions work well
      case OffensiveStrategy.pickAndRoll:
        return [PlayerRole.pointGuard, PlayerRole.center];
      case OffensiveStrategy.postUp:
        return [PlayerRole.powerForward, PlayerRole.center];
      case OffensiveStrategy.threePointHeavy:
        return [PlayerRole.pointGuard, PlayerRole.shootingGuard, PlayerRole.smallForward];
    }
  }

  /// Get default team requirements for strategies
  static Map<String, double> _getDefaultTeamRequirements(
    OffensiveStrategy offensive,
    DefensiveStrategy defensive
  ) {
    Map<String, double> requirements = {};
    
    // Offensive requirements
    switch (offensive) {
      case OffensiveStrategy.fastBreak:
        requirements['averageSpeed'] = 70.0;
        requirements['averageBallHandling'] = 65.0;
        break;
      case OffensiveStrategy.halfCourt:
        requirements['averagePassing'] = 70.0;
        requirements['averageBasketballIQ'] = 75.0;
        break;
      case OffensiveStrategy.pickAndRoll:
        requirements['centerScreening'] = 70.0;
        requirements['guardBallHandling'] = 75.0;
        break;
      case OffensiveStrategy.postUp:
        requirements['averageInsideShooting'] = 75.0;
        requirements['centerPostMoves'] = 80.0;
        break;
      case OffensiveStrategy.threePointHeavy:
        requirements['averageShooting'] = 75.0;
        requirements['averageSpacing'] = 70.0;
        break;
    }
    
    // Defensive requirements
    switch (defensive) {
      case DefensiveStrategy.manToMan:
        requirements['averagePerimeterDefense'] = 70.0;
        requirements['averagePostDefense'] = 65.0;
        break;
      case DefensiveStrategy.zoneDefense:
        requirements['averageTeamDefense'] = 75.0;
        requirements['averagePositioning'] = 70.0;
        break;
      case DefensiveStrategy.pressDefense:
        requirements['averageSpeed'] = 75.0;
        requirements['averageStamina'] = 80.0;
        break;
      case DefensiveStrategy.switchDefense:
        requirements['averageVersatility'] = 75.0;
        requirements['averageSize'] = 65.0;
        break;
    }
    
    return requirements;
  }

  /// Calculate playbook effectiveness based on team composition
  double calculateEffectiveness(Map<String, double> teamStats) {
    double totalEffectiveness = 0.0;
    
    for (var requirement in teamRequirements.entries) {
      String statName = requirement.key;
      double requiredValue = requirement.value;
      double teamValue = teamStats[statName] ?? 0.0;
      
      if (teamValue >= requiredValue) {
        // Bonus for exceeding requirements
        double bonus = (teamValue - requiredValue) / requiredValue;
        totalEffectiveness += 1.0 + (bonus * 0.1);
      } else {
        // Penalty for not meeting requirements
        double penalty = (requiredValue - teamValue) / requiredValue;
        totalEffectiveness += (1.0 - penalty).clamp(0.0, 1.0);
      }
    }
    
    // Calculate final effectiveness (0.0 to 1.0)
    effectiveness = teamRequirements.isNotEmpty 
      ? (totalEffectiveness / teamRequirements.length).clamp(0.0, 1.0)
      : 0.5;
    
    return effectiveness;
  }

  /// Get strategy modifiers for game simulation
  Map<String, double> getGameModifiers() {
    Map<String, double> modifiers = {};
    
    // Apply strategy weights as game modifiers
    for (var weight in strategyWeights.entries) {
      modifiers[weight.key] = (weight.value - 1.0) * effectiveness;
    }
    
    return modifiers;
  }

  /// Create a preset playbook
  static Playbook createPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'run_and_gun':
        return Playbook(
          name: 'Run and Gun',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.pressDefense,
        );
      case 'defensive_minded':
        return Playbook(
          name: 'Defensive Minded',
          offensiveStrategy: OffensiveStrategy.halfCourt,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );
      case 'three_point_shooters':
        return Playbook(
          name: 'Three Point Shooters',
          offensiveStrategy: OffensiveStrategy.threePointHeavy,
          defensiveStrategy: DefensiveStrategy.zoneDefense,
        );
      case 'inside_game':
        return Playbook(
          name: 'Inside Game',
          offensiveStrategy: OffensiveStrategy.postUp,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );
      case 'balanced_attack':
        return Playbook(
          name: 'Balanced Attack',
          offensiveStrategy: OffensiveStrategy.pickAndRoll,
          defensiveStrategy: DefensiveStrategy.switchDefense,
        );
      default:
        return Playbook(
          name: 'Default Playbook',
          offensiveStrategy: OffensiveStrategy.halfCourt,
          defensiveStrategy: DefensiveStrategy.manToMan,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'offensiveStrategy': offensiveStrategy.name,
      'defensiveStrategy': defensiveStrategy.name,
      'strategyWeights': strategyWeights.map(
        (key, value) => MapEntry(key, value.toString())
      ),
      'optimalRoles': optimalRoles.map((role) => role.name).toList(),
      'teamRequirements': teamRequirements.map(
        (key, value) => MapEntry(key, value.toString())
      ),
      'effectiveness': effectiveness.toString(),
    };
  }

  factory Playbook.fromMap(Map<String, dynamic> map) {
    return Playbook(
      name: map['name'] ?? 'Unknown Playbook',
      offensiveStrategy: OffensiveStrategy.values.firstWhere(
        (strategy) => strategy.name == (map['offensiveStrategy'] ?? 'halfCourt'),
        orElse: () => OffensiveStrategy.halfCourt,
      ),
      defensiveStrategy: DefensiveStrategy.values.firstWhere(
        (strategy) => strategy.name == (map['defensiveStrategy'] ?? 'manToMan'),
        orElse: () => DefensiveStrategy.manToMan,
      ),
      strategyWeights: (map['strategyWeights'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 1.0)
      ) ?? {},
      optimalRoles: (map['optimalRoles'] as List?)?.map(
        (roleStr) => PlayerRole.values.firstWhere(
          (role) => role.name == roleStr,
          orElse: () => PlayerRole.pointGuard,
        )
      ).toList() ?? [],
      teamRequirements: (map['teamRequirements'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 0.0)
      ) ?? {},
      effectiveness: double.tryParse(map['effectiveness']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

/// Playbook library for managing multiple playbooks
class PlaybookLibrary {
  List<Playbook> playbooks;
  Playbook? activePlaybook;

  PlaybookLibrary({
    List<Playbook>? playbooks,
    this.activePlaybook,
  }) : playbooks = playbooks ?? [];

  /// Add a playbook to the library
  void addPlaybook(Playbook playbook) {
    playbooks.add(playbook);
    activePlaybook ??= playbook; // Set as active if no active playbook
  }

  /// Remove a playbook from the library
  bool removePlaybook(String playbookName) {
    int index = playbooks.indexWhere((pb) => pb.name == playbookName);
    if (index != -1) {
      Playbook removed = playbooks.removeAt(index);
      if (activePlaybook == removed) {
        activePlaybook = playbooks.isNotEmpty ? playbooks.first : null;
      }
      return true;
    }
    return false;
  }

  /// Set active playbook
  bool setActivePlaybook(String playbookName) {
    try {
      activePlaybook = playbooks.firstWhere((pb) => pb.name == playbookName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get playbook by name
  Playbook? getPlaybook(String name) {
    try {
      return playbooks.firstWhere((pb) => pb.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Initialize with default playbooks
  void initializeWithDefaults() {
    playbooks.clear();
    playbooks.addAll([
      Playbook.createPreset('run_and_gun'),
      Playbook.createPreset('defensive_minded'),
      Playbook.createPreset('three_point_shooters'),
      Playbook.createPreset('inside_game'),
      Playbook.createPreset('balanced_attack'),
    ]);
    activePlaybook = playbooks.first;
  }

  Map<String, dynamic> toMap() {
    return {
      'playbooks': playbooks.map((pb) => pb.toMap()).toList(),
      'activePlaybook': activePlaybook?.name,
    };
  }

  factory PlaybookLibrary.fromMap(Map<String, dynamic> map) {
    List<Playbook> loadedPlaybooks = (map['playbooks'] as List?)?.map(
      (playbookMap) => Playbook.fromMap(playbookMap)
    ).toList() ?? [];
    
    String? activePlaybookName = map['activePlaybook'];
    Playbook? active;
    if (activePlaybookName != null) {
      try {
        active = loadedPlaybooks.firstWhere((pb) => pb.name == activePlaybookName);
      } catch (e) {
        active = loadedPlaybooks.isNotEmpty ? loadedPlaybooks.first : null;
      }
    }
    
    return PlaybookLibrary(
      playbooks: loadedPlaybooks,
      activePlaybook: active,
    );
  }
}