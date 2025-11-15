# Requirements Document

## Introduction

This document outlines the requirements for advanced features in the basketball manager application. These features build upon the existing simplified basketball manager by adding team selection for saves, possession-by-possession match simulation, and player statistics tracking. The implementation maintains the core design principles of simplicity, offline-first functionality, and accessibility while adding depth to gameplay.

## Glossary

- **Application**: The basketball manager Flutter application
- **User**: The person playing the basketball manager game
- **Save System**: The local storage mechanism for persisting game state
- **User Team**: The team selected by the User to manage in a save file
- **Possession**: A single offensive opportunity in basketball where one team attempts to score
- **Match Simulation**: The algorithmic process that determines game outcomes possession by possession
- **Player Statistics**: Tracked performance metrics including points, rebounds, assists, field goal percentage, and three-point percentage
- **Player Attributes**: The 8 inherent abilities of a player (shooting, defense, speed, stamina, passing, rebounding, ball handling, three-point)
- **Box Score**: The statistical summary of a player's performance in a game
- **Season Statistics**: Cumulative player statistics across all games in a season
- **Position Role**: One of five basketball positions (PG, SG, SF, PF, C) that defines a player's primary role on the team
- **Position Affinity**: A calculated score (0-100) indicating how well-suited a player is for a specific position based on their attributes and height
- **Blocks Attribute**: A player's ability to block opponent shots (0-100)
- **Steals Attribute**: A player's ability to steal the ball from opponents (0-100)
- **Post-Season**: The playoff tournament that occurs after the 82-game regular season
- **Play-In Tournament**: Games between seeds 7-10 in each conference to determine the final two playoff spots
- **Playoff Series**: A best-of-seven matchup between two teams where the first to win 4 games advances
- **Conference**: One of two divisions (Eastern or Western) that teams are organized into for playoff seeding
- **Playoff Bracket**: The visual tournament structure showing all playoff matchups and results
- **Playoff Round**: One stage of the post-season (First Round, Conference Semifinals, Conference Finals, NBA Finals)

## Requirements

### Requirement 1

**User Story:** As a User, I want to select which team I manage when creating a new save, so that I can choose my favorite team or try different team challenges.

#### Acceptance Criteria

1. WHEN creating a new save, THE Application SHALL display a list of all 30 teams for selection
2. THE Application SHALL require the User to select exactly one team before creating the save
3. THE Application SHALL associate the selected team with the save file
4. THE Application SHALL persist the User's team selection in the save data
5. THE Application SHALL load the correct User team when loading a save file

### Requirement 2

**User Story:** As a User, I want match simulation to occur possession by possession, so that I can experience more realistic and detailed game outcomes.

#### Acceptance Criteria

1. THE Application SHALL simulate each game as a series of individual possessions
2. WHEN a possession is simulated, THE Application SHALL determine which team gains possession
3. THE Application SHALL calculate the outcome of each possession (score, miss, turnover)
4. THE Application SHALL alternate possessions between teams based on possession outcomes
5. THE Application SHALL continue possession simulation until game time expires

### Requirement 3

**User Story:** As a User, I want possession outcomes to be influenced by player attributes, so that player abilities meaningfully affect game results.

#### Acceptance Criteria

1. THE Application SHALL use player shooting attributes to calculate field goal success probability
2. THE Application SHALL use player three-point attributes to calculate three-point success probability
3. THE Application SHALL use player ball handling attributes to calculate turnover probability
4. THE Application SHALL use player rebounding attributes to calculate offensive rebound probability
5. THE Application SHALL use player defense attributes to affect opponent possession outcomes

### Requirement 4

**User Story:** As a User, I want to see player statistics including points, rebounds, assists, field goal percentage, and three-point percentage, so that I can evaluate player performance.

#### Acceptance Criteria

1. THE Application SHALL track points scored for each player during game simulation
2. THE Application SHALL track rebounds collected for each player during game simulation
3. THE Application SHALL track assists made for each player during game simulation
4. THE Application SHALL calculate field goal percentage for each player
5. THE Application SHALL calculate three-point percentage for each player

### Requirement 5

**User Story:** As a User, I want to view player statistics after each game, so that I can see how my players performed.

#### Acceptance Criteria

1. WHEN a game is completed, THE Application SHALL display a box score with all player statistics
2. THE Application SHALL show statistics for all players who participated in the game
3. THE Application SHALL display points, rebounds, assists, field goal percentage, and three-point percentage
4. THE Application SHALL format statistics in an easily readable layout
5. THE Application SHALL include accessible labels for all statistical displays

### Requirement 6

**User Story:** As a User, I want to view season-long statistics for my players, so that I can track performance trends over time.

#### Acceptance Criteria

1. THE Application SHALL accumulate player statistics across all games in a season
2. THE Application SHALL calculate season averages for points, rebounds, and assists per game
3. THE Application SHALL calculate season field goal percentage and three-point percentage
4. THE Application SHALL display season statistics on the team page
5. THE Application SHALL persist season statistics in save files

### Requirement 7

**User Story:** As a User, I want player attributes to indirectly affect statistics through possession outcomes, so that better players naturally produce better statistics.

#### Acceptance Criteria

1. WHEN a player has high shooting attributes, THE Application SHALL increase their probability of successful field goals
2. WHEN a player has high three-point attributes, THE Application SHALL increase their probability of successful three-point shots
3. WHEN a player has high rebounding attributes, THE Application SHALL increase their probability of collecting rebounds
4. WHEN a player has high passing attributes, THE Application SHALL increase their probability of recording assists
5. THE Application SHALL ensure statistical outcomes reflect the cumulative effect of player attributes

### Requirement 8

**User Story:** As a User, I want the possession-by-possession simulation to complete quickly, so that I can play through games without long wait times.

#### Acceptance Criteria

1. THE Application SHALL complete possession-by-possession simulation within 3 seconds per game
2. THE Application SHALL provide visual feedback during simulation
3. THE Application SHALL not block the UI during simulation
4. THE Application SHALL allow the User to view results immediately after simulation completes
5. THE Application SHALL maintain the same performance standards as the basic simulation

### Requirement 9

**User Story:** As a User, I want all new features to maintain the simple class structure, so that the codebase remains easy to understand and maintain.

#### Acceptance Criteria

1. THE Application SHALL add new functionality to existing service classes where appropriate
2. THE Application SHALL create new classes only when necessary for single responsibility
3. THE Application SHALL use clear and descriptive names for new classes and methods
4. THE Application SHALL minimize dependencies between new and existing components
5. THE Application SHALL document all new classes and methods with their purpose

### Requirement 10

**User Story:** As a User, I want all new UI elements to be accessible, so that the application remains usable for all users.

#### Acceptance Criteria

1. THE Application SHALL include semantic labels for all new interactive elements
2. THE Application SHALL maintain WCAG AA color contrast standards for new UI components
3. THE Application SHALL support screen reader navigation for team selection and statistics displays
4. THE Application SHALL provide keyboard navigation for team selection
5. THE Application SHALL announce statistical updates accessibly after game completion

### Requirement 11

**User Story:** As a User, I want players to have block and steal attributes, so that defensive abilities are more detailed and realistic.

#### Acceptance Criteria

1. THE Application SHALL add a blocks attribute (0-100) to the Player model
2. THE Application SHALL add a steals attribute (0-100) to the Player model
3. THE Application SHALL use the blocks attribute to calculate block probability during possession simulation
4. THE Application SHALL use the steals attribute to calculate steal probability during possession simulation
5. THE Application SHALL persist blocks and steals attributes in save files

### Requirement 12

**User Story:** As a User, I want player generation to consider height when assigning attributes, so that taller players naturally excel at blocking and rebounding while shorter players excel at steals and shooting.

#### Acceptance Criteria

1. WHEN generating a player with height above 78 inches, THE Application SHALL increase rebounding and blocks attributes by 10-20 points
2. WHEN generating a player with height above 78 inches, THE Application SHALL decrease steals and shooting attributes by 5-10 points
3. WHEN generating a player with height below 74 inches, THE Application SHALL increase steals and shooting attributes by 10-20 points
4. WHEN generating a player with height below 74 inches, THE Application SHALL decrease rebounding and blocks attributes by 5-10 points
5. THE Application SHALL ensure all attribute adjustments keep values within 0-100 range

### Requirement 13

**User Story:** As a User, I want each player to have a position role (PG, SG, SF, PF, C), so that I can organize my team by traditional basketball positions.

#### Acceptance Criteria

1. THE Application SHALL define five position roles: PG (Point Guard), SG (Shooting Guard), SF (Small Forward), PF (Power Forward), C (Center)
2. THE Application SHALL assign each player a primary position during generation
3. THE Application SHALL persist player positions in save files
4. THE Application SHALL display player positions on the team roster screen
5. THE Application SHALL allow the User to view and change player positions on the team screen

### Requirement 14

**User Story:** As a User, I want to see each player's affinity for each position role, so that I can make informed decisions about position assignments.

#### Acceptance Criteria

1. THE Application SHALL calculate position affinity scores (0-100) for all five positions for each player
2. WHEN calculating PG affinity, THE Application SHALL weight passing, ballHandling, and speed attributes most heavily
3. WHEN calculating SG affinity, THE Application SHALL weight shooting, threePoint, and speed attributes most heavily
4. WHEN calculating SF affinity, THE Application SHALL weight shooting, defense, and athleticism (speed + stamina) attributes most heavily
5. WHEN calculating PF affinity, THE Application SHALL weight rebounding, defense, and shooting attributes most heavily
6. WHEN calculating C affinity, THE Application SHALL weight rebounding, blocks, and defense attributes most heavily
7. THE Application SHALL consider player height when calculating position affinities (shorter players favor guard positions, taller players favor forward/center positions)
8. THE Application SHALL display affinity scores for all positions on the team screen

### Requirement 15

**User Story:** As a User, I want player positions to affect their statistical outcomes during games, so that position assignments have meaningful gameplay impact.

#### Acceptance Criteria

1. WHEN a player is assigned to PG position, THE Application SHALL increase their probability of recording assists by 15%
2. WHEN a player is assigned to SG position, THE Application SHALL increase their probability of attempting three-point shots by 20%
3. WHEN a player is assigned to SF position, THE Application SHALL balance their shot attempts between two-point and three-point shots
4. WHEN a player is assigned to PF position, THE Application SHALL increase their probability of attempting rebounds by 15%
5. WHEN a player is assigned to C position, THE Application SHALL increase their probability of attempting rebounds by 25% and blocks by 20%
6. THE Application SHALL ensure position modifiers stack with player attributes to determine final probabilities

### Requirement 16

**User Story:** As a User, I want to assign specific role archetypes to players within their position, so that I can define specialized playstyles that emphasize different attributes.

#### Acceptance Criteria

1. THE Application SHALL define multiple role archetypes for each of the five positions
2. THE Application SHALL define four role archetypes for Point Guard position: All-Around PG, Floor General, Slashing Playmaker, and Offensive Point
3. THE Application SHALL define three role archetypes for Shooting Guard position: Three-Level Scorer, 3-and-D, and Microwave Shooter
4. THE Application SHALL define three role archetypes for Small Forward position: Point Forward, 3-and-D Wing, and Athletic Finisher
5. THE Application SHALL define three role archetypes for Power Forward position: Playmaking Big, Stretch Four, and Rim Runner
6. THE Application SHALL define three role archetypes for Center position: Paint Beast, Stretch Five, and Standard Center
7. THE Application SHALL persist player role archetype assignments in save files
8. THE Application SHALL allow the User to change a player's role archetype on the team screen

### Requirement 17

**User Story:** As a User, I want each role archetype to highlight specific attributes that are important for that playstyle, so that I can understand what makes a player effective in that role.

#### Acceptance Criteria

1. WHEN viewing a role archetype, THE Application SHALL display which attributes are most important for that role
2. THE Application SHALL define All-Around PG as emphasizing balanced attributes across passing, shooting, ball handling, and speed
3. THE Application SHALL define Floor General as emphasizing passing and ball handling with reduced shooting emphasis
4. THE Application SHALL define Slashing Playmaker as emphasizing post shooting, speed, and ball handling with reduced three-point emphasis
5. THE Application SHALL define Offensive Point as emphasizing shooting and three-point with slightly reduced passing emphasis
6. THE Application SHALL define Three-Level Scorer as emphasizing shooting, three-point, and ball handling with reduced passing emphasis
7. THE Application SHALL define 3-and-D (SG) as emphasizing three-point, defense, and steals
8. THE Application SHALL define Microwave Shooter as emphasizing shooting and three-point with reduced ball handling emphasis
9. THE Application SHALL define Point Forward as emphasizing passing and ball handling with reduced post shooting emphasis
10. THE Application SHALL define 3-and-D Wing as emphasizing three-point, defense, steals, blocks, and rebounding
11. THE Application SHALL define Athletic Finisher as emphasizing post shooting, speed, and rebounding with reduced three-point emphasis
12. THE Application SHALL define Playmaking Big as emphasizing passing and rebounding with reduced three-point emphasis
13. THE Application SHALL define Stretch Four as emphasizing three-point and shooting with maintained rebounding
14. THE Application SHALL define Rim Runner as emphasizing post shooting, rebounding, and blocks with minimal three-point emphasis
15. THE Application SHALL define Paint Beast as emphasizing post shooting, blocks, rebounding, and defense with no three-point emphasis
16. THE Application SHALL define Stretch Five as emphasizing three-point, shooting, and rebounding
17. THE Application SHALL define Standard Center as emphasizing balanced interior attributes between Paint Beast and Stretch Five

### Requirement 18

**User Story:** As a User, I want to see how well each player fits different role archetypes, so that I can assign them to roles that match their strengths.

#### Acceptance Criteria

1. THE Application SHALL calculate a fit score (0-100) for each role archetype for every player
2. WHEN calculating fit scores, THE Application SHALL weight the important attributes for each role more heavily
3. THE Application SHALL display fit scores for all role archetypes within a player's position on the player profile page
4. THE Application SHALL allow the User to browse through all role archetypes on the player profile page to see fit scores
5. THE Application SHALL visually highlight the best-fit role archetype for each player
6. THE Application SHALL show which attributes contribute to a player's fit for each role

### Requirement 19

**User Story:** As a User, I want to select role archetypes for players on the team screen, so that I can quickly assign specialized roles to my roster.

#### Acceptance Criteria

1. THE Application SHALL display the current role archetype for each player on the team screen
2. THE Application SHALL provide a role selector on the team screen that shows all available archetypes for the player's position
3. WHEN selecting a role archetype, THE Application SHALL display the fit score for that role
4. THE Application SHALL highlight important attributes for the selected role archetype
5. THE Application SHALL persist role archetype changes immediately to the save file

### Requirement 20

**User Story:** As a User, I want role archetypes to affect gameplay statistics, so that assigning specialized roles has meaningful impact on game outcomes.

#### Acceptance Criteria

1. WHEN a player is assigned the Floor General role, THE Application SHALL increase assist probability by 20% and decrease shot attempt probability by 15%
2. WHEN a player is assigned the Slashing Playmaker role, THE Application SHALL increase post shooting attempt probability by 25% and decrease three-point attempt probability by 20%
3. WHEN a player is assigned the Offensive Point role, THE Application SHALL increase shooting attempt probability by 15% and decrease assist probability by 10%
4. WHEN a player is assigned the Three-Level Scorer role, THE Application SHALL increase shot creation probability by 20% and decrease assist probability by 15%
5. WHEN a player is assigned the 3-and-D (SG) role, THE Application SHALL increase three-point attempt probability by 30%, steal probability by 25%, and defensive impact by 20%
6. WHEN a player is assigned the Microwave Shooter role, THE Application SHALL increase catch-and-shoot probability by 35% and decrease ball handling usage by 25%
7. WHEN a player is assigned the Point Forward role, THE Application SHALL increase assist probability by 25% and decrease post shooting attempt probability by 20%
8. WHEN a player is assigned the 3-and-D Wing role, THE Application SHALL increase three-point attempt probability by 25%, steal probability by 20%, block probability by 15%, and rebound probability by 10%
9. WHEN a player is assigned the Athletic Finisher role, THE Application SHALL increase post shooting attempt probability by 30% and decrease three-point attempt probability by 30%
10. WHEN a player is assigned the Playmaking Big role, THE Application SHALL increase assist probability by 20% and decrease three-point attempt probability by 25%
11. WHEN a player is assigned the Stretch Four role, THE Application SHALL increase three-point attempt probability by 25%
12. WHEN a player is assigned the Rim Runner role, THE Application SHALL increase post shooting attempt probability by 35%, rebound probability by 20%, and decrease three-point attempt probability by 90%
13. WHEN a player is assigned the Paint Beast role, THE Application SHALL increase post shooting attempt probability by 30%, block probability by 35%, and eliminate three-point attempts
14. WHEN a player is assigned the Stretch Five role, THE Application SHALL increase three-point attempt probability by 30% and maintain rebound probability
15. WHEN a player is assigned the Standard Center role, THE Application SHALL balance interior scoring and rebounding with moderate three-point attempts
16. THE Application SHALL ensure role archetype modifiers stack with position modifiers and player attributes

### Requirement 21

**User Story:** As a User, I want a post-season tournament after 82 regular season games, so that I can compete for a championship like in the NBA.

#### Acceptance Criteria

1. WHEN the regular season reaches 82 games, THE Application SHALL trigger the post-season tournament
2. THE Application SHALL seed all 30 teams based on regular season win-loss record
3. THE Application SHALL separate teams into Eastern Conference and Western Conference for seeding
4. THE Application SHALL seed teams 1-15 within each conference based on wins
5. THE Application SHALL display the playoff bracket showing all matchups and seeding

### Requirement 22

**User Story:** As a User, I want play-in tournament games for seeds 7-10 in each conference, so that the playoff structure matches the NBA format.

#### Acceptance Criteria

1. THE Application SHALL conduct play-in games for seeds 7-10 in each conference
2. WHEN conducting play-in games, THE Application SHALL match seed 7 vs seed 8 in each conference
3. WHEN conducting play-in games, THE Application SHALL match seed 9 vs seed 10 in each conference
4. THE Application SHALL award the 7th playoff seed to the winner of the 7 vs 8 game
5. THE Application SHALL conduct a second play-in game between the loser of 7 vs 8 and the winner of 9 vs 10
6. THE Application SHALL award the 8th playoff seed to the winner of the second play-in game
7. THE Application SHALL eliminate seeds 9 and 10 that do not win their play-in games

### Requirement 23

**User Story:** As a User, I want playoff series to be best-of-seven format, so that the playoffs feel authentic and competitive.

#### Acceptance Criteria

1. THE Application SHALL conduct all playoff series as best-of-seven (first to 4 wins)
2. THE Application SHALL track wins for each team in the current series
3. THE Application SHALL advance the team that reaches 4 wins first
4. THE Application SHALL eliminate the team that loses the series
5. THE Application SHALL display the current series score (e.g., "Lakers lead 3-2")

### Requirement 24

**User Story:** As a User, I want playoff rounds to follow NBA structure with First Round, Conference Semifinals, Conference Finals, and NBA Finals, so that the tournament progression is clear.

#### Acceptance Criteria

1. THE Application SHALL conduct First Round with seeds 1v8, 2v7, 3v6, 4v5 in each conference
2. THE Application SHALL conduct Conference Semifinals with winners from First Round
3. THE Application SHALL conduct Conference Finals with winners from Conference Semifinals
4. THE Application SHALL conduct NBA Finals between Eastern Conference champion and Western Conference champion
5. THE Application SHALL display the current playoff round name prominently

### Requirement 25

**User Story:** As a User, I want to view the playoff bracket at any time during the post-season, so that I can track tournament progress.

#### Acceptance Criteria

1. THE Application SHALL display a visual playoff bracket showing all matchups
2. THE Application SHALL show completed series results in the bracket
3. THE Application SHALL show current series scores for ongoing matchups
4. THE Application SHALL highlight the User's team in the bracket
5. THE Application SHALL update the bracket after each game is played

### Requirement 26

**User Story:** As a User, I want playoff statistics to be tracked separately from regular season statistics, so that I can evaluate playoff performance.

#### Acceptance Criteria

1. THE Application SHALL track playoff statistics separately from regular season statistics
2. THE Application SHALL display playoff PPG, RPG, APG, and shooting percentages
3. THE Application SHALL show both regular season and playoff stats on player profiles
4. THE Application SHALL persist playoff statistics in save files
5. THE Application SHALL reset playoff statistics at the start of each new season

### Requirement 27

**User Story:** As a User, I want to advance through playoff rounds by playing games, so that I control my team's championship journey.

#### Acceptance Criteria

1. WHEN the User's team is in the playoffs, THE Application SHALL allow the User to play the next playoff game
2. THE Application SHALL simulate non-User playoff games automatically
3. THE Application SHALL advance the playoff bracket after all games in a round are complete
4. THE Application SHALL display a championship celebration when the User wins the NBA Finals
5. THE Application SHALL allow the User to start a new season after the playoffs conclude
