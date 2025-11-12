import '../models/team.dart';
import 'player_generator.dart';
import 'package:uuid/uuid.dart';

/// Service for managing the 30-team league
/// Handles league initialization and team management
class LeagueService {
  final List<Team> _teams = [];
  final PlayerGenerator _playerGenerator = PlayerGenerator();
  final Uuid _uuid = const Uuid();

  // NBA team names and cities
  static const List<Map<String, String>> _nbaTeams = [
    {'city': 'Atlanta', 'name': 'Hawks'},
    {'city': 'Boston', 'name': 'Celtics'},
    {'city': 'Brooklyn', 'name': 'Nets'},
    {'city': 'Charlotte', 'name': 'Hornets'},
    {'city': 'Chicago', 'name': 'Bulls'},
    {'city': 'Cleveland', 'name': 'Cavaliers'},
    {'city': 'Dallas', 'name': 'Mavericks'},
    {'city': 'Denver', 'name': 'Nuggets'},
    {'city': 'Detroit', 'name': 'Pistons'},
    {'city': 'Golden State', 'name': 'Warriors'},
    {'city': 'Houston', 'name': 'Rockets'},
    {'city': 'Indiana', 'name': 'Pacers'},
    {'city': 'LA', 'name': 'Clippers'},
    {'city': 'Los Angeles', 'name': 'Lakers'},
    {'city': 'Memphis', 'name': 'Grizzlies'},
    {'city': 'Miami', 'name': 'Heat'},
    {'city': 'Milwaukee', 'name': 'Bucks'},
    {'city': 'Minnesota', 'name': 'Timberwolves'},
    {'city': 'New Orleans', 'name': 'Pelicans'},
    {'city': 'New York', 'name': 'Knicks'},
    {'city': 'Oklahoma City', 'name': 'Thunder'},
    {'city': 'Orlando', 'name': 'Magic'},
    {'city': 'Philadelphia', 'name': '76ers'},
    {'city': 'Phoenix', 'name': 'Suns'},
    {'city': 'Portland', 'name': 'Trail Blazers'},
    {'city': 'Sacramento', 'name': 'Kings'},
    {'city': 'San Antonio', 'name': 'Spurs'},
    {'city': 'Toronto', 'name': 'Raptors'},
    {'city': 'Utah', 'name': 'Jazz'},
    {'city': 'Washington', 'name': 'Wizards'},
  ];

  /// Get all teams in the league
  List<Team> get teams => List.unmodifiable(_teams);

  /// Get mutable teams list (for loading saved games)
  List<Team> getTeamsList() => _teams;

  /// Initialize the league with 30 teams, each with 15 players
  Future<void> initializeLeague() async {
    _teams.clear();

    for (final teamData in _nbaTeams) {
      // Generate 15 players for the team
      final players = _playerGenerator.generateTeamRoster(15);

      // Select first 5 players as starting lineup
      final startingLineupIds = players.take(5).map((p) => p.id).toList();

      // Create team
      final team = Team(
        id: _uuid.v4(),
        name: teamData['name']!,
        city: teamData['city']!,
        players: players,
        startingLineupIds: startingLineupIds,
      );

      _teams.add(team);
    }
  }

  /// Get a team by ID
  Team? getTeam(String teamId) {
    try {
      return _teams.firstWhere((team) => team.id == teamId);
    } catch (e) {
      return null;
    }
  }

  /// Update a team (for lineup changes)
  Future<void> updateTeam(Team updatedTeam) async {
    final index = _teams.indexWhere((team) => team.id == updatedTeam.id);
    if (index != -1) {
      _teams[index] = updatedTeam;
    }
  }

  /// Get all teams
  List<Team> getAllTeams() {
    return List.unmodifiable(_teams);
  }
}
