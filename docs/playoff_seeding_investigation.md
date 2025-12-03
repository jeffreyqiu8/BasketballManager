# Playoff Seeding Investigation

## Issue
User (Atlanta Hawks) finished 5th in Eastern Conference with 43-39 record, but is being placed in play-in tournament against Orlando Magic.

## Expected Behavior
- Seeds 1-6: Go directly to first round (wait for play-in to complete)
- Seeds 7-10: Participate in play-in tournament  
- Seeds 11-15: Eliminated (missed playoffs)

## Observed Standings
Eastern Conference:
1. Washington (51-31)
2. Toronto (47-35)
3. Boston (44-38)
4. Indiana (44-38)
5. **Atlanta Hawks (43-39)** ← User's team (should NOT be in play-in)
6. Charlotte (41-41)
7. Detroit (41-41)
8. Orlando (41-41)
9. Miami (40-42)
10. Milwaukee (40-42)

## Observed Play-In Bracket
- Orlando Magic vs **Atlanta Hawks** (WRONG - Hawks are 5th seed)
- Detroit Pistons vs Miami Heat

## Expected Play-In Bracket
Should be:
- 7v8: Detroit vs Orlando (or Charlotte vs Orlando, depending on tie-breaker)
- 9v10: Miami vs Milwaukee

## Investigation Needed
1. Check if seeding calculation is using correct games (league schedule vs user games)
2. Verify tie-breaking logic for teams with same record
3. Check if play-in game generation is using correct seeds
4. Verify that generatePlayInGames is only creating games for seeds 7-10

## Next Steps
1. Add logging to see actual seedings calculated
2. Verify which games are being used for seeding calculation
3. Check if there's a mismatch between league schedule and user's game list
