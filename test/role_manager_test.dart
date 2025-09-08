import 'package:flutter_test/flutter_test.dart';
import '../lib/gameData/role_manager.dart';
import '../lib/gameData/player_class.dart';
import '../lib/gameData/enums.dart';

void main() {
  group('RoleManager Tests', () {
    late Player testPlayer;

    setUp(() {
      // Create a test player with balanced attributes
      testPlayer = Player(
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
    });

    group('Role Compatibility Calculations', () {
      test('should calculate point guard compatibility correctly', () {
        // Create a player optimized for point guard
        final pgPlayer = Player(
          name: 'PG Player',
          age: 24,
          team: 'Test Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 185, // Good height for PG
          shooting: 75,
          rebounding: 45,
          passing: 85, // High passing for PG
          ballHandling: 80, // High ball handling for PG
          perimeterDefense: 70,
          postDefense: 40,
          insideShooting: 50,
          performances: {},
        );

        final compatibility = RoleManager.calculateRoleCompatibility(pgPlayer, PlayerRole.pointGuard);
        
        // Should have high compatibility for point guard
        expect(compatibility, greaterThan(0.8));
      });

      test('should calculate center compatibility correctly', () {
        // Create a player optimized for center
        final centerPlayer = Player(
          name: 'Center Player',
          age: 26,
          team: 'Test Team',
          experienceYears: 4,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 215, // Tall for center
          shooting: 45,
          rebounding: 90, // High rebounding for center
          passing: 40,
          ballHandling: 30,
          perimeterDefense: 35,
          postDefense: 85, // High post defense for center
          insideShooting: 80, // High inside shooting for center
          performances: {},
        );

        final compatibility = RoleManager.calculateRoleCompatibility(centerPlayer, PlayerRole.center);
        
        // Should have high compatibility for center
        expect(compatibility, greaterThan(0.8));
      });

      test('should return lower compatibility for mismatched roles', () {
        // Test point guard player at center position
        final pgPlayer = Player(
          name: 'PG Player',
          age: 24,
          team: 'Test Team',
          experienceYears: 2,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 180, // Short for center
          shooting: 75,
          rebounding: 40, // Low rebounding for center
          passing: 85,
          ballHandling: 80,
          perimeterDefense: 70,
          postDefense: 35, // Low post defense for center
          insideShooting: 45, // Low inside shooting for center
          performances: {},
        );

        final compatibility = RoleManager.calculateRoleCompatibility(pgPlayer, PlayerRole.center);
        
        // Should have low compatibility for center
        expect(compatibility, lessThan(0.6));
      });

      test('should handle edge cases in compatibility calculation', () {
        // Test with minimum attributes
        final minPlayer = Player(
          name: 'Min Player',
          age: 18,
          team: 'Test Team',
          experienceYears: 0,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 160,
          shooting: 1,
          rebounding: 1,
          passing: 1,
          ballHandling: 1,
          perimeterDefense: 1,
          postDefense: 1,
          insideShooting: 1,
          performances: {},
        );

        final compatibility = RoleManager.calculateRoleCompatibility(minPlayer, PlayerRole.pointGuard);
        
        // Should return a valid compatibility score
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    group('Best Role Detection', () {
      test('should identify best role for a point guard type player', () {
        final pgPlayer = Player(
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

        final bestRole = RoleManager.getBestRole(pgPlayer);
        expect(bestRole, equals(PlayerRole.pointGuard));
      });

      test('should identify best role for a center type player', () {
        final centerPlayer = Player(
          name: 'Center Player',
          age: 26,
          team: 'Test Team',
          experienceYears: 4,
          nationality: 'USA',
          currentStatus: 'Active',
          height: 220, // Very tall for center
          shooting: 30, // Very low shooting
          rebounding: 95, // Very high rebounding
          passing: 30, // Very low passing
          ballHandling: 20, // Very low ball handling
          perimeterDefense: 20, // Very low perimeter defense
          postDefense: 95, // Very high post defense
          insideShooting: 90, // Very high inside shooting
          performances: {},
        );

        final bestRole = RoleManager.getBestRole(centerPlayer);
        expect(bestRole, equals(PlayerRole.center));
      });
    });

    group('Role Bonuses and Penalties', () {
      test('should provide role bonuses for compatible positions', () {
        final bonuses = RoleManager.getRoleBonuses(testPlayer, PlayerRole.smallForward);
        
        // Should return a map with bonus values
        expect(bonuses, isNotEmpty);
        
        // All bonus values should be >= 1.0 (bonuses, not penalties)
        for (final bonus in bonuses.values) {
          expect(bonus, greaterThanOrEqualTo(1.0));
        }
      });

      test('should provide penalties for incompatible positions', () {
        // Create a point guard trying to play center
        final pgPlayer = Player(
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

        final penalties = RoleManager.getOutOfPositionPenalties(pgPlayer, PlayerRole.center);
        
        // Should have penalties for playing out of position
        expect(penalties, isNotEmpty);
        
        // All penalty values should be < 1.0 (penalties, not bonuses)
        for (final penalty in penalties.values) {
          expect(penalty, lessThan(1.0));
        }
      });

      test('should not apply penalties for good role compatibility', () {
        final pgPlayer = Player(
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

        final penalties = RoleManager.getOutOfPositionPenalties(pgPlayer, PlayerRole.pointGuard);
        
        // Should have no penalties for playing in optimal position
        expect(penalties, isEmpty);
      });
    });

    group('Lineup Validation', () {
      test('should validate correct lineup with all positions', () {
        final players = List.generate(5, (index) => testPlayer);
        final roles = [
          PlayerRole.pointGuard,
          PlayerRole.shootingGuard,
          PlayerRole.smallForward,
          PlayerRole.powerForward,
          PlayerRole.center,
        ];

        final isValid = RoleManager.validateLineup(players, roles);
        expect(isValid, isTrue);
      });

      test('should reject lineup with missing positions', () {
        final players = List.generate(5, (index) => testPlayer);
        final roles = [
          PlayerRole.pointGuard,
          PlayerRole.pointGuard, // Duplicate position
          PlayerRole.smallForward,
          PlayerRole.powerForward,
          PlayerRole.center,
        ];

        final isValid = RoleManager.validateLineup(players, roles);
        expect(isValid, isFalse);
      });

      test('should reject lineup with wrong number of players', () {
        final players = List.generate(4, (index) => testPlayer); // Only 4 players
        final roles = [
          PlayerRole.pointGuard,
          PlayerRole.shootingGuard,
          PlayerRole.smallForward,
          PlayerRole.powerForward,
        ];

        final isValid = RoleManager.validateLineup(players, roles);
        expect(isValid, isFalse);
      });
    });

    group('Optimal Lineup Generation', () {
      test('should generate valid lineup assignments', () {
        final players = [
          // Point Guard type
          Player(
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
          ),
          // Shooting Guard type
          Player(
            name: 'SG Player',
            age: 25,
            team: 'Test Team',
            experienceYears: 3,
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
          ),
          // Small Forward type
          Player(
            name: 'SF Player',
            age: 26,
            team: 'Test Team',
            experienceYears: 4,
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
          ),
          // Power Forward type
          Player(
            name: 'PF Player',
            age: 27,
            team: 'Test Team',
            experienceYears: 5,
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
          ),
          // Center type
          Player(
            name: 'C Player',
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
          ),
        ];

        final assignments = RoleManager.getOptimalLineup(players);
        
        // Should return exactly 5 role assignments
        expect(assignments.length, equals(5));
        
        // Should assign each position exactly once
        final assignedRoles = assignments.toSet();
        expect(assignedRoles.length, equals(5));
        expect(assignedRoles.containsAll(PlayerRole.values), isTrue);
      });

      test('should throw error for invalid player count', () {
        final players = List.generate(3, (index) => testPlayer); // Only 3 players
        
        expect(
          () => RoleManager.getOptimalLineup(players),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('All Role Compatibilities', () {
      test('should return compatibility scores for all roles', () {
        final compatibilities = RoleManager.getAllRoleCompatibilities(testPlayer);
        
        // Should have compatibility score for each role
        expect(compatibilities.length, equals(PlayerRole.values.length));
        
        // All compatibility scores should be between 0.0 and 1.0
        for (final compatibility in compatibilities.values) {
          expect(compatibility, greaterThanOrEqualTo(0.0));
          expect(compatibility, lessThanOrEqualTo(1.0));
        }
        
        // Should contain all player roles
        for (final role in PlayerRole.values) {
          expect(compatibilities.containsKey(role), isTrue);
        }
      });
    });
  });
}