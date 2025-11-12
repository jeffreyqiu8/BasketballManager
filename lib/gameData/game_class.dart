import 'package:BasketballManager/gameData/coach.dart';
import 'package:BasketballManager/gameData/conference.dart';
import 'package:BasketballManager/gameData/game_result.dart';
import 'package:BasketballManager/gameData/league_structure.dart';
import 'package:BasketballManager/gameData/thirty_team_league_service.dart';

class Game {
  Manager currentManager;
  EnhancedConference currentConference;
  LeagueStructure? leagueStructure;
  String? saveId;
  String? userId;

  
  Game({
    required this.currentManager, 
    required this.currentConference,
    this.leagueStructure,
    this.saveId,
    this.userId,
  });

  /// Set user context for this game save
  void setUserContext(String userId, String saveId) {
    this.userId = userId;
    this.saveId = saveId;
    currentConference.initializeMatchHistory(userId, saveId);
  }
  
  Manager get getCurrentManager => currentManager;
  EnhancedConference get getCurrentConference => currentConference;

  /// Get match history for the current season
  Future<List<GameResult>> getCurrentSeasonHistory() async {
    return await currentConference.getCurrentSeasonHistory();
  }

  /// Get match history for the managed team
  Future<List<GameResult>> getManagedTeamHistory() async {
    final managedTeam = currentConference.teams[currentManager.team];
    return await currentConference.getTeamHistory(managedTeam.name);
  }

  /// Get recent games across the league
  Future<List<GameResult>> getRecentGames({int limit = 10}) async {
    return await currentConference.getRecentGames(limit: limit);
  }

  /// Initialize 30-team league structure
  void initializeThirtyTeamLeague({
    bool useRealTeams = true,
    Map<String, int>? customRosterSizes,
    Map<String, double>? customSalaryCaps,
  }) {
    leagueStructure = ThirtyTeamLeagueService.generateThirtyTeamLeague(
      useRealTeams: useRealTeams,
      customRosterSizes: customRosterSizes,
      customSalaryCaps: customSalaryCaps,
    );
    
    // Update current conference to be part of the league structure
    if (leagueStructure!.conferences.isNotEmpty) {
      // Find the conference that matches the current one or use the first one
      EnhancedConference? matchingConference = leagueStructure!.conferences
          .where((conf) => conf.name == currentConference.name)
          .firstOrNull;
      
      if (matchingConference != null) {
        currentConference = matchingConference;
      } else {
        currentConference = leagueStructure!.conferences.first;
      }
    }
  }

  /// Get league-wide standings
  List<StandingsEntry> getLeagueStandings() {
    if (leagueStructure == null) return [];
    return ThirtyTeamLeagueService.getLeagueWideStandings(leagueStructure!);
  }

  /// Get playoff seedings for both conferences
  Map<String, List<StandingsEntry>> getPlayoffSeedings() {
    if (leagueStructure == null) return {};
    return ThirtyTeamLeagueService.getPlayoffSeedings(leagueStructure!);
  }

  /// Simulate complete 82-game season
  void simulateCompleteSeason() {
    if (leagueStructure == null) return;
    ThirtyTeamLeagueService.simulateCompleteSeason(leagueStructure!);
  }

  /// Get other conference (for inter-conference games)
  EnhancedConference? getOtherConference() {
    if (leagueStructure == null) return null;
    return leagueStructure!.conferences
        .where((conf) => conf.name != currentConference.name)
        .firstOrNull;
  }

  // Convert the Game to a Map for storage (e.g., Firebase)
  Map<String, dynamic> toMap() {
    return {
      'currentManager': currentManager.toMap(),
      'currentConference': currentConference.toLightweightMap(),
      'leagueStructure': leagueStructure?.toMap(),
      'saveId': saveId,
      'userId': userId,
    };
  } 

  // Convert the Game to a lightweight Map for Firestore storage (under 1MB limit)
  Map<String, dynamic> toLightweightMap() {
    return {
      'currentManager': currentManager.toMap(),
      'currentConference': currentConference.toLightweightMap(
        managedTeamName: currentConference.teams.length > currentManager.team 
          ? currentConference.teams[currentManager.team].name 
          : null,
      ),
      'leagueStructure': leagueStructure != null ? {
        'isThirtyTeamLeague': true,
        'currentSeason': leagueStructure!.currentSeason,
        'totalTeams': leagueStructure!.allTeams.length,
        'conferences': leagueStructure!.conferences.length,
      } : null,
      'version': '1.0',
      'created': DateTime.now().toIso8601String(),
      'isLightweight': true,
      'saveId': saveId,
      'userId': userId,
    };
  }

  // Convert a Map back into a Game object (e.g., after retrieving from Firebase)
  factory Game.fromMap(Map<String, dynamic> map) {
    EnhancedConference conference;
    
    if (map['isLightweight'] == true) {
      // Handle lightweight data
      conference = EnhancedConference.fromLightweightMap(map['currentConference'] as Map<String, dynamic>);
    } else {
      // Handle full data
      conference = EnhancedConference.fromMap(map['currentConference'] as Map<String, dynamic>);
    }
    
    final manager = Manager.fromMap(map['currentManager'] as Map<String, dynamic>);
    
    // For lightweight saves, fix the manager's team index to match the managed team
    if (map['isLightweight'] == true) {
      final managedTeamName = map['currentConference']['managedTeam'] as String?;
      if (managedTeamName != null) {
        final managedTeamIndex = conference.teams.indexWhere((team) => team.name == managedTeamName);
        if (managedTeamIndex >= 0) {
          manager.team = managedTeamIndex;
        }
      }
    }

    // Reconstruct league structure if available
    LeagueStructure? leagueStructure;
    if (map['leagueStructure'] != null) {
      if (map['isLightweight'] == true && map['leagueStructure']['isThirtyTeamLeague'] == true) {
        // For lightweight saves, regenerate the 30-team league
        leagueStructure = ThirtyTeamLeagueService.generateThirtyTeamLeague();
        
        // Update the conference to match the one from the league structure
        EnhancedConference? matchingConference = leagueStructure.conferences
            .where((conf) => conf.name == conference.name)
            .firstOrNull;
        if (matchingConference != null) {
          conference = matchingConference;
        }
      } else {
        // Full league structure data
        leagueStructure = LeagueStructure.fromMap(map['leagueStructure']);
      }
    }
    
    return Game(
      currentManager: manager,
      currentConference: conference,
      leagueStructure: leagueStructure,
      saveId: map['saveId'] as String?,
      userId: map['userId'] as String?,
    );
  }
}
