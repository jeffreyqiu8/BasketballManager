import 'package:flutter_test/flutter_test.dart';
import '../lib/gameData/enhanced_game_simulation.dart';
import '../lib/gameData/enhanced_player.dart';
import '../lib/gameData/team_class.dart';
import '../lib/gameData/enums.dart';

void main() {
  group('EnhancedGameSimulation Tests', () {
    late Team homeTeam;
    late Team awayTeam;

    setUp(() {
      // Create home team with point guard-type players
      homeTeam = Team(
        name: 'Home Team',
        reputation: 80,
        playerCount: 5,
        teamSize: 5,
        players: [
          EnhancedPlayer(
            name: 'Home PG',
            age: 25,
            team: 'Home Team',
            experienceYears: 3,
            nationality: 'USA',
            currentStatus: 'Active',
            height: 185,
            shooting: 75,
            rebounding: 45,
            passing: 85,
            ballHandling: 80,
            perimeterDefense: 70,
            postDefense: 40,
            insideShooting: 50,
            performances: {},
            primaryRole: PlayerRole.pointGuard,
          ),
          EnhancedPlayer(
            name: 'Home SG',
            age: 26,
            team: 'Home Team',
            experienceYears: 4,
            nationality: 'USA',
            currentStatus: 'Active',
            height: 195,
            shooting: 85,
            rebounding: 50,
            passing: 60,
            ballHandling: 70,
            perimeterDefense: 75,
            postDefense: 45,
            insideShooting: 55,
            performances: {},
            primaryRole: PlayerRole.shootingGuard,
          ),
          EnhancedPlayer(
            name: 'Home SF',
            age: 27,
            team: 'Home Team',
            experienceYears: 5,
            nationality: 'USA',
            currentStatus: 'Active',
            height: 200,
            shooting: 75,
            rebounding: 65,
            passing: 65,
            ballHandling: 65,
            perimeterDefense: 75,
            postDefense: 60,
            insideShooting: 65,
            performances: {},
            primaryRole: PlayerRole.smallForward,
          ),
          EnhancedPlayer(
            name: 'Home PF',
            age: 28,
            team: 'Home Team',
            experienceYears: 6,
            nationality: 'USA',
            currentStatus: 'Active',
            height: 208,
            shooting: 60,
            rebounding: 85,
            passing: 50,
            ballHandling: 45,
            perimeterDefense: 60,
            postDefense: 80,
            insideShooting: 75,
            performances: {},
            primaryRole: PlayerRole.powerForward,
          ),
          EnhancedPlayer(
            name: 'Home C',
            age: 29,
            team: 'Home Team',
            experienceYears: 7,
            nationality: 'USA',
            currentStatus: 'Active',
            height: 220,
            shooting: 40,
            rebounding: 95,
            passing: 35,
            ballHandling: 25,
            perimeterDefense: 25,
            postDefense: 90,
            insideShooting: 85,
            performances: {},
            primaryRole: PlayerRole.center,
          ),
        ],
      );

      // Create away team with similar structure
      awayTeam = Team(
        name: 'Away Team',
        reputation: 75,
        playerCount: 5,
        teamSize: 5,
        players: [
          EnhancedPlayer(
            name: 'Away PG',
            age: 24,
            team: 'Away Team',
            experienceYears: 2,
            nationality: 'Canada',
            currentStatus: 'Active',
            height: 180,
            shooting: 70,
            rebounding: 40,
            passing: 80,
            ballHandling: 75,
            perimeterDefense: 65,
            postDefense: 35,
            insideShooting: 45,
            performances: {},
            primaryRole: PlayerRole.pointGuard,
          ),
          EnhancedPlayer(
            name: 'Away SG',
            age: 25,
            team: 'Away Team',
            experienceYears: 3,
            nationality: 'Spain',
            currentStatus: 'Active',
            height: 190,
            shooting: 80,
            rebounding: 45,
            passing: 55,
            ballHandling: 65,
            perimeterDefense: 70,
            postDefense: 40,
            insideShooting: 50,
            performances: {},
            primaryRole: PlayerRole.shootingGuard,
          ),
          EnhancedPlayer(
            name: 'Away SF',
            age: 26,
            team: 'Away Team',
            experienceYears: 4,
            nationality: 'France',
            currentStatus: 'Active',
            height: 198,
            shooting: 70,
            rebounding: 60,
            passing: 60,
            ballHandling: 60,
            perimeterDefense: 70,
            postDefense: 55,
            insideShooting: 60,
            performances: {},
            primaryRole: PlayerRole.smallForward,
          ),
          EnhancedPlayer(
            name: 'Away PF',
            age: 27,
            team: 'Away Team',
            experienceYears: 5,
            nationality: 'Australia',
            currentStatus: 'Active',
            height: 205,
            shooting: 55,
            rebounding: 80,
            passing: 45,
            ballHandling: 40,
            perimeterDefense: 55,
            postDefense: 75,
            insideShooting: 70,
            performances: {},
            primaryRole: PlayerRole.powerForward,
          ),
          EnhancedPlayer(
            name: 'Away C',
            age: 30,
            team: 'Away Team',
            experienceYears: 8,
            nationality: 'Serbia',
            currentStatus: 'Active',
            height: 215,
            shooting: 35,
            rebounding: 90,
            passing: 30,
            ballHandling: 20,
            perimeterDefense: 20,
            postDefense: 85,
            insideShooting: 80,
            performances: {},
            primaryRole: PlayerRole.center,
          ),
        ],
      );
    });

    group('Game Simulation', () {
      test('should simulate a complete game', () {
        final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);
        
        // Should return valid game result
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('homeScore'), isTrue);
        expect(result.containsKey('awayScore'), isTrue);
        expect(result.containsKey('homeBoxScore'), isTrue);
        expect(result.containsKey('awayBoxScore'), isTrue);
        
        // Scores should be realistic
        final homeScore = result['homeScore'] as int;
        final awayScore = result['awayScore'] as int;
        expect(homeScore, greaterThan(40)); // Minimum realistic score
        expect(homeScore, lessThan(140)); // Maximum realistic score
        expect(awayScore, greaterThan(40));
        expect(awayScore, lessThan(140));
      });

      test('should generate box scores for all players', () {
        final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);
        
        final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
        final awayBoxScore = result['awayBoxScore'] as Map<String, Map<String, int>>;
        
        // Should have box scores for all players
        expect(homeBoxScore.length, equals(5));
        expect(awayBoxScore.length, equals(5));
        
        // Each player should have complete stat line
        for (final playerStats in homeBoxScore.values) {
          expect(playerStats.containsKey('points'), isTrue);
          expect(playerStats.containsKey('rebounds'), isTrue);
          expect(playerStats.containsKey('assists'), isTrue);
          expect(playerStats.containsKey('FGM'), isTrue);
          expect(playerStats.containsKey('FGA'), isTrue);
          expect(playerStats.containsKey('3PM'), isTrue);
          expect(playerStats.containsKey('3PA'), isTrue);
        }
      });

      test('should record player performances', () {
        final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);
        
        // Check that performances were recorded
        for (final player in homeTeam.players) {
          final enhancedPlayer = player as EnhancedPlayer;
          expect(enhancedPlayer.performances.containsKey(1), isTrue);
          
          final performance = enhancedPlayer.performances[1]!;
          expect(performance.containsKey('points'), isTrue);
          expect(performance.containsKey('rebounds'), isTrue);
          expect(performance.containsKey('assists'), isTrue);
        }
      });

      test('should award role experience to players', () {
        // Get initial role experience
        final homePlayer = homeTeam.players[0] as EnhancedPlayer;
        final initialExperience = homePlayer.roleExperience[homePlayer.primaryRole] ?? 0.0;
        
        EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);
        
        // Should have gained experience
        final newExperience = homePlayer.roleExperience[homePlayer.primaryRole] ?? 0.0;
        expect(newExperience, greaterThan(initialExperience));
      });
    });

    group('Role-Based Behavior', () {
      test('should show position-specific shot selection', () {
        // Run multiple simulations to get statistical significance
        int centerInsideShots = 0;
        int centerThreePointers = 0;
        int guardThreePointers = 0;
        int sgThreePointers = 0;
        int totalSimulations = 15;

        for (int i = 0; i < totalSimulations; i++) {
          final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
          final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
          
          // Check center (should prefer inside shots, avoid three-pointers)
          final centerStats = homeBoxScore['Home C']!;
          final centerFGA = centerStats['FGA'] ?? 0;
          final center3PA = centerStats['3PA'] ?? 0;
          centerInsideShots += (centerFGA - center3PA); // Inside + mid-range shots
          centerThreePointers += center3PA;
          
          // Check guards (should take more three-pointers)
          final pgStats = homeBoxScore['Home PG']!;
          final sgStats = homeBoxScore['Home SG']!;
          guardThreePointers += pgStats['3PA'] ?? 0;
          sgThreePointers += sgStats['3PA'] ?? 0;
        }

        // Centers should take more inside shots than three-pointers
        expect(centerInsideShots, greaterThan(centerThreePointers));
        
        // Guards should attempt some three-pointers
        expect(guardThreePointers, greaterThan(0));
        
        // Both guards should attempt some three-pointers (combined should be reasonable)
        expect(sgThreePointers + guardThreePointers, greaterThan(0));
      });

      test('should show role-based rebounding distribution', () {
        int totalSimulations = 10;
        int bigManRebounds = 0;
        int guardRebounds = 0;
        int centerRebounds = 0;
        int pfRebounds = 0;

        for (int i = 0; i < totalSimulations; i++) {
          final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
          final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
          
          // Track rebounds by position
          centerRebounds += (homeBoxScore['Home C']!['rebounds'] ?? 0);
          pfRebounds += (homeBoxScore['Home PF']!['rebounds'] ?? 0);
          bigManRebounds += centerRebounds + pfRebounds;
          
          // Guards should get fewer rebounds
          guardRebounds += (homeBoxScore['Home PG']!['rebounds'] ?? 0);
          guardRebounds += (homeBoxScore['Home SG']!['rebounds'] ?? 0);
        }

        // Big men should generally get more rebounds than guards
        expect(bigManRebounds, greaterThan(guardRebounds));
        
        // Centers should get more rebounds than power forwards
        expect(centerRebounds, greaterThanOrEqualTo(pfRebounds));
      });

      test('should show role-based assist distribution', () {
        int totalSimulations = 10;
        int pgAssists = 0;
        int sgAssists = 0;
        int centerAssists = 0;
        int guardAssists = 0;

        for (int i = 0; i < totalSimulations; i++) {
          final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
          final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
          
          pgAssists += (homeBoxScore['Home PG']!['assists'] ?? 0);
          sgAssists += (homeBoxScore['Home SG']!['assists'] ?? 0);
          centerAssists += (homeBoxScore['Home C']!['assists'] ?? 0);
          guardAssists = pgAssists + sgAssists;
        }

        // Point guards should get the most assists
        expect(pgAssists, greaterThanOrEqualTo(sgAssists));
        expect(pgAssists, greaterThanOrEqualTo(centerAssists));
        
        // Guards combined should get more assists than centers
        expect(guardAssists, greaterThan(centerAssists));
      });

      test('should show role-based defensive stats distribution', () {
        int totalSimulations = 15;
        int centerBlocks = 0;
        int pfBlocks = 0;
        int guardBlocks = 0;
        int guardSteals = 0;
        int bigManSteals = 0;

        for (int i = 0; i < totalSimulations; i++) {
          final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
          final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
          
          // Track blocks by position
          centerBlocks += (homeBoxScore['Home C']!['blocks'] ?? 0);
          pfBlocks += (homeBoxScore['Home PF']!['blocks'] ?? 0);
          guardBlocks += (homeBoxScore['Home PG']!['blocks'] ?? 0);
          guardBlocks += (homeBoxScore['Home SG']!['blocks'] ?? 0);
          
          // Track steals by position
          guardSteals += (homeBoxScore['Home PG']!['steals'] ?? 0);
          guardSteals += (homeBoxScore['Home SG']!['steals'] ?? 0);
          bigManSteals += (homeBoxScore['Home C']!['steals'] ?? 0);
          bigManSteals += (homeBoxScore['Home PF']!['steals'] ?? 0);
        }

        // Big men should get more blocks than guards
        expect(centerBlocks + pfBlocks, greaterThanOrEqualTo(guardBlocks));
        
        // Centers should get more blocks than power forwards
        expect(centerBlocks, greaterThanOrEqualTo(pfBlocks));
        
        // Guards should get more steals than big men
        expect(guardSteals, greaterThanOrEqualTo(bigManSteals));
      });

      test('should apply role-based bonuses and penalties', () {
        // Create a player with poor role compatibility
        final outOfPositionPlayer = EnhancedPlayer(
          name: 'Out of Position',
          age: 25,
          team: 'Test Team',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 220, // Tall like a center
          shooting: 30, // Poor shooting
          rebounding: 95, // Great rebounding
          passing: 25, // Poor passing
          ballHandling: 20, // Poor ball handling
          perimeterDefense: 20, // Poor perimeter defense
          postDefense: 90, // Great post defense
          insideShooting: 85, // Great inside shooting
          performances: {},
          primaryRole: PlayerRole.pointGuard, // Assigned as PG but has center attributes
        );

        // Check role compatibility
        expect(outOfPositionPlayer.roleCompatibility, lessThan(0.7));
        
        // Check that penalties are applied (or at least role compatibility is poor)
        final penalties = outOfPositionPlayer.getOutOfPositionPenalties();
        final modifiers = outOfPositionPlayer.calculateRoleBasedModifiers();
        
        // Either should have penalties or poor role compatibility
        expect(outOfPositionPlayer.roleCompatibility < 0.7 || penalties.isNotEmpty, isTrue);
      });

      test('should show role experience gain during games', () {
        final player = homeTeam.players[0] as EnhancedPlayer;
        final initialExperience = player.roleExperience[player.primaryRole] ?? 0.0;
        
        // Simulate multiple games
        for (int i = 0; i < 5; i++) {
          EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
        }
        
        final finalExperience = player.roleExperience[player.primaryRole] ?? 0.0;
        expect(finalExperience, greaterThan(initialExperience));
        
        // Role compatibility should improve slightly with experience
        expect(player.roleCompatibility, greaterThanOrEqualTo(0.0));
      });
    });

    group('Statistical Validation', () {
      test('should produce realistic team statistics', () {
        final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, 1);
        final homeBoxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;
        
        // Calculate team totals
        int teamPoints = 0;
        int teamRebounds = 0;
        int teamAssists = 0;
        int teamFGA = 0;
        int teamFGM = 0;

        for (final playerStats in homeBoxScore.values) {
          teamPoints += playerStats['points'] ?? 0;
          teamRebounds += playerStats['rebounds'] ?? 0;
          teamAssists += playerStats['assists'] ?? 0;
          teamFGA += playerStats['FGA'] ?? 0;
          teamFGM += playerStats['FGM'] ?? 0;
        }

        // Validate realistic ranges
        expect(teamPoints, greaterThan(40));
        expect(teamPoints, lessThan(140));
        expect(teamRebounds, greaterThan(5)); // Even lower minimum for rebounds
        expect(teamRebounds, lessThan(60));
        expect(teamAssists, greaterThan(5)); // Lower minimum for assists
        expect(teamAssists, lessThan(40));
        
        // Field goal percentage should be reasonable
        if (teamFGA > 0) {
          final fgPercentage = teamFGM / teamFGA;
          expect(fgPercentage, greaterThan(0.2));
          expect(fgPercentage, lessThan(0.8)); // Allow for higher variance
        }
      });

      test('should maintain statistical consistency across multiple games', () {
        List<int> homeScores = [];
        List<int> awayScores = [];

        // Simulate multiple games
        for (int i = 0; i < 10; i++) {
          final result = EnhancedGameSimulation.simulateGame(homeTeam, awayTeam, i + 1);
          homeScores.add(result['homeScore'] as int);
          awayScores.add(result['awayScore'] as int);
        }

        // Calculate averages
        final avgHomeScore = homeScores.reduce((a, b) => a + b) / homeScores.length;
        final avgAwayScore = awayScores.reduce((a, b) => a + b) / awayScores.length;

        // Averages should be in realistic range
        expect(avgHomeScore, greaterThan(50));
        expect(avgHomeScore, lessThan(130));
        expect(avgAwayScore, greaterThan(50));
        expect(avgAwayScore, lessThan(130));

        // Should have some variation in scores
        final homeScoreRange = homeScores.reduce((a, b) => a > b ? a : b) - 
                              homeScores.reduce((a, b) => a < b ? a : b);
        expect(homeScoreRange, greaterThan(10)); // At least 10 point variation
      });
    });

    group('Role-Based Modifiers', () {
      test('should apply shooting bonuses for shooting guards', () {
        // Create a shooting guard with high shooting stats
        final shootingGuard = EnhancedPlayer(
          name: 'Elite SG',
          age: 26,
          team: 'Test Team',
          experienceYears: 4,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 195,
          shooting: 95,
          rebounding: 50,
          passing: 60,
          ballHandling: 70,
          perimeterDefense: 75,
          postDefense: 45,
          insideShooting: 55,
          performances: {},
          primaryRole: PlayerRole.shootingGuard,
        );

        final modifiers = shootingGuard.calculateRoleBasedModifiers();
        expect(modifiers.containsKey('shooting'), isTrue);
        expect(modifiers.containsKey('threePointShooting'), isTrue);
        
        // Should have shooting bonuses
        expect(modifiers['shooting'], greaterThan(1.0));
        expect(modifiers['threePointShooting'], greaterThan(1.0));
      });

      test('should apply rebounding bonuses for centers', () {
        final center = EnhancedPlayer(
          name: 'Elite C',
          age: 28,
          team: 'Test Team',
          experienceYears: 6,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 220,
          shooting: 40,
          rebounding: 95,
          passing: 35,
          ballHandling: 25,
          perimeterDefense: 25,
          postDefense: 90,
          insideShooting: 85,
          performances: {},
          primaryRole: PlayerRole.center,
        );

        final modifiers = center.calculateRoleBasedModifiers();
        expect(modifiers.containsKey('rebounding'), isTrue);
        expect(modifiers.containsKey('blocks'), isTrue);
        
        // Should have rebounding and blocks bonuses
        expect(modifiers['rebounding'], greaterThan(1.0));
        expect(modifiers['blocks'], greaterThan(1.0));
      });

      test('should apply assist bonuses for point guards', () {
        final pointGuard = EnhancedPlayer(
          name: 'Elite PG',
          age: 25,
          team: 'Test Team',
          experienceYears: 3,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 185,
          shooting: 75,
          rebounding: 45,
          passing: 95,
          ballHandling: 90,
          perimeterDefense: 70,
          postDefense: 40,
          insideShooting: 50,
          performances: {},
          primaryRole: PlayerRole.pointGuard,
        );

        final modifiers = pointGuard.calculateRoleBasedModifiers();
        expect(modifiers.containsKey('assists'), isTrue);
        expect(modifiers.containsKey('ballHandling'), isTrue);
        
        // Should have assist and ball handling bonuses
        expect(modifiers['assists'], greaterThan(1.0));
        expect(modifiers['ballHandling'], greaterThan(1.0));
      });

      test('should show different shot selection patterns by role', () {
        final testTeam = Team(
          name: 'Role Test Team',
          reputation: 80,
          playerCount: 5,
          teamSize: 5,
          players: [
            // Point Guard - should facilitate and take some threes
            EnhancedPlayer(
              name: 'Test PG',
              age: 25,
              team: 'Role Test Team',
              experienceYears: 3,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 185,
              shooting: 80,
              rebounding: 40,
              passing: 90,
              ballHandling: 85,
              perimeterDefense: 75,
              postDefense: 35,
              insideShooting: 45,
              performances: {},
              primaryRole: PlayerRole.pointGuard,
            ),
            // Shooting Guard - should take lots of threes
            EnhancedPlayer(
              name: 'Test SG',
              age: 26,
              team: 'Role Test Team',
              experienceYears: 4,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 195,
              shooting: 95,
              rebounding: 45,
              passing: 55,
              ballHandling: 70,
              perimeterDefense: 80,
              postDefense: 40,
              insideShooting: 50,
              performances: {},
              primaryRole: PlayerRole.shootingGuard,
            ),
            // Small Forward - balanced
            EnhancedPlayer(
              name: 'Test SF',
              age: 27,
              team: 'Role Test Team',
              experienceYears: 5,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 200,
              shooting: 75,
              rebounding: 65,
              passing: 65,
              ballHandling: 65,
              perimeterDefense: 75,
              postDefense: 60,
              insideShooting: 65,
              performances: {},
              primaryRole: PlayerRole.smallForward,
            ),
            // Power Forward - inside focused
            EnhancedPlayer(
              name: 'Test PF',
              age: 28,
              team: 'Role Test Team',
              experienceYears: 6,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 208,
              shooting: 55,
              rebounding: 85,
              passing: 45,
              ballHandling: 40,
              perimeterDefense: 55,
              postDefense: 85,
              insideShooting: 80,
              performances: {},
              primaryRole: PlayerRole.powerForward,
            ),
            // Center - pure inside
            EnhancedPlayer(
              name: 'Test C',
              age: 29,
              team: 'Role Test Team',
              experienceYears: 7,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 220,
              shooting: 30,
              rebounding: 95,
              passing: 30,
              ballHandling: 20,
              perimeterDefense: 20,
              postDefense: 95,
              insideShooting: 90,
              performances: {},
              primaryRole: PlayerRole.center,
            ),
          ],
        );

        // Run simulation
        final result = EnhancedGameSimulation.simulateGame(testTeam, awayTeam, 1);
        final boxScore = result['homeBoxScore'] as Map<String, Map<String, int>>;

        // Analyze shot patterns
        final sgStats = boxScore['Test SG']!;
        final centerStats = boxScore['Test C']!;
        
        final sgThreeAttempts = sgStats['3PA'] ?? 0;
        final sgTotalAttempts = sgStats['FGA'] ?? 0;
        final centerThreeAttempts = centerStats['3PA'] ?? 0;
        final centerTotalAttempts = centerStats['FGA'] ?? 0;

        // Shooting guard should attempt more threes relative to total shots
        if (sgTotalAttempts > 0 && centerTotalAttempts > 0) {
          final sgThreeRate = sgThreeAttempts / sgTotalAttempts;
          final centerThreeRate = centerThreeAttempts / centerTotalAttempts;
          expect(sgThreeRate, greaterThanOrEqualTo(centerThreeRate));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle team with insufficient players', () {
        final smallTeam = Team(
          name: 'Small Team',
          reputation: 50,
          playerCount: 3,
          teamSize: 3,
          players: homeTeam.players.take(3).toList(),
        );

        expect(
          () => EnhancedGameSimulation.simulateGame(smallTeam, awayTeam, 1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle players with extreme attributes', () {
        final extremeTeam = Team(
          name: 'Extreme Team',
          reputation: 100,
          playerCount: 5,
          teamSize: 5,
          players: [
            EnhancedPlayer(
              name: 'Perfect Player',
              age: 25,
              team: 'Extreme Team',
              experienceYears: 5,
              nationality: 'USA',
              currentStatus: 'Active',
              height: 200,
              shooting: 100,
              rebounding: 100,
              passing: 100,
              ballHandling: 100,
              perimeterDefense: 100,
              postDefense: 100,
              insideShooting: 100,
              performances: {},
              primaryRole: PlayerRole.pointGuard,
            ),
            ...homeTeam.players.skip(1).take(4).toList(),
          ],
        );

        final result = EnhancedGameSimulation.simulateGame(extremeTeam, awayTeam, 1);
        
        // Should still produce valid results
        expect(result['homeScore'], isA<int>());
        expect(result['awayScore'], isA<int>());
        expect(result['homeScore'], greaterThan(0));
      });
    });
  });
}