import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/season.dart';
import '../models/player_season_stats.dart';
import '../models/role_archetype.dart';
import '../services/league_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../utils/role_archetype_registry.dart';
import '../widgets/star_rating.dart';
import 'player_profile_page.dart';

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

enum _RosterSortMode {
  lineup, // Starters first, then bench
  position, // Sorted by position (PG, SG, SF, PF, C)
}

enum _PositionFilter {
  all,
  pg,
  sg,
  sf,
  pf,
  c,
}

enum _RoleFilter {
  all,
  noRole,
  hasRole,
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

  // Roster organization
  _RosterSortMode _rosterSortMode = _RosterSortMode.lineup;
  _PositionFilter _positionFilter = _PositionFilter.all;
  _RoleFilter _roleFilter = _RoleFilter.all;

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
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                
                return Semantics(
                  label: 'Team overall rating: ${_team.teamRating}',
                  child: Card(
                    elevation: AppTheme.cardElevationMedium,
                    child: Padding(
                      padding: AppTheme.cardPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Team Overall',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${_team.teamRating}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Position distribution summary
            _buildPositionDistribution(),
            const SizedBox(height: 16),

            // Roster controls (sort mode and position filter)
            _buildRosterControls(),
            const SizedBox(height: 16),

            // Display roster based on sort mode
            if (_rosterSortMode == _RosterSortMode.lineup)
              ..._buildLineupView()
            else
              ..._buildPositionView(),
          ],
        ),
      ),
    );
  }

  /// Build position distribution summary
  Widget _buildPositionDistribution() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Count players by position
    final positionCounts = <String, int>{
      'PG': 0,
      'SG': 0,
      'SF': 0,
      'PF': 0,
      'C': 0,
    };
    
    for (var player in _team.players) {
      positionCounts[player.position] = (positionCounts[player.position] ?? 0) + 1;
    }

    return Semantics(
      label:
          'Position distribution: ${positionCounts['PG']} Point Guards, ${positionCounts['SG']} Shooting Guards, ${positionCounts['SF']} Small Forwards, ${positionCounts['PF']} Power Forwards, ${positionCounts['C']} Centers',
      child: Card(
        elevation: AppTheme.cardElevationLow,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    size: 18,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Position Distribution',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: positionCounts.entries.map((entry) {
                  return Semantics(
                    label: '${entry.value} ${entry.key}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryColorDark
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppTheme.primaryColorDark
                              : AppTheme.primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build roster controls (sort mode and position filter)
  Widget _buildRosterControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: AppTheme.cardElevationLow,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Sort mode selector
            Row(
              children: [
                Icon(
                  Icons.sort,
                  size: 20,
                  color: isDark
                      ? AppTheme.primaryColorDark
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<_RosterSortMode>(
                    segments: const [
                      ButtonSegment(
                        value: _RosterSortMode.lineup,
                        label: Text('Lineup'),
                        icon: Icon(Icons.star, size: 16),
                      ),
                      ButtonSegment(
                        value: _RosterSortMode.position,
                        label: Text('Position'),
                        icon: Icon(Icons.sports_basketball, size: 16),
                      ),
                    ],
                    selected: {_rosterSortMode},
                    onSelectionChanged: (Set<_RosterSortMode> newSelection) {
                      setState(() {
                        _rosterSortMode = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            // Position filter (only show when in position mode)
            if (_rosterSortMode == _RosterSortMode.position) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip('All', _PositionFilter.all),
                        _buildFilterChip('PG', _PositionFilter.pg),
                        _buildFilterChip('SG', _PositionFilter.sg),
                        _buildFilterChip('SF', _PositionFilter.sf),
                        _buildFilterChip('PF', _PositionFilter.pf),
                        _buildFilterChip('C', _PositionFilter.c),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            
            // Role filter
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  size: 20,
                  color: isDark
                      ? AppTheme.primaryColorDark
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRoleFilterChip('All Roles', _RoleFilter.all),
                      _buildRoleFilterChip('No Role', _RoleFilter.noRole),
                      _buildRoleFilterChip('Has Role', _RoleFilter.hasRole),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, _PositionFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _positionFilter == filter;

    return Semantics(
      label: 'Filter by $label${isSelected ? ', selected' : ''}',
      button: true,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _positionFilter = filter;
          });
        },
        selectedColor: (isDark
                ? AppTheme.primaryColorDark
                : AppTheme.primaryColor)
            .withValues(alpha: 0.3),
        checkmarkColor: isDark
            ? AppTheme.primaryColorDark
            : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, _RoleFilter filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _roleFilter == filter;

    return Semantics(
      label: 'Filter by $label${isSelected ? ', selected' : ''}',
      button: true,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _roleFilter = filter;
          });
        },
        selectedColor: (isDark
                ? AppTheme.primaryColorDark
                : AppTheme.primaryColor)
            .withValues(alpha: 0.3),
        checkmarkColor: isDark
            ? AppTheme.primaryColorDark
            : AppTheme.primaryColor,
      ),
    );
  }

  /// Build lineup view (starters and bench)
  List<Widget> _buildLineupView() {
    // Apply role filter
    final filteredPlayers = _applyRoleFilter(_team.players);
    
    final starters = filteredPlayers
        .where((p) => _selectedStarterIds.contains(p.id))
        .toList();
    final bench = filteredPlayers
        .where((p) => !_selectedStarterIds.contains(p.id))
        .toList();

    return [
      // Starting Lineup Section
      Semantics(
        label:
            'Starting lineup section with ${starters.length} players shown',
        child: _buildSectionHeader(
          context,
          'Starting Lineup (${starters.length})',
          Icons.star,
        ),
      ),
      const SizedBox(height: 8),
      ..._buildPlayerList(starters, isStarter: true),
      const SizedBox(height: 24),

      // Bench Section
      Semantics(
        label:
            'Bench section with ${bench.length} players shown',
        child: _buildSectionHeader(
          context,
          'Bench (${bench.length})',
          Icons.event_seat,
        ),
      ),
      const SizedBox(height: 8),
      ..._buildPlayerList(bench, isStarter: false),
    ];
  }

  /// Build position view (sorted by position)
  List<Widget> _buildPositionView() {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    final widgets = <Widget>[];

    for (var position in positions) {
      // Skip if filtering and not the selected position
      if (_positionFilter != _PositionFilter.all &&
          _positionFilter.toString().split('.').last.toUpperCase() !=
              position) {
        continue;
      }

      // Apply role filter
      final positionPlayers = _applyRoleFilter(
        _team.players.where((p) => p.position == position).toList(),
      );

      if (positionPlayers.isEmpty) continue;

      // Separate starters and bench for this position
      final starters = positionPlayers
          .where((p) => _selectedStarterIds.contains(p.id))
          .toList();
      final bench = positionPlayers
          .where((p) => !_selectedStarterIds.contains(p.id))
          .toList();

      // Position header
      widgets.add(
        Semantics(
          label:
              '$position section with ${positionPlayers.length} players, ${starters.length} starters',
          child: _buildSectionHeader(
            context,
            '$position (${positionPlayers.length})',
            Icons.sports_basketball,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));

      // Show starters first, then bench
      widgets.addAll(_buildPlayerList(starters, isStarter: true));
      widgets.addAll(_buildPlayerList(bench, isStarter: false));
      widgets.add(const SizedBox(height: 24));
    }

    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No players found for selected filters',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Apply role filter to a list of players
  List<Player> _applyRoleFilter(List<Player> players) {
    switch (_roleFilter) {
      case _RoleFilter.all:
        return players;
      case _RoleFilter.noRole:
        return players.where((p) => p.roleArchetypeId == null).toList();
      case _RoleFilter.hasRole:
        return players.where((p) => p.roleArchetypeId != null).toList();
    }
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
          '${player.name}, ${player.position} position, ${stats.pointsPerGame.toStringAsFixed(1)} points per game, ${stats.reboundsPerGame.toStringAsFixed(1)} rebounds, ${stats.assistsPerGame.toStringAsFixed(1)} assists. Tap to ${isExpanded ? 'collapse' : 'expand'} details',
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
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _navigateToPlayerProfile(player),
                                child: Text(
                                  player.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        color: isDark
                                            ? AppTheme.primaryColorDark
                                            : AppTheme.primaryColor,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Position badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  player.position,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Role archetype badge
                              if (player.roleArchetypeId != null)
                                _buildRoleBadge(player, isDark),
                            ],
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

    final starRating = player.getStarRatingRounded(_team.players);
    
    return Semantics(
      label:
          '${player.name}, ${player.position} position, ${player.heightFormatted}, $starRating stars, ${isSelected ? 'starter' : 'bench player'}. Tap to ${isSelected ? 'move to bench' : 'make starter'}',
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
                // Player name, position, and overall rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _navigateToPlayerProfile(player),
                            child: Text(
                              player.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: isDark
                                        ? AppTheme.primaryColorDark
                                        : AppTheme.primaryColor,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Position badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  player.position,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Role archetype badge
                              if (player.roleArchetypeId != null)
                                _buildRoleBadge(player, isDark),
                              Text(
                                player.heightFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StarRating(
                          rating: starRating,
                          size: 20,
                          showLabel: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'OVR ${player.positionAdjustedRating}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats grid
                _buildStatsGrid(player),
                
                const SizedBox(height: 12),
                
                // Position assignment section
                _buildPositionAssignment(player),
                
                const SizedBox(height: 12),
                
                // Role selector section
                _buildRoleSelector(player),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Player player) {
    final currentRole = player.getRoleArchetype();
    final topAttributes = currentRole != null ? _getTopAttributes(currentRole).toSet() : <String>{};
    
    final stats = [
      {'label': 'SHT', 'value': player.shooting, 'fullName': 'Shooting', 'key': 'shooting'},
      {'label': 'DEF', 'value': player.defense, 'fullName': 'Defense', 'key': 'defense'},
      {'label': 'SPD', 'value': player.speed, 'fullName': 'Speed', 'key': 'speed'},
      {'label': 'POST', 'value': player.postShooting, 'fullName': 'Post Shooting', 'key': 'postShooting'},
      {'label': 'PAS', 'value': player.passing, 'fullName': 'Passing', 'key': 'passing'},
      {'label': 'REB', 'value': player.rebounding, 'fullName': 'Rebounding', 'key': 'rebounding'},
      {
        'label': 'BH',
        'value': player.ballHandling,
        'fullName': 'Ball Handling',
        'key': 'ballHandling',
      },
      {'label': '3PT', 'value': player.threePoint, 'fullName': 'Three Point', 'key': 'threePoint'},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          stats.map((stat) {
            final isKeyAttribute = topAttributes.contains(stat['key']);
            return Semantics(
              label: '${stat['fullName']}: ${stat['value']}${isKeyAttribute ? ', key attribute for role' : ''}',
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
                    Container(
                      padding: isKeyAttribute 
                          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                          : null,
                      decoration: isKeyAttribute
                          ? BoxDecoration(
                              color: (isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? AppTheme.primaryColorDark
                                    : AppTheme.primaryColor,
                                width: 2,
                              ),
                            )
                          : null,
                      child: Text(
                        '${stat['value']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isKeyAttribute
                              ? (isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor)
                              : _getStatColor(stat['value'] as int),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Color _getStatColor(int stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getRatingColor(stat, isDark: isDark);
  }

  /// Build position assignment UI with affinity visualization and selector
  Widget _buildPositionAssignment(Player player) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final affinities = player.getPositionAffinities();
    
    // Find best-fit position
    final bestPosition = affinities.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with position selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Position',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            // Position selector dropdown
            Semantics(
              label:
                  'Change position for ${player.name}. Current position: ${player.position}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: player.position,
                  underline: Container(),
                  isDense: true,
                  items: ['PG', 'SG', 'SF', 'PF', 'C'].map((pos) {
                    final affinity = affinities[pos]!;
                    final isBestFit = pos == bestPosition;
                    return DropdownMenuItem(
                      value: pos,
                      child: Semantics(
                        label:
                            '$pos, ${affinity.toStringAsFixed(0)}% fit${isBestFit ? ', best fit position' : ''}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pos,
                              style: TextStyle(
                                fontWeight: isBestFit
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (isBestFit)
                              Icon(
                                Icons.star,
                                size: 14,
                                color: isDark
                                    ? AppTheme.successColorDark
                                    : AppTheme.successColor,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              '${affinity.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getAffinityColor(affinity, isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newPosition) {
                    if (newPosition != null && newPosition != player.position) {
                      _updatePlayerPosition(player, newPosition);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Position affinity bars
        Semantics(
          label:
              'Position affinities for ${player.name}. Best fit: $bestPosition at ${affinities[bestPosition]!.toStringAsFixed(0)}%',
          child: Column(
            children: affinities.entries.map((entry) {
              final position = entry.key;
              final affinity = entry.value;
              final isBestFit = position == bestPosition;
              final isCurrentPosition = position == player.position;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Semantics(
                  label:
                      '$position: ${affinity.toStringAsFixed(0)}% affinity${isBestFit ? ', best fit' : ''}${isCurrentPosition ? ', current position' : ''}',
                  child: Row(
                    children: [
                      // Position label
                      SizedBox(
                        width: isBestFit ? 40 : 28,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              position,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrentPosition
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentPosition
                                    ? (isDark
                                        ? AppTheme.primaryColorDark
                                        : AppTheme.primaryColor)
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            if (isBestFit) ...[
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star,
                                size: 12,
                                color: isDark
                                    ? AppTheme.successColorDark
                                    : AppTheme.successColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Progress bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: affinity / 100,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getAffinityColor(affinity, isDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Percentage
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${affinity.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isBestFit
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _getAffinityColor(affinity, isDark),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Get color for affinity level
  /// Green for 80+, yellow for 60-79, red for <60
  Color _getAffinityColor(double affinity, bool isDark) {
    if (affinity >= 80) {
      return isDark ? AppTheme.successColorDark : AppTheme.successColor;
    } else if (affinity >= 60) {
      return isDark ? Colors.amber[300]! : Colors.amber[700]!;
    } else {
      return isDark ? AppTheme.errorColorDark : AppTheme.errorColor;
    }
  }

  /// Build role archetype badge with abbreviated name
  Widget _buildRoleBadge(Player player, bool isDark) {
    final role = player.getRoleArchetype();
    if (role == null) return const SizedBox.shrink();

    // Abbreviate role name if too long
    final displayName = _abbreviateRoleName(role.name);
    final fitScores = player.getRoleFitScores();
    final fitScore = fitScores[role.id] ?? 0.0;

    return Semantics(
      label: 'Role: ${role.name}, ${fitScore.toStringAsFixed(0)}% fit',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: _getRoleFitColor(fitScore, isDark).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getRoleFitColor(fitScore, isDark),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.work_outline,
              size: 10,
              color: _getRoleFitColor(fitScore, isDark),
            ),
            const SizedBox(width: 3),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 10,
                color: _getRoleFitColor(fitScore, isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abbreviate role name for compact display
  String _abbreviateRoleName(String roleName) {
    // Map of full names to abbreviations
    final abbreviations = {
      'All-Around PG': 'All-Around',
      'Floor General': 'Floor Gen',
      'Slashing Playmaker': 'Slasher',
      'Offensive Point': 'Off Point',
      'Three-Level Scorer': '3-Level',
      '3-and-D': '3&D',
      'Microwave Shooter': 'Microwave',
      'Point Forward': 'Point Fwd',
      '3-and-D Wing': '3&D Wing',
      'Athletic Finisher': 'Athletic',
      'Playmaking Big': 'Playmaker',
      'Stretch Four': 'Stretch 4',
      'Rim Runner': 'Rim Run',
      'Paint Beast': 'Paint',
      'Stretch Five': 'Stretch 5',
      'Standard Center': 'Standard',
    };

    return abbreviations[roleName] ?? roleName;
  }

  /// Update player position and save changes
  Future<void> _updatePlayerPosition(Player player, String newPosition) async {
    // Create updated player with new position
    final updatedPlayer = player.copyWithPosition(newPosition);

    // Update player in team's player list
    final updatedPlayers = _team.players.map((p) {
      return p.id == player.id ? updatedPlayer : p;
    }).toList();

    // Create updated team
    final updatedTeam = _team.copyWith(players: updatedPlayers);

    // Save to league service
    await widget.leagueService.updateTeam(updatedTeam);

    // Update local state
    setState(() {
      _team = updatedTeam;
    });

    if (mounted) {
      AccessibilityUtils.showAccessibleSuccess(
        context,
        '${player.name} position changed to $newPosition',
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Navigate to player profile page
  void _navigateToPlayerProfile(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerProfilePage(
          player: player,
          teamPlayers: _team.players,
          season: widget.season,
          leagueService: widget.leagueService,
          teamId: _team.id,
        ),
      ),
    );
  }

  /// Build role selector widget that displays current role and dropdown
  Widget _buildRoleSelector(Player player) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final archetypes = RoleArchetypeRegistry.getArchetypesForPosition(player.position);
    final fitScores = player.getRoleFitScores();
    final currentRole = player.getRoleArchetype();

    // If no archetypes available for position, don't show selector
    if (archetypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with role selector dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            // Role selector dropdown
            Semantics(
              label:
                  'Change role for ${player.name}. Current role: ${currentRole?.name ?? "None"}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String?>(
                  value: player.roleArchetypeId,
                  underline: Container(),
                  isDense: true,
                  hint: Text(
                    'Select Role',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  items: [
                    // Option to clear role
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Semantics(
                        label: 'No role assigned',
                        child: Text(
                          'None',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // All available archetypes for this position
                    ...archetypes.map((archetype) {
                      final fitScore = fitScores[archetype.id] ?? 0.0;
                      return DropdownMenuItem<String?>(
                        value: archetype.id,
                        child: Semantics(
                          label:
                              '${archetype.name}, ${fitScore.toStringAsFixed(0)}% fit',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Role name
                              Flexible(
                                child: Text(
                                  archetype.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Fit indicator
                              _buildFitIndicator(fitScore, isDark),
                              const SizedBox(width: 4),
                              // Fit percentage
                              Text(
                                '${fitScore.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getRoleFitColor(fitScore, isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (newRoleId) {
                    if (newRoleId != player.roleArchetypeId) {
                      _updatePlayerRole(player, newRoleId);
                    }
                  },
                ),
              ),
            ),
          ],
        ),


      ],
    );
  }

  /// Build fit indicator widget with color coding
  /// Green for 80+, yellow for 60-79, red for <60
  Widget _buildFitIndicator(double fitScore, bool isDark) {
    final color = _getRoleFitColor(fitScore, isDark);
    return Container(
      width: 32,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  /// Get color for role fit score
  /// Green for 80+, yellow for 60-79, red for <60
  Color _getRoleFitColor(double fitScore, bool isDark) {
    if (fitScore >= 80) {
      return isDark ? AppTheme.successColorDark : AppTheme.successColor;
    } else if (fitScore >= 60) {
      return isDark ? Colors.amber[300]! : Colors.amber[700]!;
    } else {
      return isDark ? AppTheme.errorColorDark : AppTheme.errorColor;
    }
  }

  /// Get top 3 attributes for a role archetype
  List<String> _getTopAttributes(RoleArchetype role) {
    final sortedAttributes = role.attributeWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedAttributes.take(3).map((e) => e.key).toList();
  }

  /// Format attribute name for display
  String _formatAttributeName(String attribute) {
    switch (attribute) {
      case 'shooting':
        return 'Shooting';
      case 'threePoint':
        return '3PT';
      case 'passing':
        return 'Passing';
      case 'ballHandling':
        return 'Ball Handling';
      case 'postShooting':
        return 'Post';
      case 'defense':
        return 'Defense';
      case 'steals':
        return 'Steals';
      case 'blocks':
        return 'Blocks';
      case 'rebounding':
        return 'Rebounding';
      case 'speed':
        return 'Speed';
      case 'stamina':
        return 'Stamina';
      default:
        return attribute;
    }
  }

  /// Update player role and save changes
  Future<void> _updatePlayerRole(Player player, String? newRoleId) async {
    // Create updated player with new role
    final updatedPlayer = player.copyWithRoleArchetype(newRoleId);

    // Update player in team's player list
    final updatedPlayers = _team.players.map((p) {
      return p.id == player.id ? updatedPlayer : p;
    }).toList();

    // Create updated team
    final updatedTeam = _team.copyWith(players: updatedPlayers);

    // Save to league service
    await widget.leagueService.updateTeam(updatedTeam);

    // Update local state
    setState(() {
      _team = updatedTeam;
    });

    if (mounted) {
      final roleName = newRoleId != null
          ? RoleArchetypeRegistry.getArchetypeById(newRoleId)?.name ?? 'Unknown'
          : 'None';
      AccessibilityUtils.showAccessibleSuccess(
        context,
        '${player.name} role changed to $roleName',
        duration: const Duration(seconds: 2),
      );
    }
  }
}
