import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/conference_class.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/team_profile_page.dart';

class EnhancedSchedulePage extends StatefulWidget {
  final Conference conference;

  const EnhancedSchedulePage({super.key, required this.conference});

  @override
  State<EnhancedSchedulePage> createState() => _EnhancedSchedulePageState();
}

class _EnhancedSchedulePageState extends State<EnhancedSchedulePage> {
  String _selectedView = 'schedule'; // 'schedule', 'statistics', 'playoffs'
  String? _selectedTeam;
  int _selectedMatchday = 1;
  late EnhancedConference _enhancedConference;

  @override
  void initState() {
    super.initState();
    // Convert base conference to enhanced conference
    _enhancedConference = _createEnhancedConference();
    _enhancedConference.updateStandings();
    _selectedMatchday = _enhancedConference.matchday;
  }

  EnhancedConference _createEnhancedConference() {
    EnhancedConference enhanced = EnhancedConference(
      name: widget.conference.name,
    )..teams = widget.conference.teams
     ..schedule = widget.conference.schedule
     ..matchday = widget.conference.matchday;
    
    // Populate basic team statistics if they don't exist
    for (var team in enhanced.teams) {
      if (!enhanced.teamStatistics.containsKey(team.name)) {
        enhanced.teamStatistics[team.name] = TeamStats(
          pointsFor: 100.0 + (team.wins * 5.0), // Basic calculation
          pointsAgainst: 95.0 + (team.losses * 3.0),
          fieldGoalPercentage: 0.45 + (team.wins * 0.01),
          threePointPercentage: 0.35,
          freeThrowPercentage: 0.75,
          reboundsPerGame: 45.0,
          assistsPerGame: 25.0,
          turnoversPerGame: 15.0,
          stealsPerGame: 8.0,
          blocksPerGame: 5.0,
        );
      }
    }
    
    return enhanced;
  }



  List<Map<String, dynamic>> get _upcomingGames {
    return _enhancedConference.schedule
        .where((game) => game['matchday'] >= _enhancedConference.matchday)
        .take(10)
        .toList();
  }

  List<Map<String, dynamic>> get _recentGames {
    return _enhancedConference.schedule
        .where((game) => 
            game['matchday'] < _enhancedConference.matchday && 
            game['homeScore'] > 0)
        .toList()
        .reversed
        .take(10)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '${_enhancedConference.name} Schedule & Stats',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _enhancedConference.updateStandings();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // View Toggle
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _viewToggleButton(
                    'Schedule',
                    'schedule',
                    _selectedView == 'schedule',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _viewToggleButton(
                    'Statistics',
                    'statistics',
                    _selectedView == 'statistics',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _viewToggleButton(
                    'Playoffs',
                    'playoffs',
                    _selectedView == 'playoffs',
                  ),
                ),
              ],
            ),
          ),
          
          // Content based on selected view
          Expanded(
            child: _buildSelectedView(),
          ),
          
          // Team Details Panel
          if (_selectedTeam != null) _buildTeamDetailsPanel(),
        ],
      ),
    );
  }

  Widget _viewToggleButton(String label, String value, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedView = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
          ? const Color.fromARGB(255, 82, 50, 168)
          : const Color.fromARGB(255, 44, 44, 44),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case 'schedule':
        return _buildScheduleView();
      case 'statistics':
        return _buildStatisticsView();
      case 'playoffs':
        return _buildPlayoffsView();
      default:
        return _buildScheduleView();
    }
  }

  Widget _buildScheduleView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Team Filter
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Filter by team:',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedTeam,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Teams'),
                      ),
                      ..._enhancedConference.teams.map((team) =>
                        DropdownMenuItem<String?>(
                          value: team.name,
                          child: Text(team.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTeam = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Recent Games Section
          if (_recentGames.isNotEmpty) ...[
            _buildSectionHeader('Recent Games'),
            _buildGamesList(_recentGames, isCompleted: true),
          ],
          
          // Upcoming Games Section
          if (_upcomingGames.isNotEmpty) ...[
            _buildSectionHeader('Upcoming Games'),
            _buildGamesList(_upcomingGames, isCompleted: false),
          ],
          
          // All Games by Matchday
          _buildSectionHeader('All Games'),
          _buildMatchdaySelector(),
          _buildMatchdayGames(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(List<Map<String, dynamic>> games, {required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: games.map((game) => _buildGameCard(game, isCompleted: isCompleted)).toList(),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, {required bool isCompleted}) {
    String homeTeam = game['home'];
    String awayTeam = game['away'];
    int homeScore = game['homeScore'] ?? 0;
    int awayScore = game['awayScore'] ?? 0;
    int matchday = game['matchday'] ?? 1;
    
    bool homeWin = homeScore > awayScore;
    bool awayWin = awayScore > homeScore;
    
    return GestureDetector(
      onTap: () {
        // Show game details or navigate to game page
        _showGameDetails(game);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Matchday
            SizedBox(
              width: 35,
              child: Text(
                'MD$matchday',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Away Team
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    awayTeam,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted && awayWin ? Colors.green[400] : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Score or VS
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCompleted) ...[
                    Flexible(
                      child: Text(
                        '$awayScore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: awayWin ? Colors.green[400] : Colors.white,
                        ),
                      ),
                    ),
                    const Text(
                      ' - ',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Flexible(
                      child: Text(
                        '$homeScore',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: homeWin ? Colors.green[400] : Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'vs',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Home Team
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    homeTeam,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted && homeWin ? Colors.green[400] : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchdaySelector() {
    int totalMatchdays = _enhancedConference.teams.length - 1;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalMatchdays,
        itemBuilder: (context, index) {
          int matchday = index + 1;
          bool isSelected = matchday == _selectedMatchday;
          bool isCompleted = matchday < _enhancedConference.matchday;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMatchday = matchday;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                  ? const Color.fromARGB(255, 82, 50, 168)
                  : isCompleted 
                    ? Colors.grey[700]
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: isSelected 
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              ),
              child: Text(
                'MD $matchday',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[300],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchdayGames() {
    List<Map<String, dynamic>> matchdayGames = _enhancedConference.schedule
        .where((game) => game['matchday'] == _selectedMatchday)
        .toList();
    
    if (matchdayGames.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No games scheduled for this matchday',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }
    
    bool isCompleted = _selectedMatchday < _enhancedConference.matchday;
    
    return _buildGamesList(matchdayGames, isCompleted: isCompleted);
  }

  Widget _buildStatisticsView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // League Leaders Section
          _buildSectionHeader('League Leaders'),
          _buildLeagueLeaders(),
          
          // Team Rankings Section
          _buildSectionHeader('Team Rankings'),
          _buildTeamRankings(),
          
          // Team Comparison Section
          if (_selectedTeam != null) ...[
            _buildSectionHeader('Team Comparison'),
            _buildTeamComparison(),
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueLeaders() {
    // Calculate league leaders from team statistics
    List<MapEntry<String, TeamStats>> sortedByPPG = _enhancedConference.teamStatistics.entries
        .toList()
        ..sort((a, b) => b.value.pointsFor.compareTo(a.value.pointsFor));
    
    List<MapEntry<String, TeamStats>> sortedByDefense = _enhancedConference.teamStatistics.entries
        .toList()
        ..sort((a, b) => a.value.pointsAgainst.compareTo(b.value.pointsAgainst));
    
    List<MapEntry<String, TeamStats>> sortedByFG = _enhancedConference.teamStatistics.entries
        .toList()
        ..sort((a, b) => b.value.fieldGoalPercentage.compareTo(a.value.fieldGoalPercentage));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildLeaderCard('Points Per Game', sortedByPPG.isNotEmpty ? sortedByPPG.first : null, 'PPG'),
          _buildLeaderCard('Best Defense', sortedByDefense.isNotEmpty ? sortedByDefense.first : null, 'OPP PPG'),
          _buildLeaderCard('Field Goal %', sortedByFG.isNotEmpty ? sortedByFG.first : null, 'FG%'),
        ],
      ),
    );
  }

  Widget _buildLeaderCard(String category, MapEntry<String, TeamStats>? leader, String statType) {
    if (leader == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '$category: No data available',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    String value;
    switch (statType) {
      case 'PPG':
        value = leader.value.pointsFor.toStringAsFixed(1);
        break;
      case 'OPP PPG':
        value = leader.value.pointsAgainst.toStringAsFixed(1);
        break;
      case 'FG%':
        value = '${(leader.value.fieldGoalPercentage * 100).toStringAsFixed(1)}%';
        break;
      default:
        value = '0.0';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTeam = _selectedTeam == leader.key ? null : leader.key;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedTeam == leader.key 
            ? const Color.fromARGB(255, 82, 50, 168).withValues(alpha: 0.3)
            : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leader.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 82, 50, 168),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRankings() {
    List<MapEntry<String, TeamStats>> rankedTeams = _enhancedConference.teamStatistics.entries
        .toList()
        ..sort((a, b) => b.value.pointsFor.compareTo(a.value.pointsFor));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 82, 50, 168),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 30), // Rank space
                Expanded(
                  flex: 3,
                  child: Text(
                    'Team',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PPG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'OPP PPG',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'FG%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Team rows
          ...rankedTeams.asMap().entries.map((entry) {
            int rank = entry.key + 1;
            MapEntry<String, TeamStats> teamEntry = entry.value;
            return _buildTeamRankingRow(teamEntry.key, teamEntry.value, rank);
          }),
        ],
      ),
    );
  }

  Widget _buildTeamRankingRow(String teamName, TeamStats stats, int rank) {
    bool isSelected = _selectedTeam == teamName;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTeam = isSelected ? null : teamName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? const Color.fromARGB(255, 82, 50, 168).withValues(alpha: 0.3)
            : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[700]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
            ),
            // Team Name
            Expanded(
              flex: 3,
              child: Text(
                teamName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // PPG
            Expanded(
              flex: 2,
              child: Text(
                stats.pointsFor.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // OPP PPG
            Expanded(
              flex: 2,
              child: Text(
                stats.pointsAgainst.toStringAsFixed(1),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // FG%
            Expanded(
              flex: 2,
              child: Text(
                '${(stats.fieldGoalPercentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamComparison() {
    if (_selectedTeam == null) return const SizedBox.shrink();
    
    TeamStats? selectedStats = _enhancedConference.teamStatistics[_selectedTeam];
    if (selectedStats == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No statistics available for selected team',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    // Calculate league averages
    double avgPPG = _enhancedConference.teamStatistics.values
        .map((stats) => stats.pointsFor)
        .reduce((a, b) => a + b) / _enhancedConference.teamStatistics.length;
    
    double avgOppPPG = _enhancedConference.teamStatistics.values
        .map((stats) => stats.pointsAgainst)
        .reduce((a, b) => a + b) / _enhancedConference.teamStatistics.length;
    
    double avgFG = _enhancedConference.teamStatistics.values
        .map((stats) => stats.fieldGoalPercentage)
        .reduce((a, b) => a + b) / _enhancedConference.teamStatistics.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 82, 50, 168),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$_selectedTeam vs League Average',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Comparison rows
          _buildComparisonRow('Points Per Game', selectedStats.pointsFor, avgPPG, true),
          _buildComparisonRow('Opponent PPG', selectedStats.pointsAgainst, avgOppPPG, false),
          _buildComparisonRow('Field Goal %', selectedStats.fieldGoalPercentage * 100, avgFG * 100, true),
          _buildComparisonRow('Rebounds', selectedStats.reboundsPerGame, 0.0, true), // No league avg calculated
          _buildComparisonRow('Assists', selectedStats.assistsPerGame, 0.0, true),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String stat, double teamValue, double leagueAvg, bool higherIsBetter) {
    double difference = teamValue - leagueAvg;
    bool isAboveAverage = difference > 0;
    Color valueColor = (higherIsBetter && isAboveAverage) || (!higherIsBetter && !isAboveAverage)
        ? Colors.green[400]!
        : Colors.red[400]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stat,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              Text(
                teamValue.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              if (leagueAvg > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(${difference >= 0 ? '+' : ''}${difference.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: 12,
                    color: valueColor,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayoffsView() {
    // Generate playoff bracket if not exists
    if (_enhancedConference.playoffBracket == null) {
      _enhancedConference.generatePlayoffBracket();
    }

    PlayoffBracket? bracket = _enhancedConference.playoffBracket;
    
    if (bracket == null || bracket.firstRound.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Playoffs Not Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Complete more games to generate playoff bracket',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader('Playoff Bracket'),
          _buildPlayoffBracket(bracket),
        ],
      ),
    );
  }

  Widget _buildPlayoffBracket(PlayoffBracket bracket) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // First Round
          if (bracket.firstRound.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 82, 50, 168),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'First Round',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...bracket.firstRound.map((matchup) => _buildPlayoffMatchup(matchup)),
          ],
          
          // Semifinals
          if (bracket.semifinals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 82, 50, 168),
              ),
              child: const Row(
                children: [
                  Text(
                    'Semifinals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            ...bracket.semifinals.map((matchup) => _buildPlayoffMatchup(matchup)),
          ],
          
          // Finals
          if (bracket.finals != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 82, 50, 168),
              ),
              child: const Row(
                children: [
                  Text(
                    'Finals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            _buildPlayoffMatchup(bracket.finals!),
          ],
          
          // Champion
          if (bracket.champion != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text(
                        'CHAMPION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        bracket.champion!.teamName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayoffMatchup(PlayoffMatchup matchup) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[700]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Higher Seed
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  matchup.higherSeed.teamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: matchup.winner?.teamName == matchup.higherSeed.teamName
                        ? Colors.green[400]
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${matchup.higherSeedWins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // VS
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'vs',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Lower Seed
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${matchup.lowerSeedWins}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  matchup.lowerSeed.teamName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: matchup.winner?.teamName == matchup.lowerSeed.teamName
                        ? Colors.green[400]
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 4) return Colors.green[400]!; // Top teams
    if (rank <= 8) return Colors.orange[400]!; // Middle teams
    return Colors.grey[400]!; // Bottom teams
  }

  void _showGameDetails(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Game Details - Matchday ${game['matchday']}',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game['away'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${game['awayScore']} - ${game['homeScore']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    game['home'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color.fromARGB(255, 82, 50, 168)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTeamDetailsPanel() {
    Team? team = _enhancedConference.teams
        .where((t) => t.name == _selectedTeam)
        .firstOrNull;
    
    TeamStats? stats = _enhancedConference.teamStatistics[_selectedTeam];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedTeam!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (team != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamProfilePage(team: team),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 82, 50, 168),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: const Text('View Team', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedTeam = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Team Stats Grid
          if (team != null) ...[
            Row(
              children: [
                Expanded(
                  child: _statCard('Record', '${team.wins}-${team.losses}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('Win %', 
                    team.wins + team.losses > 0 
                      ? (team.wins / (team.wins + team.losses)).toStringAsFixed(3)
                      : '0.000'
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Additional Stats if available
          if (stats != null) ...[
            Row(
              children: [
                Expanded(
                  child: _statCard('PPG', stats.pointsFor.toStringAsFixed(1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('OPP PPG', stats.pointsAgainst.toStringAsFixed(1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('FG%', '${(stats.fieldGoalPercentage * 100).toStringAsFixed(1)}%'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}