import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/models/team.dart';
import 'package:BasketballManager/services/game_service.dart';

void main() {
  group('Post Shooting Simulation Tests', () {
    late GameService gameService;

    setUp(() {
      gameService = GameService();
    });

    test('Centers with high post shooting should score more efficiently', () {
      // Create a center with high post shooting
      final highPostCenter = Player(
        id: 'high-post-center',
        name: 'High Post Center',
        heightInches: 84,
        shooting: 70,
        defense: 75,
        speed: 50,
        postShooting: 95, // Very high post shooting
        passing: 50,
        rebounding: 85,
        ballHandling: 40,
        threePoint: 30,
        blocks: 90,
        steals: 50,
        position: 'C',
      );

      // Create a center with low post shooting
      final lowPostCenter = Player(
        id: 'low-post-center',
        name: 'Low Post Center',
        heightInches: 84,
        shooting: 70,
        defense: 75,
        speed: 50,
        postShooting: 40, // Low post shooting
        passing: 50,
        rebounding: 85,
        ballHandling: 40,
        threePoint: 30,
        blocks: 90,
        steals: 50,
        position: 'C',
      );

      // Create supporting players (need 14 more to make 15 total)
      final supportingPlayers = List.generate(14, (i) => Player(
        id: 'support-$i',
        name: 'Support Player $i',
        heightInches: 75,
        shooting: 60,
        defense: 60,
        speed: 60,
        postShooting: 60,
        passing: 60,
        rebounding: 60,
        ballHandling: 60,
        threePoint: 60,
        blocks: 60,
        steals: 60,
        position: i < 4 ? 'SG' : 'SF',
      ));

      final highPostTeam = Team(
        id: 'high-post-team',
        name: 'High Post Team',
        city: 'Test City',
        players: [highPostCenter, ...supportingPlayers],
        startingLineupIds: [highPostCenter.id, ...supportingPlayers.take(4).map((p) => p.id)],
      );

      final lowPostTeam = Team(
        id: 'low-post-team',
        name: 'Low Post Team',
        city: 'Test City',
        players: [lowPostCenter, ...supportingPlayers],
        startingLineupIds: [lowPostCenter.id, ...supportingPlayers.take(4).map((p) => p.id)],
      );

      // Create opponent team (15 players)
      final opponentPlayers = List.generate(15, (i) => Player(
        id: 'opponent-$i',
        name: 'Opponent $i',
        heightInches: 75,
        shooting: 60,
        defense: 60,
        speed: 60,
        postShooting: 60,
        passing: 60,
        rebounding: 60,
        ballHandling: 60,
        threePoint: 60,
        blocks: 60,
        steals: 60,
        position: 'SF',
      ));

      final opponentTeam = Team(
        id: 'opponent-team',
        name: 'Opponent Team',
        city: 'Opponent City',
        players: opponentPlayers,
        startingLineupIds: opponentPlayers.take(5).map((p) => p.id).toList(),
      );

      // Simulate multiple games and track center scoring
      int highPostCenterTotalPoints = 0;
      int lowPostCenterTotalPoints = 0;
      int highPostCenterTotalFGM = 0;
      int lowPostCenterTotalFGM = 0;
      int highPostCenterTotalFGA = 0;
      int lowPostCenterTotalFGA = 0;

      const numGames = 20;

      for (int i = 0; i < numGames; i++) {
        final highPostGame = gameService.simulateGameDetailed(highPostTeam, opponentTeam);
        final lowPostGame = gameService.simulateGameDetailed(lowPostTeam, opponentTeam);

        final highPostStats = highPostGame.boxScore![highPostCenter.id]!;
        final lowPostStats = lowPostGame.boxScore![lowPostCenter.id]!;

        highPostCenterTotalPoints += highPostStats.points;
        lowPostCenterTotalPoints += lowPostStats.points;
        highPostCenterTotalFGM += highPostStats.fieldGoalsMade;
        lowPostCenterTotalFGM += lowPostStats.fieldGoalsMade;
        highPostCenterTotalFGA += highPostStats.fieldGoalsAttempted;
        lowPostCenterTotalFGA += lowPostStats.fieldGoalsAttempted;
      }

      // Calculate averages
      final highPostAvgPoints = highPostCenterTotalPoints / numGames;
      final lowPostAvgPoints = lowPostCenterTotalPoints / numGames;
      final highPostFGPct = highPostCenterTotalFGA > 0 
          ? (highPostCenterTotalFGM / highPostCenterTotalFGA) * 100 
          : 0;
      final lowPostFGPct = lowPostCenterTotalFGA > 0 
          ? (lowPostCenterTotalFGM / lowPostCenterTotalFGA) * 100 
          : 0;

      print('High Post Center - Avg Points: ${highPostAvgPoints.toStringAsFixed(1)}, FG%: ${highPostFGPct.toStringAsFixed(1)}%');
      print('Low Post Center - Avg Points: ${lowPostAvgPoints.toStringAsFixed(1)}, FG%: ${lowPostFGPct.toStringAsFixed(1)}%');

      // High post shooting center should score more points on average
      expect(highPostAvgPoints, greaterThan(lowPostAvgPoints),
          reason: 'Center with higher post shooting should score more points');

      // High post shooting center should have better field goal percentage
      expect(highPostFGPct, greaterThan(lowPostFGPct),
          reason: 'Center with higher post shooting should have better FG%');
    });

    test('Power forwards with high post shooting should score more efficiently', () {
      // Create a power forward with high post shooting
      final highPostPF = Player(
        id: 'high-post-pf',
        name: 'High Post PF',
        heightInches: 81,
        shooting: 70,
        defense: 75,
        speed: 55,
        postShooting: 90, // Very high post shooting
        passing: 55,
        rebounding: 80,
        ballHandling: 50,
        threePoint: 40,
        blocks: 75,
        steals: 55,
        position: 'PF',
      );

      // Create a power forward with low post shooting
      final lowPostPF = Player(
        id: 'low-post-pf',
        name: 'Low Post PF',
        heightInches: 81,
        shooting: 70,
        defense: 75,
        speed: 55,
        postShooting: 45, // Low post shooting
        passing: 55,
        rebounding: 80,
        ballHandling: 50,
        threePoint: 40,
        blocks: 75,
        steals: 55,
        position: 'PF',
      );

      // Create supporting players (need 14 more to make 15 total)
      final supportingPlayers = List.generate(14, (i) => Player(
        id: 'support-pf-$i',
        name: 'Support Player $i',
        heightInches: 75,
        shooting: 60,
        defense: 60,
        speed: 60,
        postShooting: 60,
        passing: 60,
        rebounding: 60,
        ballHandling: 60,
        threePoint: 60,
        blocks: 60,
        steals: 60,
        position: i < 4 ? 'SG' : 'SF',
      ));

      final highPostTeam = Team(
        id: 'high-post-pf-team',
        name: 'High Post PF Team',
        city: 'Test City',
        players: [highPostPF, ...supportingPlayers],
        startingLineupIds: [highPostPF.id, ...supportingPlayers.take(4).map((p) => p.id)],
      );

      final lowPostTeam = Team(
        id: 'low-post-pf-team',
        name: 'Low Post PF Team',
        city: 'Test City',
        players: [lowPostPF, ...supportingPlayers],
        startingLineupIds: [lowPostPF.id, ...supportingPlayers.take(4).map((p) => p.id)],
      );

      // Create opponent team
      final opponentPlayers = List.generate(15, (i) => Player(
        id: 'opponent-2-$i',
        name: 'Opponent $i',
        heightInches: 75,
        shooting: 60,
        defense: 60,
        speed: 60,
        postShooting: 60,
        passing: 60,
        rebounding: 60,
        ballHandling: 60,
        threePoint: 60,
        blocks: 60,
        steals: 60,
        position: 'SF',
      ));

      final opponentTeam = Team(
        id: 'opponent-team-2',
        name: 'Opponent Team',
        city: 'Opponent City',
        players: opponentPlayers,
        startingLineupIds: opponentPlayers.take(5).map((p) => p.id).toList(),
      );

      // Simulate multiple games
      int highPostPFTotalFGM = 0;
      int lowPostPFTotalFGM = 0;
      int highPostPFTotalFGA = 0;
      int lowPostPFTotalFGA = 0;

      const numGames = 20;

      for (int i = 0; i < numGames; i++) {
        final highPostGame = gameService.simulateGameDetailed(highPostTeam, opponentTeam);
        final lowPostGame = gameService.simulateGameDetailed(lowPostTeam, opponentTeam);

        final highPostStats = highPostGame.boxScore![highPostPF.id]!;
        final lowPostStats = lowPostGame.boxScore![lowPostPF.id]!;

        highPostPFTotalFGM += highPostStats.fieldGoalsMade;
        lowPostPFTotalFGM += lowPostStats.fieldGoalsMade;
        highPostPFTotalFGA += highPostStats.fieldGoalsAttempted;
        lowPostPFTotalFGA += lowPostStats.fieldGoalsAttempted;
      }

      // Calculate field goal percentages
      final highPostFGPct = highPostPFTotalFGA > 0 
          ? (highPostPFTotalFGM / highPostPFTotalFGA) * 100 
          : 0;
      final lowPostFGPct = lowPostPFTotalFGA > 0 
          ? (lowPostPFTotalFGM / lowPostPFTotalFGA) * 100 
          : 0;

      print('High Post PF - FG%: ${highPostFGPct.toStringAsFixed(1)}%');
      print('Low Post PF - FG%: ${lowPostFGPct.toStringAsFixed(1)}%');

      // High post shooting PF should have better field goal percentage
      expect(highPostFGPct, greaterThan(lowPostFGPct),
          reason: 'PF with higher post shooting should have better FG%');
    });
  });
}
