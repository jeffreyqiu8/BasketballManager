import '../models/team.dart';
import '../models/season.dart';
import '../models/game.dart';
import '../models/playoff_bracket.dart';
import '../models/league_schedule.dart';
import 'player_generator.dart';
import 'playoff_service.dart';
import '../utils/playoff_seeding.dart';
import '../utils/playoff_bracket_generator.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

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
    // Use league schedule if available, otherwise fall back to user's games
    final gamesToUse = season.leagueSchedule != null
        ? season.leagueSchedule!.allGames
        : season.games;
    
    // DEBUG: Log game completion status
    print('=== PLAYOFF SEEDING DEBUG ===');
    print('Total games in source: ${gamesToUse.length}');
    final playedGames = gamesToUse.where((g) => g.isPlayed).length;
    print('Games played: $playedGames');
    print('Games remaining: ${gamesToUse.length - playedGames}');
    
    // Validate all games are complete before calculating seedings
    if (season.leagueSchedule != null) {
      final unplayedGames = gamesToUse.where((g) => !g.isPlayed).toList();
      if (unplayedGames.isNotEmpty) {
        print('WARNING: ${unplayedGames.length} league games are not complete!');
        print('This may cause seeding calculation issues.');
        // Show first few unplayed games
        for (var i = 0; i < unplayedGames.length && i < 5; i++) {
          final game = unplayedGames[i];
          print('  Unplayed: ${game.homeTeamId} vs ${game.awayTeamId}');
        }
      }
    }
    
    final seedings = PlayoffSeeding.calculateSeedings(_teams, gamesToUse);

    // DEBUG: Log seedings for all teams
    print('\n=== CALCULATED SEEDINGS ===');
    final eastSeedings = <int, String>{};
    final westSeedings = <int, String>{};
    
    for (var team in _teams) {
      final seed = seedings[team.id];
      final conference = PlayoffSeeding.getConference(team);
      final teamName = '${team.city} ${team.name}';
      
      if (seed != null) {
        if (conference == 'east') {
          eastSeedings[seed] = teamName;
        } else {
          westSeedings[seed] = teamName;
        }
      }
    }
    
    print('\nEastern Conference:');
    for (var seed in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]) {
      if (eastSeedings.containsKey(seed)) {
        print('  $seed. ${eastSeedings[seed]}');
      }
    }
    
    print('\nWestern Conference:');
    for (var seed in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]) {
      if (westSeedings.containsKey(seed)) {
        print('  $seed. ${westSeedings[seed]}');
      }
    }

    // Check if user's team made the playoffs (seeded 10 or better)
    final userTeamSeed = seedings[season.userTeamId];
    final userTeam = getTeam(season.userTeamId);
    final userTeamName = userTeam != null ? '${userTeam.city} ${userTeam.name}' : 'Unknown';
    
    print('\n=== USER TEAM STATUS ===');
    print('Team: $userTeamName');
    print('Seed: ${userTeamSeed ?? "Not seeded"}');
    print('Conference: ${userTeam != null ? PlayoffSeeding.getConference(userTeam) : "Unknown"}');
    
    if (userTeamSeed == null || userTeamSeed > 10) {
      // User's team missed the playoffs (seeded 11-15 or not seeded)
      print('Result: MISSED PLAYOFFS (seed > 10)');
      print('=== END DEBUG ===\n');
      // Don't create a playoff bracket, just mark season as post-season
      return season.copyWith(isPostSeason: true);
    }
    
    print('Result: MADE PLAYOFFS');
    if (userTeamSeed >= 7 && userTeamSeed <= 10) {
      print('Placement: PLAY-IN TOURNAMENT (seeds 7-10)');
    } else {
      print('Placement: DIRECT TO PLAYOFFS (seeds 1-6)');
    }

    // Create conference map for all teams
    final conferences = <String, String>{};
    for (var team in _teams) {
      conferences[team.id] = PlayoffSeeding.getConference(team);
    }

    // Generate play-in tournament games
    print('\n=== GENERATING PLAY-IN GAMES ===');
    final playInGames = PlayoffBracketGenerator.generatePlayInGames(
      seedings,
      conferences,
    );
    
    print('Play-in games generated: ${playInGames.length}');
    for (var game in playInGames) {
      final homeTeam = getTeam(game.homeTeamId);
      final awayTeam = getTeam(game.awayTeamId);
      final homeTeamName = homeTeam != null ? '${homeTeam.city} ${homeTeam.name}' : 'Unknown';
      final awayTeamName = awayTeam != null ? '${awayTeam.city} ${awayTeam.name}' : 'Unknown';
      print('  ${game.conference.toUpperCase()}: $homeTeamName vs $awayTeamName');
    }
    print('=== END DEBUG ===\n');

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

  /// Simulate an entire regular season (all 82 games)
  /// This method simulates all games in the season and updates statistics
  /// Returns the completed season with all games played and stats accumulated
  /// 
  /// Parameters:
  /// - season: The season to simulate (must have 82 unplayed games)
  /// - gameService: The game service to use for simulating individual games
  /// - updateStats: Whether to update season statistics (default: true)
  /// 
  /// Note: This can take some time as it simulates 82 detailed games
  Season simulateEntireRegularSeason(
    Season season,
    dynamic gameService, {
    bool updateStats = true,
  }) {
    if (season.isPostSeason) {
      throw StateError('Cannot simulate regular season for a post-season');
    }

    if (season.games.length != 82) {
      throw StateError('Season must have exactly 82 games');
    }

    var updatedSeason = season;
    final userTeam = getTeam(season.userTeamId);
    
    if (userTeam == null) {
      throw StateError('User team not found');
    }

    // Simulate each game
    for (int i = 0; i < season.games.length; i++) {
      final game = season.games[i];
      
      if (game.isPlayed) {
        continue; // Skip already played games
      }

      // Get teams for this game
      final homeTeam = getTeam(game.homeTeamId);
      final awayTeam = getTeam(game.awayTeamId);

      if (homeTeam == null || awayTeam == null) {
        continue; // Skip if teams not found
      }

      // Simulate the game
      final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);

      // Update the game in the season
      final updatedGames = List<Game>.from(updatedSeason.games);
      updatedGames[i] = simulatedGame.copyWith(
        id: game.id,
        scheduledDate: game.scheduledDate,
      );

      updatedSeason = Season(
        id: updatedSeason.id,
        year: updatedSeason.year,
        games: updatedGames,
        userTeamId: updatedSeason.userTeamId,
        seasonStats: updatedSeason.seasonStats,
        playoffBracket: updatedSeason.playoffBracket,
        playoffStats: updatedSeason.playoffStats,
        isPostSeason: updatedSeason.isPostSeason,
        championshipRecord: updatedSeason.championshipRecord,
        leagueSchedule: updatedSeason.leagueSchedule,
      );

      // Update season statistics if requested
      if (updateStats && simulatedGame.boxScore != null) {
        updatedSeason = updatedSeason.updateSeasonStats(simulatedGame.boxScore!);
      }
    }

    // If league schedule exists, simulate all league games too
    if (updatedSeason.leagueSchedule != null) {
      final updatedSchedule = simulateLeagueGames(
        updatedSeason.leagueSchedule!,
        gameService,
      );
      updatedSeason = updateSeasonWithLeagueSchedule(updatedSeason, updatedSchedule);
    }

    return updatedSeason;
  }

  /// Simulate remaining games in the regular season
  /// This method simulates only the unplayed games in the season
  /// Returns the updated season with newly played games
  /// 
  /// Parameters:
  /// - season: The season to simulate
  /// - gameService: The game service to use for simulating individual games
  /// - updateStats: Whether to update season statistics (default: true)
  Season simulateRemainingRegularSeasonGames(
    Season season,
    dynamic gameService, {
    bool updateStats = true,
  }) {
    if (season.isPostSeason) {
      throw StateError('Cannot simulate regular season for a post-season');
    }

    var updatedSeason = season;
    final userTeam = getTeam(season.userTeamId);
    
    if (userTeam == null) {
      throw StateError('User team not found');
    }

    // Simulate each unplayed game
    for (int i = 0; i < season.games.length; i++) {
      final game = season.games[i];
      
      if (game.isPlayed) {
        continue; // Skip already played games
      }

      // Get teams for this game
      final homeTeam = getTeam(game.homeTeamId);
      final awayTeam = getTeam(game.awayTeamId);

      if (homeTeam == null || awayTeam == null) {
        continue; // Skip if teams not found
      }

      // Simulate the game
      final simulatedGame = gameService.simulateGameDetailed(homeTeam, awayTeam);

      // Update the game in the season
      final updatedGames = List<Game>.from(updatedSeason.games);
      updatedGames[i] = simulatedGame.copyWith(
        id: game.id,
        scheduledDate: game.scheduledDate,
      );

      updatedSeason = Season(
        id: updatedSeason.id,
        year: updatedSeason.year,
        games: updatedGames,
        userTeamId: updatedSeason.userTeamId,
        seasonStats: updatedSeason.seasonStats,
        playoffBracket: updatedSeason.playoffBracket,
        playoffStats: updatedSeason.playoffStats,
        isPostSeason: updatedSeason.isPostSeason,
        championshipRecord: updatedSeason.championshipRecord,
        leagueSchedule: updatedSeason.leagueSchedule,
      );

      // Update season statistics if requested
      if (updateStats && simulatedGame.boxScore != null) {
        updatedSeason = updatedSeason.updateSeasonStats(simulatedGame.boxScore!);
      }
    }

    // If league schedule exists, simulate remaining league games too
    if (updatedSeason.leagueSchedule != null) {
      final updatedSchedule = simulateLeagueGames(
        updatedSeason.leagueSchedule!,
        gameService,
      );
      updatedSeason = updateSeasonWithLeagueSchedule(updatedSeason, updatedSchedule);
    }

    return updatedSeason;
  }

  /// Generate a full league schedule for all 30 teams
  /// Each team plays 82 games, resulting in 1230 total games
  /// Returns a LeagueSchedule with all games
  LeagueSchedule generateLeagueSchedule(String seasonId) {
    final allGames = <Game>[];
    final teamGameIds = <String, List<String>>{};
    final random = Random();

    // Initialize team game ID lists
    for (var team in _teams) {
      teamGameIds[team.id] = [];
    }

    // Generate games using a round-robin approach
    // Each team needs 82 games total
    // With 30 teams, each team plays the other 29 teams multiple times
    
    int gameDay = 0;
    int maxAttempts = 1000;
    int attempts = 0;
    
    // Keep generating games until all teams have 82 games
    while (teamGameIds.values.any((games) => games.length < 82) && attempts < maxAttempts) {
      attempts++;
      
      // Get teams that still need games, sorted by how many they need
      final teamsNeedingGames = _teams
          .where((team) => teamGameIds[team.id]!.length < 82)
          .toList()
        ..shuffle(random);
      
      if (teamsNeedingGames.isEmpty) break;
      
      // Try to create matchups
      final usedTeams = <String>{};
      
      for (int i = 0; i < teamsNeedingGames.length; i++) {
        final team1 = teamsNeedingGames[i];
        
        // Skip if already used in this round
        if (usedTeams.contains(team1.id)) continue;
        
        // Skip if team already has 82 games
        if (teamGameIds[team1.id]!.length >= 82) continue;
        
        // Find an opponent that also needs games and hasn't been used
        Team? opponent;
        for (int j = i + 1; j < teamsNeedingGames.length; j++) {
          final candidate = teamsNeedingGames[j];
          if (!usedTeams.contains(candidate.id) && 
              teamGameIds[candidate.id]!.length < 82) {
            opponent = candidate;
            break;
          }
        }
        
        if (opponent == null) continue;
        
        // Create the game
        final isTeam1Home = random.nextBool();
        
        final game = Game(
          id: _uuid.v4(),
          homeTeamId: isTeam1Home ? team1.id : opponent.id,
          awayTeamId: isTeam1Home ? opponent.id : team1.id,
          homeScore: null,
          awayScore: null,
          isPlayed: false,
          scheduledDate: DateTime.now().add(Duration(days: gameDay)),
        );
        
        allGames.add(game);
        teamGameIds[team1.id]!.add(game.id);
        teamGameIds[opponent.id]!.add(game.id);
        
        // Mark both teams as used in this round
        usedTeams.add(team1.id);
        usedTeams.add(opponent.id);
      }
      
      gameDay++;
    }

    return LeagueSchedule(
      seasonId: seasonId,
      allGames: allGames,
      teamGameIds: teamGameIds,
    );
  }

  /// Simulate all league games for a given day/round
  /// This simulates games across the entire league, not just the user's team
  LeagueSchedule simulateLeagueGames(
    LeagueSchedule schedule,
    dynamic gameService, {
    int? gamesToSimulate,
  }) {
    final updatedGames = List<Game>.from(schedule.allGames);
    int gamesSimulated = 0;
    final maxGames = gamesToSimulate ?? updatedGames.length;

    for (int i = 0; i < updatedGames.length && gamesSimulated < maxGames; i++) {
      final game = updatedGames[i];
      
      if (game.isPlayed) continue;

      // Get teams for this game
      final homeTeam = getTeam(game.homeTeamId);
      final awayTeam = getTeam(game.awayTeamId);

      if (homeTeam == null || awayTeam == null) continue;

      // Simulate the game (use basic simulation for speed)
      final simulatedGame = gameService.simulateGame(homeTeam, awayTeam);

      // Update the game
      updatedGames[i] = simulatedGame.copyWith(
        id: game.id,
        scheduledDate: game.scheduledDate,
      );

      gamesSimulated++;
    }

    return schedule.copyWith(allGames: updatedGames);
  }

  /// Update a season with a league schedule
  /// This syncs the user's 82 games with the corresponding games in the league schedule
  Season updateSeasonWithLeagueSchedule(Season season, LeagueSchedule schedule) {
    // Update the user's games to match the league schedule games
    final updatedUserGames = <Game>[];
    
    for (var userGame in season.games) {
      // Find the corresponding game in the league schedule
      final leagueGame = schedule.allGames.firstWhere(
        (g) => g.id == userGame.id,
        orElse: () => userGame,
      );
      updatedUserGames.add(leagueGame);
    }

    return season.copyWith(
      games: updatedUserGames,
      leagueSchedule: schedule,
    );
  }

  /// Initialize a season with a league schedule
  /// This creates a league schedule and ensures the user's games are part of it
  Season initializeSeasonWithLeagueSchedule(Season season) {
    // Generate league schedule for all 30 teams
    final leagueSchedule = generateLeagueSchedule(season.id);
    
    // Extract the user's 82 games from the league schedule
    final userGameIds = leagueSchedule.teamGameIds[season.userTeamId] ?? [];
    final userGames = leagueSchedule.allGames
        .where((game) => userGameIds.contains(game.id))
        .toList();
    
    // Ensure we have exactly 82 games for the user
    if (userGames.length != 82) {
      throw StateError('User team should have exactly 82 games in league schedule, but has ${userGames.length}');
    }
    
    // Return season with the user's games from the league schedule
    return season.copyWith(
      games: userGames,
      leagueSchedule: leagueSchedule,
    );
  }
}

