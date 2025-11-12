import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_generator.dart';

/// Demo page to display randomly generated players
/// Shows all 8 stats for each player with accessibility support
class PlayerGeneratorDemoPage extends StatefulWidget {
  const PlayerGeneratorDemoPage({super.key});

  @override
  State<PlayerGeneratorDemoPage> createState() =>
      _PlayerGeneratorDemoPageState();
}

class _PlayerGeneratorDemoPageState extends State<PlayerGeneratorDemoPage> {
  final PlayerGenerator _generator = PlayerGenerator();
  List<Player> _players = [];

  @override
  void initState() {
    super.initState();
    _generatePlayers();
  }

  void _generatePlayers() {
    setState(() {
      _players = _generator.generateTeamRoster(15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Generator Demo'),
        actions: [
          Semantics(
            label: 'Generate new players',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generatePlayers,
              tooltip: 'Generate New Players',
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          final player = _players[index];
          return Semantics(
            label:
                'Player ${index + 1}: ${player.name}, '
                'Overall rating ${player.overallRating}',
            child: _PlayerCard(player: player, index: index),
          );
        },
      ),
    );
  }
}

/// Widget to display a single player's information
class _PlayerCard extends StatelessWidget {
  final Player player;
  final int index;

  const _PlayerCard({required this.player, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player name and overall rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(player.overallRating),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Semantics(
                    label: 'Overall rating ${player.overallRating}',
                    child: Text(
                      'OVR ${player.overallRating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats grid
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        _buildStatRow('Shooting', player.shooting),
        _buildStatRow('Defense', player.defense),
        _buildStatRow('Speed', player.speed),
        _buildStatRow('Stamina', player.stamina),
        _buildStatRow('Passing', player.passing),
        _buildStatRow('Rebounding', player.rebounding),
        _buildStatRow('Ball Handling', player.ballHandling),
        _buildStatRow('Three Point', player.threePoint),
      ],
    );
  }

  Widget _buildStatRow(String statName, int statValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Semantics(
        label: '$statName: $statValue out of 100',
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                statName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Background bar
                  Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Filled bar
                  FractionallySizedBox(
                    widthFactor: statValue / 100,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getStatColor(statValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 30,
              child: Text(
                statValue.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 80) return Colors.green[700]!;
    if (rating >= 70) return Colors.blue[700]!;
    if (rating >= 60) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Color _getStatColor(int stat) {
    if (stat >= 80) return Colors.green;
    if (stat >= 60) return Colors.blue;
    if (stat >= 40) return Colors.orange;
    return Colors.red;
  }
}
