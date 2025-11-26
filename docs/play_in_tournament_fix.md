# Play-In Tournament Fix

## Problem
When the user's team qualified for the play-in tournament, the system would incorrectly show them as eliminated without simulating any games. The user would see a message saying they were "knocked out in play-ins" even though no play-in games had been played.

## Root Cause

The play-in tournament has a unique 3-game structure per conference:
1. **Game 1**: 7 seed vs 8 seed (winner gets 7th seed in playoffs)
2. **Game 2**: 9 seed vs 10 seed
3. **Game 3**: Loser of Game 1 vs Winner of Game 2 (winner gets 8th seed in playoffs)

The system was only creating the first 2 games initially (7v8 and 9v10 for each conference = 4 games total). However, the `isRoundComplete()` method would check if all games in the play-in round were complete, and since only 4 games existed, it would return `true` after those 4 games were done.

The `advancePlayoffRound()` method would then try to call `resolvePlayIn()`, which expects all 3 games per conference (6 total) to be complete. This would fail because the 3rd game for each conference hadn't been created yet, causing the system to incorrectly determine playoff seeding or mark teams as eliminated.

## Solution

### 1. Updated `isRoundComplete()` in PlayoffBracket
Added special handling for the play-in round to check if we have all 6 games before considering the round complete:

```dart
// Special handling for play-in round
// Play-in needs 6 games total (3 per conference)
if (currentRound == 'play-in') {
  // Check if we have all 6 games
  if (currentSeries.length < 6) {
    // We don't have all games yet
    return false;
  }
  // If we have 6 games, check if they're all complete
  return currentSeries.every((series) => series.isComplete);
}
```

### 2. Added `needsSecondPlayInGames()` Method
Created a new method to detect when the initial 4 play-in games are complete and the final 2 games need to be created:

```dart
bool needsSecondPlayInGames() {
  if (currentRound != 'play-in') return false;
  if (playInGames.length != 4) return false;
  
  // Check if all 4 initial games are complete
  return playInGames.every((series) => series.isComplete);
}
```

### 3. Added Automatic Second Game Creation in GamePage
Added logic in `game_page.dart` to automatically create the second round of play-in games when needed:

```dart
// Check if we need to create second play-in games
if (updatedBracket.needsSecondPlayInGames()) {
  // Create the second round of play-in games
  updatedBracket = _createSecondPlayInGames(updatedBracket);
  
  if (mounted) {
    AccessibilityUtils.showAccessibleInfo(
      context,
      'Play-in tournament continues! Final games to determine seeds 7 and 8.',
      duration: const Duration(seconds: 3),
    );
  }
}
```

### 4. Implemented `_createSecondPlayInGames()` Helper
Created a helper method that uses `PlayoffService.createSecondPlayInGame()` to generate the final 2 play-in games (one per conference) after the initial 4 games are complete.

## Result

The play-in tournament now works correctly:
1. Initial 4 games (7v8 and 9v10 for each conference) are created when playoffs start
2. After these 4 games are complete, the system automatically creates the final 2 games
3. Only after all 6 games are complete does the round advance to the first round
4. Users can now properly play through the entire play-in tournament
5. Playoff seeding is correctly determined based on all 3 games per conference

## Additional Fix: Playoff Game Loading

### Problem 1: Game Page Not Loading Playoff Games
After fixing the play-in tournament, clicking "Play Next Playoff Game" would trigger the "Season Complete" popup instead of loading the playoff game.

### Root Cause 1
The `_loadNextGame()` method in `game_page.dart` only loaded games from `_season.nextGame`, which returns the next unplayed regular season game. During playoffs, all 82 regular season games are complete, so `nextGame` returns `null`, and the system thought there were no more games to play.

### Solution 1
Updated `_loadNextGame()` to check if the season is in post-season mode and load playoff games from the playoff bracket instead:

### Problem 2: Navigation Blocked During Playoffs
The `_navigateToGame()` method in `home_page.dart` was checking `_currentSeason!.isComplete` and showing "Season complete!" message, preventing navigation to playoff games.

### Root Cause 2
The `isComplete` property returns `true` when all 82 regular season games are played, but this check was being applied to both regular season AND playoffs. During playoffs, `isComplete` is always `true`, so the navigation was blocked.

### Solution 2
Updated the check to only apply during regular season:

```dart
// Old (incorrect)
if (_currentSeason!.isComplete) {
  // Show "Season complete!" and return
}

// New (correct)
if (!_currentSeason!.isPostSeason && _currentSeason!.isComplete) {
  // Only show "Season complete!" during regular season
}
```

```dart
// Check if we're in playoffs
if (_season.isPostSeason && _season.playoffBracket != null) {
  // Get the user's current playoff series
  final userSeries = _season.playoffBracket!.getUserTeamSeries(widget.userTeamId);
  
  if (userSeries != null && !userSeries.isComplete) {
    // Create a playoff game for this series
    // Uses 2-2-1-1-1 home court format
  }
}
```

Also added `_determineHomeTeam()` helper method to implement the NBA's 2-2-1-1-1 playoff home court format:
- Games 1, 2, 5, 7: Higher seed's home
- Games 3, 4, 6: Lower seed's home

## Testing

All playoff tests pass, including:
- `test/end_to_end_playoff_test.dart` - Complete playoff flow from play-in to finals
- `test/playoff_service_test.dart` - Playoff service logic and round advancement
- `test/season_playoff_test.dart` - Season playoff integration
- `test/home_page_playoff_test.dart` - Home page playoff button and status display

The fix ensures that:
1. Teams in the play-in tournament can properly compete for playoff spots without being prematurely eliminated
2. The "Play Next Playoff Game" button correctly loads playoff games instead of showing "Season Complete"
3. Playoff games follow the proper 2-2-1-1-1 home court format
