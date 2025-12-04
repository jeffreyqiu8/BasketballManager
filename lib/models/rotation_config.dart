import 'depth_chart_entry.dart';

/// Core rotation configuration model that stores all rotation data.
/// 
/// This model defines which players are in the rotation, how many minutes
/// each player receives, and the depth chart for substitutions.
class RotationConfig {
  /// The number of players in the rotation (6-10)
  final int rotationSize;
  
  /// Map of player ID to minutes per game
  final Map<String, int> playerMinutes;
  
  /// List of depth chart entries defining position assignments
  final List<DepthChartEntry> depthChart;
  
  /// Timestamp of last modification
  final DateTime lastModified;

  RotationConfig({
    required this.rotationSize,
    required this.playerMinutes,
    required this.depthChart,
    required this.lastModified,
  });

  /// Validates the rotation configuration and returns true if valid
  bool isValid() {
    return getValidationErrors().isEmpty;
  }

  /// Returns a list of validation error messages
  List<String> getValidationErrors() {
    final errors = <String>[];

    // Validate rotation size is in valid range
    if (rotationSize < 6 || rotationSize > 10) {
      errors.add('Rotation size must be between 6 and 10, got: $rotationSize');
    }

    // Validate all five positions have at least one player
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    for (final position in positions) {
      final playersAtPosition = getPlayersForPosition(position);
      if (playersAtPosition.isEmpty) {
        errors.add('Position $position must have at least one player assigned');
      }
    }

    // Validate each position has exactly 48 minutes
    for (final position in positions) {
      final totalMinutes = getTotalMinutesForPosition(position);
      if (totalMinutes != 48) {
        errors.add('Position $position has $totalMinutes minutes allocated, must equal 48 minutes');
      }
    }

    // Validate no player is assigned to multiple positions
    final playerPositions = <String, List<String>>{};
    for (final entry in depthChart) {
      playerPositions.putIfAbsent(entry.playerId, () => []).add(entry.position);
    }
    for (final entry in playerPositions.entries) {
      if (entry.value.length > 1) {
        errors.add('Player ${entry.key} is assigned to multiple positions: ${entry.value.join(", ")}');
      }
    }

    // Validate rotation size matches number of players with non-zero minutes
    final activePlayerCount = getActivePlayerIds().length;
    if (activePlayerCount != rotationSize) {
      errors.add('Rotation size is $rotationSize but $activePlayerCount players have non-zero minutes');
    }

    // Validate minute values are in valid range (0-48)
    for (final entry in playerMinutes.entries) {
      final minutes = entry.value;
      if (minutes < 0 || minutes > 48) {
        errors.add('Player ${entry.key} has invalid minutes: $minutes (must be 0-48)');
      }
    }

    return errors;
  }

  /// Returns list of player IDs with non-zero minutes
  List<String> getActivePlayerIds() {
    return playerMinutes.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns total minutes allocated for a specific position
  int getTotalMinutesForPosition(String position) {
    final playersAtPosition = getPlayersForPosition(position);
    int total = 0;
    for (final playerId in playersAtPosition) {
      total += playerMinutes[playerId] ?? 0;
    }
    return total;
  }

  /// Returns list of player IDs assigned to a specific position
  List<String> getPlayersForPosition(String position) {
    return depthChart
        .where((entry) => entry.position == position)
        .map((entry) => entry.playerId)
        .toList();
  }

  /// Converts this configuration to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'rotationSize': rotationSize,
      'playerMinutes': playerMinutes,
      'depthChart': depthChart.map((entry) => entry.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  /// Creates a RotationConfig from a JSON map
  factory RotationConfig.fromJson(Map<String, dynamic> json) {
    return RotationConfig(
      rotationSize: json['rotationSize'] as int,
      playerMinutes: Map<String, int>.from(json['playerMinutes'] as Map),
      depthChart: (json['depthChart'] as List)
          .map((entry) => DepthChartEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RotationConfig &&
        other.rotationSize == rotationSize &&
        _mapsEqual(other.playerMinutes, playerMinutes) &&
        _listsEqual(other.depthChart, depthChart) &&
        other.lastModified == lastModified;
  }

  bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listsEqual(List<DepthChartEntry> a, List<DepthChartEntry> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    rotationSize,
    Object.hashAll(playerMinutes.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(depthChart),
    lastModified,
  );

  @override
  String toString() {
    return 'RotationConfig(rotationSize: $rotationSize, players: ${playerMinutes.length}, depthChart: ${depthChart.length} entries)';
  }
}
