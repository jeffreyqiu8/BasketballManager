import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/season.dart';
import '../models/player_season_stats.dart';
import '../models/player_playoff_stats.dart';
import '../models/rotation_config.dart';
import '../models/depth_chart_entry.dart';
import '../services/league_service.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/star_rating.dart';
import 'player_profile_page.dart';
import 'lineup_page.dart';
import 'minutes_editor_dialog.dart';

/// TeamOverviewPage displays a single team's 15 players with read-only roster view
/// Provides navigation to LineupPage and MinutesEditorDialog for editing
class TeamOverviewPage extends StatefulWidget {
  final String teamId;
  final LeagueService leagueService;
  final Season? season;
  final int initialTab;

  const TeamOverviewPage({
    super.key,
    required this.teamId,
    required this.leagueService,
    this.season,
    this.initialTab = 0,
  });

  @override
  State<TeamOverviewPage> createState() => _TeamOverviewPageState();
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
  all, // All players in one list
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

class _TeamOverviewPageState extends State<TeamOverviewPage>
    with SingleTickerProviderStateMixin {
  late Team _team;
  late TabController _tabController;

  // Season stats sorting
  _SortColumn _sortColumn = _SortColumn.ppg;
  bool _sortAscending = false;

  // Track expanded player cards in season stats
  final Set<String> _expandedPlayerIds = {};

  // Roster organization
  _RosterSortMode _rosterSortMode = _RosterSortMode.all;
  _PositionFilter _positionFilter = _PositionFilter.all;
  _RoleFilter _roleFilter = _RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Team page for ${_team.city} ${_team.name}',
          child: Text('${_team.city} ${_team.name}'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Semantics(
              label: 'Roster tab, view team roster',
              child: const Tab(icon: Icon(Icons.people), text: 'Roster'),
            ),
            Semantics(
              label: 'Season statistics tab, view player season statistics',
              child: const Tab(
                icon: Icon(Icons.bar_chart),
                text: 'Season Stats',
              ),
            ),
            Semantics(
              label: 'Playoff statistics tab, view player playoff statistics',
              child: const Tab(
                icon: Icon(Icons.emoji_events),
                text: 'Playoff Stats',
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRosterTab(),
          _buildSeasonStatsTab(),
          _buildPlayoffStatsTab(),
        ],
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

            // Rotation summary section (read-only with action buttons)
            _buildRotationSummary(),
            const SizedBox(height: 16),

            // Position distribution summary
            _buildPositionDistribution(),
            const SizedBox(height: 16),

            // Roster controls (sort mode and position filter)
            _buildRosterControls(),
            const SizedBox(height: 16),

            // Display roster based on sort mode
            if (_rosterSortMode == _RosterSortMode.all)
              ..._buildLineupView()
            else
              ..._buildPositionView(),
          ],
        ),
      ),
    );
  }

  /// Build rotation summary section (read-only with action buttons)
  Widget _buildRotationSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rotationConfig = _team.rotationConfig;

    // Get rotation info
    String rotationSizeText;
    List<Player> starters = [];
    List<Player> keyRotationPlayers = [];

    if (rotationConfig != null) {
      rotationSizeText = '${rotationConfig.rotationSize}-Player Rotation';
      
      // Get starters from depth chart
      final starterIds = rotationConfig.depthChart
          .where((entry) => entry.depth == 1)
          .map((entry) => entry.playerId)
          .toSet();
      starters = _team.players.where((p) => starterIds.contains(p.id)).toList();
      
      // Get key rotation players (non-starters with most minutes)
      final activePlayerIds = rotationConfig.getActivePlayerIds();
      keyRotationPlayers = _team.players
          .where((p) => activePlayerIds.contains(p.id) && !starterIds.contains(p.id))
          .toList();
      keyRotationPlayers.sort((a, b) {
        final minutesA = rotationConfig.playerMinutes[a.id] ?? 0;
        final minutesB = rotationConfig.playerMinutes[b.id] ?? 0;
        return minutesB.compareTo(minutesA);
      });
      // Take top 3 bench players
      if (keyRotationPlayers.length > 3) {
        keyRotationPlayers = keyRotationPlayers.sublist(0, 3);
      }
    } else {
      rotationSizeText = 'No Rotation Set';
      // Use starting lineup as fallback
      starters = _team.players
          .where((p) => _team.startingLineupIds.contains(p.id))
          .toList();
    }

    return Semantics(
      label: 'Rotation summary: $rotationSizeText. Use Edit Lineup or Edit Minutes buttons to manage rotation.',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with rotation size and action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rotate_right,
                        size: 20,
                        color: isDark
                            ? AppTheme.primaryColorDark
                            : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rotation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Semantics(
                        label: 'Edit lineup button',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToLineupPage,
                          icon: const Icon(Icons.people, size: 16),
                          label: const Text('Edit Lineup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppTheme.primaryColorDark
                                : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'Edit minutes button',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: _openMinutesEditor,
                          icon: const Icon(Icons.timer, size: 16),
                          label: const Text('Edit Minutes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppTheme.primaryColorDark
                                : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rotation size
              Text(
                rotationSizeText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.primaryColorDark
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // Starting lineup
              if (starters.isNotEmpty) ...[
                Text(
                  'Starting Lineup',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: starters.map((player) {
                    final minutes = rotationConfig?.playerMinutes[player.id];
                    return _buildRotationPlayerChip(
                      player,
                      minutes,
                      isStarter: true,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
              ],

              // Key rotation players (bench)
              if (keyRotationPlayers.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Key Rotation Players',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: keyRotationPlayers.map((player) {
                    final minutes = rotationConfig?.playerMinutes[player.id];
                    return _buildRotationPlayerChip(
                      player,
                      minutes,
                      isStarter: false,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a chip for a player in the rotation summary
  Widget _buildRotationPlayerChip(
    Player player,
    int? minutes, {
    required bool isStarter,
    required bool isDark,
  }) {
    return Semantics(
      label: '${player.name}, ${player.position}, ${minutes ?? 0} minutes per game',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
              .withValues(alpha: isStarter ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
            width: isStarter ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStarter)
              Icon(
                Icons.star,
                size: 12,
                color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
              ),
            if (isStarter) const SizedBox(width: 4),
            Text(
              player.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isStarter ? FontWeight.bold : FontWeight.w600,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player.position,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (minutes != null) ...[
              const SizedBox(width: 4),
              Text(
                '${minutes}m',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
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
                        value: _RosterSortMode.all,
                        label: Text('All Players'),
                        icon: Icon(Icons.people, size: 16),
                      ),
                      ButtonSegment(
                        value: _RosterSortMode.position,
                        label: Text('By Position'),
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

  /// Build lineup view (all players in a simple list)
  List<Widget> _buildLineupView() {
    // Apply role filter
    final filteredPlayers = _applyRoleFilter(_team.players);

    return [
      // All Players Section
      Semantics(
        label: 'All players section with ${filteredPlayers.length} players shown',
        child: _buildSectionHeader(
          context,
          'All Players (${filteredPlayers.length})',
          Icons.people,
        ),
      ),
      const SizedBox(height: 8),
      ..._buildPlayerList(filteredPlayers, isStarter: false),
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

      // Position header
      widgets.add(
        Semantics(
          label: '$position section with ${positionPlayers.length} players',
          child: _buildSectionHeader(
            context,
            '$position (${positionPlayers.length})',
            Icons.sports_basketball,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 8));

      // Show all players for this position
      widgets.addAll(_buildPlayerList(positionPlayers, isStarter: false));
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
    final isSelected = _team.startingLineupIds.contains(player.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final starRating = player.getStarRatingRounded(_team.players);
    
    // Get rotation info for this player
    final rotationConfig = _team.rotationConfig;
    final isInRotation = rotationConfig?.playerMinutes[player.id] != null &&
        (rotationConfig?.playerMinutes[player.id] ?? 0) > 0;
    final playerMinutes = rotationConfig?.playerMinutes[player.id];
    final depthChartEntry = rotationConfig?.depthChart
        .firstWhere(
          (entry) => entry.playerId == player.id,
          orElse: () => DepthChartEntry(
            playerId: player.id,
            position: player.position,
            depth: 99,
          ),
        );
    final depthPosition = depthChartEntry?.depth;
    
    return Semantics(
      label:
          '${player.name}, ${player.position} position, $starRating stars, ${isSelected ? 'starter' : 'bench player'}${isInRotation ? ', in rotation with $playerMinutes minutes' : ''}. Tap to view player profile',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation:
            isSelected ? AppTheme.cardElevationHigh : AppTheme.cardElevationLow,
        color:
            isSelected
                ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                    .withValues(alpha: 0.1)
                : null,
        child: InkWell(
          onTap: () => _navigateToPlayerProfile(player),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Left side: Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
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
                          const SizedBox(width: 6),
                          // Role archetype badge
                          if (player.roleArchetypeId != null)
                            _buildRoleBadge(player, isDark),
                          // Rotation badge
                          if (isInRotation) ...[
                            const SizedBox(width: 6),
                            _buildRotationBadge(
                              playerMinutes!,
                              depthPosition!,
                              isDark,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side: Rating and star
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StarRating(
                      rating: starRating,
                      size: 18,
                      showLabel: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OVR ${player.positionAdjustedRating}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build rotation badge showing minutes and depth
  Widget _buildRotationBadge(int minutes, int depth, bool isDark) {
    return Semantics(
      label: 'In rotation: $minutes minutes per game, depth $depth',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.successColorDark : AppTheme.successColor)
              .withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rotate_right,
              size: 10,
              color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
            ),
            const SizedBox(width: 3),
            Text(
              '${minutes}m',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (depth > 1) ...[
              const SizedBox(width: 2),
              Text(
                '(D$depth)',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
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

  Widget _buildPlayoffStatsTab() {
    if (widget.season == null ||
        widget.season!.playoffStats == null ||
        widget.season!.playoffStats!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Semantics(
                label:
                    'No playoff data available. Team has not made the playoffs yet.',
                child: const Text(
                  'No playoff data available.\nTeam has not made the playoffs yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get playoff stats for team players
    final playerStats = <String, PlayerPlayoffStats>{};
    for (var player in _team.players) {
      final stats = widget.season!.getPlayerPlayoffStats(player.id);
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
              Icon(Icons.emoji_events, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Semantics(
                label:
                    'No playoff statistics for team players yet. Play playoff games to see player statistics.',
                child: const Text(
                  'No playoff statistics for team players yet.\nPlay playoff games to see player statistics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort players by selected column (reuse same sorting logic as season stats)
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
              label: 'Playoff statistics for ${_team.city} ${_team.name}',
              child: _buildSectionHeader(
                context,
                'Playoff Statistics',
                Icons.emoji_events,
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
              return _buildPlayerPlayoffStatsCard(player, stats);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPlayoffStatsCard(Player player, PlayerPlayoffStats stats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedPlayerIds.contains(player.id);

    return Semantics(
      label:
          '${player.name}, ${player.position} position, ${stats.pointsPerGame.toStringAsFixed(1)} points per game in playoffs, ${stats.reboundsPerGame.toStringAsFixed(1)} rebounds, ${stats.assistsPerGame.toStringAsFixed(1)} assists. Tap to ${isExpanded ? 'collapse' : 'expand'} details',
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
                            '${stats.gamesPlayed} Playoff Games',
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

  /// Navigate to LineupPage for editing lineup and depth chart
  Future<void> _navigateToLineupPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LineupPage(
          team: _team,
          leagueService: widget.leagueService,
        ),
      ),
    );

    // If changes were saved, reload the team
    if (result == true) {
      _loadTeam();
      if (mounted) {
        AccessibilityUtils.showAccessibleSuccess(
          context,
          'Lineup updated successfully',
        );
      }
    }
  }

  /// Open the minutes editor dialog
  Future<void> _openMinutesEditor() async {
    // Check if team has a rotation config
    if (_team.rotationConfig == null) {
      if (mounted) {
        AccessibilityUtils.showAccessibleInfo(
          context,
          'Please set up a lineup first',
        );
      }
      return;
    }

    final result = await showDialog<RotationConfig>(
      context: context,
      builder: (context) => MinutesEditorDialog(
        team: _team,
        initialConfig: _team.rotationConfig!,
        onSave: (config) {
          Navigator.of(context).pop(config);
        },
      ),
    );

    // If a config was returned, save it
    if (result != null) {
      final updatedTeam = _team.copyWith(
        rotationConfig: result,
      );

      await widget.leagueService.updateTeam(updatedTeam);

      // Refresh the team page
      setState(() {
        _team = updatedTeam;
      });

      // Show success message
      if (mounted) {
        AccessibilityUtils.showAccessibleSuccess(
          context,
          'Minutes updated successfully',
        );
      }
    }
  }
}
