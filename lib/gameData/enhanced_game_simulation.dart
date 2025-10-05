import 'dart:math';
import 'enhanced_player.dart';
import 'player_class.dart';
import 'team_class.dart';
import 'enhanced_team.dart';
import 'enhanced_coach.dart';
import 'enums.dart';
import 'playbook.dart';
import 'coaching_service.dart';
import 'development_service.dart';
import 'coach_progression_service.dart';
import 'performance_optimizer.dart';
import 'performance_profiler.dart';
import 'memory_manager.dart';

/// Enhanced game simulation that incorporates player roles and position-specific behavior
class EnhancedGameSimulation {
  static final Random _random = Random();
  static final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  static final PerformanceProfiler _profiler = PerformanceProfiler();
  static final MemoryManager _memoryManager = MemoryManager();

  /// Simulate a game between two teams with role-based logic, playbook effects, and coaching bonuses
  static Map<String, dynamic> simulateGame(
    Team homeTeam,
    Team awayTeam,
    int matchday, {
    CoachProfile? homeCoach,
    CoachProfile? awayCoach,
  }) {
    return _profiler.profileFunction(
      'game_simulation',
      () {
        // Convert teams to enhanced teams if needed
        final EnhancedTeam enhancedHomeTeam =
            homeTeam is EnhancedTeam
                ? homeTeam
                : _convertToEnhancedTeam(homeTeam);
        final EnhancedTeam enhancedAwayTeam =
            awayTeam is EnhancedTeam
                ? awayTeam
                : _convertToEnhancedTeam(awayTeam);

        // Convert players to enhanced players if needed
        final List<EnhancedPlayer> homePlayers = _convertToEnhancedPlayers(
          enhancedHomeTeam.players,
        );
        final List<EnhancedPlayer> awayPlayers = _convertToEnhancedPlayers(
          enhancedAwayTeam.players,
        );

        // Get starting lineups (first 5 players with optimal role assignments) - cached
        final List<EnhancedPlayer> homeStarters = _optimizer
            .getCachedOptimalLineup(homePlayers);
        final List<EnhancedPlayer> awayStarters = _optimizer
            .getCachedOptimalLineup(awayPlayers);

        // Get active playbooks for strategy modifiers (with effectiveness caching)
        final Playbook? homePlaybook =
            enhancedHomeTeam.playbookLibrary.activePlaybook;
        final Playbook? awayPlaybook =
            enhancedAwayTeam.playbookLibrary.activePlaybook;

        // Cache playbook effectiveness for performance
        if (homePlaybook != null) {
          _optimizer.getCachedPlaybookEffectiveness(homePlaybook, homePlayers);
        }
        if (awayPlaybook != null) {
          _optimizer.getCachedPlaybookEffectiveness(awayPlaybook, awayPlayers);
        }

        // Calculate coaching bonuses for both teams (with caching)
        final Map<String, double> homeCoachingBonuses =
            homeCoach != null
                ? _optimizer.getCachedTeamChemistry(homePlayers) > 0
                    ? CoachingService.calculateTeamBonuses(homeCoach)
                    : <String, double>{}
                : <String, double>{};
        final Map<String, double> awayCoachingBonuses =
            awayCoach != null
                ? _optimizer.getCachedTeamChemistry(awayPlayers) > 0
                    ? CoachingService.calculateTeamBonuses(awayCoach)
                    : <String, double>{}
                : <String, double>{};

        int homeScore = 0;
        int awayScore = 0;

        // Apply playbook pace modifiers to possession count
        int basePossessions = 100 + _random.nextInt(20);
        int possessions = _applyPaceModifiers(
          basePossessions,
          homePlaybook,
          awayPlaybook,
          homeCoachingBonuses,
          awayCoachingBonuses,
        );

        bool homeTeamPossession =
            _random.nextBool(); // Which team starts with possession

        // Initialize box score tracking using memory manager
        final Map<String, Map<String, int>> homeBoxScore = {};
        final Map<String, Map<String, int>> awayBoxScore = {};

        // Initialize box scores for all players using pooled objects
        for (final player in homePlayers) {
          homeBoxScore[player.name] =
              _memoryManager.getBoxScoreFromPool()..addAll({
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
              });
        }

        for (final player in awayPlayers) {
          awayBoxScore[player.name] =
              _memoryManager.getBoxScoreFromPool()..addAll({
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
              });
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
              offensivePlaybook: homePlaybook,
              defensivePlaybook: awayPlaybook,
              offensiveCoachingBonuses: homeCoachingBonuses,
              defensiveCoachingBonuses: awayCoachingBonuses,
            );
            homeScore += result['points'] as int;
            homeTeamPossession =
                result['retainPossession']
                    ? homeTeamPossession
                    : !homeTeamPossession;
          } else {
            final result = _simulatePossession(
              awayStarters,
              homeStarters,
              awayBoxScore,
              homeBoxScore,
              isHomeTeam: false,
              offensivePlaybook: awayPlaybook,
              defensivePlaybook: homePlaybook,
              offensiveCoachingBonuses: awayCoachingBonuses,
              defensiveCoachingBonuses: homeCoachingBonuses,
            );
            awayScore += result['points'] as int;
            homeTeamPossession =
                result['retainPossession']
                    ? homeTeamPossession
                    : !homeTeamPossession;
          }
        }

        // Record performances for all players with coaching bonuses
        _recordPlayerPerformances(
          homePlayers,
          homeBoxScore,
          matchday,
          homeCoach,
        );
        _recordPlayerPerformances(
          awayPlayers,
          awayBoxScore,
          matchday,
          awayCoach,
        );

        // Update coach progression after game
        if (homeCoach != null) {
          _updateCoachAfterGame(
            homeCoach,
            homeScore > awayScore,
            homeScore,
            awayScore,
            homePlayers,
          );
        }
        if (awayCoach != null) {
          _updateCoachAfterGame(
            awayCoach,
            awayScore > homeScore,
            awayScore,
            homeScore,
            awayPlayers,
          );
        }

        // Prepare result using memory manager
        final result =
            _memoryManager.getGameResultFromPool()..addAll({
              'homeScore': homeScore,
              'awayScore': awayScore,
              'homeBoxScore': homeBoxScore,
              'awayBoxScore': awayBoxScore,
              'homeCoachingEffectiveness':
                  homeCoach != null
                      ? CoachingService.calculateCoachingEffectiveness(
                        homeCoach,
                      )
                      : 0.0,
              'awayCoachingEffectiveness':
                  awayCoach != null
                      ? CoachingService.calculateCoachingEffectiveness(
                        awayCoach,
                      )
                      : 0.0,
            });

        // Don't return box scores to pool immediately - let caller handle cleanup
        // This ensures the test can read the box score data
        // for (final boxScore in homeBoxScore.values) {
        //   _memoryManager.returnBoxScoreToPool(boxScore);
        // }
        // for (final boxScore in awayBoxScore.values) {
        //   _memoryManager.returnBoxScoreToPool(boxScore);
        // }

        return result;
      },
      metadata: {
        'homeTeam': homeTeam.name,
        'awayTeam': awayTeam.name,
        'matchday': matchday,
      },
    );
  }

  /// Convert regular team to enhanced team if needed
  static EnhancedTeam _convertToEnhancedTeam(Team team) {
    if (team is EnhancedTeam) {
      return team;
    }

    // Create enhanced team from regular team
    return EnhancedTeam(
      name: team.name,
      reputation: team.reputation,
      playerCount: team.playerCount,
      teamSize: team.teamSize,
      players: team.players,
      wins: team.wins,
      losses: team.losses,
      starters: team.starters,
    );
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

  /// Apply pace modifiers from playbooks and coaching bonuses to determine total possessions
  static int _applyPaceModifiers(
    int basePossessions,
    Playbook? homePlaybook,
    Playbook? awayPlaybook,
    Map<String, double> homeCoachingBonuses,
    Map<String, double> awayCoachingBonuses,
  ) {
    double paceModifier = 1.0;

    // Apply home team pace modifier
    if (homePlaybook != null) {
      final homeModifiers = homePlaybook.getGameModifiers();
      paceModifier *= (1.0 + (homeModifiers['pace'] ?? 0.0));
    }

    // Apply away team pace modifier
    if (awayPlaybook != null) {
      final awayModifiers = awayPlaybook.getGameModifiers();
      paceModifier *= (1.0 + (awayModifiers['pace'] ?? 0.0));
    }

    // Apply coaching bonuses to pace
    final homeCoachPaceBonus = homeCoachingBonuses['pace'] ?? 0.0;
    final awayCoachPaceBonus = awayCoachingBonuses['pace'] ?? 0.0;
    paceModifier *= (1.0 + (homeCoachPaceBonus + awayCoachPaceBonus) / 2.0);

    // Average the pace modifiers and apply
    paceModifier = (paceModifier / 2.0).clamp(0.8, 1.3);

    return (basePossessions * paceModifier).round();
  }

  /// Simulate a single possession with role-based logic, playbook effects, and coaching bonuses
  static Map<String, dynamic> _simulatePossession(
    List<EnhancedPlayer> offensivePlayers,
    List<EnhancedPlayer> defensivePlayers,
    Map<String, Map<String, int>> offensiveBoxScore,
    Map<String, Map<String, int>> defensiveBoxScore, {
    required bool isHomeTeam,
    Playbook? offensivePlaybook,
    Playbook? defensivePlaybook,
    Map<String, double> offensiveCoachingBonuses = const {},
    Map<String, double> defensiveCoachingBonuses = const {},
  }) {
    int points = 0;
    bool retainPossession = false;

    // Get playbook modifiers and combine with coaching bonuses
    final offensiveModifiers = <String, double>{
      ...offensivePlaybook?.getGameModifiers() ?? <String, double>{},
      ...offensiveCoachingBonuses,
    };
    final defensiveModifiers = <String, double>{
      ...defensivePlaybook?.getGameModifiers() ?? <String, double>{},
      ...defensiveCoachingBonuses,
    };

    // Determine who gets the ball based on role and playbook strategy
    final ballHandler = _selectBallHandler(offensivePlayers, offensivePlaybook);

    // Check for turnover first (with playbook modifiers)
    if (_checkTurnover(
      ballHandler,
      defensivePlayers,
      offensiveModifiers,
      defensiveModifiers,
    )) {
      offensiveBoxScore[ballHandler.name]!['turnovers'] =
          (offensiveBoxScore[ballHandler.name]!['turnovers'] ?? 0) + 1;

      // Award steal to a defensive player
      final stealer = _selectStealer(defensivePlayers);
      defensiveBoxScore[stealer.name]!['steals'] =
          (defensiveBoxScore[stealer.name]!['steals'] ?? 0) + 1;

      return {'points': 0, 'retainPossession': false};
    }

    // Determine shot type and shooter based on roles and playbook strategy
    final shooter = _selectShooter(
      offensivePlayers,
      ballHandler,
      offensivePlaybook,
    );
    final shotType = _determineShotType(shooter, offensivePlaybook);

    // Check for block attempt first (only on inside shots)
    if (shotType == ShotType.inside &&
        _checkBlock(shooter, defensivePlayers, defensiveBoxScore)) {
      return {
        'points': 0,
        'retainPossession': false,
      }; // Blocked shot = possession change
    }

    // Apply role-based and playbook modifiers to shooting
    final roleModifiers = shooter.calculateRoleBasedModifiers();
    final shotSuccess = _attemptShot(
      shooter,
      shotType,
      defensivePlayers,
      roleModifiers,
      offensiveModifiers,
      defensiveModifiers,
    );

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

      // Enhanced assist logic with multiple factors
      if (shooter != ballHandler) {
        final assistChance = _calculateAssistChance(
          ballHandler,
          shooter,
          shotType,
          offensivePlaybook,
          defensivePlaybook,
        );

        if (_random.nextDouble() < assistChance) {
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

  /// Select ball handler based on role and playbook strategy
  static EnhancedPlayer _selectBallHandler(
    List<EnhancedPlayer> players,
    Playbook? playbook,
  ) {
    // Apply playbook-specific ball handler preferences
    if (playbook != null) {
      switch (playbook.offensiveStrategy) {
        case OffensiveStrategy.fastBreak:
          // Fast break prefers fastest guards
          final guards =
              players
                  .where(
                    (p) =>
                        p.primaryRole == PlayerRole.pointGuard ||
                        p.primaryRole == PlayerRole.shootingGuard,
                  )
                  .toList();
          if (guards.isNotEmpty) {
            guards.sort((a, b) => b.ballHandling.compareTo(a.ballHandling));
            return guards.first;
          }
          break;
        case OffensiveStrategy.pickAndRoll:
          // Pick and roll heavily favors point guards
          final pointGuards =
              players
                  .where((p) => p.primaryRole == PlayerRole.pointGuard)
                  .toList();
          if (pointGuards.isNotEmpty) {
            return pointGuards[_random.nextInt(pointGuards.length)];
          }
          break;
        case OffensiveStrategy.postUp:
          // Post-up can start with big men
          if (_random.nextDouble() < 0.3) {
            final bigMen =
                players
                    .where(
                      (p) =>
                          p.primaryRole == PlayerRole.center ||
                          p.primaryRole == PlayerRole.powerForward,
                    )
                    .toList();
            if (bigMen.isNotEmpty) {
              return bigMen[_random.nextInt(bigMen.length)];
            }
          }
          break;
        default:
          break;
      }
    }

    // Default logic: Prefer point guards, then shooting guards
    final pointGuards =
        players.where((p) => p.primaryRole == PlayerRole.pointGuard).toList();
    if (pointGuards.isNotEmpty) {
      return pointGuards[_random.nextInt(pointGuards.length)];
    }

    final shootingGuards =
        players
            .where((p) => p.primaryRole == PlayerRole.shootingGuard)
            .toList();
    if (shootingGuards.isNotEmpty) {
      return shootingGuards[_random.nextInt(shootingGuards.length)];
    }

    // Fallback to any player
    return players[_random.nextInt(players.length)];
  }

  /// Check for turnover based on ball handling, defensive pressure, and playbook effects
  static bool _checkTurnover(
    EnhancedPlayer ballHandler,
    List<EnhancedPlayer> defenders,
    Map<String, double> offensiveModifiers,
    Map<String, double> defensiveModifiers,
  ) {
    final ballHandlingSkill = ballHandler.ballHandling;
    final roleModifiers = ballHandler.calculateRoleBasedModifiers();
    final adjustedBallHandling =
        ballHandlingSkill * (roleModifiers['ballHandling'] ?? 1.0);

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

    // Apply playbook modifiers to turnover chance
    double playbookTurnoverModifier = 1.0;

    // Offensive playbook effects
    playbookTurnoverModifier *=
        (1.0 - (offensiveModifiers['ballHandling'] ?? 0.0));
    playbookTurnoverModifier *=
        (1.0 + (offensiveModifiers['turnovers'] ?? 0.0));

    // Defensive playbook effects (press defense increases turnovers)
    playbookTurnoverModifier *= (1.0 + (defensiveModifiers['pressure'] ?? 0.0));

    final baseTurnoverChance =
        (100 - adjustedBallHandling + defensivePressure) / 1000;
    final finalTurnoverChance = (baseTurnoverChance *
            turnoverModifier *
            playbookTurnoverModifier)
        .clamp(0.01, 0.20);

    return _random.nextDouble() < finalTurnoverChance;
  }

  /// Select player who gets the steal
  static EnhancedPlayer _selectStealer(List<EnhancedPlayer> defenders) {
    // Weight by perimeter defense and role
    final weights =
        defenders.map((player) {
          double weight = player.perimeterDefense.toDouble();
          if (player.primaryRole == PlayerRole.pointGuard ||
              player.primaryRole == PlayerRole.shootingGuard) {
            weight *= 1.5; // Guards more likely to get steals
          }
          return weight;
        }).toList();

    return _selectWeightedRandom(defenders, weights);
  }

  /// Select shooter based on role, situation, and playbook strategy
  static EnhancedPlayer _selectShooter(
    List<EnhancedPlayer> players,
    EnhancedPlayer ballHandler,
    Playbook? playbook,
  ) {
    double ballHandlerShootChance = 0.4;

    // Apply playbook-specific shooter selection
    if (playbook != null) {
      switch (playbook.offensiveStrategy) {
        case OffensiveStrategy.fastBreak:
          // Fast break: first good shot
          ballHandlerShootChance = 0.6;
          break;
        case OffensiveStrategy.threePointHeavy:
          // Three-point heavy: prefer best shooters
          ballHandlerShootChance = 0.2;
          break;
        case OffensiveStrategy.postUp:
          // Post-up: prefer big men
          final bigMen =
              players
                  .where(
                    (p) =>
                        p.primaryRole == PlayerRole.center ||
                        p.primaryRole == PlayerRole.powerForward,
                  )
                  .toList();
          if (bigMen.isNotEmpty && _random.nextDouble() < 0.7) {
            return _selectWeightedRandom(
              bigMen,
              bigMen.map((p) => p.insideShooting.toDouble()).toList(),
            );
          }
          break;
        case OffensiveStrategy.pickAndRoll:
          // Pick and roll: balanced approach
          ballHandlerShootChance = 0.45;
          break;
        default:
          break;
      }
    }

    if (_random.nextDouble() < ballHandlerShootChance) {
      return ballHandler;
    }

    // Weight by shooting ability, role, and playbook preferences
    final weights =
        players.map((player) {
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

          // Apply playbook-specific weights
          if (playbook != null) {
            switch (playbook.offensiveStrategy) {
              case OffensiveStrategy.threePointHeavy:
                if (player.primaryRole == PlayerRole.shootingGuard ||
                    player.primaryRole == PlayerRole.smallForward) {
                  weight *= 1.5;
                }
                break;
              case OffensiveStrategy.postUp:
                if (player.primaryRole == PlayerRole.center ||
                    player.primaryRole == PlayerRole.powerForward) {
                  weight *= 2.0;
                }
                break;
              default:
                break;
            }
          }

          return weight;
        }).toList();

    return _selectWeightedRandom(players, weights);
  }

  /// Determine shot type based on player role, position, and playbook strategy
  static ShotType _determineShotType(
    EnhancedPlayer shooter,
    Playbook? playbook,
  ) {
    final role = shooter.primaryRole;
    double random = _random.nextDouble();

    // Apply playbook-specific shot selection modifiers
    Map<ShotType, double> shotTypeWeights = {};

    // Base weights by role
    switch (role) {
      case PlayerRole.center:
      case PlayerRole.powerForward:
        shotTypeWeights = {
          ShotType.inside: 0.7,
          ShotType.midRange: 0.2,
          ShotType.threePoint: 0.1,
        };
        break;
      case PlayerRole.pointGuard:
        shotTypeWeights = {
          ShotType.inside: 0.2,
          ShotType.midRange: 0.3,
          ShotType.threePoint: 0.5,
        };
        break;
      case PlayerRole.shootingGuard:
        shotTypeWeights = {
          ShotType.inside: 0.15,
          ShotType.midRange: 0.25,
          ShotType.threePoint: 0.6,
        };
        break;
      case PlayerRole.smallForward:
        shotTypeWeights = {
          ShotType.inside: 0.3,
          ShotType.midRange: 0.3,
          ShotType.threePoint: 0.4,
        };
        break;
    }

    // Apply playbook modifiers
    if (playbook != null) {
      switch (playbook.offensiveStrategy) {
        case OffensiveStrategy.threePointHeavy:
          shotTypeWeights[ShotType.threePoint] =
              (shotTypeWeights[ShotType.threePoint]! * 1.8).clamp(0.0, 0.9);
          shotTypeWeights[ShotType.inside] =
              shotTypeWeights[ShotType.inside]! * 0.5;
          break;
        case OffensiveStrategy.postUp:
          shotTypeWeights[ShotType.inside] =
              (shotTypeWeights[ShotType.inside]! * 1.6).clamp(0.0, 0.9);
          shotTypeWeights[ShotType.threePoint] =
              shotTypeWeights[ShotType.threePoint]! * 0.6;
          break;
        case OffensiveStrategy.fastBreak:
          // Fast break prefers quick shots (inside and three-point)
          shotTypeWeights[ShotType.midRange] =
              shotTypeWeights[ShotType.midRange]! * 0.7;
          break;
        default:
          break;
      }
    }

    // Normalize weights
    final totalWeight = shotTypeWeights.values.reduce((a, b) => a + b);
    shotTypeWeights = shotTypeWeights.map(
      (key, value) => MapEntry(key, value / totalWeight),
    );

    // Select shot type based on weights
    double cumulative = 0.0;
    for (final entry in shotTypeWeights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    return ShotType.midRange; // Fallback
  }

  /// Attempt a shot with role-based and playbook modifiers
  static Map<String, dynamic> _attemptShot(
    EnhancedPlayer shooter,
    ShotType shotType,
    List<EnhancedPlayer> defenders,
    Map<String, double> roleModifiers,
    Map<String, double> offensiveModifiers,
    Map<String, double> defensiveModifiers,
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

    // Apply playbook offensive modifiers
    if (shotType == ShotType.threePoint) {
      finalModifier *= (1.0 + (offensiveModifiers['shooting'] ?? 0.0));
      finalModifier *= (1.0 + (offensiveModifiers['spacing'] ?? 0.0));
    } else if (shotType == ShotType.inside) {
      finalModifier *= (1.0 + (offensiveModifiers['insideShooting'] ?? 0.0));
      finalModifier *= (1.0 + (offensiveModifiers['postMoves'] ?? 0.0));
    }

    // Apply general offensive modifiers
    finalModifier *= (1.0 + (offensiveModifiers['ballMovement'] ?? 0.0));

    baseAccuracy *= finalModifier;

    // Apply defensive pressure with role-based and playbook defensive modifiers
    double defensiveModifier = 1.0;
    for (final defender in defenders) {
      final defenderModifiers = defender.calculateRoleBasedModifiers();

      if (shotType == ShotType.inside) {
        final postDefenseBonus = defenderModifiers['postDefense'] ?? 1.0;
        defensiveModifier -= (defender.postDefense * postDefenseBonus) * 0.001;
      } else {
        final perimeterDefenseBonus =
            defenderModifiers['perimeterDefense'] ?? 1.0;
        defensiveModifier -=
            (defender.perimeterDefense * perimeterDefenseBonus) * 0.001;
      }
    }

    // Apply playbook defensive modifiers
    defensiveModifier *=
        (1.0 - (defensiveModifiers['individualDefense'] ?? 0.0));
    defensiveModifier *= (1.0 - (defensiveModifiers['teamDefense'] ?? 0.0));
    defensiveModifier *= (1.0 - (defensiveModifiers['positioning'] ?? 0.0));

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
    final weights =
        allPlayers.map((player) {
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
    final potentialBlockers =
        defenders
            .where(
              (defender) =>
                  defender.primaryRole == PlayerRole.center ||
                  defender.primaryRole == PlayerRole.powerForward,
            )
            .toList();

    if (potentialBlockers.isEmpty) return false;

    // Calculate block probability
    double totalBlockChance = 0.0;
    EnhancedPlayer? blocker;

    for (final defender in potentialBlockers) {
      final roleModifiers = defender.calculateRoleBasedModifiers();
      final blockBonus = roleModifiers['blocks'] ?? 1.0;
      final blockChance =
          (defender.postDefense * blockBonus) / 2000; // Low base chance

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

  /// Record player performances in their performance maps and award development experience
  static void _recordPlayerPerformances(
    List<EnhancedPlayer> players,
    Map<String, Map<String, int>> boxScore,
    int matchday,
    CoachProfile? coach,
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
      final totalStats =
          (stats['points'] ?? 0) +
          (stats['rebounds'] ?? 0) +
          (stats['assists'] ?? 0);
      final experience = (totalStats * 0.1).clamp(0.1, 2.0);
      player.awardRoleExperience(player.primaryRole, experience);

      // Award additional experience for playing in optimal role
      if (player.roleCompatibility > 0.8) {
        player.awardRoleExperience(player.primaryRole, experience * 0.2);
      }

      // Award development experience with coaching bonuses
      if (coach != null) {
        DevelopmentService.awardExperienceWithCoaching(player, stats, coach);
      } else {
        DevelopmentService.awardGameExperience(player, stats);
      }

      // Process skill development
      final upgradedSkills = DevelopmentService.processSkillDevelopment(player);
      if (upgradedSkills.isNotEmpty) {
        // Log skill improvements for debugging
        print(
          'Player ${player.name} improved skills: ${upgradedSkills.join(', ')}',
        );
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

  /// Update coach progression after game completion
  static void _updateCoachAfterGame(
    CoachProfile coach,
    bool won,
    int teamScore,
    int opponentScore,
    List<EnhancedPlayer> teamPlayers,
  ) {
    // Calculate team performance rating (0-100)
    final scoreDifference = teamScore - opponentScore;
    final teamPerformanceRating = _calculateTeamPerformanceRating(
      teamScore,
      opponentScore,
      teamPlayers,
    );

    // Determine special game conditions
    final wasUpset = false; // Would need team ratings to determine this
    final wasBlowout = scoreDifference.abs() > 20;

    // Calculate and award experience
    final gameExperience = CoachProgressionService.calculateGameExperience(
      won,
      teamPerformanceRating,
      wasUpset,
      wasBlowout,
      coach.primarySpecialization,
    );

    coach.awardExperience(gameExperience);

    // Track developed players (players who improved skills this game)
    final developedPlayers =
        teamPlayers.where((player) => _playerImprovedThisGame(player)).toList();

    // Update coaching service with game results
    CoachingService.updateCoachAfterGame(
      coach,
      won,
      teamPerformanceRating,
      developedPlayers,
    );

    // Check for new achievements
    final newAchievements = CoachProgressionService.checkAndUnlockAchievements(
      coach,
    );
    if (newAchievements.isNotEmpty) {
      print(
        'Coach ${coach.name} unlocked achievements: ${newAchievements.map((a) => a.name).join(', ')}',
      );
    }
  }

  /// Calculate team performance rating based on game statistics
  static int _calculateTeamPerformanceRating(
    int teamScore,
    int opponentScore,
    List<EnhancedPlayer> teamPlayers,
  ) {
    // Base rating from score differential
    final scoreDifference = teamScore - opponentScore;
    int rating = 50 + (scoreDifference * 2).clamp(-30, 30);

    // Adjust based on team shooting efficiency (would need more detailed stats)
    // For now, use a simplified calculation based on score
    if (teamScore > 110) rating += 10; // High-scoring game
    if (teamScore < 80) rating -= 10; // Low-scoring game

    return rating.clamp(0, 100);
  }

  /// Calculate assist chance based on multiple factors
  static double _calculateAssistChance(
    EnhancedPlayer ballHandler,
    EnhancedPlayer shooter,
    ShotType shotType,
    Playbook? offensivePlaybook,
    Playbook? defensivePlaybook,
  ) {
    // Base assist chance varies by shot type
    double baseChance = switch (shotType) {
      ShotType.inside => 0.45, // Inside shots less likely to be assisted
      ShotType.midRange => 0.65, // Mid-range shots moderately assisted
      ShotType.threePoint => 0.85, // Three-pointers highly assisted
    };

    // Ball handler's passing ability and role modifiers
    final ballHandlerModifiers = ballHandler.calculateRoleBasedModifiers();
    final passingSkill = ballHandler.passing / 100.0; // Normalize to 0-1
    final assistBonus = ballHandlerModifiers['assists'] ?? 1.0;

    // Shooter's ability to receive passes (ball handling affects this)
    final shooterReceiving = shooter.ballHandling / 100.0;

    // Role-based assist tendencies
    double roleMultiplier = 1.0;
    switch (ballHandler.primaryRole) {
      case PlayerRole.pointGuard:
        roleMultiplier = 1.3; // Point guards are primary playmakers
        break;
      case PlayerRole.shootingGuard:
        roleMultiplier = 1.1; // Secondary playmakers
        break;
      case PlayerRole.smallForward:
        roleMultiplier = 1.15; // Versatile players
        break;
      case PlayerRole.powerForward:
        roleMultiplier = 0.9; // Less likely to assist
        break;
      case PlayerRole.center:
        roleMultiplier = 0.8; // Least likely to assist
        break;
    }

    // Playbook influence on ball movement
    double playbookMultiplier = 1.0;
    if (offensivePlaybook != null) {
      switch (offensivePlaybook.offensiveStrategy) {
        case OffensiveStrategy.fastBreak:
          playbookMultiplier = 0.9; // Fast breaks often unassisted
          break;
        case OffensiveStrategy.halfCourt:
          playbookMultiplier = 1.2; // Half-court sets emphasize ball movement
          break;
        case OffensiveStrategy.pickAndRoll:
          playbookMultiplier =
              1.15; // Pick and roll creates assist opportunities
          break;
        case OffensiveStrategy.postUp:
          playbookMultiplier = 0.85; // Post-ups often individual efforts
          break;
        case OffensiveStrategy.threePointHeavy:
          playbookMultiplier =
              1.25; // Three-point offense requires ball movement
          break;
      }
    }

    // Calculate final assist chance
    final assistChance =
        baseChance *
        passingSkill *
        assistBonus *
        shooterReceiving *
        roleMultiplier *
        playbookMultiplier;

    // Clamp to reasonable range
    return assistChance.clamp(0.05, 0.95);
  }

  /// Check if a player improved skills this game (simplified check)
  static bool _playerImprovedThisGame(EnhancedPlayer player) {
    // This is a simplified check - in a real implementation,
    // we'd track skill changes during the game
    return player.development.totalExperience > 0;
  }
}

/// Shot types for position-specific behavior
enum ShotType { inside, midRange, threePoint }
