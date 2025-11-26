# Missed Playoffs Fix

## Problem
Users who missed the playoffs (seeded 11-15 in their conference) were incorrectly being placed in the play-in tournament. This happened because the system was trying to create play-in games for all teams regardless of their seeding.

## Root Cause
The `checkAndStartPostSeason` method in `LeagueService` was creating a playoff bracket for all teams, even those that missed the playoffs. The play-in tournament should only include teams seeded 7-10. Teams seeded 11-15 have missed the playoffs entirely.

## Solution

### 1. Added Validation in PlayoffBracketGenerator
Updated `generatePlayInGames` in `lib/utils/playoff_bracket_generator.dart` to validate that seeds 7-10 exist before creating play-in games. This prevents the system from trying to create play-in games with teams that don't qualify.

```dart
// Validate that seeds 7-10 exist for Eastern Conference
if (!eastTeams.containsKey(7) || !eastTeams.containsKey(8) ||
    !eastTeams.containsKey(9) || !eastTeams.containsKey(10)) {
  throw StateError(
      'Eastern Conference must have teams seeded 7-10 for play-in tournament');
}
```

### 2. Added Check in LeagueService
Updated `checkAndStartPostSeason` in `lib/services/league_service.dart` to check if the user's team made the playoffs before creating a playoff bracket:

```dart
// Check if user's team made the playoffs (seeded 10 or better)
final userTeamSeed = seedings[season.userTeamId];
if (userTeamSeed == null || userTeamSeed > 10) {
  // User's team missed the playoffs (seeded 11-15 or not seeded)
  // Don't create a playoff bracket, just mark season as post-season
  return season.copyWith(isPostSeason: true);
}
```

## Playoff Qualification Rules
- **Seeds 1-6**: Automatically qualify for the first round of playoffs
- **Seeds 7-10**: Qualify for the play-in tournament
  - 7 vs 8: Winner gets 7th seed
  - 9 vs 10: Winner plays loser of 7v8 for 8th seed
- **Seeds 11-15**: Missed the playoffs entirely

## Testing
The home page already has logic to detect when a team missed the playoffs:
- Checks if user is not in any playoff series
- Displays "Missed Playoffs" message
- Shows final record
- Provides button to view playoff bracket

## Files Modified
1. `lib/utils/playoff_bracket_generator.dart` - Added validation for play-in game generation
2. `lib/services/league_service.dart` - Added check to prevent playoff bracket creation for teams that missed playoffs

## Impact
- Teams seeded 11-15 will no longer be incorrectly placed in the play-in tournament
- The system will correctly identify when a team has missed the playoffs
- Users will see the appropriate "Missed Playoffs" message instead of being placed in a play-in game
