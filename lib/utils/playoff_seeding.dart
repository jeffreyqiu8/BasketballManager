import '../models/team.dart';
import '../models/game.dart';

/// Utility class for calculating playoff seedings based on regular season records
/// Separates teams into Eastern and Western conferences and assigns seeds 1-15
class PlayoffSeeding {
  // Eastern Conference cities (15 teams)
  static const List<String> _easternConferenceCities = [
    'Atlanta',
    'Boston',
    'Brooklyn',
    'Charlotte',
    'Chicago',
    'Cleveland',
    'Detroit',
    'Indiana',
    'Miami',
    'Milwaukee',
    'New York',
    'Orlando',
    'Philadelphia',
    'Toronto',
    'Washington',
  ];

  // Western Conference cities (15 teams)
  static const List<String> _westernConferenceCities = [
    'Dallas',
    'Denver',
    'Golden State',
    'Houston',
    'LA',
    'Los Angeles',
    'Memphis',
    'Minnesota',
    'New Orleans',
    'Oklahoma City',
    'Phoenix',
    'Portland',
    'Sacramento',
    'San Antonio',
    'Utah',
  ];

  /// Calculate playoff seedings for all teams based on regular season records
  /// Returns a Map of teamId -> seed (1-15 within each conference)
  static Map<String, int> calculateSeedings(
    List<Team> teams,
    List<Game> allGames,
  ) {
    // Calculate win-loss records for each team
    final winRecords = _calculateWinLossRecords(teams, allGames);
    final lossRecords = _calculateLossRecords(teams, allGames);

    // Separate teams by conference
    final eastTeams = teams.where((t) => isEasternConference(t)).toList();
    final westTeams = teams.where((t) => !isEasternConference(t)).toList();

    // Sort teams by wins (descending), then by win percentage within each conference
    // This matches the standings page sorting logic
    eastTeams.sort((a, b) {
      final aWins = winRecords[a.id] ?? 0;
      final bWins = winRecords[b.id] ?? 0;
      
      // First compare by wins
      if (aWins != bWins) {
        return bWins.compareTo(aWins); // Descending order
      }
      
      // If wins are equal, use win percentage as tiebreaker
      final aLosses = lossRecords[a.id] ?? 0;
      final bLosses = lossRecords[b.id] ?? 0;
      final aWinPct = (aWins + aLosses) > 0 ? aWins / (aWins + aLosses) : 0.0;
      final bWinPct = (bWins + bLosses) > 0 ? bWins / (bWins + bLosses) : 0.0;
      
      if (aWinPct != bWinPct) {
        return bWinPct.compareTo(aWinPct); // Descending order
      }
      
      // If still tied, use team name for stable sorting
      return '${a.city} ${a.name}'.compareTo('${b.city} ${b.name}');
    });

    westTeams.sort((a, b) {
      final aWins = winRecords[a.id] ?? 0;
      final bWins = winRecords[b.id] ?? 0;
      
      // First compare by wins
      if (aWins != bWins) {
        return bWins.compareTo(aWins); // Descending order
      }
      
      // If wins are equal, use win percentage as tiebreaker
      final aLosses = lossRecords[a.id] ?? 0;
      final bLosses = lossRecords[b.id] ?? 0;
      final aWinPct = (aWins + aLosses) > 0 ? aWins / (aWins + aLosses) : 0.0;
      final bWinPct = (bWins + bLosses) > 0 ? bWins / (bWins + bLosses) : 0.0;
      
      if (aWinPct != bWinPct) {
        return bWinPct.compareTo(aWinPct); // Descending order
      }
      
      // If still tied, use team name for stable sorting
      return '${a.city} ${a.name}'.compareTo('${b.city} ${b.name}');
    });

    // Assign seeds 1-15 to teams in each conference
    final seedings = <String, int>{};

    for (int i = 0; i < eastTeams.length; i++) {
      seedings[eastTeams[i].id] = i + 1;
    }

    for (int i = 0; i < westTeams.length; i++) {
      seedings[westTeams[i].id] = i + 1;
    }

    return seedings;
  }

  /// Determine if a team is in the Eastern Conference based on city
  static bool isEasternConference(Team team) {
    // Check if team is in Eastern Conference
    if (_easternConferenceCities.contains(team.city)) {
      return true;
    }
    // Verify team is in Western Conference (for validation)
    if (_westernConferenceCities.contains(team.city)) {
      return false;
    }
    // Default to Eastern Conference if city not found (shouldn't happen)
    return true;
  }

  /// Get the conference name for a team ('east' or 'west')
  static String getConference(Team team) {
    return isEasternConference(team) ? 'east' : 'west';
  }

  /// Calculate win-loss records for all teams from a list of games
  /// Returns a Map of teamId -> number of wins
  static Map<String, int> _calculateWinLossRecords(
    List<Team> teams,
    List<Game> allGames,
  ) {
    final records = <String, int>{};

    // Initialize all teams with 0 wins
    for (var team in teams) {
      records[team.id] = 0;
    }

    // Count wins from played games
    for (var game in allGames) {
      if (!game.isPlayed) continue;

      if (game.homeTeamWon) {
        records[game.homeTeamId] = (records[game.homeTeamId] ?? 0) + 1;
      } else if (game.awayTeamWon) {
        records[game.awayTeamId] = (records[game.awayTeamId] ?? 0) + 1;
      }
    }

    return records;
  }

  /// Calculate loss records for all teams from a list of games
  /// Returns a Map of teamId -> number of losses
  static Map<String, int> _calculateLossRecords(
    List<Team> teams,
    List<Game> allGames,
  ) {
    final records = <String, int>{};

    // Initialize all teams with 0 losses
    for (var team in teams) {
      records[team.id] = 0;
    }

    // Count losses from played games
    for (var game in allGames) {
      if (!game.isPlayed) continue;

      if (game.homeTeamWon) {
        // Away team lost
        records[game.awayTeamId] = (records[game.awayTeamId] ?? 0) + 1;
      } else if (game.awayTeamWon) {
        // Home team lost
        records[game.homeTeamId] = (records[game.homeTeamId] ?? 0) + 1;
      }
    }

    return records;
  }

  /// Get all teams in a specific conference
  static List<Team> getTeamsByConference(
    List<Team> teams,
    String conference,
  ) {
    if (conference == 'east') {
      return teams.where((t) => isEasternConference(t)).toList();
    } else {
      return teams.where((t) => !isEasternConference(t)).toList();
    }
  }

  /// Get teams sorted by seeding for a specific conference
  static List<Team> getSeededTeams(
    List<Team> teams,
    Map<String, int> seedings,
    String conference,
  ) {
    final conferenceTeams = getTeamsByConference(teams, conference);
    conferenceTeams.sort((a, b) {
      final aSeed = seedings[a.id] ?? 99;
      final bSeed = seedings[b.id] ?? 99;
      return aSeed.compareTo(bSeed); // Ascending order (1, 2, 3, ...)
    });
    return conferenceTeams;
  }
}
