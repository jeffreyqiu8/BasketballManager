import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

class PlayerPage extends StatelessWidget {
  final Player player;

  const PlayerPage({super.key, required this.player});

  EnhancedPlayer? get enhancedPlayer => player is EnhancedPlayer ? player as EnhancedPlayer : null;

  // Calculate season averages
  Map<String, double> get seasonAverages {
    if (player.gamesPlayed == 0) {
      return {
        'ppg': 0.0,
        'rpg': 0.0,
        'apg': 0.0,
        'fgPct': 0.0,
        'threePct': 0.0,
        'mpg': 0.0,
      };
    }

    double totalFGM = 0, totalFGA = 0, total3PM = 0, total3PA = 0, totalMinutes = 0;
    
    for (var performance in player.performances.values) {
      totalFGM += (performance['FGM'] ?? 0).toDouble();
      totalFGA += (performance['FGA'] ?? 0).toDouble();
      total3PM += (performance['3PM'] ?? 0).toDouble();
      total3PA += (performance['3PA'] ?? 0).toDouble();
      totalMinutes += (performance['minutes'] ?? 25).toDouble(); // Default 25 minutes if not tracked
    }

    return {
      'ppg': player.points / player.gamesPlayed,
      'rpg': player.rebounds / player.gamesPlayed,
      'apg': player.assists / player.gamesPlayed,
      'fgPct': totalFGA > 0 ? (totalFGM / totalFGA) * 100 : 0.0,
      'threePct': total3PA > 0 ? (total3PM / total3PA) * 100 : 0.0,
      'mpg': totalMinutes / player.gamesPlayed,
    };
  }

  // Get player rating based on attributes
  int get overallRating {
    final attributes = [
      player.shooting,
      player.rebounding,
      player.passing,
      player.ballHandling,
      player.perimeterDefense,
      player.postDefense,
      player.insideShooting,
    ];
    return (attributes.reduce((a, b) => a + b) / attributes.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final averages = seasonAverages;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          player.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          HelpButton(contextId: 'player_profile'),
          FeedbackButton(feature: 'player_profile'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Header Card
            _buildPlayerHeader(),
            
            const SizedBox(height: 20),
            
            // Season Averages Card
            _buildSeasonAverages(averages),
            
            const SizedBox(height: 20),
            
            // Player Attributes
            _buildPlayerAttributes(),
            
            const SizedBox(height: 20),
            
            // Enhanced Player Info (if available)
            if (enhancedPlayer != null) ...[
              _buildEnhancedPlayerInfo(),
              const SizedBox(height: 20),
            ],
            
            // Recent Games Performance
            if (player.performances.isNotEmpty) ...[
              _buildRecentGames(),
              const SizedBox(height: 20),
            ],
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // Player Header with photo, name, and basic info
  Widget _buildPlayerHeader() {
    return AccessibleCard(
      semanticLabel: 'Player ${player.name}, age ${player.age}, overall rating $overallRating',
      child: Column(
        children: [
          Row(
            children: [
              // Player Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    player.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip('Age ${player.age}', Icons.cake),
                        const SizedBox(width: 8),
                        _buildInfoChip('${player.height} cm', Icons.height),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(player.team, Icons.sports_basketball),
                        const SizedBox(width: 8),
                        if (enhancedPlayer != null)
                          _buildInfoChip(
                            enhancedPlayer!.primaryRole.toString().split('.').last.toUpperCase(),
                            Icons.person,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Overall Rating
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRatingColor(overallRating),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      overallRating.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'OVR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Season Averages Card
  Widget _buildSeasonAverages(Map<String, double> averages) {
    return AccessibleCard(
      semanticLabel: 'Season averages: ${averages['ppg']!.toStringAsFixed(1)} points, ${averages['rpg']!.toStringAsFixed(1)} rebounds, ${averages['apg']!.toStringAsFixed(1)} assists per game',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Season Averages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${player.gamesPlayed} GP',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('PPG', averages['ppg']!.toStringAsFixed(1), Colors.orange),
              _buildStatColumn('RPG', averages['rpg']!.toStringAsFixed(1), Colors.green),
              _buildStatColumn('APG', averages['apg']!.toStringAsFixed(1), Colors.blue),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Shooting Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('FG%', '${averages['fgPct']!.toStringAsFixed(1)}%', Colors.purple),
              _buildStatColumn('3P%', '${averages['threePct']!.toStringAsFixed(1)}%', Colors.red),
              _buildStatColumn('MPG', averages['mpg']!.toStringAsFixed(1), Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  // Player Attributes with visual bars
  Widget _buildPlayerAttributes() {
    return AccessibleCard(
      semanticLabel: 'Player attributes and skills',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Player Attributes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildAttributeBar('Shooting', player.shooting, Colors.orange),
          _buildAttributeBar('Rebounding', player.rebounding, Colors.green),
          _buildAttributeBar('Passing', player.passing, Colors.blue),
          _buildAttributeBar('Ball Handling', player.ballHandling, Colors.purple),
          _buildAttributeBar('Perimeter Defense', player.perimeterDefense, Colors.red),
          _buildAttributeBar('Post Defense', player.postDefense, Colors.indigo),
          _buildAttributeBar('Inside Shooting', player.insideShooting, Colors.amber),
        ],
      ),
    );
  }

  // Enhanced Player Information
  Widget _buildEnhancedPlayerInfo() {
    if (enhancedPlayer == null) return const SizedBox.shrink();
    
    return AccessibleCard(
      semanticLabel: 'Enhanced player information and development',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Development Info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Experience',
                  '${enhancedPlayer!.experienceYears} years',
                  Icons.timeline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  'Nationality',
                  enhancedPlayer!.nationality,
                  Icons.flag,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  'Status',
                  enhancedPlayer!.currentStatus,
                  Icons.info,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoTile(
                  'Total XP',
                  '${enhancedPlayer!.development.totalExperience}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Games Performance
  Widget _buildRecentGames() {
    final recentGames = player.performances.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // Sort by matchday descending
    final displayGames = recentGames.take(5).toList(); // Show last 5 games
    
    return AccessibleCard(
      semanticLabel: 'Recent game performances',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.deepPurple, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Recent Games',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...displayGames.map((entry) => _buildGameRow(entry.key, entry.value)),
        ],
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (enhancedPlayer != null) ...[
          Row(
            children: [
              Expanded(
                child: AccessibleButton(
                  text: 'Develop Skills',
                  icon: Icons.trending_up,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Player development feature coming soon!')),
                    );
                  },
                  semanticLabel: 'Develop ${player.name}\'s skills',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccessibleButton(
                  text: 'View Analytics',
                  icon: Icons.analytics,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Player analytics feature coming soon!')),
                    );
                  },
                  semanticLabel: 'View ${player.name}\'s performance analytics',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Helper Widgets
  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildAttributeBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRow(int matchday, Map<String, int> performance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'G$matchday',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGameStat('${performance['points'] ?? 0}', 'PTS'),
                _buildGameStat('${performance['rebounds'] ?? 0}', 'REB'),
                _buildGameStat('${performance['assists'] ?? 0}', 'AST'),
                _buildGameStat('${performance['FGM'] ?? 0}/${performance['FGA'] ?? 0}', 'FG'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 90) return Colors.purple;
    if (rating >= 80) return Colors.blue;
    if (rating >= 70) return Colors.green;
    if (rating >= 60) return Colors.orange;
    return Colors.red;
  }
}
