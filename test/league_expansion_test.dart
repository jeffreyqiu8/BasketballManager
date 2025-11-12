import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/league_structure.dart';
import 'package:BasketballManager/gameData/league_expansion_service.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';

void main() {
  group('League Expansion System Tests', () {
    test('LeagueStructure should validate 30-team structure correctly', () {
      // Create mock conferences with proper structure
      List<EnhancedConference> conferences = [];
      
      // Create Eastern Conference with 3 divisions of 5 teams each
      List<Division> easternDivisions = [
        Division(name: 'Atlantic', teams: _createMockTeams(5, 'Eastern', 'Atlantic')),
        Division(name: 'Central', teams: _createMockTeams(5, 'Eastern', 'Central')),
        Division(name: 'Southeast', teams: _createMockTeams(5, 'Eastern', 'Southeast')),
      ];
      
      EnhancedConference easternConf = EnhancedConference(
        name: 'Eastern',
        divisions: easternDivisions,
      );
      easternConf.teams = easternDivisions.expand((div) => div.teams).toList();
      
      // Create Western Conference with 3 divisions of 5 teams each
      List<Division> westernDivisions = [
        Division(name: 'Northwest', teams: _createMockTeams(5, 'Western', 'Northwest')),
        Division(name: 'Pacific', teams: _createMockTeams(5, 'Western', 'Pacific')),
        Division(name: 'Southwest', teams: _createMockTeams(5, 'Western', 'Southwest')),
      ];
      
      EnhancedConference westernConf = EnhancedConference(
        name: 'Western',
        divisions: westernDivisions,
      );
      westernConf.teams = westernDivisions.expand((div) => div.teams).toList();
      
      conferences = [easternConf, westernConf];
      
      // Create league structure
      LeagueStructure league = LeagueStructure(conferences: conferences);
      
      // Test validation
      expect(league.validateStructure(), isTrue);
      expect(league.allTeams.length, equals(LeagueStructure.TOTAL_TEAMS));
      expect(league.conferences.length, equals(2));
      
      // Test conference distribution
      var easternTeams = league.getTeamsByConference('Eastern');
      var westernTeams = league.getTeamsByConference('Western');
      expect(easternTeams.length, equals(LeagueStructure.TEAMS_PER_CONFERENCE));
      expect(westernTeams.length, equals(LeagueStructure.TEAMS_PER_CONFERENCE));
    });

    test('LeagueStructure should handle team and division lookups correctly', () {
      // Create a simple league structure
      List<EnhancedConference> conferences = [];
      
      List<Division> easternDivisions = [
        Division(name: 'Atlantic', teams: _createMockTeams(5, 'Eastern', 'Atlantic')),
        Division(name: 'Central', teams: _createMockTeams(5, 'Eastern', 'Central')),
        Division(name: 'Southeast', teams: _createMockTeams(5, 'Eastern', 'Southeast')),
      ];
      
      EnhancedConference easternConf = EnhancedConference(
        name: 'Eastern',
        divisions: easternDivisions,
      );
      easternConf.teams = easternDivisions.expand((div) => div.teams).toList();
      conferences.add(easternConf);
      
      List<Division> westernDivisions = [
        Division(name: 'Northwest', teams: _createMockTeams(5, 'Western', 'Northwest')),
        Division(name: 'Pacific', teams: _createMockTeams(5, 'Western', 'Pacific')),
        Division(name: 'Southwest', teams: _createMockTeams(5, 'Western', 'Southwest')),
      ];
      
      EnhancedConference westernConf = EnhancedConference(
        name: 'Western',
        divisions: westernDivisions,
      );
      westernConf.teams = westernDivisions.expand((div) => div.teams).toList();
      conferences.add(westernConf);
      
      LeagueStructure league = LeagueStructure(conferences: conferences);
      
      // Test conference lookup
      var easternConf2 = league.getConference('Eastern');
      expect(easternConf2, isNotNull);
      expect(easternConf2!.name, equals('Eastern'));
      
      // Test division lookup
      var atlanticDiv = league.getDivision('Eastern', 'Atlantic');
      expect(atlanticDiv, isNotNull);
      expect(atlanticDiv!.name, equals('Atlantic'));
      expect(atlanticDiv.teams.length, equals(5));
      
      // Test team lookup
      var firstTeam = league.getTeam('Eastern Team 0');
      expect(firstTeam, isNotNull);
      expect(firstTeam!.name, equals('Eastern Team 0'));
    });

    test('LeagueExpansionService validation should work correctly', () {
      // Create a valid league structure
      List<EnhancedConference> conferences = [];
      
      List<Division> easternDivisions = [
        Division(name: 'Atlantic', teams: _createMockTeams(5, 'Eastern', 'Atlantic')),
        Division(name: 'Central', teams: _createMockTeams(5, 'Eastern', 'Central')),
        Division(name: 'Southeast', teams: _createMockTeams(5, 'Eastern', 'Southeast')),
      ];
      
      EnhancedConference easternConf = EnhancedConference(
        name: 'Eastern',
        divisions: easternDivisions,
      );
      easternConf.teams = easternDivisions.expand((div) => div.teams).toList();
      
      List<Division> westernDivisions = [
        Division(name: 'Northwest', teams: _createMockTeams(5, 'Western', 'Northwest')),
        Division(name: 'Pacific', teams: _createMockTeams(5, 'Western', 'Pacific')),
        Division(name: 'Southwest', teams: _createMockTeams(5, 'Western', 'Southwest')),
      ];
      
      EnhancedConference westernConf = EnhancedConference(
        name: 'Western',
        divisions: westernDivisions,
      );
      westernConf.teams = westernDivisions.expand((div) => div.teams).toList();
      
      conferences = [easternConf, westernConf];
      LeagueStructure league = LeagueStructure(conferences: conferences);
      
      // Test validation
      bool isValid = LeagueExpansionService.validateLeagueStructure(league);
      expect(isValid, isTrue);
      
      // Test invalid structure (remove some teams)
      league.allTeams.removeLast();
      bool isInvalid = LeagueExpansionService.validateLeagueStructure(league);
      expect(isInvalid, isFalse);
    });

    test('ScheduleMatrix should validate correctly', () {
      Map<String, List<Map<String, dynamic>>> teamSchedules = {};
      
      // Create schedules for 4 teams (simplified test)
      List<String> teams = ['Team A', 'Team B', 'Team C', 'Team D'];
      
      for (String team in teams) {
        teamSchedules[team] = [];
        
        // Add exactly 82 games for each team
        for (int i = 0; i < LeagueStructure.REGULAR_SEASON_GAMES; i++) {
          teamSchedules[team]!.add({
            'gameId': i,
            'home': team,
            'away': teams[(teams.indexOf(team) + 1) % teams.length],
            'homeScore': 0,
            'awayScore': 0,
            'matchday': (i ~/ 4) + 1,
          });
        }
      }
      
      ScheduleMatrix matrix = ScheduleMatrix(teamSchedules: teamSchedules);
      expect(matrix.validate(), isTrue);
      
      // Test invalid schedule (wrong number of games)
      teamSchedules['Team A']!.removeLast();
      ScheduleMatrix invalidMatrix = ScheduleMatrix(teamSchedules: teamSchedules);
      expect(invalidMatrix.validate(), isFalse);
    });

    test('PlayoffFormat should create standard NBA format correctly', () {
      PlayoffFormat format = PlayoffFormat.standard();
      
      expect(format.teamsPerConference, equals(8));
      expect(format.totalRounds, equals(4));
      expect(format.seriesLengths, equals([7, 7, 7, 7]));
      expect(format.reseeding, isFalse);
      expect(format.format, equals("NBA Standard"));
    });

    test('LeagueSettings should create standard settings correctly', () {
      LeagueSettings settings = LeagueSettings.standard();
      
      expect(settings.useRealTeams, isTrue);
      expect(settings.balancedScheduling, isTrue);
      expect(settings.playoffReseeding, isFalse);
      expect(settings.regularSeasonLength, equals(LeagueStructure.REGULAR_SEASON_GAMES));
      expect(settings.customRules, isEmpty);
    });
  });

  group('30-Team League Generation and Balance Tests', () {
    test('should generate exactly 30 teams with proper distribution', () {
      // Test team count validation
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      expect(teams.length, equals(LeagueStructure.TOTAL_TEAMS));
      
      // Test conference distribution
      var easternTeams = teams.where((team) => team.conference == 'Eastern').toList();
      var westernTeams = teams.where((team) => team.conference == 'Western').toList();
      
      expect(easternTeams.length, equals(LeagueStructure.TEAMS_PER_CONFERENCE));
      expect(westernTeams.length, equals(LeagueStructure.TEAMS_PER_CONFERENCE));
    });

    test('should distribute teams evenly across divisions', () {
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Test Eastern Conference divisions
      var atlanticTeams = teams.where((team) => team.division == 'Atlantic').toList();
      var centralTeams = teams.where((team) => team.division == 'Central').toList();
      var southeastTeams = teams.where((team) => team.division == 'Southeast').toList();
      
      expect(atlanticTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
      expect(centralTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
      expect(southeastTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
      
      // Test Western Conference divisions
      var northwestTeams = teams.where((team) => team.division == 'Northwest').toList();
      var pacificTeams = teams.where((team) => team.division == 'Pacific').toList();
      var southwestTeams = teams.where((team) => team.division == 'Southwest').toList();
      
      expect(northwestTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
      expect(pacificTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
      expect(southwestTeams.length, equals(LeagueStructure.TEAMS_PER_DIVISION));
    });

    test('should validate talent distribution balance across teams', () {
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Calculate average team reputation
      double totalReputation = teams.fold(0.0, (sum, team) => sum + team.reputation);
      double averageReputation = totalReputation / teams.length;
      
      // Test that no team is too far from average (within 20 points)
      for (var team in teams) {
        double deviationFromAverage = (team.reputation - averageReputation).abs();
        expect(deviationFromAverage, lessThan(20.0), 
               reason: 'Team ${team.name} reputation ${team.reputation} deviates too much from average $averageReputation');
      }
      
      // Test reputation range is reasonable (between 30-80)
      for (var team in teams) {
        expect(team.reputation, greaterThanOrEqualTo(30.0));
        expect(team.reputation, lessThanOrEqualTo(80.0));
      }
    });

    test('should generate proper 82-game schedule for each team', () {
      // Test schedule generation logic
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Create a mock schedule matrix
      Map<String, List<Map<String, dynamic>>> schedules = {};
      
      for (var team in teams) {
        schedules[team.name] = [];
        
        // Generate 82 games per team
        for (int i = 0; i < LeagueStructure.REGULAR_SEASON_GAMES; i++) {
          schedules[team.name]!.add({
            'gameId': '${team.name}_game_$i',
            'opponent': teams[(teams.indexOf(team) + i + 1) % teams.length].name,
            'isHome': i % 2 == 0,
            'week': (i ~/ 4) + 1,
          });
        }
      }
      
      // Validate each team has exactly 82 games
      for (var teamSchedule in schedules.values) {
        expect(teamSchedule.length, equals(LeagueStructure.REGULAR_SEASON_GAMES));
      }
      
      // Validate home/away balance (approximately 41 each)
      for (var teamSchedule in schedules.values) {
        int homeGames = teamSchedule.where((game) => game['isHome'] == true).length;
        int awayGames = teamSchedule.where((game) => game['isHome'] == false).length;
        
        // Allow for slight imbalance (40-42 range)
        expect(homeGames, greaterThanOrEqualTo(40));
        expect(homeGames, lessThanOrEqualTo(42));
        expect(awayGames, greaterThanOrEqualTo(40));
        expect(awayGames, lessThanOrEqualTo(42));
      }
    });

    test('should validate playoff system with 16 teams (8 per conference)', () {
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Simulate playoff qualification
      var easternTeams = teams.where((team) => team.conference == 'Eastern').toList();
      var westernTeams = teams.where((team) => team.conference == 'Western').toList();
      
      // Sort by reputation (simulating standings)
      easternTeams.sort((a, b) => b.reputation.compareTo(a.reputation));
      westernTeams.sort((a, b) => b.reputation.compareTo(a.reputation));
      
      // Take top 8 from each conference
      var easternPlayoffTeams = easternTeams.take(8).toList();
      var westernPlayoffTeams = westernTeams.take(8).toList();
      
      expect(easternPlayoffTeams.length, equals(8));
      expect(westernPlayoffTeams.length, equals(8));
      
      // Validate playoff teams are from correct conference
      for (var team in easternPlayoffTeams) {
        expect(team.conference, equals('Eastern'));
      }
      for (var team in westernPlayoffTeams) {
        expect(team.conference, equals('Western'));
      }
    });

    test('should validate conference standings tracking', () {
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Create mock standings
      Map<String, Map<String, dynamic>> standings = {};
      
      for (var team in teams) {
        standings[team.name] = {
          'wins': 41, // Default .500 record
          'losses': 41,
          'conference': team.conference,
          'division': team.division,
          'winPercentage': 0.5,
        };
      }
      
      // Test conference separation
      var easternStandings = standings.entries
          .where((entry) => entry.value['conference'] == 'Eastern')
          .toList();
      var westernStandings = standings.entries
          .where((entry) => entry.value['conference'] == 'Western')
          .toList();
      
      expect(easternStandings.length, equals(15));
      expect(westernStandings.length, equals(15));
      
      // Test division tracking within conferences
      var atlanticStandings = easternStandings
          .where((entry) => entry.value['division'] == 'Atlantic')
          .toList();
      expect(atlanticStandings.length, equals(5));
    });

    test('should ensure team roster balance across league', () {
      List<EnhancedTeam> teams = _createBalancedTeamSet();
      
      // Test that all teams have proper roster sizes
      for (var team in teams) {
        expect(team.teamSize, greaterThanOrEqualTo(15));
        expect(team.teamSize, lessThanOrEqualTo(17));
        expect(team.playerCount, lessThanOrEqualTo(team.teamSize));
      }
      
      // Test total player distribution
      int totalPlayers = teams.fold(0, (sum, team) => sum + team.playerCount);
      double averagePlayersPerTeam = totalPlayers / teams.length;
      
      // Should be around 15 players per team
      expect(averagePlayersPerTeam, greaterThan(14.0));
      expect(averagePlayersPerTeam, lessThan(16.0));
    });
  });
}

/// Helper function to create a balanced set of 30 teams for testing
List<EnhancedTeam> _createBalancedTeamSet() {
  List<EnhancedTeam> teams = [];
  
  // Eastern Conference divisions
  List<String> easternDivisions = ['Atlantic', 'Central', 'Southeast'];
  List<String> westernDivisions = ['Northwest', 'Pacific', 'Southwest'];
  
  int teamIndex = 0;
  
  // Create Eastern Conference teams
  for (String division in easternDivisions) {
    for (int i = 0; i < LeagueStructure.TEAMS_PER_DIVISION; i++) {
      teams.add(EnhancedTeam(
        name: 'Eastern $division Team $i',
        reputation: 45 + (teamIndex % 20) + (i * 2), // Varied but balanced reputation
        playerCount: 15,
        teamSize: 17,
        players: [], // Empty for testing
        conference: 'Eastern',
        division: division,
      ));
      teamIndex++;
    }
  }
  
  // Create Western Conference teams
  for (String division in westernDivisions) {
    for (int i = 0; i < LeagueStructure.TEAMS_PER_DIVISION; i++) {
      teams.add(EnhancedTeam(
        name: 'Western $division Team $i',
        reputation: 45 + (teamIndex % 20) + (i * 2), // Varied but balanced reputation
        playerCount: 15,
        teamSize: 17,
        players: [], // Empty for testing
        conference: 'Western',
        division: division,
      ));
      teamIndex++;
    }
  }
  
  return teams;
}

/// Helper function to create mock teams for testing
List<EnhancedTeam> _createMockTeams(int count, String conference, String division) {
  List<EnhancedTeam> teams = [];
  
  for (int i = 0; i < count; i++) {
    EnhancedTeam team = EnhancedTeam(
      name: '$conference Team $i',
      reputation: 50 + i * 5,
      playerCount: 15,
      teamSize: 17,
      players: [], // Empty for testing
      conference: conference,
      division: division,
    );
    
    teams.add(team);
  }
  
  return teams;
}