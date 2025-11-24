import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/player_playoff_stats.dart';
import 'package:BasketballManager/models/championship_record.dart';

void main() {
  group('Championship Celebration Tests', () {
    test('Season completePlayoffs creates championship record', () {
      // Create a season with completed playoffs
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final playoffBracket = PlayoffBracket(
        seasonId: 'season-2024',
        teamSeedings: {'team-1': 1, 'team-2': 2},
        teamConferences: {'team-1': 'east', 'team-2': 'west'},
        playInGames: [],
        firstRound: [],
        conferenceSemis: [],
        conferenceFinals: [],
        nbaFinals: PlayoffSeries(
          id: 'finals',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeWins: 4,
          awayWins: 2,
          round: 'finals',
          conference: 'finals',
          gameIds: [],
          isComplete: true,
        ),
        currentRound: 'complete',
      );

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
        isPostSeason: true,
        playoffBracket: playoffBracket,
      );

      // Complete the playoffs
      final updatedSeason = season.completePlayoffs('team-1', 'team-2');

      // Verify championship record was created
      expect(updatedSeason.championshipRecord, isNotNull);
      expect(updatedSeason.championshipRecord!.year, 2024);
      expect(updatedSeason.championshipRecord!.championTeamId, 'team-1');
      expect(updatedSeason.championshipRecord!.runnerUpTeamId, 'team-2');
    });

    test('calculateFinalsMvp returns player with best stats', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      // Create playoff stats for multiple players
      final playoffStats = {
        'player-1': PlayerPlayoffStats(
          playerId: 'player-1',
          gamesPlayed: 16,
          totalPoints: 400, // 25 PPG
          totalRebounds: 160, // 10 RPG
          totalAssists: 80, // 5 APG
          totalSteals: 32, // 2 SPG
          totalBlocks: 16, // 1 BPG
          totalTurnovers: 48,
          totalFouls: 48,
          totalFieldGoalsMade: 160,
          totalFieldGoalsAttempted: 320,
          totalThreePointersMade: 48,
          totalThreePointersAttempted: 120,
          totalFreeThrowsMade: 32,
          totalFreeThrowsAttempted: 40,
        ),
        'player-2': PlayerPlayoffStats(
          playerId: 'player-2',
          gamesPlayed: 16,
          totalPoints: 320, // 20 PPG
          totalRebounds: 128, // 8 RPG
          totalAssists: 64, // 4 APG
          totalSteals: 16, // 1 SPG
          totalBlocks: 8, // 0.5 BPG
          totalTurnovers: 32,
          totalFouls: 32,
          totalFieldGoalsMade: 128,
          totalFieldGoalsAttempted: 256,
          totalThreePointersMade: 32,
          totalThreePointersAttempted: 96,
          totalFreeThrowsMade: 32,
          totalFreeThrowsAttempted: 40,
        ),
      };

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
        isPostSeason: true,
        playoffStats: playoffStats,
      );

      // Calculate MVP
      final mvpId = season.calculateFinalsMvp('team-1');

      // Player 1 should be MVP (higher stats)
      expect(mvpId, 'player-1');
    });

    test('ChampionshipRecord serialization works correctly', () {
      final record = ChampionshipRecord(
        year: 2024,
        championTeamId: 'team-1',
        finalsMvpPlayerId: 'player-1',
        runnerUpTeamId: 'team-2',
      );

      // Convert to JSON
      final json = record.toJson();

      // Verify JSON structure
      expect(json['year'], 2024);
      expect(json['championTeamId'], 'team-1');
      expect(json['finalsMvpPlayerId'], 'player-1');
      expect(json['runnerUpTeamId'], 'team-2');

      // Convert back from JSON
      final restored = ChampionshipRecord.fromJson(json);

      // Verify restored record
      expect(restored.year, record.year);
      expect(restored.championTeamId, record.championTeamId);
      expect(restored.finalsMvpPlayerId, record.finalsMvpPlayerId);
      expect(restored.runnerUpTeamId, record.runnerUpTeamId);
    });

    test('Season with championship record serializes correctly', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      final record = ChampionshipRecord(
        year: 2024,
        championTeamId: 'team-1',
        finalsMvpPlayerId: 'player-1',
        runnerUpTeamId: 'team-2',
      );

      final season = Season(
        id: 'season-2024',
        year: 2024,
        games: games,
        userTeamId: 'team-1',
        championshipRecord: record,
      );

      // Convert to JSON
      final json = season.toJson();

      // Verify championship record is in JSON
      expect(json['championshipRecord'], isNotNull);
      expect(json['championshipRecord']['year'], 2024);

      // Convert back from JSON
      final restored = Season.fromJson(json);

      // Verify championship record is restored
      expect(restored.championshipRecord, isNotNull);
      expect(restored.championshipRecord!.year, 2024);
      expect(restored.championshipRecord!.championTeamId, 'team-1');
    });

    test('Season without championship record handles backward compatibility', () {
      final games = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game-$i',
          homeTeamId: 'team-1',
          awayTeamId: 'team-2',
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now(),
        ),
      );

      // Create JSON without championship record (old save format)
      final json = {
        'id': 'season-2024',
        'year': 2024,
        'games': games.map((g) => g.toJson()).toList(),
        'userTeamId': 'team-1',
        'isPostSeason': false,
      };

      // Should load without error
      final season = Season.fromJson(json);

      // Championship record should be null
      expect(season.championshipRecord, isNull);
    });
  });
}
