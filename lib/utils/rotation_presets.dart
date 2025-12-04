import '../models/player.dart';
import '../models/depth_chart_entry.dart';

/// Utility class for generating preset rotation configurations
/// 
/// Provides preset minute distributions for rotation sizes 6-10 players.
/// Each preset ensures total minutes equal 240 (48 minutes × 5 positions).
class RotationPresets {
  /// Generate a 10-player rotation preset
  /// Starters: 30 minutes each (150 total)
  /// Bench: 18 minutes each (90 total)
  /// Total: 240 minutes
  static Map<String, dynamic> get10PlayerPreset(List<Player> players) {
    final ranked = rankPlayersByRating(players);
    
    if (ranked.length < 10) {
      throw ArgumentError('Need at least 10 players for 10-player rotation');
    }

    final playerMinutes = <String, int>{};
    final depthChart = <DepthChartEntry>[];
    
    // Assign starters (top 5 players) to positions
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    for (int i = 0; i < 5; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = 30;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i],
        depth: 1,
      ));
    }
    
    // Assign bench players (next 5 players) to positions
    for (int i = 5; i < 10; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = 18;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i - 5],
        depth: 2,
      ));
    }
    
    return {
      'playerMinutes': playerMinutes,
      'depthChart': depthChart,
    };
  }

  /// Generate a 9-player rotation preset
  /// Starters: 32 minutes each (160 total)
  /// Bench: 16, 16, 16, 16 minutes (64 total)
  /// One position has no backup (starter plays full 48)
  /// Total: 224 minutes + 16 (one starter plays 48) = 240 minutes
  static Map<String, dynamic> get9PlayerPreset(List<Player> players) {
    final ranked = rankPlayersByRating(players);
    
    if (ranked.length < 9) {
      throw ArgumentError('Need at least 9 players for 9-player rotation');
    }

    final playerMinutes = <String, int>{};
    final depthChart = <DepthChartEntry>[];
    
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    // Assign starters (top 5 players) to positions
    // The best starter (index 0) plays 48 minutes (no backup)
    for (int i = 0; i < 5; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = i == 0 ? 48 : 32;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i],
        depth: 1,
      ));
    }
    
    // Assign bench players (next 4 players) to positions 1-4
    // Position 0 (PG) has no backup since best player plays full 48
    for (int i = 5; i < 9; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = 16;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i - 4], // Positions 1-4 (SG, SF, PF, C)
        depth: 2,
      ));
    }
    
    return {
      'playerMinutes': playerMinutes,
      'depthChart': depthChart,
    };
  }

  /// Generate an 8-player rotation preset
  /// Starters: 34 minutes each (170 total)
  /// Bench: 14, 14, 14 minutes (42 total)
  /// Two positions have no backup (starters play full 48)
  /// Total: 170 + 42 + 28 (two starters play 48) = 240 minutes
  /// 
  /// Players are assigned to depth chart positions based on their actual position
  /// Falls back to rating-based assignment if positions aren't balanced
  static Map<String, dynamic> get8PlayerPreset(List<Player> players) {
    if (players.length < 8) {
      throw ArgumentError('Need at least 8 players for 8-player rotation');
    }

    final playerMinutes = <String, int>{};
    final depthChart = <DepthChartEntry>[];
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    // Get players grouped by their actual position
    final byPosition = getPlayersByPosition(players);
    
    // Check if we have at least one player at each position
    bool hasAllPositions = positions.every((pos) => byPosition[pos]!.isNotEmpty);
    
    if (!hasAllPositions) {
      // Fall back to rating-based assignment if positions aren't balanced
      final ranked = rankPlayersByRating(players);
      
      // Assign starters (top 5 players) to positions
      // Top 2 starters play 48 minutes (no backup)
      for (int i = 0; i < 5; i++) {
        final player = ranked[i];
        playerMinutes[player.id] = i < 2 ? 48 : 34;
        depthChart.add(DepthChartEntry(
          playerId: player.id,
          position: positions[i],
          depth: 1,
        ));
      }
      
      // Assign bench players (next 3 players) to positions 2-4
      for (int i = 5; i < 8; i++) {
        final player = ranked[i];
        playerMinutes[player.id] = 14;
        depthChart.add(DepthChartEntry(
          playerId: player.id,
          position: positions[i - 3], // Positions 2-4 (SF, PF, C)
          depth: 2,
        ));
      }
      
      return {
        'playerMinutes': playerMinutes,
        'depthChart': depthChart,
      };
    }
    
    // Position-based assignment (preferred when all positions are covered)
    // For 8-player rotation: 5 starters + 3 bench
    // We'll give bench spots to the 3 positions with the best backup players
    
    // First, assign the best player at each position as starter
    for (final position in positions) {
      final starter = byPosition[position]![0];
      // Default to 34 minutes, will adjust later for positions without backup
      playerMinutes[starter.id] = 34;
      depthChart.add(DepthChartEntry(
        playerId: starter.id,
        position: position,
        depth: 1,
      ));
    }
    
    // Find the 3 positions with the best backup players
    final backupCandidates = <Map<String, dynamic>>[];
    for (final position in positions) {
      final positionPlayers = byPosition[position]!;
      if (positionPlayers.length > 1) {
        backupCandidates.add({
          'position': position,
          'player': positionPlayers[1],
          'rating': positionPlayers[1].positionAdjustedRating,
        });
      }
    }
    
    // Sort by rating and take top 3
    backupCandidates.sort((a, b) => 
      (b['rating'] as int).compareTo(a['rating'] as int)
    );
    
    final positionsWithBackup = <String>{};
    for (int i = 0; i < 3 && i < backupCandidates.length; i++) {
      final candidate = backupCandidates[i];
      final position = candidate['position'] as String;
      final player = candidate['player'] as Player;
      
      positionsWithBackup.add(position);
      playerMinutes[player.id] = 14;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: position,
        depth: 2,
      ));
    }
    
    // Update starters without backup to play 48 minutes
    for (final position in positions) {
      if (!positionsWithBackup.contains(position)) {
        final starter = byPosition[position]![0];
        playerMinutes[starter.id] = 48;
      }
    }
    
    return {
      'playerMinutes': playerMinutes,
      'depthChart': depthChart,
    };
  }

  /// Generate a 7-player rotation preset
  /// Starters: 36 minutes each (180 total)
  /// Bench: 12, 12 minutes (24 total)
  /// Three positions have no backup (starters play full 48)
  /// Total: 180 + 24 + 36 (three starters play 48) = 240 minutes
  static Map<String, dynamic> get7PlayerPreset(List<Player> players) {
    final ranked = rankPlayersByRating(players);
    
    if (ranked.length < 7) {
      throw ArgumentError('Need at least 7 players for 7-player rotation');
    }

    final playerMinutes = <String, int>{};
    final depthChart = <DepthChartEntry>[];
    
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    // Assign starters (top 5 players) to positions
    // Top 3 starters play 48 minutes (no backup)
    for (int i = 0; i < 5; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = i < 3 ? 48 : 36;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i],
        depth: 1,
      ));
    }
    
    // Assign bench players (next 2 players) to positions 3-4
    // Positions 0-2 (PG, SG, SF) have no backup
    for (int i = 5; i < 7; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = 12;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i - 2], // Positions 3-4 (PF, C)
        depth: 2,
      ));
    }
    
    return {
      'playerMinutes': playerMinutes,
      'depthChart': depthChart,
    };
  }

  /// Generate a 6-player rotation preset
  /// Starters: 38 minutes each (190 total)
  /// Bench: 10 minutes (10 total)
  /// Four positions have no backup (starters play full 48)
  /// Total: 190 + 10 + 40 (four starters play 48) = 240 minutes
  static Map<String, dynamic> get6PlayerPreset(List<Player> players) {
    final ranked = rankPlayersByRating(players);
    
    if (ranked.length < 6) {
      throw ArgumentError('Need at least 6 players for 6-player rotation');
    }

    final playerMinutes = <String, int>{};
    final depthChart = <DepthChartEntry>[];
    
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    
    // Assign starters (top 5 players) to positions
    // Top 4 starters play 48 minutes (no backup)
    for (int i = 0; i < 5; i++) {
      final player = ranked[i];
      playerMinutes[player.id] = i < 4 ? 48 : 38;
      depthChart.add(DepthChartEntry(
        playerId: player.id,
        position: positions[i],
        depth: 1,
      ));
    }
    
    // Assign bench player (6th player) to position 4 (C)
    // Positions 0-3 (PG, SG, SF, PF) have no backup
    final player = ranked[5];
    playerMinutes[player.id] = 10;
    depthChart.add(DepthChartEntry(
      playerId: player.id,
      position: positions[4], // Position 4 (C)
      depth: 2,
    ));
    
    return {
      'playerMinutes': playerMinutes,
      'depthChart': depthChart,
    };
  }

  /// Rank players by their position-adjusted rating (highest to lowest)
  /// 
  /// This helper method sorts players to determine who should be starters
  /// and who should be bench players in preset rotations.
  static List<Player> rankPlayersByRating(List<Player> players) {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => b.positionAdjustedRating.compareTo(a.positionAdjustedRating));
    return sorted;
  }

  /// Get the best players for each position
  /// Returns a map of position -> list of players sorted by rating
  static Map<String, List<Player>> getPlayersByPosition(List<Player> players) {
    final byPosition = <String, List<Player>>{
      'PG': [],
      'SG': [],
      'SF': [],
      'PF': [],
      'C': [],
    };

    // Group players by their actual position
    for (final player in players) {
      byPosition[player.position]?.add(player);
    }

    // Sort each position group by rating (best first)
    for (final position in byPosition.keys) {
      byPosition[position]!.sort((a, b) => 
        b.positionAdjustedRating.compareTo(a.positionAdjustedRating)
      );
    }

    return byPosition;
  }
}
