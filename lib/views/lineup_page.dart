import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/rotation_config.dart';
import '../models/depth_chart_entry.dart';
import '../services/rotation_service.dart';
import '../services/league_service.dart';
import '../utils/app_theme.dart';
import '../utils/accessibility_utils.dart';
import 'minutes_editor_dialog.dart';

/// Full-page dedicated interface for managing starting five and depth chart
/// 
/// Provides unified lineup management:
/// - Display current starting five organized by position
/// - Show complete depth chart with reordering
/// - Allow adding/removing players from rotation
/// - Provide visual distinction between starters and bench
/// - Validate lineup configuration in real-time
/// - Navigate to MinutesEditorDialog for time allocation
class LineupPage extends StatefulWidget {
  final Team team;
  final LeagueService leagueService;

  const LineupPage({
    super.key,
    required this.team,
    required this.leagueService,
  });

  @override
  State<LineupPage> createState() => _LineupPageState();
}

class _LineupPageState extends State<LineupPage> {
  late Team _team;
  late List<DepthChartEntry> _depthChart;
  late Map<String, int> _playerMinutes;
  late int _rotationSize;
  List<String> _validationErrors = [];
  bool _hasUnsavedChanges = false;
  
  // Focus nodes for keyboard navigation
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _cancelFocusNode = FocusNode();
  final FocusNode _minutesEditorFocusNode = FocusNode();
  final Map<String, FocusNode> _playerFocusNodes = {};

  @override
  void initState() {
    super.initState();
    _initializeState();
  }
  
  @override
  void dispose() {
    _saveFocusNode.dispose();
    _cancelFocusNode.dispose();
    _minutesEditorFocusNode.dispose();
    for (final node in _playerFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _initializeState() {
    _team = widget.team;
    
    // Initialize from existing rotation config or create default
    if (_team.rotationConfig != null) {
      _depthChart = List<DepthChartEntry>.from(_team.rotationConfig!.depthChart);
      _playerMinutes = Map<String, int>.from(_team.rotationConfig!.playerMinutes);
      _rotationSize = _team.rotationConfig!.rotationSize;
    } else {
      // Generate default 8-player rotation
      final defaultConfig = RotationService.generateDefaultRotation(_team.players);
      _depthChart = List<DepthChartEntry>.from(defaultConfig.depthChart);
      _playerMinutes = Map<String, int>.from(defaultConfig.playerMinutes);
      _rotationSize = defaultConfig.rotationSize;
    }
    
    _validateConfig();
  }

  void _validateConfig() {
    final config = _buildCurrentConfig();
    setState(() {
      _validationErrors = RotationService.validateRotation(config, _team.players);
    });
  }

  RotationConfig _buildCurrentConfig() {
    return RotationConfig(
      rotationSize: _rotationSize,
      playerMinutes: _playerMinutes,
      depthChart: _depthChart,
      lastModified: DateTime.now(),
    );
  }

  Future<bool> _confirmUnsavedChanges() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Discard changes and leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard Changes'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _handleSave() async {
    if (_validationErrors.isNotEmpty) {
      return;
    }

    final config = _buildCurrentConfig();
    
    // Update starting lineup IDs from depth chart
    final startingLineupIds = _depthChart
        .where((entry) => entry.depth == 1)
        .map((entry) => entry.playerId)
        .toList();

    final updatedTeam = _team.copyWith(
      rotationConfig: config,
      startingLineupIds: startingLineupIds,
    );

    await widget.leagueService.updateTeam(updatedTeam);

    setState(() {
      _team = updatedTeam;
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lineup saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Return true to indicate successful save
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await _confirmUnsavedChanges();
    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openMinutesEditor() async {
    final config = _buildCurrentConfig();
    
    await showDialog(
      context: context,
      builder: (context) => MinutesEditorDialog(
        team: _team,
        initialConfig: config,
        onSave: (newConfig) {
          setState(() {
            _playerMinutes = Map<String, int>.from(newConfig.playerMinutes);
            _rotationSize = newConfig.rotationSize;
            _hasUnsavedChanges = true;
            _validateConfig();
          });
        },
      ),
    );
  }

  void _reorderDepthChart(String position, int oldIndex, int newIndex) {
    setState(() {
      // Get all entries for this position
      final positionEntries = _depthChart
          .where((entry) => entry.position == position)
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));

      if (oldIndex >= positionEntries.length || newIndex >= positionEntries.length) {
        return;
      }

      // Remove the entry being moved
      final movedEntry = positionEntries.removeAt(oldIndex);
      final player = _team.players.firstWhere((p) => p.id == movedEntry.playerId);
      
      // Insert at new position
      positionEntries.insert(newIndex, movedEntry);

      // Update depths
      for (int i = 0; i < positionEntries.length; i++) {
        final entry = positionEntries[i];
        final index = _depthChart.indexWhere(
          (e) => e.playerId == entry.playerId && e.position == entry.position,
        );
        if (index != -1) {
          _depthChart[index] = DepthChartEntry(
            playerId: entry.playerId,
            position: entry.position,
            depth: i + 1,
          );
        }
      }

      _hasUnsavedChanges = true;
      _validateConfig();
      
      // Announce to screen readers
      if (mounted) {
        AccessibilityUtils.announce(
          context,
          '${player.name} moved to depth ${newIndex + 1} at $position',
        );
      }
    });
  }

  void _promoteToStarter(String playerId, String position) {
    final player = _team.players.firstWhere((p) => p.id == playerId);
    
    setState(() {
      // Find current starter at this position
      final currentStarterIndex = _depthChart.indexWhere(
        (entry) => entry.position == position && entry.depth == 1,
      );

      // Find the player being promoted
      final promotedPlayerIndex = _depthChart.indexWhere(
        (entry) => entry.playerId == playerId && entry.position == position,
      );

      if (currentStarterIndex == -1 || promotedPlayerIndex == -1) {
        return;
      }

      final currentStarter = _depthChart[currentStarterIndex];
      final promotedPlayer = _depthChart[promotedPlayerIndex];

      // Swap depths
      _depthChart[currentStarterIndex] = DepthChartEntry(
        playerId: currentStarter.playerId,
        position: currentStarter.position,
        depth: promotedPlayer.depth,
      );

      _depthChart[promotedPlayerIndex] = DepthChartEntry(
        playerId: promotedPlayer.playerId,
        position: promotedPlayer.position,
        depth: 1,
      );

      _hasUnsavedChanges = true;
      _validateConfig();
    });
    
    // Announce to screen readers
    if (mounted) {
      AccessibilityUtils.announce(
        context,
        '${player.name} promoted to starter at $position',
      );
    }
  }

  Future<void> _addPlayerToRotation(Player player) async {
    // Show position selector dialog
    final selectedPosition = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${player.name} to Rotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select position:'),
            const SizedBox(height: AppTheme.spacingMedium),
            ...['PG', 'SG', 'SF', 'PF', 'C'].map((position) {
              return Semantics(
                button: true,
                label: 'Add to $position - ${_getPositionName(position)}',
                child: ListTile(
                  title: Text('$position - ${_getPositionName(position)}'),
                  onTap: () => Navigator.of(context).pop(position),
                ),
              );
            }),
          ],
        ),
      ),
    );

    if (selectedPosition == null) return;

    setState(() {
      // Get current depth at this position
      final currentDepth = _depthChart
          .where((entry) => entry.position == selectedPosition)
          .length;

      // Add to depth chart
      _depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: selectedPosition,
        depth: currentDepth + 1,
      ));

      // Add to player minutes (default 0)
      _playerMinutes[player.id] = 0;

      // Increment rotation size
      _rotationSize++;

      _hasUnsavedChanges = true;
      _validateConfig();
    });
    
    // Announce to screen readers
    if (mounted) {
      AccessibilityUtils.announce(
        context,
        '${player.name} added to rotation at $selectedPosition',
      );
    }

    // Open minutes editor to allocate minutes
    await _openMinutesEditor();
  }

  Future<void> _removePlayerFromRotation(String playerId) async {
    final player = _team.players.firstWhere((p) => p.id == playerId);
    
    // Check if player is a starter
    final isStarter = _depthChart.any(
      (entry) => entry.playerId == playerId && entry.depth == 1,
    );

    if (isStarter) {
      // Show error - cannot remove starter without replacement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot remove ${player.name} - they are a starter. Promote another player first.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Confirm removal
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text(
          'Remove ${player.name} from the rotation? Their minutes will be redistributed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      // Remove from depth chart
      final position = _depthChart
          .firstWhere((entry) => entry.playerId == playerId)
          .position;
      
      _depthChart.removeWhere((entry) => entry.playerId == playerId);

      // Reorder depths for this position
      final positionEntries = _depthChart
          .where((entry) => entry.position == position)
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));

      for (int i = 0; i < positionEntries.length; i++) {
        final entry = positionEntries[i];
        final index = _depthChart.indexWhere(
          (e) => e.playerId == entry.playerId && e.position == entry.position,
        );
        if (index != -1) {
          _depthChart[index] = DepthChartEntry(
            playerId: entry.playerId,
            position: entry.position,
            depth: i + 1,
          );
        }
      }

      // Remove from player minutes
      _playerMinutes.remove(playerId);

      // Decrement rotation size
      _rotationSize--;

      _hasUnsavedChanges = true;
      _validateConfig();
    });

    // Open minutes editor to redistribute minutes
    await _openMinutesEditor();
  }

  String _getPositionName(String position) {
    switch (position) {
      case 'PG':
        return 'Point Guard';
      case 'SG':
        return 'Shooting Guard';
      case 'SF':
        return 'Small Forward';
      case 'PF':
        return 'Power Forward';
      case 'C':
        return 'Center';
      default:
        return position;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final confirmed = await _confirmUnsavedChanges();
          if (confirmed && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text('${_team.city} ${_team.name} - Lineup'),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancel lineup changes',
              child: Focus(
                focusNode: _cancelFocusNode,
                child: Builder(
                  builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    return TextButton(
                      onPressed: _handleCancel,
                      style: hasFocus
                          ? TextButton.styleFrom(
                              backgroundColor: (isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.2),
                            )
                          : null,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Semantics(
              button: true,
              label: _validationErrors.isEmpty
                  ? 'Save lineup changes'
                  : 'Save lineup changes, disabled due to validation errors',
              enabled: _validationErrors.isEmpty,
              child: Focus(
                focusNode: _saveFocusNode,
                child: Builder(
                  builder: (context) {
                    final hasFocus = Focus.of(context).hasFocus;
                    return TextButton(
                      onPressed: _validationErrors.isEmpty ? _handleSave : null,
                      style: hasFocus && _validationErrors.isEmpty
                          ? TextButton.styleFrom(
                              backgroundColor: (isDark
                                      ? AppTheme.primaryColorDark
                                      : AppTheme.primaryColor)
                                  .withValues(alpha: 0.3),
                            )
                          : null,
                      child: Text(
                        'Save',
                        style: TextStyle(
                          color: _validationErrors.isEmpty
                              ? (isDark ? AppTheme.primaryColorDark : Colors.white)
                              : (isDark ? AppTheme.textDisabledDark : Colors.white54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Validation feedback banner
              if (_validationErrors.isNotEmpty) ...[
                _buildValidationBanner(isDark),
                const SizedBox(height: AppTheme.spacingMedium),
              ],

              // Starting Five section
              _buildStartingFiveSection(isDark),
              const SizedBox(height: AppTheme.spacingLarge),

              // Depth Chart section
              _buildDepthChartSection(isDark),
              const SizedBox(height: AppTheme.spacingLarge),

              // Available Players section
              _buildAvailablePlayersSection(isDark),
            ],
          ),
        ),
        floatingActionButton: Semantics(
          button: true,
          label: 'Open minutes editor',
          child: Focus(
            focusNode: _minutesEditorFocusNode,
            child: Builder(
              builder: (context) {
                final hasFocus = Focus.of(context).hasFocus;
                return FloatingActionButton.extended(
                  onPressed: _openMinutesEditor,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Edit Minutes'),
                  elevation: hasFocus ? 8 : 6,
                  focusElevation: 12,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationBanner(bool isDark) {
    return Semantics(
      liveRegion: true,
      label: 'Validation errors: ${_validationErrors.length} errors found',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.errorColorDark : AppTheme.errorColor)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error,
                  color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                  semanticLabel: 'Error',
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Text(
                    'Lineup Configuration Errors',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            ..._validationErrors.map((error) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                          color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStartingFiveSection(bool isDark) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    return Semantics(
      label: 'Starting five section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Starting Five',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Your starting lineup for each position',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          // Position cards
          ...positions.map((position) => _buildStarterCard(position, isDark)),
        ],
      ),
    );
  }

  Widget _buildStarterCard(String position, bool isDark) {
    // Find starter for this position
    final starterEntry = _depthChart.firstWhere(
      (entry) => entry.position == position && entry.depth == 1,
      orElse: () => DepthChartEntry(playerId: '', position: position, depth: 1),
    );

    final hasStarter = starterEntry.playerId.isNotEmpty;
    final player = hasStarter
        ? _team.players.firstWhere((p) => p.id == starterEntry.playerId)
        : null;

    return Semantics(
      label: hasStarter && player != null
          ? 'Starter at $position: ${player.name}, rating ${player.positionAdjustedRating}, ${_playerMinutes[player.id] ?? 0} minutes'
          : 'No starter assigned at $position position',
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceColorDark : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: hasStarter
                ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                : (isDark ? AppTheme.errorColorDark : AppTheme.errorColor),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Position badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Column(
                children: [
                  Text(
                    position,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    'STARTER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            // Player info
            Expanded(
              child: hasStarter && player != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Rating: ${player.positionAdjustedRating}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.getRatingColor(
                                  player.positionAdjustedRating,
                                  isDark: isDark,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '•',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '${_playerMinutes[player.id] ?? 0} min',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Text(
                      'No starter assigned',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthChartSection(bool isDark) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    return Semantics(
      label: 'Depth chart section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Depth Chart',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Manage player assignments and substitution order',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          // Position groups
          ...positions.map((position) => _buildDepthChartPositionGroup(position, isDark)),
        ],
      ),
    );
  }

  Widget _buildDepthChartPositionGroup(String position, bool isDark) {
    // Get players assigned to this position, sorted by depth
    final playersAtPosition = _depthChart
        .where((entry) => entry.position == position)
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColorDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                topRight: Radius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    position,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  _getPositionName(position),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Players list
          if (playersAtPosition.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Text(
                'No players assigned to this position',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playersAtPosition.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                _reorderDepthChart(position, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final entry = playersAtPosition[index];
                final player = _team.players.firstWhere((p) => p.id == entry.playerId);
                final isStarter = entry.depth == 1;
                
                return _buildDepthChartPlayerTile(
                  key: ValueKey(entry.playerId),
                  player: player,
                  entry: entry,
                  isStarter: isStarter,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDepthChartPlayerTile({
    required Key key,
    required Player player,
    required DepthChartEntry entry,
    required bool isStarter,
    required bool isDark,
  }) {
    // Get or create focus node for this player
    _playerFocusNodes.putIfAbsent(player.id, () => FocusNode());
    
    return Semantics(
      label: '${isStarter ? "Starter" : "Bench player"}, depth ${entry.depth}, ${player.name}, rating ${player.positionAdjustedRating}, ${_playerMinutes[player.id] ?? 0} minutes',
      container: true,
      child: Focus(
        focusNode: _playerFocusNodes[player.id],
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            
            return Container(
              key: key,
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
                vertical: 4,
              ),
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: isStarter
                    ? (isDark
                        ? AppTheme.primaryColorDark.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.1))
                    : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(
                  color: hasFocus
                      ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                      : (isStarter
                          ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                          : (isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight)),
                  width: hasFocus ? 3 : (isStarter ? 2 : 1),
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Depth indicator
                  Semantics(
                    label: 'Depth ${entry.depth}',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isStarter
                            ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                            : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        shape: BoxShape.circle,
                        border: hasFocus
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.depth}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isStarter
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  // Player info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                player.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isStarter ? FontWeight.bold : FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.textPrimaryDark
                                      : AppTheme.textPrimaryLight,
                                ),
                              ),
                            ),
                            if (isStarter)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'STARTER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Rating: ${player.positionAdjustedRating}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.getRatingColor(
                                  player.positionAdjustedRating,
                                  isDark: isDark,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '•',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              '${_playerMinutes[player.id] ?? 0} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isStarter)
                        Semantics(
                          button: true,
                          label: 'Promote ${player.name} to starter',
                          child: IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 20),
                            onPressed: () => _promoteToStarter(player.id, entry.position),
                            tooltip: 'Promote to starter',
                          ),
                        ),
                      Semantics(
                        button: true,
                        label: 'Remove ${player.name} from rotation',
                        child: IconButton(
                          icon: Icon(
                            Icons.remove_circle,
                            size: 20,
                            color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                          ),
                          onPressed: () => _removePlayerFromRotation(player.id),
                          tooltip: 'Remove from rotation',
                        ),
                      ),
                      // Drag handle
                      Semantics(
                        label: 'Drag to reorder ${player.name}',
                        child: const Icon(Icons.drag_handle, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvailablePlayersSection(bool isDark) {
    // Get players not in rotation
    final playersInRotation = _depthChart.map((e) => e.playerId).toSet();
    final availablePlayers = _team.players
        .where((player) => !playersInRotation.contains(player.id))
        .toList()
      ..sort((a, b) => b.positionAdjustedRating.compareTo(a.positionAdjustedRating));

    if (availablePlayers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Available players section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Available Players',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Players not currently in the rotation',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          // Available players list
          ...availablePlayers.map((player) => _buildAvailablePlayerTile(player, isDark)),
        ],
      ),
    );
  }

  Widget _buildAvailablePlayerTile(Player player, bool isDark) {
    return Semantics(
      label: 'Available player: ${player.name}, position ${player.position}, rating ${player.positionAdjustedRating}',
      container: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceColorDark : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
          ),
        ),
        child: Row(
          children: [
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.position,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        'Rating: ${player.positionAdjustedRating}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getRatingColor(
                            player.positionAdjustedRating,
                            isDark: isDark,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add button
            Semantics(
              button: true,
              label: 'Add ${player.name} to rotation',
              child: ElevatedButton.icon(
                onPressed: () => _addPlayerToRotation(player),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: AppTheme.spacingSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
