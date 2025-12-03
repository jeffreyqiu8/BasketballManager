import 'package:flutter_test/flutter_test.dart';
import '../lib/models/season.dart';
import '../lib/models/game.dart';
import '../lib/services/league_service.dart';
import '../lib/services/game_service.dart';
import '../lib/utils/playoff_seeding.dart';

/// Test to diagnose playoff seeding mismatch issue
/// 
/// This test simulates a full season and checks if the playoff seedings
/// match the standings positions. It helps identify timing issues or
/// data inconsistencies between standings display and playoff generation.
void main() {
  group('Playoff Seeding Mismatch Diagnosis', () {
    late LeagueService leagueService;
    late GameService gameService;

    setUp(() async {
      leagueService = LeagueService();
      gameService = GameService();
      await leagueService.initializeLeague();
    });

    test('Verify seedings match standings after full season simulation', () async {
      // Create a season with league schedule
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create dummy games first (will be replaced by league schedule)
      final dummyGames = List<Game>.generate(82, (i) => Game(
        id: 'dummy-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: null,
        awayScore: null,
        isPlayed: false,
        scheduledDate: DateTime.now().add(Duration(days: i)),
      ));
      
      var season = Season(
        id: 'test-season',
        year: 2024,
        games: dummyGames,
        userTeamId: userTeam.id,
      );

      // Initialize with league schedule
      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      print('\n=== INITIAL STATE ===');
      print('Total league games: ${season.leagueSchedule!.allGames.length}');
      print('User team games: ${season.games.length}');
      print('User team: ${userTeam.city} ${userTeam.name}');

      // Simulate entire regular season
      print('\n=== SIMULATING SEASON ===');
      season = leagueService.simulateEntireRegularSeason(season, gameService);
      
      print('Season complete: ${season.isComplete}');
      print('Games played: ${season.gamesPlayed}');
      
      // Verify all league games are complete
      final unplayedLeagueGames = season.leagueSchedule!.allGames
          .where((g) => !g.isPlayed)
          .length;
      print('Unplayed league games: $unplayedLeagueGames');
      
      expect(unplayedLeagueGames, 0, 
          reason: 'All league games should be complete before playoffs');

      // Calculate standings manually (same logic as standings page)
      print('\n=== CALCULATING STANDINGS ===');
      final standingsRecords = <String, StandingsRecord>{};
      
      for (var team in teams) {
        int wins = 0;
        int losses = 0;

        for (var game in season.leagueSchedule!.allGames) {
          if (!game.isPlayed) continue;

          if (game.homeTeamId == team.id) {
            if (game.homeTeamWon) {
              wins++;
            } else if (game.awayTeamWon) {
              losses++;
            }
            // If neither won, it's a tie (shouldn't happen in basketball)
          } else if (game.awayTeamId == team.id) {
            if (game.awayTeamWon) {
              wins++;
            } else if (game.homeTeamWon) {
              losses++;
            }
            // If neither won, it's a tie (shouldn't happen in basketball)
          }
        }

        standingsRecords[team.id] = StandingsRecord(
          teamId: team.id,
          teamName: '${team.city} ${team.name}',
          wins: wins,
          losses: losses,
          conference: PlayoffSeeding.getConference(team),
        );
      }

      // Sort by conference, wins, win percentage, and team name to get standings positions
      // This matches the exact logic used in playoff seeding and standings page
      final eastStandings = standingsRecords.values
          .where((r) => r.conference == 'east')
          .toList()
        ..sort((a, b) {
          // First compare by wins
          if (a.wins != b.wins) {
            return b.wins.compareTo(a.wins);
          }
          // Then by win percentage
          final aWinPct = (a.wins + a.losses) > 0 ? a.wins / (a.wins + a.losses) : 0.0;
          final bWinPct = (b.wins + b.losses) > 0 ? b.wins / (b.wins + b.losses) : 0.0;
          if (aWinPct != bWinPct) {
            return bWinPct.compareTo(aWinPct);
          }
          // Finally by team name for stable sorting
          return a.teamName.compareTo(b.teamName);
        });
      
      final westStandings = standingsRecords.values
          .where((r) => r.conference == 'west')
          .toList()
        ..sort((a, b) {
          // First compare by wins
          if (a.wins != b.wins) {
            return b.wins.compareTo(a.wins);
          }
          // Then by win percentage
          final aWinPct = (a.wins + a.losses) > 0 ? a.wins / (a.wins + a.losses) : 0.0;
          final bWinPct = (b.wins + b.losses) > 0 ? b.wins / (b.wins + b.losses) : 0.0;
          if (aWinPct != bWinPct) {
            return bWinPct.compareTo(aWinPct);
          }
          // Finally by team name for stable sorting
          return a.teamName.compareTo(b.teamName);
        });

      print('\nEastern Conference Standings:');
      for (int i = 0; i < eastStandings.length; i++) {
        final record = eastStandings[i];
        print('  ${i + 1}. ${record.teamName} (${record.wins}-${record.losses})');
      }

      print('\nWestern Conference Standings:');
      for (int i = 0; i < westStandings.length; i++) {
        final record = westStandings[i];
        print('  ${i + 1}. ${record.teamName} (${record.wins}-${record.losses})');
      }

      // Calculate playoff seedings (same logic as playoff generation)
      print('\n=== CALCULATING PLAYOFF SEEDINGS ===');
      final seedings = PlayoffSeeding.calculateSeedings(
        teams,
        season.leagueSchedule!.allGames,
      );

      // Organize seedings by conference
      final eastSeedings = <int, String>{};
      final westSeedings = <int, String>{};
      
      for (var team in teams) {
        final seed = seedings[team.id];
        final conference = PlayoffSeeding.getConference(team);
        
        if (seed != null) {
          if (conference == 'east') {
            eastSeedings[seed] = team.id;
          } else {
            westSeedings[seed] = team.id;
          }
        }
      }

      print('\nEastern Conference Seedings:');
      for (var seed in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
        if (eastSeedings.containsKey(seed)) {
          final teamId = eastSeedings[seed]!;
          final record = standingsRecords[teamId]!;
          print('  $seed. ${record.teamName} (${record.wins}-${record.losses})');
        }
      }

      print('\nWestern Conference Seedings:');
      for (var seed in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]) {
        if (westSeedings.containsKey(seed)) {
          final teamId = westSeedings[seed]!;
          final record = standingsRecords[teamId]!;
          print('  $seed. ${record.teamName} (${record.wins}-${record.losses})');
        }
      }

      // Compare standings positions with playoff seedings
      print('\n=== COMPARING STANDINGS VS SEEDINGS ===');
      bool foundMismatch = false;

      // Check Eastern Conference
      for (int i = 0; i < eastStandings.length && i < 10; i++) {
        final standingsPosition = i + 1;
        final teamId = eastStandings[i].teamId;
        final playoffSeed = seedings[teamId];
        final record = eastStandings[i];

        if (playoffSeed != standingsPosition) {
          print('MISMATCH (East): ${record.teamName}');
          print('  Standings Position: #$standingsPosition');
          print('  Playoff Seed: #$playoffSeed');
          print('  Record: ${record.wins}-${record.losses}');
          foundMismatch = true;
        }
      }

      // Check Western Conference
      for (int i = 0; i < westStandings.length && i < 10; i++) {
        final standingsPosition = i + 1;
        final teamId = westStandings[i].teamId;
        final playoffSeed = seedings[teamId];
        final record = westStandings[i];

        if (playoffSeed != standingsPosition) {
          print('MISMATCH (West): ${record.teamName}');
          print('  Standings Position: #$standingsPosition');
          print('  Playoff Seed: #$playoffSeed');
          print('  Record: ${record.wins}-${record.losses}');
          foundMismatch = true;
        }
      }

      if (!foundMismatch) {
        print('✓ No mismatches found - standings match seedings perfectly');
      }

      // Check user team specifically
      final userRecord = standingsRecords[userTeam.id]!;
      final userSeed = seedings[userTeam.id];
      final userConference = PlayoffSeeding.getConference(userTeam);
      final userStandings = userConference == 'east' ? eastStandings : westStandings;
      final userStandingsPosition = userStandings.indexWhere((r) => r.teamId == userTeam.id) + 1;

      print('\n=== USER TEAM ANALYSIS ===');
      print('Team: ${userTeam.city} ${userTeam.name}');
      print('Conference: $userConference');
      print('Record: ${userRecord.wins}-${userRecord.losses}');
      print('Standings Position: #$userStandingsPosition');
      print('Playoff Seed: #$userSeed');
      
      if (userSeed != userStandingsPosition) {
        print('⚠️  USER TEAM HAS MISMATCH!');
      } else {
        print('✓ User team standings match playoff seed');
      }

      // Now trigger playoff generation and verify
      print('\n=== TRIGGERING PLAYOFF GENERATION ===');
      final postSeasonResult = leagueService.checkAndStartPostSeason(season);
      
      expect(postSeasonResult, isNotNull, 
          reason: 'Post-season should be triggered after complete season');
      
      if (postSeasonResult != null) {
        season = postSeasonResult;
        
        expect(season.isPostSeason, true);
        
        if (season.playoffBracket != null) {
          print('Playoff bracket created');
          print('Current round: ${season.playoffBracket!.currentRound}');
          
          // Verify user team's playoff seed matches their standings position
          final bracketUserSeed = season.playoffBracket!.teamSeedings[userTeam.id];
          print('User team seed in bracket: $bracketUserSeed');
          
          expect(bracketUserSeed, userStandingsPosition,
              reason: 'User team playoff seed should match standings position');
        } else {
          print('User team missed playoffs (seed > 10)');
        }
      }

      print('\n=== TEST COMPLETE ===\n');
    });

    test('Check for race conditions in game completion', () async {
      // This test checks if there's a timing issue where playoffs are generated
      // before all league games are marked as complete
      
      final teams = leagueService.getAllTeams();
      final userTeam = teams.first;
      
      // Create dummy games first (will be replaced by league schedule)
      final dummyGames = List<Game>.generate(82, (i) => Game(
        id: 'dummy-$i',
        homeTeamId: userTeam.id,
        awayTeamId: teams[1].id,
        homeScore: null,
        awayScore: null,
        isPlayed: false,
        scheduledDate: DateTime.now().add(Duration(days: i)),
      ));
      
      var season = Season(
        id: 'test-season-2',
        year: 2024,
        games: dummyGames,
        userTeamId: userTeam.id,
      );

      season = leagueService.initializeSeasonWithLeagueSchedule(season);
      
      print('\n=== CHECKING FOR RACE CONDITIONS ===');
      
      // Simulate season
      season = leagueService.simulateEntireRegularSeason(season, gameService);
      
      // Check immediately if all games are complete
      final allGames = season.leagueSchedule!.allGames;
      final playedCount = allGames.where((g) => g.isPlayed).length;
      final totalCount = allGames.length;
      
      print('Games played: $playedCount / $totalCount');
      
      if (playedCount < totalCount) {
        print('⚠️  WARNING: Not all games are complete!');
        print('This could cause seeding calculation issues.');
        
        // Show some unplayed games
        final unplayed = allGames.where((g) => !g.isPlayed).take(10).toList();
        print('\nSample unplayed games:');
        for (var game in unplayed) {
          print('  ${game.homeTeamId} vs ${game.awayTeamId}');
        }
      } else {
        print('✓ All games are complete');
      }
      
      // Try to start playoffs
      final postSeasonResult = leagueService.checkAndStartPostSeason(season);
      
      if (postSeasonResult != null && postSeasonResult.playoffBracket != null) {
        // Verify seedings were calculated with complete data
        final seedings = postSeasonResult.playoffBracket!.teamSeedings;
        print('\nPlayoff seedings calculated: ${seedings.length} teams');
        
        // All 30 teams should have seedings
        expect(seedings.length, 30,
            reason: 'All 30 teams should have playoff seedings');
      }
      
      print('=== RACE CONDITION CHECK COMPLETE ===\n');
    });
  });
}

/// Helper class to track standings records
class StandingsRecord {
  final String teamId;
  final String teamName;
  final int wins;
  final int losses;
  final String conference;

  StandingsRecord({
    required this.teamId,
    required this.teamName,
    required this.wins,
    required this.losses,
    required this.conference,
  });
}
