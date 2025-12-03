# Playoff Seeding Mismatch Issue

## Problem
User's team (Atlanta Hawks) shows as 5th seed (43-39) in League Standings, but is placed in play-in tournament (which is only for seeds 7-10).

## Investigation Results

### Test Results
Created debug test that simulates a full season and checks seedings:
- Atlanta Hawks ended up as 8th seed (40-42) in the test
- Correctly placed in play-in tournament (7v8 game)
- This is DIFFERENT from user's actual game where Atlanta is 5th (43-39)

### Key Finding
The seeding calculation and league standings both use the same source:
```dart
final gamesToUse = season.leagueSchedule != null
    ? season.leagueSchedule!.allGames
    : season.games;
```

Both use `season.leagueSchedule!.allGames` when available.

### Hypothesis
The mismatch suggests one of these scenarios:
1. **Timing Issue**: Playoff bracket is generated before all league games are simulated
2. **Data Inconsistency**: League standings and playoff seeding are reading from different game lists
3. **Calculation Bug**: There's a subtle bug in how wins/losses are counted in one place but not the other

## Next Steps

1. **Add Logging**: Add debug output to show:
   - Which games are being used for seeding calculation
   - Actual win-loss records calculated for each team
   - When playoff bracket is generated vs when league games are simulated

2. **Verify Game Completion**: Ensure all 1230 league games are marked as played before playoffs start

3. **Check for Race Conditions**: Verify that `simulateRemainingRegularSeasonGames` completes before `checkAndStartPostSeason` is called

4. **Add Validation**: Add assertion to verify standings match seedings before creating playoff bracket

## Temporary Workaround
User can check their actual seed in the league standings before playoffs start. If they're top 6, they should not be in play-in games.

## Recommended Fix
Add validation in `checkAndStartPostSeason` to verify that calculated seedings match expected standings:

```dart
// After calculating seedings, verify they match standings
final userTeamSeed = seedings[season.userTeamId];
final userTeamWins = _countWins(season.userTeamId, gamesToUse);

// Log for debugging
print('User team seed: $userTeamSeed, wins: $userTeamWins');

// Verify seeding makes sense
if (userTeamSeed != null && userTeamSeed <= 6) {
  // User should NOT be in play-in
  // Verify they're not in any play-in game
}
```
