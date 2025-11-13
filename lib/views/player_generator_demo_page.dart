import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_generator.dart';
import '../widgets/star_rating.dart';

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
            hint: 'Creates 15 new random players',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _generatePlayers,
              tooltip: 'Generate New Players',
            ),
          ),
        ],
      ),
      body: Semantics(
        label: 'List of ${_players.length} generated players',
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final player = _players[index];
            return Semantics(
              label:
                  'Player ${index + 1} of ${_players.length}: ${player.name}, '
                  '${player.heightFormatted}, '
                  'overall rating ${player.positionAdjustedRating}',
              child: _PlayerCard(player: player, index: index, allPlayers: _players),
            );
          },
        ),
      ),
    );
  }
}

/// Widget to display a single player's information
class _PlayerCard extends StatelessWidget {
  final Player player;
  final int index;
  final List<Player> allPlayers;

  const _PlayerCard({
    required this.player,
    required this.index,
    required this.allPlayers,
  });

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        player.heightFormatted,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      label: '${player.getStarRatingRounded(allPlayers)} stars',
                      child: StarRating(
                        rating: player.getStarRatingRounded(allPlayers),
                        size: 20,
                        showLabel: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OVR ${player.positionAdjustedRating}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  Color _getStatColor(int stat) {
    if (stat >= 80) return Colors.green;
    if (stat >= 60) return Colors.blue;
    if (stat >= 40) return Colors.orange;
    return Colors.red;
  }
}
