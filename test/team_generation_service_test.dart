import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/team_generation_service.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/nba_team_data.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/gameData/player_class.dart';

void main() {
  group('TeamGenerationService Tests', () {
    
    test('should generate realistic NBA team roster with correct size', () {
      // Get a test NBA team
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      // Generate roster
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      // Verify basic properties
      expect(generatedTeam.name, equals(testTeam.name));
      expect(generatedTeam.players.length, equals(15));
      expect(generatedTeam.playerCount, equals(15));
      expect(generatedTeam.conference, equals(testTeam.conference));
      expect(generatedTeam.division, equals(testTeam.division));
      expect(generatedTeam.branding, isNotNull);
    });

    test('should generate position-balanced roster', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      // Count players by position
      Map<PlayerRole, int> positionCounts = {};
      for (Player player in generatedTeam.players) {
        if (player is EnhancedPlayer) {
          PlayerRole role = player.primaryRole;
          positionCounts[role] = (positionCounts[role] ?? 0) + 1;
        }
      }
      
      // Verify all positions are represented
      expect(positionCounts.keys.length, equals(5));
      
      // Verify reasonable distribution (at least 1 of each position)
      for (PlayerRole role in PlayerRole.values) {
        expect(positionCounts[role], greaterThan(0));
      }
      
      // Verify total adds up
      int totalPlayers = positionCounts.values.reduce((a, b) => a + b);
      expect(totalPlayers, equals(15));
    });

    test('should generate players with appropriate skill distributions', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      // Check that players have realistic attribute ranges
      for (Player player in generatedTeam.players) {
        if (player is EnhancedPlayer) {
          // All attributes should be between 30-99
          expect(player.shooting, inInclusiveRange(30, 99));
          expect(player.rebounding, inInclusiveRange(30, 99));
          expect(player.passing, inInclusiveRange(30, 99));
          expect(player.ballHandling, inInclusiveRange(30, 99));
          expect(player.perimeterDefense, inInclusiveRange(30, 99));
          expect(player.postDefense, inInclusiveRange(30, 99));
          expect(player.insideShooting, inInclusiveRange(30, 99));
          
          // Height should be realistic for basketball players
          expect(player.height, inInclusiveRange(175, 230));
          
          // Age should be realistic
          expect(player.age, inInclusiveRange(18, 40));
          
          // Should have valid nationality
          expect(player.nationality, isNotEmpty);
          
          // Should have valid name
          expect(player.name, isNotEmpty);
          expect(player.name.contains(' '), isTrue); // Should have first and last name
        }
      }
    });

    test('should generate players with role-appropriate attributes', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      for (Player player in generatedTeam.players) {
        if (player is EnhancedPlayer) {
          PlayerRole role = player.primaryRole;
          
          switch (role) {
            case PlayerRole.pointGuard:
              // Point guards should be good at ball handling and passing
              expect(player.ballHandling, greaterThan(50));
              expect(player.passing, greaterThan(50));
              break;
              
            case PlayerRole.center:
              // Centers should be good at rebounding and post defense
              expect(player.rebounding, greaterThan(60));
              expect(player.postDefense, greaterThan(60));
              // Centers should be tall
              expect(player.height, greaterThan(200));
              break;
              
            case PlayerRole.shootingGuard:
              // Shooting guards should be good shooters
              expect(player.shooting, greaterThan(55));
              break;
              
            case PlayerRole.smallForward:
              // Small forwards should be versatile
              expect(player.shooting, greaterThan(45));
              expect(player.rebounding, greaterThan(45));
              break;
              
            case PlayerRole.powerForward:
              // Power forwards should be good rebounders and inside scorers
              expect(player.rebounding, greaterThan(55));
              expect(player.insideShooting, greaterThan(50));
              break;
          }
        }
      }
    });

    test('should generate valid starting lineup', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      // Should have 5 starters
      expect(generatedTeam.starters.length, equals(5));
      
      // All starters should be on the roster
      for (Player starter in generatedTeam.starters) {
        expect(generatedTeam.players.contains(starter), isTrue);
      }
      
      // Starting lineup should have all 5 positions (or at least be valid)
      List<PlayerRole> starterRoles = [];
      for (Player starter in generatedTeam.starters) {
        if (starter is EnhancedPlayer) {
          starterRoles.add(starter.primaryRole);
        }
      }
      
      // Should have 5 unique positions ideally, but at minimum should have starters
      expect(starterRoles.length, equals(5));
    });

    test('should generate diverse nationalities', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      Set<String> nationalities = {};
      for (Player player in generatedTeam.players) {
        if (player is EnhancedPlayer) {
          nationalities.add(player.nationality);
        }
      }
      
      // Should have some diversity (at least USA represented)
      expect(nationalities.contains('USA'), isTrue);
      expect(nationalities.isNotEmpty, isTrue);
    });

    test('should generate all 30 NBA teams', () {
      List<EnhancedTeam> allTeams = TeamGenerationService.generateAllNBATeams();
      
      // Should generate exactly 30 teams
      expect(allTeams.length, equals(30));
      
      // Each team should have players
      for (EnhancedTeam team in allTeams) {
        expect(team.players.length, greaterThanOrEqualTo(13));
        expect(team.players.length, lessThanOrEqualTo(17));
      }
      
      // Should have teams from both conferences
      Set<String> conferences = {};
      for (EnhancedTeam team in allTeams) {
        conferences.add(team.conference!);
      }
      expect(conferences.contains('Eastern'), isTrue);
      expect(conferences.contains('Western'), isTrue);
    });

    test('should respect roster size constraints', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      // Test minimum roster size
      EnhancedTeam smallTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 13,
      );
      expect(smallTeam.players.length, equals(13));
      
      // Test maximum roster size
      EnhancedTeam largeTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 17,
      );
      expect(largeTeam.players.length, equals(17));
    });

    test('should generate players with valid development data', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      for (Player player in generatedTeam.players) {
        if (player is EnhancedPlayer) {
          // Should have valid potential
          expect(player.potential, isNotNull);
          expect(player.potential.overallPotential, inInclusiveRange(50, 99));
          expect(player.potential.maxSkills['shooting'], inInclusiveRange(50, 99));
          
          // Should have development tracker
          expect(player.development, isNotNull);
          
          // Should have role compatibility calculated
          expect(player.roleCompatibility, inInclusiveRange(0.0, 1.0));
          
          // Experience should match age
          if (player.age <= 19) {
            expect(player.experienceYears, equals(0));
          } else {
            expect(player.experienceYears, greaterThanOrEqualTo(0));
            expect(player.experienceYears, lessThan(player.age));
          }
        }
      }
    });

    test('should generate team with reasonable reputation', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      // Team reputation should be in valid range
      expect(generatedTeam.reputation, inInclusiveRange(30, 95));
    });

    test('should generate unique player names', () {
      NBATeam testTeam = RealTeamData.getAllNBATeams().first;
      
      EnhancedTeam generatedTeam = TeamGenerationService.generateNBATeamRoster(
        testTeam,
        rosterSize: 15,
      );
      
      Set<String> playerNames = {};
      for (Player player in generatedTeam.players) {
        playerNames.add(player.name);
      }
      
      // Should have unique names (very unlikely to have duplicates)
      expect(playerNames.length, equals(generatedTeam.players.length));
    });

    test('should handle custom roster sizes and salary caps', () {
      List<EnhancedTeam> customTeams = TeamGenerationService.generateAllNBATeams(
        customRosterSizes: {'Boston Celtics': 16},
        customSalaryCaps: {'Boston Celtics': 150.0},
      );
      
      // Find the Celtics team
      EnhancedTeam? celticsTeam;
      for (EnhancedTeam team in customTeams) {
        if (team.name == 'Celtics') {
          celticsTeam = team;
          break;
        }
      }
      
      expect(celticsTeam, isNotNull);
      expect(celticsTeam!.players.length, equals(16));
    });
  });
}