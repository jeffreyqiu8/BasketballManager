import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/aging_service.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('AgingService Tests', () {
    late EnhancedPlayer youngPlayer;
    late EnhancedPlayer oldPlayer;
    late EnhancedPlayer elitePlayer;

    setUp(() {
      youngPlayer = EnhancedPlayer(
        name: 'Young Player',
        age: 25,
        team: 'Test Team',
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 200,
        shooting: 75,
        rebounding: 70,
        passing: 65,
        ballHandling: 60,
        perimeterDefense: 65,
        postDefense: 70,
        insideShooting: 75,
        performances: {},
        primaryRole: PlayerRole.smallForward,
        potential: PlayerPotential.fromTier(PotentialTier.silver),
        development: DevelopmentTracker.initial(age: 25),
      );

      oldPlayer = EnhancedPlayer(
        name: 'Old Player',
        age: 35,
        team: 'Test Team',
        experienceYears: 15,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 205,
        shooting: 65,
        rebounding: 75,
        passing: 60,
        ballHandling: 55,
        perimeterDefense: 60,
        postDefense: 80,
        insideShooting: 70,
        performances: {},
        primaryRole: PlayerRole.center,
        potential: PlayerPotential.fromTier(PotentialTier.bronze),
        development: DevelopmentTracker.initial(age: 35),
      );

      elitePlayer = EnhancedPlayer(
        name: 'Elite Player',
        age: 30,
        team: 'Test Team',
        experienceYears: 10,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 198,
        shooting: 90,
        rebounding: 85,
        passing: 88,
        ballHandling: 92,
        perimeterDefense: 87,
        postDefense: 80,
        insideShooting: 85,
        performances: {},
        primaryRole: PlayerRole.pointGuard,
        potential: PlayerPotential.fromTier(PotentialTier.elite),
        development: DevelopmentTracker.initial(age: 30),
      );
    });

    test('should age player correctly', () {
      final initialAge = youngPlayer.age;
      final result = AgingService.processPlayerAging(youngPlayer);
      
      expect(youngPlayer.age, initialAge + 1);
      expect(result.previousAge, initialAge);
      expect(result.newAge, initialAge + 1);
      expect(result.playerName, youngPlayer.name);
    });

    test('should not degrade skills for young players', () {
      final initialShooting = youngPlayer.shooting;
      final result = AgingService.processPlayerAging(youngPlayer);
      
      // Young players (25) shouldn't have significant degradation
      expect(youngPlayer.shooting, greaterThanOrEqualTo(initialShooting - 1));
      expect(result.shouldRetire, false);
    });

    test('should degrade skills for old players', () {
      final initialSkills = {
        'shooting': oldPlayer.shooting,
        'rebounding': oldPlayer.rebounding,
        'passing': oldPlayer.passing,
        'ballHandling': oldPlayer.ballHandling,
        'perimeterDefense': oldPlayer.perimeterDefense,
        'postDefense': oldPlayer.postDefense,
        'insideShooting': oldPlayer.insideShooting,
      };

      final result = AgingService.processPlayerAging(oldPlayer);
      
      // Old players should have some skill degradation
      bool hasSkillDegradation = result.skillChanges.values.any((change) => change.change < 0);
      expect(hasSkillDegradation, true);
      
      // Skills should not go below 30
      expect(oldPlayer.shooting, greaterThanOrEqualTo(30));
      expect(oldPlayer.rebounding, greaterThanOrEqualTo(30));
    });

    test('should handle retirement correctly', () {
      // Age the player to retirement age
      oldPlayer.age = 40;
      oldPlayer.shooting = 40;
      oldPlayer.rebounding = 45;
      oldPlayer.passing = 35;
      oldPlayer.ballHandling = 30;
      oldPlayer.perimeterDefense = 35;
      oldPlayer.postDefense = 50;
      oldPlayer.insideShooting = 40;

      final result = AgingService.processPlayerAging(oldPlayer);
      
      expect(result.shouldRetire, true);
      expect(result.retirementReason, isNotNull);
    });

    test('should not retire elite players prematurely', () {
      // Elite players should have longer careers
      final result = AgingService.processPlayerAging(elitePlayer);
      
      expect(result.shouldRetire, false);
      
      // Even with some skill degradation, elite players should maintain high skills
      final overallSkill = (elitePlayer.shooting + elitePlayer.rebounding + 
                           elitePlayer.passing + elitePlayer.ballHandling + 
                           elitePlayer.perimeterDefense + elitePlayer.postDefense + 
                           elitePlayer.insideShooting) / 7.0;
      expect(overallSkill, greaterThan(75));
    });

    test('should process team aging correctly', () {
      final team = [youngPlayer, oldPlayer, elitePlayer];
      final results = AgingService.processTeamAging(team);
      
      expect(results.length, 3);
      expect(results[0].playerName, youngPlayer.name);
      expect(results[1].playerName, oldPlayer.name);
      expect(results[2].playerName, elitePlayer.name);
      
      // All players should be aged
      expect(team.every((player) => player.age > 25), true);
    });

    test('should create custom aging curves correctly', () {
      final pgCurve = AgingService.createCustomAgingCurve(
        role: PlayerRole.pointGuard,
        currentAge: 25,
        overallSkill: 80,
      );
      
      final centerCurve = AgingService.createCustomAgingCurve(
        role: PlayerRole.center,
        currentAge: 25,
        overallSkill: 80,
      );
      
      // Point guards should have longer careers than centers
      expect(pgCurve.retirementAge, greaterThan(centerCurve.retirementAge));
      expect(pgCurve.declineRate, lessThan(centerCurve.declineRate));
    });

    test('should adjust aging curves for elite players', () {
      final eliteCurve = AgingService.createCustomAgingCurve(
        role: PlayerRole.shootingGuard,
        currentAge: 25,
        overallSkill: 90, // Elite skill
      );
      
      final averageCurve = AgingService.createCustomAgingCurve(
        role: PlayerRole.shootingGuard,
        currentAge: 25,
        overallSkill: 70, // Average skill
      );
      
      // Elite players should have extended careers
      expect(eliteCurve.retirementAge, greaterThan(averageCurve.retirementAge));
      expect(eliteCurve.declineRate, lessThan(averageCurve.declineRate));
    });

    test('should project career progression correctly', () {
      final projections = AgingService.projectCareerProgression(youngPlayer, 10);
      
      expect(projections.length, greaterThan(0));
      expect(projections.length, lessThanOrEqualTo(10));
      
      // Projections should show aging
      expect(projections.first.age, youngPlayer.age + 1);
      
      // Overall skill should generally decline over time (for older projections)
      if (projections.length > 5) {
        expect(projections.last.projectedOverall, lessThan(projections.first.projectedOverall));
      }
    });

    test('should calculate retirement probability correctly', () {
      // Young player should have low retirement probability
      youngPlayer.age = 25;
      final youngProjections = AgingService.projectCareerProgression(youngPlayer, 1);
      expect(youngProjections.first.retirementProbability, lessThan(0.1));
      
      // Old player should have high retirement probability
      oldPlayer.age = 38;
      final oldProjections = AgingService.projectCareerProgression(oldPlayer, 1);
      expect(oldProjections.first.retirementProbability, greaterThan(0.5));
    });

    test('should handle different skill degradation rates', () {
      // Set up player with high skills
      oldPlayer.shooting = 85;
      oldPlayer.rebounding = 85;
      oldPlayer.passing = 85;
      oldPlayer.ballHandling = 85;
      oldPlayer.perimeterDefense = 85;
      oldPlayer.postDefense = 85;
      oldPlayer.insideShooting = 85;
      
      final result = AgingService.processPlayerAging(oldPlayer);
      
      // Physical skills should degrade more than mental skills
      if (result.skillChanges.containsKey('passing') && result.skillChanges.containsKey('perimeterDefense')) {
        final passingChange = result.skillChanges['passing']!.change;
        final defenseChange = result.skillChanges['perimeterDefense']!.change;
        
        // Defense (physical) should degrade more than passing (mental)
        expect(defenseChange, lessThanOrEqualTo(passingChange));
      }
    });

    test('should respect minimum skill values', () {
      // Set player with very low skills
      oldPlayer.shooting = 35;
      oldPlayer.rebounding = 32;
      oldPlayer.passing = 31;
      oldPlayer.ballHandling = 30;
      
      // Age multiple times
      for (int i = 0; i < 5; i++) {
        AgingService.processPlayerAging(oldPlayer);
      }
      
      // Skills should not go below 30
      expect(oldPlayer.shooting, greaterThanOrEqualTo(30));
      expect(oldPlayer.rebounding, greaterThanOrEqualTo(30));
      expect(oldPlayer.passing, greaterThanOrEqualTo(30));
      expect(oldPlayer.ballHandling, greaterThanOrEqualTo(30));
    });

    test('should provide detailed aging results', () {
      oldPlayer.age = 33; // Ensure some degradation
      final result = AgingService.processPlayerAging(oldPlayer);
      
      expect(result.playerName, isNotEmpty);
      expect(result.previousAge, greaterThan(0));
      expect(result.newAge, result.previousAge + 1);
      
      if (result.skillChanges.isNotEmpty) {
        final firstChange = result.skillChanges.values.first;
        expect(firstChange.previousValue, greaterThan(0));
        expect(firstChange.newValue, greaterThan(0));
        expect(firstChange.change, firstChange.newValue - firstChange.previousValue);
      }
    });

    test('should handle different retirement reasons', () {
      // Test age-based retirement
      oldPlayer.age = 42;
      var result = AgingService.processPlayerAging(oldPlayer);
      if (result.shouldRetire) {
        expect(result.retirementReason, RetirementReason.age);
      }
      
      // Test performance-based retirement
      oldPlayer.age = 35;
      oldPlayer.shooting = 40;
      oldPlayer.rebounding = 35;
      oldPlayer.passing = 30;
      oldPlayer.ballHandling = 35;
      oldPlayer.perimeterDefense = 30;
      oldPlayer.postDefense = 40;
      oldPlayer.insideShooting = 35;
      
      result = AgingService.processPlayerAging(oldPlayer);
      if (result.shouldRetire) {
        expect(result.retirementReason, 
               isIn([RetirementReason.performance, RetirementReason.voluntary]));
      }
    });
  });
}