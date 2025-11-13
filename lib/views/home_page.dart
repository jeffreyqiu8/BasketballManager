import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../models/game_state.dart';
import '../services/league_service.dart';
import '../services/game_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'game_page.dart';
import 'teams_list_page.dart';
import 'team_page.dart';
import 'season_page.dart';
import 'save_page.dart';

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

  Future<void> _initializeGame() async {
    // Check if we have initial data from a loaded save
    if (widget.initialSeason != null && widget.initialUserTeamId != null) {
      _currentSeason = widget.initialSeason;
      _userTeamId = widget.initialUserTeamId;
      _userTeam = _leagueService.getTeam(_userTeamId!);
      
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
      _currentSeason = Season(
        id: 'season-2024',
        year: 2024,
        games: schedule,
        userTeamId: _userTeamId!,
      );
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

  void _navigateToGame() {
    if (_currentSeason == null || _userTeamId == null) return;

    if (_currentSeason!.isComplete) {
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

            // Season record card
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

  Widget _buildPlayNextGameButton() {
    final season = _currentSeason!;
    final isComplete = season.isComplete;

    return Semantics(
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
                      (context) => TeamPage(
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
                      (context) => TeamPage(
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
