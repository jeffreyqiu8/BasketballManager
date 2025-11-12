import 'package:flutter/foundation.dart';
import 'enhanced_coach.dart';
import 'game_result.dart';
import 'enums.dart';

/// Service for managing comprehensive career statistics and historical tracking
class CareerStatisticsService {
  // Singleton instance
  static final CareerStatisticsService instance = CareerStatisticsService._internal();
  CareerStatisticsService._internal();

  /// Track a completed game and update all relevant statistics
  Future<void> trackGameResult(GameResult result, CoachProfile coach) async {
    try {
      // Update coach history
      final bool isWin = result.homeTeam == coach.team.toString() ? 
        result.homeScore > result.awayScore :
        result.awayScore > result.homeScore;

      // Update season record
      _updateSeasonRecord(coach, isWin);

      // Track player performances
      _trackPlayerPerformances(result, coach);

      // Check for achievements
      _checkForAchievements(coach);

      // Update coaching effectiveness metrics
      _updateCoachingEffectiveness(result, coach);
    } catch (e) {
      debugPrint('Error tracking game result: $e');
    }
  }

  /// Update season record in coach history
  void _updateSeasonRecord(CoachProfile coach, bool isWin) {
    if (coach.history.seasonRecords.isEmpty || 
        coach.history.seasonRecords.last.season != coach.history.totalGames ~/ 82 + 1) {
      // Start new season record
      coach.history.seasonRecords.add(SeasonRecord(
        season: coach.history.totalGames ~/ 82 + 1,
        wins: isWin ? 1 : 0,
        losses: isWin ? 0 : 1,
        madePlayoffs: false, // Will be updated when playoffs start
        wonChampionship: false, // Will be updated if championship is won
        teamName: coach.team.toString(),
      ));
    } else {
      // Update current season record
      final currentRecord = coach.history.seasonRecords.last;
      if (isWin) {
        currentRecord.wins++;
      } else {
        currentRecord.losses++;
      }
    }

    // Update total career stats
    if (isWin) {
      coach.history.totalWins++;
    } else {
      coach.history.totalLosses++;
    }
    coach.history.totalGames++;
  }

  /// Track individual player performances for development tracking
  void _trackPlayerPerformances(GameResult result, CoachProfile coach) {
    // For now, we'll simulate player stats since the GameResult structure needs to be updated
    // This is a placeholder implementation that will be enhanced when the full match history system is integrated
    
    // Simulate tracking 5-8 players per game
    final playerCount = 5 + (result.homeScore % 4); // Vary between 5-8 players
    
    for (int i = 0; i < playerCount; i++) {
      final playerId = 'player_${result.gameId}_$i';
      
      // Track player development under coach
      if (!coach.history.playersDeveloped.containsKey(playerId)) {
        coach.history.playersDeveloped[playerId] = 0;
      }

      // Simulate development points based on game outcome
      int developmentPoints = _calculateSimulatedDevelopmentPoints(result, coach);
      coach.history.playersDeveloped[playerId] = 
        (coach.history.playersDeveloped[playerId] ?? 0) + developmentPoints;
    }
  }

  /// Calculate simulated development points from game result
  int _calculateSimulatedDevelopmentPoints(GameResult result, CoachProfile coach) {
    int points = 0;
    
    // Base points for playing in the game
    points += 2;
    
    // Bonus points for winning
    final isWin = result.homeTeam == coach.team.toString() ? 
      result.homeScore > result.awayScore :
      result.awayScore > result.homeScore;
    
    if (isWin) {
      points += 3;
    }
    
    // Bonus based on score differential (competitive games = more development)
    final scoreDiff = (result.homeScore - result.awayScore).abs();
    if (scoreDiff <= 5) {
      points += 2; // Close game bonus
    }
    
    // Coach development bonus
    final developmentBonus = coach.getDevelopmentBonus();
    points += (developmentBonus * 10).round();
    
    return points.clamp(1, 15);
  }

  /// Check and award achievements based on career milestones
  void _checkForAchievements(CoachProfile coach) {
    // Wins achievements
    if (coach.history.totalWins >= 500 && !coach.hasAchievement('500 Career Wins')) {
      coach.achievements.add(Achievement(
        name: '500 Career Wins',
        description: 'Achieved 500 career wins as a head coach',
        type: AchievementType.wins,
        unlockedDate: DateTime.now(),
      ));
    }

    // Championship achievements
    if (coach.history.championships >= 3 && !coach.hasAchievement('Dynasty Builder')) {
      coach.achievements.add(Achievement(
        name: 'Dynasty Builder',
        description: 'Won 3 or more championships',
        type: AchievementType.championships,
        unlockedDate: DateTime.now(),
      ));
    }

    // Development achievements
    int totalDevelopedPlayers = coach.history.playersDeveloped.values
      .where((points) => points >= 100).length;
    if (totalDevelopedPlayers >= 10 && !coach.hasAchievement('Player Developer')) {
      coach.achievements.add(Achievement(
        name: 'Player Developer',
        description: 'Successfully developed 10 players to their potential',
        type: AchievementType.development,
        unlockedDate: DateTime.now(),
      ));
    }
  }

  /// Update coaching effectiveness metrics based on game results
  void _updateCoachingEffectiveness(GameResult result, CoachProfile coach) {
    // Simulate team performance metrics based on game result
    final isWin = result.homeTeam == coach.team.toString() ? 
      result.homeScore > result.awayScore :
      result.awayScore > result.homeScore;
    
    final teamScore = result.homeTeam == coach.team.toString() ? 
      result.homeScore : result.awayScore;
    
    final opponentScore = result.homeTeam == coach.team.toString() ? 
      result.awayScore : result.homeScore;

    // Update coaching attributes based on performance
    _updateCoachingAttributes(teamScore, opponentScore, isWin, coach);
  }

  /// Update coaching attributes based on team performance
  void _updateCoachingAttributes(int teamScore, int opponentScore, bool isWin, CoachProfile coach) {
    // Update offensive coaching based on team scoring
    if (teamScore >= 110) {
      coach.coachingAttributes['offensive'] = 
        (coach.coachingAttributes['offensive']! + 1).clamp(0, 100);
    }

    // Update defensive coaching based on opponent scoring
    if (opponentScore <= 100) {
      coach.coachingAttributes['defensive'] = 
        (coach.coachingAttributes['defensive']! + 1).clamp(0, 100);
    }

    // Update development coaching based on player improvements
    int improvedPlayers = coach.history.playersDeveloped.values
      .where((points) => points > 0).length;
    if (improvedPlayers > 0) {
      coach.coachingAttributes['development'] = 
        (coach.coachingAttributes['development']! + 1).clamp(0, 100);
    }

    // Update chemistry based on wins
    if (isWin) {
      coach.coachingAttributes['chemistry'] = 
        (coach.coachingAttributes['chemistry']! + 1).clamp(0, 100);
    }

    // Recalculate team bonuses after attribute updates
    coach.calculateTeamBonuses();
  }

  /// Get career statistics summary
  Map<String, dynamic> getCareerSummary(CoachProfile coach) {
    return {
      'totalWins': coach.history.totalWins,
      'totalLosses': coach.history.totalLosses,
      'winPercentage': coach.history.winPercentage,
      'championships': coach.history.championships,
      'playoffAppearances': coach.history.playoffAppearances,
      'seasonsCoached': coach.history.seasonRecords.length,
      'playersDeveloped': coach.history.playersDeveloped.length,
      'achievements': coach.achievements.length,
      'coachingLevel': coach.experienceLevel,
    };
  }

  /// Get detailed season-by-season statistics
  List<Map<String, dynamic>> getSeasonHistory(CoachProfile coach) {
    return coach.history.seasonRecords.map((season) => {
      'season': season.season,
      'wins': season.wins,
      'losses': season.losses,
      'winPercentage': season.winPercentage,
      'madePlayoffs': season.madePlayoffs,
      'wonChampionship': season.wonChampionship,
      'teamName': season.teamName,
    }).toList();
  }

  /// Get player development history
  Map<String, dynamic> getPlayerDevelopmentHistory(CoachProfile coach) {
    return {
      'totalPlayersDeveloped': coach.history.playersDeveloped.length,
      'developmentPoints': coach.history.playersDeveloped,
      'developmentBonus': coach.getDevelopmentBonus(),
      'specialization': coach.primarySpecialization == CoachingSpecialization.playerDevelopment,
    };
  }

  /// Get coaching effectiveness metrics
  Map<String, dynamic> getCoachingEffectiveness(CoachProfile coach) {
    return {
      'offensiveRating': coach.coachingAttributes['offensive'] ?? 50,
      'defensiveRating': coach.coachingAttributes['defensive'] ?? 50,
      'developmentRating': coach.coachingAttributes['development'] ?? 50,
      'chemistryRating': coach.coachingAttributes['chemistry'] ?? 50,
      'experienceLevel': coach.experienceLevel,
      'teamBonuses': coach.teamBonuses,
    };
  }
}