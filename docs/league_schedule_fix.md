# League Schedule Fix

## Problem
When creating a new save, the league-wide game simulation was not working properly. Teams were either getting more than 82 games or the league schedule was being lost during season simulation.

## Root Causes

### 1. Schedule Generation Algorithm
The `generateLeagueSchedule` method had a flawed algorithm that didn't properly ensure each team got exactly 82 games. The original logic would:
- Process teams sequentially
- Mark teams as "processed" when they reached 82 games
- But this didn't guarantee all teams would get 82 games

### 2. League Schedule Initialization
The `initializeSeasonWithLeagueSchedule` method was adding the user's 82 games ON TOP OF the already generated league schedule, causing:
- User's team to have more than 82 games
- Opponent teams to also have more than 82 games
- Inconsistent game counts across the league

### 3. Missing League Schedule in Season Updates
When simulating games, the `Season` object was being recreated without preserving the `leagueSchedule` field, causing it to be lost during simulation.

## Solutions

### 1. Improved Schedule Generation
Rewrote the `generateLeagueSchedule` method to use a proper round-robin approach:
- Shuffles teams each round for variety
- Pairs up teams that both need games
- Ensures no team gets more than 82 games
- Continues until all teams have exactly 82 games

### 2. Fixed Schedule Initialization
Changed `initializeSeasonWithLeagueSchedule` to:
- Generate the league schedule first (with all 30 teams)
- Extract the user's 82 games FROM the league schedule
- Use those games as the user's season games
- This ensures the user's games are part of the league schedule, not duplicates

### 3. Preserved League Schedule During Simulation
Updated both `simulateEntireRegularSeason` and `simulateRemainingRegularSeasonGames` to:
- Include `leagueSchedule` field when creating new Season objects
- Properly preserve the league schedule throughout the simulation process

## Testing
All tests now pass:
- `test/league_wide_simulation_test.dart` - Basic league schedule functionality
- `test/league_simulation_integration_test.dart` - End-to-end integration tests
- `test/season_simulation_test.dart` - Season simulation tests

## Result
League-wide game simulation now works correctly:
- Each team gets exactly 82 games
- All 30 teams' records are tracked properly
- League standings show accurate win-loss records
- User's games stay in sync with the league schedule
