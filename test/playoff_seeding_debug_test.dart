import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/services/league_service.dart';
import 'package:BasketballManager/services/game_service.dart';
import 'package:BasketballManager/models/season.dart';
import 'package:BasketballManager/models/game.dart';
import 'package:BasketballManager/utils/playoff_seeding.dart';

/// Debug test to verify playoff seeding is calculated correctly
void main() {
  group('Playoff Seeding Debug Tests', () {
    late LeagueService leagueService;

    setUp(() async {
      leagueService = LeagueService();
      await leagueService.initializeLeague();
    });

    test('Verify seeding calculation with league schedule', () async {
      final teams = leagueService.getAllTeams();
      final userTeam = teams.firstWhere((t) => t.city == 'Atlanta');
      
      // Create a season with league schedule
      final games = List<Game>.generate(
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
        games: games,
        userTeamId: userTeam.id,
      );
      
      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      // Simulate remaining league games
      final gameService = GameService();
      season = leagueService.simulateRemainingRegularSeasonGames(
        season,
        gameService,
        updateStats: false,
      );
      
      // Calculate seedings
      final seedings = PlayoffSeeding.calculateSeedings(
        teams,
        season.leagueSchedule!.allGames,
      );
      
      // Print seedings for Eastern Conference
      print('\n=== Eastern Conference Seedings ===');
      final eastTeams = teams.where((t) => PlayoffSeeding.isEasternConference(t)).toList();
      eastTeams.sort((a, b) {
        final aSeed = seedings[a.id] ?? 99;
        final bSeed = seedings[b.id] ?? 99;
        return aSeed.compareTo(bSeed);
      });
      
      for (var team in eastTeams) {
        final seed = seedings[team.id];
        final wins = _countWins(team.id, season.leagueSchedule!.allGames);
        final losses = _countLosses(team.id, season.leagueSchedule!.allGames);
        print('Seed $seed: ${team.city} ${team.name} ($wins-$losses)');
      }
      
      // Verify Atlanta Hawks seeding
      final atlantaSeed = seedings[userTeam.id];
      print('\nAtlanta Hawks seed: $atlantaSeed');
      
      // Check if Atlanta is in play-in range (7-10)
      if (atlantaSeed != null && atlantaSeed >= 7 && atlantaSeed <= 10) {
        print('Atlanta Hawks IS in play-in tournament (seed $atlantaSeed)');
      } else if (atlantaSeed != null && atlantaSeed <= 6) {
        print('Atlanta Hawks should NOT be in play-in (seed $atlantaSeed - top 6)');
      } else {
        print('Atlanta Hawks missed playoffs (seed $atlantaSeed)');
      }
      
      // Start post-season and check bracket
      final postSeasonSeason = leagueService.checkAndStartPostSeason(season);
      if (postSeasonSeason != null && postSeasonSeason.playoffBracket != null) {
        final bracket = postSeasonSeason.playoffBracket!;
        
        print('\n=== Play-In Games ===');
        for (var game in bracket.playInGames) {
          final homeTeam = teams.firstWhere((t) => t.id == game.homeTeamId);
          final awayTeam = teams.firstWhere((t) => t.id == game.awayTeamId);
          final homeSeed = seedings[game.homeTeamId];
          final awaySeed = seedings[game.awayTeamId];
          print('${game.conference.toUpperCase()}: Seed $homeSeed ${homeTeam.city} vs Seed $awaySeed ${awayTeam.city}');
        }
        
        // Check if Atlanta is in any play-in game
        final atlantaInPlayIn = bracket.playInGames.any((g) => 
          g.homeTeamId == userTeam.id || g.awayTeamId == userTeam.id
        );
        print('\nAtlanta Hawks in play-in games: $atlantaInPlayIn');
      }
    });
  });
}

int _countWins(String teamId, List<Game> games) {
  return games.where((g) => 
    g.isPlayed && 
    ((g.homeTeamId == teamId && g.homeTeamWon) || 
     (g.awayTeamId == teamId && g.awayTeamWon))
  ).length;
}

int _countLosses(String teamId, List<Game> games) {
  return games.where((g) => 
    g.isPlayed && 
    ((g.homeTeamId == teamId && !g.homeTeamWon) || 
     (g.awayTeamId == teamId && !g.awayTeamWon))
  ).length;
}
