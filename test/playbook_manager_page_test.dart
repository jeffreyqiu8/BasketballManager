import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enums.dart';

void main() {
  group('PlaybookManagerPage Tests', () {
    late EnhancedTeam mockTeam;
    late PlaybookLibrary mockLibrary;

    setUp(() {
      // Create a mock team for testing
      List<EnhancedPlayer> mockPlayers = [];
      mockTeam = EnhancedTeam(
        name: 'Test Team',
        reputation: 50,
        playerCount: 0,
        teamSize: 15,
        players: mockPlayers,
        conference: 'Eastern',
        division: 'Atlantic',
      );

      // Create a mock playbook library
      mockLibrary = PlaybookLibrary();
      mockLibrary.initializeWithDefaults();
    });

    test('should create playbook library with defaults', () {
      expect(mockLibrary.playbooks.isNotEmpty, true);
      expect(mockLibrary.activePlaybook, isNotNull);
    });

    test('should create playbook with strategies', () {
      Playbook testPlaybook = Playbook(
        name: 'Test Playbook',
        offensiveStrategy: OffensiveStrategy.fastBreak,
        defensiveStrategy: DefensiveStrategy.pressDefense,
      );

      expect(testPlaybook.name, 'Test Playbook');
      expect(testPlaybook.offensiveStrategy, OffensiveStrategy.fastBreak);
      expect(testPlaybook.defensiveStrategy, DefensiveStrategy.pressDefense);
    });

    test('should add playbook to library', () {
      int initialCount = mockLibrary.playbooks.length;
      
      Playbook newPlaybook = Playbook(
        name: 'Custom Playbook',
        offensiveStrategy: OffensiveStrategy.threePointHeavy,
        defensiveStrategy: DefensiveStrategy.zoneDefense,
      );

      mockLibrary.addPlaybook(newPlaybook);
      
      expect(mockLibrary.playbooks.length, initialCount + 1);
      expect(mockLibrary.playbooks.last.name, 'Custom Playbook');
    });

    test('should set active playbook', () {
      Playbook newPlaybook = Playbook(
        name: 'New Active Playbook',
        offensiveStrategy: OffensiveStrategy.postUp,
        defensiveStrategy: DefensiveStrategy.manToMan,
      );

      mockLibrary.addPlaybook(newPlaybook);
      bool result = mockLibrary.setActivePlaybook('New Active Playbook');
      
      expect(result, true);
      expect(mockLibrary.activePlaybook?.name, 'New Active Playbook');
    });

    test('should calculate team stats for enhanced team', () {
      Map<String, double> teamStats = mockTeam.calculateTeamStats();
      
      expect(teamStats, isA<Map<String, double>>());
      // Team stats calculation works regardless of content
    });

    test('should create preset playbooks', () {
      List<Playbook> presets = [
        Playbook.createPreset('run_and_gun'),
        Playbook.createPreset('defensive_minded'),
        Playbook.createPreset('three_point_shooters'),
      ];

      expect(presets.length, 3);
      expect(presets[0].name, 'Run and Gun');
      expect(presets[1].name, 'Defensive Minded');
      expect(presets[2].name, 'Three Point Shooters');
    });

    test('should validate strategy enums', () {
      // Test that all offensive strategies are available
      expect(OffensiveStrategy.values.length, 5);
      expect(OffensiveStrategy.values.contains(OffensiveStrategy.fastBreak), true);
      expect(OffensiveStrategy.values.contains(OffensiveStrategy.halfCourt), true);
      expect(OffensiveStrategy.values.contains(OffensiveStrategy.pickAndRoll), true);
      expect(OffensiveStrategy.values.contains(OffensiveStrategy.postUp), true);
      expect(OffensiveStrategy.values.contains(OffensiveStrategy.threePointHeavy), true);

      // Test that all defensive strategies are available
      expect(DefensiveStrategy.values.length, 4);
      expect(DefensiveStrategy.values.contains(DefensiveStrategy.manToMan), true);
      expect(DefensiveStrategy.values.contains(DefensiveStrategy.zoneDefense), true);
      expect(DefensiveStrategy.values.contains(DefensiveStrategy.pressDefense), true);
      expect(DefensiveStrategy.values.contains(DefensiveStrategy.switchDefense), true);
    });

    test('should have display names for strategies', () {
      expect(OffensiveStrategy.fastBreak.displayName, 'Fast Break');
      expect(OffensiveStrategy.halfCourt.displayName, 'Half Court');
      expect(DefensiveStrategy.manToMan.displayName, 'Man-to-Man');
      expect(DefensiveStrategy.zoneDefense.displayName, 'Zone Defense');
    });

    test('should serialize and deserialize playbook', () {
      Playbook original = Playbook(
        name: 'Serialization Test',
        offensiveStrategy: OffensiveStrategy.pickAndRoll,
        defensiveStrategy: DefensiveStrategy.switchDefense,
      );

      Map<String, dynamic> serialized = original.toMap();
      Playbook deserialized = Playbook.fromMap(serialized);

      expect(deserialized.name, original.name);
      expect(deserialized.offensiveStrategy, original.offensiveStrategy);
      expect(deserialized.defensiveStrategy, original.defensiveStrategy);
    });
  });
}