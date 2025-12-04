import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/rotation_config.dart';
import '../models/depth_chart_entry.dart';
import '../services/rotation_service.dart';
import '../utils/app_theme.dart';

/// Dialog for editing player minutes allocation
/// 
/// Provides a focused interface for adjusting playing time distribution:
/// - Read-only depth chart display
/// - Minutes allocation per player with sliders
/// - Preset selector for rotation sizes 6-10
/// - Real-time validation feedback
/// - Minutes remaining indicators per position
class MinutesEditorDialog extends StatefulWidget {
  final Team team;
  final RotationConfig initialConfig;
  final Function(RotationConfig) onSave;

  const MinutesEditorDialog({
    super.key,
    required this.team,
    required this.initialConfig,
    required this.onSave,
  });

  @override
  State<MinutesEditorDialog> createState() => _MinutesEditorDialogState();
}

class _MinutesEditorDialogState extends State<MinutesEditorDialog> {
  late int _rotationSize;
  late Map<String, int> _playerMinutes;
  late List<DepthChartEntry> _depthChart; // Read-only
  List<String> _validationErrors = [];
  final FocusNode _dialogFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  @override
  void dispose() {
    _dialogFocusNode.dispose();
    super.dispose();
  }

  void _initializeConfig() {
    _rotationSize = widget.initialConfig.rotationSize;
    _playerMinutes = Map<String, int>.from(widget.initialConfig.playerMinutes);
    _depthChart = List<DepthChartEntry>.from(widget.initialConfig.depthChart);
    _validateConfig();
  }

  void _validateConfig() {
    final config = _buildCurrentConfig();
    setState(() {
      _validationErrors = RotationService.validateRotation(config, widget.team.players);
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

  Future<void> _handleSave() async {
    if (_validationErrors.isNotEmpty) {
      return;
    }

    final config = _buildCurrentConfig();
    widget.onSave(config);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _applyPreset(int newSize) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Preset?'),
        content: Text(
          'Apply the $newSize-player preset? This will reset all minute allocations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apply Preset'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Apply new preset
    final newPreset = RotationService.generatePreset(newSize, widget.team.players);
    
    setState(() {
      _rotationSize = newSize;
      _playerMinutes = Map<String, int>.from(newPreset.playerMinutes);
      // Keep the existing depth chart (read-only)
      _validateConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      child: Focus(
        focusNode: _dialogFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            // Handle Enter key to save
            if (event.logicalKey.keyLabel == 'Enter' && _validationErrors.isEmpty) {
              _handleSave();
              return KeyEventResult.handled;
            }
            // Handle Escape key to cancel
            if (event.logicalKey.keyLabel == 'Escape') {
              _handleCancel();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Semantics(
          label: 'Minutes editor dialog',
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rotation size display and preset selector
                        _buildPresetSelector(isDark),
                        const SizedBox(height: AppTheme.spacingLarge),

                        // Read-only depth chart display
                        _buildReadOnlyDepthChart(isDark),
                        const SizedBox(height: AppTheme.spacingLarge),

                        // Minutes allocation
                        _buildMinutesAllocation(isDark),
                        const SizedBox(height: AppTheme.spacingLarge),

                        // Validation feedback
                        _buildValidationFeedback(isDark),
                      ],
                    ),
                  ),
                ),

                // Footer with action buttons
                _buildFooter(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColorDark : AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusMedium),
          topRight: Radius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: isDark ? AppTheme.primaryColorDark : Colors.white,
            size: 28,
            semanticLabel: 'Minutes icon',
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Edit Minutes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimaryDark : Colors.white,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Close minutes editor',
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: isDark ? AppTheme.textPrimaryDark : Colors.white,
              ),
              onPressed: _handleCancel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector(bool isDark) {
    return Semantics(
      label: 'Preset selector section',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Rotation Size & Presets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Current rotation: $_rotationSize players. Apply a preset to quickly set standard minute allocations.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          // Preset buttons for rotation sizes 6-10
          Semantics(
            label: 'Preset selection buttons',
            child: Wrap(
              spacing: AppTheme.spacingSmall,
              runSpacing: AppTheme.spacingSmall,
              children: [
                for (int size = 6; size <= 10; size++)
                  ElevatedButton(
                    onPressed: () => _applyPreset(size),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: size == _rotationSize
                          ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                          : null,
                    ),
                    child: Text('$size-Player Preset'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyDepthChart(bool isDark) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Current Depth Chart (Read-Only)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'This shows your current lineup and depth chart. To change player assignments, use the Lineup Page.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        // Position groups (read-only)
        ...positions.map((position) => _buildReadOnlyPositionGroup(position, isDark)),
      ],
    );
  }

  Widget _buildReadOnlyPositionGroup(String position, bool isDark) {
    // Get players assigned to this position, sorted by depth
    final playersAtPosition = _depthChart
        .where((entry) => entry.position == position)
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColorDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
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
          Expanded(
            child: Text(
              playersAtPosition.isEmpty
                  ? 'No players assigned'
                  : playersAtPosition.map((entry) {
                      final player = widget.team.players.firstWhere(
                        (p) => p.id == entry.playerId,
                      );
                      return '${entry.depth}. ${player.name}';
                    }).join(' → '),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesAllocation(bool isDark) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Minutes Allocation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          'Adjust playing time for each player (0-48 minutes per game)',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        // Position-based minutes allocation
        ...positions.map((position) => _buildPositionMinutesGroup(position, isDark)),
      ],
    );
  }

  Widget _buildPositionMinutesGroup(String position, bool isDark) {
    final playersAtPosition = _depthChart
        .where((entry) => entry.position == position)
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    final totalMinutes = playersAtPosition.fold<int>(
      0,
      (sum, entry) => sum + (_playerMinutes[entry.playerId] ?? 0),
    );
    
    final isValid = totalMinutes == 48;
    final remainingMinutes = 48 - totalMinutes;
    final statusLabel = isValid 
        ? '$position position has valid minutes allocation: $totalMinutes of 48 minutes'
        : '$position position has invalid minutes allocation: $totalMinutes of 48 minutes, ${remainingMinutes > 0 ? "need $remainingMinutes more" : "exceeded by ${-remainingMinutes}"}';

    return Semantics(
      label: statusLabel,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceColorDark : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: isValid
                ? (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                : (isDark ? AppTheme.errorColorDark : AppTheme.errorColor),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isValid
                        ? (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                        : (isDark ? AppTheme.errorColorDark : AppTheme.errorColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$totalMinutes / 48 min',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (!isValid) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Semantics(
                liveRegion: true,
                child: Text(
                  remainingMinutes > 0
                      ? 'Need $remainingMinutes more minutes'
                      : 'Exceeded by ${-remainingMinutes} minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingMedium),
            // Player minutes controls
            if (playersAtPosition.isEmpty)
              Text(
                'No players assigned to this position',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...playersAtPosition.map((entry) {
                final player = widget.team.players.firstWhere(
                  (p) => p.id == entry.playerId,
                );
                final minutes = _playerMinutes[entry.playerId] ?? 0;
                return _buildPlayerMinutesControl(player, minutes, isDark);
              }),
          ],
        ),
      ),
    );
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

  Widget _buildPlayerMinutesControl(Player player, int minutes, bool isDark) {
    final percentage = (minutes / 48 * 100).toStringAsFixed(1);
    
    return MergeSemantics(
      child: Semantics(
        label: '${player.name} minutes allocation',
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          padding: const EdgeInsets.all(AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Semantics(
                    label: '$minutes minutes, $percentage percent of game time',
                    child: Text(
                      '$minutes min ($percentage%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Minutes slider for ${player.name}, currently $minutes minutes',
                      value: '$minutes minutes',
                      child: Slider(
                        value: minutes.toDouble(),
                        min: 0,
                        max: 48,
                        divisions: 48,
                        label: '$minutes',
                        onChanged: (value) {
                          setState(() {
                            _playerMinutes[player.id] = value.round();
                            _validateConfig();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  SizedBox(
                    width: 60,
                    child: Semantics(
                      label: 'Minutes text input for ${player.name}',
                      textField: true,
                      child: TextField(
                        controller: TextEditingController(text: minutes.toString()),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final newMinutes = int.tryParse(value);
                          if (newMinutes != null && newMinutes >= 0 && newMinutes <= 48) {
                            setState(() {
                              _playerMinutes[player.id] = newMinutes;
                              _validateConfig();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationFeedback(bool isDark) {
    if (_validationErrors.isEmpty) {
      return Semantics(
        liveRegion: true,
        label: 'Validation status: Minutes configuration is valid',
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.successColorDark.withOpacity(0.2)
                : AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(
              color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                semanticLabel: 'Success',
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: Text(
                  'Minutes configuration is valid',
                  style: TextStyle(
                    color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Semantics(
      liveRegion: true,
      label: 'Validation errors: ${_validationErrors.length} errors found',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Validation Errors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.errorColorDark.withOpacity(0.2)
                  : AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _validationErrors.asMap().entries.map((entry) {
                final index = entry.key;
                final error = entry.value;
                return Semantics(
                  label: 'Error ${index + 1}: $error',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error,
                          size: 20,
                          color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                          semanticLabel: 'Error icon',
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
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
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColorDark : AppTheme.surfaceColorLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            button: true,
            label: 'Cancel minutes changes',
            child: OutlinedButton(
              onPressed: _handleCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Semantics(
            button: true,
            label: _validationErrors.isEmpty 
                ? 'Save minutes configuration'
                : 'Save minutes configuration, disabled due to validation errors',
            enabled: _validationErrors.isEmpty,
            child: ElevatedButton(
              onPressed: _validationErrors.isEmpty ? _handleSave : null,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
