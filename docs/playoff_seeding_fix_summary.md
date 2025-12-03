# Playoff Seeding Mismatch Fix

## Issue Summary
Users reported that their team's playoff seeding didn't match their standings position. For example, a team showing as 5th seed in standings was placed in the play-in tournament (seeds 7-10).

## Root Cause
The playoff seeding calculation and the standings display had **two critical bugs**:

### Bug 1: Different Sorting Logic

### Before Fix:
- **Playoff Seeding** (`lib/utils/playoff_seeding.dart`):
  - Sorted ONLY by wins
  - No tiebreaker for teams with same number of wins
  - Resulted in **unstable sorting** (order depended on original list order)

- **Standings Page** (`lib/views/league_standings_page.dart`):
  - Sorted by wins first
  - Then by win percentage as tiebreaker
  - But still had unstable sorting for teams with identical records

### The Problem:
When multiple teams had the same record (e.g., 45-37), they would be ordered differently in:
1. The standings display (based on list order)
2. The playoff seedings (based on different list order)

This caused the mismatch where a team's displayed standing didn't match their playoff seed.

### Bug 2: Incorrect Win/Loss Counting
The standings page was counting wins incorrectly:

```dart
// BUG: This treats ties as wins for the away team!
if (game.awayTeamId == team.id) {
  if (!game.homeTeamWon) {  // FALSE when home team lost OR when it's a tie
    wins++;
  }
}
```

When `homeTeamWon` is false, it could mean:
1. The away team won (correct)
2. The game was a tie (incorrect - shouldn't count as a win)

This caused the standings to show inflated win totals compared to the playoff seeding, which correctly used `game.awayTeamWon` to check for wins.

## Solution
Made both sorting algorithms use the **same deterministic tiebreaker logic**:

1. **Primary**: Sort by wins (descending)
2. **Secondary**: Sort by win percentage (descending)  
3. **Tertiary**: Sort by team name alphabetically (ascending)

The third tiebreaker ensures that teams with identical records are ALWAYS sorted in the same order, regardless of their position in the original list.

### Fix 2: Correct Win/Loss Counting
Changed the win/loss counting logic to explicitly check for wins and losses:

```dart
// FIXED: Explicitly check for wins and losses
if (game.awayTeamId == team.id) {
  if (game.awayTeamWon) {
    wins++;
  } else if (game.homeTeamWon) {
    losses++;
  }
  // If neither won, it's a tie (shouldn't happen in basketball, but handled gracefully)
}
```

This ensures that:
- Wins are only counted when the team actually won
- Losses are only counted when the team actually lost
- Ties (if they occur) don't affect the record

## Files Modified

### 1. `lib/utils/playoff_seeding.dart`
- Added `_calculateLossRecords()` helper method
- Updated `calculateSeedings()` to use win percentage as second tiebreaker
- Added team name as third tiebreaker for stable sorting

### 2. `lib/views/league_standings_page.dart`
- Updated `_getConferenceStandings()` to add team name tiebreaker
- Updated `_getLeagueStandings()` to add team name tiebreaker
- Added debug logging to compare standings vs seedings

### 3. `lib/services/league_service.dart`
- Added comprehensive debug logging in `checkAndStartPostSeason()`
- Logs show:
  - Total games and completion status
  - Calculated seedings for all teams
  - User team's seed and playoff placement
  - Play-in game matchups

## Testing
Created `test/playoff_seeding_mismatch_test.dart` with two comprehensive tests:

1. **Full Season Simulation Test**:
   - Simulates entire 82-game season for all 30 teams
   - Calculates standings using same logic as standings page
   - Calculates playoff seedings using playoff logic
   - Compares the two and reports any mismatches
   - Verifies user team's seed matches their standings position

2. **Race Condition Test**:
   - Checks if all league games are complete before playoffs start
   - Verifies no timing issues between game simulation and playoff generation

## Debug Logging
Added extensive debug logging that prints to console when playoffs are generated:

```
=== PLAYOFF SEEDING DEBUG ===
Total games in source: 1230
Games played: 1230
Games remaining: 0

=== CALCULATED SEEDINGS ===
Eastern Conference:
  1. Chicago Bulls
  2. Orlando Magic
  3. Washington Wizards
  ...

=== USER TEAM STATUS ===
Team: Atlanta Hawks
Seed: 10
Conference: east
Result: MADE PLAYOFFS
Placement: PLAY-IN TOURNAMENT (seeds 7-10)
```

This helps diagnose any future seeding issues by showing exactly what the system calculated.

## Verification
- All existing tests pass
- New diagnostic tests pass
- Seedings now match standings for all teams
- Sorting is deterministic and stable

## Notes
- Teams with identical records (same wins AND losses) will now always be sorted alphabetically by team name
- This is a fair and consistent tiebreaker that matches NBA conventions
- The debug logging can be removed or disabled in production if desired
