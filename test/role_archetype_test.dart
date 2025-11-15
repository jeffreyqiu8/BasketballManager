import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/models/player.dart';
import 'package:BasketballManager/utils/role_archetype_registry.dart';

void main() {
  group('RoleArchetype', () {
    test('calculateFitScore returns value between 0 and 100', () {
      final player = Player(
        id: 'test1',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
      );

      final archetype = RoleArchetypeRegistry.getArchetypeById('pg_floor_general');
      expect(archetype, isNotNull);

      final fitScore = archetype!.calculateFitScore(player);
      expect(fitScore, greaterThanOrEqualTo(0.0));
      expect(fitScore, lessThanOrEqualTo(100.0));
    });

    test('calculateFitScore weights attributes correctly', () {
      // Create a player with high passing and ball handling (Floor General attributes)
      final floorGeneralPlayer = Player(
        id: 'test2',
        name: 'Floor General Player',
        heightInches: 74,
        shooting: 50,
        defense: 60,
        speed: 70,
        postShooting: 50,
        passing: 95, // High passing
        rebounding: 40,
        ballHandling: 90, // High ball handling
        threePoint: 60,
        blocks: 30,
        steals: 65,
        position: 'PG',
      );

      // Create a player with high shooting (Offensive Point attributes)
      final offensivePointPlayer = Player(
        id: 'test3',
        name: 'Offensive Point Player',
        heightInches: 74,
        shooting: 95, // High shooting
        defense: 60,
        speed: 70,
        postShooting: 50,
        passing: 60,
        rebounding: 40,
        ballHandling: 70,
        threePoint: 90, // High three-point
        blocks: 30,
        steals: 65,
        position: 'PG',
      );

      final floorGeneral = RoleArchetypeRegistry.getArchetypeById('pg_floor_general')!;
      final offensivePoint = RoleArchetypeRegistry.getArchetypeById('pg_offensive_point')!;

      // Floor General player should fit Floor General role better
      final floorGeneralFitForFloorGeneral = floorGeneral.calculateFitScore(floorGeneralPlayer);
      final offensivePointFitForFloorGeneral = floorGeneral.calculateFitScore(offensivePointPlayer);
      expect(floorGeneralFitForFloorGeneral, greaterThan(offensivePointFitForFloorGeneral));

      // Offensive Point player should fit Offensive Point role better
      final floorGeneralFitForOffensivePoint = offensivePoint.calculateFitScore(floorGeneralPlayer);
      final offensivePointFitForOffensivePoint = offensivePoint.calculateFitScore(offensivePointPlayer);
      expect(offensivePointFitForOffensivePoint, greaterThan(floorGeneralFitForOffensivePoint));
    });
  });

  group('RoleArchetypeRegistry', () {
    test('getArchetypesForPosition returns correct number of archetypes', () {
      expect(RoleArchetypeRegistry.getArchetypesForPosition('PG').length, equals(4));
      expect(RoleArchetypeRegistry.getArchetypesForPosition('SG').length, equals(3));
      expect(RoleArchetypeRegistry.getArchetypesForPosition('SF').length, equals(3));
      expect(RoleArchetypeRegistry.getArchetypesForPosition('PF').length, equals(3));
      expect(RoleArchetypeRegistry.getArchetypesForPosition('C').length, equals(3));
    });

    test('getArchetypesForPosition returns empty list for invalid position', () {
      expect(RoleArchetypeRegistry.getArchetypesForPosition('INVALID'), isEmpty);
    });

    test('getArchetypeById returns correct archetype', () {
      final archetype = RoleArchetypeRegistry.getArchetypeById('pg_floor_general');
      expect(archetype, isNotNull);
      expect(archetype!.name, equals('Floor General'));
      expect(archetype.position, equals('PG'));
    });

    test('getArchetypeById returns null for invalid id', () {
      final archetype = RoleArchetypeRegistry.getArchetypeById('invalid_id');
      expect(archetype, isNull);
    });

    test('all Point Guard archetypes are defined', () {
      final pgArchetypes = RoleArchetypeRegistry.getArchetypesForPosition('PG');
      final names = pgArchetypes.map((a) => a.name).toList();
      
      expect(names, contains('All-Around PG'));
      expect(names, contains('Floor General'));
      expect(names, contains('Slashing Playmaker'));
      expect(names, contains('Offensive Point'));
    });

    test('all Shooting Guard archetypes are defined', () {
      final sgArchetypes = RoleArchetypeRegistry.getArchetypesForPosition('SG');
      final names = sgArchetypes.map((a) => a.name).toList();
      
      expect(names, contains('Three-Level Scorer'));
      expect(names, contains('3-and-D'));
      expect(names, contains('Microwave Shooter'));
    });

    test('all Small Forward archetypes are defined', () {
      final sfArchetypes = RoleArchetypeRegistry.getArchetypesForPosition('SF');
      final names = sfArchetypes.map((a) => a.name).toList();
      
      expect(names, contains('Point Forward'));
      expect(names, contains('3-and-D Wing'));
      expect(names, contains('Athletic Finisher'));
    });

    test('all Power Forward archetypes are defined', () {
      final pfArchetypes = RoleArchetypeRegistry.getArchetypesForPosition('PF');
      final names = pfArchetypes.map((a) => a.name).toList();
      
      expect(names, contains('Playmaking Big'));
      expect(names, contains('Stretch Four'));
      expect(names, contains('Rim Runner'));
    });

    test('all Center archetypes are defined', () {
      final cArchetypes = RoleArchetypeRegistry.getArchetypesForPosition('C');
      final names = cArchetypes.map((a) => a.name).toList();
      
      expect(names, contains('Paint Beast'));
      expect(names, contains('Stretch Five'));
      expect(names, contains('Standard Center'));
    });

    test('getAllArchetypes returns all 16 archetypes', () {
      final allArchetypes = RoleArchetypeRegistry.getAllArchetypes();
      expect(allArchetypes.length, equals(16)); // 4 PG + 3 SG + 3 SF + 3 PF + 3 C
    });

    test('getAllPositions returns all 5 positions', () {
      final positions = RoleArchetypeRegistry.getAllPositions();
      expect(positions.length, equals(5));
      expect(positions, containsAll(['PG', 'SG', 'SF', 'PF', 'C']));
    });

    test('each archetype has gameplay modifiers', () {
      final allArchetypes = RoleArchetypeRegistry.getAllArchetypes();
      
      for (final archetype in allArchetypes) {
        // All-Around archetypes may have empty modifiers (standard behavior)
        // All other archetypes should have at least one modifier
        if (!archetype.name.contains('All-Around')) {
          expect(archetype.gameplayModifiers.isNotEmpty, isTrue,
              reason: '${archetype.name} should have gameplay modifiers');
        }
      }
    });

    test('each archetype has attribute weights', () {
      final allArchetypes = RoleArchetypeRegistry.getAllArchetypes();
      
      for (final archetype in allArchetypes) {
        expect(archetype.attributeWeights.isNotEmpty, isTrue,
            reason: '${archetype.name} should have attribute weights');
      }
    });
  });

  group('Player Role Archetype Integration', () {
    test('getRoleArchetype returns null when no role is assigned', () {
      final player = Player(
        id: 'test1',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: null,
      );

      expect(player.getRoleArchetype(), isNull);
    });

    test('getRoleArchetype returns correct archetype when assigned', () {
      final player = Player(
        id: 'test2',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: 'pg_floor_general',
      );

      final archetype = player.getRoleArchetype();
      expect(archetype, isNotNull);
      expect(archetype!.id, equals('pg_floor_general'));
      expect(archetype.name, equals('Floor General'));
    });

    test('getRoleArchetype returns null for invalid role ID', () {
      final player = Player(
        id: 'test3',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: 'invalid_role_id',
      );

      expect(player.getRoleArchetype(), isNull);
    });

    test('getRoleFitScores returns fit scores for all position archetypes', () {
      final player = Player(
        id: 'test4',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
      );

      final fitScores = player.getRoleFitScores();
      
      // Should have fit scores for all PG archetypes (4 total)
      expect(fitScores.length, equals(4));
      expect(fitScores.keys, containsAll([
        'pg_allaround',
        'pg_floor_general',
        'pg_slashing_playmaker',
        'pg_offensive_point',
      ]));

      // All scores should be between 0 and 100
      for (final score in fitScores.values) {
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(100.0));
      }
    });

    test('getRoleFitScores calculates different scores for different archetypes', () {
      // Create a player optimized for Floor General (high passing and ball handling)
      final player = Player(
        id: 'test5',
        name: 'Floor General Player',
        heightInches: 74,
        shooting: 50,
        defense: 60,
        speed: 70,
        postShooting: 50,
        passing: 95,
        rebounding: 40,
        ballHandling: 90,
        threePoint: 60,
        blocks: 30,
        steals: 65,
        position: 'PG',
      );

      final fitScores = player.getRoleFitScores();
      
      // Floor General should have the highest fit score
      final floorGeneralScore = fitScores['pg_floor_general']!;
      final offensivePointScore = fitScores['pg_offensive_point']!;
      
      expect(floorGeneralScore, greaterThan(offensivePointScore));
    });

    test('copyWithRoleArchetype creates new player with updated role', () {
      final originalPlayer = Player(
        id: 'test6',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: null,
      );

      final updatedPlayer = originalPlayer.copyWithRoleArchetype('pg_floor_general');

      // Original player should be unchanged
      expect(originalPlayer.roleArchetypeId, isNull);
      
      // Updated player should have new role
      expect(updatedPlayer.roleArchetypeId, equals('pg_floor_general'));
      
      // All other attributes should be the same
      expect(updatedPlayer.id, equals(originalPlayer.id));
      expect(updatedPlayer.name, equals(originalPlayer.name));
      expect(updatedPlayer.shooting, equals(originalPlayer.shooting));
      expect(updatedPlayer.position, equals(originalPlayer.position));
    });

    test('copyWithRoleArchetype can clear role by passing null', () {
      final originalPlayer = Player(
        id: 'test7',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: 'pg_floor_general',
      );

      final updatedPlayer = originalPlayer.copyWithRoleArchetype(null);

      expect(originalPlayer.roleArchetypeId, equals('pg_floor_general'));
      expect(updatedPlayer.roleArchetypeId, isNull);
    });

    test('toJson includes roleArchetypeId', () {
      final player = Player(
        id: 'test8',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: 'pg_floor_general',
      );

      final json = player.toJson();
      expect(json['roleArchetypeId'], equals('pg_floor_general'));
    });

    test('toJson includes null roleArchetypeId when not assigned', () {
      final player = Player(
        id: 'test9',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: null,
      );

      final json = player.toJson();
      expect(json['roleArchetypeId'], isNull);
    });

    test('fromJson handles roleArchetypeId correctly', () {
      final json = {
        'id': 'test10',
        'name': 'Test Player',
        'heightInches': 75,
        'shooting': 80,
        'defense': 70,
        'speed': 75,
        'postShooting': 60,
        'passing': 85,
        'rebounding': 50,
        'ballHandling': 80,
        'threePoint': 70,
        'blocks': 40,
        'steals': 65,
        'position': 'PG',
        'roleArchetypeId': 'pg_floor_general',
      };

      final player = Player.fromJson(json);
      expect(player.roleArchetypeId, equals('pg_floor_general'));
    });

    test('fromJson handles missing roleArchetypeId for backward compatibility', () {
      final json = {
        'id': 'test11',
        'name': 'Test Player',
        'heightInches': 75,
        'shooting': 80,
        'defense': 70,
        'speed': 75,
        'postShooting': 60,
        'passing': 85,
        'rebounding': 50,
        'ballHandling': 80,
        'threePoint': 70,
        'blocks': 40,
        'steals': 65,
        'position': 'PG',
        // roleArchetypeId is missing
      };

      final player = Player.fromJson(json);
      expect(player.roleArchetypeId, isNull);
    });

    test('fromJson and toJson round-trip preserves roleArchetypeId', () {
      final originalPlayer = Player(
        id: 'test12',
        name: 'Test Player',
        heightInches: 75,
        shooting: 80,
        defense: 70,
        speed: 75,
        postShooting: 60,
        passing: 85,
        rebounding: 50,
        ballHandling: 80,
        threePoint: 70,
        blocks: 40,
        steals: 65,
        position: 'PG',
        roleArchetypeId: 'pg_offensive_point',
      );

      final json = originalPlayer.toJson();
      final deserializedPlayer = Player.fromJson(json);

      expect(deserializedPlayer.roleArchetypeId, equals(originalPlayer.roleArchetypeId));
      expect(deserializedPlayer.getRoleArchetype()?.id, equals('pg_offensive_point'));
    });
  });
}
