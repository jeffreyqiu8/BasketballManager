import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/player_page.dart'; // Adjust the import to match where your PlayerPage is

class TeamProfilePage extends StatelessWidget {
  final Team team;

  // Constructor to initialize the team
  TeamProfilePage({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the page
      appBar: AppBar(
        title: Text('${team.name}'),
        backgroundColor: Colors.deepPurple, // Dark purple background for app bar
        elevation: 0,
        foregroundColor: Colors.white, // White text in app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Name and Record
            Text(
              '${team.name}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for the team name
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record: ${team.wins} - ${team.losses}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.deepPurpleAccent, // Purple color for the record
                  ),
            ),
            const SizedBox(height: 20),

            // Players List
            Expanded(
              child: ListView.builder(
                itemCount: team.players.length,
                itemBuilder: (context, index) {
                  Player player = team.players[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to Player Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return PlayerPage(player: player);
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          // Player Initials (for simplicity)
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.deepPurple, // Purple background for initials
                            child: Text(
                              player.name.substring(0, 1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white, // White text for initials
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Player Name and Role (Minimized)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // White text for player name
                                ),
                              ),
                              Text(
                                '${player.age} | ${player.nationality}',
                                style: TextStyle(
                                  color: Colors.grey, // Grey for secondary info
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
