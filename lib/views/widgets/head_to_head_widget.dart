import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/game_result.dart';
import 'package:BasketballManager/gameData/match_history_service.dart';

class HeadToHeadWidget extends StatefulWidget {
  final String? teamName;
  final List<GameResult> allGames;

  const HeadToHeadWidget({
    super.key,
    this.teamName,
    required this.allGames,
  });

  @override
  State<HeadToHeadWidget> createState() => _HeadToHeadWidgetState();
}

class _HeadToHeadWidgetState extends State<HeadToHeadWidget> {
  final MatchHistoryService _matchHistoryService = MatchHistoryService();
  String? _selectedOpponent;
  List<GameResult> _headToHeadGames = [];
  Map<String, dynamic> _rivalryStats = {};
  bool _isLoading = false;
  
  List<String> _availableOpponents = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableOpponents();
  }

  void _loadAvailableOpponents() {
    if (widget.teamName == null) {
      // For league-wide view, show all teams
      final allTeams = <String>{};
      for (final game in widget.allGames) {
        allTeams.add(game.homeTeam);
        allTeams.add(game.awayTeam);
      }
      _availableOpponents = allTeams.toList()..sort();
    } else {
      // For team-specific view, show opponents
      final opponents = <String>{};
      for (final game in widget.allGames) {
        if (game.homeTeam == widget.teamName) {
          opponents.add(game.awayTeam);
        } else if (game.awayTeam == widget.teamName) {
          opponents.add(game.homeTeam);
        }
      }
      _availableOpponents = opponents.toList()..sort();
    }
  }

  Future<void> _loadHeadToHeadData(String opponent) async {
    if (widget.teamName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final games = await _matchHistoryService.getHeadToHeadHistory(
        widget.teamName!,
        opponent,
      );
      
      final stats = _calculateRivalryStats(games, opponent);

      setState(() {
        _headToHeadGames = games;
        _rivalryStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading head-to-head data: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateRivalryStats(List<GameResult> games, String opponent) {
    if (games.isEmpty || widget.teamName == null) {
      return {};
    }

    int wins = 0;
    int losses = 0;
    int homeWins = 0;
    int homeLosses = 0;
    int awayWins = 0;
    int awayLosses = 0;
    int totalPointsScored = 0;
    int totalPointsAllowed = 0;
    int playoffMeetings = 0;
    int playoffWins = 0;

    GameResult? lastMeeting;
    int currentStreak = 0;
    String? streakType;

    // Sort games by date (most recent first)
    final sortedGames = List<GameResult>.from(games)
      ..sort((a, b) => b.gameDate.compareTo(a.gameDate));

    for (int i = 0; i < sortedGames.length; i++) {
      final game = sortedGames[i];
      final isWin = game.getResultForTeam(widget.teamName!) == 'W';
      final isHome = game.isHomeGameForTeam(widget.teamName!);

      if (isWin) {
        wins++;
        if (isHome) {
          homeWins++;
        } else {
          awayWins++;
        }
      } else {
        losses++;
        if (isHome) {
          homeLosses++;
        } else {
          awayLosses++;
        }
      }

      // Calculate points
      if (isHome) {
        totalPointsScored += game.homeScore;
        totalPointsAllowed += game.awayScore;
      } else {
        totalPointsScored += game.awayScore;
        totalPointsAllowed += game.homeScore;
      }

      // Playoff meetings
      if (game.isPlayoffGame) {
        playoffMeetings++;
        if (isWin) playoffWins++;
      }

      // Track current streak
      if (i == 0) {
        lastMeeting = game;
        streakType = isWin ? 'W' : 'L';
        currentStreak = 1;
      } else if ((isWin && streakType == 'W') || (!isWin && streakType == 'L')) {
        currentStreak++;
      } else {
        // Streak broken, don't continue counting
      }
    }

    final totalGames = games.length;
    
    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'winPercentage': totalGames > 0 ? (wins / totalGames * 100) : 0.0,
      'homeRecord': '$homeWins-$homeLosses',
      'awayRecord': '$awayWins-$awayLosses',
      'averagePointsScored': totalGames > 0 ? totalPointsScored / totalGames : 0.0,
      'averagePointsAllowed': totalGames > 0 ? totalPointsAllowed / totalGames : 0.0,
      'playoffMeetings': playoffMeetings,
      'playoffWins': playoffWins,
      'lastMeeting': lastMeeting,
      'currentStreak': currentStreak,
      'streakType': streakType,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOpponentSelector(),
          const SizedBox(height: 16),
          if (_selectedOpponent != null) ...[
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_headToHeadGames.isNotEmpty) ...[
              _buildRivalryOverview(),
              const SizedBox(height: 16),
              _buildRecentMeetings(),
              const SizedBox(height: 16),
              _buildRivalryBreakdown(),
            ] else
              _buildNoDataMessage(),
          ] else
            _buildSelectOpponentMessage(),
        ],
      ),
    );
  }

  Widget _buildOpponentSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.teamName != null 
                  ? 'Select Opponent for ${widget.teamName}'
                  : 'Head-to-Head Analysis',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.teamName != null)
              DropdownButtonFormField<String>(
                value: _selectedOpponent,
                decoration: const InputDecoration(
                  labelText: 'Choose Opponent',
                  border: OutlineInputBorder(),
                ),
                items: _availableOpponents.map((opponent) {
                  return DropdownMenuItem<String>(
                    value: opponent,
                    child: Text(opponent),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOpponent = value;
                  });
                  if (value != null) {
                    _loadHeadToHeadData(value);
                  }
                },
              )
            else
              const Text(
                'Head-to-head analysis is only available when viewing a specific team\'s history.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRivalryOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${widget.teamName} vs $_selectedOpponent',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_rivalryStats['lastMeeting'] != null)
                  Text(
                    'Last: ${(_rivalryStats['lastMeeting'] as GameResult).gameDate.month}/${(_rivalryStats['lastMeeting'] as GameResult).gameDate.day}/${(_rivalryStats['lastMeeting'] as GameResult).gameDate.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Overall record
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRecordCard(
                  'Overall Record',
                  '${_rivalryStats['wins']}-${_rivalryStats['losses']}',
                  '${(_rivalryStats['winPercentage'] as double).toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildRecordCard(
                  'Current Streak',
                  '${_rivalryStats['currentStreak']} ${_rivalryStats['streakType']}',
                  _rivalryStats['streakType'] == 'W' ? 'Winning' : 'Losing',
                  _rivalryStats['streakType'] == 'W' ? Colors.green : Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Playoff record if applicable
            if (_rivalryStats['playoffMeetings'] > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Playoff Meetings',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_rivalryStats['playoffWins']}-${_rivalryStats['playoffMeetings'] - _rivalryStats['playoffWins']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(String title, String record, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMeetings() {
    final recentGames = _headToHeadGames.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Meetings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            ...recentGames.map((game) => _buildGameSummary(game)),
            
            if (_headToHeadGames.length > 5)
              TextButton(
                onPressed: () => _showAllGames(),
                child: Text('View All ${_headToHeadGames.length} Games'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameSummary(GameResult game) {
    final isWin = game.getResultForTeam(widget.teamName!) == 'W';
    final isHome = game.isHomeGameForTeam(widget.teamName!);
    final score = game.getScoreForTeam(widget.teamName!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWin ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWin ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isWin ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isWin ? 'W' : 'L',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isHome ? 'vs' : '@'} $_selectedOpponent',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  score,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${game.gameDate.month}/${game.gameDate.day}/${game.gameDate.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (game.isPlayoffGame)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Playoff',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRivalryBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rivalry Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownCard(
                    'Home Games',
                    _rivalryStats['homeRecord'],
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBreakdownCard(
                    'Away Games',
                    _rivalryStats['awayRecord'],
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildStatRow('Average Points Scored', (_rivalryStats['averagePointsScored'] as double).toStringAsFixed(1)),
            _buildStatRow('Average Points Allowed', (_rivalryStats['averagePointsAllowed'] as double).toStringAsFixed(1)),
            _buildStatRow('Point Differential', ((_rivalryStats['averagePointsScored'] as double) - (_rivalryStats['averagePointsAllowed'] as double)).toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownCard(String title, String record, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectOpponentMessage() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Select an Opponent',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Choose an opponent from the dropdown above to view head-to-head statistics and rivalry history.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No Head-to-Head Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'No games found between these teams.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllGames() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${widget.teamName} vs $_selectedOpponent - All Games',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _headToHeadGames.length,
                  itemBuilder: (context, index) {
                    return _buildGameSummary(_headToHeadGames[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}