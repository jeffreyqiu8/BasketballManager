import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/player_page.dart'; // Adjust the import to match where your Team and Player classes are

class TeamViewPage extends StatelessWidget {
  final Team team;

  TeamViewPage({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${team.name}'),
        backgroundColor: const Color.fromARGB(255, 49, 1, 57),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${team.name}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[50],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reputation: ${team.reputation}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.purple[50],
                        ),
                  ),
                  Text(
                    'Player Count: ${team.playerCount}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.purple[50],
                        ),
                  ),
                  Text(
                    'Team Size: ${team.teamSize}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.purple[50],
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // List of Players
            Expanded(
              child: ListView.builder(
                itemCount: team.players.length,
                itemBuilder: (context, index) {
                  Player player = team.players[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return PlayerPage(player: player);
                            },
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.purple[50],
                        child: Text(
                          player.name.substring(0, 1),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
                        ),
                      ),
                      title: Text(
                        player.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[50]),
                      ),
                      subtitle: Text(
                        'Age: ${player.age}\nNationality: ${player.nationality}\nExperience: ${player.experienceYears} years',
                        style: TextStyle(color: Colors.purple[50]),
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
