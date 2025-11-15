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

- [x] 19. Add blocks and steals attributes to Player model





  - Add blocks field (0-100) to Player model
  - Add steals field (0-100) to Player model
  - Update Player JSON serialization to include blocks and steals
  - Update Player.fromJson to handle blocks and steals
  - Handle backward compatibility for saves without blocks/steals attributes (default to reasonable values)
  - _Requirements: 11.1, 11.2, 11.5_

- [x] 20. Add position role to Player model





  - Add position field to Player model (String: 'PG', 'SG', 'SF', 'PF', 'C')
  - Update Player JSON serialization to include position
  - Update Player.fromJson to handle position
  - Add copyWithPosition method to Player model
  - Handle backward compatibility for saves without position (assign based on attributes)
  - _Requirements: 13.1, 13.2, 13.3_

- [x] 21. Implement position affinity calculation system





  - Create PositionAffinity utility class in utils/
  - Implement calculatePGAffinity method (weights: passing 40%, ballHandling 30%, speed 20%, height penalty)
  - Implement calculateSGAffinity method (weights: shooting 35%, threePoint 35%, speed 20%, height bonus for 73-78")
  - Implement calculateSFAffinity method (weights: shooting 25%, defense 25%, athleticism 25%, height bonus for 76-80")
  - Implement calculatePFAffinity method (weights: rebounding 35%, defense 25%, shooting 20%, height bonus)
  - Implement calculateCAffinity method (weights: rebounding 35%, blocks 30%, defense 25%, height bonus)
  - Add getPositionAffinities method to Player model that returns Map<String, double>
  - Ensure all affinity scores are clamped to 0-100 range
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 14.8_

- [x] 22. Update player generation with height-based attribute modifiers










  - Modify player generation to apply height-based modifiers after base attribute generation
  - For players 80"+ (tall): increase rebounding +15, blocks +20, decrease steals -8, shooting -5, speed -10
  - For players 72" and under (short): increase steals +20, shooting +15, speed +10, decrease rebounding -10, blocks -15
  - Ensure all modified attributes are clamped to 0-100 range
  - Assign initial position based on highest affinity score
  - Test that generated players have realistic attribute distributions for their height
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 23. Update possession simulation with position-based modifiers










  - Modify assist probability calculation to add +15% for PG position
  - Modify three-point attempt probability to add +20% for SG position
  - Modify shot selection for SF position to balance 2PT and 3PT attempts
  - Modify rebound probability to add +15% for PF position
  - Modify rebound probability to add +25% for C position
  - Modify block probability to add +20% for C position
  - Ensure position modifiers stack multiplicatively with attribute-based probabilities
  - Test that position assignments meaningfully affect game statistics
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 11.3, 11.4_

- [ ] 24. Create position assignment UI on TeamPage





  - Add position display to player roster view
  - Create position affinity visualization widget (progress bars for each position)
  - Implement position selector dropdown with affinity percentages
  - Add color-coding for affinity levels (green 80+, yellow 60-79, red <60)
  - Implement position change handler that updates player and saves
  - Add accessible labels for position selector and affinity displays
  - Show visual indicator for player's best-fit position
  - _Requirements: 13.4, 13.5, 14.8_

- [x] 25. Update TeamPage to show position-based roster organization





  - Add option to view roster sorted by position (PG, SG, SF, PF, C)
  - Display starting lineup with position labels
  - Show position distribution summary (e.g., "2 PGs, 3 SGs, 4 SFs, 3 PFs, 3 Cs")
  - Add filter to view players by specific position
  - Ensure position information is visible in season stats view
  - _Requirements: 13.4_

- [x] 26. Test and validate position system end-to-end





  - Generate multiple players and verify height-based attribute modifiers work correctly
  - Verify position affinities are calculated correctly for various player types
  - Test position assignment and verify it persists across save/load
  - Play multiple games and verify position modifiers affect statistics appropriately
  - Verify UI displays position information and affinity scores correctly
  - Test changing player positions and verify gameplay impact
  - Ensure backward compatibility with existing saves
  - _Requirements: 11.5, 12.5, 13.3, 13.5, 14.8, 15.6_

- [x] 27. Expand player name generation lists





  - Expand first names list from 50 to at least 200 unique names
  - Expand last names list from 50 to at least 200 unique names
  - Include diverse basketball player names from various eras and backgrounds
  - Test that name generation produces minimal duplicates across multiple team rosters
  - Verify name combinations create realistic player names
  - _Requirements: 9.3_

- [x] 28. Create player profile page with detailed statistics and information










  - Create PlayerProfilePage widget in views/
  - Display player header with name, position, height, and overall rating
  - Show all 10 player attributes with visual bars (shooting, defense, speed, postShooting, passing, rebounding, ballHandling, threePoint, blocks, steals)
  - Display position affinity scores for all 5 positions with visual indicators
  - Show season statistics if available (PPG, RPG, APG, FG%, 3PT%, FT%, etc.)
  - Display recent game logs (last 5-10 games with stats)
  - Add star rating display relative to team
  - Make player names clickable in TeamPage roster view to navigate to profile
  - Make player names clickable in box score to navigate to profile
  - Add accessible navigation and semantic labels throughout profile page
  - Implement back navigation to return to previous page
  - Add responsive layout for different screen sizes
  - _Requirements: 5.4, 6.5, 10.1, 10.2, 13.4, 14.8_

- [x] 29. Create RoleArchetype model and registry system









  - Create RoleArchetype class in models/ with id, name, position, attributeWeights, and gameplayModifiers
  - Implement calculateFitScore method that weights player attributes
  - Create RoleArchetypeRegistry class in utils/ to manage all role archetypes
  - Define all 4 Point Guard archetypes (All-Around PG, Floor General, Slashing Playmaker, Offensive Point)
  - Define all 3 Shooting Guard archetypes (Three-Level Scorer, 3-and-D, Microwave Shooter)
  - Define all 3 Small Forward archetypes (Point Forward, 3-and-D Wing, Athletic Finisher)
  - Define all 3 Power Forward archetypes (Playmaking Big, Stretch Four, Rim Runner)
  - Define all 3 Center archetypes (Paint Beast, Stretch Five, Standard Center)
  - Implement getArchetypesForPosition method to retrieve archetypes by position
  - Implement getArchetypeById method to retrieve specific archetype
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 17.1-17.17_

- [x] 30. Extend Player model with role archetype support













  - Add optional roleArchetypeId field to Player model
  - Implement getRoleArchetype method that returns RoleArchetype from registry
  - Implement getRoleFitScores method that calculates fit for all position archetypes
  - Implement copyWithRoleArchetype method for updating player role
  - Update Player JSON serialization to include roleArchetypeId
  - Update Player.fromJson to handle roleArchetypeId with backward compatibility
  - _Requirements: 16.7, 18.1, 18.2_

- [x] 31. Update possession simulation with role archetype modifiers









  - Create _getModifiedProbability helper method that applies position and role modifiers
  - Update assist probability calculation to apply role modifiers
  - Update shot attempt probability calculation to apply role modifiers
  - Update three-point attempt probability calculation to apply role modifiers
  - Update post shooting attempt probability calculation to apply role modifiers
  - Update catch-and-shoot probability calculation to apply role modifiers
  - Update steal probability calculation to apply role modifiers
  - Update block probability calculation to apply role modifiers
  - Update rebound probability calculation to apply role modifiers
  - Ensure role modifiers stack multiplicatively with position and attribute modifiers
  - Test that different role assignments produce different statistical outcomes
  - _Requirements: 20.1-20.16_

- [x] 32. Create role selector UI component for TeamPage









  - Create _buildRoleSelector widget that displays current role and dropdown
  - Display all available role archetypes for player's position in dropdown
  - Show fit score percentage next to each role option
  - Add color-coded fit indicator (green 80+, yellow 60-79, red <60)
  - Display key attributes for currently selected role
  - Implement _updatePlayerRole handler that saves role change
  - Add accessible labels for role selector
  - Integrate role selector into existing player roster view on TeamPage
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

- [x] 33. Create role fit analysis section for PlayerProfilePage









  - Create _buildRoleFitSection widget that displays all role archetypes
  - Show fit score circle for each role with color coding
  - Display top 3 key attributes as chips for each role
  - Highlight currently assigned role with visual indicator
  - Make role cards tappable to show detailed role information
  - Create _showRoleDetails dialog with full attribute breakdown and gameplay modifiers
  - Add "Assign Role" button in role details dialog
  - Ensure role fit section is accessible with semantic labels
  - _Requirements: 18.3, 18.4, 18.5, 18.6_

- [x] 34. Add role archetype display to team roster view












  - Display current role archetype name next to player position on roster
  - Add visual badge or icon for role archetype
  - Show abbreviated role name if space is limited
  - Update roster sorting to optionally group by role archetype
  - Add filter to view players by specific role archetype
  - Ensure role information is visible in both roster and season stats views
  - _Requirements: 19.1_

- [x] 35. Test and validate role archetype system end-to-end









  - Assign different role archetypes to players and verify persistence across save/load
  - Play multiple games with different role assignments and verify statistical differences
  - Verify fit scores accurately reflect player attributes
  - Test role selector UI on TeamPage with all positions
  - Test role fit analysis on PlayerProfilePage with various player types
  - Verify role modifiers stack correctly with position and attribute modifiers
  - Test backward compatibility with saves that don't have role assignments
  - Verify UI displays "No role assigned" for players without roles
  - Test that role changes immediately affect next game simulation
  - _Requirements: 16.7, 16.8, 18.1-18.6, 19.1-19.5, 20.16_

- [x] 36. Create post-season data models









  - Create PlayoffSeries model in models/ with id, homeTeamId, awayTeamId, homeWins, awayWins, round, conference, gameIds, isComplete
  - Implement winnerId getter and seriesScore getter in PlayoffSeries
  - Implement copyWithGameResult method to update series after each game
  - Implement JSON serialization for PlayoffSeries
  - Create PlayoffBracket model with seasonId, teamSeedings, teamConferences, playInGames, firstRound, conferenceSemis, conferenceFinals, nbaFinals, currentRound
  - Implement getCurrentRoundSeries, getUserTeamSeries, and isRoundComplete methods in PlayoffBracket
  - Implement JSON serialization for PlayoffBracket
  - Create PlayerPlayoffStats model with same structure as PlayerSeasonStats
  - Implement JSON serialization for PlayerPlayoffStats
  - _Requirements: 21.1, 23.1, 23.2, 23.3, 23.4, 23.5, 26.1, 26.2, 26.4_

- [ ] 37. Extend Season model for post-season support




  - Add optional playoffBracket field to Season model
  - Add optional playoffStats field (Map<String, PlayerPlayoffStats>) to Season model
  - Add isPostSeason boolean field to Season model
  - Implement startPostSeason method that initializes playoff bracket
  - Implement updatePlayoffStats method to accumulate playoff statistics
  - Implement getPlayerPlayoffStats method
  - Update Season JSON serialization to include playoff fields
  - Handle backward compatibility for saves without playoff data
  - _Requirements: 21.1, 26.1, 26.4, 26.5_

- [ ] 38. Implement playoff seeding algorithm




  - Create PlayoffSeeding utility class in utils/
  - Implement calculateSeedings method that computes win-loss records for all teams
  - Separate teams into Eastern and Western conferences (15 teams each)
  - Sort teams by wins within each conference
  - Assign seeds 1-15 to teams in each conference
  - Create helper method to determine team conference based on city
  - Return Map<String, int> with teamId to seed mapping
  - _Requirements: 21.2, 21.3, 21.4_

- [ ] 39. Implement play-in tournament generation




  - Create PlayoffBracketGenerator utility class in utils/
  - Implement generatePlayInGames method that creates 4 play-in series (2 per conference)
  - Create 7 vs 8 seed matchup for Eastern Conference
  - Create 9 vs 10 seed matchup for Eastern Conference
  - Create 7 vs 8 seed matchup for Western Conference
  - Create 9 vs 10 seed matchup for Western Conference
  - Return List<PlayoffSeries> with all play-in games
  - _Requirements: 22.1, 22.2, 22.3_

- [ ] 40. Implement playoff bracket generation and round progression




  - Implement generateFirstRoundSeries method that creates 1v8, 2v7, 3v6, 4v5 matchups per conference
  - Implement resolvePlayIn method that determines seeds 7 and 8 from play-in results
  - Create second play-in game between loser of 7v8 and winner of 9v10
  - Implement generateConferenceSemis method that matches first round winners
  - Implement generateConferenceFinals method that matches conference semi winners
  - Implement generateNBAFinals method that matches conference champions
  - Create PlayoffService class in services/ to manage round progression
  - Implement advancePlayoffRound method that checks completion and generates next round
  - _Requirements: 22.4, 22.5, 22.6, 22.7, 24.1, 24.2, 24.3, 24.4_

- [ ] 41. Implement playoff game simulation




  - Add simulatePlayoffGame method to GameService
  - Use existing simulateGameDetailed for possession simulation
  - Mark game as playoff game with seriesId reference
  - Update PlayoffSeries with game result (increment homeWins or awayWins)
  - Check if series is complete (team reaches 4 wins)
  - Update playoff statistics for all players in the game
  - Return Game object with playoff metadata
  - _Requirements: 23.1, 23.2, 23.3, 23.4, 27.1_

- [ ] 42. Implement season completion detection and post-season trigger




  - Add isRegularSeasonComplete method to LeagueService
  - Check if 82 games have been played (1230 total games across league)
  - Implement checkAndStartPostSeason method called after each game
  - When regular season completes, call Season.startPostSeason with all teams
  - Generate playoff seedings using PlayoffSeeding utility
  - Generate play-in games using PlayoffBracketGenerator
  - Set Season.isPostSeason to true
  - Save updated season state
  - _Requirements: 21.1, 21.2, 21.5_

- [ ] 43. Create PlayoffBracketPage UI




  - Create PlayoffBracketPage widget in views/
  - Display current playoff round name in app bar
  - Implement _buildBracketVisualization with three columns (East, Finals, West)
  - Create _buildConferenceBracket that shows all rounds for one conference
  - Create _buildSeriesCard that displays team matchup with wins
  - Highlight user's team series with colored background
  - Show series score (e.g., "3-2") for ongoing series
  - Display winner for completed series
  - Add accessible labels for all bracket elements
  - Implement navigation to PlayoffBracketPage from HomePage
  - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5_

- [ ] 44. Update HomePage for post-season mode




  - Add conditional rendering based on Season.isPostSeason
  - Display current playoff round name prominently
  - Show user's current series score if team is in playoffs
  - Add "Play Next Playoff Game" button when user's team has next game
  - Show "View Playoff Bracket" button
  - Display "Team Eliminated" message if user's team is out
  - Show championship celebration when user wins NBA Finals
  - Add "Start New Season" button after playoffs complete
  - Update UI to distinguish playoff games from regular season
  - _Requirements: 24.5, 27.1, 27.4, 27.5_

- [ ] 45. Implement non-user playoff game simulation




  - Create simulateNonUserPlayoffGames method in PlayoffService
  - Simulate all games in current round for series not involving user's team
  - Use batch simulation for performance (simulate all at once)
  - Update all PlayoffSeries with results
  - Check if round is complete after simulation
  - Advance to next round if all series are complete
  - Display summary of results to user
  - _Requirements: 27.2, 27.3_

- [ ] 46. Add playoff statistics display to PlayerProfilePage




  - Add "Playoffs" tab to statistics section
  - Display playoff PPG, RPG, APG, steals, blocks, turnovers
  - Show playoff shooting percentages (FG%, 3PT%, FT%)
  - Display games played in playoffs
  - Show "No playoff games played" message if player hasn't played in playoffs
  - Add comparison view between regular season and playoff stats
  - Ensure accessible labels for playoff stats tab
  - _Requirements: 26.2, 26.3_

- [ ] 47. Update TeamPage to show playoff statistics




  - Add playoff statistics tab alongside regular season stats
  - Display playoff stats table with same columns as regular season
  - Show playoff games played for each player
  - Add sortable columns for playoff stats
  - Display "No playoff data" message if team hasn't made playoffs
  - Ensure playoff stats persist and load correctly
  - _Requirements: 26.2, 26.3, 26.4_

- [ ] 48. Implement playoff bracket update after each game




  - Update PlayoffBracket after each playoff game is played
  - Refresh bracket visualization to show updated series scores
  - Check if current series is complete
  - If series complete, check if entire round is complete
  - If round complete, advance to next round automatically
  - Display notification when advancing to next round
  - Update HomePage to reflect new playoff state
  - _Requirements: 25.5, 27.3_

- [ ] 49. Add championship celebration and season completion




  - Detect when NBA Finals series is complete
  - Display championship celebration screen for winner
  - Show championship banner with team name and year
  - Display Finals MVP (player with best playoff stats)
  - Show playoff statistics summary for user's team
  - Add "Start New Season" button to begin next season
  - Reset playoff bracket and playoff stats for new season
  - Preserve championship history in save file
  - _Requirements: 27.4, 27.5, 26.5_

- [ ] 50. Test and validate post-season system end-to-end




  - Play through complete regular season (82 games) and verify post-season triggers
  - Verify playoff seeding is correct based on regular season records
  - Test play-in tournament games and verify seeds 7-8 are determined correctly
  - Play through all playoff rounds and verify bracket progression
  - Test best-of-seven series logic (first to 4 wins advances)
  - Verify playoff statistics are tracked separately from regular season
  - Test non-user playoff games simulate correctly
  - Verify playoff bracket displays correctly at all stages
  - Test championship celebration when winning NBA Finals
  - Verify backward compatibility with saves that don't have playoff data
  - Test starting new season after playoffs complete
  - _Requirements: 21.1-21.5, 22.1-22.7, 23.1-23.5, 24.1-24.5, 25.1-25.5, 26.1-26.5, 27.1-27.5_

- [ ]* 51. Write unit tests for post-season functionality
  - Write tests for PlayoffSeries model and series progression
  - Write tests for PlayoffBracket model and round advancement
  - Write tests for playoff seeding algorithm
  - Write tests for play-in tournament resolution
  - Write tests for playoff statistics accumulation
  - Write tests for season completion detection
  - _Requirements: 21.2, 22.4, 23.3, 26.1_

- [ ]* 52. Write widget tests for playoff UI components
  - Write tests for PlayoffBracketPage rendering
  - Write tests for series card display
  - Write tests for playoff statistics tabs
  - Verify accessibility labels in playoff UI
  - Test championship celebration screen
  - _Requirements: 25.1, 25.4, 26.3_

- [ ]* 53. Write integration tests for complete playoff flow
  - Write test for complete season through playoffs to championship
  - Write test for play-in tournament through to first round
  - Write test for playoff statistics persistence across save/load
  - Write test for non-user playoff game simulation
  - _Requirements: 21.1, 27.1, 27.2, 27.3_
