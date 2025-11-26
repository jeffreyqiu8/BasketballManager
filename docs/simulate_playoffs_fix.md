# Simulate Rest of Playoffs Fix

## Problem
When a user's team was eliminated from the playoffs (or didn't make playoffs), they would see "Waiting for Round to Complete" and had no way to:
1. Simulate the rest of the playoffs to see who wins the championship
2. Progress to the next season without manually waiting for all playoff games

This left users stuck, unable to see the playoff outcome or start a new season.

## Root Cause

The button logic for eliminated teams only provided:
- "View Playoff Bracket" - to see current playoff status
- "Start New Season" - to immediately start a new season

There was no option to simulate the remaining playoff games to completion, meaning users couldn't see who won the championship before starting a new season.

## Solution

### 1. Added `_simulateRestOfPlayoffs()` Method
Created a new method that:
- Shows a confirmation dialog
- Simulates all remaining playoff games using `PlayoffService.simulateNonUserPlayoffGames()`
- Continues simulating until `currentRound == 'complete'`
- Shows a loading indicator during simulation
- Displays the champion when complete

```dart
Future<void> _simulateRestOfPlayoffs() async {
  // Confirm with user
  // Show loading
  // Simulate until playoffs complete
  while (updatedBracket.currentRound != 'complete') {
    final result = PlayoffService.simulateNonUserPlayoffGames(...);
    updatedBracket = result.bracket;
  }
  // Show champion
}
```

### 2. Updated Button Layout for Eliminated Teams
Changed the button layout to include three options (in order of priority):

1. **Simulate Rest of Playoffs** (Orange button)
   - Primary action for eliminated teams
   - Simulates all remaining games to see the champion
   - Uses orange color to match the "Simulate Remaining Season" button style

2. **View Playoff Bracket** (Outlined button)
   - Secondary action to view current playoff status
   - Allows users to see matchups and scores

3. **Start New Season** (Purple button)
   - Tertiary action to skip to next season
   - Allows users to start fresh without seeing playoff outcome

### 3. Improved User Experience
Users who are eliminated can now:
- **See the outcome**: Simulate playoffs to see who wins the championship
- **Stay informed**: View the playoff bracket at any time
- **Move on**: Start a new season when ready

The simulation:
- Shows a loading indicator with progress
- Completes quickly (uses fast simulation for non-user games)
- Displays the champion's name when complete
- Updates the playoff bracket so users can view final results

### 4. Updated "Waiting for Round to Complete" Case
The fallback case when a user finishes their series but other series in the round aren't complete was showing a disabled "Waiting for Round to Complete" button. This has been replaced with the same actionable buttons:
- "Simulate Rest of Playoffs" - to see the outcome
- "View Playoff Bracket" - to see current status

## Result

All playoff scenarios now have actionable buttons:

**Eliminated teams:**
1. Get eliminated from playoffs
2. Click "Simulate Rest of Playoffs" to see who wins
3. View the playoff bracket to see final matchups and scores
4. Click "Start New Season" when ready to continue

**Teams waiting between rounds:**
1. Finish their playoff series
2. Click "Simulate Rest of Playoffs" to see who advances
3. View the playoff bracket to see current matchups
4. Automatically advance when round completes

Users are never stuck with disabled buttons and can always progress.

## Testing

All tests pass:
- `test/home_page_playoff_test.dart`
- `test/end_to_end_playoff_test.dart`

The fix provides a smooth experience for all playoff scenarios:
- Making playoffs and competing
- Missing playoffs entirely
- Getting eliminated in any round
- Winning the championship

### 5. Fixed Playoff Game Synchronization
Added automatic simulation of non-user playoff games after each user playoff game in `game_page.dart`. This ensures:
- All playoff series progress at the same pace
- When you finish a game, other teams' games are also simulated
- "Simulate Rest of Playoffs" doesn't get stuck
- The bracket stays synchronized

```dart
// After user plays their playoff game
final simulationResult = PlayoffService.simulateNonUserPlayoffGames(
  bracket: updatedBracket,
  userTeamId: widget.userTeamId,
  getTeam: (teamId) => widget.leagueService.getTeam(teamId)!,
  simulateGame: (homeTeam, awayTeam, series) {
    return _gameService.simulatePlayoffGame(homeTeam, awayTeam, series);
  },
);
```

## Files Modified
- `lib/views/home_page.dart` - Added simulation method and updated button layout
- `lib/views/game_page.dart` - Added automatic non-user game simulation after each playoff game
