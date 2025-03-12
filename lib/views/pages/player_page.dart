import 'package:flutter/material.dart';
import 'package:test1/gameData/player_class.dart';

class PlayerPage extends StatelessWidget {
  final Player player;

  // Constructor to pass the Player data
  PlayerPage({required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Player's general information
              _buildSectionTitle("General Info"),
              _buildInfoRow("Age", player.age.toString()),
              _buildInfoRow("Team", player.team),
              _buildInfoRow("Experience", "${player.experienceYears} years"),
              _buildInfoRow("Nationality", player.nationality),
              _buildInfoRow("Status", player.currentStatus),
              SizedBox(height: 20),

              // Player's physical attributes
              _buildSectionTitle("Physical Attributes"),
              _buildInfoRow("Height", "${player.height} cm"),

              // Player's gameplay attributes
              _buildSectionTitle("Gameplay Attributes"),
              _buildInfoRow("Shooting", player.shooting.toString()),
              _buildInfoRow("Rebounding", player.rebounding.toString()),
              _buildInfoRow("Passing", player.passing.toString()),
              _buildInfoRow("Ball Handling", player.ballHandling.toString()),
              _buildInfoRow("Perimeter Defense", player.perimeterDefense.toString()),
              _buildInfoRow("Post Defense", player.postDefense.toString()),
              _buildInfoRow("Inside Shooting", player.insideShooting.toString()),
              SizedBox(height: 20),

              // Player's performance history (if available)
              _buildSectionTitle("Performance History"),
              ..._buildPerformanceRows(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build a section title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper function to build individual info rows
  Widget _buildInfoRow(String label, String value) {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(label, style: TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Helper function to build performance rows
  List<Widget> _buildPerformanceRows() {
    List<Widget> rows = [];
    for (var matchday in player.performances.keys) {
      var performance = player.performances[matchday];
      if (performance != null) {
        rows.add(
          _buildPerformanceRow(matchday, performance),
        );
      }
    }
    return rows;
  }

  // Helper function to display performance stats in a table format
// Helper function to display performance stats in a more visually appealing layout
Widget _buildPerformanceRow(int matchday, Map<String, int> performance) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Card(
      elevation: 4, // Adds a subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      color: const Color.fromARGB(255, 72, 38, 89),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Matchday Header
            Text(
              "Matchday $matchday",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            SizedBox(height: 12), // Add space between header and stats

            // Points, Rebounds, Assists
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn("Points", "${performance['points']}"),
                _buildStatColumn("Rebounds", "${performance['rebounds']}"),
                _buildStatColumn("Assists", "${performance['assists']}"),
              ],
            ),
            SizedBox(height: 12), // Add space between stats and shooting info

            // Shooting Info (FG and 3PT)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn("FG", "${performance['FGM']}/${performance['FGA']}"),
                _buildStatColumn("FG%", "${performance['FG%']}%"),
                _buildStatColumn("3PT", "${performance['3PM']}/${performance['3PA']}"),
                _buildStatColumn("3PT%", "${performance['3PT%']}%"),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper function to build a stat column with label and value
Widget _buildStatColumn(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: const Color.fromARGB(255, 255, 255, 255)),
      ),
      SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
      ),
    ],
  );
}

}
