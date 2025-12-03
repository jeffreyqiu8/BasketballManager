# Play-In Tournament Second Game Bug Fix

## Issue Description

After winning a play-in tournament game (7v8 matchup), the user was incorrectly shown:
1. "Simulate Rest of Playoffs" button - suggesting their season was over
2. An extra play-in series created for them (e.g., Atlanta Hawks vs Boston Celtics 0-0)

This occurred because the system was creating a second play-in game for the **winner** of the 7v8 game, when it should only create a second game for the **loser** of 7v8.

## Root Cause

The `_createSecondPlayInGames` method in `game_page.dart` was not correctly identifying which play-in game was the 7v8 matchup versus the 9v10 matchup. It was simply taking the first two games in the list (`eastGames[0]` and `eastGames[1]`) without checking the team seedings.

According to the NBA play-in format:
- **7 vs 8**: Winner gets 7th seed (goes directly to first round)
- **9 vs 10**: Winner advances to play the loser of 7v8  
- **Loser of 7v8 vs Winner of 9v10**: Winner gets 8th seed

The bug caused the system to create a second play-in game using the wrong teams, resulting in the winner of 7v8 being placed in another play-in game instead of advancing to the first round.

## Solution

Added a new helper method `_identifyGame78` that correctly identifies the 7v8 game by checking team seedings:

```dart
/// Identify the 7v8 game from a list of play-in games
/// The 7v8 game is the one where both teams have seeds 7 or 8
PlayoffSeries _identifyGame78(List<PlayoffSeries> games, Map<String, int> seedings) {
  for (var game in games) {
    final homeSeed = seedings[game.homeTeamId] ?? 0;
    final awaySeed = seedings[game.awayTeamId] ?? 0;
    
    // Check if this is the 7v8 game (both teams are seed 7 or 8)
    if ((homeSeed == 7 || homeSeed == 8) && (awaySeed == 7 || awaySeed == 8)) {
      return game;
    }
  }
  
  // Fallback to first game if we can't identify (shouldn't happen)
  return games.first;
}
```

Updated `_createSecondPlayInGames` to use this helper:

```dart
// Create second play-in game for East (loser of 7v8 vs winner of 9v10)
if (eastGames.length == 2 && eastGames.every((g) => g.isComplete)) {
  // Identify which game is 7v8 and which is 9v10 based on seedings
  final game78 = _identifyGame78(eastGames, bracket.teamSeedings);
  final game910 = eastGames.firstWhere((g) => g.id != game78.id);
  
  final eastSecondGame = PlayoffService.createSecondPlayInGame(
    game78,
    game910,
    'east',
  );
  playInGames.add(eastSecondGame);
}
```

## Result

Now when a team wins the 7v8 play-in game:
- They correctly advance to the first round as the 7th seed
- No extra play-in game is created for them
- The second play-in game is only created between the **loser** of 7v8 and the **winner** of 9v10
- The user sees the correct playoff status and can continue playing

## Testing

All existing tests pass, including:
- `test/playoff_integration_test.dart` (4 tests)
- `test/end_to_end_playoff_test.dart` (11 tests)
- `test/playoff_service_test.dart` (31 tests)
- `test/season_playoff_test.dart` (11 tests)

Total: 57 tests passing
