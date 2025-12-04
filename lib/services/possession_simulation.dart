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

  // Rotation tracking: minutes played per player
  final Map<String, double> _minutesPlayed = {};

  // Current lineups on the court
  List<Player> _homeLineup = [];
  List<Player> _awayLineup = [];

  PossessionSimulation(this.homeTeam, this.awayTeam) {
    _initializeStatsTracking();
    _initializeLineups();
  }

  /// Initialize stats tracking for all players in rotation
  void _initializeStatsTracking() {
    // Initialize for home team rotation players
    final homeRotationPlayers = _getRotationPlayers(homeTeam);
    for (final player in homeRotationPlayers) {
      _statsTracker[player.id] = _MutablePlayerStats(player.id);
      _minutesPlayed[player.id] = 0.0;
    }

    // Initialize for away team rotation players
    final awayRotationPlayers = _getRotationPlayers(awayTeam);
    for (final player in awayRotationPlayers) {
      _statsTracker[player.id] = _MutablePlayerStats(player.id);
      _minutesPlayed[player.id] = 0.0;
    }
  }

  /// Get all players in the rotation for a team
  List<Player> _getRotationPlayers(Team team) {
    if (team.rotationConfig == null) {
      // No rotation config - use starting lineup only
      return team.startingLineup;
    }

    final activePlayerIds = team.rotationConfig!.getActivePlayerIds();
    return team.players
        .where((player) => activePlayerIds.contains(player.id))
        .toList();
  }

  /// Initialize lineups with starters
  void _initializeLineups() {
    _homeLineup = _getStartingLineup(homeTeam);
    _awayLineup = _getStartingLineup(awayTeam);
  }

  /// Get the starting lineup for a team based on rotation config
  List<Player> _getStartingLineup(Team team) {
    if (team.rotationConfig == null) {
      // No rotation config - use team's starting lineup
      return team.startingLineup;
    }

    // Get starters from depth chart (depth = 1)
    final starterIds = team.rotationConfig!.depthChart
        .where((entry) => entry.depth == 1)
        .map((entry) => entry.playerId)
        .toList();

    return team.players
        .where((player) => starterIds.contains(player.id))
        .toList();
  }

  /// Simulate the entire game and return box score
  Map<String, PlayerGameStats> simulate() {
    // Randomize possessions per game (190-210 range, realistic for basketball)
    // This creates variety in game pace and final scores
    final totalPossessions = 190 + _random.nextInt(21); // 190-210 possessions

    while (possessionCount < totalPossessions) {
      final isHomeTeam = possessionCount % 2 == 0;

      // Calculate minutes elapsed (48 minutes / total possessions)
      final minutesPerPossession = 48.0 / totalPossessions;
      
      // Check for substitutions before the possession
      _checkSubstitutions(homeTeam, _homeLineup, minutesPerPossession);
      _checkSubstitutions(awayTeam, _awayLineup, minutesPerPossession);

      _simulatePossession(
        isHomeTeam ? _homeLineup : _awayLineup,
        isHomeTeam ? _awayLineup : _homeLineup,
        isHomeTeam,
      );
      
      // Update minutes played for current lineups
      _updateMinutesPlayed(_homeLineup, minutesPerPossession);
      _updateMinutesPlayed(_awayLineup, minutesPerPossession);

      possessionCount++;
    }

    // Handle overtime if game is tied
    // Basketball games cannot end in ties, so simulate overtime possessions
    while (homeScore == awayScore) {
      // Overtime: alternate possessions until someone scores
      final isHomeTeam = possessionCount % 2 == 0;
      
      // In overtime, use a fixed minutes per possession estimate
      final overtimeMinutesPerPossession = 5.0 / 20.0; // 5 min OT / ~20 possessions
      
      _checkSubstitutions(homeTeam, _homeLineup, overtimeMinutesPerPossession);
      _checkSubstitutions(awayTeam, _awayLineup, overtimeMinutesPerPossession);

      _simulatePossession(
        isHomeTeam ? _homeLineup : _awayLineup,
        isHomeTeam ? _awayLineup : _homeLineup,
        isHomeTeam,
      );
      
      _updateMinutesPlayed(_homeLineup, overtimeMinutesPerPossession);
      _updateMinutesPlayed(_awayLineup, overtimeMinutesPerPossession);

      possessionCount++;
    }

    // Convert mutable stats to immutable PlayerGameStats
    return _statsTracker.map(
      (playerId, stats) => MapEntry(
        playerId, 
        stats.toPlayerGameStats(_minutesPlayed[playerId] ?? 0.0),
      ),
    );
  }

  /// Update minutes played for all players in the lineup
  void _updateMinutesPlayed(List<Player> lineup, double minutes) {
    for (final player in lineup) {
      _minutesPlayed[player.id] = (_minutesPlayed[player.id] ?? 0.0) + minutes;
    }
  }

  /// Check if substitutions are needed and perform them
  void _checkSubstitutions(Team team, List<Player> currentLineup, double minutesPerPossession) {
    if (team.rotationConfig == null) {
      // No rotation config - no substitutions
      return;
    }

    final config = team.rotationConfig!;
    
    // Check each position for substitution needs
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    for (final position in positions) {
      // Get the current player at this position
      final currentPlayer = _getPlayerAtPosition(currentLineup, position);
      if (currentPlayer == null) continue;

      // Get target minutes for this player
      final targetMinutes = config.playerMinutes[currentPlayer.id] ?? 0;
      final currentMinutes = _minutesPlayed[currentPlayer.id] ?? 0.0;

      // Substitute if current player has reached or will exceed their target minutes after this possession
      // This prevents players from significantly exceeding their allocation
      if (currentMinutes + minutesPerPossession >= targetMinutes) {
        // Find substitute from depth chart
        final substitute = _findSubstitute(team, position, currentPlayer.id);
        if (substitute != null) {
          // Perform substitution
          final index = currentLineup.indexOf(currentPlayer);
          if (index != -1) {
            currentLineup[index] = substitute;
          }
        }
      }
    }
  }

  /// Get the player currently playing at a specific position in the lineup
  /// Returns the player at the given position index (0=PG, 1=SG, 2=SF, 3=PF, 4=C)
  Player? _getPlayerAtPosition(List<Player> lineup, String position) {
    // Map position to lineup index
    final positionIndex = {
      'PG': 0,
      'SG': 1,
      'SF': 2,
      'PF': 3,
      'C': 4,
    }[position];
    
    if (positionIndex == null || positionIndex >= lineup.length) {
      return null;
    }
    
    return lineup[positionIndex];
  }

  /// Find a substitute for a position from the depth chart
  Player? _findSubstitute(Team team, String position, String currentPlayerId) {
    final config = team.rotationConfig!;
    
    // Get all players at this position from depth chart, ordered by depth
    final playersAtPosition = config.depthChart
        .where((entry) => entry.position == position)
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    // Find the player who needs the most minutes (furthest behind their target)
    Player? bestSubstitute;
    double maxMinutesNeeded = 0;

    for (final entry in playersAtPosition) {
      if (entry.playerId == currentPlayerId) continue;

      final targetMinutes = config.playerMinutes[entry.playerId] ?? 0;
      final currentMinutes = _minutesPlayed[entry.playerId] ?? 0.0;
      final minutesNeeded = targetMinutes - currentMinutes;

      // If this player needs minutes and needs more than the current best
      if (minutesNeeded > 0 && minutesNeeded > maxMinutesNeeded) {
        maxMinutesNeeded = minutesNeeded;
        bestSubstitute = team.players.firstWhere((p) => p.id == entry.playerId);
      }
    }

    return bestSubstitute;
  }

  /// Simulate a single possession
  void _simulatePossession(List<Player> offense, List<Player> defense, bool isHome) {
    // Select ball handler
    final ballHandler = _selectShooter(offense);

    // Check for steal by defense
    final stealResult = _checkSteal(ballHandler, defense);
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
    final shooter = _selectShooter(offense);

    // Determine shot type based on player's three-point attribute
    final isThreePoint = _determineShotType(shooter);

    // Check for foul during shot attempt
    final foulResult = _checkFoul(shooter, defense);
    if (foulResult != null) {
      // Foul occurred - simulate free throws
      _statsTracker[foulResult.id]!.fouls++;
      _simulateFreeThrows(shooter, isThreePoint, isHome);
      return;
    }

    // Check for block attempt
    final blockResult = _checkBlock(
      shooter,
      defense,
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
      _handleRebound(offense, defense);
      return;
    }

    // Attempt the shot
    final shotMade = _attemptShot(
      shooter,
      defense,
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
      _checkAssist(offense, shooter);
    } else {
      // Shot missed - handle rebound
      _handleRebound(offense, defense);
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

  /// Get modified probability by applying position and role archetype modifiers
  /// Takes a base probability and applies multiplicative modifiers from position and role
  double _getModifiedProbability(
    Player player,
    String modifierType,
    double baseProbability,
  ) {
    double probability = baseProbability;

    // Apply position-based modifiers
    probability *= _getPositionModifier(player.position, modifierType);

    // Apply role archetype modifiers
    final role = player.getRoleArchetype();
    if (role != null) {
      final roleModifier = role.gameplayModifiers[modifierType];
      if (roleModifier != null) {
        probability *= roleModifier;
      }
    }

    // Clamp to valid probability range (0.0 to 100.0)
    return probability.clamp(0.0, 100.0);
  }

  /// Get position-based modifier for a specific gameplay type
  double _getPositionModifier(String position, String modifierType) {
    switch (modifierType) {
      case 'assistProbability':
        return position == 'PG' ? 1.15 : 1.0;
      case 'threePointAttemptProbability':
        if (position == 'SG') return 1.20;
        if (position == 'SF') return 0.95;
        if (position == 'PF') return 0.60; // Power forwards take fewer threes
        if (position == 'C') return 0.40; // Centers rarely take threes
        return 1.0;
      case 'reboundProbability':
        if (position == 'PF') return 1.15;
        if (position == 'C') return 1.25;
        return 1.0;
      case 'blockProbability':
        return position == 'C' ? 1.20 : 1.0;
      default:
        return 1.0;
    }
  }

  /// Determine if shot is a three-pointer based on player's threePoint attribute
  bool _determineShotType(Player shooter) {
    // Higher threePoint attribute = more likely to attempt 3PT
    // Reduced base: 15% chance, +0.2% per threePoint point (max ~35% for elite shooters)
    double baseChance = 15 + (shooter.threePoint * 0.2);

    // Apply position and role modifiers
    double threePointChance = _getModifiedProbability(
      shooter,
      'threePointAttemptProbability',
      baseChance,
    );

    return _random.nextInt(100) < threePointChance;
  }

  /// Determine if this is a post shooting attempt (close-range/paint shot)
  /// vs a perimeter shot based on player attributes and role
  bool _isPostShootingAttempt(Player shooter, bool isThreePoint) {
    // Three-pointers are never post shots
    if (isThreePoint) return false;

    // Base probability based on post shooting attribute
    // Higher postShooting = more likely to attempt post shots
    double baseChance = shooter.postShooting * 0.4; // 0-40% base range

    // Apply position and role modifiers
    double postShootingChance = _getModifiedProbability(
      shooter,
      'postShootingAttemptProbability',
      baseChance,
    );

    return _random.nextInt(100) < postShootingChance;
  }

  /// Attempt a shot and return if it was successful
  bool _attemptShot(Player shooter, List<Player> defenders, bool isThreePoint) {
    // Calculate average defense rating
    final avgDefense =
        defenders.fold<int>(0, (sum, player) => sum + player.defense) /
        defenders.length;

    // Check if this is a post shooting attempt
    final isPostShot = _isPostShootingAttempt(shooter, isThreePoint);

    double successChance;
    if (isThreePoint) {
      // 3PT: base 35% + (threePoint/100 * 10%) - (avgDefense/100 * 5%)
      successChance =
          35 + (shooter.threePoint / 100 * 10) - (avgDefense / 100 * 5);
    } else if (isPostShot) {
      // Post shot: base 50% + (postShooting/100 * 20%) - (avgDefense/100 * 8%)
      successChance =
          50 + (shooter.postShooting / 100 * 20) - (avgDefense / 100 * 8);
    } else {
      // Regular 2PT: base 45% + (shooting/100 * 15%) - (avgDefense/100 * 7%)
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
    double baseChance = 50 + (assister.passing / 100 * 20);

    // Apply position and role modifiers
    double assistChance = _getModifiedProbability(
      assister,
      'assistProbability',
      baseChance,
    );

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

  /// Calculate position and role-based rebound modifier
  double _getPositionReboundModifier(Player player) {
    // Start with base rebounding value
    double modifier = player.rebounding.toDouble();

    // Apply position and role modifiers
    double modifiedValue = _getModifiedProbability(
      player,
      'reboundProbability',
      modifier,
    );

    // Return as a multiplier relative to base rebounding
    return modifiedValue / player.rebounding;
  }

  /// Select rebounder weighted by rebounding attribute and position
  Player _selectRebounder(List<Player> lineup) {
    // Calculate total rebounding weight with position and role modifiers
    final totalRebounding = lineup.fold<double>(
      0.0,
      (sum, player) =>
          sum + (player.rebounding * _getPositionReboundModifier(player)),
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
    // Select a defender weighted by steals attribute
    final defender = _selectStealDefender(defenders);

    // Base 8% steal chance + (steals/100 * 5%) - (ballHandling/100 * 4%)
    double baseChance =
        8 + (defender.steals / 100 * 5) - (ballHandler.ballHandling / 100 * 4);

    // Apply position and role modifiers
    double stealChance = _getModifiedProbability(
      defender,
      'stealProbability',
      baseChance,
    );

    final clampedChance = stealChance.clamp(2.0, 15.0);

    if (_random.nextInt(100) < clampedChance) {
      return defender;
    }

    return null;
  }

  /// Select a defender weighted by steals attribute for steal attempts
  Player _selectStealDefender(List<Player> defenders) {
    final totalSteals = defenders.fold<int>(
      0,
      (sum, player) => sum + player.steals,
    );

    // Fallback if all players have 0 steals
    if (totalSteals == 0) return defenders.first;

    final randomValue = _random.nextInt(totalSteals);
    int currentWeight = 0;

    for (final player in defenders) {
      currentWeight += player.steals;
      if (randomValue < currentWeight) {
        return player;
      }
    }

    return defenders.first;
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
    double baseChance = 6 + (defender.blocks / 100 * 8);

    // Apply position and role modifiers
    double blockChance = _getModifiedProbability(
      defender,
      'blockProbability',
      baseChance,
    );

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
    double freeThrowChance = 70 + (shooter.shooting / 100 * 15);

    // Post shooting bonus for Centers and Power Forwards
    // They often get fouled on post moves and benefit from post shooting skill
    if (shooter.position == 'C' && !wasThreePointAttempt) {
      freeThrowChance += (shooter.postShooting / 100 * 8);
    } else if (shooter.position == 'PF' && !wasThreePointAttempt) {
      freeThrowChance += (shooter.postShooting / 100 * 6);
    }

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
  PlayerGameStats toPlayerGameStats(double minutesPlayed) {
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
      minutesPlayed: minutesPlayed,
    );
  }
}
