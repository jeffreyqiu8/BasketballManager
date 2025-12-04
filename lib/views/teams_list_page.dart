import 'package:flutter/material.dart';
import '../models/team.dart';
import '../services/league_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'team_overview_page.dart';

/// Page to display all 30 teams in the league
class TeamsListPage extends StatefulWidget {
  const TeamsListPage({super.key});

  @override
  State<TeamsListPage> createState() => _TeamsListPageState();
}

class _TeamsListPageState extends State<TeamsListPage> {
  final LeagueService _leagueService = LeagueService();
  bool _isLoading = true;
  List<Team> _teams = [];

  @override
  void initState() {
    super.initState();
    _initializeLeague();
  }

  Future<void> _initializeLeague() async {
    setState(() {
      _isLoading = true;
    });

    await _leagueService.initializeLeague();

    setState(() {
      _teams = _leagueService.getAllTeams();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Teams'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading teams')
          : _buildTeamsList(),
    );
  }

  Widget _buildTeamsList() {
    return Semantics(
      label: 'List of ${_teams.length} teams in the league',
      child: ListView.builder(
        itemCount: _teams.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final team = _teams[index];
          return _buildTeamCard(team);
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
    return Semantics(
      label: '${team.city} ${team.name}, overall rating ${team.teamRating}, ${team.players.length} players. Tap to view team details.',
      button: true,
      hint: 'Opens team roster and lineup management',
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXSmall, horizontal: AppTheme.spacingSmall),
        elevation: AppTheme.cardElevationMedium,
        child: ListTile(
          leading: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return CircleAvatar(
                backgroundColor: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
                child: Text(
                  team.city.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          title: Text(
            '${team.city} ${team.name}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Overall: ${team.teamRating} • ${team.players.length} Players',
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
              );
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamOverviewPage(
                  teamId: team.id,
                  leagueService: _leagueService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
