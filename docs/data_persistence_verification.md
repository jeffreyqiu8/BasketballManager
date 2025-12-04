# Data Persistence and Compatibility Verification

## Task 5: Implementation Summary

This document verifies that data persistence and compatibility requirements (11.1-11.5) are correctly implemented across the new team management UI.

## Verified Components

### 1. LineupPage Data Persistence

**Location**: `lib/views/lineup_page.dart`

**Implementation**:
- `_handleSave()` method correctly builds a `RotationConfig` from current state
- Updates `startingLineupIds` by deriving from depth chart (depth = 1 entries)
- Calls `LeagueService.updateTeam()` to persist changes
- Maintains data format compatibility with existing rotation system

**Key Code**:
```dart
Future<void> _handleSave() async {
  final config = _buildCurrentConfig();
  
  // Update starting lineup IDs from depth chart
  final startingLineupIds = _depthChart
      .where((entry) => entry.depth == 1)
      .map((entry) => entry.playerId)
      .toList();

  final updatedTeam = _team.copyWith(
    rotationConfig: config,
    startingLineupIds: startingLineupIds,
  );

  await widget.leagueService.updateTeam(updatedTeam);
}
```

### 2. MinutesEditorDialog Data Persistence

**Location**: `lib/views/minutes_editor_dialog.dart`

**Implementation**:
- `_handleSave()` method builds a `RotationConfig` with updated minutes
- Preserves depth chart unchanged (read-only in minutes editor)
- Calls `onSave` callback to update parent component
- Maintains rotation size and depth chart integrity

**Key Code**:
```dart
Future<void> _handleSave() async {
  final config = _buildCurrentConfig();
  widget.onSave(config);
  Navigator.of(context).pop();
}

RotationConfig _buildCurrentConfig() {
  return RotationConfig(
    rotationSize: _rotationSize,
    playerMinutes: _playerMinutes,
    depthChart: _depthChart, // Read-only, unchanged
    lastModified: DateTime.now(),
  );
}
```

### 3. Team.startingLineupIds Derivation

**Location**: `lib/models/team.dart`

**Implementation**:
- `startingLineup` getter derives starters from rotation config depth chart
- Falls back to `startingLineupIds` if no rotation config exists
- Ensures consistency between depth chart and starting lineup

**Key Code**:
```dart
List<Player> get startingLineup {
  if (rotationConfig != null) {
    // Get starters from rotation config (depth = 1)
    final starterIds = rotationConfig!.depthChart
        .where((entry) => entry.depth == 1)
        .map((entry) => entry.playerId)
        .toSet();
    
    return players
        .where((player) => starterIds.contains(player.id))
        .toList();
  }
  
  // Fallback to startingLineupIds if no rotation config
  return players
      .where((player) => startingLineupIds.contains(player.id))
      .toList();
}
```

### 4. Game Simulation Compatibility

**Location**: `lib/services/possession_simulation.dart`

**Implementation**:
- Game simulation correctly reads rotation config from teams
- Uses `getActivePlayerIds()` to get rotation players
- Derives starters from depth chart (depth = 1)
- Handles null rotation config gracefully

**Key Code**:
```dart
List<Player> _getRotationPlayers(Team team) {
  if (team.rotationConfig == null) {
    return team.startingLineup;
  }

  final activePlayerIds = team.rotationConfig!.getActivePlayerIds();
  return team.players
      .where((player) => activePlayerIds.contains(player.id))
      .toList();
}

List<Player> _getStartingLineup(Team team) {
  if (team.rotationConfig == null) {
    return team.startingLineup;
  }

  final starterIds = team.rotationConfig!.depthChart
      .where((entry) => entry.depth == 1)
      .map((entry) => entry.playerId)
      .toSet();
  
  return team.players
      .where((player) => starterIds.contains(player.id))
      .toList();
}
```

### 5. Data Serialization

**Location**: `lib/models/rotation_config.dart`, `lib/models/team.dart`

**Implementation**:
- `RotationConfig.toJson()` and `fromJson()` handle complete serialization
- `Team.toJson()` and `fromJson()` preserve rotation config
- Round-trip serialization maintains all data integrity

## Test Coverage

**Test File**: `test/data_persistence_compatibility_test.dart`

All 10 tests pass, verifying:

1. ✅ **Requirement 11.1**: Loading existing rotation config displays correctly
2. ✅ **Requirement 11.2**: Saving from LineupPage preserves rotation format
3. ✅ **Requirement 11.2**: Saving from MinutesEditorDialog preserves rotation format
4. ✅ **Requirement 11.3**: Team.startingLineupIds derived from depth chart
5. ✅ **Requirement 11.4**: Rotation config serialization round-trip
6. ✅ **Requirement 11.5**: Team serialization preserves rotation config
7. ✅ **Requirement 11.5**: Game simulation can use rotation config from new UI
8. ✅ **Requirement 11.1**: Loading rotation config with missing data handles gracefully
9. ✅ **Requirement 11.3**: Starting lineup IDs update when depth chart changes
10. ✅ **Requirement 11.4**: LeagueService.updateTeam persists changes

## Data Flow Diagram

```
┌─────────────────┐
│   LineupPage    │
│                 │
│ - Edit depth    │
│   chart         │
│ - Reorder       │
│   players       │
└────────┬────────┘
         │
         │ Save
         ▼
┌─────────────────────────┐
│   RotationConfig        │
│                         │
│ - rotationSize          │
│ - playerMinutes         │
│ - depthChart            │
│ - lastModified          │
└────────┬────────────────┘
         │
         │ Derive
         ▼
┌─────────────────────────┐
│   Team                  │
│                         │
│ - startingLineupIds     │
│   (from depth chart)    │
│ - rotationConfig        │
└────────┬────────────────┘
         │
         │ Persist
         ▼
┌─────────────────────────┐
│   LeagueService         │
│                         │
│ - updateTeam()          │
│ - getTeam()             │
└────────┬────────────────┘
         │
         │ Use in game
         ▼
┌─────────────────────────┐
│   PossessionSimulation  │
│                         │
│ - Get rotation players  │
│ - Get starters          │
│ - Simulate game         │
└─────────────────────────┘
```

## Compatibility Notes

### Backward Compatibility

The implementation maintains backward compatibility with existing saved games:

1. **Null Rotation Config**: Teams without rotation config fall back to `startingLineupIds`
2. **Default Generation**: Missing rotation configs can be generated on-demand
3. **Graceful Degradation**: Game simulation works with or without rotation config

### Forward Compatibility

The data format is designed for future enhancements:

1. **Extensible**: `RotationConfig` can be extended with new fields
2. **Versioned**: `lastModified` timestamp tracks changes
3. **Validated**: Built-in validation ensures data integrity

## Conclusion

All data persistence and compatibility requirements (11.1-11.5) are fully implemented and verified:

- ✅ LineupPage saves to RotationConfig correctly
- ✅ MinutesEditorDialog saves to RotationConfig correctly  
- ✅ Team.startingLineupIds derivation from depth chart works
- ✅ Loading existing rotation configs in new UI works
- ✅ Game simulation compatibility with new UI verified

The implementation ensures seamless data flow between UI components, proper persistence through LeagueService, and full compatibility with the game simulation engine.
