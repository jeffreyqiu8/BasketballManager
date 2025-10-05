import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/conference_class.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/team_class.dart';
import 'package:BasketballManager/views/pages/team_profile_page.dart';

class ConferenceStandingsPage extends StatefulWidget {
  final Conference conference;

  const ConferenceStandingsPage({super.key, required this.conference});

  @override
  State<ConferenceStandingsPage> createState() => _ConferenceStandingsPageState();
}

class _ConferenceStandingsPageState extends State<ConferenceStandingsPage> {
  String _sortColumn = 'winPercentage';
  bool _sortAscending = false;
  String _selectedView = 'overall'; // 'overall', 'division'
  String? _selectedTeam;
  late EnhancedConference _enhancedConference;

  @override
  void initState() {
    super.initState();
    // Convert base conference to enhanced conference
    _enhancedConference = _createEnhancedConference();
    // Update standings when page loads
    _enhancedConference.updateStandings();
  }

  EnhancedConference _createEnhancedConference() {
    return EnhancedConference(
      name: widget.conference.name,
    )..teams = widget.conference.teams
     ..schedule = widget.conference.schedule
     ..matchday = widget.conference.matchday;
  }

  List<StandingsEntry> get _sortedStandings {
    List<StandingsEntry> standings = List.from(_enhancedConference.standings.entries);
    
    standings.sort((a, b) {
      int comparison = 0;
      
      switch (_sortColumn) {
        case 'team':
          comparison = a.teamName.compareTo(b.teamName);
          break;
        case 'wins':
          comparison = a.wins.compareTo(b.wins);
          break;
        case 'losses':
          comparison = a.losses.compareTo(b.losses);
          break;
        case 'winPercentage':
          comparison = a.winPercentage.compareTo(b.winPercentage);
          break;
        case 'pointsDifferential':
          comparison = a.pointsDifferential.compareTo(b.pointsDifferential);
          break;
        case 'streak':
          comparison = a.streak.compareTo(b.streak);
          break;
        case 'divisionRecord':
          comparison = a.divisionRecord.compareTo(b.divisionRecord);
          break;
        case 'conferenceRecord':
          comparison = a.conferenceRecord.compareTo(b.conferenceRecord);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return standings;
  }

  Map<String, List<StandingsEntry>> get _divisionStandings {
    return _enhancedConference.getDivisionStandings();
  }

  void _sortBy(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '${_enhancedConference.name} Standings',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    'Overall',
                    'overall',
                    _selectedView == 'overall',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _viewToggleButton(
                    'By Division',
                    'division',
                    _selectedView == 'division',
                  ),
                ),
              ],
            ),
          ),
          
          // Standings Content
          Expanded(
            child: _selectedView == 'overall' 
              ? _buildOverallStandings() 
              : _buildDivisionStandings(),
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
      child: Text(label),
    );
  }

  Widget _buildOverallStandings() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Standings Table
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[850]?.withValues(alpha: 0.7),
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
              children: [
                // Header
                _buildStandingsHeader(),
                // Standings Rows
                ..._sortedStandings.asMap().entries.map((entry) {
                  int index = entry.key;
                  StandingsEntry standing = entry.value;
                  return _buildStandingsRow(standing, index + 1);
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDivisionStandings() {
    return SingleChildScrollView(
      child: Column(
        children: _divisionStandings.entries.map((entry) {
          String divisionName = entry.key;
          List<StandingsEntry> divisionTeams = entry.value;
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[850]?.withValues(alpha: 0.7),
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
              children: [
                // Division Header
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
                        '$divisionName Division',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Division Teams
                ...divisionTeams.asMap().entries.map((teamEntry) {
                  int index = teamEntry.key;
                  StandingsEntry standing = teamEntry.value;
                  return _buildStandingsRow(standing, index + 1, isDivision: true);
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 82, 50, 168),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30), // Rank space
          Expanded(
            flex: 3,
            child: _sortableHeader('Team', 'team'),
          ),
          Expanded(
            flex: 1,
            child: _sortableHeader('W', 'wins'),
          ),
          Expanded(
            flex: 1,
            child: _sortableHeader('L', 'losses'),
          ),
          Expanded(
            flex: 2,
            child: _sortableHeader('PCT', 'winPercentage'),
          ),
          Expanded(
            flex: 2,
            child: _sortableHeader('DIFF', 'pointsDifferential'),
          ),
          Expanded(
            flex: 2,
            child: _sortableHeader('STRK', 'streak'),
          ),
        ],
      ),
    );
  }

  Widget _sortableHeader(String title, String column) {
    bool isCurrentSort = _sortColumn == column;
    
    return GestureDetector(
      onTap: () => _sortBy(column),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (isCurrentSort) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingsRow(StandingsEntry standing, int rank, {bool isDivision = false}) {
    bool isSelected = _selectedTeam == standing.teamName;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTeam = isSelected ? null : standing.teamName;
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
                standing.teamName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            // Wins
            Expanded(
              flex: 1,
              child: Text(
                '${standing.wins}',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // Losses
            Expanded(
              flex: 1,
              child: Text(
                '${standing.losses}',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // Win Percentage
            Expanded(
              flex: 2,
              child: Text(
                standing.winPercentage.toStringAsFixed(3),
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // Points Differential
            Expanded(
              flex: 2,
              child: Text(
                standing.pointsDifferential >= 0 
                  ? '+${standing.pointsDifferential.toStringAsFixed(1)}'
                  : standing.pointsDifferential.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  color: standing.pointsDifferential >= 0 
                    ? Colors.green[400] 
                    : Colors.red[400],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Streak
            Expanded(
              flex: 2,
              child: Text(
                standing.streak,
                style: TextStyle(
                  fontSize: 14,
                  color: standing.streak.startsWith('W') 
                    ? Colors.green[400] 
                    : Colors.red[400],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank <= 4) return Colors.green[400]!; // Playoff teams
    if (rank <= 8) return Colors.orange[400]!; // Play-in teams
    return Colors.grey[400]!; // Non-playoff teams
  }

  Widget _buildTeamDetailsPanel() {
    StandingsEntry? selectedStanding = _enhancedConference.standings.entries
        .where((entry) => entry.teamName == _selectedTeam)
        .firstOrNull;
    
    if (selectedStanding == null) return const SizedBox.shrink();
    
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
                selectedStanding.teamName,
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
          Row(
            children: [
              Expanded(
                child: _statCard('Record', '${selectedStanding.wins}-${selectedStanding.losses}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard('Win %', selectedStanding.winPercentage.toStringAsFixed(3)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard('Streak', selectedStanding.streak),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _statCard('Pts Diff', 
                  selectedStanding.pointsDifferential >= 0 
                    ? '+${selectedStanding.pointsDifferential.toStringAsFixed(1)}'
                    : selectedStanding.pointsDifferential.toStringAsFixed(1)
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard('Div Record', selectedStanding.divisionRecord),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statCard('Conf Record', selectedStanding.conferenceRecord),
              ),
            ],
          ),
          
          // Additional Stats if available
          if (stats != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),
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