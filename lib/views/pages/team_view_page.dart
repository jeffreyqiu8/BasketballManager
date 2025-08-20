import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/player_page.dart';

class TeamViewPage extends StatefulWidget {
  final Team team;

  const TeamViewPage({super.key, required this.team});

  @override
  State<TeamViewPage> createState() => _TeamViewPageState();
}

class _TeamViewPageState extends State<TeamViewPage> {
  static const positionLabels = ['PG', 'SG', 'SF', 'PF', 'C'];

  void _editLineup() {
    List<Player> selectedStarters = List.from(widget.team.starters);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Select Starters (5)',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...widget.team.players.map((player) {
                      bool isStarter = selectedStarters.contains(player);
                      return ListTile(
                        onTap: () {
                          setModalState(() {
                            if (isStarter) {
                              selectedStarters.remove(player);
                            } else if (selectedStarters.length < 5) {
                              selectedStarters.add(player);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: isStarter ? Colors.amber : const Color(0xFF444444),
                          child: Text(player.name[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(player.name, style: const TextStyle(color: Colors.white)),
                        trailing: isStarter
                            ? const Icon(Icons.check_circle, color: Colors.amber)
                            : const Icon(Icons.circle_outlined, color: Colors.white24),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedStarters.length == 5) {
                          setState(() {
                            widget.team.starters = List.from(selectedStarters);
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save Lineup'),
                    ),
                  ],
                ),
              ),
            ),
          );

        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final starters = widget.team.starters;
    final benchPlayers = widget.team.players.where((p) => !starters.contains(p)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.team.name),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.amber),
            onPressed: _editLineup,
            tooltip: 'Edit Lineup',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Roster',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (starters.isNotEmpty) ...[
                    sectionHeader('Starters'),
                    ...starters.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final player = entry.value;
                        final label = index < positionLabels.length ? positionLabels[index] : '';
                        return playerTile(context, player, isStarter: true, positionLabel: label);
                      },
                    ),
                  ],
                  if (benchPlayers.isNotEmpty) ...[
                    sectionHeader('Bench'),
                    ...benchPlayers.map(
                      (player) => playerTile(context, player),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget teamInfoCard() {
    final team = widget.team;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(team.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
          const SizedBox(height: 10),
          //Text('Reputation: ${team.reputation}', style: const TextStyle(color: Colors.grey)),
          Text('Player Count: ${team.playerCount}', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.amberAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget playerTile(BuildContext context, Player player, {bool isStarter = false, String positionLabel = ''}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: isStarter ? Border.all(color: Colors.amberAccent, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlayerPage(player: player)),
          );
        },
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF3A3A3A),
          child: Text(
            player.name[0],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Text(
              player.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            if (isStarter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  positionLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Text(
          'Age: ${player.age}  •  Exp: ${player.experienceYears} yrs\nNationality: ${player.nationality}',
          style: const TextStyle(color: Colors.grey, height: 1.4),
        ),
      ),
    );
  }
}
