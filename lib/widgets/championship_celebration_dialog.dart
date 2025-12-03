import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../models/player_playoff_stats.dart';
import '../services/league_service.dart';

/// Championship celebration dialog
/// Displays when the user wins the NBA Finals
class ChampionshipCelebrationDialog extends StatelessWidget {
  final Season season;
  final Team championTeam;
  final LeagueService leagueService;
  final VoidCallback onStartNewSeason;

  const ChampionshipCelebrationDialog({
    super.key,
    required this.season,
    required this.championTeam,
    required this.leagueService,
    required this.onStartNewSeason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mvpPlayer = _getMvpPlayer();
    final mvpStats = season.playoffStats?[mvpPlayer?.id];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                const Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),

                // Championship banner
                Text(
                  '🏆 NBA CHAMPIONS! 🏆',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amber : Colors.amber.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Team name and year
                Text(
                  '${championTeam.city} ${championTeam.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${season.year} Season',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Finals MVP section
                if (mvpPlayer != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Finals MVP',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mvpPlayer.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mvpPlayer.position} • ${mvpPlayer.heightInches ~/ 12}\'${mvpPlayer.heightInches % 12}"',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  if (mvpStats != null) ...[
                    const SizedBox(height: 16),
                    _buildMvpStats(mvpStats, isDark),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Playoff statistics summary
                const SizedBox(height: 16),
                Text(
                  'Playoff Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPlayoffSummary(isDark),

                const SizedBox(height: 24),

                // Start new season button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onStartNewSeason();
                    },
                    icon: const Icon(Icons.refresh, size: 24),
                    label: const Text(
                      'Start New Season',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Player? _getMvpPlayer() {
    if (season.championshipRecord?.finalsMvpPlayerId == null) return null;
    
    final mvpId = season.championshipRecord!.finalsMvpPlayerId!;
    for (var player in championTeam.players) {
      if (player.id == mvpId) return player;
    }
    return null;
  }

  Widget _buildMvpStats(PlayerPlayoffStats stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('PPG', stats.pointsPerGame.toStringAsFixed(1), isDark),
          _buildStatColumn('RPG', stats.reboundsPerGame.toStringAsFixed(1), isDark),
          _buildStatColumn('APG', stats.assistsPerGame.toStringAsFixed(1), isDark),
          _buildStatColumn('FG%', '${(stats.fieldGoalPercentage * 100).toStringAsFixed(1)}%', isDark),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayoffSummary(bool isDark) {
    if (season.playoffStats == null || season.playoffStats!.isEmpty) {
      return const Text('No playoff statistics available');
    }

    // Get top 3 scorers from the championship team
    final teamStats = <String, PlayerPlayoffStats>{};
    for (var entry in season.playoffStats!.entries) {
      final playerId = entry.key;
      // Check if player is on championship team
      if (championTeam.players.any((p) => p.id == playerId)) {
        teamStats[playerId] = entry.value;
      }
    }

    final sortedStats = teamStats.entries.toList()
      ..sort((a, b) => b.value.pointsPerGame.compareTo(a.value.pointsPerGame));

    final topScorers = sortedStats.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...topScorers.map((entry) {
            final player = championTeam.players.firstWhere((p) => p.id == entry.key);
            final stats = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      player.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '${stats.pointsPerGame.toStringAsFixed(1)} PPG',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
