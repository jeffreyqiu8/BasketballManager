import 'package:flutter/material.dart';
import 'package:test1/gameData/game_class.dart';
import 'package:test1/gameData/team_class.dart';
import 'package:test1/views/pages/team_profile_page.dart';

class HomePage extends StatefulWidget {
  final Game game;  // This is the object the widget will accept

  const HomePage({Key? key, required this.game}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Team getManagedTeam() {
    return widget.game.currentConference.teams[widget.game.currentManager.team];
  }

  // Method to get the current matchup for the manager's team
  Map<String, dynamic>? getCurrentMatchup(Team managedTeam) {
    try {
      return widget.game.currentConference.schedule.firstWhere(
        (match) =>
            (match['home'] == managedTeam.name || match['away'] == managedTeam.name) &&
            match['matchday'] == widget.game.currentConference.matchday,
        orElse: () => {} // Return an empty map if no match is found
      );
    } catch (e) {
      print("Error fetching current matchup: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Team managedTeam = getManagedTeam();
    Map<String, dynamic>? currentMatchup = getCurrentMatchup(managedTeam);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Info Card
            GestureDetector(
              onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return TeamProfilePage(team: managedTeam);
                            },
                          ),
                        );
                      },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        managedTeam.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10, width: double.infinity),
                      Text(
                        'Record: ${managedTeam.wins} Wins, ${managedTeam.losses} Losses',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Current Matchup Section
            Text(
              'Current Matchup:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            currentMatchup != null && currentMatchup.isNotEmpty
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${currentMatchup['home']} vs ${currentMatchup['away']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10, width: double.infinity),
                          Text(
                            'Matchday: ${currentMatchup['matchday']}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No matchup available',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
            SizedBox(height: 20),

            // Match History Button
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to the match history page
                widget.game.currentConference.playNextMatchday();
                setState(() {
                });
              },
              icon: Icon(Icons.history),
              label: Text('Play Next Game'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to the match history page
                widget.game.currentConference.generateSchedule();
                setState(() {
                });
              },
              icon: Icon(Icons.history),
              label: Text('Regen Schedule'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              
            ),
          
          ],
        ),
      ),
    );
  }
}
