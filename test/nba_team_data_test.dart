import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/nba_team_data.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';

void main() {
  group('NBATeam', () {
    test('should create NBA team with all required properties', () {
      final branding = TeamBranding(
        primaryColor: '#007A33',
        secondaryColor: '#BA9653',
        logoUrl: 'assets/logos/celtics.png',
        abbreviation: 'BOS',
        city: 'Boston',
        mascot: 'Lucky the Leprechaun',
      );

      final history = TeamHistory(
        foundedYear: 1946,
        championships: 17,
        playoffAppearances: 58,
        retiredNumbers: ['1', '2', '3'],
        hallOfFamers: ['Bill Russell', 'Larry Bird'],
        rivalries: {'Los Angeles Lakers': 'Historic Finals rivalry'},
      );

      final team = NBATeam(
        name: 'Celtics',
        city: 'Boston',
        abbreviation: 'BOS',
        conference: 'Eastern',
        division: 'Atlantic',
        branding: branding,
        history: history,
      );

      expect(team.name, equals('Celtics'));
      expect(team.city, equals('Boston'));
      expect(team.fullName, equals('Boston Celtics'));
      expect(team.abbreviation, equals('BOS'));
      expect(team.conference, equals('Eastern'));
      expect(team.division, equals('Atlantic'));
      expect(team.branding, equals(branding));
      expect(team.history, equals(history));
    });

    test('should serialize and deserialize correctly', () {
      final branding = TeamBranding(
        primaryColor: '#007A33',
        secondaryColor: '#BA9653',
        logoUrl: 'assets/logos/celtics.png',
        abbreviation: 'BOS',
        city: 'Boston',
        mascot: 'Lucky the Leprechaun',
      );

      final history = TeamHistory(
        foundedYear: 1946,
        championships: 17,
        playoffAppearances: 58,
        retiredNumbers: ['1', '2', '3'],
        hallOfFamers: ['Bill Russell', 'Larry Bird'],
        rivalries: {'Los Angeles Lakers': 'Historic Finals rivalry'},
      );

      final originalTeam = NBATeam(
        name: 'Celtics',
        city: 'Boston',
        abbreviation: 'BOS',
        conference: 'Eastern',
        division: 'Atlantic',
        branding: branding,
        history: history,
      );

      final map = originalTeam.toMap();
      final deserializedTeam = NBATeam.fromMap(map);

      expect(deserializedTeam.name, equals(originalTeam.name));
      expect(deserializedTeam.city, equals(originalTeam.city));
      expect(deserializedTeam.abbreviation, equals(originalTeam.abbreviation));
      expect(deserializedTeam.conference, equals(originalTeam.conference));
      expect(deserializedTeam.division, equals(originalTeam.division));
    });
  });

  group('RealTeamData', () {
    test('should return all 30 NBA teams', () {
      final teams = RealTeamData.getAllNBATeams();
      expect(teams.length, equals(30));
    });

    test('should return teams by conference', () {
      final easternTeams = RealTeamData.getTeamsByConference('Eastern');
      final westernTeams = RealTeamData.getTeamsByConference('Western');
      
      expect(easternTeams.length, equals(15));
      expect(westernTeams.length, equals(15));
      
      // Verify all eastern teams have correct conference
      for (final team in easternTeams) {
        expect(team.conference, equals('Eastern'));
      }
      
      // Verify all western teams have correct conference
      for (final team in westernTeams) {
        expect(team.conference, equals('Western'));
      }
    });

    test('should return teams by division', () {
      final atlanticTeams = RealTeamData.getTeamsByDivision('Atlantic');
      final centralTeams = RealTeamData.getTeamsByDivision('Central');
      final southeastTeams = RealTeamData.getTeamsByDivision('Southeast');
      final northwestTeams = RealTeamData.getTeamsByDivision('Northwest');
      final pacificTeams = RealTeamData.getTeamsByDivision('Pacific');
      final southwestTeams = RealTeamData.getTeamsByDivision('Southwest');
      
      expect(atlanticTeams.length, equals(5));
      expect(centralTeams.length, equals(5));
      expect(southeastTeams.length, equals(5));
      expect(northwestTeams.length, equals(5));
      expect(pacificTeams.length, equals(5));
      expect(southwestTeams.length, equals(5));
    });

    test('should get team by name', () {
      final celtics = RealTeamData.getTeamByName('Boston Celtics');
      expect(celtics, isNotNull);
      expect(celtics!.name, equals('Celtics'));
      expect(celtics.city, equals('Boston'));
      expect(celtics.abbreviation, equals('BOS'));
      
      final nonExistent = RealTeamData.getTeamByName('Non Existent Team');
      expect(nonExistent, isNull);
    });

    test('should get team branding by name', () {
      final branding = RealTeamData.getTeamBranding('Boston Celtics');
      expect(branding, isNotNull);
      expect(branding!.primaryColor, equals('#007A33'));
      expect(branding.abbreviation, equals('BOS'));
      
      final nonExistentBranding = RealTeamData.getTeamBranding('Non Existent Team');
      expect(nonExistentBranding, isNull);
    });

    test('should return correct conferences and divisions', () {
      final conferences = RealTeamData.getConferences();
      expect(conferences, containsAll(['Eastern', 'Western']));
      
      final easternDivisions = RealTeamData.getDivisions('Eastern');
      expect(easternDivisions, containsAll(['Atlantic', 'Central', 'Southeast']));
      
      final westernDivisions = RealTeamData.getDivisions('Western');
      expect(westernDivisions, containsAll(['Northwest', 'Pacific', 'Southwest']));
    });

    test('should return team abbreviations mapping', () {
      final abbreviations = RealTeamData.getTeamAbbreviations();
      expect(abbreviations.length, equals(30));
      expect(abbreviations['BOS'], equals('Boston Celtics'));
      expect(abbreviations['LAL'], equals('Los Angeles Lakers'));
      expect(abbreviations['GSW'], equals('Golden State Warriors'));
    });

    test('should verify specific team data accuracy', () {
      // Test Boston Celtics
      final celtics = RealTeamData.getTeamByName('Boston Celtics');
      expect(celtics!.history.championships, equals(17));
      expect(celtics.history.foundedYear, equals(1946));
      expect(celtics.branding.primaryColor, equals('#007A33'));
      
      // Test Los Angeles Lakers
      final lakers = RealTeamData.getTeamByName('Los Angeles Lakers');
      expect(lakers!.history.championships, equals(17));
      expect(lakers.history.foundedYear, equals(1947));
      expect(lakers.branding.primaryColor, equals('#552583'));
      
      // Test Golden State Warriors
      final warriors = RealTeamData.getTeamByName('Golden State Warriors');
      expect(warriors!.history.championships, equals(7));
      expect(warriors.conference, equals('Western'));
      expect(warriors.division, equals('Pacific'));
    });

    test('should have rivalries defined for major teams', () {
      final celtics = RealTeamData.getTeamByName('Boston Celtics');
      expect(celtics!.history.rivalries.containsKey('Los Angeles Lakers'), isTrue);
      
      final lakers = RealTeamData.getTeamByName('Los Angeles Lakers');
      expect(lakers!.history.rivalries.containsKey('Boston Celtics'), isTrue);
      
      final warriors = RealTeamData.getTeamByName('Golden State Warriors');
      expect(warriors!.history.rivalries.containsKey('Cleveland Cavaliers'), isTrue);
    });

    test('should have retired numbers for historic teams', () {
      final celtics = RealTeamData.getTeamByName('Boston Celtics');
      expect(celtics!.history.retiredNumbers.isNotEmpty, isTrue);
      expect(celtics.history.retiredNumbers.contains('33'), isTrue); // Larry Bird
      
      final lakers = RealTeamData.getTeamByName('Los Angeles Lakers');
      expect(lakers!.history.retiredNumbers.isNotEmpty, isTrue);
      expect(lakers.history.retiredNumbers.contains('24'), isTrue); // Kobe Bryant
    });
  });
}