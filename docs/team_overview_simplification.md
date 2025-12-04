# Team Overview Page Simplification

## Issue
When starting a new save, the team overview page's starting lineup view didn't reflect the actual starting lineup correctly, causing confusion.

## Solution
Simplified the roster tab to show a simple list of all players without separating starters and bench.

## Changes Made

### 1. Updated Roster Sort Modes
- **Before**: `lineup` (starters first, then bench) and `position` (by position)
- **After**: `all` (all players in one list) and `position` (by position)

### 2. Simplified Player List Display
- **Before**: Separated players into "Starting Lineup" and "Bench" sections
- **After**: Shows all players in a single "All Players" list

### 3. Updated Position View
- **Before**: Within each position, separated starters and bench
- **After**: Shows all players for each position together

## Benefits
1. **Clearer**: No confusion about starting lineup status
2. **Simpler**: One unified view of all players
3. **Consistent**: Rotation information is shown via badges on player cards
4. **Focused**: Users should use the dedicated Lineup Page to manage starters

## User Experience
- Players can still see rotation status via badges on player cards
- The "Edit Lineup" button navigates to the dedicated Lineup Page for managing starters
- The roster tab is now purely for browsing and viewing player information
- Rotation summary card still shows starting lineup and key rotation players

## Files Modified
- `lib/views/team_overview_page.dart`
  - Updated `_RosterSortMode` enum
  - Simplified `_buildLineupView()` method
  - Simplified `_buildPositionView()` method
  - Updated default sort mode to `all`
  - Updated segmented button labels

## Testing
All existing tests pass, confirming the changes maintain functionality while improving clarity.
