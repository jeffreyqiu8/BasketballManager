import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/utils/playoff_seeding.dart';

void main() {
  group('PlayoffSeeding', () {
    late List<Team> teams;
    late List<Game> games;

    setUp(() {
      // Create 30 teams (15 East, 15 West)
      teams = _createTestTeams();
      games = [];
    });

    test('should separate teams into Eastern and Western conferences', () {
      final eastTeams = teams.where((t) => PlayoffSeeding.isEasternConference(t)).toList();
      final westTeams = teams.where((t) => !PlayoffSeeding.isEasternConference(t)).toList();

      expect(eastTeams.length, 15);
      expect(westTeams.length, 15);
    });

    test('should correctly identify Eastern Conference teams', () {
      final atlantaTeam = teams.firstWhere((t) => t.city == 'Atlanta');
      final bostonTeam = teams.firstWhere((t) => t.city == 'Boston');
      final miamiTeam = teams.firstWhere((t) => t.city == 'Miami');

      expect(PlayoffSeeding.isEasternConference(atlantaTeam), true);
      expect(PlayoffSeeding.isEasternConference(bostonTeam), true);
      expect(PlayoffSeeding.isEasternConference(miamiTeam), true);
    });

    test('should correctly identify Western Conference teams', () {
      final lakersTeam = teams.firstWhere((t) => t.city == 'Los Angeles');
      final warriorsTeam = teams.firstWhere((t) => t.city == 'Golden State');
      final mavericksTeam = teams.firstWhere((t) => t.city == 'Dallas');

      expect(PlayoffSeeding.isEasternConference(lakersTeam), false);
      expect(PlayoffSeeding.isEasternConference(warriorsTeam), false);
      expect(PlayoffSeeding.isEasternConference(mavericksTeam), false);
    });

    test('should return correct conference name', () {
      final eastTeam = teams.firstWhere((t) => t.city == 'Boston');
      final westTeam = teams.firstWhere((t) => t.city == 'Dallas');

      expect(PlayoffSeeding.getConference(eastTeam), 'east');
      expect(PlayoffSeeding.getConference(westTeam), 'west');
    });

    test('should calculate seedings based on win-loss records', () {
      // Create games where some teams have more wins
      final team1 = teams[0]; // East team
      final team2 = teams[1]; // East team
      final team3 = teams[15]; // West team
      final team4 = teams[16]; // West team

      // Team1 wins 50 games, Team2 wins 40 games
      for (int i = 0; i < 50; i++) {
        games.add(_createGame(team1.id, team2.id, homeWins: true));
      }
      for (int i = 0; i < 40; i++) {
        games.add(_createGame(team2.id, team1.id, homeWins: true));
      }

      // Team3 wins 55 games, Team4 wins 45 games
      for (int i = 0; i < 55; i++) {
        games.add(_createGame(team3.id, team4.id, homeWins: true));
      }
      for (int i = 0; i < 45; i++) {
        games.add(_createGame(team4.id, team3.id, homeWins: true));
      }

      final seedings = PlayoffSeeding.calculateSeedings(teams, games);

      // Team1 should be seed 1 in East (50 wins)
      // Team2 should be seed 2 in East (40 wins)
      expect(seedings[team1.id], 1);
      expect(seedings[team2.id], 2);

      // Team3 should be seed 1 in West (55 wins)
      // Team4 should be seed 2 in West (45 wins)
      expect(seedings[team3.id], 1);
      expect(seedings[team4.id], 2);
    });

    test('should assign seeds 1-15 to each conference', () {
      // Create games with varying win totals
      games = _createGamesWithVaryingWins(teams);

      final seedings = PlayoffSeeding.calculateSeedings(teams, games);

      // Check that all teams have a seed
      expect(seedings.length, 30);

      // Check that East teams have seeds 1-15
      final eastTeams = teams.where((t) => PlayoffSeeding.isEasternConference(t)).toList();
      final eastSeeds = eastTeams.map((t) => seedings[t.id]!).toList();
      eastSeeds.sort();
      expect(eastSeeds, List.generate(15, (i) => i + 1));

      // Check that West teams have seeds 1-15
      final westTeams = teams.where((t) => !PlayoffSeeding.isEasternConference(t)).toList();
      final westSeeds = westTeams.map((t) => seedings[t.id]!).toList();
      westSeeds.sort();
      expect(westSeeds, List.generate(15, (i) => i + 1));
    });

    test('should handle teams with same record (stable sort)', () {
      final team1 = teams[0];
      final team2 = teams[1];
      final team3 = teams[2];

      // All three teams have 40 wins
      for (int i = 0; i < 40; i++) {
        games.add(_createGame(team1.id, 'opponent', homeWins: true));
        games.add(_createGame(team2.id, 'opponent', homeWins: true));
        games.add(_createGame(team3.id, 'opponent', homeWins: true));
      }

      final seedings = PlayoffSeeding.calculateSeedings(teams, games);

      // All three should have seeds 1, 2, 3 (order may vary but all should be seeded)
      expect(seedings[team1.id], lessThanOrEqualTo(3));
      expect(seedings[team2.id], lessThanOrEqualTo(3));
      expect(seedings[team3.id], lessThanOrEqualTo(3));
    });

    test('should get teams by conference', () {
      final eastTeams = PlayoffSeeding.getTeamsByConference(teams, 'east');
      final westTeams = PlayoffSeeding.getTeamsByConference(teams, 'west');

      expect(eastTeams.length, 15);
      expect(westTeams.length, 15);

      // Verify all east teams are actually in the east
      for (var team in eastTeams) {
        expect(PlayoffSeeding.isEasternConference(team), true);
      }

      // Verify all west teams are actually in the west
      for (var team in westTeams) {
        expect(PlayoffSeeding.isEasternConference(team), false);
      }
    });

    test('should get seeded teams in correct order', () {
      games = _createGamesWithVaryingWins(teams);
      final seedings = PlayoffSeeding.calculateSeedings(teams, games);

      final eastSeeded = PlayoffSeeding.getSeededTeams(teams, seedings, 'east');
      final westSeeded = PlayoffSeeding.getSeededTeams(teams, seedings, 'west');

      // Verify teams are in seed order (1, 2, 3, ...)
      for (int i = 0; i < eastSeeded.length; i++) {
        expect(seedings[eastSeeded[i].id], i + 1);
      }

      for (int i = 0; i < westSeeded.length; i++) {
        expect(seedings[westSeeded[i].id], i + 1);
      }
    });
  });
}

// Helper function to create test teams
List<Team> _createTestTeams() {
  final teams = <Team>[];
  
  // Eastern Conference teams
  final eastCities = [
    'Atlanta', 'Boston', 'Brooklyn', 'Charlotte', 'Chicago',
    'Cleveland', 'Detroit', 'Indiana', 'Miami', 'Milwaukee',
    'New York', 'Orlando', 'Philadelphia', 'Toronto', 'Washington'
  ];

  // Western Conference teams
  final westCities = [
    'Dallas', 'Denver', 'Golden State', 'Houston', 'LA',
    'Los Angeles', 'Memphis', 'Minnesota', 'New Orleans', 'Oklahoma City',
    'Phoenix', 'Portland', 'Sacramento', 'San Antonio', 'Utah'
  ];

  int teamIndex = 0;
  for (var city in eastCities) {
    teams.add(_createTeam('team_$teamIndex', city, 'Team$teamIndex'));
    teamIndex++;
  }

  for (var city in westCities) {
    teams.add(_createTeam('team_$teamIndex', city, 'Team$teamIndex'));
    teamIndex++;
  }

  return teams;
}

// Helper function to create a test team
Team _createTeam(String id, String city, String name) {
  final players = List.generate(15, (i) => _createPlayer('player_${id}_$i'));
  final startingLineupIds = players.take(5).map((p) => p.id).toList();

  return Team(
    id: id,
    city: city,
    name: name,
    players: players,
    startingLineupIds: startingLineupIds,
  );
}

// Helper function to create a test player
Player _createPlayer(String id) {
  return Player(
    id: id,
    name: 'Test Player',
    heightInches: 75,
    shooting: 50,
    defense: 50,
    speed: 50,
    postShooting: 50,
    passing: 50,
    rebounding: 50,
    ballHandling: 50,
    threePoint: 50,
    blocks: 50,
    steals: 50,
    position: 'SG',
  );
}

// Helper function to create a test game
Game _createGame(String homeTeamId, String awayTeamId, {required bool homeWins}) {
  return Game(
    id: 'game_${DateTime.now().millisecondsSinceEpoch}',
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    homeScore: homeWins ? 100 : 90,
    awayScore: homeWins ? 90 : 100,
    isPlayed: true,
    scheduledDate: DateTime.now(),
  );
}

// Helper function to create games with varying win totals
List<Game> _createGamesWithVaryingWins(List<Team> teams) {
  final games = <Game>[];
  
  // Give each team a different number of wins (descending within conference)
  for (int i = 0; i < teams.length; i++) {
    final wins = 60 - (i % 15) * 3; // 60, 57, 54, ... wins
    for (int j = 0; j < wins; j++) {
      games.add(_createGame(teams[i].id, 'opponent_$j', homeWins: true));
    }
  }

  return games;
}
