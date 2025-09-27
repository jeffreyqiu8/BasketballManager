import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/strategy_history.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('StrategyHistory Tests', () {
    late StrategyHistory strategyHistory;
    late Playbook testPlaybook;

    setUp(() {
      strategyHistory = StrategyHistory();
      testPlaybook = Playbook(
        name: 'Test Playbook',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.pressDefense,
      );
    });

    test('should record strategy changes', () {
      strategyHistory.recordStrategyChange(
        testPlaybook,
        1, // gameId
        2, // quarter
        300, // timeRemaining
        'Trailing by 10 points',
      );

      expect(strategyHistory.entries.length, 1);
      expect(strategyHistory.entries.first.playbookName, 'Test Playbook');
      expect(strategyHistory.entries.first.gameId, 1);
      expect(strategyHistory.entries.first.quarter, 2);
      expect(strategyHistory.entries.first.reason, 'Trailing by 10 points');
    });

    test('should record performance metrics', () {
      // First record a strategy change
      strategyHistory.recordStrategyChange(
        testPlaybook,
        1,
        2,
        300,
        'Test change',
      );

      // Then record performance
      GameSegmentStats stats = GameSegmentStats(
        pointsScored: 15.0,
        pointsAllowed: 12.0,
        turnovers: 2.0,
        rebounds: 8.0,
      );

      strategyHistory.recordPerformance('Test Playbook', 1, stats);

      expect(strategyHistory.entries.first.performance, isNotNull);
      expect(strategyHistory.entries.first.performance!.pointsScored, 15.0);
      expect(strategyHistory.playbookStats.containsKey('Test Playbook'), true);
    });

    test('should calculate strategy statistics', () {
      GameSegmentStats stats1 = GameSegmentStats(
        pointsScored: 20.0,
        pointsAllowed: 15.0,
        turnovers: 3.0,
        rebounds: 10.0,
      );

      GameSegmentStats stats2 = GameSegmentStats(
        pointsScored: 18.0,
        pointsAllowed: 20.0,
        turnovers: 2.0,
        rebounds: 8.0,
      );

      strategyHistory.recordPerformance('Test Playbook', 1, stats1);
      strategyHistory.recordPerformance('Test Playbook', 2, stats2);

      StrategyStats? stats = strategyHistory.getPlaybookStats('Test Playbook');
      expect(stats, isNotNull);
      expect(stats!.gamesUsed, 2);
      expect(stats.averagePointsScored, 19.0);
      expect(stats.averagePointsAllowed, 17.5);
      expect(stats.averageTurnovers, 2.5);
    });

    test('should generate strategy recommendations', () {
      // Add some performance data
      GameSegmentStats goodStats = GameSegmentStats(
        pointsScored: 25.0,
        pointsAllowed: 18.0,
        turnovers: 2.0,
        rebounds: 12.0,
      );

      // Record multiple good performances
      for (int i = 1; i <= 5; i++) {
        strategyHistory.recordPerformance('Test Playbook', i, goodStats);
      }

      List<StrategyRecommendation> recommendations = strategyHistory.getRecommendations(
        quarter: 4,
        scoreDifferential: -5, // Trailing
      );

      expect(recommendations.isNotEmpty, true);
      if (recommendations.isNotEmpty) {
        expect(recommendations.first.playbookName, 'Test Playbook');
        expect(recommendations.first.effectiveness, greaterThan(0.6));
      }
    });

    test('should get recent strategy changes', () {
      // Add multiple strategy changes with different timestamps
      for (int i = 1; i <= 5; i++) {
        strategyHistory.entries.add(StrategyPerformanceEntry(
          playbookName: testPlaybook.name,
          gameId: i,
          quarter: 1,
          timeRemaining: 600,
          timestamp: DateTime.now().add(Duration(seconds: i)),
          reason: 'Change $i',
        ));
      }

      List<StrategyPerformanceEntry> recent = strategyHistory.getRecentChanges(limit: 3);
      expect(recent.length, 3);
      // Should be in reverse chronological order (most recent first)
      expect(recent.first.reason, 'Change 5');
    });

    test('should serialize and deserialize strategy history', () {
      strategyHistory.recordStrategyChange(
        testPlaybook,
        1,
        2,
        300,
        'Test serialization',
      );

      GameSegmentStats stats = GameSegmentStats(
        pointsScored: 20.0,
        pointsAllowed: 15.0,
        turnovers: 3.0,
        rebounds: 10.0,
      );
      strategyHistory.recordPerformance('Test Playbook', 1, stats);

      Map<String, dynamic> serialized = strategyHistory.toMap();
      StrategyHistory deserialized = StrategyHistory.fromMap(serialized);

      expect(deserialized.entries.length, strategyHistory.entries.length);
      expect(deserialized.playbookStats.length, strategyHistory.playbookStats.length);
      expect(deserialized.entries.first.playbookName, 'Test Playbook');
    });

    test('should calculate effectiveness correctly', () {
      GameSegmentStats highEffectiveness = GameSegmentStats(
        pointsScored: 30.0,
        pointsAllowed: 20.0,
        turnovers: 1.0,
        rebounds: 15.0,
      );

      GameSegmentStats lowEffectiveness = GameSegmentStats(
        pointsScored: 15.0,
        pointsAllowed: 25.0,
        turnovers: 5.0,
        rebounds: 5.0,
      );

      strategyHistory.recordPerformance('High Effectiveness', 1, highEffectiveness);
      strategyHistory.recordPerformance('Low Effectiveness', 1, lowEffectiveness);

      StrategyStats? highStats = strategyHistory.getPlaybookStats('High Effectiveness');
      StrategyStats? lowStats = strategyHistory.getPlaybookStats('Low Effectiveness');

      expect(highStats!.averageEffectiveness, greaterThan(lowStats!.averageEffectiveness));
    });

    test('should handle empty history gracefully', () {
      List<StrategyRecommendation> recommendations = strategyHistory.getRecommendations();
      expect(recommendations.isEmpty, true);

      List<StrategyPerformanceEntry> recent = strategyHistory.getRecentChanges();
      expect(recent.isEmpty, true);

      StrategyStats? stats = strategyHistory.getPlaybookStats('Nonexistent');
      expect(stats, isNull);
    });
  });

  group('GameSegmentStats Tests', () {
    test('should serialize and deserialize correctly', () {
      GameSegmentStats original = GameSegmentStats(
        pointsScored: 25.0,
        pointsAllowed: 20.0,
        turnovers: 3.0,
        rebounds: 12.0,
        assists: 8.0,
        steals: 4.0,
        possessions: 20,
      );

      Map<String, dynamic> serialized = original.toMap();
      GameSegmentStats deserialized = GameSegmentStats.fromMap(serialized);

      expect(deserialized.pointsScored, original.pointsScored);
      expect(deserialized.pointsAllowed, original.pointsAllowed);
      expect(deserialized.turnovers, original.turnovers);
      expect(deserialized.rebounds, original.rebounds);
      expect(deserialized.assists, original.assists);
      expect(deserialized.steals, original.steals);
      expect(deserialized.possessions, original.possessions);
    });
  });

  group('StrategyStats Tests', () {
    test('should update averages correctly when adding performances', () {
      StrategyStats stats = StrategyStats(playbookName: 'Test');

      GameSegmentStats performance1 = GameSegmentStats(
        pointsScored: 20.0,
        pointsAllowed: 15.0,
        turnovers: 2.0,
        rebounds: 10.0,
      );

      GameSegmentStats performance2 = GameSegmentStats(
        pointsScored: 24.0,
        pointsAllowed: 18.0,
        turnovers: 3.0,
        rebounds: 8.0,
      );

      stats.addPerformance(performance1);
      expect(stats.gamesUsed, 1);
      expect(stats.averagePointsScored, 20.0);

      stats.addPerformance(performance2);
      expect(stats.gamesUsed, 2);
      expect(stats.averagePointsScored, 22.0);
      expect(stats.averagePointsAllowed, 16.5);
      expect(stats.averageTurnovers, 2.5);
    });

    test('should calculate variance correctly', () {
      StrategyStats stats = StrategyStats(playbookName: 'Test');

      // Add performances with varying effectiveness
      GameSegmentStats consistent1 = GameSegmentStats(
        pointsScored: 20.0,
        pointsAllowed: 15.0,
        turnovers: 2.0,
        rebounds: 10.0,
      );

      GameSegmentStats consistent2 = GameSegmentStats(
        pointsScored: 21.0,
        pointsAllowed: 16.0,
        turnovers: 2.0,
        rebounds: 10.0,
      );

      stats.addPerformance(consistent1);
      stats.addPerformance(consistent2);

      double lowVariance = stats.effectivenessVariance;

      // Reset and add more varied performances
      StrategyStats stats2 = StrategyStats(playbookName: 'Test2');

      GameSegmentStats varied1 = GameSegmentStats(
        pointsScored: 30.0,
        pointsAllowed: 10.0,
        turnovers: 1.0,
        rebounds: 15.0,
      );

      GameSegmentStats varied2 = GameSegmentStats(
        pointsScored: 10.0,
        pointsAllowed: 30.0,
        turnovers: 5.0,
        rebounds: 5.0,
      );

      stats2.addPerformance(varied1);
      stats2.addPerformance(varied2);

      double highVariance = stats2.effectivenessVariance;

      expect(highVariance, greaterThan(lowVariance));
    });
  });
}