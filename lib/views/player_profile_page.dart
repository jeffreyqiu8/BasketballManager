import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/player_season_stats.dart';
import '../models/player_game_stats.dart';
import '../models/season.dart';
import '../models/role_archetype.dart';
import '../utils/app_theme.dart';
import '../utils/role_archetype_registry.dart';
import '../utils/accessibility_utils.dart';
import '../widgets/star_rating.dart';
import '../services/league_service.dart';

/// Player profile page with detailed statistics and information
/// Displays comprehensive player data including attributes, position affinities, and statistics
class PlayerProfilePage extends StatefulWidget {
  final Player player;
  final List<Player> teamPlayers;
  final Season? season;
  final LeagueService? leagueService;
  final String? teamId;

  const PlayerProfilePage({
    super.key,
    required this.player,
    required this.teamPlayers,
    this.season,
    this.leagueService,
    this.teamId,
  });

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  late Player _player;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seasonStats = widget.season?.getPlayerStats(_player.id);
    final starRating = _player.getStarRatingRounded(widget.teamPlayers);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Player profile for ${_player.name}',
          child: Text(_player.name),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player header
            _buildPlayerHeader(context, isDark, starRating),
            const SizedBox(height: 24),

            // Player attributes
            _buildAttributesSection(context, isDark),
            const SizedBox(height: 24),

            // Position affinities
            _buildPositionAffinitiesSection(context, isDark),
            const SizedBox(height: 24),

            // Role fit analysis
            _buildRoleFitSection(context, isDark),
            const SizedBox(height: 24),

            // Season statistics
            if (seasonStats != null) ...[
              _buildSeasonStatsSection(context, isDark, seasonStats),
              const SizedBox(height: 24),
            ],

            // Recent game logs
            if (widget.season != null) _buildRecentGameLogs(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context, bool isDark, double starRating) {
    return Semantics(
      label: '${_player.name}, ${_player.position} position, ${_player.heightFormatted}, overall rating ${_player.positionAdjustedRating}, $starRating stars',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _player.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.primaryColorDark
                                    : AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _player.position,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _player.heightFormatted,
                              style: const TextStyle(
                                fontSize: 16,
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
                        size: 24,
                        showLabel: true,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.infoColorDark
                                  : AppTheme.infoColor)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OVR ${_player.positionAdjustedRating}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.infoColorDark
                                : AppTheme.infoColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributesSection(BuildContext context, bool isDark) {
    final currentRole = _player.getRoleArchetype();
    final topAttributes = currentRole != null ? _getTopAttributes(currentRole, 3).toSet() : <String>{};
    
    final attributes = [
      {'name': 'Shooting', 'value': _player.shooting, 'key': 'shooting'},
      {'name': 'Defense', 'value': _player.defense, 'key': 'defense'},
      {'name': 'Speed', 'value': _player.speed, 'key': 'speed'},
      {'name': 'Post Shooting', 'value': _player.postShooting, 'key': 'postShooting'},
      {'name': 'Passing', 'value': _player.passing, 'key': 'passing'},
      {'name': 'Rebounding', 'value': _player.rebounding, 'key': 'rebounding'},
      {'name': 'Ball Handling', 'value': _player.ballHandling, 'key': 'ballHandling'},
      {'name': 'Three Point', 'value': _player.threePoint, 'key': 'threePoint'},
      {'name': 'Blocks', 'value': _player.blocks, 'key': 'blocks'},
      {'name': 'Steals', 'value': _player.steals, 'key': 'steals'},
    ];

    return Semantics(
      label: 'Player attributes section',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Attributes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...attributes.map((attr) => _buildAttributeBar(
                    attr['name'] as String,
                    attr['value'] as int,
                    isDark,
                    isKeyAttribute: topAttributes.contains(attr['key']),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeBar(String name, int value, bool isDark, {bool isKeyAttribute = false}) {
    final color = isKeyAttribute 
        ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
        : AppTheme.getRatingColor(value, isDark: isDark);

    return Semantics(
      label: '$name: $value out of 100${isKeyAttribute ? ', key attribute for role' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isKeyAttribute ? FontWeight.bold : FontWeight.w500,
                        color: isKeyAttribute ? color : null,
                      ),
                    ),
                    if (isKeyAttribute) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: color,
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: isKeyAttribute 
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : null,
                  decoration: isKeyAttribute
                      ? BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                        )
                      : null,
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 12,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionAffinitiesSection(BuildContext context, bool isDark) {
    final affinities = _player.getPositionAffinities();
    final bestPosition = affinities.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return Semantics(
      label: 'Position affinities section. Best fit: $bestPosition',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_basketball,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Position Affinities',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...affinities.entries.map((entry) {
                final isBestFit = entry.key == bestPosition;
                final isCurrentPosition = entry.key == _player.position;
                return _buildAffinityBar(
                  entry.key,
                  entry.value,
                  isDark,
                  isBestFit: isBestFit,
                  isCurrentPosition: isCurrentPosition,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffinityBar(
    String position,
    double affinity,
    bool isDark, {
    bool isBestFit = false,
    bool isCurrentPosition = false,
  }) {
    final color = _getAffinityColor(affinity, isDark);

    return Semantics(
      label: '$position: ${affinity.toStringAsFixed(0)}% affinity${isBestFit ? ', best fit' : ''}${isCurrentPosition ? ', current position' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      position,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrentPosition
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrentPosition
                            ? (isDark
                                ? AppTheme.primaryColorDark
                                : AppTheme.primaryColor)
                            : null,
                      ),
                    ),
                    if (isBestFit) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star,
                        size: 16,
                        color: isDark
                            ? AppTheme.successColorDark
                            : AppTheme.successColor,
                      ),
                    ],
                    if (isCurrentPosition) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${affinity.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: affinity / 100,
                minHeight: 12,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAffinityColor(double affinity, bool isDark) {
    if (affinity >= 80) {
      return isDark ? AppTheme.successColorDark : AppTheme.successColor;
    } else if (affinity >= 60) {
      return isDark ? Colors.amber[300]! : Colors.amber[700]!;
    } else {
      return isDark ? AppTheme.errorColorDark : AppTheme.errorColor;
    }
  }

  /// Build role fit analysis section showing all role archetypes for player's position
  Widget _buildRoleFitSection(BuildContext context, bool isDark) {
    final archetypes = RoleArchetypeRegistry.getArchetypesForPosition(_player.position);
    final fitScores = _player.getRoleFitScores();
    final currentRole = _player.getRoleArchetype();

    return Semantics(
      label: 'Role fit analysis section. Current role: ${currentRole?.name ?? "None"}',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Role Fit Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Display all role archetypes as cards
              ...archetypes.map((archetype) {
                final fitScore = fitScores[archetype.id] ?? 0.0;
                final isCurrentRole = currentRole?.id == archetype.id;
                return _buildRoleCard(
                  context,
                  archetype,
                  fitScore,
                  isDark,
                  isCurrentRole: isCurrentRole,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a single role card with fit score
  Widget _buildRoleCard(
    BuildContext context,
    RoleArchetype archetype,
    double fitScore,
    bool isDark, {
    bool isCurrentRole = false,
  }) {
    final fitColor = _getAffinityColor(fitScore, isDark);

    return Semantics(
      label: '${archetype.name}, fit score ${fitScore.toStringAsFixed(0)}%${isCurrentRole ? ', currently assigned' : ''}. Tap to view details.',
      button: true,
      child: InkWell(
        onTap: () => _showRoleDetails(context, archetype, fitScore, isDark),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentRole
                ? (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor)
                    .withValues(alpha: 0.15)
                : (isDark ? Colors.grey[850] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: isCurrentRole
                ? Border.all(
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Fit score circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fitColor.withValues(alpha: 0.2),
                  border: Border.all(color: fitColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${fitScore.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: fitColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Role name
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        archetype.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentRole
                              ? (isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor)
                              : null,
                        ),
                      ),
                    ),
                    if (isCurrentRole)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppTheme.primaryColorDark
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get top N attributes for a role archetype sorted by weight
  List<String> _getTopAttributes(RoleArchetype archetype, int count) {
    final sortedAttributes = archetype.attributeWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedAttributes.take(count).map((e) => e.key).toList();
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
      default:
        return attribute;
    }
  }

  /// Show detailed role information dialog
  void _showRoleDetails(
    BuildContext context,
    RoleArchetype archetype,
    double fitScore,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Semantics(
            label: '${archetype.name} role details',
            child: Text(archetype.name),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fit score display
                Center(
                  child: Semantics(
                    label: 'Fit score: ${fitScore.toStringAsFixed(0)}%',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAffinityColor(fitScore, isDark)
                            .withValues(alpha: 0.2),
                        border: Border.all(
                          color: _getAffinityColor(fitScore, isDark),
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${fitScore.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getAffinityColor(fitScore, isDark),
                              ),
                            ),
                            const Text(
                              'Fit',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Attribute breakdown
                Semantics(
                  label: 'Key attributes for this role',
                  child: const Text(
                    'Key Attributes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Show all attributes with weights
                ...archetype.attributeWeights.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final attr = entry.value;
                  final playerValue = _getPlayerAttributeValue(attr.key);
                  return Semantics(
                    label:
                        '${_formatAttributeName(attr.key)}: player has $playerValue, weight ${(attr.value * 100).toStringAsFixed(0)}%',
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatAttributeName(attr.key),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Player: $playerValue',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getRatingColor(
                                  playerValue,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Weight: ${(attr.value * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Gameplay modifiers
                if (archetype.gameplayModifiers.isNotEmpty) ...[
                  Semantics(
                    label: 'Gameplay modifiers for this role',
                    child: const Text(
                      'Gameplay Modifiers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...archetype.gameplayModifiers.entries.map((modifier) {
                    final modifierText = _formatModifierName(modifier.key);
                    final modifierValue = modifier.value;
                    final isIncrease = modifierValue > 1.0;
                    final percentChange =
                        ((modifierValue - 1.0) * 100).abs().toStringAsFixed(0);

                    return Semantics(
                      label:
                          '$modifierText ${isIncrease ? 'increased' : 'decreased'} by $percentChange%',
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              isIncrease
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: isIncrease
                                  ? (isDark
                                      ? AppTheme.successColorDark
                                      : AppTheme.successColor)
                                  : (isDark
                                      ? AppTheme.errorColorDark
                                      : AppTheme.errorColor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modifierText,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${isIncrease ? '+' : '-'}$percentChange%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isIncrease
                                    ? (isDark
                                        ? AppTheme.successColorDark
                                        : AppTheme.successColor)
                                    : (isDark
                                        ? AppTheme.errorColorDark
                                        : AppTheme.errorColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            // Assign Role button (only if leagueService is available)
            if (widget.leagueService != null &&
                _player.roleArchetypeId != archetype.id)
              Semantics(
                label: 'Assign ${archetype.name} role to ${_player.name}',
                button: true,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _assignRole(archetype);
                  },
                  child: const Text('Assign Role'),
                ),
              ),
            Semantics(
              label: 'Close dialog',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Get player attribute value by name
  int _getPlayerAttributeValue(String attribute) {
    switch (attribute) {
      case 'shooting':
        return _player.shooting;
      case 'threePoint':
        return _player.threePoint;
      case 'passing':
        return _player.passing;
      case 'ballHandling':
        return _player.ballHandling;
      case 'postShooting':
        return _player.postShooting;
      case 'defense':
        return _player.defense;
      case 'steals':
        return _player.steals;
      case 'blocks':
        return _player.blocks;
      case 'rebounding':
        return _player.rebounding;
      case 'speed':
        return _player.speed;
      default:
        return 0;
    }
  }

  /// Format gameplay modifier name for display
  String _formatModifierName(String modifier) {
    switch (modifier) {
      case 'assistProbability':
        return 'Assist Probability';
      case 'shotAttemptProbability':
        return 'Shot Attempts';
      case 'threePointAttemptProbability':
        return '3PT Attempts';
      case 'postShootingAttemptProbability':
        return 'Post Shot Attempts';
      case 'shotCreationProbability':
        return 'Shot Creation';
      case 'catchAndShootProbability':
        return 'Catch & Shoot';
      case 'stealProbability':
        return 'Steal Probability';
      case 'blockProbability':
        return 'Block Probability';
      case 'reboundProbability':
        return 'Rebound Probability';
      case 'defensiveImpact':
        return 'Defensive Impact';
      case 'ballHandlingUsage':
        return 'Ball Handling Usage';
      default:
        return modifier;
    }
  }

  /// Assign a role to the player
  Future<void> _assignRole(RoleArchetype archetype) async {
    if (widget.leagueService == null || widget.teamId == null) return;

    // Create updated player with new role
    final updatedPlayer = _player.copyWithRoleArchetype(archetype.id);

    // Find the team that contains this player
    final team = widget.leagueService!.teams.firstWhere(
      (t) => t.id == widget.teamId,
    );

    // Update player in team's player list
    final updatedPlayers = team.players.map((p) {
      return p.id == _player.id ? updatedPlayer : p;
    }).toList();

    // Create updated team
    final updatedTeam = team.copyWith(players: updatedPlayers);

    // Save to league service
    await widget.leagueService!.updateTeam(updatedTeam);

    // Update local state
    setState(() {
      _player = updatedPlayer;
    });

    if (mounted) {
      AccessibilityUtils.showAccessibleSuccess(
        context,
        '${_player.name} role changed to ${archetype.name}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildSeasonStatsSection(
    BuildContext context,
    bool isDark,
    PlayerSeasonStats stats,
  ) {
    return Semantics(
      label: 'Season statistics: ${stats.gamesPlayed} games played',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Season Statistics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${stats.gamesPlayed} Games',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Primary stats
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

              const Divider(height: 32),

              // Shooting stats
              _buildStatCategory('Shooting', [
                _buildStatRow('FG%', '${stats.fieldGoalPercentage.toStringAsFixed(1)}%', stats.fieldGoalPercentage >= 50.0, isDark),
                _buildStatRow('3PT%', '${stats.threePointPercentage.toStringAsFixed(1)}%', stats.threePointPercentage >= 40.0, isDark),
                _buildStatRow('FT%', '${stats.freeThrowPercentage.toStringAsFixed(1)}%', stats.freeThrowPercentage >= 80.0, isDark),
              ]),

              const SizedBox(height: 16),

              // Defense stats
              _buildStatCategory('Defense', [
                _buildStatRow('SPG', stats.stealsPerGame.toStringAsFixed(1), stats.stealsPerGame >= 2.0, isDark),
                _buildStatRow('BPG', stats.blocksPerGame.toStringAsFixed(1), stats.blocksPerGame >= 1.5, isDark),
              ]),

              const SizedBox(height: 16),

              // Other stats
              _buildStatCategory('Other', [
                _buildStatRow('TPG', stats.turnoversPerGame.toStringAsFixed(1), stats.turnoversPerGame >= 3.0, isDark, isNegative: true),
                _buildStatRow('FPG', stats.foulsPerGame.toStringAsFixed(1), stats.foulsPerGame >= 4.0, isDark, isNegative: true),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isHighlight, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCategory(String title, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...stats,
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    bool isHighlight,
    bool isDark, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight
                  ? (isNegative
                      ? (isDark ? AppTheme.errorColorDark : AppTheme.errorColor)
                      : (isDark ? AppTheme.successColorDark : AppTheme.successColor))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGameLogs(BuildContext context, bool isDark) {
    // Get recent games where this player participated
    final playedGames = widget.season!.games
        .where((game) => game.isPlayed && game.boxScore != null && game.boxScore!.containsKey(_player.id))
        .toList();

    // Get last 5-10 games
    final recentGames = playedGames.reversed.take(10).toList();

    if (recentGames.isEmpty) {
      return Semantics(
        label: 'No game logs available yet',
        child: Card(
          elevation: AppTheme.cardElevationMedium,
          child: Padding(
            padding: AppTheme.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: isDark
                          ? AppTheme.primaryColorDark
                          : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Game Logs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'No game logs available yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Recent game logs: ${recentGames.length} games',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: isDark
                        ? AppTheme.primaryColorDark
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Game Logs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last ${recentGames.length} Games',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Game log table header
              Semantics(
                label: 'Game logs table with columns: Game number, Points, Rebounds, Assists, Field Goal Percentage, Three Point Percentage',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 60, child: Text('Game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      _buildGameLogHeaderCell('PTS'),
                      _buildGameLogHeaderCell('REB'),
                      _buildGameLogHeaderCell('AST'),
                      _buildGameLogHeaderCell('FG%'),
                      _buildGameLogHeaderCell('3P%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Game log rows
              ...recentGames.asMap().entries.map((entry) {
                final index = entry.key;
                final game = entry.value;
                final stats = game.boxScore![_player.id]!;
                final gameNumber = widget.season!.games.indexOf(game) + 1;
                return _buildGameLogRow(gameNumber, stats, isDark, index);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameLogHeaderCell(String text) {
    return SizedBox(
      width: 55,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGameLogRow(int gameNumber, PlayerGameStats stats, bool isDark, int index) {
    return Semantics(
      label: 'Game $gameNumber: ${stats.points} points, ${stats.rebounds} rebounds, ${stats.assists} assists, ${stats.fieldGoalPercentage.toStringAsFixed(1)}% field goals, ${stats.threePointPercentage.toStringAsFixed(1)}% three pointers',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppTheme.dividerColorDark : AppTheme.dividerColorLight,
              width: 0.5,
            ),
          ),
          color: index % 2 == 0
              ? (isDark ? Colors.grey[900] : Colors.grey[50])
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Game $gameNumber',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            _buildGameLogStatCell(stats.points, isHighlight: stats.points >= 20),
            _buildGameLogStatCell(stats.rebounds, isHighlight: stats.rebounds >= 10),
            _buildGameLogStatCell(stats.assists, isHighlight: stats.assists >= 10),
            _buildGameLogPercentageCell(stats.fieldGoalPercentage, isHighlight: stats.fieldGoalPercentage >= 50),
            _buildGameLogPercentageCell(stats.threePointPercentage, isHighlight: stats.threePointPercentage >= 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGameLogStatCell(int value, {bool isHighlight = false}) {
    return SizedBox(
      width: 55,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: isHighlight ? AppTheme.successColor : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildGameLogPercentageCell(double value, {bool isHighlight = false}) {
    return SizedBox(
      width: 55,
      child: Text(
        value > 0 ? '${value.toStringAsFixed(1)}%' : '-',
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: isHighlight ? AppTheme.successColor : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
