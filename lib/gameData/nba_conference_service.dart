import 'dart:math';
import 'enhanced_conference.dart';
import 'enhanced_team.dart';
import 'nba_team_data.dart';
import 'team_class.dart';

/// Service for creating and managing realistic NBA conferences with proper scheduling
class NBAConferenceService {
  static final Random _random = Random();

  /// Create both NBA conferences with realistic structure
  static Map<String, EnhancedConference> createNBAConferences() {
    final easternConference = _createEasternConference();
    final westernConference = _createWesternConference();
    
    return {
      'Eastern': easternConference,
      'Western': westernConference,
    };
  }

  /// Create Eastern Conference with proper divisions
  static EnhancedConference _createEasternConference() {
    final nbaTeams = RealTeamData.getTeamsByConference('Eastern');
    
    // Create divisions
    final atlanticDivision = Division(
      name: 'Atlantic',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Atlantic').toList()
      ),
    );
    
    final centralDivision = Division(
      name: 'Central',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Central').toList()
      ),
    );
    
    final southeastDivision = Division(
      name: 'Southeast',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Southeast').toList()
      ),
    );

    // Combine all teams
    List<Team> allTeams = [
      ...atlanticDivision.teams,
      ...centralDivision.teams,
      ...southeastDivision.teams,
    ];

    final conference = EnhancedConference(
      name: 'Eastern Conference',
      divisions: [atlanticDivision, centralDivision, southeastDivision],
    );
    
    // Set teams manually since the constructor doesn't accept teams parameter
    conference.teams = allTeams;
    
    // Generate NBA-style schedule
    _generateNBASchedule(conference);
    
    return conference;
  }

  /// Create Western Conference with proper divisions
  static EnhancedConference _createWesternConference() {
    final nbaTeams = RealTeamData.getTeamsByConference('Western');
    
    // Create divisions
    final northwestDivision = Division(
      name: 'Northwest',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Northwest').toList()
      ),
    );
    
    final pacificDivision = Division(
      name: 'Pacific',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Pacific').toList()
      ),
    );
    
    final southwestDivision = Division(
      name: 'Southwest',
      teams: _createTeamsFromNBAData(
        nbaTeams.where((team) => team.division == 'Southwest').toList()
      ),
    );

    // Combine all teams
    List<Team> allTeams = [
      ...northwestDivision.teams,
      ...pacificDivision.teams,
      ...southwestDivision.teams,
    ];

    final conference = EnhancedConference(
      name: 'Western Conference',
      divisions: [northwestDivision, pacificDivision, southwestDivision],
    );
    
    // Set teams manually
    conference.teams = allTeams;
    
    // Generate NBA-style schedule
    _generateNBASchedule(conference);
    
    return conference;
  }

  /// Convert NBA team data to enhanced teams
  static List<Team> _createTeamsFromNBAData(List<NBATeam> nbaTeams) {
    return nbaTeams.map((nbaTeam) {
      return EnhancedTeam(
        name: nbaTeam.fullName,
        reputation: _calculateTeamReputation(nbaTeam),
        playerCount: 15, // Standard NBA roster size
        teamSize: 15,
        players: [], // Will be populated by roster generation service
        branding: nbaTeam.branding,
        conference: nbaTeam.conference,
        division: nbaTeam.division,
        history: nbaTeam.history,
      );
    }).toList();
  }

  /// Calculate team reputation based on historical success
  static int _calculateTeamReputation(NBATeam nbaTeam) {
    int baseReputation = 50;
    
    // Add reputation based on championships
    baseReputation += (nbaTeam.history.championships * 3).clamp(0, 30);
    
    // Add reputation based on playoff appearances
    baseReputation += (nbaTeam.history.playoffAppearances ~/ 2).clamp(0, 20);
    
    // Add some randomness for current form
    baseReputation += _random.nextInt(21) - 10; // -10 to +10
    
    return baseReputation.clamp(20, 100);
  }

  /// Generate NBA-style 82-game schedule with realistic distribution
  static void _generateNBASchedule(EnhancedConference conference) {
    conference.schedule.clear();
    conference.matchday = 1;
    
    List<Map<String, dynamic>> games = [];
    
    // Get divisions for this conference
    Map<String, List<Team>> divisionTeams = {};
    for (var division in conference.divisions) {
      divisionTeams[division.name] = division.teams;
    }
    
    int matchday = 1;
    
    // Generate games between all teams following NBA rules
    for (int i = 0; i < conference.teams.length; i++) {
      Team team1 = conference.teams[i];
      
      // Find team1's division
      String team1Division = '';
      for (var entry in divisionTeams.entries) {
        if (entry.value.any((t) => t.name == team1.name)) {
          team1Division = entry.key;
          break;
        }
      }
      
      for (int j = i + 1; j < conference.teams.length; j++) {
        Team team2 = conference.teams[j];
        
        // Find team2's division
        String team2Division = '';
        for (var entry in divisionTeams.entries) {
          if (entry.value.any((t) => t.name == team2.name)) {
            team2Division = entry.key;
            break;
          }
        }
        
        // Determine number of games based on division
        int numGames;
        if (team1Division == team2Division) {
          numGames = 4; // Division rivals play 4 times
        } else {
          numGames = 3; // Non-division conference teams play 3 times (some 4)
        }
        
        // Create the games
        for (int gameNum = 0; gameNum < numGames; gameNum++) {
          // Alternate home/away
          String homeTeam = (gameNum % 2 == 0) ? team1.name : team2.name;
          String awayTeam = (gameNum % 2 == 0) ? team2.name : team1.name;
          
          games.add({
            'home': homeTeam,
            'away': awayTeam,
            'homeScore': 0,
            'awayScore': 0,
            'matchday': matchday,
          });
          
          matchday++;
        }
      }
    }
    
    // Shuffle games to distribute them across matchdays more realistically
    games.shuffle(_random);
    
    // Reassign matchdays to spread games more evenly
    int totalGames = games.length;
    int gamesPerMatchday = (totalGames / 82).ceil(); // Spread across ~82 matchdays
    
    for (int i = 0; i < games.length; i++) {
      games[i]['matchday'] = (i ~/ gamesPerMatchday) + 1;
    }
    
    conference.schedule = games;
    conference.schedule.sort((a, b) => a['matchday'].compareTo(b['matchday']));
    
    // Reset team records
    for (var team in conference.teams) {
      team.resetRecord();
      team.clearTeamPerformances();
    }
  }



  /// Generate playoff bracket following NBA format
  static PlayoffBracket generateNBAPlayoffBracket(EnhancedConference conference) {
    // Update standings first
    conference.updateStandings();
    
    if (conference.standings.entries.length < 8) {
      throw Exception('Not enough teams for playoffs');
    }
    
    // Get top 8 teams
    List<StandingsEntry> playoffTeams = conference.standings.entries.take(8).toList();
    
    // Create first round matchups (1v8, 2v7, 3v6, 4v5)
    List<PlayoffMatchup> firstRound = [
      PlayoffMatchup(higherSeed: playoffTeams[0], lowerSeed: playoffTeams[7], round: 1),
      PlayoffMatchup(higherSeed: playoffTeams[1], lowerSeed: playoffTeams[6], round: 1),
      PlayoffMatchup(higherSeed: playoffTeams[2], lowerSeed: playoffTeams[5], round: 1),
      PlayoffMatchup(higherSeed: playoffTeams[3], lowerSeed: playoffTeams[4], round: 1),
    ];
    
    return PlayoffBracket(
      firstRound: firstRound,
      semifinals: [],
      finals: null,
      champion: null,
    );
  }

  /// Simulate playoff series (best of 7)
  static void simulatePlayoffSeries(PlayoffMatchup matchup) {
    while (!matchup.isComplete && matchup.higherSeedWins < 4 && matchup.lowerSeedWins < 4) {
      // Simulate one game
      bool higherSeedWins = _simulatePlayoffGame(matchup.higherSeed, matchup.lowerSeed);
      
      if (higherSeedWins) {
        matchup.higherSeedWins++;
      } else {
        matchup.lowerSeedWins++;
      }
    }
    
    // Determine winner
    if (matchup.higherSeedWins == 4) {
      matchup.winner = matchup.higherSeed;
    } else {
      matchup.winner = matchup.lowerSeed;
    }
    
    matchup.isComplete = true;
  }

  /// Simulate a single playoff game
  static bool _simulatePlayoffGame(StandingsEntry higherSeed, StandingsEntry lowerSeed) {
    // Higher seed has slight advantage (55% chance to win)
    double higherSeedAdvantage = 0.55;
    
    // Adjust based on win percentage difference
    double winPercentageDiff = higherSeed.winPercentage - lowerSeed.winPercentage;
    higherSeedAdvantage += (winPercentageDiff * 0.3); // Scale the advantage
    
    // Clamp between 0.3 and 0.8 to keep games competitive
    higherSeedAdvantage = higherSeedAdvantage.clamp(0.3, 0.8);
    
    return _random.nextDouble() < higherSeedAdvantage;
  }

  /// Calculate division-based scheduling weights
  static Map<String, int> calculateSchedulingWeights(Team team, List<Team> allTeams, Map<String, List<Team>> divisionTeams) {
    Map<String, int> weights = {};
    
    // Find team's division
    String teamDivision = '';
    for (var entry in divisionTeams.entries) {
      if (entry.value.any((t) => t.name == team.name)) {
        teamDivision = entry.key;
        break;
      }
    }
    
    for (var opponent in allTeams) {
      if (opponent.name == team.name) continue;
      
      // Check if opponent is in same division
      bool sameDiv = false;
      for (var divTeam in divisionTeams[teamDivision] ?? []) {
        if (divTeam.name == opponent.name) {
          sameDiv = true;
          break;
        }
      }
      
      // Division rivals get more games
      weights[opponent.name] = sameDiv ? 4 : 6; // 4 vs division, 6-7 vs conference
    }
    
    return weights;
  }
}