# Elimination Status Fix

## Problem
After making it into the regular playoffs (past the play-in tournament), the home page would still show "Team Eliminated in Play-In Tournament" even though the team had advanced.

## Root Cause

The logic for determining if a team was eliminated was:

```dart
final isUserEliminated = userSeries == null && !isPlayoffsComplete;
```

This logic was flawed because:
1. When a team is between rounds (e.g., just finished play-in, waiting for first round to start), `getUserTeamSeries()` returns `null` because the next round hasn't been generated yet
2. The system incorrectly interpreted this as elimination
3. Teams that successfully advanced would be shown as eliminated until their next series started

## Solution

### 1. Added `isTeamEliminated()` Method to PlayoffBracket
Created a proper method to check if a team has been eliminated by looking through all completed series to see if the team lost:

```dart
bool isTeamEliminated(String teamId) {
  // Check all completed rounds to see if team lost a series
  
  // Check play-in games
  // Check first round
  // Check conference semifinals
  // Check conference finals
  // Check NBA Finals
  
  return false; // Team is still alive or won championship
}
```

The method:
- Checks each playoff round (play-in, first round, semis, finals, NBA Finals)
- Looks for completed series where the team participated
- Returns `true` if the team lost any series
- Handles special play-in logic (losing 7v8 doesn't eliminate you if you win the second game)

### 2. Added `_getEliminationRound()` Helper in HomePage
Created a method to determine which round the team was actually eliminated in, rather than just showing the current round:

```dart
String _getEliminationRound(PlayoffBracket bracket) {
  // Check each round to find where the team lost
  // Returns the specific round name where elimination occurred
}
```

### 3. Updated HomePage Logic
Changed both the playoff status card and the play button to use the new elimination check:

```dart
// Old (incorrect)
final isUserEliminated = userSeries == null && !isPlayoffsComplete;

// New (correct)
final isUserEliminated = bracket.isTeamEliminated(_userTeamId!);
```

## Result

The home page now correctly shows:
- **Active series**: When the team has a current playoff series to play
- **Waiting for round**: When the team advanced but the next round hasn't started yet
- **Eliminated**: Only when the team actually lost a playoff series, with the correct round shown
- **Champion**: When the team wins the NBA Finals

Teams that advance through the play-in tournament are no longer incorrectly shown as eliminated.

## Testing

Updated `test/home_page_playoff_test.dart` to properly test elimination by creating a completed series where the user's team lost, rather than just having them absent from the bracket.

All tests pass:
- `test/end_to_end_playoff_test.dart`
- `test/playoff_service_test.dart`
- `test/home_page_playoff_test.dart`
