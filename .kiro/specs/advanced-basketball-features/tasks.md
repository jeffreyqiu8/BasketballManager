# Implementation Plan

- [x] 1. Create player statistics models





  - Create PlayerGameStats model in models/ with points, rebounds, assists, FG stats, 3PT stats
  - Implement JSON serialization for PlayerGameStats
  - Create PlayerSeasonStats model with cumulative tracking and per-game averages
  - Implement addGameStats method to accumulate statistics
  - Implement JSON serialization for PlayerSeasonStats
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 6.1, 6.2, 6.3_

- [x] 2. Extend Game and Season models for statistics




  - Add optional boxScore field to Game model (Map<String, PlayerGameStats>)
  - Add copyWithBoxScore method to Game model
  - Update Game JSON serialization to include boxScore
  - Add optional seasonStats field to Season model (Map<String, PlayerSeasonStats>)
  - Implement updateSeasonStats method in Season model
  - Implement getPlayerStats method in Season model
  - Update Season JSON serialization to include seasonStats
  - _Requirements: 5.1, 5.2, 6.4, 6.5_

- [x] 3. Implement possession-by-possession simulation





  - Create PossessionSimulation helper class in services/
  - Implement possession loop (~200 possessions per game)
  - Implement shooter selection weighted by attributes
  - Implement shot type determination (2PT vs 3PT based on threePoint attribute)
  - Implement shot success calculation using shooting/threePoint attributes
  - Implement rebound logic using rebounding attributes
  - Implement turnover logic using ballHandling attributes
  - Implement assist logic using passing attributes
  - Record PlayerGameStats for each player during simulation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 4. Add detailed simulation method to GameService





  - Add simulateGameDetailed method to GameService
  - Integrate PossessionSimulation into GameService
  - Return Game object with populated boxScore
  - Ensure simulation completes within 3 seconds
  - Update existing simulateGame to use new system or keep as fallback
  - _Requirements: 2.1, 2.5, 5.5, 8.1, 8.2, 8.3, 8.4_


- [x] 5. Add team selection to save creation flow





  - Create team selection dialog widget in views/save_page.dart
  - Display all 30 teams with city, name, and rating
  - Implement team selection with accessible labels
  - Add search/filter functionality for teams
  - Update save creation to require team selection
  - Pass selected team ID to league initialization
  - Update UI to show loading indicator during team selection
  - Test keyboard navigation in team selection dialog
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 10.1, 10.2, 10.3, 10.4_

- [x] 6. Display box score after game simulation





  - Create box score widget in views/game_page.dart
  - Display player statistics table (Name, PTS, REB, AST, FG%, 3PT%)
  - Sort players by points descending
  - Add accessible table structure with semantic labels
  - Show team totals at bottom of box score
  - Add color-coded performance indicators
  - Ensure WCAG AA color contrast standards
  - Update GamePage to show box score after simulation
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 10.1, 10.2, 10.5_

- [x] 7. Integrate season statistics tracking





  - Update game simulation flow to call Season.updateSeasonStats
  - Ensure season stats persist in save files
  - Test statistics accumulation across multiple games
  - Verify season stats load correctly from saved games
  - Handle null/missing stats gracefully for backward compatibility
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 8. Add season statistics display to TeamPage








  - Create season stats tab in TeamPage
  - Display season statistics table (Name, PPG, RPG, APG, FG%, 3PT%)
  - Add sortable columns with accessible sort indicators
  - Show games played for each player
  - Implement tab navigation between Roster and Season Stats
  - Add accessible labels for tab navigation
  - Ensure table is keyboard navigable
  - _Requirements: 6.2, 6.3, 6.4, 6.5, 10.1, 10.2, 10.3_

- [x] 9. Update HomePage to reflect new features





  - Update HomePage to show selected team name
  - Ensure "Play Next Game" uses detailed simulation
  - Update season record display to be more prominent
  - Add quick link to view season statistics
  - Test all navigation flows from HomePage
  - _Requirements: 8.5, 9.1, 9.2_


- [x] 10. Polish and test all features end-to-end





  - Test complete flow: create save with team selection → play game → view box score → view season stats
  - Verify statistics persist across save/load cycles
  - Test multiple games to ensure season stats accumulate correctly
  - Verify all accessibility features work with screen readers
  - Test keyboard navigation on all new UI elements
  - Ensure all simulations complete within 3 seconds
  - Verify backward compatibility with existing saves
  - Test error handling for edge cases
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4, 9.5, 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ]* 11. Write unit tests for new functionality
  - Write tests for PlayerGameStats and PlayerSeasonStats models
  - Write tests for possession simulation logic
  - Write tests for attribute influence on outcomes
  - Write tests for season stats accumulation
  - Write tests for box score serialization
  - _Requirements: 3.1, 3.2, 3.3, 7.1, 7.2, 7.3_

- [ ]* 12. Write widget tests for new UI components
  - Write tests for team selection dialog
  - Write tests for box score display
  - Write tests for season stats table
  - Verify accessibility labels in widget tests
  - Test sorting functionality in statistics tables
  - _Requirements: 5.4, 10.1, 10.2_

- [ ]* 13. Write integration tests
  - Write test for complete game flow with statistics
  - Write test for season progression with stat tracking
  - Write test for save/load with team selection and statistics
  - Write test for multiple games accumulating season stats correctly
  - _Requirements: 1.5, 6.5, 8.4_

- [x] 14. Enhance PlayerGameStats model with advanced statistics





  - Add turnovers field to PlayerGameStats model
  - Add steals field to PlayerGameStats model
  - Add blocks field to PlayerGameStats model
  - Add fouls field to PlayerGameStats model
  - Add freeThrowsMade field to PlayerGameStats model
  - Add freeThrowsAttempted field to PlayerGameStats model
  - Add freeThrowPercentage getter to PlayerGameStats model
  - Update PlayerGameStats JSON serialization to include new fields
  - Handle backward compatibility for old saves without new stats

- [x] 15. Enhance PlayerSeasonStats model with advanced statistics





  - Add totalTurnovers field to PlayerSeasonStats model
  - Add totalSteals field to PlayerSeasonStats model
  - Add totalBlocks field to PlayerSeasonStats model
  - Add totalFouls field to PlayerSeasonStats model
  - Add totalFreeThrowsMade field to PlayerSeasonStats model
  - Add totalFreeThrowsAttempted field to PlayerSeasonStats model
  - Add per-game average getters (turnoversPerGame, stealsPerGame, blocksPerGame, foulsPerGame)
  - Add freeThrowPercentage getter to PlayerSeasonStats model
  - Update addGameStats method to accumulate new statistics
  - Update PlayerSeasonStats JSON serialization to include new fields
  - Handle backward compatibility for old saves without new stats

- [x] 16. Enhance possession simulation with advanced gameplay mechanics





  - Update _MutablePlayerStats to track turnovers, steals, blocks, fouls, and free throws
  - Implement steal logic in possession simulation (defenders can steal based on defense attribute)
  - Record turnovers when steals occur
  - Implement foul logic during shot attempts (based on defense aggressiveness)
  - Implement free throw simulation after fouls (based on shooter's shooting attribute)
  - Implement block logic for shot attempts (based on defender's defense and height)
  - Record blocks when shots are blocked
  - Update turnover tracking to record player who committed turnover
  - Ensure free throw points are added to score and player stats
  - Update toPlayerGameStats method to include all new statistics

- [x] 17. Update box score display with advanced statistics





  - Add TO (turnovers) column to box score table
  - Add STL (steals) column to box score table
  - Add BLK (blocks) column to box score table
  - Add PF (personal fouls) column to box score table
  - Add FT (free throws made/attempted) column to box score table
  - Add FT% (free throw percentage) column to box score table
  - Update team totals to include new statistics
  - Update accessible labels to include new stat columns
  - Adjust table layout to accommodate additional columns (consider responsive design)
  - Update high-performance indicators for new stats (e.g., 3+ steals, 2+ blocks)

- [x] 18. Update season statistics display with advanced statistics





  - Add turnovers per game column to season stats table
  - Add steals per game column to season stats table
  - Add blocks per game column to season stats table
  - Add fouls per game column to season stats table
  - Add free throw percentage column to season stats table
  - Update sortable columns to include new statistics
  - Update accessible labels for new stat columns
  - Test sorting functionality with new statistics
