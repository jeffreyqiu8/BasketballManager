# Season Simulation Feature

## Overview

The season simulation feature allows users to quickly simulate entire regular seasons or remaining games in a season, rather than playing each game individually.

## Features

### 1. Simulate Entire Regular Season

Simulates all 82 games in a season from start to finish.

**Usage:**
```dart
final updatedSeason = leagueService.simulateEntireRegularSeason(
  season,
  gameService,
  updateStats: true, // Optional: whether to track statistics
);
```

**Parameters:**
- `season`: The season to simulate (must have 82 unplayed games)
- `gameService`: The game service to use for simulating individual games
- `updateStats`: Whether to update season statistics (default: true)

**Returns:** Updated season with all games played and statistics accumulated

### 2. Simulate Remaining Games

Simulates only the unplayed games in a season, preserving results of already-played games.

**Usage:**
```dart
final updatedSeason = leagueService.simulateRemainingRegularSeasonGames(
  season,
  gameService,
  updateStats: true,
);
```

**Parameters:**
- `season`: The season to simulate
- `gameService`: The game service to use for simulating individual games
- `updateStats`: Whether to update season statistics (default: true)

**Returns:** Updated season with newly played games

## UI Integration

### HomePage Button

A "Simulate Remaining Season" button appears on the HomePage when:
- The regular season is not complete
- There are 2 or more games remaining

The button:
- Shows the number of remaining games
- Displays a confirmation dialog before simulating
- Shows a loading indicator during simulation
- Automatically triggers post-season if the regular season completes

## Performance

- Each game simulation takes approximately 3 seconds
- Full season simulation (82 games) takes approximately 4-5 minutes
- Simulation runs asynchronously to avoid blocking the UI

## Error Handling

The simulation methods throw `StateError` if:
- Attempting to simulate a post-season season
- Season doesn't have exactly 82 games
- User team is not found

## Testing

Comprehensive tests are available in `test/season_simulation_test.dart`:

1. **simulateEntireRegularSeason simulates all 82 games** - Verifies all games are played
2. **simulateEntireRegularSeason updates season statistics** - Confirms stats are tracked
3. **simulateRemainingRegularSeasonGames only simulates unplayed games** - Tests partial simulation
4. **simulateEntireRegularSeason throws error for post-season** - Validates error handling
5. **simulateEntireRegularSeason completes in reasonable time** - Performance test
6. **simulateEntireRegularSeason produces realistic win-loss records** - Validates results
7. **simulateRemainingRegularSeasonGames preserves existing game results** - Tests data integrity
8. **simulateEntireRegularSeason can be disabled for stats updates** - Tests optional parameter

## Example Usage

```dart
// Simulate entire season
final teams = leagueService.getAllTeams();
final userTeam = teams[0];
final games = gameService.generateSchedule(userTeam.id, teams);

var season = Season(
  id: 'season-2024',
  year: 2024,
  games: games,
  userTeamId: userTeam.id,
);

// Simulate all games
season = leagueService.simulateEntireRegularSeason(season, gameService);

// Check results
print('Final record: ${season.wins}-${season.losses}');
print('Games played: ${season.gamesPlayed}');

// Check if post-season should start
final postSeasonSeason = leagueService.checkAndStartPostSeason(season);
if (postSeasonSeason != null) {
  print('Post-season started!');
}
```

## Future Enhancements

Potential improvements for future versions:

1. **Batch Simulation** - Simulate multiple seasons at once
2. **Simulation Speed Options** - Fast mode (no stats) vs detailed mode
3. **Simulation Preview** - Show projected standings before confirming
4. **Pause/Resume** - Allow pausing long simulations
5. **Background Simulation** - Run simulation in background thread
6. **Simulation History** - Track and review simulated seasons
