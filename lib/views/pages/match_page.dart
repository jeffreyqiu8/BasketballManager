import 'package:BasketballManager/gameData/conference_class.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:flutter/material.dart';

class MatchPage extends StatelessWidget {
  final Conference conference;
  final int matchday;
  final String hometeam;

  const MatchPage({
    super.key,
    required this.conference,
    required this.matchday,
    required this.hometeam,
  });

  @override
  Widget build(BuildContext context) {
    final match = conference.getMatch(hometeam, matchday);
    final home = conference.getTeam(hometeam);
    final away = conference.getTeam(match['away']);
    final homePlayers = home.players;
    final awayPlayers = away.players;

    return Scaffold(
      appBar: AppBar(
        title: Text('${home.name} vs ${away.name} - Matchday $matchday'),
        backgroundColor: Colors.grey[950],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: Colors.grey[850],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      '${home.name} vs ${away.name}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${match['homeScore']} - ${match['awayScore']}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildBoxScoreSection("${home.name} Box Score", homePlayers, matchday),
                _buildBoxScoreSection("${away.name} Box Score", awayPlayers, matchday),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxScoreSection(String title, List<Player> players, int matchday) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: players.map((player) {
              final stats = player.performances[matchday] ?? {
                "points": 0,
                "rebounds": 0,
                "assists": 0,
              };
              return Card(
                color: Colors.grey[800],
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statBox("PTS", stats["points"] ?? 0),
                      const SizedBox(width: 8),
                      _statBox("REB", stats["rebounds"] ?? 0),
                      const SizedBox(width: 8),
                      _statBox("AST", stats["assists"] ?? 0),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
