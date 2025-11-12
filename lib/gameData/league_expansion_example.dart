import 'dart:math';
import 'league_structure.dart';
import 'league_expansion_service.dart';
import 'enhanced_conference.dart';

/// Example usage of the 30-team league expansion system
class LeagueExpansionExample {
  
  /// Generate a complete 30-team NBA-style league
  static Future<LeagueStructure> createNBALeague() async {
    try {
      // Generate the complete league with real NBA teams
      LeagueStructure league = await LeagueExpansionService.generateNBAStyleLeague(
        useRealTeams: true,
        settings: LeagueSettings.standard(),
      );
      
      print('Successfully created 30-team NBA league!');
      print('Total teams: ${league.allTeams.length}');
      print('Conferences: ${league.conferences.length}');
      
      // Print conference breakdown
      for (var conference in league.conferences) {
        print('\n${conference.name} Conference:');
        print('  Teams: ${conference.teams.length}');
        print('  Divisions: ${conference.divisions.length}');
        
        for (var division in conference.divisions) {
          print('    ${division.name} Division: ${division.teams.length} teams');
          for (var team in division.teams) {
            print('      - ${team.name}');
          }
        }
      }
      
      return league;
    } catch (e) {
      print('Error creating NBA league: $e');
      rethrow;
    }
  }
  
  /// Generate season schedule for the league
  static Future<void> generateSeasonSchedule(LeagueStructure league) async {
    try {
      print('\nGenerating season schedule...');
      
      var scheduleMatrix = await LeagueExpansionService.generateSeasonSchedule(league);
      
      print('Schedule generated successfully!');
      print('Total games in matrix: ${scheduleMatrix.totalGames}');
      print('Games per team: ${scheduleMatrix.gamesPerTeam}');
      
      // Validate schedule
      if (scheduleMatrix.validate()) {
        print('Schedule validation: PASSED');
      } else {
        print('Schedule validation: FAILED');
      }
      
      // Show sample schedule for first team
      if (scheduleMatrix.teamSchedules.isNotEmpty) {
        var firstTeam = scheduleMatrix.teamSchedules.keys.first;
        var firstTeamSchedule = scheduleMatrix.teamSchedules[firstTeam]!;
        
        print('\nSample schedule for $firstTeam (first 10 games):');
        for (int i = 0; i < 10 && i < firstTeamSchedule.length; i++) {
          var game = firstTeamSchedule[i];
          print('  Game ${i + 1}: ${game['home']} vs ${game['away']} (Matchday ${game['matchday']})');
        }
      }
      
    } catch (e) {
      print('Error generating schedule: $e');
      rethrow;
    }
  }
  
  /// Demonstrate league standings and playoff qualification
  static void demonstrateStandings(LeagueStructure league) {
    print('\nGenerating league standings...');
    
    // Simulate some games by updating team records
    _simulatePartialSeason(league);
    
    // Generate standings
    var standings = league.generateLeagueStandings();
    
    print('\nLeague Standings (Season ${standings['season']}):');
    
    // Show conference standings
    var conferences = standings['conferences'] as Map<String, dynamic>;
    for (var confEntry in conferences.entries) {
      print('\n${confEntry.key} Conference:');
      var confData = confEntry.value as Map<String, dynamic>;
      var confStandings = confData['standings'] as List<StandingsEntry>;
      
      for (int i = 0; i < confStandings.length && i < 8; i++) {
        var entry = confStandings[i];
        String playoffStatus = i < 8 ? ' (Playoff)' : '';
        print('  ${i + 1}. ${entry.teamName} - ${entry.wins}-${entry.losses} (${(entry.winPercentage * 100).toStringAsFixed(1)}%)$playoffStatus');
      }
    }
    
    // Show playoff teams
    var playoffTeams = league.getPlayoffTeams();
    print('\nPlayoff Teams (${playoffTeams.length} total):');
    for (var team in playoffTeams) {
      print('  - ${team.name} (${team.wins}-${team.losses})');
    }
  }
  
  /// Demonstrate league statistics
  static void demonstrateLeagueStats(LeagueStructure league) {
    print('\nLeague Statistics:');
    
    var stats = league.calculateLeagueStats();
    print('  Total Teams: ${stats['totalTeams']}');
    print('  Current Season: ${stats['currentSeason']}');
    print('  Average Games Played: ${stats['averageGamesPlayed']?.toStringAsFixed(1)}');
    print('  Average Win Percentage: ${(stats['averageWinPercentage'] * 100)?.toStringAsFixed(1)}%');
    print('  Playoff Teams: ${stats['playoffTeamsCount']}');
  }
  
  /// Simulate a partial season by randomly updating team records
  static void _simulatePartialSeason(LeagueStructure league) {
    var random = Random();
    
    for (var team in league.allTeams) {
      // Simulate 20-40 games played
      int gamesPlayed = 20 + random.nextInt(21);
      int wins = random.nextInt(gamesPlayed + 1);
      int losses = gamesPlayed - wins;
      
      // Update team record
      team.wins = wins;
      team.losses = losses;
    }
  }
  
  /// Complete example demonstrating all features
  static Future<void> runCompleteExample() async {
    print('=== 30-Team League Expansion System Demo ===\n');
    
    try {
      // Step 1: Create the league
      LeagueStructure league = await createNBALeague();
      
      // Step 2: Generate schedule
      await generateSeasonSchedule(league);
      
      // Step 3: Demonstrate standings
      demonstrateStandings(league);
      
      // Step 4: Show league statistics
      demonstrateLeagueStats(league);
      
      // Step 5: Validate the complete structure
      print('\n=== Final Validation ===');
      bool isValid = LeagueExpansionService.validateLeagueStructure(league);
      print('League structure validation: ${isValid ? 'PASSED' : 'FAILED'}');
      
      if (isValid) {
        print('\n✅ 30-team league expansion system is working correctly!');
        print('The league is ready for simulation with:');
        print('  - ${LeagueStructure.TOTAL_TEAMS} teams');
        print('  - ${LeagueStructure.TEAMS_PER_CONFERENCE} teams per conference');
        print('  - ${LeagueStructure.TEAMS_PER_DIVISION} teams per division');
        print('  - ${LeagueStructure.REGULAR_SEASON_GAMES} games per team');
        print('  - ${LeagueStructure.TOTAL_PLAYOFF_TEAMS} playoff teams');
      } else {
        print('\n❌ League structure validation failed!');
      }
      
    } catch (e) {
      print('\n❌ Error in league expansion demo: $e');
    }
  }
}