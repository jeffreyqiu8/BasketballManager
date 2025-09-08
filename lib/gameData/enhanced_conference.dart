import 'conference_class.dart';
import 'team_class.dart';
import 'enhanced_game_simulation.dart';

/// Enhanced conference class that extends the base Conference with divisions and advanced features
class EnhancedConference extends Conference {
  List<Division> divisions;
  ConferenceStandings standings;
  PlayoffBracket? playoffBracket;
  Map<String, TeamStats> teamStatistics;
  List<Award> seasonAwards;

  EnhancedConference({
    required super.name,
    List<Division>? divisions,
    ConferenceStandings? standings,
    this.playoffBracket,
    Map<String, TeamStats>? teamStatistics,
    List<Award>? seasonAwards,
  }) : divisions = divisions ?? [],
       standings = standings ?? ConferenceStandings.empty(),
       teamStatistics = teamStatistics ?? {},
       seasonAwards = seasonAwards ?? [] {
    
    // Initialize divisions if not provided
    if (this.divisions.isEmpty) {
      _initializeDefaultDivisions();
    }
  }

  /// Initialize default divisions for the conference
  void _initializeDefaultDivisions() {
    if (name.toLowerCase().contains('eastern')) {
      divisions = [
        Division(name: 'Atlantic', teams: <Team>[]),
        Division(name: 'Central', teams: <Team>[]),
        Division(name: 'Southeast', teams: <Team>[]),
      ];
    } else if (name.toLowerCase().contains('western')) {
      divisions = [
        Division(name: 'Northwest', teams: <Team>[]),
        Division(name: 'Pacific', teams: <Team>[]),
        Division(name: 'Southwest', teams: <Team>[]),
      ];
    } else {
      // Generic divisions
      divisions = [
        Division(name: 'North', teams: <Team>[]),
        Division(name: 'South', teams: <Team>[]),
      ];
    }
  }

  /// Update standings based on current team records
  void updateStandings() {
    List<StandingsEntry> entries = [];
    
    for (var team in teams) {
      double winPercentage = (team.wins + team.losses) > 0 
        ? team.wins / (team.wins + team.losses) 
        : 0.0;
      
      TeamStats stats = teamStatistics[team.name] ?? TeamStats.empty();
      
      entries.add(StandingsEntry(
        teamName: team.name,
        wins: team.wins,
        losses: team.losses,
        winPercentage: winPercentage,
        pointsDifferential: stats.pointsFor - stats.pointsAgainst,
        streak: _calculateStreak(team),
        divisionRecord: _calculateDivisionRecord(team),
        conferenceRecord: _calculateConferenceRecord(team),
      ));
    }
    
    // Sort by win percentage (descending), then by points differential
    entries.sort((a, b) {
      int winComparison = b.winPercentage.compareTo(a.winPercentage);
      if (winComparison != 0) return winComparison;
      return b.pointsDifferential.compareTo(a.pointsDifferential);
    });
    
    standings = ConferenceStandings(
      entries: entries,
      headToHeadRecords: _calculateHeadToHeadRecords(),
      strengthOfSchedule: _calculateStrengthOfSchedule(),
    );
  }

  /// Calculate current win/loss streak for a team
  String _calculateStreak(Team team) {
    // This would need access to recent game results
    // For now, return a placeholder
    return 'W1'; // TODO: Implement based on recent games
  }

  /// Calculate division record for a team
  String _calculateDivisionRecord(Team team) {
    // This would need access to division-specific game results
    // For now, return a placeholder
    return '0-0'; // TODO: Implement based on division games
  }

  /// Calculate conference record for a team
  String _calculateConferenceRecord(Team team) {
    // This would need access to conference-specific game results
    // For now, return a placeholder
    return '0-0'; // TODO: Implement based on conference games
  }

  /// Calculate head-to-head records between teams
  Map<String, int> _calculateHeadToHeadRecords() {
    Map<String, int> records = {};
    // TODO: Implement based on game results
    return records;
  }

  /// Calculate strength of schedule for each team
  Map<String, double> _calculateStrengthOfSchedule() {
    Map<String, double> sos = {};
    // TODO: Implement based on opponents' records
    return sos;
  }

  /// Generate playoff bracket
  void generatePlayoffBracket() {
    if (standings.entries.length < 8) return;
    
    List<StandingsEntry> playoffTeams = standings.entries.take(8).toList();
    
    playoffBracket = PlayoffBracket(
      firstRound: _createFirstRoundMatchups(playoffTeams),
      semifinals: [],
      finals: null,
      champion: null,
    );
  }

  /// Create first round playoff matchups
  List<PlayoffMatchup> _createFirstRoundMatchups(List<StandingsEntry> teams) {
    return [
      PlayoffMatchup(higherSeed: teams[0], lowerSeed: teams[7], round: 1),
      PlayoffMatchup(higherSeed: teams[1], lowerSeed: teams[6], round: 1),
      PlayoffMatchup(higherSeed: teams[2], lowerSeed: teams[5], round: 1),
      PlayoffMatchup(higherSeed: teams[3], lowerSeed: teams[4], round: 1),
    ];
  }

  /// Get division standings
  Map<String, List<StandingsEntry>> getDivisionStandings() {
    Map<String, List<StandingsEntry>> divisionStandings = {};
    
    for (var division in divisions) {
      List<StandingsEntry> divisionEntries = standings.entries
          .where((entry) => division.teams.any((team) => team.name == entry.teamName))
          .toList();
      
      divisionStandings[division.name] = divisionEntries;
    }
    
    return divisionStandings;
  }

  /// Play next matchday with enhanced role-based simulation
  void playNextMatchdayEnhanced() {
    // Get all the games for the current matchday
    List<Map<String, dynamic>> currentMatchdayGames = schedule
        .where((game) => game['matchday'] == matchday)
        .toList();

    if (currentMatchdayGames.isEmpty) {
      print('No more games to play.');
      return;
    }

    print('Playing matchday $matchday with enhanced simulation');

    // Simulate the results of the games using enhanced simulation
    for (var game in currentMatchdayGames) {
      Team homeTeam = teams.firstWhere((team) => team.name == game['home']);
      Team awayTeam = teams.firstWhere((team) => team.name == game['away']);

      // Use enhanced game simulation
      final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, matchday);

      // Update the game scores in the schedule
      game['homeScore'] = result['homeScore'];
      game['awayScore'] = result['awayScore'];

      // Update team statistics
      _updateTeamStatistics(homeTeam.name, result['homeBoxScore'], true);
      _updateTeamStatistics(awayTeam.name, result['awayBoxScore'], false);

      // Update the win/loss record for each team
      if (result['homeScore'] > result['awayScore']) {
        homeTeam.updateRecord(true);  // Home team wins
        awayTeam.updateRecord(false); // Away team loses
      } else if (result['homeScore'] < result['awayScore']) {
        homeTeam.updateRecord(false); // Home team loses
        awayTeam.updateRecord(true);  // Away team wins
      }
    }

    // Update standings after all games are played
    updateStandings();

    // After playing the current matchday, increment the matchday
    matchday++;
  }

  /// Update team statistics based on game results
  void _updateTeamStatistics(String teamName, Map<String, Map<String, int>> boxScore, bool isHome) {
    TeamStats stats = teamStatistics[teamName] ?? TeamStats.empty();
    
    // Calculate team totals from box score
    int totalPoints = 0;
    int totalFGM = 0;
    int totalFGA = 0;
    int total3PM = 0;
    int total3PA = 0;
    int totalRebounds = 0;
    int totalAssists = 0;
    int totalTurnovers = 0;
    int totalSteals = 0;
    int totalBlocks = 0;

    for (final playerStats in boxScore.values) {
      totalPoints += playerStats['points'] ?? 0;
      totalFGM += playerStats['FGM'] ?? 0;
      totalFGA += playerStats['FGA'] ?? 0;
      total3PM += playerStats['3PM'] ?? 0;
      total3PA += playerStats['3PA'] ?? 0;
      totalRebounds += playerStats['rebounds'] ?? 0;
      totalAssists += playerStats['assists'] ?? 0;
      totalTurnovers += playerStats['turnovers'] ?? 0;
      totalSteals += playerStats['steals'] ?? 0;
      totalBlocks += playerStats['blocks'] ?? 0;
    }

    // Update cumulative statistics
    stats.pointsFor += totalPoints;
    stats.reboundsPerGame = (stats.reboundsPerGame + totalRebounds) / 2; // Simple average
    stats.assistsPerGame = (stats.assistsPerGame + totalAssists) / 2;
    stats.turnoversPerGame = (stats.turnoversPerGame + totalTurnovers) / 2;
    stats.stealsPerGame = (stats.stealsPerGame + totalSteals) / 2;
    stats.blocksPerGame = (stats.blocksPerGame + totalBlocks) / 2;
    
    if (totalFGA > 0) {
      stats.fieldGoalPercentage = (stats.fieldGoalPercentage + (totalFGM / totalFGA)) / 2;
    }
    
    if (total3PA > 0) {
      stats.threePointPercentage = (stats.threePointPercentage + (total3PM / total3PA)) / 2;
    }

    teamStatistics[teamName] = stats;
  }

  @override
  Map<String, dynamic> toMap() {
    var baseMap = super.toMap();
    baseMap.addAll({
      'divisions': divisions.map((division) => division.toMap()).toList(),
      'standings': standings.toMap(),
      'playoffBracket': playoffBracket?.toMap(),
      'teamStatistics': teamStatistics.map(
        (teamName, stats) => MapEntry(teamName, stats.toMap())
      ),
      'seasonAwards': seasonAwards.map((award) => award.toMap()).toList(),
    });
    return baseMap;
  }

  factory EnhancedConference.fromMap(Map<String, dynamic> map) {
    // Create base conference first
    var baseConference = Conference.fromMap(map);
    
    return EnhancedConference(
      name: baseConference.name,
      divisions: (map['divisions'] as List?)?.map(
        (divisionMap) => Division.fromMap(divisionMap)
      ).toList() ?? [],
      standings: map['standings'] != null
        ? ConferenceStandings.fromMap(map['standings'])
        : ConferenceStandings.empty(),
      playoffBracket: map['playoffBracket'] != null
        ? PlayoffBracket.fromMap(map['playoffBracket'])
        : null,
      teamStatistics: (map['teamStatistics'] as Map<String, dynamic>?)?.map(
        (teamName, statsMap) => MapEntry(teamName, TeamStats.fromMap(statsMap))
      ) ?? {},
      seasonAwards: (map['seasonAwards'] as List?)?.map(
        (awardMap) => Award.fromMap(awardMap)
      ).toList() ?? [],
    )..teams = baseConference.teams
     ..schedule = baseConference.schedule
     ..matchday = baseConference.matchday;
  }
}

/// Division within a conference
class Division {
  String name;
  List<Team> teams;

  Division({
    required this.name,
    required this.teams,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teams': teams.map((team) => team.toMap()).toList(),
    };
  }

  factory Division.fromMap(Map<String, dynamic> map) {
    return Division(
      name: map['name'] ?? '',
      teams: (map['teams'] as List?)?.map(
        (teamMap) => Team.fromMap(teamMap)
      ).toList() ?? [],
    );
  }
}

/// Conference standings with enhanced information
class ConferenceStandings {
  List<StandingsEntry> entries;
  Map<String, int> headToHeadRecords;
  Map<String, double> strengthOfSchedule;

  ConferenceStandings({
    required this.entries,
    required this.headToHeadRecords,
    required this.strengthOfSchedule,
  });

  factory ConferenceStandings.empty() {
    return ConferenceStandings(
      entries: [],
      headToHeadRecords: {},
      strengthOfSchedule: {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entries': entries.map((entry) => entry.toMap()).toList(),
      'headToHeadRecords': headToHeadRecords.map(
        (key, value) => MapEntry(key, value.toString())
      ),
      'strengthOfSchedule': strengthOfSchedule.map(
        (key, value) => MapEntry(key, value.toString())
      ),
    };
  }

  factory ConferenceStandings.fromMap(Map<String, dynamic> map) {
    return ConferenceStandings(
      entries: (map['entries'] as List?)?.map(
        (entryMap) => StandingsEntry.fromMap(entryMap)
      ).toList() ?? [],
      headToHeadRecords: (map['headToHeadRecords'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, int.tryParse(valueStr.toString()) ?? 0)
      ) ?? {},
      strengthOfSchedule: (map['strengthOfSchedule'] as Map<String, dynamic>?)?.map(
        (key, valueStr) => MapEntry(key, double.tryParse(valueStr.toString()) ?? 0.0)
      ) ?? {},
    );
  }
}

/// Individual team entry in standings
class StandingsEntry {
  String teamName;
  int wins;
  int losses;
  double winPercentage;
  double pointsDifferential;
  String streak;
  String divisionRecord;
  String conferenceRecord;

  StandingsEntry({
    required this.teamName,
    required this.wins,
    required this.losses,
    required this.winPercentage,
    required this.pointsDifferential,
    required this.streak,
    required this.divisionRecord,
    required this.conferenceRecord,
  });

  Map<String, dynamic> toMap() {
    return {
      'teamName': teamName,
      'wins': wins.toString(),
      'losses': losses.toString(),
      'winPercentage': winPercentage.toString(),
      'pointsDifferential': pointsDifferential.toString(),
      'streak': streak,
      'divisionRecord': divisionRecord,
      'conferenceRecord': conferenceRecord,
    };
  }

  factory StandingsEntry.fromMap(Map<String, dynamic> map) {
    return StandingsEntry(
      teamName: map['teamName'] ?? '',
      wins: int.tryParse(map['wins']?.toString() ?? '0') ?? 0,
      losses: int.tryParse(map['losses']?.toString() ?? '0') ?? 0,
      winPercentage: double.tryParse(map['winPercentage']?.toString() ?? '0.0') ?? 0.0,
      pointsDifferential: double.tryParse(map['pointsDifferential']?.toString() ?? '0.0') ?? 0.0,
      streak: map['streak'] ?? '',
      divisionRecord: map['divisionRecord'] ?? '0-0',
      conferenceRecord: map['conferenceRecord'] ?? '0-0',
    );
  }
}

/// Team statistics for advanced analytics
class TeamStats {
  double pointsFor;
  double pointsAgainst;
  double fieldGoalPercentage;
  double threePointPercentage;
  double freeThrowPercentage;
  double reboundsPerGame;
  double assistsPerGame;
  double turnoversPerGame;
  double stealsPerGame;
  double blocksPerGame;

  TeamStats({
    required this.pointsFor,
    required this.pointsAgainst,
    required this.fieldGoalPercentage,
    required this.threePointPercentage,
    required this.freeThrowPercentage,
    required this.reboundsPerGame,
    required this.assistsPerGame,
    required this.turnoversPerGame,
    required this.stealsPerGame,
    required this.blocksPerGame,
  });

  factory TeamStats.empty() {
    return TeamStats(
      pointsFor: 0.0,
      pointsAgainst: 0.0,
      fieldGoalPercentage: 0.0,
      threePointPercentage: 0.0,
      freeThrowPercentage: 0.0,
      reboundsPerGame: 0.0,
      assistsPerGame: 0.0,
      turnoversPerGame: 0.0,
      stealsPerGame: 0.0,
      blocksPerGame: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pointsFor': pointsFor.toString(),
      'pointsAgainst': pointsAgainst.toString(),
      'fieldGoalPercentage': fieldGoalPercentage.toString(),
      'threePointPercentage': threePointPercentage.toString(),
      'freeThrowPercentage': freeThrowPercentage.toString(),
      'reboundsPerGame': reboundsPerGame.toString(),
      'assistsPerGame': assistsPerGame.toString(),
      'turnoversPerGame': turnoversPerGame.toString(),
      'stealsPerGame': stealsPerGame.toString(),
      'blocksPerGame': blocksPerGame.toString(),
    };
  }

  factory TeamStats.fromMap(Map<String, dynamic> map) {
    return TeamStats(
      pointsFor: double.tryParse(map['pointsFor']?.toString() ?? '0.0') ?? 0.0,
      pointsAgainst: double.tryParse(map['pointsAgainst']?.toString() ?? '0.0') ?? 0.0,
      fieldGoalPercentage: double.tryParse(map['fieldGoalPercentage']?.toString() ?? '0.0') ?? 0.0,
      threePointPercentage: double.tryParse(map['threePointPercentage']?.toString() ?? '0.0') ?? 0.0,
      freeThrowPercentage: double.tryParse(map['freeThrowPercentage']?.toString() ?? '0.0') ?? 0.0,
      reboundsPerGame: double.tryParse(map['reboundsPerGame']?.toString() ?? '0.0') ?? 0.0,
      assistsPerGame: double.tryParse(map['assistsPerGame']?.toString() ?? '0.0') ?? 0.0,
      turnoversPerGame: double.tryParse(map['turnoversPerGame']?.toString() ?? '0.0') ?? 0.0,
      stealsPerGame: double.tryParse(map['stealsPerGame']?.toString() ?? '0.0') ?? 0.0,
      blocksPerGame: double.tryParse(map['blocksPerGame']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

/// Playoff bracket system
class PlayoffBracket {
  List<PlayoffMatchup> firstRound;
  List<PlayoffMatchup> semifinals;
  PlayoffMatchup? finals;
  StandingsEntry? champion;

  PlayoffBracket({
    required this.firstRound,
    required this.semifinals,
    this.finals,
    this.champion,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstRound': firstRound.map((matchup) => matchup.toMap()).toList(),
      'semifinals': semifinals.map((matchup) => matchup.toMap()).toList(),
      'finals': finals?.toMap(),
      'champion': champion?.toMap(),
    };
  }

  factory PlayoffBracket.fromMap(Map<String, dynamic> map) {
    return PlayoffBracket(
      firstRound: (map['firstRound'] as List?)?.map(
        (matchupMap) => PlayoffMatchup.fromMap(matchupMap)
      ).toList() ?? [],
      semifinals: (map['semifinals'] as List?)?.map(
        (matchupMap) => PlayoffMatchup.fromMap(matchupMap)
      ).toList() ?? [],
      finals: map['finals'] != null
        ? PlayoffMatchup.fromMap(map['finals'])
        : null,
      champion: map['champion'] != null
        ? StandingsEntry.fromMap(map['champion'])
        : null,
    );
  }
}

/// Individual playoff matchup
class PlayoffMatchup {
  StandingsEntry higherSeed;
  StandingsEntry lowerSeed;
  int round;
  int higherSeedWins;
  int lowerSeedWins;
  bool isComplete;
  StandingsEntry? winner;

  PlayoffMatchup({
    required this.higherSeed,
    required this.lowerSeed,
    required this.round,
    this.higherSeedWins = 0,
    this.lowerSeedWins = 0,
    this.isComplete = false,
    this.winner,
  });

  Map<String, dynamic> toMap() {
    return {
      'higherSeed': higherSeed.toMap(),
      'lowerSeed': lowerSeed.toMap(),
      'round': round.toString(),
      'higherSeedWins': higherSeedWins.toString(),
      'lowerSeedWins': lowerSeedWins.toString(),
      'isComplete': isComplete.toString(),
      'winner': winner?.toMap(),
    };
  }

  factory PlayoffMatchup.fromMap(Map<String, dynamic> map) {
    return PlayoffMatchup(
      higherSeed: StandingsEntry.fromMap(map['higherSeed']),
      lowerSeed: StandingsEntry.fromMap(map['lowerSeed']),
      round: int.tryParse(map['round']?.toString() ?? '1') ?? 1,
      higherSeedWins: int.tryParse(map['higherSeedWins']?.toString() ?? '0') ?? 0,
      lowerSeedWins: int.tryParse(map['lowerSeedWins']?.toString() ?? '0') ?? 0,
      isComplete: map['isComplete']?.toString().toLowerCase() == 'true',
      winner: map['winner'] != null
        ? StandingsEntry.fromMap(map['winner'])
        : null,
    );
  }
}

/// Season awards
class Award {
  String name;
  String description;
  String recipient;
  String category;
  int season;

  Award({
    required this.name,
    required this.description,
    required this.recipient,
    required this.category,
    required this.season,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'recipient': recipient,
      'category': category,
      'season': season.toString(),
    };
  }

  factory Award.fromMap(Map<String, dynamic> map) {
    return Award(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      recipient: map['recipient'] ?? '',
      category: map['category'] ?? '',
      season: int.tryParse(map['season']?.toString() ?? '1') ?? 1,
    );
  }
}