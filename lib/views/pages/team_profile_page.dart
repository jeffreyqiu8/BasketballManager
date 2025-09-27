import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'player_page.dart';
import '../../gameData/enhanced_player.dart';
import '../../gameData/enhanced_team.dart';
import '../../gameData/enums.dart';
import 'role_assignment_page.dart';
import 'player_development_page.dart';
import 'playbook_manager_page.dart';
import 'coach_profile_page.dart';
import '../../gameData/enhanced_coach.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

class TeamProfilePage extends StatelessWidget {
  final Team team;

  const TeamProfilePage({super.key, required this.team});

  EnhancedTeam? get enhancedTeam => team is EnhancedTeam ? team as EnhancedTeam : null;
  
  List<EnhancedPlayer> get enhancedPlayers => 
    team.players.whereType<EnhancedPlayer>().toList();

  Map<PlayerRole, EnhancedPlayer?> getRoleAssignments() {
    final assignments = <PlayerRole, EnhancedPlayer?>{};
    for (final role in PlayerRole.values) {
      assignments[role] = null;
    }
    
    for (final player in enhancedPlayers) {
      assignments[player.primaryRole] = player;
    }
    
    return assignments;
  }

  String getPlaybookInfo() {
    if (enhancedTeam?.playbookLibrary.activePlaybook != null) {
      final playbook = enhancedTeam!.playbookLibrary.activePlaybook!;
      return '${playbook.name} (${playbook.offensiveStrategy.name})';
    }
    return 'No active playbook';
  }

  int getDevelopingPlayersCount() {
    return enhancedPlayers.where((player) => 
      player.development.totalExperience > 0 && player.age < 28
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // True dark background
      appBar: AppBar(
        title: Text(team.name),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        actions: [
          HelpButton(contextId: 'team_profile'),
          FeedbackButton(feature: 'team_profile'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏀 Team Info
            Text(
              team.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record: ${team.wins} - ${team.losses}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurpleAccent.shade100,
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Team Strategy & Development Overview
            if (enhancedTeam != null) ...[
              _buildInfoCard(
                title: 'Team Strategy',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active Playbook:',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        AccessibleButton(
                          text: 'Manage',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaybookManagerPage(
                                  team: enhancedTeam!,
                                  initialLibrary: enhancedTeam!.playbookLibrary,
                                ),
                              ),
                            );
                          },
                          semanticLabel: 'Manage team playbooks',
                        ),
                      ],
                    ),
                    Text(
                      getPlaybookInfo(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              _buildInfoCard(
                title: 'Player Development',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Developing Players: ${getDevelopingPlayersCount()}/${enhancedPlayers.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        AccessibleButton(
                          text: 'View',
                          onPressed: () {
                            if (enhancedPlayers.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerDevelopmentPage(player: enhancedPlayers.first),
                                ),
                              );
                            }
                          },
                          semanticLabel: 'View player development details',
                        ),
                      ],
                    ),
                    Text(
                      'Young players under 28 with active development',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 🔹 Coaching Staff
              _buildInfoCard(
                title: 'Coaching Staff',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Head Coach:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        AccessibleButton(
                          text: 'Manage',
                          onPressed: () {
                            // Create a default coach if none exists
                            final coach = CoachProfile(
                              name: 'Head Coach',
                              age: 45,
                              team: 0, // Default team ID
                              experienceYears: 10,
                              nationality: 'USA',
                              currentStatus: 'Active',
                              primarySpecialization: CoachingSpecialization.offensive,
                              secondarySpecialization: CoachingSpecialization.defensive,
                              achievements: [],
                              experienceLevel: 5,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CoachProfilePage(coach: coach),
                              ),
                            );
                          },
                          semanticLabel: 'Manage coaching staff',
                        ),
                      ],
                    ),
                    Text(
                      'Manage your coaching staff and development programs',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 🔹 Role Assignments
              _buildInfoCard(
                title: 'Starting Lineup',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Role Assignments:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        AccessibleButton(
                          text: 'Manage',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RoleAssignmentPage(
                                  team: enhancedTeam ?? EnhancedTeam(
                                    name: team.name,
                                    reputation: team.reputation,
                                    playerCount: team.playerCount,
                                    teamSize: team.teamSize,
                                    players: team.players,
                                    wins: team.wins,
                                    losses: team.losses,
                                    starters: team.starters,
                                  ),
                                  players: enhancedPlayers,
                                ),
                              ),
                            );
                          },
                          semanticLabel: 'Manage player role assignments',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...getRoleAssignments().entries.map((entry) {
                      final role = entry.key;
                      final player = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                role.abbreviation,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player?.name ?? 'Unassigned',
                                style: TextStyle(
                                  color: player != null ? Colors.white : Colors.red[400],
                                ),
                              ),
                            ),
                            if (player != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getCompatibilityColor(player.roleCompatibility),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(player.roleCompatibility * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 25),
            ],

            // 🔹 Players Section
            const Text(
              'Players',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),

            // 👥 Player List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: team.players.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                Player player = team.players[index];
                EnhancedPlayer? enhancedPlayer = player is EnhancedPlayer ? player : null;
                
                return AccessibleCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlayerPage(player: player)),
                    );
                  },
                  semanticLabel: '${player.name}, ${player.age} years old, ${player.nationality}${enhancedPlayer != null ? ', role ${enhancedPlayer.primaryRole.displayName}' : ''}',
                  semanticHint: 'Tap to view player details',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        // 🔵 Player Initials Avatar
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.deepPurpleAccent.shade200,
                          child: Text(
                            player.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // 📄 Player Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (enhancedPlayer != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[800],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        enhancedPlayer.primaryRole.abbreviation,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${player.age} yrs | ${player.nationality}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              if (enhancedPlayer != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'XP: ${enhancedPlayer.development.totalExperience} | Compatibility: ${(enhancedPlayer.roleCompatibility * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Color _getCompatibilityColor(double compatibility) {
    if (compatibility >= 0.8) return Colors.green;
    if (compatibility >= 0.6) return Colors.orange;
    return Colors.red;
  }
}