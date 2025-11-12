import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/season.dart';
import '../models/player_season_stats.dart';
import '../services/league_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';

/// TeamPage displays a single team's 15 players with lineup management
/// Allows users to view all player stats and manage starting lineup
class TeamPage extends StatefulWidget {
  final String teamId;
  final LeagueService leagueService;
  final Season? season;
  final int initialTab;

  const TeamPage({
    super.key,
    required this.teamId,
    required this.leagueService,
    this.season,
    this.initialTab = 0,
  });

  @override
  State<TeamPage> createState() => _TeamPageState();
}

enum _SortColumn {
  name,
  ppg,
  rpg,
  apg,
  fgPercentage,
  threePointPercentage,
  turnoversPerGame,
  stealsPerGame,
  blocksPerGame,
  foulsPerGame,
  freeThrowPercentage,
}

class _TeamPageState extends State<TeamPage>
    with SingleTickerProviderStateMixin {
  late Team _team;
  Set<String> _selectedStarterIds = {};
  bool _hasChanges = false;
  late TabController _tabController;

  // Season stats sorting
  _SortColumn _sortColumn = _SortColumn.ppg;
  bool _sortAscending = false;

  // Track expanded player cards in season stats
  final Set<String> _expandedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadTeam();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTeam() {
    final team = widget.leagueService.getTeam(widget.teamId);
    if (team != null) {
      setState(() {
        _team = team;
        _selectedStarterIds = Set.from(team.startingLineupIds);
      });
    }
  }

  void _togglePlayerStarter(String playerId) {
    setState(() {
      if (_selectedStarterIds.contains(playerId)) {
        // Remove from starters
        _selectedStarterIds.remove(playerId);
      } else {
        // Add to starters if less than 5
        if (_selectedStarterIds.length < 5) {
          _selectedStarterIds.add(playerId);
        } else {
          // Show accessible error - already have 5 starters
          AccessibilityUtils.showAccessibleError(
            context,
            'You must have exactly 5 starters. Remove a starter first.',
            duration: const Duration(seconds: 2),
          );
          return;
        }
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveLineup() async {
    // Validate exactly 5 starters
    if (_selectedStarterIds.length != 5) {
      AccessibilityUtils.showAccessibleError(
        context,
        'You must select exactly 5 starters. Currently selected: ${_selectedStarterIds.length}',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Update team with new lineup
    final updatedTeam = _team.copyWith(
      startingLineupIds: _selectedStarterIds.toList(),
    );

    await widget.leagueService.updateTeam(updatedTeam);

    setState(() {
      _team = updatedTeam;
      _hasChanges = false;
    });

    if (mounted) {
      AccessibilityUtils.showAccessibleSuccess(
        context,
        'Lineup saved successfully!',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _resetLineup() {
    setState(() {
      _selectedStarterIds = Set.from(_team.startingLineupIds);
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Team page for ${_team.city} ${_team.name}',
          child: Text('${_team.city} ${_team.name}'),
        ),
        actions: [
          if (_hasChanges)
            Semantics(
              label: 'Reset lineup changes',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetLineup,
                tooltip: 'Reset changes',
              ),
            ),
          if (_hasChanges)
            Semantics(
              label: 'Save lineup changes',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveLineup,
                tooltip: 'Save lineup',
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Semantics(
              label: 'Roster tab, view team roster and manage lineup',
              child: const Tab(icon: Icon(Icons.people), text: 'Roster'),
            ),
            Semantics(
              label: 'Season statistics tab, view player season statistics',
              child: const Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Season Stats',
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRosterTab(), _buildSeasonStatsTab()],
      ),
    );
  }

  Widget _buildRosterTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team info
            Semantics(
              label: 'Team rating: ${_team.teamRating}',
              child: Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Card(
                    elevation: AppTheme.cardElevationMedium,
                    child: Padding(
                      padding: AppTheme.cardPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Team Rating',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color:
                                  isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${_team.teamRating}',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Starting Lineup Section
            Semantics(
              label:
                  'Starting lineup section with ${_selectedStarterIds.length} of 5 players selected',
              child: _buildSectionHeader(
                context,
                'Starting Lineup (${_selectedStarterIds.length}/5)',
                Icons.star,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildPlayerList(
              _team.players
                  .where((p) => _selectedStarterIds.contains(p.id))
                  .toList(),
              isStarter: true,
            ),

            const SizedBox(height: 24),

            // Bench Section
            Semantics(
              label:
                  'Bench section with ${15 - _selectedStarterIds.length} players',
              child: _buildSectionHeader(
                context,
                'Bench (${15 - _selectedStarterIds.length})',
                Icons.event_seat,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildPlayerList(
              _team.players
                  .where((p) => !_selectedStarterIds.contains(p.id))
                  .toList(),
              isStarter: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonStatsTab() {
    if (widget.season == null ||
        widget.season!.seasonStats == null ||
        widget.season!.seasonStats!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Semantics(
                label:
                    'No season statistics available yet. Play games to see player statistics.',
                child: const Text(
                  'No season statistics available yet.\nPlay games to see player statistics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get season stats for team players
    final playerStats = <String, PlayerSeasonStats>{};
    for (var player in _team.players) {
      final stats = widget.season!.getPlayerStats(player.id);
      if (stats != null && stats.gamesPlayed > 0) {
        playerStats[player.id] = stats;
      }
    }

    if (playerStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Semantics(
                label:
                    'No statistics for team players yet. Play games to see player statistics.',
                child: const Text(
                  'No statistics for team players yet.\nPlay games to see player statistics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort players by selected column
    final sortedPlayerIds = playerStats.keys.toList();
    sortedPlayerIds.sort((a, b) {
      final statsA = playerStats[a]!;
      final statsB = playerStats[b]!;
      final playerA = _team.players.firstWhere((p) => p.id == a);
      final playerB = _team.players.firstWhere((p) => p.id == b);

      int comparison = 0;
      switch (_sortColumn) {
        case _SortColumn.name:
          comparison = playerA.name.compareTo(playerB.name);
          break;
        case _SortColumn.ppg:
          comparison = statsA.pointsPerGame.compareTo(statsB.pointsPerGame);
          break;
        case _SortColumn.rpg:
          comparison = statsA.reboundsPerGame.compareTo(statsB.reboundsPerGame);
          break;
        case _SortColumn.apg:
          comparison = statsA.assistsPerGame.compareTo(statsB.assistsPerGame);
          break;
        case _SortColumn.fgPercentage:
          comparison = statsA.fieldGoalPercentage.compareTo(
            statsB.fieldGoalPercentage,
          );
          break;
        case _SortColumn.threePointPercentage:
          comparison = statsA.threePointPercentage.compareTo(
            statsB.threePointPercentage,
          );
          break;
        case _SortColumn.turnoversPerGame:
          comparison = statsA.turnoversPerGame.compareTo(
            statsB.turnoversPerGame,
          );
          break;
        case _SortColumn.stealsPerGame:
          comparison = statsA.stealsPerGame.compareTo(statsB.stealsPerGame);
          break;
        case _SortColumn.blocksPerGame:
          comparison = statsA.blocksPerGame.compareTo(statsB.blocksPerGame);
          break;
        case _SortColumn.foulsPerGame:
          comparison = statsA.foulsPerGame.compareTo(statsB.foulsPerGame);
          break;
        case _SortColumn.freeThrowPercentage:
          comparison = statsA.freeThrowPercentage.compareTo(
            statsB.freeThrowPercentage,
          );
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Semantics(
              label: 'Season statistics for ${_team.city} ${_team.name}',
              child: _buildSectionHeader(
                context,
                'Season Statistics',
                Icons.bar_chart,
              ),
            ),
            const SizedBox(height: 8),

            // Sort controls
            _buildSortControls(),
            const SizedBox(height: 16),

            // Statistics cards
            ...sortedPlayerIds.map((playerId) {
              final player = _team.players.firstWhere((p) => p.id == playerId);
              final stats = playerStats[playerId]!;
              return _buildPlayerStatsCard(player, stats);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSortControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: AppTheme.cardElevationLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.sort,
              size: 20,
              color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<_SortColumn>(
                value: _sortColumn,
                isExpanded: true,
                underline: Container(),
                items: const [
                  DropdownMenuItem(
                    value: _SortColumn.name,
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.ppg,
                    child: Text('Points Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.rpg,
                    child: Text('Rebounds Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.apg,
                    child: Text('Assists Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.stealsPerGame,
                    child: Text('Steals Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.blocksPerGame,
                    child: Text('Blocks Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.turnoversPerGame,
                    child: Text('Turnovers Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.foulsPerGame,
                    child: Text('Fouls Per Game'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.fgPercentage,
                    child: Text('Field Goal %'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.threePointPercentage,
                    child: Text('Three Point %'),
                  ),
                  DropdownMenuItem(
                    value: _SortColumn.freeThrowPercentage,
                    child: Text('Free Throw %'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortColumn = value;
                    });
                  }
                },
              ),
            ),
            IconButton(
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color:
                    isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              },
              tooltip: _sortAscending ? 'Ascending' : 'Descending',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatsCard(Player player, PlayerSeasonStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedPlayerIds.contains(player.id);

    return Semantics(
      label:
          '${player.name}, ${stats.pointsPerGame.toStringAsFixed(1)} points per game, ${stats.reboundsPerGame.toStringAsFixed(1)} rebounds, ${stats.assistsPerGame.toStringAsFixed(1)} assists. Tap to ${isExpanded ? 'collapse' : 'expand'} details',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: AppTheme.cardElevationMedium,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPlayerIds.remove(player.id);
              } else {
                _expandedPlayerIds.add(player.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with name and key stats
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${stats.gamesPlayed} Games',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color:
                          isDark
                              ? AppTheme.primaryColorDark
                              : AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primary stats (always visible)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'PPG',
                      stats.pointsPerGame.toStringAsFixed(1),
                      stats.pointsPerGame >= 20.0,
                      isDark,
                    ),
                    _buildStatItem(
                      'RPG',
                      stats.reboundsPerGame.toStringAsFixed(1),
                      stats.reboundsPerGame >= 10.0,
                      isDark,
                    ),
                    _buildStatItem(
                      'APG',
                      stats.assistsPerGame.toStringAsFixed(1),
                      stats.assistsPerGame >= 8.0,
                      isDark,
                    ),
                  ],
                ),

                // Expanded details
                if (isExpanded) ...[
                  const Divider(height: 24),

                  // Shooting stats
                  _buildStatSection('Shooting', [
                    _buildDetailStatRow(
                      'FG%',
                      '${stats.fieldGoalPercentage.toStringAsFixed(1)}%',
                      stats.fieldGoalPercentage >= 50.0,
                      isDark,
                    ),
                    _buildDetailStatRow(
                      '3PT%',
                      '${stats.threePointPercentage.toStringAsFixed(1)}%',
                      stats.threePointPercentage >= 40.0,
                      isDark,
                    ),
                    _buildDetailStatRow(
                      'FT%',
                      '${stats.freeThrowPercentage.toStringAsFixed(1)}%',
                      stats.freeThrowPercentage >= 80.0,
                      isDark,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Defense stats
                  _buildStatSection('Defense', [
                    _buildDetailStatRow(
                      'SPG',
                      stats.stealsPerGame.toStringAsFixed(1),
                      stats.stealsPerGame >= 2.0,
                      isDark,
                    ),
                    _buildDetailStatRow(
                      'BPG',
                      stats.blocksPerGame.toStringAsFixed(1),
                      stats.blocksPerGame >= 1.5,
                      isDark,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Other stats
                  _buildStatSection('Other', [
                    _buildDetailStatRow(
                      'TPG',
                      stats.turnoversPerGame.toStringAsFixed(1),
                      stats.turnoversPerGame >= 3.0,
                      isDark,
                      isNegative: true,
                    ),
                    _buildDetailStatRow(
                      'FPG',
                      stats.foulsPerGame.toStringAsFixed(1),
                      stats.foulsPerGame >= 4.0,
                      isDark,
                      isNegative: true,
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    bool isHighlight,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color:
                isHighlight
                    ? (isDark
                        ? AppTheme.successColorDark
                        : AppTheme.successColor)
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatSection(String title, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...stats,
      ],
    );
  }

  Widget _buildDetailStatRow(
    String label,
    String value,
    bool isHighlight,
    bool isDark, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color:
                  isHighlight
                      ? (isNegative
                          ? (isDark
                              ? AppTheme.errorColorDark
                              : AppTheme.errorColor)
                          : (isDark
                              ? AppTheme.successColorDark
                              : AppTheme.successColor))
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlayerList(
    List<Player> players, {
    required bool isStarter,
  }) {
    if (players.isEmpty) {
      return [
        Padding(
          padding: AppTheme.cardPadding,
          child: Text(
            isStarter ? 'No starters selected' : 'No bench players',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ];
    }

    return players
        .map((player) => _buildPlayerCard(player, isStarter))
        .toList();
  }

  Widget _buildPlayerCard(Player player, bool isStarter) {
    final isSelected = _selectedStarterIds.contains(player.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label:
          '${player.name}, ${player.heightFormatted}, overall rating ${player.overallRating}, ${isSelected ? 'starter' : 'bench player'}. Tap to ${isSelected ? 'move to bench' : 'make starter'}',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
        elevation:
            isSelected ? AppTheme.cardElevationHigh : AppTheme.cardElevationLow,
        color:
            isSelected
                ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                    .withValues(alpha: 0.1)
                : null,
        child: InkWell(
          onTap: () => _togglePlayerStarter(player.id),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player name and overall rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            player.heightFormatted,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(player.overallRating),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OVR ${player.overallRating}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats grid
                _buildStatsGrid(player),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Player player) {
    final stats = [
      {'label': 'SHT', 'value': player.shooting, 'fullName': 'Shooting'},
      {'label': 'DEF', 'value': player.defense, 'fullName': 'Defense'},
      {'label': 'SPD', 'value': player.speed, 'fullName': 'Speed'},
      {'label': 'STA', 'value': player.stamina, 'fullName': 'Stamina'},
      {'label': 'PAS', 'value': player.passing, 'fullName': 'Passing'},
      {'label': 'REB', 'value': player.rebounding, 'fullName': 'Rebounding'},
      {
        'label': 'BH',
        'value': player.ballHandling,
        'fullName': 'Ball Handling',
      },
      {'label': '3PT', 'value': player.threePoint, 'fullName': 'Three Point'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          stats.map((stat) {
            return Semantics(
              label: '${stat['fullName']}: ${stat['value']}',
              child: SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Text(
                      stat['label'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stat['value']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatColor(stat['value'] as int),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Color _getRatingColor(int rating) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getRatingColor(rating, isDark: isDark);
  }

  Color _getStatColor(int stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getRatingColor(stat, isDark: isDark);
  }
}
