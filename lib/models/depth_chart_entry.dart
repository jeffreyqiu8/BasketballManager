/// Represents a player's assignment to a position in the depth chart.
/// 
/// Each entry defines which player is assigned to which position and at what
/// depth (1 = starter, 2+ = bench depth).
class DepthChartEntry {
  /// The unique identifier of the player
  final String playerId;
  
  /// The position assigned to the player ('PG', 'SG', 'SF', 'PF', 'C')
  final String position;
  
  /// The depth at this position (1 = starter, 2+ = bench depth)
  final int depth;

  /// Valid position values
  static const List<String> validPositions = ['PG', 'SG', 'SF', 'PF', 'C'];

  DepthChartEntry({
    required this.playerId,
    required this.position,
    required this.depth,
  }) {
    _validate();
  }

  /// Validates the depth chart entry
  void _validate() {
    if (!validPositions.contains(position)) {
      throw ArgumentError(
        'Invalid position: $position. Must be one of: ${validPositions.join(", ")}'
      );
    }
    if (depth < 1) {
      throw ArgumentError('Depth must be at least 1, got: $depth');
    }
  }

  /// Converts this entry to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'position': position,
      'depth': depth,
    };
  }

  /// Creates a DepthChartEntry from a JSON map
  factory DepthChartEntry.fromJson(Map<String, dynamic> json) {
    return DepthChartEntry(
      playerId: json['playerId'] as String,
      position: json['position'] as String,
      depth: json['depth'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DepthChartEntry &&
        other.playerId == playerId &&
        other.position == position &&
        other.depth == depth;
  }

  @override
  int get hashCode => Object.hash(playerId, position, depth);

  @override
  String toString() {
    return 'DepthChartEntry(playerId: $playerId, position: $position, depth: $depth)';
  }
}
