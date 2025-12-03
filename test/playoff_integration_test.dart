import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/services/playoff_service.dart';
import 'package:BasketballManager/services/save_service.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/models/playoff_bracket.dart';
import 'package:BasketballManager/models/playoff_series.dart';
import 'package:BasketballManager/models/player_game_stats.dart';
import 'package:BasketballManager/utils/playoff_bracket_generator.dart';

/// Integration tests for complete playoff flow
/// Validates Requirements: 21.1, 27.1, 27.2, 27.3
void main() {
  group('Playoff Integration Tests', () {
    late LeagueService leagueService;
    late GameService gameService;
    late SaveService saveService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
      gameService = GameService();
      saveService = SaveService();
    });

    /// Test for complete season through playoffs to championship
    /// Validates Requirements: 21.1, 27.1
    test('Complete season through playoffs to championship', () async {
      // Initialize league and get teams
      final teams = leagueService.getAllTeams();
      expect(teams.length, 30);
      
      final userTeam = teams[0];
      
      // Create a complete regular season (82 games)
      // User team wins 60 games to ensure high seed
      final regularSeasonGames = <Game>[];
      for (int i = 0; i < 82; i++) {
        final opponentTeam = teams[(i + 1) % teams.length];
        final userWins = i < 60; // Win 60 out of 82 games
        
        regularSeasonGames.add(Game(
          id: 'regular_game_$i',
          homeTeamId: userTeam.id,
          awayTeamId: opponentTeam.id,
          homeScore: userWins ? 105 : 95,
          awayScore: userWins ? 95 : 105,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ));
      }
      
      // Create season with completed regular season
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: regularSeasonGames,
        userTeamId: userTeam.id,
      );
      
      // Verify regular season is complete
      expect(leagueService.isRegularSeasonComplete(season), true);
      
      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      expect(season.isPostSeason, true);
      expect(season.playoffBracket, isNotNull);
      expect(season.playoffBracket!.currentRound, 'play-in');
      
      var bracket = season.playoffBracket!;
      
      // Complete play-in tournament
      final completedPlayInGames = <PlayoffSeries>[];
      for (var game in bracket.playInGames) {
        var completedGame = game;
        // Simulate 4 wins for home team
        for (int i = 0; i < 4; i++) {
          completedGame = completedGame.copyWithGameResult(
            'playin_${game.id}_game_$i',
            game.homeTeamId,
          );
        }
        completedPlayInGames.add(completedGame);
      }
      
      // Generate second play-in games for each conference
      final eastGames = completedPlayInGames.where((g) => g.conference == 'east').toList();
      final westGames = completedPlayInGames.where((g) => g.conference == 'west').toList();
      
      // East second play-in game
      final eastSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        eastGames[0],
        eastGames[1],
        'east',
      );
      var completedEastSecondGame = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecondGame = completedEastSecondGame.copyWithGameResult(
          'east_second_playin_$i',
          eastSecondGame.homeTeamId,
        );
      }
      completedPlayInGames.add(completedEastSecondGame);
      
      // West second play-in game
      final westSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        westGames[0],
        westGames[1],
        'west',
      );
      var completedWestSecondGame = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecondGame = completedWestSecondGame.copyWithGameResult(
          'west_second_playin_$i',
          westSecondGame.homeTeamId,
        );
      }
      completedPlayInGames.add(completedWestSecondGame);
      
      // Update bracket with completed play-in games
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedPlayInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to first round
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'first-round');
      expect(bracket.firstRound.length, 8); // 4 per conference
      
      // Complete first round
      final completedFirstRound = bracket.firstRound.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult(
            'first_round_${series.id}_game_$i',
            series.homeTeamId,
          );
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: completedFirstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to conference semifinals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'conf-semis');
      expect(bracket.conferenceSemis.length, 4); // 2 per conference
      
      // Complete conference semifinals
      final completedSemis = bracket.conferenceSemis.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult(
            'semis_${series.id}_game_$i',
            series.homeTeamId,
          );
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: completedSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to conference finals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'conf-finals');
      expect(bracket.conferenceFinals.length, 2); // 1 per conference
      
      // Complete conference finals
      final completedConfFinals = bracket.conferenceFinals.map((series) {
        var completed = series;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult(
            'conf_finals_${series.id}_game_$i',
            series.homeTeamId,
          );
        }
        return completed;
      }).toList();
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: completedConfFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to NBA Finals
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'finals');
      expect(bracket.nbaFinals, isNotNull);
      
      // Complete NBA Finals
      var nbaFinals = bracket.nbaFinals!;
      for (int i = 0; i < 4; i++) {
        nbaFinals = nbaFinals.copyWithGameResult(
          'finals_game_$i',
          nbaFinals.homeTeamId,
        );
      }
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: bracket.playInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to complete
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'complete');
      expect(bracket.nbaFinals!.isComplete, true);
      expect(bracket.nbaFinals!.winnerId, isNotNull);
      
      // Verify championship was completed
      final champion = bracket.nbaFinals!.winnerId!;
      expect(champion, isNotEmpty);
    });

    /// Test for play-in tournament through to first round
    /// Validates Requirements: 21.1, 27.1
    test('Play-in tournament through to first round', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];
      
      // Create completed regular season
      final regularSeasonGames = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game_$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: regularSeasonGames,
        userTeamId: userTeam.id,
      );
      
      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      var bracket = season.playoffBracket!;
      
      // Verify play-in games were generated
      expect(bracket.playInGames.length, 4); // 2 per conference
      expect(bracket.currentRound, 'play-in');
      
      // Verify play-in matchups are correct (7v8 and 9v10 for each conference)
      final eastPlayInGames = bracket.playInGames.where((g) => g.conference == 'east').toList();
      final westPlayInGames = bracket.playInGames.where((g) => g.conference == 'west').toList();
      
      expect(eastPlayInGames.length, 2);
      expect(westPlayInGames.length, 2);
      
      // Complete initial play-in games
      final completedInitialPlayIn = <PlayoffSeries>[];
      for (var game in bracket.playInGames) {
        var completed = game;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('game_${game.id}_$i', game.homeTeamId);
        }
        completedInitialPlayIn.add(completed);
      }
      
      // Generate and complete second play-in games
      final eastGames = completedInitialPlayIn.where((g) => g.conference == 'east').toList();
      final westGames = completedInitialPlayIn.where((g) => g.conference == 'west').toList();
      
      final eastSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        eastGames[0],
        eastGames[1],
        'east',
      );
      var completedEastSecond = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecond = completedEastSecond.copyWithGameResult('east_2nd_$i', eastSecondGame.homeTeamId);
      }
      
      final westSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        westGames[0],
        westGames[1],
        'west',
      );
      var completedWestSecond = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecond = completedWestSecond.copyWithGameResult('west_2nd_$i', westSecondGame.homeTeamId);
      }
      
      completedInitialPlayIn.add(completedEastSecond);
      completedInitialPlayIn.add(completedWestSecond);
      
      // Update bracket
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedInitialPlayIn,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Verify all play-in games are complete
      expect(bracket.isRoundComplete(), true);
      
      // Advance to first round
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'first-round');
      expect(bracket.firstRound.length, 8);
      
      // Verify first round matchups are correct (1v8, 2v7, 3v6, 4v5 per conference)
      final eastFirstRound = bracket.firstRound.where((s) => s.conference == 'east').toList();
      final westFirstRound = bracket.firstRound.where((s) => s.conference == 'west').toList();
      
      expect(eastFirstRound.length, 4);
      expect(westFirstRound.length, 4);
      
      // Verify seeds 7 and 8 came from play-in results
      final eastSeeds = eastFirstRound.map((s) {
        final homeSeed = bracket.teamSeedings[s.homeTeamId];
        final awaySeed = bracket.teamSeedings[s.awayTeamId];
        return [homeSeed, awaySeed]..sort();
      }).toList();
      
      // Should have matchups: 1v8, 2v7, 3v6, 4v5
      expect(eastSeeds.any((seeds) => seeds[0] == 1 && seeds[1] == 8), true);
      expect(eastSeeds.any((seeds) => seeds[0] == 2 && seeds[1] == 7), true);
      expect(eastSeeds.any((seeds) => seeds[0] == 3 && seeds[1] == 6), true);
      expect(eastSeeds.any((seeds) => seeds[0] == 4 && seeds[1] == 5), true);
    });

    /// Test for playoff statistics persistence across save/load
    /// Validates Requirements: 27.1
    test('Playoff statistics persistence across save/load', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];
      final player = userTeam.players[0];
      
      // Create completed regular season
      final regularSeasonGames = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game_$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: regularSeasonGames,
        userTeamId: userTeam.id,
      );
      
      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      
      // Simulate playoff games and accumulate stats
      final playoffGameStats1 = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 28,
          rebounds: 10,
          assists: 7,
          fieldGoalsMade: 11,
          fieldGoalsAttempted: 22,
          threePointersMade: 4,
          threePointersAttempted: 10,
          turnovers: 3,
          steals: 2,
          blocks: 1,
          fouls: 2,
          freeThrowsMade: 2,
          freeThrowsAttempted: 3,
        ),
      };
      
      season = season.updatePlayoffStats(playoffGameStats1);
      
      // Add more playoff games
      final playoffGameStats2 = {
        player.id: PlayerGameStats(
          playerId: player.id,
          points: 32,
          rebounds: 8,
          assists: 9,
          fieldGoalsMade: 13,
          fieldGoalsAttempted: 25,
          threePointersMade: 5,
          threePointersAttempted: 12,
          turnovers: 2,
          steals: 3,
          blocks: 2,
          fouls: 3,
          freeThrowsMade: 1,
          freeThrowsAttempted: 2,
        ),
      };
      
      season = season.updatePlayoffStats(playoffGameStats2);
      
      // Verify playoff stats before save
      final statsBeforeSave = season.getPlayerPlayoffStats(player.id);
      expect(statsBeforeSave, isNotNull);
      expect(statsBeforeSave!.gamesPlayed, 2);
      expect(statsBeforeSave.totalPoints, 60); // 28 + 32
      expect(statsBeforeSave.totalRebounds, 18); // 10 + 8
      expect(statsBeforeSave.totalAssists, 16); // 7 + 9
      expect(statsBeforeSave.pointsPerGame, 30.0); // 60 / 2
      
      // Serialize season to JSON (simulating save)
      final seasonJson = season.toJson();
      
      // Deserialize season from JSON (simulating load)
      final loadedSeason = Season.fromJson(seasonJson);
      
      // Verify playoff data persisted
      expect(loadedSeason.isPostSeason, true);
      expect(loadedSeason.playoffBracket, isNotNull);
      expect(loadedSeason.playoffStats, isNotNull);
      
      // Verify playoff stats after load
      final statsAfterLoad = loadedSeason.getPlayerPlayoffStats(player.id);
      expect(statsAfterLoad, isNotNull);
      expect(statsAfterLoad!.gamesPlayed, 2);
      expect(statsAfterLoad.totalPoints, 60);
      expect(statsAfterLoad.totalRebounds, 18);
      expect(statsAfterLoad.totalAssists, 16);
      expect(statsAfterLoad.pointsPerGame, 30.0);
      expect(statsAfterLoad.totalSteals, 5); // 2 + 3
      expect(statsAfterLoad.totalBlocks, 3); // 1 + 2
      expect(statsAfterLoad.totalTurnovers, 5); // 3 + 2
      
      // Verify bracket persisted
      expect(loadedSeason.playoffBracket!.seasonId, season.playoffBracket!.seasonId);
      expect(loadedSeason.playoffBracket!.currentRound, season.playoffBracket!.currentRound);
      expect(loadedSeason.playoffBracket!.teamSeedings.length, season.playoffBracket!.teamSeedings.length);
    });

    /// Test for non-user playoff game simulation
    /// Validates Requirements: 27.2, 27.3
    test('Non-user playoff game simulation', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams[0];
      
      // Create completed regular season
      final regularSeasonGames = List<Game>.generate(
        82,
        (i) => Game(
          id: 'game_$i',
          homeTeamId: userTeam.id,
          awayTeamId: teams[(i + 1) % teams.length].id,
          homeScore: 100,
          awayScore: 95,
          isPlayed: true,
          scheduledDate: DateTime.now().add(Duration(days: i)),
        ),
      );
      
      var season = Season(
        id: 'season-2024',
        year: 2024,
        games: regularSeasonGames,
        userTeamId: userTeam.id,
      );
      
      // Start post-season
      season = leagueService.checkAndStartPostSeason(season)!;
      var bracket = season.playoffBracket!;
      
      // Complete play-in games to advance to first round
      final completedPlayInGames = <PlayoffSeries>[];
      for (var game in bracket.playInGames) {
        var completed = game;
        for (int i = 0; i < 4; i++) {
          completed = completed.copyWithGameResult('game_${game.id}_$i', game.homeTeamId);
        }
        completedPlayInGames.add(completed);
      }
      
      // Generate second play-in games
      final eastGames = completedPlayInGames.where((g) => g.conference == 'east').toList();
      final westGames = completedPlayInGames.where((g) => g.conference == 'west').toList();
      
      final eastSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        eastGames[0],
        eastGames[1],
        'east',
      );
      var completedEastSecond = eastSecondGame;
      for (int i = 0; i < 4; i++) {
        completedEastSecond = completedEastSecond.copyWithGameResult('east_2nd_$i', eastSecondGame.homeTeamId);
      }
      
      final westSecondGame = PlayoffBracketGenerator.createSecondPlayInGame(
        westGames[0],
        westGames[1],
        'west',
      );
      var completedWestSecond = westSecondGame;
      for (int i = 0; i < 4; i++) {
        completedWestSecond = completedWestSecond.copyWithGameResult('west_2nd_$i', westSecondGame.homeTeamId);
      }
      
      completedPlayInGames.add(completedEastSecond);
      completedPlayInGames.add(completedWestSecond);
      
      bracket = PlayoffBracket(
        seasonId: bracket.seasonId,
        teamSeedings: bracket.teamSeedings,
        teamConferences: bracket.teamConferences,
        playInGames: completedPlayInGames,
        firstRound: bracket.firstRound,
        conferenceSemis: bracket.conferenceSemis,
        conferenceFinals: bracket.conferenceFinals,
        nbaFinals: bracket.nbaFinals,
        currentRound: bracket.currentRound,
      );
      
      // Advance to first round
      bracket = PlayoffService.advancePlayoffRound(bracket);
      expect(bracket.currentRound, 'first-round');
      
      // Find user's series
      final userSeries = bracket.getUserTeamSeries(userTeam.id);
      expect(userSeries, isNotNull);
      expect(userSeries!.isComplete, false);
      
      // Count non-user series
      final nonUserSeries = bracket.firstRound.where((s) => 
        s.homeTeamId != userTeam.id && s.awayTeamId != userTeam.id
      ).toList();
      
      expect(nonUserSeries.length, greaterThan(0));
      
      // Simulate non-user playoff games
      Team getTeam(String teamId) {
        return teams.firstWhere((t) => t.id == teamId);
      }
      
      Game simulateGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
        return gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
      }
      
      final result = PlayoffService.simulateNonUserPlayoffGames(
        bracket: bracket,
        userTeamId: userTeam.id,
        getTeam: getTeam,
        simulateGame: simulateGame,
      );
      
      // Verify non-user series were simulated
      expect(result.gameResults.isNotEmpty, true);
      
      // Verify user's series was NOT simulated
      final updatedUserSeries = result.bracket.getUserTeamSeries(userTeam.id);
      expect(updatedUserSeries, isNotNull);
      expect(updatedUserSeries!.homeWins, userSeries.homeWins);
      expect(updatedUserSeries.awayWins, userSeries.awayWins);
      expect(updatedUserSeries.isComplete, false);
      
      // Verify at least some non-user series were completed
      final completedNonUserSeries = result.bracket.firstRound.where((s) =>
        s.isComplete &&
        s.homeTeamId != userTeam.id &&
        s.awayTeamId != userTeam.id
      ).toList();
      
      expect(completedNonUserSeries.length, greaterThan(0));
      
      // Verify game results were recorded
      for (var seriesId in result.gameResults.keys) {
        final games = result.gameResults[seriesId]!;
        expect(games.isNotEmpty, true);
        
        // Verify each game has valid scores
        for (var game in games) {
          expect(game.homeScore, greaterThan(0));
          expect(game.awayScore, greaterThan(0));
          expect(game.winnerTeamId, isNotEmpty);
        }
      }
      
      // Verify bracket advances when all series complete
      // Complete user's series manually
      var updatedBracket = result.bracket;
      final userSeriesIndex = updatedBracket.firstRound.indexWhere((s) => s.id == updatedUserSeries.id);
      var completedUserSeries = updatedUserSeries;
      for (int i = 0; i < 4; i++) {
        completedUserSeries = completedUserSeries.copyWithGameResult('user_game_$i', userTeam.id);
      }
      
      final updatedFirstRound = List<PlayoffSeries>.from(updatedBracket.firstRound);
      updatedFirstRound[userSeriesIndex] = completedUserSeries;
      
      updatedBracket = PlayoffBracket(
        seasonId: updatedBracket.seasonId,
        teamSeedings: updatedBracket.teamSeedings,
        teamConferences: updatedBracket.teamConferences,
        playInGames: updatedBracket.playInGames,
        firstRound: updatedFirstRound,
        conferenceSemis: updatedBracket.conferenceSemis,
        conferenceFinals: updatedBracket.conferenceFinals,
        nbaFinals: updatedBracket.nbaFinals,
        currentRound: updatedBracket.currentRound,
      );
      
      // Now all series should be complete
      expect(updatedBracket.isRoundComplete(), true);
      
      // Advance to next round
      updatedBracket = PlayoffService.advancePlayoffRound(updatedBracket);
      expect(updatedBracket.currentRound, 'conf-semis');
    });
  });
}
