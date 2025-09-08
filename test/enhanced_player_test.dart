import 'package:flutter_test/flutter_test.dart';
import '../lib/gameData/enhanced_player.dart';
import '../lib/gameData/player_class.dart';
import '../lib/gameData/enums.dart';

void main() {
  group('EnhancedPlayer Tests', () {
    late Player basePlayer;
    late EnhancedPlayer enhancedPlayer;

    setUp(() {
      basePlayer = Player(
        name: 'Test Player',
        age: 25,
        team: 'Test Team',
        experienceYears: 3,
        nationality: 'USA',
        currentStatus: 'Active',
        height: 195,
        shooting: 70,
        rebounding: 60,
        passing: 65,
        ballHandling: 60,
        perimeterDefense: 65,
        postDefense: 55,
        insideShooting: 60,
        performances: {},
      );

      enhancedPlayer = EnhancedPlayer.fromPlayer(
        basePlayer,
        primaryRole: PlayerRole.smallForward,
      );
    });

    group('Role Assignment and Validation', () {
      test('should create enhanced player with automatic role assignment', () {
        final autoPlayer = EnhancedPlayer.fromPlayer(basePlayer);
        
        // Should have a valid primary role assigned
        expect(autoPlayer.primaryRole, isNotNull);
        expect(PlayerRole.values.contains(autoPlayer.primaryRole), isTrue);
        
        // Should have calculated role compatibility
        expect(autoPlayer.roleCompatibility, greaterThan(0.0));
        expect(autoPlayer.roleCompatibility, lessThanOrEqualTo(1.0));
      });

      test('should validate role assignments correctly', () {
        // Create a point guard type player
        final pgPlayer = EnhancedPlayer(
          name: 'PG Player',
          age: 24,
          team: 'Test Team',
          experienceYears: 2,
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
        );

        // Should validate point guard role as good
        expect(pgPlayer.isValidRoleAssignment(PlayerRole.pointGuard), isTrue);
        
        // Should reject center role as poor fit
        expect(pgPlayer.isValidRoleAssignment(PlayerRole.center), isFalse);
      });

      test('should assign primary role successfully', () {
        final success = enhancedPlayer.assignPrimaryRole(PlayerRole.shootingGuard);
        
        expect(success, isTrue);
        expect(enhancedPlayer.primaryRole, equals(PlayerRole.shootingGuard));
        expect(enhancedPlayer.roleCompatibility, greaterThan(0.0));
      });

      test('should reject invalid primary role assignment', () {
        // Create a point guard trying to play center
        final pgPlayer = EnhancedPlayer(
          name: 'PG Player',
          age: 24,
          team: 'Test Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 180,
          shooting: 75,
          rebounding: 40,
          passing: 85,
          ballHandling: 80,
          perimeterDefense: 70,
          postDefense: 35,
          insideShooting: 45,
          performances: {},
        );

        final originalRole = pgPlayer.primaryRole;
        final success = pgPlayer.assignPrimaryRole(PlayerRole.center);
        
        expect(success, isFalse);
        expect(pgPlayer.primaryRole, equals(originalRole)); // Should remain unchanged
      });

      test('should assign secondary role successfully', () {
        final success = enhancedPlayer.assignSecondaryRole(PlayerRole.shootingGuard);
        
        expect(success, isTrue);
        expect(enhancedPlayer.secondaryRole, equals(PlayerRole.shootingGuard));
      });

      test('should reject secondary role same as primary', () {
        final success = enhancedPlayer.assignSecondaryRole(enhancedPlayer.primaryRole);
        
        expect(success, isFalse);
        expect(enhancedPlayer.secondaryRole, isNull);
      });
    });

    group('Role Compatibility and Bonuses', () {
      test('should calculate role compatibility correctly', () {
        final compatibility = enhancedPlayer.calculateRoleCompatibility(PlayerRole.smallForward);
        
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });

      test('should get all role compatibilities', () {
        final compatibilities = enhancedPlayer.getAllRoleCompatibilities();
        
        expect(compatibilities.length, equals(PlayerRole.values.length));
        
        for (final compatibility in compatibilities.values) {
          expect(compatibility, greaterThanOrEqualTo(0.0));
          expect(compatibility, lessThanOrEqualTo(1.0));
        }
      });

      test('should get best role for player', () {
        final bestRole = enhancedPlayer.getBestRole();
        
        expect(PlayerRole.values.contains(bestRole), isTrue);
      });

      test('should provide role bonuses', () {
        final bonuses = enhancedPlayer.getRoleBonuses();
        
        expect(bonuses, isA<Map<String, double>>());
        
        // All bonuses should be >= 1.0 (bonuses, not penalties)
        for (final bonus in bonuses.values) {
          expect(bonus, greaterThanOrEqualTo(1.0));
        }
      });

      test('should provide out-of-position penalties when applicable', () {
        // Create a point guard playing center
        final pgPlayer = EnhancedPlayer(
          name: 'PG Player',
          age: 24,
          team: 'Test Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 180,
          shooting: 75,
          rebounding: 40,
          passing: 85,
          ballHandling: 80,
          perimeterDefense: 70,
          postDefense: 35,
          insideShooting: 45,
          performances: {},
          primaryRole: PlayerRole.center, // Force center role
        );

        final penalties = pgPlayer.getOutOfPositionPenalties();
        
        if (penalties.isNotEmpty) {
          // All penalties should be < 1.0 (penalties, not bonuses)
          for (final penalty in penalties.values) {
            expect(penalty, lessThan(1.0));
          }
        }
      });

      test('should calculate combined role-based modifiers', () {
        final modifiers = enhancedPlayer.calculateRoleBasedModifiers();
        
        expect(modifiers, isA<Map<String, double>>());
        
        // All modifiers should be positive
        for (final modifier in modifiers.values) {
          expect(modifier, greaterThan(0.0));
        }
      });
    });

    group('Role Experience System', () {
      test('should award role experience correctly', () {
        final initialExperience = enhancedPlayer.roleExperience[PlayerRole.smallForward] ?? 0.0;
        
        enhancedPlayer.awardRoleExperience(PlayerRole.smallForward, 10.0);
        
        final newExperience = enhancedPlayer.roleExperience[PlayerRole.smallForward] ?? 0.0;
        expect(newExperience, equals(initialExperience + 10.0));
      });

      test('should improve role compatibility with experience', () {
        final initialCompatibility = enhancedPlayer.roleCompatibility;
        
        enhancedPlayer.awardRoleExperience(enhancedPlayer.primaryRole, 50.0);
        
        expect(enhancedPlayer.roleCompatibility, greaterThanOrEqualTo(initialCompatibility));
      });

      test('should not improve compatibility for non-primary roles', () {
        final initialCompatibility = enhancedPlayer.roleCompatibility;
        
        enhancedPlayer.awardRoleExperience(PlayerRole.center, 50.0);
        
        expect(enhancedPlayer.roleCompatibility, equals(initialCompatibility));
      });
    });

    group('Serialization', () {
      test('should serialize to map correctly', () {
        final map = enhancedPlayer.toMap();
        
        expect(map, isA<Map<String, dynamic>>());
        expect(map.containsKey('primaryRole'), isTrue);
        expect(map.containsKey('roleCompatibility'), isTrue);
        expect(map.containsKey('roleExperience'), isTrue);
        expect(map.containsKey('potential'), isTrue);
        expect(map.containsKey('development'), isTrue);
      });

      test('should deserialize from map correctly', () {
        final originalMap = enhancedPlayer.toMap();
        final deserializedPlayer = EnhancedPlayer.fromMap(originalMap);
        
        expect(deserializedPlayer.name, equals(enhancedPlayer.name));
        expect(deserializedPlayer.primaryRole, equals(enhancedPlayer.primaryRole));
        expect(deserializedPlayer.secondaryRole, equals(enhancedPlayer.secondaryRole));
        expect(deserializedPlayer.roleCompatibility, equals(enhancedPlayer.roleCompatibility));
      });

      test('should handle missing role data in deserialization', () {
        final baseMap = basePlayer.toMap();
        final deserializedPlayer = EnhancedPlayer.fromMap(baseMap);
        
        expect(deserializedPlayer.primaryRole, equals(PlayerRole.pointGuard)); // Default
        expect(deserializedPlayer.roleCompatibility, greaterThan(0.0));
        expect(deserializedPlayer.potential, isNotNull);
        expect(deserializedPlayer.development, isNotNull);
      });
    });

    group('Player Potential System', () {
      test('should create default potential correctly', () {
        final potential = PlayerPotential.defaultPotential();
        
        expect(potential.tier, equals(PotentialTier.bronze));
        expect(potential.maxSkills, isNotEmpty);
        expect(potential.overallPotential, equals(75));
        expect(potential.isHidden, isTrue);
      });

      test('should serialize and deserialize potential correctly', () {
        final potential = PlayerPotential.defaultPotential();
        final map = potential.toMap();
        final deserializedPotential = PlayerPotential.fromMap(map);
        
        expect(deserializedPotential.tier, equals(potential.tier));
        expect(deserializedPotential.overallPotential, equals(potential.overallPotential));
        expect(deserializedPotential.isHidden, equals(potential.isHidden));
      });
    });

    group('Development Tracker System', () {
      test('should create initial development tracker correctly', () {
        final tracker = DevelopmentTracker.initial();
        
        expect(tracker.skillExperience, isNotEmpty);
        expect(tracker.totalExperience, equals(0));
        expect(tracker.developmentRate, equals(1.0));
        expect(tracker.milestones, isEmpty);
        expect(tracker.agingCurve, isNotNull);
      });

      test('should serialize and deserialize development tracker correctly', () {
        final tracker = DevelopmentTracker.initial();
        final map = tracker.toMap();
        final deserializedTracker = DevelopmentTracker.fromMap(map);
        
        expect(deserializedTracker.totalExperience, equals(tracker.totalExperience));
        expect(deserializedTracker.developmentRate, equals(tracker.developmentRate));
        expect(deserializedTracker.milestones.length, equals(tracker.milestones.length));
      });
    });

    group('Aging Curve System', () {
      test('should create standard aging curve correctly', () {
        final curve = AgingCurve.standard();
        
        expect(curve.peakAge, equals(27));
        expect(curve.declineStartAge, equals(30));
        expect(curve.peakMultiplier, equals(1.2));
        expect(curve.declineRate, equals(0.02));
      });

      test('should calculate age modifiers correctly', () {
        final curve = AgingCurve.standard();
        
        // Young player should have bonus
        final youngModifier = curve.getAgeModifier(22);
        expect(youngModifier, greaterThan(1.0));
        
        // Peak age player should have peak multiplier
        final peakModifier = curve.getAgeModifier(27);
        expect(peakModifier, equals(1.2));
        
        // Old player should have penalty
        final oldModifier = curve.getAgeModifier(35);
        expect(oldModifier, lessThan(1.0));
        expect(oldModifier, greaterThanOrEqualTo(0.1)); // Should not go below minimum
      });

      test('should serialize and deserialize aging curve correctly', () {
        final curve = AgingCurve.standard();
        final map = curve.toMap();
        final deserializedCurve = AgingCurve.fromMap(map);
        
        expect(deserializedCurve.peakAge, equals(curve.peakAge));
        expect(deserializedCurve.declineStartAge, equals(curve.declineStartAge));
        expect(deserializedCurve.peakMultiplier, equals(curve.peakMultiplier));
        expect(deserializedCurve.declineRate, equals(curve.declineRate));
      });
    });
  });
}