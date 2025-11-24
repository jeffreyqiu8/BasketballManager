import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/team.dart';
import '../models/season.dart';
import '../models/player.dart';
import '../models/player_game_stats.dart';
import '../models/playoff_bracket.dart';
import '../models/playoff_series.dart';
import '../services/game_service.dart';
import '../services/league_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'player_profile_page.dart';

/// Game page for simulating basketball matches
/// Displays game setup and results with accessibility features
class GamePage extends StatefulWidget {
  final LeagueService leagueService;
  final String userTeamId;
  final Season season;
  final Function(Season) onSeasonUpdate;

  const GamePage({
    super.key,
    required this.leagueService,
    required this.userTeamId,
    required this.season,
    required this.onSeasonUpdate,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GameService _gameService = GameService();
  Game? _currentGame;
  Game? _lastPlayedGame;
  Team? _userTeam;
  Team? _opponentTeam;
  bool _isSimulating = false;
  late Season _season;

  @override
  void initState() {
    super.initState();
    _season = widget.season;
    _loadNextGame();
  }

  void _loadNextGame() {
    _userTeam = widget.leagueService.getTeam(widget.userTeamId);
    
    // Get the next unplayed game from the season
    _currentGame = _season.nextGame;
    
    if (_currentGame != null) {
      // Load opponent team
      final opponentId = _currentGame!.homeTeamId == widget.userTeamId
          ? _currentGame!.awayTeamId
          : _currentGame!.homeTeamId;
      _opponentTeam = widget.leagueService.getTeam(opponentId);
    }
    
    setState(() {});
  }

  Future<void> _simulateGame() async {
    if (_userTeam == null || _opponentTeam == null || _currentGame == null) return;
    
    setState(() {
      _isSimulating = true;
    });

    // Determine home and away teams
    final isUserHome = _currentGame!.homeTeamId == widget.userTeamId;
    final homeTeam = isUserHome ? _userTeam! : _opponentTeam!;
    final awayTeam = isUserHome ? _opponentTeam! : _userTeam!;

    // Check if this is a playoff game
    final isPlayoffGame = _season.isPostSeason && _season.playoffBracket != null;
    
    Game simulatedGame;
    if (isPlayoffGame) {
      // Get the user's current playoff series
      final userSeries = _season.playoffBracket!.getUserTeamSeries(widget.userTeamId);
      if (userSeries != null) {
        // Simulate playoff game with series reference
        simulatedGame = _gameService.simulatePlayoffGame(homeTeam, awayTeam, userSeries);
      } else {
        // Fallback to regular simulation if no series found
        simulatedGame = _gameService.simulateGameDetailed(homeTeam, awayTeam);
      }
    } else {
      // Regular season game
      simulatedGame = _gameService.simulateGameDetailed(homeTeam, awayTeam);
    }
    
    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update the game in the season (for regular season)
    if (!isPlayoffGame) {
      final gameIndex = _season.games.indexWhere((g) => g.id == _currentGame!.id);
      if (gameIndex != -1) {
        final updatedGames = List<Game>.from(_season.games);
        updatedGames[gameIndex] = simulatedGame;
        _season = _season.copyWith(games: updatedGames);
      }
    }
    
    // Update statistics with game stats (only for user's team players)
    if (simulatedGame.boxScore != null && simulatedGame.boxScore!.isNotEmpty) {
      // Filter box score to only include user's team players
      final userTeamStats = <String, PlayerGameStats>{};
      for (var entry in simulatedGame.boxScore!.entries) {
        // Check if player belongs to user's team
        if (_userTeam!.players.any((p) => p.id == entry.key)) {
          userTeamStats[entry.key] = entry.value;
        }
      }
      
      // Update appropriate stats based on game type
      if (userTeamStats.isNotEmpty) {
        if (isPlayoffGame) {
          _season = _season.updatePlayoffStats(userTeamStats);
        } else {
          _season = _season.updateSeasonStats(userTeamStats);
        }
      }
    }
    
    // Update playoff bracket if this was a playoff game
    if (isPlayoffGame && _season.playoffBracket != null) {
      final userSeries = _season.playoffBracket!.getUserTeamSeries(widget.userTeamId);
      if (userSeries != null) {
        // Update the series with the game result
        final updatedSeries = _gameService.updateSeriesWithResult(userSeries, simulatedGame);
        
        // Update the bracket with the updated series
        var updatedBracket = _updateBracketWithSeries(_season.playoffBracket!, updatedSeries);
        
        // Check if the series is complete
        if (updatedSeries.isComplete) {
          final won = updatedSeries.winnerId == widget.userTeamId;
          final seriesAnnouncement = won
              ? 'Series complete! You won ${updatedSeries.seriesScore}'
              : 'Series complete! You lost ${updatedSeries.seriesScore}';
          
          if (mounted) {
            AccessibilityUtils.showAccessibleInfo(
              context,
              seriesAnnouncement,
              duration: const Duration(seconds: 3),
            );
          }
        }
        
        // Check if the current round is complete and advance if needed
        if (updatedBracket.isRoundComplete()) {
          final currentRound = updatedBracket.currentRound;
          updatedBracket = widget.leagueService.advancePlayoffRound(updatedBracket);
          
          // Show notification about advancing to next round
          if (updatedBracket.currentRound != currentRound && mounted) {
            final nextRoundName = _getRoundName(updatedBracket.currentRound);
            AccessibilityUtils.showAccessibleSuccess(
              context,
              'Advancing to $nextRoundName!',
              duration: const Duration(seconds: 4),
            );
          }
        }
        
        // Update the season with the new bracket
        _season = _season.updatePlayoffBracket(updatedBracket);
      }
    }
    
    // Notify parent of season update
    widget.onSeasonUpdate(_season);
    
    setState(() {
      _lastPlayedGame = simulatedGame;
      _isSimulating = false;
    });

    // Announce result for screen readers with accessibility features
    if (mounted) {
      final userScore = simulatedGame.homeTeamId == widget.userTeamId 
          ? simulatedGame.homeScore 
          : simulatedGame.awayScore;
      final opponentScore = simulatedGame.homeTeamId == widget.userTeamId 
          ? simulatedGame.awayScore 
          : simulatedGame.homeScore;
      
      final won = userScore! > opponentScore!;
      final gameType = isPlayoffGame ? 'Playoff game' : 'Game';
      final announcement = won 
          ? '$gameType complete. You won $userScore to $opponentScore'
          : '$gameType complete. You lost $userScore to $opponentScore';
      
      // Use accessible announcement
      AccessibilityUtils.announce(context, announcement);
      AccessibilityUtils.showAccessibleInfo(context, announcement);
      
      // Check if regular season is complete
      if (!isPlayoffGame && _season.isComplete) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            final seasonCompleteMsg = 'Season Complete! Final Record: ${_season.wins} wins, ${_season.losses} losses';
            AccessibilityUtils.showAccessibleSuccess(
              context,
              seasonCompleteMsg,
              duration: const Duration(seconds: 5),
            );
          }
        });
      }
    }
  }
  
  /// Update the playoff bracket with an updated series
  /// This helper method updates the appropriate round in the bracket
  PlayoffBracket _updateBracketWithSeries(PlayoffBracket bracket, PlayoffSeries updatedSeries) {
    // Create a map for quick lookup
    final seriesMap = {updatedSeries.id: updatedSeries};
    
    // Update the appropriate round based on current round
    switch (bracket.currentRound) {
      case 'play-in':
        final updatedPlayInGames = bracket.playInGames.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: updatedPlayInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'first-round':
        final updatedFirstRound = bracket.firstRound.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: updatedFirstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'conf-semis':
        final updatedConferenceSemis = bracket.conferenceSemis.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: updatedConferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'conf-finals':
        final updatedConferenceFinals = bracket.conferenceFinals.map((series) {
          return seriesMap[series.id] ?? series;
        }).toList();
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: updatedConferenceFinals,
          nbaFinals: bracket.nbaFinals,
          currentRound: bracket.currentRound,
        );

      case 'finals':
        final updatedNbaFinals = bracket.nbaFinals != null && seriesMap.containsKey(bracket.nbaFinals!.id)
            ? seriesMap[bracket.nbaFinals!.id]
            : bracket.nbaFinals;
        return PlayoffBracket(
          seasonId: bracket.seasonId,
          teamSeedings: bracket.teamSeedings,
          teamConferences: bracket.teamConferences,
          playInGames: bracket.playInGames,
          firstRound: bracket.firstRound,
          conferenceSemis: bracket.conferenceSemis,
          conferenceFinals: bracket.conferenceFinals,
          nbaFinals: updatedNbaFinals,
          currentRound: bracket.currentRound,
        );

      default:
        return bracket;
    }
  }
  
  /// Get human-readable round name
  String _getRoundName(String round) {
    switch (round) {
      case 'play-in':
        return 'Play-In Tournament';
      case 'first-round':
        return 'First Round';
      case 'conf-semis':
        return 'Conference Semifinals';
      case 'conf-finals':
        return 'Conference Finals';
      case 'finals':
        return 'NBA Finals';
      case 'complete':
        return 'Season Complete';
      default:
        return 'Playoffs';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGame == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Simulation'),
        ),
        body: Center(
          child: Semantics(
            label: 'Season complete! Final record: ${_season.wins} wins, ${_season.losses} losses',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Season Complete!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Final Record: ${_season.wins}-${_season.losses}',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Return to home page',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Simulation'),
      ),
      body: _userTeam == null || _opponentTeam == null
          ? const LoadingIndicator(message: 'Loading teams')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Season progress header
                  _buildSeasonProgressHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Matchup display
                  _buildMatchupCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Simulate button
                  Semantics(
                    label: 'Simulate game ${_season.gamesPlayed + 1} of 82 between ${_userTeam!.city} ${_userTeam!.name} and ${_opponentTeam!.city} ${_opponentTeam!.name}',
                    button: true,
                    enabled: !_isSimulating,
                    child: ElevatedButton(
                      onPressed: _isSimulating ? null : _simulateGame,
                      style: ElevatedButton.styleFrom(
                        padding: AppTheme.buttonPaddingLarge,
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSimulating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Simulating...'),
                              ],
                            )
                          : const Text('Play Game'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Game result
                  if (_lastPlayedGame != null) _buildGameResult(),
                ],
              ),
            ),
    );
  }

  Widget _buildSeasonProgressHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Season progress: Game ${_season.gamesPlayed + 1} of 82. Current record: ${_season.wins} wins, ${_season.losses} losses',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.1),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Game ${_season.gamesPlayed + 1} of 82',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Record: ${_season.wins}-${_season.losses}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Season progress: ${_season.gamesPlayed} of 82 games completed',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  child: LinearProgressIndicator(
                    value: _season.gamesPlayed / 82,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF2A2A2A) : AppTheme.dividerColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppTheme.infoColorDark : AppTheme.infoColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchupCard() {
    return Card(
      elevation: AppTheme.cardElevationMedium,
      child: Padding(
        padding: AppTheme.cardPadding,
        child: Column(
          children: [
            const Text(
              'Matchup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // User team
            _buildTeamInfo(_userTeam!, isUserTeam: true),
            
            const SizedBox(height: 16),
            
            const Text(
              'VS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Opponent team
            _buildTeamInfo(_opponentTeam!, isUserTeam: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(Team team, {required bool isUserTeam}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Semantics(
          label: '${isUserTeam ? "Your team" : "Opponent"}: ${team.city} ${team.name}, overall rating ${team.teamRating}',
          child: Container(
            padding: AppTheme.cardPadding,
            decoration: BoxDecoration(
              color: isUserTeam 
                  ? (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.1)
                  : (isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Column(
              children: [
                Text(
                  '${team.city} ${team.name}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  'Overall: ${team.teamRating}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameResult() {
    final game = _lastPlayedGame!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUserHome = game.homeTeamId == widget.userTeamId;
    final userScore = isUserHome ? game.homeScore! : game.awayScore!;
    final opponentScore = isUserHome ? game.awayScore! : game.homeScore!;
    final won = userScore > opponentScore;

    return Column(
      children: [
        Semantics(
          label: 'Game result: ${won ? "Victory" : "Defeat"}. Final score: ${_userTeam!.city} ${_userTeam!.name} $userScore, ${_opponentTeam!.city} ${_opponentTeam!.name} $opponentScore',
          child: Card(
            elevation: AppTheme.cardElevationHigh,
            color: won 
                ? (isDark ? AppTheme.successColorDark : AppTheme.successColor).withValues(alpha: 0.1)
                : (isDark ? AppTheme.errorColorDark : AppTheme.errorColor).withValues(alpha: 0.1),
            child: Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                children: [
                  Text(
                    won ? '🏆 Victory!' : '😔 Defeat',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getWinLossColor(won, isDark: isDark),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Final Score',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Score display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // User team score
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_userTeam!.city}\n${_userTeam!.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$userScore',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getWinLossColor(won, isDark: isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Text(
                        '-',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Opponent team score
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_opponentTeam!.city}\n${_opponentTeam!.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$opponentScore',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.getWinLossColor(!won, isDark: isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Updated season record
                  Container(
                    padding: AppTheme.cardPadding,
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    ),
                    child: Text(
                      'Season Record: ${_season.wins}-${_season.losses}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Box score display
        if (game.boxScore != null && game.boxScore!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildBoxScore(game.boxScore!),
        ],
      ],
    );
  }

  Widget _buildBoxScore(Map<String, PlayerGameStats> boxScore) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get all players from both teams
    final allPlayers = [..._userTeam!.players, ..._opponentTeam!.players];
    
    // Create separate lists for each team, sorted by points descending
    final userTeamPlayers = <Map<String, dynamic>>[];
    final opponentTeamPlayers = <Map<String, dynamic>>[];
    
    for (var entry in boxScore.entries) {
      final player = allPlayers.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => allPlayers.first, // Fallback
      );
      final stats = entry.value;
      final isUserTeam = _userTeam!.players.any((p) => p.id == player.id);
      
      // Only include players with stats
      if (stats.points > 0 || stats.rebounds > 0 || stats.assists > 0) {
        final playerData = {
          'player': player,
          'stats': stats,
          'isUserTeam': isUserTeam,
        };
        
        if (isUserTeam) {
          userTeamPlayers.add(playerData);
        } else {
          opponentTeamPlayers.add(playerData);
        }
      }
    }
    
    // Sort each team by points descending
    userTeamPlayers.sort((a, b) => (b['stats'] as PlayerGameStats).points
        .compareTo((a['stats'] as PlayerGameStats).points));
    opponentTeamPlayers.sort((a, b) => (b['stats'] as PlayerGameStats).points
        .compareTo((a['stats'] as PlayerGameStats).points));
    
    final playerStatsList = [...userTeamPlayers, ...opponentTeamPlayers];

    // Calculate team totals
    int userTeamPoints = 0, userTeamRebounds = 0, userTeamAssists = 0;
    int userTeamFGM = 0, userTeamFGA = 0, userTeam3PM = 0, userTeam3PA = 0;
    int userTeamTO = 0, userTeamSTL = 0, userTeamBLK = 0, userTeamPF = 0;
    int userTeamFTM = 0, userTeamFTA = 0;
    int oppTeamPoints = 0, oppTeamRebounds = 0, oppTeamAssists = 0;
    int oppTeamFGM = 0, oppTeamFGA = 0, oppTeam3PM = 0, oppTeam3PA = 0;
    int oppTeamTO = 0, oppTeamSTL = 0, oppTeamBLK = 0, oppTeamPF = 0;
    int oppTeamFTM = 0, oppTeamFTA = 0;

    for (var item in playerStatsList) {
      final stats = item['stats'] as PlayerGameStats;
      final isUserTeam = item['isUserTeam'] as bool;
      
      if (isUserTeam) {
        userTeamPoints += stats.points;
        userTeamRebounds += stats.rebounds;
        userTeamAssists += stats.assists;
        userTeamFGM += stats.fieldGoalsMade;
        userTeamFGA += stats.fieldGoalsAttempted;
        userTeam3PM += stats.threePointersMade;
        userTeam3PA += stats.threePointersAttempted;
        userTeamTO += stats.turnovers;
        userTeamSTL += stats.steals;
        userTeamBLK += stats.blocks;
        userTeamPF += stats.fouls;
        userTeamFTM += stats.freeThrowsMade;
        userTeamFTA += stats.freeThrowsAttempted;
      } else {
        oppTeamPoints += stats.points;
        oppTeamRebounds += stats.rebounds;
        oppTeamAssists += stats.assists;
        oppTeamFGM += stats.fieldGoalsMade;
        oppTeamFGA += stats.fieldGoalsAttempted;
        oppTeam3PM += stats.threePointersMade;
        oppTeam3PA += stats.threePointersAttempted;
        oppTeamTO += stats.turnovers;
        oppTeamSTL += stats.steals;
        oppTeamBLK += stats.blocks;
        oppTeamPF += stats.fouls;
        oppTeamFTM += stats.freeThrowsMade;
        oppTeamFTA += stats.freeThrowsAttempted;
      }
    }

    final userTeamFGPct = userTeamFGA > 0 ? (userTeamFGM / userTeamFGA * 100) : 0.0;
    final userTeam3PPct = userTeam3PA > 0 ? (userTeam3PM / userTeam3PA * 100) : 0.0;
    final userTeamFTPct = userTeamFTA > 0 ? (userTeamFTM / userTeamFTA * 100) : 0.0;
    final oppTeamFGPct = oppTeamFGA > 0 ? (oppTeamFGM / oppTeamFGA * 100) : 0.0;
    final oppTeam3PPct = oppTeam3PA > 0 ? (oppTeam3PM / oppTeam3PA * 100) : 0.0;
    final oppTeamFTPct = oppTeamFTA > 0 ? (oppTeamFTM / oppTeamFTA * 100) : 0.0;

    return Semantics(
      label: 'Box score with player statistics',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Box Score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Table header
              Semantics(
                label: 'Statistics table with columns: Player name, Points, Rebounds, Assists, Field Goals, Field Goal Percentage, Three Pointers, Three Point Percentage, Free Throws, Free Throw Percentage, Turnovers, Steals, Blocks, Personal Fouls',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            'Player',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            ),
                          ),
                        ),
                        _buildHeaderCell('PTS'),
                        _buildHeaderCell('REB'),
                        _buildHeaderCell('AST'),
                        _buildHeaderCell('FG', width: 60),
                        _buildHeaderCell('FG%'),
                        _buildHeaderCell('3PT', width: 60),
                        _buildHeaderCell('3P%'),
                        _buildHeaderCell('FT', width: 60),
                        _buildHeaderCell('FT%'),
                        _buildHeaderCell('TO'),
                        _buildHeaderCell('STL'),
                        _buildHeaderCell('BLK'),
                        _buildHeaderCell('PF'),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // User team section
              Semantics(
                label: '${_userTeam!.city} ${_userTeam!.name} player statistics',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        '${_userTeam!.city} ${_userTeam!.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...userTeamPlayers.map((item) => _buildPlayerRow(item)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Opponent team section
              Semantics(
                label: '${_opponentTeam!.city} ${_opponentTeam!.name} player statistics',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        '${_opponentTeam!.city} ${_opponentTeam!.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...opponentTeamPlayers.map((item) => _buildPlayerRow(item)),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Team totals
              Semantics(
                label: 'Team totals',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Column(
                    children: [
                      // User team totals
                      Semantics(
                        label: '${_userTeam!.name} totals: $userTeamPoints points, $userTeamRebounds rebounds, $userTeamAssists assists, $userTeamFGM of $userTeamFGA field goals, ${userTeamFGPct.toStringAsFixed(1)} percent field goals, $userTeam3PM of $userTeam3PA three pointers, ${userTeam3PPct.toStringAsFixed(1)} percent three pointers, $userTeamFTM of $userTeamFTA free throws, ${userTeamFTPct.toStringAsFixed(1)} percent free throws, $userTeamTO turnovers, $userTeamSTL steals, $userTeamBLK blocks, $userTeamPF fouls',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${_userTeam!.name} Total',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              _buildStatCell(userTeamPoints, isBold: true),
                              _buildStatCell(userTeamRebounds, isBold: true),
                              _buildStatCell(userTeamAssists, isBold: true),
                              _buildFractionCell(userTeamFGM, userTeamFGA, isBold: true, width: 60),
                              _buildPercentageCell(userTeamFGPct, isBold: true),
                              _buildFractionCell(userTeam3PM, userTeam3PA, isBold: true, width: 60),
                              _buildPercentageCell(userTeam3PPct, isBold: true),
                              _buildFractionCell(userTeamFTM, userTeamFTA, isBold: true, width: 60),
                              _buildPercentageCell(userTeamFTPct, isBold: true),
                              _buildStatCell(userTeamTO, isBold: true),
                              _buildStatCell(userTeamSTL, isBold: true),
                              _buildStatCell(userTeamBLK, isBold: true),
                              _buildStatCell(userTeamPF, isBold: true),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Opponent team totals
                      Semantics(
                        label: '${_opponentTeam!.name} totals: $oppTeamPoints points, $oppTeamRebounds rebounds, $oppTeamAssists assists, $oppTeamFGM of $oppTeamFGA field goals, ${oppTeamFGPct.toStringAsFixed(1)} percent field goals, $oppTeam3PM of $oppTeam3PA three pointers, ${oppTeam3PPct.toStringAsFixed(1)} percent three pointers, $oppTeamFTM of $oppTeamFTA free throws, ${oppTeamFTPct.toStringAsFixed(1)} percent free throws, $oppTeamTO turnovers, $oppTeamSTL steals, $oppTeamBLK blocks, $oppTeamPF fouls',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${_opponentTeam!.name} Total',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              _buildStatCell(oppTeamPoints, isBold: true),
                              _buildStatCell(oppTeamRebounds, isBold: true),
                              _buildStatCell(oppTeamAssists, isBold: true),
                              _buildFractionCell(oppTeamFGM, oppTeamFGA, isBold: true, width: 60),
                              _buildPercentageCell(oppTeamFGPct, isBold: true),
                              _buildFractionCell(oppTeam3PM, oppTeam3PA, isBold: true, width: 60),
                              _buildPercentageCell(oppTeam3PPct, isBold: true),
                              _buildFractionCell(oppTeamFTM, oppTeamFTA, isBold: true, width: 60),
                              _buildPercentageCell(oppTeamFTPct, isBold: true),
                              _buildStatCell(oppTeamTO, isBold: true),
                              _buildStatCell(oppTeamSTL, isBold: true),
                              _buildStatCell(oppTeamBLK, isBold: true),
                              _buildStatCell(oppTeamPF, isBold: true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = item['player'] as Player;
    final stats = item['stats'] as PlayerGameStats;
    final isUserTeam = item['isUserTeam'] as bool;
    
    return Semantics(
      label: '${player.name}, ${stats.points} points, ${stats.rebounds} rebounds, ${stats.assists} assists, ${stats.fieldGoalsMade} of ${stats.fieldGoalsAttempted} field goals, ${stats.fieldGoalPercentage.toStringAsFixed(1)} percent field goals, ${stats.threePointersMade} of ${stats.threePointersAttempted} three pointers, ${stats.threePointPercentage.toStringAsFixed(1)} percent three pointers, ${stats.freeThrowsMade} of ${stats.freeThrowsAttempted} free throws, ${stats.freeThrowPercentage.toStringAsFixed(1)} percent free throws, ${stats.turnovers} turnovers, ${stats.steals} steals, ${stats.blocks} blocks, ${stats.fouls} fouls',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: InkWell(
                  onTap: () => _navigateToPlayerProfile(player, isUserTeam),
                  child: Text(
                    player.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      color: isDark
                          ? AppTheme.primaryColorDark
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              _buildStatCell(stats.points, isHighPerformance: stats.points >= 20),
              _buildStatCell(stats.rebounds, isHighPerformance: stats.rebounds >= 10),
              _buildStatCell(stats.assists, isHighPerformance: stats.assists >= 10),
              _buildFractionCell(stats.fieldGoalsMade, stats.fieldGoalsAttempted, width: 60),
              _buildPercentageCell(stats.fieldGoalPercentage, isHighPerformance: stats.fieldGoalPercentage >= 50),
              _buildFractionCell(stats.threePointersMade, stats.threePointersAttempted, width: 60),
              _buildPercentageCell(stats.threePointPercentage, isHighPerformance: stats.threePointPercentage >= 40),
              _buildFractionCell(stats.freeThrowsMade, stats.freeThrowsAttempted, width: 60),
              _buildPercentageCell(stats.freeThrowPercentage, isHighPerformance: stats.freeThrowPercentage >= 80),
              _buildStatCell(stats.turnovers),
              _buildStatCell(stats.steals, isHighPerformance: stats.steals >= 3),
              _buildStatCell(stats.blocks, isHighPerformance: stats.blocks >= 2),
              _buildStatCell(stats.fouls),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double width = 50}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatCell(int value, {bool isHighPerformance = false, bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color coding for high performance (WCAG AA compliant)
    Color? textColor;
    if (isHighPerformance) {
      textColor = isDark ? AppTheme.successColorDark : const Color(0xFF2E7D32); // Dark green for light mode
    }
    
    return SizedBox(
      width: 50,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPercentageCell(double value, {bool isHighPerformance = false, bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color coding for high performance (WCAG AA compliant)
    Color? textColor;
    if (isHighPerformance) {
      textColor = isDark ? AppTheme.successColorDark : const Color(0xFF2E7D32); // Dark green for light mode
    }
    
    return SizedBox(
      width: 50,
      child: Text(
        value > 0 ? '${value.toStringAsFixed(1)}%' : '-',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFractionCell(int made, int attempted, {bool isBold = false, double width = 50}) {
    return SizedBox(
      width: width,
      child: Text(
        attempted > 0 ? '$made/$attempted' : '-',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Navigate to player profile page
  void _navigateToPlayerProfile(Player player, bool isUserTeam) {
    final team = isUserTeam ? _userTeam! : _opponentTeam!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerProfilePage(
          player: player,
          teamPlayers: team.players,
          season: _season,
          leagueService: widget.leagueService,
          teamId: team.id,
        ),
      ),
    );
  }
}
