import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../services/league_service.dart';
import '../utils/app_theme.dart';
import '../utils/playoff_seeding.dart';
import 'team_page.dart';

/// League standings page showing all 30 teams ranked by record
/// Displays Eastern and Western Conference standings separately
class LeagueStandingsPage extends StatefulWidget {
  final LeagueService leagueService;
  final Season season;
  final String userTeamId;

  const LeagueStandingsPage({
    super.key,
    required this.leagueService,
    required this.season,
    required this.userTeamId,
  });

  @override
  State<LeagueStandingsPage> createState() => _LeagueStandingsPageState();
}

class _LeagueStandingsPageState extends State<LeagueStandingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, TeamRecord> _teamRecords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateStandings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateStandings() {
    final teams = widget.leagueService.getAllTeams();
    final records = <String, TeamRecord>{};

    // Use league schedule if available, otherwise fall back to user's games
    final gamesToAnalyze = widget.season.leagueSchedule != null
        ? widget.season.leagueSchedule!.allGames
        : widget.season.games;

    // DEBUG: Log standings calculation
    print('=== STANDINGS CALCULATION DEBUG ===');
    print('Total games in source: ${gamesToAnalyze.length}');
    final playedGames = gamesToAnalyze.where((g) => g.isPlayed).length;
    print('Games played: $playedGames');
    print('Using league schedule: ${widget.season.leagueSchedule != null}');

    // Calculate record for each team based on games
    for (var team in teams) {
      int wins = 0;
      int losses = 0;

      // Count wins and losses from all games
      for (var game in gamesToAnalyze) {
        if (!game.isPlayed) continue;

        if (game.homeTeamId == team.id) {
          if (game.homeTeamWon) {
            wins++;
          } else if (game.awayTeamWon) {
            losses++;
          }
          // If neither won, it's a tie (shouldn't happen in basketball)
        } else if (game.awayTeamId == team.id) {
          if (game.awayTeamWon) {
            wins++;
          } else if (game.homeTeamWon) {
            losses++;
          }
          // If neither won, it's a tie (shouldn't happen in basketball)
        }
      }

      final winPercentage = (wins + losses) > 0 ? wins / (wins + losses) : 0.0;
      final conference = PlayoffSeeding.getConference(team);

      records[team.id] = TeamRecord(
        team: team,
        wins: wins,
        losses: losses,
        winPercentage: winPercentage,
        conference: conference,
      );
    }

    // DEBUG: Log user team record
    final userRecord = records[widget.userTeamId];
    if (userRecord != null) {
      print('\n=== USER TEAM RECORD ===');
      print('Team: ${userRecord.team.city} ${userRecord.team.name}');
      print('Record: ${userRecord.wins}-${userRecord.losses}');
      print('Win %: ${(userRecord.winPercentage * 100).toStringAsFixed(1)}%');
      print('Conference: ${userRecord.conference}');
    }
    print('=== END STANDINGS DEBUG ===\n');

    setState(() {
      _teamRecords = records;
    });
  }


  List<TeamRecord> _getConferenceStandings(String conference) {
    final conferenceTeams = _teamRecords.values
        .where((record) => record.conference == conference)
        .toList();

    // Sort by wins (descending), then by win percentage, then by team name
    conferenceTeams.sort((a, b) {
      if (a.wins != b.wins) {
        return b.wins.compareTo(a.wins);
      }
      if (a.winPercentage != b.winPercentage) {
        return b.winPercentage.compareTo(a.winPercentage);
      }
      // Use team name as final tiebreaker for stable sorting
      return '${a.team.city} ${a.team.name}'.compareTo('${b.team.city} ${b.team.name}');
    });

    // DEBUG: Log standings positions for comparison with playoff seedings
    if (widget.season.isPostSeason && widget.season.playoffBracket != null) {
      print('=== STANDINGS VS SEEDING COMPARISON ($conference) ===');
      for (int i = 0; i < conferenceTeams.length; i++) {
        final record = conferenceTeams[i];
        final standingsPosition = i + 1;
        final playoffSeed = widget.season.playoffBracket!.teamSeedings[record.team.id];
        final teamName = '${record.team.city} ${record.team.name}';
        
        if (playoffSeed != null && playoffSeed != standingsPosition) {
          print('  MISMATCH: $teamName - Standings: #$standingsPosition, Playoff Seed: #$playoffSeed (${record.wins}-${record.losses})');
        } else if (record.team.id == widget.userTeamId) {
          print('  USER TEAM: $teamName - Standings: #$standingsPosition, Playoff Seed: ${playoffSeed ?? "N/A"} (${record.wins}-${record.losses})');
        }
      }
      print('=== END COMPARISON ===\n');
    }

    return conferenceTeams;
  }

  List<TeamRecord> _getLeagueStandings() {
    final allTeams = _teamRecords.values.toList();

    // Sort by wins (descending), then by win percentage, then by team name
    allTeams.sort((a, b) {
      if (a.wins != b.wins) {
        return b.wins.compareTo(a.wins);
      }
      if (a.winPercentage != b.winPercentage) {
        return b.winPercentage.compareTo(a.winPercentage);
      }
      // Use team name as final tiebreaker for stable sorting
      return '${a.team.city} ${a.team.name}'.compareTo('${b.team.city} ${b.team.name}');
    });

    return allTeams;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('League Standings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Eastern Conference'),
            Tab(text: 'Western Conference'),
            Tab(text: 'League'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStandingsTable(_getConferenceStandings('east'), 'Eastern'),
          _buildStandingsTable(_getConferenceStandings('west'), 'Western'),
          _buildStandingsTable(_getLeagueStandings(), 'League'),
        ],
      ),
    );
  }

  Widget _buildStandingsTable(List<TeamRecord> standings, String conferenceName) {
    if (standings.isEmpty) {
      return const Center(
        child: Text('No standings data available'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: standings.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTableHeader();
        }

        final record = standings[index - 1];
        final rank = index;
        final isUserTeam = record.team.id == widget.userTeamId;
        final isPlayoffTeam = rank <= 10; // Top 10 make playoffs (with play-in)

        return _buildTeamRow(
          rank: rank,
          record: record,
          isUserTeam: isUserTeam,
          isPlayoffTeam: isPlayoffTeam,
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              'Rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Team',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'W',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              'L',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              'PCT',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    required int rank,
    required TeamRecord record,
    required bool isUserTeam,
    required bool isPlayoffTeam,
  }) {
    return Semantics(
      label: 'Rank $rank: ${record.team.city} ${record.team.name}, '
          '${record.wins} wins, ${record.losses} losses, '
          '${(record.winPercentage * 100).toStringAsFixed(1)} percent',
      button: true,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamPage(
                teamId: record.team.id,
                leagueService: widget.leagueService,
                season: widget.season,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isUserTeam
                ? AppTheme.primaryColor.withOpacity(0.15)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 40,
                child: Row(
                  children: [
                    Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    if (isPlayoffTeam && rank <= 6)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ),
                    if (isPlayoffTeam && rank > 6 && rank <= 10)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.play_arrow,
                          size: 12,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              // Team name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.team.city,
                      style: TextStyle(
                        fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      record.team.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: isUserTeam ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Wins
              SizedBox(
                width: 50,
                child: Text(
                  '${record.wins}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              // Losses
              SizedBox(
                width: 50,
                child: Text(
                  '${record.losses}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              // Win percentage
              SizedBox(
                width: 60,
                child: Text(
                  record.winPercentage.toStringAsFixed(3),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class to hold team record information
class TeamRecord {
  final Team team;
  final int wins;
  final int losses;
  final double winPercentage;
  final String conference;

  TeamRecord({
    required this.team,
    required this.wins,
    required this.losses,
    required this.winPercentage,
    required this.conference,
  });
}
