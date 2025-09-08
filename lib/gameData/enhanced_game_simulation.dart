import 'dart:math';
import 'enhanced_player.dart';
import 'player_class.dart';
import 'team_class.dart';
import 'enums.dart';
import 'role_manager.dart';

/// Enhanced game simulation that incorporates player roles and position-specific behavior
class EnhancedGameSimulation {
  static final Random _random = Random();

  /// Simulate a game between two teams with role-based logic
  static Map<String, dynamic> simulateGame(Team homeTeam, Team awayTeam, int matchday) {
    // Convert players to enhanced players if needed
    final List<EnhancedPlayer> homePlayers = _convertToEnhancedPlayers(homeTeam.players);
    final List<EnhancedPlayer> awayPlayers = _convertToEnhancedPlayers(awayTeam.players);

    // Get starting lineups (first 5 players with optimal role assignments)
    final List<EnhancedPlayer> homeStarters = _getStartingLineup(homePlayers);
    final List<EnhancedPlayer> awayStarters = _getStartingLineup(awayPlayers);

    int homeScore = 0;
    int awayScore = 0;
    int possessions = 100 + _random.nextInt(20); // Total possessions in the game (more realistic)
    bool homeTeamPossession = _random.nextBool(); // Which team starts with possession

    // Initialize box score tracking
    final Map<String, Map<String, int>> homeBoxScore = {};
    final Map<String, Map<String, int>> awayBoxScore = {};

    // Initialize box scores for all players
    for (final player in homePlayers) {
      homeBoxScore[player.name] = {
        'points': 0,
        'rebounds': 0,
        'assists': 0,
        'FGM': 0,
        'FGA': 0,
        '3PM': 0,
        '3PA': 0,
        'steals': 0,
        'blocks': 0,
        'turnovers': 0,
      };
    }

    for (final player in awayPlayers) {
      awayBoxScore[player.name] = {
        'points': 0,
        'rebounds': 0,
        'assists': 0,
        'FGM': 0,
        'FGA': 0,
        '3PM': 0,
        '3PA': 0,
        'steals': 0,
        'blocks': 0,
        'turnovers': 0,
      };
    }

    // Simulate each possession
    for (int i = 0; i < possessions; i++) {
      if (homeTeamPossession) {
        final result = _simulatePossession(
          homeStarters, 
          awayStarters, 
          homeBoxScore, 
          awayBoxScore,
          isHomeTeam: true,
        );
        homeScore += result['points'] as int;
        homeTeamPossession = result['retainPossession'] ? homeTeamPossession : !homeTeamPossession;
      } else {
        final result = _simulatePossession(
          awayStarters, 
          homeStarters, 
          awayBoxScore, 
          homeBoxScore,
          isHomeTeam: false,
        );
        awayScore += result['points'] as int;
        homeTeamPossession = result['retainPossession'] ? homeTeamPossession : !homeTeamPossession;
      }
    }

    // Record performances for all players
    _recordPlayerPerformances(homePlayers, homeBoxScore, matchday);
    _recordPlayerPerformances(awayPlayers, awayBoxScore, matchday);

    return {
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homeBoxScore': homeBoxScore,
      'awayBoxScore': awayBoxScore,
    };
  }

  /// Convert regular players to enhanced players if needed
  static List<EnhancedPlayer> _convertToEnhancedPlayers(List<dynamic> players) {
    return players.map((player) {
      if (player is EnhancedPlayer) {
        return player;
      } else if (player is Player) {
        return EnhancedPlayer.fromPlayer(player);
      } else {
        throw ArgumentError('Invalid player type');
      }
    }).toList();
  }

  /// Get optimal starting lineup with role assignments
  static List<EnhancedPlayer> _getStartingLineup(List<EnhancedPlayer> players) {
    if (players.length < 5) {
      throw ArgumentError('Team must have at least 5 players');
    }

    // Take first 5 players and assign optimal roles
    final starters = players.take(5).toList();
    final optimalRoles = RoleManager.getOptimalLineup(starters);

    // Assign roles to starters
    for (int i = 0; i < starters.length; i++) {
      starters[i].assignPrimaryRole(optimalRoles[i]);
    }

    return starters;
  }

  /// Simulate a single possession with role-based logic
  static Map<String, dynamic> _simulatePossession(
    List<EnhancedPlayer> offensivePlayers,
    List<EnhancedPlayer> defensivePlayers,
    Map<String, Map<String, int>> offensiveBoxScore,
    Map<String, Map<String, int>> defensiveBoxScore, {
    required bool isHomeTeam,
  }) {
    int points = 0;
    bool retainPossession = false;

    // Determine who gets the ball based on role (point guards more likely)
    final ballHandler = _selectBallHandler(offensivePlayers);
    
    // Check for turnover first
    if (_checkTurnover(ballHandler, defensivePlayers)) {
      offensiveBoxScore[ballHandler.name]!['turnovers'] = 
          (offensiveBoxScore[ballHandler.name]!['turnovers'] ?? 0) + 1;
      
      // Award steal to a defensive player
      final stealer = _selectStealer(defensivePlayers);
      defensiveBoxScore[stealer.name]!['steals'] = 
          (defensiveBoxScore[stealer.name]!['steals'] ?? 0) + 1;
      
      return {'points': 0, 'retainPossession': false};
    }

    // Determine shot type and shooter based on roles
    final shooter = _selectShooter(offensivePlayers, ballHandler);
    final shotType = _determineShotType(shooter);
    
    // Check for block attempt first (only on inside shots)
    if (shotType == ShotType.inside && _checkBlock(shooter, defensivePlayers, defensiveBoxScore)) {
      return {'points': 0, 'retainPossession': false}; // Blocked shot = possession change
    }
    
    // Apply role-based modifiers to shooting
    final roleModifiers = shooter.calculateRoleBasedModifiers();
    final shotSuccess = _attemptShot(shooter, shotType, defensivePlayers, roleModifiers);

    // Update shooting stats
    offensiveBoxScore[shooter.name]!['FGA'] = 
        (offensiveBoxScore[shooter.name]!['FGA'] ?? 0) + 1;
    
    if (shotType == ShotType.threePoint) {
      offensiveBoxScore[shooter.name]!['3PA'] = 
          (offensiveBoxScore[shooter.name]!['3PA'] ?? 0) + 1;
    }

    if (shotSuccess['made']) {
      // Shot made
      points = shotSuccess['points'];
      offensiveBoxScore[shooter.name]!['points'] = 
          (offensiveBoxScore[shooter.name]!['points'] ?? 0) + points;
      offensiveBoxScore[shooter.name]!['FGM'] = 
          (offensiveBoxScore[shooter.name]!['FGM'] ?? 0) + 1;
      
      if (shotType == ShotType.threePoint) {
        offensiveBoxScore[shooter.name]!['3PM'] = 
            (offensiveBoxScore[shooter.name]!['3PM'] ?? 0) + 1;
      }

      // Award assist if applicable (with role-based modifier)
      if (shooter != ballHandler) {
        final ballHandlerModifiers = ballHandler.calculateRoleBasedModifiers();
        final assistChance = 0.6 * (ballHandlerModifiers['assists'] ?? 1.0);
        
        if (_random.nextDouble() < assistChance.clamp(0.1, 0.9)) {
          offensiveBoxScore[ballHandler.name]!['assists'] = 
              (offensiveBoxScore[ballHandler.name]!['assists'] ?? 0) + 1;
        }
      }

      retainPossession = false; // Made shot = possession change
    } else {
      // Shot missed - rebound battle
      final rebounder = _simulateRebound(offensivePlayers, defensivePlayers);
      
      if (offensivePlayers.contains(rebounder)) {
        // Offensive rebound
        offensiveBoxScore[rebounder.name]!['rebounds'] = 
            (offensiveBoxScore[rebounder.name]!['rebounds'] ?? 0) + 1;
        retainPossession = true; // Keep possession
      } else {
        // Defensive rebound
        defensiveBoxScore[rebounder.name]!['rebounds'] = 
            (defensiveBoxScore[rebounder.name]!['rebounds'] ?? 0) + 1;
        retainPossession = false; // Lose possession
      }
    }

    return {'points': points, 'retainPossession': retainPossession};
  }

  /// Select ball handler based on role (point guards preferred)
  static EnhancedPlayer _selectBallHandler(List<EnhancedPlayer> players) {
    // Prefer point guards, then shooting guards
    final pointGuards = players.where((p) => p.primaryRole == PlayerRole.pointGuard).toList();
    if (pointGuards.isNotEmpty) {
      return pointGuards[_random.nextInt(pointGuards.length)];
    }

    final shootingGuards = players.where((p) => p.primaryRole == PlayerRole.shootingGuard).toList();
    if (shootingGuards.isNotEmpty) {
      return shootingGuards[_random.nextInt(shootingGuards.length)];
    }

    // Fallback to any player
    return players[_random.nextInt(players.length)];
  }

  /// Check for turnover based on ball handling and defensive pressure
  static bool _checkTurnover(EnhancedPlayer ballHandler, List<EnhancedPlayer> defenders) {
    final ballHandlingSkill = ballHandler.ballHandling;
    final roleModifiers = ballHandler.calculateRoleBasedModifiers();
    final adjustedBallHandling = ballHandlingSkill * (roleModifiers['ballHandling'] ?? 1.0);

    // Apply role-based turnover modifier
    final turnoverModifier = roleModifiers['turnovers'] ?? 1.0;

    // Calculate defensive pressure with role-based bonuses
    double defensivePressure = 0.0;
    for (final defender in defenders) {
      final defenderModifiers = defender.calculateRoleBasedModifiers();
      final stealBonus = defenderModifiers['steals'] ?? 1.0;
      
      if (defender.primaryRole == PlayerRole.pointGuard || 
          defender.primaryRole == PlayerRole.shootingGuard) {
        defensivePressure += (defender.perimeterDefense * stealBonus) * 0.3;
      }
    }

    final baseTurnoverChance = (100 - adjustedBallHandling + defensivePressure) / 1000;
    final finalTurnoverChance = (baseTurnoverChance * turnoverModifier).clamp(0.01, 0.15);
    
    return _random.nextDouble() < finalTurnoverChance;
  }

  /// Select player who gets the steal
  static EnhancedPlayer _selectStealer(List<EnhancedPlayer> defenders) {
    // Weight by perimeter defense and role
    final weights = defenders.map((player) {
      double weight = player.perimeterDefense.toDouble();
      if (player.primaryRole == PlayerRole.pointGuard || 
          player.primaryRole == PlayerRole.shootingGuard) {
        weight *= 1.5; // Guards more likely to get steals
      }
      return weight;
    }).toList();

    return _selectWeightedRandom(defenders, weights);
  }

  /// Select shooter based on role and situation
  static EnhancedPlayer _selectShooter(List<EnhancedPlayer> players, EnhancedPlayer ballHandler) {
    // 40% chance ball handler shoots, 60% chance pass to someone else
    if (_random.nextDouble() < 0.4) {
      return ballHandler;
    }

    // Weight by shooting ability and role
    final weights = players.map((player) {
      double weight = player.shooting.toDouble();
      
      // Role-based shooting preferences
      switch (player.primaryRole) {
        case PlayerRole.shootingGuard:
          weight *= 1.8;
          break;
        case PlayerRole.smallForward:
          weight *= 1.4;
          break;
        case PlayerRole.pointGuard:
          weight *= 1.2;
          break;
        case PlayerRole.powerForward:
          weight *= 0.8;
          break;
        case PlayerRole.center:
          weight *= 0.6;
          break;
      }
      
      return weight;
    }).toList();

    return _selectWeightedRandom(players, weights);
  }

  /// Determine shot type based on player role and position
  static ShotType _determineShotType(EnhancedPlayer shooter) {
    final role = shooter.primaryRole;
    final random = _random.nextDouble();

    switch (role) {
      case PlayerRole.center:
      case PlayerRole.powerForward:
        // Big men prefer inside shots
        if (random < 0.7) return ShotType.inside;
        if (random < 0.9) return ShotType.midRange;
        return ShotType.threePoint;
        
      case PlayerRole.pointGuard:
        // Point guards balanced but prefer outside shots
        if (random < 0.2) return ShotType.inside;
        if (random < 0.5) return ShotType.midRange;
        return ShotType.threePoint;
        
      case PlayerRole.shootingGuard:
        // Shooting guards love three-pointers
        if (random < 0.15) return ShotType.inside;
        if (random < 0.4) return ShotType.midRange;
        return ShotType.threePoint;
        
      case PlayerRole.smallForward:
        // Small forwards are versatile
        if (random < 0.3) return ShotType.inside;
        if (random < 0.6) return ShotType.midRange;
        return ShotType.threePoint;
    }
  }

  /// Attempt a shot with role-based modifiers
  static Map<String, dynamic> _attemptShot(
    EnhancedPlayer shooter, 
    ShotType shotType, 
    List<EnhancedPlayer> defenders,
    Map<String, double> roleModifiers,
  ) {
    double baseAccuracy;
    int points;

    switch (shotType) {
      case ShotType.inside:
        baseAccuracy = (25 + shooter.insideShooting * 1.0) / 100.0;
        points = 2;
        break;
      case ShotType.midRange:
        baseAccuracy = (20 + shooter.shooting * 1.0) / 100.0;
        points = 2;
        break;
      case ShotType.threePoint:
        baseAccuracy = (15 + shooter.shooting * 0.8) / 100.0;
        points = 3;
        break;
    }

    // Apply role-based shooting modifiers more comprehensively
    double finalModifier = 1.0;
    
    if (shotType == ShotType.threePoint) {
      finalModifier *= roleModifiers['threePointShooting'] ?? 1.0;
    } else if (shotType == ShotType.inside) {
      finalModifier *= roleModifiers['insideShooting'] ?? 1.0;
    } else {
      finalModifier *= roleModifiers['shooting'] ?? 1.0;
    }

    // Apply general shooting modifier
    finalModifier *= roleModifiers['shooting'] ?? 1.0;
    
    baseAccuracy *= finalModifier;

    // Apply defensive pressure with role-based defensive modifiers
    double defensiveModifier = 1.0;
    for (final defender in defenders) {
      final defenderModifiers = defender.calculateRoleBasedModifiers();
      
      if (shotType == ShotType.inside) {
        final postDefenseBonus = defenderModifiers['postDefense'] ?? 1.0;
        defensiveModifier -= (defender.postDefense * postDefenseBonus) * 0.001;
      } else {
        final perimeterDefenseBonus = defenderModifiers['perimeterDefense'] ?? 1.0;
        defensiveModifier -= (defender.perimeterDefense * perimeterDefenseBonus) * 0.001;
      }
    }

    final finalAccuracy = (baseAccuracy * defensiveModifier).clamp(0.05, 0.95);
    final made = _random.nextDouble() < finalAccuracy;

    return {'made': made, 'points': made ? points : 0};
  }

  /// Simulate rebound battle with role-based logic
  static EnhancedPlayer _simulateRebound(
    List<EnhancedPlayer> offensivePlayers, 
    List<EnhancedPlayer> defensivePlayers,
  ) {
    final allPlayers = [...offensivePlayers, ...defensivePlayers];
    
    // Weight by rebounding ability and role
    final weights = allPlayers.map((player) {
      double weight = player.rebounding.toDouble();
      
      // Role-based rebounding bonuses
      switch (player.primaryRole) {
        case PlayerRole.center:
          weight *= 2.0;
          break;
        case PlayerRole.powerForward:
          weight *= 1.6;
          break;
        case PlayerRole.smallForward:
          weight *= 1.2;
          break;
        case PlayerRole.shootingGuard:
          weight *= 0.8;
          break;
        case PlayerRole.pointGuard:
          weight *= 0.6;
          break;
      }

      // Apply role-based modifiers from player's role bonuses/penalties
      final roleModifiers = player.calculateRoleBasedModifiers();
      weight *= (roleModifiers['rebounding'] ?? 1.0);
      
      return weight;
    }).toList();

    return _selectWeightedRandom(allPlayers, weights);
  }

  /// Check for block attempt on inside shots
  static bool _checkBlock(
    EnhancedPlayer shooter, 
    List<EnhancedPlayer> defenders,
    Map<String, Map<String, int>> defensiveBoxScore,
  ) {
    // Only big men can effectively block shots
    final potentialBlockers = defenders.where((defender) =>
      defender.primaryRole == PlayerRole.center || 
      defender.primaryRole == PlayerRole.powerForward
    ).toList();

    if (potentialBlockers.isEmpty) return false;

    // Calculate block probability
    double totalBlockChance = 0.0;
    EnhancedPlayer? blocker;
    
    for (final defender in potentialBlockers) {
      final roleModifiers = defender.calculateRoleBasedModifiers();
      final blockBonus = roleModifiers['blocks'] ?? 1.0;
      final blockChance = (defender.postDefense * blockBonus) / 2000; // Low base chance
      
      if (_random.nextDouble() < blockChance) {
        totalBlockChance += blockChance;
        blocker = defender;
      }
    }

    if (blocker != null && totalBlockChance > 0) {
      // Award block to the defender
      defensiveBoxScore[blocker.name]!['blocks'] = 
          (defensiveBoxScore[blocker.name]!['blocks'] ?? 0) + 1;
      return true;
    }

    return false;
  }

  /// Select a random element based on weights
  static T _selectWeightedRandom<T>(List<T> items, List<double> weights) {
    if (items.length != weights.length) {
      throw ArgumentError('Items and weights must have the same length');
    }

    final totalWeight = weights.reduce((a, b) => a + b);
    final randomValue = _random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (int i = 0; i < items.length; i++) {
      currentWeight += weights[i];
      if (randomValue <= currentWeight) {
        return items[i];
      }
    }

    // Fallback (should not happen)
    return items.last;
  }

  /// Record player performances in their performance maps
  static void _recordPlayerPerformances(
    List<EnhancedPlayer> players,
    Map<String, Map<String, int>> boxScore,
    int matchday,
  ) {
    for (final player in players) {
      final stats = boxScore[player.name]!;
      
      // Apply role-based modifiers to final stats for performance recording
      final roleModifiers = player.calculateRoleBasedModifiers();
      final adjustedStats = _applyRoleModifiersToStats(stats, roleModifiers);
      
      final performanceList = [
        adjustedStats['points'] ?? 0,
        adjustedStats['rebounds'] ?? 0,
        adjustedStats['assists'] ?? 0,
        adjustedStats['FGM'] ?? 0,
        adjustedStats['FGA'] ?? 0,
        adjustedStats['3PM'] ?? 0,
        adjustedStats['3PA'] ?? 0,
      ];
      
      player.recordPerformance(matchday, performanceList);
      
      // Award role experience based on playing time and performance
      final totalStats = (stats['points'] ?? 0) + (stats['rebounds'] ?? 0) + (stats['assists'] ?? 0);
      final experience = (totalStats * 0.1).clamp(0.1, 2.0);
      player.awardRoleExperience(player.primaryRole, experience);
      
      // Award additional experience for playing in optimal role
      if (player.roleCompatibility > 0.8) {
        player.awardRoleExperience(player.primaryRole, experience * 0.2);
      }
    }
  }

  /// Apply role-based modifiers to final statistics
  static Map<String, int> _applyRoleModifiersToStats(
    Map<String, int> baseStats, 
    Map<String, double> roleModifiers,
  ) {
    final adjustedStats = Map<String, int>.from(baseStats);
    
    // Apply modifiers to relevant stats
    for (final entry in roleModifiers.entries) {
      final statName = entry.key;
      final modifier = entry.value;
      
      if (adjustedStats.containsKey(statName)) {
        final baseValue = adjustedStats[statName] ?? 0;
        adjustedStats[statName] = (baseValue * modifier).round();
      }
    }
    
    return adjustedStats;
  }
}

/// Shot types for position-specific behavior
enum ShotType {
  inside,
  midRange,
  threePoint,
}