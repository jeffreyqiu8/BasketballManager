# Implementation Plan

## Phase 1: Project Cleanup

- [x] 1. Clean up old gameData files





  - Delete obsolete gameData files that conflict with new simplified design
  - Remove: enhanced_game_simulation.dart, enhanced_data_models.dart, development_service.dart, development_system.dart
  - Remove: coaching_service.dart, coaching_effectiveness_service.dart, career_statistics_manager.dart
  - Remove: achievement_system.dart, player_development_tracking.dart, talent_distribution_system.dart
  - Remove: playbook.dart, playbook_service.dart, role_manager.dart
  - Remove: nba_conference_service.dart, nba_team_data.dart, league_expansion_service.dart, league_structure.dart
  - Remove: thirty_team_league_service.dart, conference.dart, coach.dart
  - Remove: game_class.dart, game_service.dart, game_event.dart, game_result.dart, game_result_converter.dart
  - Remove: match_history_service.dart, player_game_stats.dart, team_game_stats.dart, quarter_score.dart
  - Remove: save_manager.dart, save_backup_service.dart, save_creation_data.dart, save_metadata.dart
  - Remove: player.dart, team.dart (old complex versions in gameData)
  - Keep: enums.dart (if it contains useful enums)
  - _Requirements: 8.1, 8.2, 8.3_
-

- [x] 2. Clean up old view pages




  - Delete Firebase-dependent and complex feature pages
  - Remove: auth_wrapper.dart, login_page.dart, profile_page.dart, loading_page.dart
  - Remove: career_statistics_page.dart, coach_profile_page.dart, coaching_effectiveness_dashboard.dart
  - Remove: conference_standings_page.dart, enhanced_schedule_page.dart, match_history_page.dart
  - Remove: playbook_manager_page.dart, player_development_page.dart, role_assignment_page.dart
  - Remove: save_creation_page.dart, save_management_page.dart, manager_creation_page.dart
  - Remove: team_profile_page.dart, team_view_page.dart, player_page.dart
  - Remove: home_page.dart (will be rebuilt from scratch)
  - Remove: widget_tree.dart, accessibility_initializer.dart
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 3. Clean up old widget files





  - Delete complex widgets not needed for simplified design
  - Remove: coach_creation_widget.dart, difficulty_settings_widget.dart, league_settings_widget.dart
  - Remove: team_selection_widget.dart, save_recovery_widget.dart, in_game_strategy_selector.dart
  - Remove: head_to_head_widget.dart, match_history_trends_widget.dart, navbar_widget.dart
  - Remove: lazy_loading_widget.dart, smooth_animations.dart
  - Keep: accessible_widgets.dart, enhanced_tooltips.dart, help_system.dart, user_feedback_system.dart, ui_theme_enhancements.dart (for accessibility)
  - _Requirements: 8.1, 8.2, 8.3_

- [x] 4. Clean up test files





  - Delete tests for removed features
  - Remove: enhanced_game_simulation_test.dart, playbook_service_test.dart, playbook_integration_test.dart
  - Remove: playbook_basic_test.dart, playbook_manager_page_test.dart
  - Remove: nba_team_data_test.dart, nba_conference_service_test.dart, thirty_team_league_test.dart
  - Remove: league_expansion_test.dart, match_history_test.dart, match_history_integration_test.dart, match_history_ui_test.dart
  - Remove: save_system_test.dart, save_backup_recovery_test.dart
  - Remove: game_integration_test.dart, simple_integration_test.dart
  - Remove: user_experience_test.dart, integration_and_performance_summary.md
  - _Requirements: 8.1, 8.2, 8.3_


- [x] 5. Update main.dart for simplified app



  - Remove Firebase initialization
  - Remove auth_wrapper dependency
  - Remove help system and user feedback initialization (will be re-added if needed)
  - Create simple MaterialApp with placeholder home page
  - Remove Firebase dependencies from pubspec.yaml
  - _Requirements: 1.5, 8.1, 8.2_

## Phase 2: Core Implementation

- [x] 6. Set up project structure and core data models
  - Create directory structure (models/, services/, views/)
  - Implement Player model with 8 stats and JSON serialization
  - Implement Team model with 15-player roster and starting lineup management
  - Implement Game model with score tracking
  - Implement Season model with 82-game tracking
  - Add uuid and shared_preferences dependencies to pubspec.yaml
  - _Requirements: 8.1, 8.2, 8.3, 3.1, 2.2, 6.1_

- [x] 7. Implement player generation service





  - Create PlayerGenerator service class in services/
  - Implement random stat generation (0-100 range for all 8 stats)
  - Implement random name generation
  - Implement team roster generation (15 players)
  - Create simple UI page to display generated players with all 8 stats
  - Add accessibility labels to player display
  - _Requirements: 3.1, 3.2, 7.1, 7.2, 9.1, 9.5_

- [ ] 8. Implement league initialization
  - Create LeagueService class in services/
  - Implement 30-team league initialization
  - Assign 15 randomly generated players to each team
  - Create UI page to display all 30 teams
  - Add navigation from home to teams list
  - Implement accessibility features for team list
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 7.2, 9.1_

- [ ] 9. Implement team roster and lineup management
  - Create TeamPage to display single team's 15 players
  - Display all 8 stats for each player with proper formatting
  - Implement visual separation between starting lineup (5) and bench (10)
  - Add lineup selection UI (tap to toggle starter/bench)
  - Validate exactly 5 starters are selected
  - Add accessible labels and semantic structure to roster
  - Ensure WCAG AA color contrast for all text
  - _Requirements: 3.3, 4.1, 4.2, 4.3, 4.4, 9.1, 9.2, 9.5_

- [ ] 10. Implement basic game simulation
  - Create GameService class in services/
  - Implement basic simulation algorithm using team ratings
  - Calculate team rating from starting lineup stats
  - Generate realistic scores (80-120 range) with variance
  - Create GamePage UI to trigger simulation
  - Display game results with both team scores
  - Add accessible announcements for game results
  - Ensure simulation completes within 2 seconds
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 4.5, 9.1_

- [ ] 11. Implement season schedule and progression
  - Implement 82-game schedule generation in GameService
  - Create Season model tracking with wins/losses
  - Update GamePage to show current game number and season progress
  - Display season record (wins-losses) on home page
  - Implement "Play Next Game" functionality
  - Show season completion message after 82 games
  - Add accessible labels for season statistics
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.2, 9.1_

- [ ] 12. Implement local save system
  - Create SaveService class using shared_preferences in services/
  - Implement GameState model with full serialization
  - Implement save game functionality (persist teams, season, user team)
  - Implement load game functionality
  - Implement list all saves functionality
  - Implement delete save functionality
  - Create SavePage UI with save/load/delete buttons
  - Add accessible labels and confirmation dialogs
  - Test save/load cycle preserves all game state
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 3.5, 9.1, 9.4_

- [ ] 13. Create home page and navigation
  - Implement HomePage with main navigation
  - Display user's team name and current record
  - Add "Play Next Game" quick action button
  - Add navigation to Team, Season, and Save pages
  - Implement accessible navigation with semantic labels
  - Ensure all buttons have proper focus indicators
  - Test keyboard navigation flow
  - _Requirements: 7.1, 7.2, 7.3, 9.1, 9.4, 9.5_

- [ ] 14. Implement comprehensive accessibility features
  - Add Semantics widgets to all interactive elements
  - Verify color contrast ratios meet WCAG AA standards
  - Test screen reader navigation on all pages
  - Implement focus management for navigation
  - Add semantic announcements for dynamic content (game results, errors)
  - Create accessible error messages via SnackBar
  - Document accessibility features in code comments
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 15. Polish UI and ensure visual consistency
  - Apply consistent styling across all pages
  - Ensure UI updates render within 100ms
  - Add loading indicators where appropriate
  - Implement proper error handling UI
  - Test all features end-to-end in the app
  - Verify each implemented feature is visible and functional
  - _Requirements: 7.1, 7.3, 7.4, 7.5_

## Phase 3: Testing

- [ ] 16. Write unit tests for core functionality
  - Write tests for Player model serialization
  - Write tests for Team model lineup management
  - Write tests for PlayerGenerator stat ranges
  - Write tests for GameService simulation logic
  - Write tests for SaveService save/load operations
  - _Requirements: 3.1, 4.3, 5.4_

- [ ] 17. Write widget tests for UI components
  - Write tests for PlayerCard widget
  - Write tests for TeamRoster widget
  - Write tests for GameResult widget
  - Write tests for lineup selection validation
  - Verify accessibility labels in widget tests
  - _Requirements: 3.3, 4.4, 9.1_

- [ ] 18. Write integration tests
  - Write test for complete game flow (create → play → save → load)
  - Write test for season progression through multiple games
  - Write test for lineup changes persisting across saves
  - Write test for 82-game season completion
  - _Requirements: 1.1, 1.2, 6.5_
