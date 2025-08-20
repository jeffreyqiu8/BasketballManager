import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/views/pages/player_page.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/team_profile_page.dart';

class HomePage extends StatefulWidget {
  final Game game;

  const HomePage({super.key, required this.game});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Team getManagedTeam() {
    return widget.game.currentConference.teams[widget.game.currentManager.team];
  }

  Map<String, dynamic>? getCurrentMatchup(Team managedTeam) {
    try {
      return widget.game.currentConference.schedule.firstWhere(
        (match) =>
            (match['home'] == managedTeam.name || match['away'] == managedTeam.name) &&
            match['matchday'] == widget.game.currentConference.matchday,
        orElse: () => {},
      );
    } catch (e) {
      print("Error fetching current matchup: $e");
      return null;
    }
  }

  List<Player> getTopPerformers(Team team, {int count = 3}) {
    List<Player> sortedPlayers = List.from(team.players);
    sortedPlayers.sort((a, b) => b.points.compareTo(a.points)); // You can change the metric here
    return sortedPlayers.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    Team managedTeam = getManagedTeam();
    Map<String, dynamic>? currentMatchup = getCurrentMatchup(managedTeam);
    List<Player> topPerformers = getTopPerformers(managedTeam);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Team Card
            _glassCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TeamProfilePage(team: managedTeam)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    managedTeam.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record: ${managedTeam.wins} Wins, ${managedTeam.losses} Losses',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Matchup Card
            Text(
              'Current Matchup',
              style: _sectionTitleStyle(),
            ),
            const SizedBox(height: 10),
            currentMatchup != null && currentMatchup.isNotEmpty
                ? _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentMatchup['home']} vs ${currentMatchup['away']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Matchday: ${currentMatchup['matchday']}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No matchup available', style: TextStyle(color: Colors.redAccent)),
                  ),

            const SizedBox(height: 25),

            // 🔹 Top Performers
            Text('Top Performers', style: _sectionTitleStyle()),
            const SizedBox(height: 10),
            Column(
              children: topPerformers.map((player) {
                return _glassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(player: player),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          player.name[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(player.points / (player.gamesPlayed != 0 ? player.gamesPlayed : 1)).toInt()} PPG | ${(player.rebounds / (player.gamesPlayed != 0 ? player.gamesPlayed : 1)).toInt()} REB | ${(player.assists / (player.gamesPlayed != 0 ? player.gamesPlayed : 1)).toInt()} AST',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }).toList(),
            ),


            const SizedBox(height: 30),

            // 🔘 Buttons
            _homeButton(
              label: 'Play Next Game',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                widget.game.currentConference.playNextMatchday();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            _homeButton(
              label: 'Regenerate Schedule',
              icon: Icons.refresh_rounded,
              onPressed: () {
                widget.game.currentConference.generateSchedule();
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Glassy Card
  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  // 🔘 Reusable Button
  Widget _homeButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 44, 44, 44),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // 🔤 Section Heading Style
  TextStyle _sectionTitleStyle() {
    return const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white);
  }
}
