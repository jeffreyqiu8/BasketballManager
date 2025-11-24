import '../models/team.dart';
import '../models/season.dart';
import '../models/playoff_bracket.dart';
import 'player_generator.dart';
import 'playoff_service.dart';
import '../utils/playoff_seeding.dart';
import '../utils/playoff_bracket_generator.dart';
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

  /// Check if the regular season is complete
  /// A regular season is complete when 82 games have been played by the user's team
  /// Requirements: 21.1
  bool isRegularSeasonComplete(Season season) {
    // Check if the user's team has played all 82 games
    return season.gamesPlayed >= 82;
  }

  /// Check if the regular season is complete and start the post-season if needed
  /// This method should be called after each game is played
  /// Requirements: 21.1, 21.2, 21.5
  Season? checkAndStartPostSeason(Season season) {
    // Only start post-season if:
    // 1. Regular season is complete
    // 2. Not already in post-season
    if (!isRegularSeasonComplete(season) || season.isPostSeason) {
      return null;
    }

    // Generate playoff seedings based on regular season records
    // Note: We need all games from all teams to calculate proper seedings
    // For now, we'll use the user's team games as a proxy
    // In a full implementation, we'd track all 1230 games across the league
    final seedings = PlayoffSeeding.calculateSeedings(_teams, season.games);

    // Create conference map for all teams
    final conferences = <String, String>{};
    for (var team in _teams) {
      conferences[team.id] = PlayoffSeeding.getConference(team);
    }

    // Generate play-in tournament games
    final playInGames = PlayoffBracketGenerator.generatePlayInGames(
      seedings,
      conferences,
    );

    // Create the playoff bracket
    final playoffBracket = PlayoffBracket(
      seasonId: season.id,
      teamSeedings: seedings,
      teamConferences: conferences,
      playInGames: playInGames,
      firstRound: [],
      conferenceSemis: [],
      conferenceFinals: [],
      nbaFinals: null,
      currentRound: 'play-in',
    );

    // Start the post-season with the generated bracket
    return season.startPostSeason(playoffBracket);
  }

  /// Advance the playoff bracket to the next round
  /// This method checks if the current round is complete and generates the next round
  /// Requirements: 24.1, 24.2, 24.3, 24.4, 27.3
  PlayoffBracket advancePlayoffRound(PlayoffBracket bracket) {
    return PlayoffService.advancePlayoffRound(bracket);
  }
}
