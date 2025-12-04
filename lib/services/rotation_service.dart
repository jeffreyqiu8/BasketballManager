import '../models/player.dart';
import '../models/rotation_config.dart';
import '../models/depth_chart_entry.dart';
import '../utils/rotation_presets.dart';

/// Business logic service for rotation management
/// 
/// Provides methods for generating rotation configurations, validating them,
/// and managing preset rotations for teams.
class RotationService {
  /// Generate a rotation configuration for the given rotation size
  /// 
  /// Creates a preset rotation configuration based on the specified size (6-10 players)
  /// and the team's player roster. Players are ranked by position-adjusted rating
  /// and assigned to positions accordingly.
  /// 
  /// Throws [ArgumentError] if rotationSize is not between 6 and 10, or if
  /// there are insufficient players for the requested rotation size.
  static RotationConfig generatePreset(int rotationSize, List<Player> players) {
    if (rotationSize < 6 || rotationSize > 10) {
      throw ArgumentError('Rotation size must be between 6 and 10, got: $rotationSize');
    }
    
    if (players.length < rotationSize) {
      throw ArgumentError(
        'Need at least $rotationSize players for $rotationSize-player rotation, got: ${players.length}'
      );
    }

    // Get the appropriate preset based on rotation size
    final Map<String, dynamic> presetData;
    switch (rotationSize) {
      case 10:
        presetData = RotationPresets.get10PlayerPreset(players);
        break;
      case 9:
        presetData = RotationPresets.get9PlayerPreset(players);
        break;
      case 8:
        presetData = RotationPresets.get8PlayerPreset(players);
        break;
      case 7:
        presetData = RotationPresets.get7PlayerPreset(players);
        break;
      case 6:
        presetData = RotationPresets.get6PlayerPreset(players);
        break;
      default:
        throw ArgumentError('Invalid rotation size: $rotationSize');
    }

    return RotationConfig(
      rotationSize: rotationSize,
      playerMinutes: presetData['playerMinutes'] as Map<String, int>,
      depthChart: presetData['depthChart'] as List<DepthChartEntry>,
      lastModified: DateTime.now(),
    );
  }

  /// Generate a default 8-player rotation for teams without a rotation configuration
  /// 
  /// Creates a standard 8-player rotation based on player ratings. This is used
  /// when a team doesn't have a custom rotation configured.
  /// 
  /// Throws [ArgumentError] if there are fewer than 8 players on the team.
  static RotationConfig generateDefaultRotation(List<Player> players) {
    return generatePreset(8, players);
  }

  /// Get the starting lineup player IDs from a rotation configuration
  /// 
  /// Returns a list of player IDs for players with depth = 1 in the depth chart,
  /// which represents the starting lineup.
  static List<String> getStartingLineup(RotationConfig config) {
    return config.depthChart
        .where((entry) => entry.depth == 1)
        .map((entry) => entry.playerId)
        .toList();
  }

  /// Group players by their assigned position in the depth chart
  /// 
  /// Returns a map where keys are position abbreviations ('PG', 'SG', 'SF', 'PF', 'C')
  /// and values are lists of player IDs assigned to that position, ordered by depth.
  static Map<String, List<String>> groupPlayersByPosition(RotationConfig config) {
    final grouped = <String, List<String>>{
      'PG': [],
      'SG': [],
      'SF': [],
      'PF': [],
      'C': [],
    };

    // Sort depth chart entries by position and depth
    final sortedEntries = List<DepthChartEntry>.from(config.depthChart);
    sortedEntries.sort((a, b) {
      final positionCompare = a.position.compareTo(b.position);
      if (positionCompare != 0) return positionCompare;
      return a.depth.compareTo(b.depth);
    });

    // Group by position
    for (final entry in sortedEntries) {
      grouped[entry.position]?.add(entry.playerId);
    }

    return grouped;
  }

  /// Validate a rotation configuration and return a list of error messages
  /// 
  /// Performs comprehensive validation of the rotation configuration including:
  /// - Position coverage (all 5 positions must have at least one player)
  /// - Minute distribution (each position must total exactly 48 minutes)
  /// - Player uniqueness (no player assigned to multiple positions)
  /// - Rotation size consistency (matches number of active players)
  /// - Minute value ranges (0-48 for each player)
  /// 
  /// Returns an empty list if the configuration is valid, otherwise returns
  /// a list of specific error messages describing the validation failures.
  static List<String> validateRotation(RotationConfig config, List<Player> players) {
    final errors = <String>[];

    // Use the built-in validation from RotationConfig
    errors.addAll(config.getValidationErrors());

    // Additional validation: check that all players in the rotation exist in the team
    final playerIds = players.map((p) => p.id).toSet();
    for (final playerId in config.playerMinutes.keys) {
      if (!playerIds.contains(playerId)) {
        errors.add('Player $playerId in rotation does not exist in team roster');
      }
    }

    // Additional validation: check that all depth chart players exist in the team
    for (final entry in config.depthChart) {
      if (!playerIds.contains(entry.playerId)) {
        errors.add('Player ${entry.playerId} in depth chart does not exist in team roster');
      }
    }

    return errors;
  }

  /// Check if all five positions have at least one player assigned
  /// 
  /// Returns true if each of the five positions (PG, SG, SF, PF, C) has at least
  /// one player assigned in the depth chart, false otherwise.
  static bool hasAllPositionsCovered(RotationConfig config) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    for (final position in positions) {
      final playersAtPosition = config.getPlayersForPosition(position);
      if (playersAtPosition.isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if the minute distribution is valid for all positions
  /// 
  /// Returns true if each of the five positions has exactly 48 minutes allocated
  /// across all players assigned to that position, false otherwise.
  static bool hasValidMinuteDistribution(RotationConfig config) {
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    for (final position in positions) {
      final totalMinutes = config.getTotalMinutesForPosition(position);
      if (totalMinutes != 48) {
        return false;
      }
    }
    
    return true;
  }
}
