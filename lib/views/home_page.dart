import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../models/game_state.dart';
import '../models/playoff_bracket.dart';
import '../models/playoff_series.dart';
import '../services/league_service.dart';
import '../services/game_service.dart';
import '../services/playoff_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/championship_celebration_dialog.dart';
import 'game_page.dart';
import 'teams_list_page.dart';
import 'team_overview_page.dart';
import 'season_page.dart';
import 'save_page.dart';
import 'playoff_bracket_page.dart';
import 'league_standings_page.dart';
import 'package:uuid/uuid.dart';

/// Home page displaying user's team and season progress
/// Main navigation hub for the basketball manager app
class HomePage extends StatefulWidget {
  final LeagueService? leagueService;
  final Season? initialSeason;
  final String? initialUserTeamId;

  const HomePage({
    super.key,
    this.leagueService,
    this.initialSeason,
    this.initialUserTeamId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LeagueService _leagueService;
  final GameService _gameService = GameService();

  bool _isInitialized = false;
  String? _userTeamId;
  Team? _userTeam;
  Season? _currentSeason;

  @override
  void initState() {
    super.initState();
    _leagueService = widget.leagueService ?? LeagueService();
    _initializeGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we should show championship celebration
    _checkForChampionshipCelebration();
  }

  void _checkForChampionshipCelebration() {
    if (_currentSeason == null || _userTeamId == null) return;
    
    // Only show if playoffs are complete, user won, and we haven't recorded the championship yet
    final bracket = _currentSeason!.playoffBracket;
    if (bracket != null &&
        bracket.currentRound == 'complete' &&
        bracket.nbaFinals?.winnerId == _userTeamId &&
        _currentSeason!.championshipRecord == null) {
      // Use addPostFrameCallback to show dialog after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showChampionshipCelebration();
      });
    }
  }

  Future<void> _initializeGame() async {
    // Check if we have initial data from a loaded save
    if (widget.initialSeason != null && widget.initialUserTeamId != null) {
      _currentSeason = widget.initialSeason;
      _userTeamId = widget.initialUserTeamId;
      _userTeam = _leagueService.getTeam(_userTeamId!);
      
      // If loaded season doesn't have a league schedule, create one
      if (_currentSeason!.leagueSchedule == null) {
        _currentSeason = _leagueService.initializeSeasonWithLeagueSchedule(_currentSeason!);
      }
      
      setState(() {
        _isInitialized = true;
      });
      return;
    }

    // Otherwise initialize a new league (legacy behavior)
    await _leagueService.initializeLeague();

    // Get user's team (first team for demo)
    final teams = _leagueService.getAllTeams();
    if (teams.isNotEmpty) {
      _userTeamId = teams[0].id;
      _userTeam = teams[0];

      // Generate season schedule
      final schedule = _gameService.generateSchedule(_userTeamId!, teams);
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: schedule,
        userTeamId: _userTeamId!,
      );
      
      // Initialize with league-wide schedule
      _currentSeason = _leagueService.initializeSeasonWithLeagueSchedule(season);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  void _loadGameState(GameState gameState) {
    setState(() {
      // Update league service with loaded teams
      final teamsList = _leagueService.getTeamsList();
      teamsList.clear();
      teamsList.addAll(gameState.teams);

      // Update current season
      _currentSeason = gameState.currentSeason;
      _userTeamId = gameState.userTeamId;
      _userTeam = _leagueService.getTeam(_userTeamId!);
    });
  }

  void _navigateToSavePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SavePage(
              leagueService: _leagueService,
              currentSeason: _currentSeason,
              userTeamId: _userTeamId,
              onLoadGame: _loadGameState,
            ),
      ),
    );
  }

  /// Show championship celebration dialog
  void _showChampionshipCelebration() {
    if (_currentSeason == null || _userTeam == null) return;

    // Complete the playoffs and record championship
    final bracket = _currentSeason!.playoffBracket;
    if (bracket?.nbaFinals == null) return;

    final runnerUpTeamId = bracket!.nbaFinals!.winnerId == bracket.nbaFinals!.homeTeamId
        ? bracket.nbaFinals!.awayTeamId
        : bracket.nbaFinals!.homeTeamId;

    final updatedSeason = _currentSeason!.completePlayoffs(
      _userTeamId!,
      runnerUpTeamId,
    );

    setState(() {
      _currentSeason = updatedSeason;
    });

    // Show celebration dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChampionshipCelebrationDialog(
        season: updatedSeason,
        championTeam: _userTeam!,
        leagueService: _leagueService,
        onStartNewSeason: _startNewSeason,
      ),
    );
  }

  /// Simulate the rest of the playoffs to completion
  Future<void> _simulateRestOfPlayoffs() async {
    if (_currentSeason == null || _currentSeason!.playoffBracket == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Rest of Playoffs'),
        content: const Text(
          'This will simulate all remaining playoff games to determine the champion. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simulate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Simulating playoffs...'),
          ],
        ),
      ),
    );

    try {
      var updatedBracket = _currentSeason!.playoffBracket!;
      
      // Simulate until playoffs are complete or user has a series to play
      int iterations = 0;
      const maxIterations = 100; // Safety limit to prevent infinite loops
      
      while (updatedBracket.currentRound != 'complete' && iterations < maxIterations) {
        iterations++;
        
        // Check if user has a series to play in current round
        final userSeries = updatedBracket.getUserTeamSeries(_userTeamId!);
        if (userSeries != null && !userSeries.isComplete) {
          // User has a series to play, stop simulation
          break;
        }
        
        // Simulate all non-user games in current round
        final result = PlayoffService.simulateNonUserPlayoffGames(
          bracket: updatedBracket,
          userTeamId: _userTeamId!,
          getTeam: (teamId) => _leagueService.getTeam(teamId)!,
          simulateGame: (homeTeam, awayTeam, series) {
            return _gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
          },
        );
        
        updatedBracket = result.bracket;
        
        // Small delay to show progress
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (iterations >= maxIterations) {
        throw Exception('Playoff simulation stuck in infinite loop');
      }

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Update the season with completed bracket
      setState(() {
        _currentSeason = _currentSeason!.updatePlayoffBracket(updatedBracket);
      });

      // Show success message with champion
      final champion = updatedBracket.nbaFinals?.winnerId;
      if (champion != null) {
        final championTeam = _leagueService.getTeam(champion);
        if (championTeam != null) {
          AccessibilityUtils.showAccessibleSuccess(
            context,
            'Playoffs complete! Champion: ${championTeam.city} ${championTeam.name}',
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      AccessibilityUtils.showAccessibleInfo(
        context,
        'Error simulating playoffs: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Start a new season
  Future<void> _startNewSeason() async {
    if (_userTeamId == null) return;

    // Generate new season schedule
    final teams = _leagueService.getAllTeams();
    final schedule = _gameService.generateSchedule(_userTeamId!, teams);
    
    final seasonId = const Uuid().v4();
    
    var newSeason = Season(
      id: seasonId,
      year: (_currentSeason?.year ?? 2024) + 1,
      games: schedule,
      userTeamId: _userTeamId!,
    );
    
    // Initialize with league-wide schedule
    newSeason = _leagueService.initializeSeasonWithLeagueSchedule(newSeason);

    setState(() {
      _currentSeason = newSeason;
    });

    // Note: In a full implementation, we would save the new season to the current save slot
    // For now, we just update the state and notify the user

    AccessibilityUtils.showAccessibleInfo(
      context,
      'New season started! Year ${newSeason.year}',
      duration: const Duration(seconds: 2),
    );
  }

  void _navigateToGame() {
    if (_currentSeason == null || _userTeamId == null) return;

    // Only check if regular season is complete (not playoffs)
    if (!_currentSeason!.isPostSeason && _currentSeason!.isComplete) {
      AccessibilityUtils.showAccessibleInfo(
        context,
        'Season complete! All 82 games have been played.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GamePage(
              leagueService: _leagueService,
              userTeamId: _userTeamId!,
              season: _currentSeason!,
              onSeasonUpdate: (updatedSeason) {
                setState(() {
                  _currentSeason = updatedSeason;
                });
              },
            ),
      ),
    );
  }

  void _navigateToPlayoffBracket() {
    if (_currentSeason == null || 
        _userTeamId == null || 
        _currentSeason!.playoffBracket == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PlayoffBracketPage(
              bracket: _currentSeason!.playoffBracket!,
              userTeamId: _userTeamId!,
              leagueService: _leagueService,
            ),
      ),
    );
  }

  Future<void> _simulateRemainingSeason() async {
    if (_currentSeason == null || _userTeamId == null) return;

    if (_currentSeason!.isComplete) {
      AccessibilityUtils.showAccessibleInfo(
        context,
        'Season is already complete!',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Remaining Season'),
        content: Text(
          'This will simulate all ${_currentSeason!.gamesRemaining} remaining games. '
          'This may take a few moments. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simulate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Simulating remaining season...'),
          ],
        ),
      ),
    );

    try {
      // Simulate the remaining season
      final updatedSeason = await Future.microtask(() {
        return _leagueService.simulateRemainingRegularSeasonGames(
          _currentSeason!,
          _gameService,
          updateStats: true,
        );
      });

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Update the season
      setState(() {
        _currentSeason = updatedSeason;
      });

      // Check if we should start post-season
      final postSeasonSeason = _leagueService.checkAndStartPostSeason(updatedSeason);
      if (postSeasonSeason != null) {
        setState(() {
          _currentSeason = postSeasonSeason;
        });
      }

      // Show success message
      AccessibilityUtils.showAccessibleInfo(
        context,
        'Season simulation complete! Record: ${updatedSeason.wins}-${updatedSeason.losses}',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      AccessibilityUtils.showAccessibleInfo(
        context,
        'Error simulating season: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Basketball Manager')),
        body: const LoadingIndicator(message: 'Loading game'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Basketball Manager')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team header
            _buildTeamHeader(),

            const SizedBox(height: 24),

            // Season record card or playoff status
            if (_currentSeason!.isPostSeason)
              _buildPlayoffStatusCard()
            else
              _buildSeasonRecordCard(),

            const SizedBox(height: 24),

            // Play next game button
            _buildPlayNextGameButton(),

            const SizedBox(height: 16),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Your team: ${_userTeam!.city} ${_userTeam!.name}',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              Icon(
                Icons.sports_basketball,
                size: 60,
                color:
                    isDark
                        ? AppTheme.secondaryColorDark
                        : AppTheme.secondaryColor,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                '${_userTeam!.city} ${_userTeam!.name}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'Team Overall: ${_userTeam!.teamRating}',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonRecordCard() {
    final season = _currentSeason!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winPercentage =
        season.gamesPlayed > 0
            ? (season.wins / season.gamesPlayed * 100).toStringAsFixed(1)
            : '0.0';

    return Semantics(
      label:
          'Season record: ${season.wins} wins, ${season.losses} losses. ${season.gamesPlayed} games played, ${season.gamesRemaining} games remaining',
      child: Card(
        elevation: AppTheme.cardElevationHigh,
        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor)
            .withOpacity(0.1),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              const Text(
                'Season 2024',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Win-Loss record
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${season.wins}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppTheme.successColorDark
                              : AppTheme.successColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '${season.losses}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppTheme.errorColorDark
                              : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Win Percentage: $winPercentage%',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Games progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Played', '${season.gamesPlayed}'),
                  _buildStatColumn('Remaining', '${season.gamesRemaining}'),
                  _buildStatColumn('Total', '82'),
                ],
              ),

              const SizedBox(height: 16),

              // Progress bar with accessibility label
              Semantics(
                label:
                    'Season progress: ${season.gamesPlayed} of 82 games completed',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  child: LinearProgressIndicator(
                    value: season.gamesPlayed / 82,
                    minHeight: 12,
                    backgroundColor:
                        isDark
                            ? const Color(0xFF2A2A2A)
                            : AppTheme.dividerColorLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      season.isComplete
                          ? (isDark
                              ? AppTheme.successColorDark
                              : AppTheme.successColor)
                          : (isDark
                              ? AppTheme.infoColorDark
                              : AppTheme.infoColor),
                    ),
                  ),
                ),
              ),

              if (season.isComplete) ...[
                const SizedBox(height: AppTheme.spacingMedium),
                Semantics(
                  label: 'Season complete! All 82 games have been played.',
                  child: Container(
                    padding: AppTheme.cardPadding,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                      border: Border.all(
                        color: AppTheme.successColor,
                        width: 2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: AppTheme.successColor),
                        SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          'Season Complete!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXSmall),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color:
                isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayoffStatusCard() {
    final season = _currentSeason!;
    final bracket = season.playoffBracket;
    if (bracket == null) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userSeries = bracket.getUserTeamSeries(_userTeamId!);
    final isPlayoffsComplete = bracket.currentRound == 'complete';
    final isUserEliminated = bracket.isTeamEliminated(_userTeamId!);
    final isChampion = isPlayoffsComplete && bracket.nbaFinals?.winnerId == _userTeamId;
    
    // Check if user never made playoffs
    // A team made playoffs if they have a seed of 10 or better (1-10)
    final userSeed = bracket.teamSeedings[_userTeamId];
    final neverMadePlayoffs = userSeed == null || userSeed > 10;
    
    return Semantics(
      label: _getPlayoffStatusLabel(bracket, userSeries, isUserEliminated, isChampion),
      child: Card(
        elevation: AppTheme.cardElevationHigh,
        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor)
            .withValues(alpha: 0.1),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              // Championship celebration
              if (isChampion) ...[
                Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                ),
                const SizedBox(height: 16),
                Text(
                  '🏆 NBA CHAMPIONS! 🏆',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_userTeam!.city} ${_userTeam!.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Congratulations on winning the championship!',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ]
              // Didn't make playoffs
              else if (neverMadePlayoffs) ...[
                Icon(
                  Icons.sports_basketball,
                  size: 60,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'Missed Playoffs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your team did not qualify for the playoffs this season',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Final Record: ${season.wins}-${season.losses}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _navigateToPlayoffBracket,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('View Playoff Bracket'),
                ),
              ]
              // Team eliminated
              else if (isUserEliminated) ...[
                Icon(
                  Icons.cancel,
                  size: 60,
                  color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Team Eliminated',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your playoff run has ended in the ${_getEliminationRound(bracket)}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _navigateToPlayoffBracket,
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('View Playoff Bracket'),
                ),
              ]
              // Playoffs complete but didn't win
              else if (isPlayoffsComplete) ...[
                const Icon(
                  Icons.sports_basketball,
                  size: 60,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Playoffs Complete',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (bracket.nbaFinals?.winnerId != null) ...[
                  Text(
                    'Champion: ${_getTeamName(bracket.nbaFinals!.winnerId!)}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ]
              // Active playoff series
              else if (userSeries != null) ...[
                Text(
                  _getRoundName(bracket.currentRound),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Series matchup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _getTeamName(userSeries.homeTeamId),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: userSeries.homeTeamId == _userTeamId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${userSeries.homeWins}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.successColorDark
                                  : AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'vs',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            _getTeamName(userSeries.awayTeamId),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: userSeries.awayTeamId == _userTeamId
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${userSeries.awayWins}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.successColorDark
                                  : AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Best of 7 Series',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ]
              // Waiting for round to complete
              else ...[
                const Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  _getRoundName(bracket.currentRound),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for other series to complete',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPlayoffStatusLabel(
    PlayoffBracket bracket,
    PlayoffSeries? userSeries,
    bool isUserEliminated,
    bool isChampion,
  ) {
    if (isChampion) {
      return 'NBA Champions! ${_userTeam!.city} ${_userTeam!.name} won the championship!';
    }
    if (isUserEliminated) {
      return 'Team eliminated from playoffs in ${_getRoundName(bracket.currentRound)}';
    }
    if (userSeries != null) {
      return '${_getRoundName(bracket.currentRound)}: Series ${userSeries.seriesScore}. ${_getTeamName(userSeries.homeTeamId)} vs ${_getTeamName(userSeries.awayTeamId)}';
    }
    return '${_getRoundName(bracket.currentRound)}: Waiting for other series to complete';
  }

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

  String _getTeamName(String teamId) {
    final team = _leagueService.getTeam(teamId);
    if (team == null) return 'Unknown Team';
    return '${team.city} ${team.name}';
  }

  /// Get the round where the user's team was eliminated
  String _getEliminationRound(PlayoffBracket bracket) {
    // Check each round to find where the team lost
    
    // Check play-in
    for (var series in bracket.playInGames) {
      if (series.isComplete && 
          (series.homeTeamId == _userTeamId || series.awayTeamId == _userTeamId) &&
          series.winnerId != _userTeamId) {
        // Lost a play-in game, but check if they made it to first round
        final inFirstRound = bracket.firstRound.any((s) => 
          s.homeTeamId == _userTeamId || s.awayTeamId == _userTeamId);
        if (!inFirstRound) {
          return _getRoundName('play-in');
        }
      }
    }
    
    // Check first round
    for (var series in bracket.firstRound) {
      if (series.isComplete && 
          (series.homeTeamId == _userTeamId || series.awayTeamId == _userTeamId) &&
          series.winnerId != _userTeamId) {
        return _getRoundName('first-round');
      }
    }
    
    // Check conference semifinals
    for (var series in bracket.conferenceSemis) {
      if (series.isComplete && 
          (series.homeTeamId == _userTeamId || series.awayTeamId == _userTeamId) &&
          series.winnerId != _userTeamId) {
        return _getRoundName('conf-semis');
      }
    }
    
    // Check conference finals
    for (var series in bracket.conferenceFinals) {
      if (series.isComplete && 
          (series.homeTeamId == _userTeamId || series.awayTeamId == _userTeamId) &&
          series.winnerId != _userTeamId) {
        return _getRoundName('conf-finals');
      }
    }
    
    // Check NBA Finals
    if (bracket.nbaFinals != null && bracket.nbaFinals!.isComplete &&
        (bracket.nbaFinals!.homeTeamId == _userTeamId || bracket.nbaFinals!.awayTeamId == _userTeamId) &&
        bracket.nbaFinals!.winnerId != _userTeamId) {
      return _getRoundName('finals');
    }
    
    // Shouldn't reach here, but return current round as fallback
    return _getRoundName(bracket.currentRound);
  }

  Widget _buildPlayNextGameButton() {
    final season = _currentSeason!;
    
    // Post-season mode
    if (season.isPostSeason) {
      final bracket = season.playoffBracket;
      if (bracket == null) return const SizedBox.shrink();
      
      final userSeries = bracket.getUserTeamSeries(_userTeamId!);
      final isPlayoffsComplete = bracket.currentRound == 'complete';
      final isUserEliminated = bracket.isTeamEliminated(_userTeamId!);
      
      // Check if user won the championship
      if (isPlayoffsComplete && bracket.nbaFinals?.winnerId == _userTeamId) {
        return Semantics(
          label: 'Championship won! Start a new season',
          button: true,
          child: ElevatedButton.icon(
            onPressed: _startNewSeason,
            icon: const Icon(Icons.emoji_events, size: 28),
            label: const Text(
              'Start New Season',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: AppTheme.buttonPaddingLarge,
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      
      // Check if user made playoffs
      final userSeed = bracket.teamSeedings[_userTeamId];
      final userMissedPlayoffs = userSeed == null || userSeed > 10;
      
      // User team eliminated or didn't make playoffs
      if ((isUserEliminated && !isPlayoffsComplete) || userMissedPlayoffs) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simulate rest of playoffs button
            Semantics(
              label: 'Simulate the rest of the playoffs to see who wins',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _simulateRestOfPlayoffs,
                icon: const Icon(Icons.fast_forward, size: 24),
                label: const Text(
                  'Simulate Rest of Playoffs',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: AppTheme.buttonPaddingMedium,
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // View playoff bracket button
            Semantics(
              label: 'View playoff bracket',
              button: true,
              child: OutlinedButton.icon(
                onPressed: _navigateToPlayoffBracket,
                icon: const Icon(Icons.emoji_events),
                label: const Text(
                  'View Playoff Bracket',
                  style: TextStyle(fontSize: 16),
                ),
                style: OutlinedButton.styleFrom(
                  padding: AppTheme.buttonPaddingMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Start new season button
            Semantics(
              label: 'Start a new season',
              button: true,
              child: ElevatedButton.icon(
                onPressed: _startNewSeason,
                icon: const Icon(Icons.refresh, size: 24),
                label: const Text(
                  'Start New Season',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: AppTheme.buttonPaddingMedium,
                  backgroundColor: const Color.fromARGB(255, 55, 11, 92),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      }
      
      // Playoffs complete but user didn't win
      if (isPlayoffsComplete) {
        return Semantics(
          label: 'Playoffs complete. Start a new season',
          button: true,
          child: ElevatedButton.icon(
            onPressed: _startNewSeason,
            icon: const Icon(Icons.refresh, size: 28),
            label: const Text(
              'Start New Season',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: AppTheme.buttonPaddingLarge,
              backgroundColor: const Color.fromARGB(255, 55, 11, 92),
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      
      // User has next playoff game
      if (userSeries != null && !userSeries.isComplete) {
        return Semantics(
          label: 'Play next playoff game in ${_getRoundName(bracket.currentRound)}',
          button: true,
          child: ElevatedButton.icon(
            onPressed: _navigateToGame,
            icon: const Icon(Icons.sports_basketball, size: 28),
            label: const Text(
              'Play Next Playoff Game',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: AppTheme.buttonPaddingLarge,
              backgroundColor: const Color.fromARGB(255, 55, 11, 92),
              foregroundColor: Colors.white,
            ),
          ),
        );
      }
      
      // Waiting for other series to complete (user finished their series or waiting for play-in)
      final isWaitingForPlayIn = bracket.currentRound == 'play-in' && userSeries == null && !userMissedPlayoffs;
      final buttonText = isWaitingForPlayIn ? 'Simulate Play-In Tournament' : 'Simulate Rest of Playoffs';
      final buttonLabel = isWaitingForPlayIn 
          ? 'Simulate play-in tournament to advance to first round'
          : 'Simulate the rest of the playoffs to see who wins';
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulate rest of playoffs button
          Semantics(
            label: buttonLabel,
            button: true,
            child: ElevatedButton.icon(
              onPressed: _simulateRestOfPlayoffs,
              icon: const Icon(Icons.fast_forward, size: 24),
              label: Text(
                buttonText,
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: AppTheme.buttonPaddingMedium,
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // View playoff bracket button
          Semantics(
            label: 'View playoff bracket',
            button: true,
            child: OutlinedButton.icon(
              onPressed: _navigateToPlayoffBracket,
              icon: const Icon(Icons.emoji_events),
              label: const Text(
                'View Playoff Bracket',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: AppTheme.buttonPaddingMedium,
              ),
            ),
          ),
        ],
      );
    }
    
    // Regular season mode
    final isComplete = season.isComplete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              isComplete
                  ? 'Season complete, no more games to play'
                  : 'Play next game, game ${season.gamesPlayed + 1} of 82',
          button: true,
          enabled: !isComplete,
          child: ElevatedButton.icon(
            onPressed: isComplete ? null : _navigateToGame,
            icon: Icon(
              isComplete ? Icons.check_circle : Icons.play_arrow,
              size: 28,
            ),
            label: Text(
              isComplete ? 'Season Complete' : 'Play Next Game',
              style: const TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: AppTheme.buttonPaddingLarge,
              backgroundColor:
                  isComplete ? AppTheme.textDisabled : const Color.fromARGB(255, 55, 11, 92),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (!isComplete && season.gamesRemaining > 1) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'Simulate remaining ${season.gamesRemaining} games in the season',
            button: true,
            child: ElevatedButton.icon(
              onPressed: _simulateRemainingSeason,
              icon: const Icon(Icons.fast_forward, size: 24),
              label: Text(
                'Simulate Remaining Season (${season.gamesRemaining} games)',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: AppTheme.buttonPaddingMedium,
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'View your team roster and lineup',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TeamOverviewPage(
                        teamId: _userTeamId!,
                        leagueService: _leagueService,
                        season: _currentSeason,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.people),
            label: const Text('My Team'),
          ),
        ),

        const SizedBox(height: 12),

        Semantics(
          label: 'View season statistics for your players',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TeamOverviewPage(
                        teamId: _userTeamId!,
                        leagueService: _leagueService,
                        season: _currentSeason,
                        initialTab: 1, // Open to Season Stats tab
                      ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Season Statistics'),
          ),
        ),

        const SizedBox(height: 12),

        Semantics(
          label: 'View season schedule and game results',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SeasonPage(
                        season: _currentSeason!,
                        leagueService: _leagueService,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('Season Schedule'),
          ),
        ),

        const SizedBox(height: 12),

        Semantics(
          label: 'View league standings and team records',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => LeagueStandingsPage(
                        leagueService: _leagueService,
                        season: _currentSeason!,
                        userTeamId: _userTeamId!,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.leaderboard),
            label: const Text('League Standings'),
          ),
        ),

        const SizedBox(height: 12),

        // Show playoff bracket button if in post-season
        if (_currentSeason?.isPostSeason == true &&
            _currentSeason?.playoffBracket != null)
          Semantics(
            label: 'View playoff bracket and tournament progress',
            button: true,
            child: OutlinedButton.icon(
              onPressed: _navigateToPlayoffBracket,
              icon: const Icon(Icons.emoji_events),
              label: const Text('Playoff Bracket'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.infoColorDark
                      : AppTheme.infoColor,
                  width: 2,
                ),
              ),
            ),
          ),

        if (_currentSeason?.isPostSeason == true &&
            _currentSeason?.playoffBracket != null)
          const SizedBox(height: 12),

        Semantics(
          label: 'View all league teams',
          button: true,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamsListPage()),
              );
            },
            icon: const Icon(Icons.groups),
            label: const Text('All Teams'),
          ),
        ),

        const SizedBox(height: 12),

        Semantics(
          label: 'Manage save files',
          button: true,
          child: OutlinedButton.icon(
            onPressed: _navigateToSavePage,
            icon: const Icon(Icons.save),
            label: const Text('Save / Load Game'),
          ),
        ),
      ],
    );
  }
}
