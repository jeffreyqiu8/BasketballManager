import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/conference_class.dart'; // Assuming Conference is imported

class MatchHistoryPage extends StatelessWidget {
  final Conference conference;

  // Constructor for MatchHistoryPage widget
  MatchHistoryPage({Key? key, required this.conference}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: conference.schedule.length,
          itemBuilder: (context, index) {
            var game = conference.schedule[index];
            return ListTile(
              title: Text('Matchday ${game['matchday']} : ${game['home']} vs ${game['away']}'),
              subtitle: Text(
                'Score: ${game['homeScore']} - ${game['awayScore']}',
              ),
            );
          },
        ),
      ),
    );
  }
}
