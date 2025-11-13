import 'dart:math';
import '../models/team.dart';
import '../models/player.dart';
import '../models/player_game_stats.dart';

/// Helper class for possession-by-possession game simulation
/// Simulates realistic basketball gameplay with attribute-based outcomes
class PossessionSimulation {
  final Team homeTeam;
  final Team awayTeam;
  final Random _random = Random();

  // Game state
  int homeScore = 0;
  int awayScore = 0;
  int possessionCount = 0;

  // Box score tracking: playerId -> stats
  final Map<String, _MutablePlayerStats> _statsTracker = {};

  PossessionSimulation(this.homeTeam, this.awayTeam) {
    _initializeStatsTracking();
  }

  /// Initialize stats tracking for all starting lineup players
  void _initializeStatsTracking() {
    for (final player in homeTeam.startingLineup) {
      _statsTracker[player.id] = _MutablePlayerStats(player.id);
    }
    for (final player in awayTeam.startingLineup) {
      _statsTracker[player.id] = _MutablePlayerStats(player.id);
    }
  }

  /// Simulate the entire game and return box score
  Map<String, PlayerGameStats> simulate() {
    // Randomize possessions per game (190-210 range, realistic for basketball)
    // This creates variety in game pace and final scores
    final totalPossessions = 190 + _random.nextInt(21); // 190-210 possessions

    while (possessionCount < totalPossessions) {
      final isHomeTeam = possessionCount % 2 == 0;
      _simulatePossession(
        isHomeTeam ? homeTeam : awayTeam,
        isHomeTeam ? awayTeam : homeTeam,
        isHomeTeam,
      );
      possessionCount++;
    }

    // Convert mutable stats to immutable PlayerGameStats
    return _statsTracker.map(
      (playerId, stats) => MapEntry(playerId, stats.toPlayerGameStats()),
    );
  }

  /// Simulate a single possession
  void _simulatePossession(Team offense, Team defense, bool isHome) {
    // Select ball handler
    final ballHandler = _selectShooter(offense.startingLineup);

    // Check for steal by defense
    final stealResult = _checkSteal(ballHandler, defense.startingLineup);
    if (stealResult != null) {
      // Steal occurred - record turnover and steal
      _statsTracker[ballHandler.id]!.turnovers++;
      _statsTracker[stealResult.id]!.steals++;
      return;
    }

    // Check for regular turnover
    if (_checkTurnover(ballHandler)) {
      // Turnover - possession ends with no shot
      _statsTracker[ballHandler.id]!.turnovers++;
      return;
    }

    // Select shooter (may be different from ball handler)
    final shooter = _selectShooter(offense.startingLineup);

    // Determine shot type based on player's three-point attribute
    final isThreePoint = _determineShotType(shooter);

    // Check for foul during shot attempt
    final foulResult = _checkFoul(shooter, defense.startingLineup);
    if (foulResult != null) {
      // Foul occurred - simulate free throws
      _statsTracker[foulResult.id]!.fouls++;
      _simulateFreeThrows(shooter, isThreePoint, isHome);
      return;
    }

    // Check for block attempt
    final blockResult = _checkBlock(
      shooter,
      defense.startingLineup,
      isThreePoint,
    );
    if (blockResult != null) {
      // Shot was blocked
      _statsTracker[blockResult.id]!.blocks++;
      _statsTracker[shooter.id]!.fieldGoalsAttempted++;
      if (isThreePoint) {
        _statsTracker[shooter.id]!.threePointersAttempted++;
      }
      // Handle rebound after block
      _handleRebound(offense.startingLineup, defense.startingLineup);
      return;
    }

    // Attempt the shot
    final shotMade = _attemptShot(
      shooter,
      defense.startingLineup,
      isThreePoint,
    );

    // Record the attempt
    _statsTracker[shooter.id]!.fieldGoalsAttempted++;
    if (isThreePoint) {
      _statsTracker[shooter.id]!.threePointersAttempted++;
    }

    if (shotMade) {
      // Shot made - record points and check for assist
      final points = isThreePoint ? 3 : 2;
      _statsTracker[shooter.id]!.fieldGoalsMade++;
      _statsTracker[shooter.id]!.points += points;

      if (isThreePoint) {
        _statsTracker[shooter.id]!.threePointersMade++;
      }

      // Update score
      if (isHome) {
        homeScore += points;
      } else {
        awayScore += points;
      }

      // Check for assist
      _checkAssist(offense.startingLineup, shooter);
    } else {
      // Shot missed - handle rebound
      _handleRebound(offense.startingLineup, defense.startingLineup);
    }
  }

  /// Select shooter from lineup weighted by shooting attributes
  Player _selectShooter(List<Player> lineup) {
    // Calculate total shooting weight
    final totalWeight = lineup.fold<int>(
      0,
      (sum, player) => sum + player.shooting + player.threePoint,
    );

    // Select random value
    final randomValue = _random.nextInt(totalWeight);

    // Find player based on weighted selection
    int currentWeight = 0;
    for (final player in lineup) {
      currentWeight += player.shooting + player.threePoint;
      if (randomValue < currentWeight) {
        return player;
      }
    }

    // Fallback to first player (should never reach here)
    return lineup.first;
  }

  /// Determine if shot is a three-pointer based on player's threePoint attribute
  bool _determineShotType(Player shooter) {
    // Higher threePoint attribute = more likely to attempt 3PT
    // Base 35% chance, +0.3% per threePoint point
    double threePointChance = 35 + (shooter.threePoint * 0.3);
    
    // Position-based modifiers
    if (shooter.position == 'SG') {
      // Shooting guards get +20% to three-point attempt probability
      threePointChance *= 1.20;
    } else if (shooter.position == 'SF') {
      // Small forwards balance 2PT and 3PT attempts (slight reduction)
      threePointChance *= 0.95;
    }
    
    return _random.nextInt(100) < threePointChance;
  }

  /// Attempt a shot and return if it was successful
  bool _attemptShot(Player shooter, List<Player> defenders, bool isThreePoint) {
    // Calculate average defense rating
    final avgDefense =
        defenders.fold<int>(0, (sum, player) => sum + player.defense) /
        defenders.length;

    double successChance;
    if (isThreePoint) {
      // 3PT: base 35% + (threePoint/100 * 10%) - (avgDefense/100 * 5%)
      successChance =
          35 + (shooter.threePoint / 100 * 10) - (avgDefense / 100 * 5);
    } else {
      // 2PT: base 45% + (shooting/100 * 15%) - (avgDefense/100 * 7%)
      successChance =
          45 + (shooter.shooting / 100 * 15) - (avgDefense / 100 * 7);
    }

    // Clamp to realistic range
    successChance = successChance.clamp(20.0, 70.0);

    return _random.nextInt(100) < successChance;
  }

  /// Check if possession results in a turnover
  bool _checkTurnover(Player ballHandler) {
    // Base 15% turnover chance - (ballHandling/100 * 10%)
    final turnoverChance = 15 - (ballHandler.ballHandling / 100 * 10);
    final clampedChance = turnoverChance.clamp(3.0, 20.0);

    return _random.nextInt(100) < clampedChance;
  }

  /// Check for assist on made basket
  void _checkAssist(List<Player> lineup, Player scorer) {
    // Select potential assister (not the scorer)
    final potentialAssisters = lineup.where((p) => p.id != scorer.id).toList();
    if (potentialAssisters.isEmpty) return;

    // Pick random teammate weighted by passing attribute
    final totalPassing = potentialAssisters.fold<int>(
      0,
      (sum, player) => sum + player.passing,
    );

    final randomValue = _random.nextInt(totalPassing);
    int currentWeight = 0;
    Player? assister;

    for (final player in potentialAssisters) {
      currentWeight += player.passing;
      if (randomValue < currentWeight) {
        assister = player;
        break;
      }
    }

    if (assister == null) return;

    // Base 50% assist chance + (passing/100 * 20%)
    double assistChance = 50 + (assister.passing / 100 * 20);
    
    // Position-based modifier: Point guards get +15% to assist probability
    if (assister.position == 'PG') {
      assistChance *= 1.15;
    }

    if (_random.nextInt(100) < assistChance) {
      _statsTracker[assister.id]!.assists++;
    }
  }

  /// Handle rebound after missed shot
  void _handleRebound(List<Player> offense, List<Player> defense) {
    // Calculate offensive and defensive rebounding strength
    final offensiveRebounding =
        offense.fold<int>(0, (sum, player) => sum + player.rebounding) /
        offense.length;

    final defensiveRebounding =
        defense.fold<int>(0, (sum, player) => sum + player.rebounding) /
        defense.length;

    // Base 25% offensive rebound chance + (offReb/100 * 15%) - (defReb/100 * 10%)
    final offensiveReboundChance =
        25 +
        (offensiveRebounding / 100 * 15) -
        (defensiveRebounding / 100 * 10);

    final clampedChance = offensiveReboundChance.clamp(15.0, 40.0);

    final isOffensiveRebound = _random.nextInt(100) < clampedChance;

    // Select rebounder from appropriate team
    final reboundingTeam = isOffensiveRebound ? offense : defense;
    final rebounder = _selectRebounder(reboundingTeam);

    _statsTracker[rebounder.id]!.rebounds++;
  }

  /// Calculate position-based rebound modifier
  double _getPositionReboundModifier(Player player) {
    switch (player.position) {
      case 'PF':
        return 1.15; // +15% for power forwards
      case 'C':
        return 1.25; // +25% for centers
      default:
        return 1.0; // No modifier for other positions
    }
  }

  /// Select rebounder weighted by rebounding attribute and position
  Player _selectRebounder(List<Player> lineup) {
    // Calculate total rebounding weight with position modifiers
    final totalRebounding = lineup.fold<double>(
      0.0,
      (sum, player) => sum + (player.rebounding * _getPositionReboundModifier(player)),
    );

    final randomValue = _random.nextDouble() * totalRebounding;
    double currentWeight = 0.0;

    for (final player in lineup) {
      currentWeight += player.rebounding * _getPositionReboundModifier(player);
      if (randomValue < currentWeight) {
        return player;
      }
    }

    return lineup.first;
  }

  /// Check if a defender steals the ball
  /// Returns the defender who made the steal, or null if no steal
  Player? _checkSteal(Player ballHandler, List<Player> defenders) {
    // Select a defender weighted by defense attribute
    final defender = _selectDefender(defenders);

    // Base 8% steal chance + (defense/100 * 5%) - (ballHandling/100 * 4%)
    final stealChance =
        8 + (defender.defense / 100 * 5) - (ballHandler.ballHandling / 100 * 4);

    final clampedChance = stealChance.clamp(2.0, 15.0);

    if (_random.nextInt(100) < clampedChance) {
      return defender;
    }

    return null;
  }

  /// Check if a foul occurs during shot attempt
  /// Returns the defender who committed the foul, or null if no foul
  Player? _checkFoul(Player shooter, List<Player> defenders) {
    // Select a defender weighted by defense attribute (aggressive defenders foul more)
    final defender = _selectDefender(defenders);

    // Base 12% foul chance + (defense/100 * 3%)
    // More aggressive defense leads to more fouls
    final foulChance = 12 + (defender.defense / 100 * 3);

    final clampedChance = foulChance.clamp(8.0, 20.0);

    if (_random.nextInt(100) < clampedChance) {
      return defender;
    }

    return null;
  }

  /// Check if a shot is blocked
  /// Returns the defender who blocked the shot, or null if no block
  Player? _checkBlock(
    Player shooter,
    List<Player> defenders,
    bool isThreePoint,
  ) {
    // Three-pointers are harder to block
    if (isThreePoint) {
      // Very low block chance for 3PT shots
      final threePointBlockChance = 2.0;
      if (_random.nextInt(100) >= threePointBlockChance) {
        return null;
      }
    }

    // Select a defender weighted by blocks attribute
    final defender = _selectBlocker(defenders);

    // Base 6% block chance + (blocks/100 * 8%)
    // Blocks attribute is primary factor for blocking shots
    double blockChance = 6 + (defender.blocks / 100 * 8);
    
    // Position-based modifier: Centers get +20% to block probability
    if (defender.position == 'C') {
      blockChance *= 1.20;
    }

    final clampedChance = blockChance.clamp(3.0, 18.0);

    if (_random.nextInt(100) < clampedChance) {
      return defender;
    }

    return null;
  }

  /// Select a blocker weighted by blocks attribute
  Player _selectBlocker(List<Player> defenders) {
    final totalBlocks = defenders.fold<int>(
      0,
      (sum, player) => sum + player.blocks,
    );

    final randomValue = _random.nextInt(totalBlocks);
    int currentWeight = 0;

    for (final player in defenders) {
      currentWeight += player.blocks;
      if (randomValue < currentWeight) {
        return player;
      }
    }

    return defenders.first;
  }

  /// Select a defender weighted by defense attribute
  Player _selectDefender(List<Player> defenders) {
    final totalDefense = defenders.fold<int>(
      0,
      (sum, player) => sum + player.defense,
    );

    final randomValue = _random.nextInt(totalDefense);
    int currentWeight = 0;

    for (final player in defenders) {
      currentWeight += player.defense;
      if (randomValue < currentWeight) {
        return player;
      }
    }

    return defenders.first;
  }

  /// Simulate free throws after a foul
  void _simulateFreeThrows(
    Player shooter,
    bool wasThreePointAttempt,
    bool isHome,
  ) {
    // Determine number of free throws (2 for regular foul, 3 for three-point foul)
    final numFreeThrows = wasThreePointAttempt ? 3 : 2;

    // Free throw success based on shooting attribute
    // Base 70% + (shooting/100 * 15%)
    final freeThrowChance = 70 + (shooter.shooting / 100 * 15);
    final clampedChance = freeThrowChance.clamp(60.0, 90.0);

    for (int i = 0; i < numFreeThrows; i++) {
      _statsTracker[shooter.id]!.freeThrowsAttempted++;

      if (_random.nextInt(100) < clampedChance) {
        _statsTracker[shooter.id]!.freeThrowsMade++;
        _statsTracker[shooter.id]!.points++;

        // Update score
        if (isHome) {
          homeScore++;
        } else {
          awayScore++;
        }
      }
    }
  }
}

/// Mutable stats tracker for building PlayerGameStats during simulation
class _MutablePlayerStats {
  final String playerId;
  int points = 0;
  int rebounds = 0;
  int assists = 0;
  int fieldGoalsMade = 0;
  int fieldGoalsAttempted = 0;
  int threePointersMade = 0;
  int threePointersAttempted = 0;
  int turnovers = 0;
  int steals = 0;
  int blocks = 0;
  int fouls = 0;
  int freeThrowsMade = 0;
  int freeThrowsAttempted = 0;

  _MutablePlayerStats(this.playerId);

  /// Convert to immutable PlayerGameStats
  PlayerGameStats toPlayerGameStats() {
    return PlayerGameStats(
      playerId: playerId,
      points: points,
      rebounds: rebounds,
      assists: assists,
      fieldGoalsMade: fieldGoalsMade,
      fieldGoalsAttempted: fieldGoalsAttempted,
      threePointersMade: threePointersMade,
      threePointersAttempted: threePointersAttempted,
      turnovers: turnovers,
      steals: steals,
      blocks: blocks,
      fouls: fouls,
      freeThrowsMade: freeThrowsMade,
      freeThrowsAttempted: freeThrowsAttempted,
    );
  }
}
