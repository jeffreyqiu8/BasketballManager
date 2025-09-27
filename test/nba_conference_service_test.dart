import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/nba_conference_service.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/nba_team_data.dart';

void main() {
  group('NBAConferenceService', () {
    test('should create both NBA conferences with correct structure', () {
      final conferences = NBAConferenceService.createNBAConferences();
      
      expect(conferences.length, equals(2));
      expect(conferences.containsKey('Eastern'), isTrue);
      expect(conferences.containsKey('Western'), isTrue);
      
      final eastern = conferences['Eastern']!;
      final western = conferences['Western']!;
      
      // Each conference should have 15 teams
      expect(eastern.teams.length, equals(15));
      expect(western.teams.length, equals(15));
      
      // Each conference should have 3 divisions
      expect(eastern.divisions.length, equals(3));
      expect(western.divisions.length, equals(3));
    });

    test('should create Eastern Conference with correct divisions', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      final divisionNames = eastern.divisions.map((d) => d.name).toList();
      expect(divisionNames, containsAll(['Atlantic', 'Central', 'Southeast']));
      
      // Each division should have 5 teams
      for (var division in eastern.divisions) {
        expect(division.teams.length, equals(5));
      }
      
      // Verify specific teams are in correct divisions
      final atlanticTeams = eastern.divisions
          .firstWhere((d) => d.name == 'Atlantic')
          .teams
          .map((t) => t.name)
          .toList();
      
      expect(atlanticTeams, contains('Boston Celtics'));
      expect(atlanticTeams, contains('New York Knicks'));
      expect(atlanticTeams, contains('Philadelphia 76ers'));
    });

    test('should create Western Conference with correct divisions', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final western = conferences['Western']!;
      
      final divisionNames = western.divisions.map((d) => d.name).toList();
      expect(divisionNames, containsAll(['Northwest', 'Pacific', 'Southwest']));
      
      // Each division should have 5 teams
      for (var division in western.divisions) {
        expect(division.teams.length, equals(5));
      }
      
      // Verify specific teams are in correct divisions
      final pacificTeams = western.divisions
          .firstWhere((d) => d.name == 'Pacific')
          .teams
          .map((t) => t.name)
          .toList();
      
      expect(pacificTeams, contains('Los Angeles Lakers'));
      expect(pacificTeams, contains('Golden State Warriors'));
      expect(pacificTeams, contains('Los Angeles Clippers'));
    });

    test('should generate NBA-style schedule with reasonable game count', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      // Each team should play multiple games against each other team
      // With 15 teams, each team plays 14 other teams
      // Division rivals (4 teams) play 4 games each = 16 games
      // Non-division teams (10 teams) play 3 games each = 30 games
      // Total per team = 46 games (simplified schedule)
      
      for (var team in eastern.teams) {
        final teamGames = eastern.schedule.where(
          (game) => game['home'] == team.name || game['away'] == team.name
        ).toList();
        
        // Should have games against all other teams
        expect(teamGames.length, greaterThan(40));
        expect(teamGames.length, lessThan(50));
      }
    });

    test('should have correct division rivalry scheduling', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      // Find a team and its division rivals
      final celtics = eastern.teams.firstWhere((t) => t.name == 'Boston Celtics');
      final atlanticDivision = eastern.divisions.firstWhere((d) => d.name == 'Atlantic');
      final divisionRivals = atlanticDivision.teams.where((t) => t.name != celtics.name).toList();
      
      // Celtics should play each division rival more than non-division teams
      for (var rival in divisionRivals) {
        final gamesVsRival = eastern.schedule.where(
          (game) => (game['home'] == celtics.name && game['away'] == rival.name) ||
                   (game['home'] == rival.name && game['away'] == celtics.name)
        ).toList();
        
        expect(gamesVsRival.length, equals(4));
      }
    });

    test('should generate playoff bracket with correct seeding', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      // Simulate some games to create standings
      for (int i = 0; i < eastern.teams.length; i++) {
        eastern.teams[i].wins = 50 - (i * 2); // Decreasing wins
        eastern.teams[i].losses = 32 + (i * 2); // Increasing losses
      }
      
      final bracket = NBAConferenceService.generateNBAPlayoffBracket(eastern);
      
      expect(bracket.firstRound.length, equals(4));
      
      // Verify seeding (1v8, 2v7, 3v6, 4v5)
      final matchup1 = bracket.firstRound[0];
      expect(matchup1.higherSeed.wins > matchup1.lowerSeed.wins, isTrue);
      
      final matchup2 = bracket.firstRound[1];
      expect(matchup2.higherSeed.wins > matchup2.lowerSeed.wins, isTrue);
    });

    test('should simulate playoff series correctly', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      // Create mock standings entries
      final higherSeed = StandingsEntry(
        teamName: 'Boston Celtics',
        wins: 60,
        losses: 22,
        winPercentage: 0.732,
        pointsDifferential: 8.5,
        streak: 'W3',
        divisionRecord: '12-4',
        conferenceRecord: '38-14',
      );
      
      final lowerSeed = StandingsEntry(
        teamName: 'Miami Heat',
        wins: 44,
        losses: 38,
        winPercentage: 0.537,
        pointsDifferential: 2.1,
        streak: 'L1',
        divisionRecord: '8-8',
        conferenceRecord: '28-24',
      );
      
      final matchup = PlayoffMatchup(
        higherSeed: higherSeed,
        lowerSeed: lowerSeed,
        round: 1,
      );
      
      NBAConferenceService.simulatePlayoffSeries(matchup);
      
      expect(matchup.isComplete, isTrue);
      expect(matchup.winner, isNotNull);
      expect(matchup.higherSeedWins + matchup.lowerSeedWins, greaterThanOrEqualTo(4));
      expect(matchup.higherSeedWins + matchup.lowerSeedWins, lessThanOrEqualTo(7));
    });

    test('should calculate team reputation based on history', () {
      final nbaTeams = RealTeamData.getAllNBATeams();
      final conferences = NBAConferenceService.createNBAConferences();
      
      // Find Lakers and Celtics (historically successful teams)
      final allTeams = [...conferences['Eastern']!.teams, ...conferences['Western']!.teams];
      final lakers = allTeams.firstWhere((t) => t.name.contains('Lakers'));
      final celtics = allTeams.firstWhere((t) => t.name.contains('Celtics'));
      
      // Both should have high reputation due to championships
      expect(lakers.reputation, greaterThan(70));
      expect(celtics.reputation, greaterThan(70));
      
      // Find a newer team with fewer championships
      final hornets = allTeams.firstWhere((t) => t.name.contains('Hornets'));
      expect(hornets.reputation, lessThan(lakers.reputation));
    });

    test('should have proper team branding and history', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final allTeams = [...conferences['Eastern']!.teams, ...conferences['Western']!.teams];
      
      for (var team in allTeams) {
        if (team is EnhancedTeam) {
          expect(team.branding, isNotNull);
          expect(team.history, isNotNull);
          expect(team.conference, isNotNull);
          expect(team.division, isNotNull);
          
          // Verify branding has required fields
          expect(team.branding!.primaryColor, isNotEmpty);
          expect(team.branding!.abbreviation, isNotEmpty);
          expect(team.branding!.city, isNotEmpty);
          
          // Verify history has required fields
          expect(team.history!.foundedYear, greaterThan(1900));
          expect(team.history!.championships, greaterThanOrEqualTo(0));
        }
      }
    });

    test('should maintain schedule integrity', () {
      final conferences = NBAConferenceService.createNBAConferences();
      final eastern = conferences['Eastern']!;
      
      // Should have a reasonable number of games
      expect(eastern.schedule.length, greaterThan(300));
      expect(eastern.schedule.length, lessThan(400));
      
      // Each game should have valid teams
      for (var game in eastern.schedule) {
        expect(game['home'], isNotNull);
        expect(game['away'], isNotNull);
        expect(game['home'], isNot(equals(game['away'])));
        expect(game['matchday'], greaterThan(0));
        
        // Verify teams exist in conference
        final homeTeamExists = eastern.teams.any((t) => t.name == game['home']);
        final awayTeamExists = eastern.teams.any((t) => t.name == game['away']);
        expect(homeTeamExists, isTrue);
        expect(awayTeamExists, isTrue);
      }
    });
  });
}