import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('PlayerPotential Tests', () {
    test('should create default potential correctly', () {
      final potential = PlayerPotential.defaultPotential();
      
      expect(potential.tier, PotentialTier.bronze);
      expect(potential.overallPotential, 75);
      expect(potential.isHidden, true);
      expect(potential.maxSkills.length, 7);
      expect(potential.maxSkills['shooting'], 75);
    });

    test('should create potential from tier correctly', () {
      final bronzePotential = PlayerPotential.fromTier(PotentialTier.bronze);
      final elitePotential = PlayerPotential.fromTier(PotentialTier.elite);
      
      expect(bronzePotential.tier, PotentialTier.bronze);
      expect(bronzePotential.overallPotential, greaterThanOrEqualTo(70));
      expect(bronzePotential.overallPotential, lessThan(80));
      
      expect(elitePotential.tier, PotentialTier.elite);
      expect(elitePotential.overallPotential, greaterThanOrEqualTo(95));
      expect(elitePotential.overallPotential, lessThan(100));
    });

    test('should check skill improvement correctly', () {
      final potential = PlayerPotential(
        tier: PotentialTier.gold,
        maxSkills: {'shooting': 95, 'rebounding': 90},
        overallPotential: 92,
      );
      
      expect(potential.canImproveSkill('shooting', 85), true);
      expect(potential.canImproveSkill('shooting', 99), false);
      expect(potential.canImproveSkill('rebounding', 85), true);
      expect(potential.canImproveSkill('rebounding', 95), false);
    });

    test('should calculate remaining potential correctly', () {
      final potential = PlayerPotential(
        tier: PotentialTier.silver,
        maxSkills: {'shooting': 85},
        overallPotential: 85,
      );
      
      expect(potential.getRemainingPotential('shooting', 80), 5);
      expect(potential.getRemainingPotential('shooting', 90), 0);
    });

    test('should serialize and deserialize correctly', () {
      final original = PlayerPotential.fromTier(PotentialTier.gold, isHidden: false);
      final map = original.toMap();
      final restored = PlayerPotential.fromMap(map);
      
      expect(restored.tier, original.tier);
      expect(restored.overallPotential, original.overallPotential);
      expect(restored.isHidden, original.isHidden);
      expect(restored.maxSkills.length, original.maxSkills.length);
    });
  });

  group('DevelopmentTracker Tests', () {
    test('should create initial tracker correctly', () {
      final tracker = DevelopmentTracker.initial();
      
      expect(tracker.totalExperience, 0);
      expect(tracker.developmentRate, 1.0);
      expect(tracker.skillExperience.length, 7);
      expect(tracker.milestones.length, 5);
      expect(tracker.skillExperience['shooting'], 0);
    });

    test('should create tracker for specific age', () {
      final youngTracker = DevelopmentTracker.initial(age: 20);
      final oldTracker = DevelopmentTracker.initial(age: 35);
      
      expect(youngTracker.agingCurve.peakAge, 28);
      expect(oldTracker.agingCurve.peakAge, 25);
    });

    test('should add skill experience correctly', () {
      final tracker = DevelopmentTracker.initial();
      
      tracker.addSkillExperience('shooting', 150);
      
      expect(tracker.skillExperience['shooting'], 150);
      expect(tracker.totalExperience, 150);
      expect(tracker.milestones.first.isAchieved, true);
    });

    test('should add general experience correctly', () {
      final tracker = DevelopmentTracker.initial();
      
      tracker.addGeneralExperience(700);
      
      expect(tracker.totalExperience, 700);
      expect(tracker.skillExperience.values.reduce((a, b) => a + b), 700);
      
      // Check that milestones are achieved
      final achievedMilestones = tracker.milestones.where((m) => m.isAchieved).length;
      expect(achievedMilestones, greaterThan(0));
    });

    test('should calculate experience for next skill point correctly', () {
      final tracker = DevelopmentTracker.initial();
      
      expect(tracker.getExperienceForNextSkillPoint('shooting'), 100);
      
      tracker.addSkillExperience('shooting', 150);
      expect(tracker.getExperienceForNextSkillPoint('shooting'), 200);
    });

    test('should check skill upgrade eligibility correctly', () {
      final tracker = DevelopmentTracker.initial();
      final potential = PlayerPotential(
        tier: PotentialTier.gold,
        maxSkills: {'shooting': 95},
        overallPotential: 92,
      );
      
      expect(tracker.canUpgradeSkill('shooting', potential, 70), false);
      
      tracker.addSkillExperience('shooting', 100);
      expect(tracker.canUpgradeSkill('shooting', potential, 70), true);
    });

    test('should upgrade skill correctly', () {
      final tracker = DevelopmentTracker.initial();
      final potential = PlayerPotential(
        tier: PotentialTier.gold,
        maxSkills: {'shooting': 95},
        overallPotential: 92,
      );
      
      tracker.addSkillExperience('shooting', 100);
      final initialExp = tracker.skillExperience['shooting']!;
      
      final upgraded = tracker.upgradeSkill('shooting', potential, 70);
      
      expect(upgraded, true);
      expect(tracker.skillExperience['shooting'], lessThan(initialExp));
    });

    test('should calculate development rate with bonuses', () {
      final tracker = DevelopmentTracker.initial();
      
      final rate25 = tracker.getCurrentDevelopmentRate(25);
      final rate35 = tracker.getCurrentDevelopmentRate(35);
      final rateWithBonus = tracker.getCurrentDevelopmentRate(25, coachBonus: 0.5);
      
      expect(rate25, greaterThan(rate35));
      expect(rateWithBonus, greaterThan(rate25));
    });

    test('should serialize and deserialize correctly', () {
      final original = DevelopmentTracker.initial();
      original.addSkillExperience('shooting', 250);
      
      final map = original.toMap();
      final restored = DevelopmentTracker.fromMap(map);
      
      expect(restored.totalExperience, original.totalExperience);
      expect(restored.skillExperience['shooting'], original.skillExperience['shooting']);
      expect(restored.developmentRate, original.developmentRate);
      expect(restored.milestones.length, original.milestones.length);
    });
  });

  group('DevelopmentMilestone Tests', () {
    test('should create milestone correctly', () {
      final milestone = DevelopmentMilestone(
        name: 'Test Milestone',
        description: 'Test description',
        experienceRequired: 500,
      );
      
      expect(milestone.name, 'Test Milestone');
      expect(milestone.isAchieved, false);
      expect(milestone.achievedDate, null);
    });

    test('should achieve milestone correctly', () {
      final milestone = DevelopmentMilestone(
        name: 'Test Milestone',
        description: 'Test description',
        experienceRequired: 500,
      );
      
      milestone.achieve();
      
      expect(milestone.isAchieved, true);
      expect(milestone.achievedDate, isNotNull);
    });

    test('should not re-achieve milestone', () {
      final milestone = DevelopmentMilestone(
        name: 'Test Milestone',
        description: 'Test description',
        experienceRequired: 500,
      );
      
      milestone.achieve();
      final firstDate = milestone.achievedDate;
      
      // Wait a bit and try to achieve again
      Future.delayed(Duration(milliseconds: 1), () {
        milestone.achieve();
        expect(milestone.achievedDate, firstDate);
      });
    });

    test('should reset milestone correctly', () {
      final milestone = DevelopmentMilestone(
        name: 'Test Milestone',
        description: 'Test description',
        experienceRequired: 500,
      );
      
      milestone.achieve();
      milestone.reset();
      
      expect(milestone.isAchieved, false);
      expect(milestone.achievedDate, null);
    });

    test('should serialize and deserialize correctly', () {
      final original = DevelopmentMilestone(
        name: 'Test Milestone',
        description: 'Test description',
        experienceRequired: 500,
      );
      original.achieve();
      
      final map = original.toMap();
      final restored = DevelopmentMilestone.fromMap(map);
      
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.experienceRequired, original.experienceRequired);
      expect(restored.isAchieved, original.isAchieved);
      expect(restored.achievedDate?.toIso8601String(), 
             original.achievedDate?.toIso8601String());
    });
  });

  group('AgingCurve Tests', () {
    test('should create standard aging curve correctly', () {
      final curve = AgingCurve.standard();
      
      expect(curve.peakAge, 27);
      expect(curve.declineStartAge, 30);
      expect(curve.peakMultiplier, 1.2);
      expect(curve.declineRate, 0.02);
      expect(curve.retirementAge, 38);
    });

    test('should create age-specific curves correctly', () {
      final youngCurve = AgingCurve.forAge(20);
      final oldCurve = AgingCurve.forAge(32);
      
      expect(youngCurve.peakAge, 28);
      expect(youngCurve.retirementAge, 40);
      
      expect(oldCurve.peakAge, 25);
      expect(oldCurve.retirementAge, 35);
    });

    test('should calculate age modifiers correctly', () {
      final curve = AgingCurve.standard();
      
      final youngModifier = curve.getAgeModifier(22);
      final peakModifier = curve.getAgeModifier(27);
      final declineModifier = curve.getAgeModifier(35);
      final oldModifier = curve.getAgeModifier(40);
      
      expect(youngModifier, greaterThan(1.0));
      expect(peakModifier, curve.peakMultiplier);
      expect(declineModifier, lessThan(peakModifier));
      expect(oldModifier, 0.1);
    });

    test('should calculate skill degradation correctly', () {
      final curve = AgingCurve.standard();
      
      final noDegradation = curve.getSkillDegradationRate(25);
      final someDegradation = curve.getSkillDegradationRate(35);
      final highDegradation = curve.getSkillDegradationRate(40);
      
      expect(noDegradation, 0.0);
      expect(someDegradation, greaterThan(0.0));
      expect(someDegradation, lessThan(0.15));
      expect(highDegradation, 0.15);
    });

    test('should determine retirement correctly', () {
      final curve = AgingCurve.standard();
      
      expect(curve.shouldConsiderRetirement(25, 80), false);
      expect(curve.shouldConsiderRetirement(38, 80), true);
      expect(curve.shouldConsiderRetirement(35, 45), true);
      expect(curve.shouldConsiderRetirement(35, 70), false);
    });

    test('should serialize and deserialize correctly', () {
      final original = AgingCurve.forAge(25);
      
      final map = original.toMap();
      final restored = AgingCurve.fromMap(map);
      
      expect(restored.peakAge, original.peakAge);
      expect(restored.declineStartAge, original.declineStartAge);
      expect(restored.peakMultiplier, original.peakMultiplier);
      expect(restored.declineRate, original.declineRate);
      expect(restored.retirementAge, original.retirementAge);
    });
  });
}