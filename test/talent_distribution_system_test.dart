import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/talent_distribution_system.dart';
import 'package:BasketballManager/gameData/player_generator.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/gameData/development_system.dart';

void main() {
  group('TalentDistributionSystem Tests', () {
    test('generateTalentTier follows realistic distribution', () {
      Map<TalentTier, int> distribution = {};
      int sampleSize = 1000;
      
      // Generate large sample to test distribution
      for (int i = 0; i < sampleSize; i++) {
        TalentTier tier = TalentDistributionSystem.generateTalentTier();
        distribution[tier] = (distribution[tier] ?? 0) + 1;
      }
      
      // Check that superstars are rare (less than 5%)
      double superstarPercentage = (distribution[TalentTier.superstar] ?? 0) / sampleSize;
      expect(superstarPercentage, lessThan(0.05));
      
      // Check that bench players are common (more than 20%)
      double benchPercentage = (distribution[TalentTier.bench] ?? 0) / sampleSize;
      expect(benchPercentage, greaterThan(0.20));
      
      // Check that all tiers are represented
      expect(distribution.keys.length, greaterThanOrEqualTo(4));
    });

    test('rookie talent distribution differs from standard distribution', () {
      Map<TalentTier, int> standardDist = {};
      Map<TalentTier, int> rookieDist = {};
      int sampleSize = 500;
      
      // Generate samples for both distributions
      for (int i = 0; i < sampleSize; i++) {
        TalentTier standard = TalentDistributionSystem.generateTalentTier(isRookie: false);
        TalentTier rookie = TalentDistributionSystem.generateTalentTier(isRookie: true);
        
        standardDist[standard] = (standardDist[standard] ?? 0) + 1;
        rookieDist[rookie] = (rookieDist[rookie] ?? 0) + 1;
      }
      
      // Rookies should have higher chance of superstar/allStar
      double rookieSuperstar = (rookieDist[TalentTier.superstar] ?? 0) / sampleSize;
      double standardSuperstar = (standardDist[TalentTier.superstar] ?? 0) / sampleSize;
      
      expect(rookieSuperstar, greaterThanOrEqualTo(standardSuperstar));
      
      // Rookies should have lower chance of bench players
      double rookieBench = (rookieDist[TalentTier.bench] ?? 0) / sampleSize;
      double standardBench = (standardDist[TalentTier.bench] ?? 0) / sampleSize;
      
      expect(rookieBench, lessThanOrEqualTo(standardBench));
    });

    test('generatePotentialTier correlates with talent tier', () {
      // Superstar talent should have high potential
      PotentialTier superstarPotential = TalentDistributionSystem.generatePotentialTier(
        TalentTier.superstar, 
        22,
      );
      
      // Bench talent should have lower potential
      PotentialTier benchPotential = TalentDistributionSystem.generatePotentialTier(
        TalentTier.bench, 
        22,
      );
      
      // Test multiple generations to check correlation
      int superstarHighPotential = 0;
      int benchLowPotential = 0;
      
      for (int i = 0; i < 50; i++) {
        PotentialTier sp = TalentDistributionSystem.generatePotentialTier(
          TalentTier.superstar, 22
        );
        PotentialTier bp = TalentDistributionSystem.generatePotentialTier(
          TalentTier.bench, 22
        );
        
        if ([PotentialTier.elite, PotentialTier.gold].contains(sp)) {
          superstarHighPotential++;
        }
        if (bp == PotentialTier.bronze) {
          benchLowPotential++;
        }
      }
      
      // At least 50% of superstars should have high potential
      expect(superstarHighPotential / 50, greaterThan(0.5));
      
      // At least 50% of bench players should have bronze potential
      expect(benchLowPotential / 50, greaterThan(0.5));
    });

    test('rookie potential system includes hidden variance', () {
      PotentialTier rookiePotential = TalentDistributionSystem.generatePotentialTier(
        TalentTier.starter, 
        20, 
        isRookie: true,
      );
      
      PotentialTier veteranPotential = TalentDistributionSystem.generatePotentialTier(
        TalentTier.starter, 
        28, 
        isRookie: false,
      );
      
      // Test that rookies can get potential boosts
      int rookieBoosts = 0;
      for (int i = 0; i < 100; i++) {
        PotentialTier rp = TalentDistributionSystem.generatePotentialTier(
          TalentTier.rotation, 20, isRookie: true
        );
        if ([PotentialTier.gold, PotentialTier.elite].contains(rp)) {
          rookieBoosts++;
        }
      }
      
      // Rookies should get some potential boosts
      expect(rookieBoosts, greaterThan(5));
    });

    test('generateRareArchetype respects position constraints', () {
      // Point guards should be able to get playmaker archetype
      PlayerArchetype? pgArchetype = TalentDistributionSystem.generateRareArchetype(
        PlayerRole.pointGuard
      );
      
      // Centers should be able to get stretch big archetype
      PlayerArchetype? centerArchetype = TalentDistributionSystem.generateRareArchetype(
        PlayerRole.center
      );
      
      // Test multiple generations to see if appropriate archetypes appear
      Set<PlayerArchetype> pgArchetypes = {};
      Set<PlayerArchetype> centerArchetypes = {};
      
      for (int i = 0; i < 200; i++) {
        PlayerArchetype? pga = TalentDistributionSystem.generateRareArchetype(
          PlayerRole.pointGuard
        );
        PlayerArchetype? ca = TalentDistributionSystem.generateRareArchetype(
          PlayerRole.center
        );
        
        if (pga != null) pgArchetypes.add(pga);
        if (ca != null) centerArchetypes.add(ca);
      }
      
      // Point guards should be able to get playmaker
      expect(pgArchetypes.contains(PlayerArchetype.playmaker) || 
             pgArchetypes.contains(PlayerArchetype.floorGeneral), isTrue);
      
      // Centers should be able to get stretch big or athletic finisher
      expect(centerArchetypes.contains(PlayerArchetype.stretchBig) || 
             centerArchetypes.contains(PlayerArchetype.athleticFinisher), isTrue);
    });

    test('generatePositionAttributeRanges creates appropriate specializations', () {
      // Point guard should have high passing/ball handling ranges
      Map<String, AttributeRange> pgRanges = TalentDistributionSystem
          .generatePositionAttributeRanges(PlayerRole.pointGuard, TalentTier.starter);
      
      // Center should have high rebounding/post defense ranges
      Map<String, AttributeRange> centerRanges = TalentDistributionSystem
          .generatePositionAttributeRanges(PlayerRole.center, TalentTier.starter);
      
      // Point guard should have higher passing average than center
      expect(pgRanges['passing']!.average, 
             greaterThan(centerRanges['passing']!.average));
      
      // Center should have higher rebounding average than point guard
      expect(centerRanges['rebounding']!.average, 
             greaterThan(pgRanges['rebounding']!.average));
      
      // All ranges should be within valid bounds
      for (AttributeRange range in pgRanges.values) {
        expect(range.min, inInclusiveRange(30, 95));
        expect(range.max, inInclusiveRange(50, 99));
        expect(range.average, inInclusiveRange(40, 95));
        expect(range.min, lessThanOrEqualTo(range.average));
        expect(range.average, lessThanOrEqualTo(range.max));
      }
    });

    test('generateRookiePotential creates comprehensive profile', () {
      RookiePotentialProfile profile = TalentDistributionSystem.generateRookiePotential(
        PlayerRole.shootingGuard,
        TalentTier.allStar,
      );
      
      // Profile should have all required fields
      expect(profile.potentialTier, isA<PotentialTier>());
      expect(profile.hiddenVariance, inInclusiveRange(-0.15, 0.15));
      expect(profile.developmentRate, inInclusiveRange(0.8, 1.4));
      expect(profile.ceilingProjection, inInclusiveRange(70, 99));
      expect(profile.floorProjection, inInclusiveRange(45, 85));
      expect(profile.bustProbability, inInclusiveRange(0.0, 1.0));
      expect(profile.boomProbability, inInclusiveRange(0.0, 1.0));
      expect(profile.isHidden, isTrue);
      
      // Ceiling should be higher than floor
      expect(profile.ceilingProjection, greaterThan(profile.floorProjection));
      
      // Can convert to PlayerPotential
      expect(profile.toPlayerPotential(), isA<PlayerPotential>());
    });

    test('generateDraftClassDistribution creates realistic draft', () {
      List<TalentTier> draftClass = TalentDistributionSystem.generateDraftClassDistribution(60);
      
      expect(draftClass.length, equals(60));
      
      // Count distribution
      Map<TalentTier, int> distribution = {};
      for (TalentTier tier in draftClass) {
        distribution[tier] = (distribution[tier] ?? 0) + 1;
      }
      
      // Early picks should have better talent on average
      List<TalentTier> earlyPicks = draftClass.take(10).toList();
      List<TalentTier> latePicks = draftClass.skip(50).take(10).toList();
      
      int earlyHighTalent = earlyPicks.where((t) => 
        [TalentTier.superstar, TalentTier.allStar].contains(t)
      ).length;
      
      int lateHighTalent = latePicks.where((t) => 
        [TalentTier.superstar, TalentTier.allStar].contains(t)
      ).length;
      
      // Early picks should generally have more high talent
      expect(earlyHighTalent, greaterThanOrEqualTo(lateHighTalent));
      
      // Should have variety in talent levels
      expect(distribution.keys.length, greaterThanOrEqualTo(3));
    });

    test('talent distribution maintains consistency across multiple generations', () {
      // Generate multiple samples and check consistency
      List<Map<TalentTier, int>> samples = [];
      
      for (int sample = 0; sample < 5; sample++) {
        Map<TalentTier, int> distribution = {};
        
        for (int i = 0; i < 200; i++) {
          TalentTier tier = TalentDistributionSystem.generateTalentTier();
          distribution[tier] = (distribution[tier] ?? 0) + 1;
        }
        
        samples.add(distribution);
      }
      
      // Check that superstar percentage is consistently low across samples
      for (Map<TalentTier, int> sample in samples) {
        double superstarPercentage = (sample[TalentTier.superstar] ?? 0) / 200;
        expect(superstarPercentage, lessThan(0.08)); // Should be less than 8%
      }
      
      // Check that bench percentage is consistently high across samples
      for (Map<TalentTier, int> sample in samples) {
        double benchPercentage = (sample[TalentTier.bench] ?? 0) / 200;
        expect(benchPercentage, greaterThan(0.15)); // Should be more than 15%
      }
    });

    test('position specializations create meaningful differences', () {
      // Generate attribute ranges for all positions
      Map<PlayerRole, Map<String, AttributeRange>> allRanges = {};
      
      for (PlayerRole role in PlayerRole.values) {
        allRanges[role] = TalentDistributionSystem.generatePositionAttributeRanges(
          role, TalentTier.starter
        );
      }
      
      // Point guards should have higher passing than centers (most different positions)
      int pgPassingAvg = allRanges[PlayerRole.pointGuard]!['passing']!.average;
      int centerPassingAvg = allRanges[PlayerRole.center]!['passing']!.average;
      
      expect(pgPassingAvg, greaterThan(centerPassingAvg));
      
      // Centers should have higher rebounding than point guards
      int centerReboundingAvg = allRanges[PlayerRole.center]!['rebounding']!.average;
      int pgReboundingAvg = allRanges[PlayerRole.pointGuard]!['rebounding']!.average;
      
      expect(centerReboundingAvg, greaterThan(pgReboundingAvg));
    });
  });

  group('TalentDistributionSystem Integration Tests', () {
    test('integrates with PlayerGenerator for enhanced generation', () {
      // Test that the talent distribution system can be used with PlayerGenerator
      TalentTier tier = TalentDistributionSystem.generateTalentTier();
      PotentialTier potential = TalentDistributionSystem.generatePotentialTier(tier, 22);
      PlayerArchetype? archetype = TalentDistributionSystem.generateRareArchetype(
        PlayerRole.shootingGuard
      );
      
      // These should all be valid values that can be used in player generation
      expect(tier, isA<TalentTier>());
      expect(potential, isA<PotentialTier>());
      // archetype can be null, which is valid
    });

    test('rookie potential profiles work with development system', () {
      RookiePotentialProfile profile = TalentDistributionSystem.generateRookiePotential(
        PlayerRole.pointGuard,
        TalentTier.starter,
      );
      
      // Should be able to convert to PlayerPotential
      PlayerPotential potential = profile.toPlayerPotential();
      expect(potential, isA<PlayerPotential>());
      expect(potential.isHidden, isTrue);
      
      // Should have reasonable values for development
      expect(profile.developmentRate, greaterThan(0.5));
      expect(profile.developmentRate, lessThan(2.0));
    });
  });
}