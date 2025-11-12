# Manual Testing Checklist for Advanced Basketball Features

This checklist covers manual testing requirements for task 10 that cannot be fully automated.

## Complete Flow Test

### 1. Create Save with Team Selection
- [ ] Launch the app
- [ ] Click "New Save" button
- [ ] Enter a save name
- [ ] Verify team selection dialog appears with all 30 teams
- [ ] Verify each team shows: city, name, and rating
- [ ] Search/filter functionality works (if implemented)
- [ ] Select a team (e.g., "Los Angeles Lakers")
- [ ] Verify save is created successfully
- [ ] Verify selected team name appears on home page

### 2. Play Game and View Box Score
- [ ] Click "Play Next Game" button
- [ ] Verify simulation completes quickly (< 3 seconds)
- [ ] Verify game result is displayed
- [ ] Verify box score table appears with columns:
  - Player Name
  - PTS (Points)
  - REB (Rebounds)
  - AST (Assists)
  - FG% (Field Goal Percentage)
  - 3PT% (Three-Point Percentage)
- [ ] Verify players are sorted by points (descending)
- [ ] Verify team totals appear at bottom
- [ ] Verify statistics are realistic (no negative values, reasonable ranges)

### 3. View Season Statistics
- [ ] Navigate to Team Page
- [ ] Verify "Season Stats" tab exists
- [ ] Click "Season Stats" tab
- [ ] Verify season statistics table appears with columns:
  - Player Name
  - PPG (Points Per Game)
  - RPG (Rebounds Per Game)
  - APG (Assists Per Game)
  - FG% (Field Goal Percentage)
  - 3PT% (Three-Point Percentage)
  - GP (Games Played)
- [ ] Verify statistics match the game just played (1 game played)
- [ ] Verify per-game averages are calculated correctly

### 4. Statistics Persistence
- [ ] Return to home page
- [ ] Save the game (should auto-save)
- [ ] Close and reopen the app
- [ ] Load the save file
- [ ] Navigate to Team Page → Season Stats
- [ ] Verify season statistics are still present
- [ ] Verify statistics match what was shown before

### 5. Multiple Games Accumulation
- [ ] Play 3-5 more games
- [ ] After each game, check box score appears
- [ ] Navigate to Season Stats after multiple games
- [ ] Verify games played count increases
- [ ] Verify per-game averages update correctly
- [ ] Verify total statistics accumulate (not reset)

## Performance Testing

### Simulation Speed
- [ ] Play 10 games in succession
- [ ] Verify each simulation completes within 3 seconds
- [ ] Verify no noticeable lag or freezing
- [ ] Verify UI remains responsive during simulation

## Backward Compatibility Testing

### Old Save Files
If you have old save files from before the advanced features:
- [ ] Load an old save file
- [ ] Verify it loads without errors
- [ ] Verify you can play games normally
- [ ] Verify box scores appear for new games
- [ ] Verify season stats start accumulating from zero

## Accessibility Testing

### Screen Reader Support
With a screen reader enabled (e.g., NVDA, JAWS, TalkBack):

#### Team Selection Dialog
- [ ] Navigate to team selection dialog
- [ ] Verify each team option is announced with city, name, and rating
- [ ] Verify keyboard navigation works (Tab, Arrow keys)
- [ ] Verify Enter key selects a team
- [ ] Verify Escape key closes dialog

#### Box Score Table
- [ ] Navigate to box score after game
- [ ] Verify table structure is announced (headers, rows, cells)
- [ ] Verify column headers are announced when navigating cells
- [ ] Verify player names and statistics are announced clearly
- [ ] Verify team totals are announced

#### Season Statistics Table
- [ ] Navigate to season stats tab
- [ ] Verify tab navigation is announced
- [ ] Verify table structure is announced
- [ ] Verify sortable columns have sort indicators
- [ ] Verify sort order changes are announced

### Keyboard Navigation
Without using a mouse:

#### Team Selection
- [ ] Tab to team selection dialog
- [ ] Use arrow keys to navigate teams
- [ ] Use Enter to select a team
- [ ] Use Escape to cancel

#### Box Score
- [ ] Tab through box score table
- [ ] Verify focus indicators are visible
- [ ] Verify all interactive elements are reachable

#### Season Stats
- [ ] Tab to season stats tab
- [ ] Use arrow keys or Tab to navigate table
- [ ] If sortable, verify keyboard can trigger sort
- [ ] Verify focus indicators are visible

### Color Contrast
- [ ] Verify all text is readable against backgrounds
- [ ] Verify statistics tables have good contrast
- [ ] Verify color-coded performance indicators (if any) also have text/icons
- [ ] Test in both light and dark mode (if supported)

## Error Handling

### Edge Cases
- [ ] Try to create save without selecting a team (should show error)
- [ ] Try to play game when season is complete (should handle gracefully)
- [ ] Load a corrupted save file (should show error message)
- [ ] Verify error messages are accessible (announced by screen readers)

## UI Polish

### Visual Quality
- [ ] Verify all tables are properly aligned
- [ ] Verify statistics are formatted consistently (decimals, percentages)
- [ ] Verify loading indicators appear during simulation
- [ ] Verify success/error messages are clear and visible
- [ ] Verify no UI elements overlap or clip

### Responsive Design
- [ ] Test on different screen sizes (if applicable)
- [ ] Verify tables scroll horizontally if needed
- [ ] Verify all content is accessible on smaller screens

## Results Summary

Date Tested: _______________
Tester: _______________

### Issues Found
List any issues discovered during manual testing:

1. 
2. 
3. 

### Overall Assessment
- [ ] All features work as expected
- [ ] Performance meets requirements (< 3 seconds)
- [ ] Accessibility features are functional
- [ ] No critical bugs found

### Notes
Additional observations or comments:


