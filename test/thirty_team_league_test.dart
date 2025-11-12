import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/league_structure.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/nba_conference_service.dart';
import 'package:BasketballManager/gameData/team_class.dart';

void main() {
  group('Thirty Team League Tests', () {
    test('should create NBA conferences with proper structure', () {
      // Create NBA conferences
      Map<String, EnhancedConference> conferences = NBAConferenceService.createNBAConferences();

      // Validate basic structure
      expect(conferences.length, equals(2));
      expect(conferences.containsKey('Eastern'), isTrue);
      expect(conferences.containsKey('Western'), isTrue);

      // Check each conference has proper divisions
      for (String conferenceName in conferences.keys) {
        EnhancedConference conference = conferences[conferenceName]!;
        expect(conference.divisions.length, equals(3));
        
        // Each division should be properly named
        for (Division division in conference.divisions) {
          expect(division.name.isNotEmpty, isTrue);
        }
      }
    });

    test('should validate league structure constants', () {
      // Test league structure constants
      expect(LeagueStructure.TOTAL_TEAMS, equals(30));
      expect(LeagueStructure.TEAMS_PER_CONFERENCE, equals(15));
      expect(LeagueStructure.TEAMS_PER_DIVISION, equals(5));
      expect(LeagueStructure.REGULAR_SEASON_GAMES, equals(82));
      expect(LeagueStructure.PLAYOFF_TEAMS_PER_CONFERENCE, equals(8));
      expect(LeagueStructure.TOTAL_PLAYOFF_TEAMS, equals(16));
    });

    test('should create proper division structure', () {
      // Create NBA conferences
      Map<String, EnhancedConference> conferences = NBAConferenceService.createNBAConferences();

      // Check Eastern Conference divisions
      EnhancedConference eastern = conferences['Eastern']!;
      List<String> easternDivisions = eastern.divisions.map((d) => d.name).toList();
      expect(easternDivisions.contains('Atlantic'), isTrue);
      expect(easternDivisions.contains('Central'), isTrue);
      expect(easternDivisions.contains('Southeast'), isTrue);

      // Check Western Conference divisions
      EnhancedConference western = conferences['Western']!;
      List<String> westernDivisions = western.divisions.map((d) => d.name).toList();
      expect(westernDivisions.contains('Northwest'), isTrue);
      expect(westernDivisions.contains('Pacific'), isTrue);
      expect(westernDivisions.contains('Southwest'), isTrue);
    });

    test('should create enhanced conference with proper initialization', () {
      // Create a basic enhanced conference
      EnhancedConference conference = EnhancedConference(name: 'Test Conference');

      // Check initialization
      expect(conference.name, equals('Test Conference'));
      expect(conference.divisions.length, equals(2)); // Generic divisions
      expect(conference.standings.entries.isEmpty, isTrue);
      expect(conference.teamStatistics.isEmpty, isTrue);
      expect(conference.seasonAwards.isEmpty, isTrue);
      expect(conference.currentSeason, equals(1));
    });

    test('should handle playoff bracket generation', () {
      // Create a conference with some teams
      EnhancedConference conference = EnhancedConference(name: 'Test Conference');
      
      // Add some mock standings entries
      conference.standings = ConferenceStandings(
        entries: List.generate(10, (index) => StandingsEntry(
          teamName: 'Team ${index + 1}',
          wins: 50 - index,
          losses: 32 + index,
          winPercentage: (50 - index) / 82,
          pointsDifferential: 100 - (index * 10),
          streak: 'W1',
          divisionRecord: '10-6',
          conferenceRecord: '30-22',
        )),
        headToHeadRecords: {},
        strengthOfSchedule: {},
      );

      // Generate playoff bracket
      conference.generatePlayoffBracket();

      expect(conference.playoffBracket, isNotNull);
      expect(conference.playoffBracket!.firstRound.length, equals(4));
    });

    test('should handle standings updates properly', () {
      // Create a conference
      EnhancedConference conference = EnhancedConference(name: 'Test Conference');
      
      // Add some mock teams
      conference.teams = List.generate(8, (index) => Team(
        name: 'Team ${index + 1}',
        reputation: 50 + index,
        playerCount: 15,
        teamSize: 15,
        players: [],
        wins: index * 5,
        losses: 40 - (index * 5),
      ));

      // Update standings
      conference.updateStandings();

      expect(conference.standings.entries.length, equals(8));
      
      // Check that standings are sorted by win percentage
      for (int i = 0; i < conference.standings.entries.length - 1; i++) {
        expect(
          conference.standings.entries[i].winPercentage,
          greaterThanOrEqualTo(conference.standings.entries[i + 1].winPercentage),
        );
      }
    });

    test('should create league structure with proper settings', () {
      // Create a basic league structure
      LeagueStructure league = LeagueStructure(
        conferences: [
          EnhancedConference(name: 'Eastern'),
          EnhancedConference(name: 'Western'),
        ],
      );

      // Check basic properties
      expect(league.conferences.length, equals(2));
      expect(league.currentSeason, equals(1));
      expect(league.playoffFormat.teamsPerConference, equals(8));
      expect(league.settings.useRealTeams, isTrue);
      expect(league.settings.regularSeasonLength, equals(82));
    });

    test('should handle division standings calculation', () {
      // Create a conference with divisions and teams
      EnhancedConference conference = EnhancedConference(name: 'Eastern');
      
      // Add teams to divisions
      for (int divIndex = 0; divIndex < 3; divIndex++) {
        Division division = conference.divisions[divIndex];
        for (int teamIndex = 0; teamIndex < 3; teamIndex++) {
          Team team = Team(
            name: 'Team $divIndex-$teamIndex',
            reputation: 50,
            playerCount: 15,
            teamSize: 15,
            players: [],
            wins: teamIndex * 10,
            losses: 30 - (teamIndex * 10),
          );
          division.teams.add(team);
          conference.teams.add(team);
        }
      }

      // Update standings
      conference.updateStandings();

      // Get division standings
      Map<String, List<StandingsEntry>> divisionStandings = conference.getDivisionStandings();
      
      expect(divisionStandings.length, equals(3));
      
      for (String divisionName in divisionStandings.keys) {
        List<StandingsEntry> entries = divisionStandings[divisionName]!;
        expect(entries.length, equals(3));
      }
    });
  });
}