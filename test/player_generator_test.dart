import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/player_generator.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/gameData/development_system.dart';

void main() {
  group('PlayerGenerator Tests', () {
    test('generateRealisticPlayer creates valid player with all required attributes', () {
      final player = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'USA',
      );

      expect(player, isA<EnhancedPlayer>());
      expect(player.primaryRole, equals(PlayerRole.pointGuard));
      expect(player.age, equals(25));
      expect(player.nationality, equals('USA'));
      expect(player.name, isNotEmpty);
      expect(player.height, greaterThan(0));
      
      // Check all skill attributes are within valid range
      expect(player.shooting, inInclusiveRange(45, 99));
      expect(player.rebounding, inInclusiveRange(45, 99));
      expect(player.passing, inInclusiveRange(45, 99));
      expect(player.ballHandling, inInclusiveRange(45, 99));
      expect(player.perimeterDefense, inInclusiveRange(45, 99));
      expect(player.postDefense, inInclusiveRange(45, 99));
      expect(player.insideShooting, inInclusiveRange(45, 99));
      
      // Check development system is initialized
      expect(player.potential, isA<PlayerPotential>());
      expect(player.development, isA<DevelopmentTracker>());
    });

    test('generateRealisticPlayer respects role-based attribute distributions', () {
      // Generate point guard - should have high passing and ball handling
      final pointGuard = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        talentTier: TalentTier.allStar,
      );

      // Generate center - should have high rebounding and inside shooting
      final center = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.center,
        age: 25,
        talentTier: TalentTier.allStar,
      );

      // Point guards should generally have better ball handling than centers
      // (This is probabilistic, so we'll test with multiple generations)
      int pgBetterBallHandling = 0;
      int centerBetterRebounding = 0;
      
      for (int i = 0; i < 10; i++) {
        final pg = PlayerGenerator.generateRealisticPlayer(
          primaryRole: PlayerRole.pointGuard,
          age: 25,
          talentTier: TalentTier.starter,
        );
        final c = PlayerGenerator.generateRealisticPlayer(
          primaryRole: PlayerRole.center,
          age: 25,
          talentTier: TalentTier.starter,
        );
        
        if (pg.ballHandling > c.ballHandling) pgBetterBallHandling++;
        if (c.rebounding > pg.rebounding) centerBetterRebounding++;
      }
      
      // At least 60% should follow expected patterns
      expect(pgBetterBallHandling, greaterThanOrEqualTo(6));
      expect(centerBetterRebounding, greaterThanOrEqualTo(6));
    });

    test('generateRealisticPlayer creates appropriate height ranges by position', () {
      // Test height ranges for different positions
      final pointGuard = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
      );
      
      final center = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.center,
        age: 25,
      );

      // Point guards should be shorter than centers
      expect(pointGuard.height, inInclusiveRange(175, 195));
      expect(center.height, inInclusiveRange(205, 225));
      
      // Generate multiple to test distribution
      List<int> pgHeights = [];
      List<int> centerHeights = [];
      
      for (int i = 0; i < 20; i++) {
        pgHeights.add(PlayerGenerator.generateRealisticPlayer(
          primaryRole: PlayerRole.pointGuard,
          age: 25,
        ).height);
        
        centerHeights.add(PlayerGenerator.generateRealisticPlayer(
          primaryRole: PlayerRole.center,
          age: 25,
        ).height);
      }
      
      // Average center should be taller than average point guard
      double avgPgHeight = pgHeights.reduce((a, b) => a + b) / pgHeights.length;
      double avgCenterHeight = centerHeights.reduce((a, b) => a + b) / centerHeights.length;
      
      expect(avgCenterHeight, greaterThan(avgPgHeight));
    });

    test('generateDraftProspect creates young players with appropriate ages', () {
      final prospect = PlayerGenerator.generateDraftProspect(
        primaryRole: PlayerRole.shootingGuard,
        nationality: 'USA',
      );

      expect(prospect.age, inInclusiveRange(18, 22));
      expect(prospect.team, equals('Draft Prospect'));
      expect(prospect.experienceYears, inInclusiveRange(0, 2));
      expect(prospect.potential.isHidden, isTrue);
    });

    test('generateArchetypePlayer applies correct specializations', () {
      final eliteShooter = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.shootingGuard,
        archetype: PlayerArchetype.eliteShooter,
        age: 25,
      );

      final defensiveSpecialist = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.smallForward,
        archetype: PlayerArchetype.defensiveSpecialist,
        age: 25,
      );

      // Elite shooter should have high shooting, lower inside shooting
      expect(eliteShooter.shooting, greaterThan(70));
      
      // Defensive specialist should have high defensive stats
      expect(defensiveSpecialist.perimeterDefense, greaterThan(65));
      expect(defensiveSpecialist.postDefense, greaterThan(60));
    });

    test('generatePlayerPool creates correct number and distribution of players', () {
      final players = PlayerGenerator.generatePlayerPool(
        count: 50,
        averageAge: 26,
      );

      expect(players.length, equals(50));
      
      // Check role distribution
      Map<PlayerRole, int> roleCounts = {};
      for (var player in players) {
        roleCounts[player.primaryRole] = (roleCounts[player.primaryRole] ?? 0) + 1;
      }
      
      // Should have players in all positions
      expect(roleCounts.keys.length, greaterThanOrEqualTo(4));
      
      // Check age distribution around average
      double avgAge = players.map((p) => p.age).reduce((a, b) => a + b) / players.length;
      expect(avgAge, closeTo(26, 5)); // Within 5 years of target
    });

    test('talent tier distribution follows realistic patterns', () {
      // Generate many players and check talent distribution
      List<TalentTier> talents = [];
      
      for (int i = 0; i < 1000; i++) {
        final player = PlayerGenerator.generateRealisticPlayer(
          primaryRole: PlayerRole.values[i % PlayerRole.values.length],
          age: 20 + (i % 15),
        );
        
        // Infer talent tier from overall attributes
        double overall = (player.shooting + player.rebounding + player.passing + 
                         player.ballHandling + player.perimeterDefense + 
                         player.postDefense + player.insideShooting) / 7.0;
        
        if (overall >= 90) {
          talents.add(TalentTier.superstar);
        } else if (overall >= 80) {
          talents.add(TalentTier.allStar);
        } else if (overall >= 70) {
          talents.add(TalentTier.starter);
        } else if (overall >= 60) {
          talents.add(TalentTier.rotation);
        } else {
          talents.add(TalentTier.bench);
        }
      }
      
      // Count distribution
      Map<TalentTier, int> distribution = {};
      for (var tier in talents) {
        distribution[tier] = (distribution[tier] ?? 0) + 1;
      }
      
      // Superstars should be rare (less than 5%)
      expect((distribution[TalentTier.superstar] ?? 0) / talents.length, lessThan(0.05));
      
      // Bench players should be common (more than 20%)
      expect((distribution[TalentTier.bench] ?? 0) / talents.length, greaterThan(0.20));
    });

    test('age affects attribute generation appropriately', () {
      // Young player should have lower current attributes
      final youngPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 20,
        talentTier: TalentTier.starter,
      );

      // Prime player should have higher current attributes
      final primePlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 27,
        talentTier: TalentTier.starter,
      );

      // Old player should have lower current attributes
      final oldPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 35,
        talentTier: TalentTier.starter,
      );

      // Calculate overall ratings
      double youngOverall = (youngPlayer.shooting + youngPlayer.rebounding + 
                           youngPlayer.passing + youngPlayer.ballHandling + 
                           youngPlayer.perimeterDefense + youngPlayer.postDefense + 
                           youngPlayer.insideShooting) / 7.0;
      
      double primeOverall = (primePlayer.shooting + primePlayer.rebounding + 
                           primePlayer.passing + primePlayer.ballHandling + 
                           primePlayer.perimeterDefense + primePlayer.postDefense + 
                           primePlayer.insideShooting) / 7.0;
      
      double oldOverall = (oldPlayer.shooting + oldPlayer.rebounding + 
                         oldPlayer.passing + oldPlayer.ballHandling + 
                         oldPlayer.perimeterDefense + oldPlayer.postDefense + 
                         oldPlayer.insideShooting) / 7.0;

      // Prime player should generally have highest current attributes
      expect(primeOverall, greaterThanOrEqualTo(youngOverall - 5)); // Allow some variance
      expect(primeOverall, greaterThanOrEqualTo(oldOverall - 5));
    });

    test('nationality affects name generation correctly', () {
      final usaPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'USA',
      );

      final frenchPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'France',
      );

      final serbianPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'Serbia',
      );

      // Names should be different and appropriate for nationality
      expect(usaPlayer.name, isNotEmpty);
      expect(frenchPlayer.name, isNotEmpty);
      expect(serbianPlayer.name, isNotEmpty);
      
      // Names should contain spaces (first and last name)
      expect(usaPlayer.name.contains(' '), isTrue);
      expect(frenchPlayer.name.contains(' '), isTrue);
      expect(serbianPlayer.name.contains(' '), isTrue);
    });

    test('unique name generation avoids duplicates', () {
      Set<String> usedNames = {'John Smith', 'Michael Jordan', 'LeBron James'};
      
      final player1 = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'USA',
        usedNames: usedNames,
      );

      final player2 = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 25,
        nationality: 'USA',
        usedNames: usedNames,
      );

      // Names should not be in the used names set
      expect(usedNames.contains(player1.name), isFalse);
      expect(usedNames.contains(player2.name), isFalse);
      
      // Names should be different from each other
      expect(player1.name, isNot(equals(player2.name)));
    });

    test('potential tier correlates with talent tier appropriately', () {
      // Generate superstar talent - should have high potential
      final superstar = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 22,
        talentTier: TalentTier.superstar,
      );

      // Generate bench talent - should have lower potential
      final benchPlayer = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 22,
        talentTier: TalentTier.bench,
      );

      // Superstar should have higher potential overall
      expect(superstar.potential.overallPotential, 
             greaterThan(benchPlayer.potential.overallPotential));
      
      // Superstar more likely to have elite/gold potential
      expect([PotentialTier.elite, PotentialTier.gold].contains(superstar.potential.tier), 
             isTrue);
    });

    test('experience years correlate with age realistically', () {
      final rookie = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 19,
      );

      final veteran = PlayerGenerator.generateRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 35,
      );

      // Rookie should have low experience
      expect(rookie.experienceYears, lessThanOrEqualTo(2));
      
      // Veteran should have high experience
      expect(veteran.experienceYears, greaterThanOrEqualTo(8));
    });
  });

  group('PlayerGenerator Archetype Tests', () {
    test('elite shooter archetype has enhanced shooting attributes', () {
      final shooter = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.shootingGuard,
        archetype: PlayerArchetype.eliteShooter,
        age: 25,
      );

      // Should have high shooting, lower inside game
      expect(shooter.shooting, greaterThan(75));
      expect(shooter.shooting, greaterThan(shooter.insideShooting));
    });

    test('defensive specialist has enhanced defensive attributes', () {
      final defender = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.smallForward,
        archetype: PlayerArchetype.defensiveSpecialist,
        age: 25,
      );

      // Should have high defensive stats
      expect(defender.perimeterDefense, greaterThan(75));
      expect(defender.postDefense, greaterThan(70));
    });

    test('playmaker has enhanced passing and ball handling', () {
      final playmaker = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.pointGuard,
        archetype: PlayerArchetype.playmaker,
        age: 25,
      );

      // Should excel at passing and ball handling
      expect(playmaker.passing, greaterThan(75));
      expect(playmaker.ballHandling, greaterThan(75));
    });

    test('athletic finisher excels at inside game and rebounding', () {
      final finisher = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.powerForward,
        archetype: PlayerArchetype.athleticFinisher,
        age: 25,
      );

      // Should have high inside shooting and rebounding
      expect(finisher.insideShooting, greaterThan(70));
      expect(finisher.rebounding, greaterThan(65));
    });

    test('stretch big combines size with shooting ability', () {
      final stretchBig = PlayerGenerator.generateArchetypePlayer(
        primaryRole: PlayerRole.center,
        archetype: PlayerArchetype.stretchBig,
        age: 25,
      );

      // Should have good shooting for a big man
      expect(stretchBig.shooting, greaterThan(70));
      expect(stretchBig.rebounding, greaterThan(65));
      // Should be tall like a center
      expect(stretchBig.height, greaterThan(205));
    });
  });

  group('Enhanced PlayerGenerator Tests', () {
    test('generateEnhancedRealisticPlayer uses talent distribution system', () {
      final player = PlayerGenerator.generateEnhancedRealisticPlayer(
        primaryRole: PlayerRole.pointGuard,
        age: 22,
        nationality: 'USA',
        isRookie: true,
      );

      expect(player, isA<EnhancedPlayer>());
      expect(player.primaryRole, equals(PlayerRole.pointGuard));
      expect(player.age, equals(22));
      expect(player.nationality, equals('USA'));
      
      // Should have valid attributes and potential
      expect(player.potential, isA<PlayerPotential>());
      expect(player.development, isA<DevelopmentTracker>());
    });

    test('generateDraftClass creates realistic draft with talent distribution', () {
      final draftClass = PlayerGenerator.generateDraftClass(
        draftSize: 30,
      );

      expect(draftClass.length, equals(30));
      
      // All should be young prospects
      for (var prospect in draftClass) {
        expect(prospect.age, inInclusiveRange(18, 21));
        expect(prospect.team, equals('Draft Prospect'));
      }
      
      // Should have variety in positions
      Set<PlayerRole> positions = draftClass.map((p) => p.primaryRole).toSet();
      expect(positions.length, greaterThanOrEqualTo(3));
      
      // Early picks should generally have better talent
      // (This is probabilistic, so we'll check the first few vs last few)
      List<double> earlyOveralls = [];
      List<double> lateOveralls = [];
      
      for (int i = 0; i < 5; i++) {
        var early = draftClass[i];
        var late = draftClass[draftClass.length - 1 - i];
        
        double earlyOverall = (early.shooting + early.rebounding + early.passing + 
                              early.ballHandling + early.perimeterDefense + 
                              early.postDefense + early.insideShooting) / 7.0;
        
        double lateOverall = (late.shooting + late.rebounding + late.passing + 
                             late.ballHandling + late.perimeterDefense + 
                             late.postDefense + late.insideShooting) / 7.0;
        
        earlyOveralls.add(earlyOverall);
        lateOveralls.add(lateOverall);
      }
      
      double avgEarly = earlyOveralls.reduce((a, b) => a + b) / earlyOveralls.length;
      double avgLate = lateOveralls.reduce((a, b) => a + b) / lateOveralls.length;
      
      // Early picks should generally be better (allow some variance)
      expect(avgEarly, greaterThanOrEqualTo(avgLate - 5));
    });

    test('generateDraftClass respects position weights', () {
      final draftClass = PlayerGenerator.generateDraftClass(
        draftSize: 20,
        positionWeights: {
          PlayerRole.pointGuard: 0.5,  // 50% point guards
          PlayerRole.shootingGuard: 0.3,  // 30% shooting guards
          PlayerRole.smallForward: 0.2,   // 20% small forwards
          PlayerRole.powerForward: 0.0,   // No power forwards
          PlayerRole.center: 0.0,         // No centers
        },
      );

      // Count positions
      Map<PlayerRole, int> positionCounts = {};
      for (var player in draftClass) {
        positionCounts[player.primaryRole] = (positionCounts[player.primaryRole] ?? 0) + 1;
      }

      // Should have no power forwards or centers
      expect(positionCounts[PlayerRole.powerForward] ?? 0, equals(0));
      expect(positionCounts[PlayerRole.center] ?? 0, equals(0));
      
      // Should have mostly point guards
      expect((positionCounts[PlayerRole.pointGuard] ?? 0) / draftClass.length, 
             greaterThan(0.3)); // At least 30% due to randomness
    });

    test('enhanced generation can produce rare archetypes', () {
      Set<PlayerArchetype?> foundArchetypes = {};
      
      // Generate many players to find rare archetypes
      for (int i = 0; i < 100; i++) {
        final player = PlayerGenerator.generateEnhancedRealisticPlayer(
          primaryRole: PlayerRole.shootingGuard,
          age: 25,
        );
        
        // Check if this player has archetype characteristics
        if (player.shooting > 85) {
          foundArchetypes.add(PlayerArchetype.eliteShooter);
        }
        if (player.perimeterDefense > 85) {
          foundArchetypes.add(PlayerArchetype.defensiveSpecialist);
        }
      }
      
      // Should find at least some specialized players
      expect(foundArchetypes.isNotEmpty, isTrue);
    });

    test('rookie generation has different characteristics than veteran generation', () {
      List<double> rookieOveralls = [];
      List<double> veteranOveralls = [];
      
      for (int i = 0; i < 20; i++) {
        final rookie = PlayerGenerator.generateEnhancedRealisticPlayer(
          primaryRole: PlayerRole.pointGuard,
          age: 20,
          isRookie: true,
        );
        
        final veteran = PlayerGenerator.generateEnhancedRealisticPlayer(
          primaryRole: PlayerRole.pointGuard,
          age: 30,
          isRookie: false,
        );
        
        double rookieOverall = (rookie.shooting + rookie.rebounding + rookie.passing + 
                               rookie.ballHandling + rookie.perimeterDefense + 
                               rookie.postDefense + rookie.insideShooting) / 7.0;
        
        double veteranOverall = (veteran.shooting + veteran.rebounding + veteran.passing + 
                                veteran.ballHandling + veteran.perimeterDefense + 
                                veteran.postDefense + veteran.insideShooting) / 7.0;
        
        rookieOveralls.add(rookieOverall);
        veteranOveralls.add(veteranOverall);
      }
      
      // Veterans should generally have higher current attributes
      double avgRookie = rookieOveralls.reduce((a, b) => a + b) / rookieOveralls.length;
      double avgVeteran = veteranOveralls.reduce((a, b) => a + b) / veteranOveralls.length;
      
      expect(avgVeteran, greaterThanOrEqualTo(avgRookie - 3)); // Allow some variance
    });

    test('draft class maintains name uniqueness', () {
      final draftClass = PlayerGenerator.generateDraftClass(
        draftSize: 50,
      );

      Set<String> names = draftClass.map((p) => p.name).toSet();
      
      // All names should be unique
      expect(names.length, equals(draftClass.length));
    });

    test('enhanced generation integrates with existing systems', () {
      final player = PlayerGenerator.generateEnhancedRealisticPlayer(
        primaryRole: PlayerRole.center,
        age: 24,
        nationality: 'Serbia',
      );

      // Should work with role system
      expect(player.calculateRoleCompatibility(PlayerRole.center), greaterThan(0.5));
      
      // Should work with development system
      expect(player.development.canUpgradeSkill('rebounding', player.potential, player.rebounding), 
             isA<bool>());
      
      // Should have proper serialization
      Map<String, dynamic> playerMap = player.toMap();
      expect(playerMap, isA<Map<String, dynamic>>());
      expect(playerMap['name'], equals(player.name));
    });
  });
}