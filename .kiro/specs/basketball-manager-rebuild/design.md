# Design Document

## Overview

This design document outlines the architecture for a simplified, offline-first basketball manager application built with Flutter. The application uses local storage exclusively (no Firebase), features a clean class structure with minimal dependencies, and prioritizes accessibility from the ground up. The design emphasizes incremental development where each feature is immediately visible and testable in the UI.

### Core Design Principles

1. **Offline-First**: All data persists locally using shared_preferences or sqflite
2. **Simplicity**: Minimal class hierarchy with clear responsibilities
3. **Accessibility-First**: Every UI component includes semantic labels and proper contrast from initial implementation
4. **Incremental Visibility**: Each feature has immediate UI representation for testing
5. **Single Responsibility**: Each class handles one specific domain concern

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer (Views)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Home    │  │  Team    │  │  Game    │  │  Save   │ │
│  │  Page    │  │  Page    │  │  Page    │  │  Page   │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Game    │  │  League  │  │  Player  │  │  Save   │ │
│  │ Service  │  │ Service  │  │Generator │  │ Service │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Player  │  │   Team   │  │  Season  │  │  Game   │ │
│  │  Model   │  │  Model   │  │  Model   │  │  Model  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              Local Storage (shared_preferences)          │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart
├── models/
│   ├── player.dart
│   ├── team.dart
│   ├── game.dart
│   └── season.dart
├── services/
│   ├── player_generator.dart
│   ├── league_service.dart
│   ├── game_service.dart
│   └── save_service.dart
└── views/
    ├── home_page.dart
    ├── team_page.dart
    ├── game_page.dart
    ├── save_page.dart
    └── widgets/
        ├── player_card.dart
        ├── team_roster.dart
        └── game_result.dart
```

## Components and Interfaces

### Data Models

#### Player Model
```dart
class Player {
  final String id;
  final String name;
  final int shooting;      // 0-100
  final int defense;       // 0-100
  final int speed;         // 0-100
  final int stamina;       // 0-100
  final int passing;       // 0-100
  final int rebounding;    // 0-100
  final int ballHandling;  // 0-100
  final int threePoint;    // 0-100
  
  Player({required this.id, required this.name, ...});
  
  // Serialization
  Map<String, dynamic> toJson();
  factory Player.fromJson(Map<String, dynamic> json);
  
  // Overall rating calculation
  int get overallRating;
}
```

**Rationale**: Simple data class with 8 stats as specified. Overall rating provides quick comparison metric.

#### Team Model
```dart
class Team {
  final String id;
  final String name;
  final String city;
  final List<Player> players;  // Always 15 players
  final List<String> startingLineupIds;  // 5 player IDs
  
  Team({required this.id, required this.name, ...});
  
  List<Player> get startingLineup;
  List<Player> get bench;
  int get teamRating;
  
  Map<String, dynamic> toJson();
  factory Team.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Encapsulates team data with clear separation between starters and bench. Team rating enables match simulation.

#### Game Model
```dart
class Game {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final bool isPlayed;
  final DateTime scheduledDate;
  
  Game({required this.id, ...});
  
  Map<String, dynamic> toJson();
  factory Game.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Tracks individual game state. Nullable scores indicate unplayed games.

#### Season Model
```dart
class Season {
  final String id;
  final int year;
  final List<Game> games;  // 82 games for user's team
  final String userTeamId;
  
  Season({required this.id, ...});
  
  int get gamesPlayed;
  int get gamesRemaining;
  int get wins;
  int get losses;
  
  Map<String, dynamic> toJson();
  factory Season.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Manages season progression and statistics.

### Service Layer

#### PlayerGenerator Service
```dart
class PlayerGenerator {
  // Generates random player with 8 stats
  Player generatePlayer({String? name});
  
  // Generates list of players for team
  List<Player> generateTeamRoster(int count);
  
  // Random name generation
  String _generateRandomName();
  
  // Random stat generation (0-100)
  int _generateStat();
}
```

**Rationale**: Centralizes player creation logic. Ensures consistent random generation.

#### LeagueService
```dart
class LeagueService {
  List<Team> teams = [];
  
  // Initialize 30 teams with 15 players each
  Future<void> initializeLeague();
  
  // Get team by ID
  Team? getTeam(String teamId);
  
  // Update team (for lineup changes)
  Future<void> updateTeam(Team team);
  
  // Get all teams
  List<Team> getAllTeams();
}
```

**Rationale**: Manages league-wide operations. Single source of truth for team data.

#### GameService
```dart
class GameService {
  // Simulate a single game
  Game simulateGame(Team homeTeam, Team awayTeam);
  
  // Basic simulation algorithm
  int _calculateTeamScore(Team team);
  
  // Generate 82-game schedule
  List<Game> generateSchedule(String userTeamId, List<Team> allTeams);
}
```

**Rationale**: Handles match simulation logic. Keeps algorithm simple and deterministic based on team ratings.

**Basic Simulation Algorithm**:
1. Calculate team rating from starting lineup
2. Add random variance (±15 points)
3. Generate score in realistic range (80-120 points)
4. Higher rated team has better probability of higher score

#### SaveService
```dart
class SaveService {
  final SharedPreferences _prefs;
  
  // Save game state
  Future<void> saveGame(String saveName, GameState state);
  
  // Load game state
  Future<GameState?> loadGame(String saveName);
  
  // List all saves
  Future<List<String>> listSaves();
  
  // Delete save
  Future<void> deleteSave(String saveName);
}

class GameState {
  final List<Team> teams;
  final Season currentSeason;
  final String userTeamId;
  
  Map<String, dynamic> toJson();
  factory GameState.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Abstracts storage operations. Uses shared_preferences for simplicity (can migrate to sqflite if needed).

### UI Layer

#### HomePage
- Display user's team record
- Quick access to "Play Next Game"
- Navigation to Team, Season, and Save pages
- Accessible buttons with semantic labels

**Requirements**: 7.1, 7.2, 7.3, 9.1, 9.5

#### TeamPage
- Display all 15 players with their 8 stats
- Visual distinction between starting lineup (5) and bench (10)
- Drag-and-drop or tap to change lineup
- Player cards with accessible labels
- Save lineup changes

**Requirements**: 2.5, 3.3, 4.4, 9.1, 9.2

#### GamePage
- Display upcoming opponent
- "Simulate Game" button
- Show game result (scores)
- Display updated season record
- Accessible result announcements

**Requirements**: 5.5, 6.4, 7.2, 9.1

#### SavePage
- List all save files
- Create new save button
- Load save button
- Delete save button (with confirmation)
- Accessible list with semantic labels

**Requirements**: 1.3, 1.4, 9.1, 9.4

#### Widgets

**PlayerCard**: Displays player name and stats with proper contrast and semantic labels

**TeamRoster**: Scrollable list of players with section headers for starters/bench

**GameResult**: Shows final score with accessible announcements

## Data Models

### Player Attributes

The 8 player statistics:
1. **Shooting**: Mid-range and close-range shooting ability
2. **Defense**: Defensive capability and steal potential
3. **Speed**: Movement speed and fast-break ability
4. **Stamina**: Endurance throughout the game
5. **Passing**: Assist and playmaking ability
6. **Rebounding**: Ability to secure rebounds
7. **Ball Handling**: Dribbling and turnover prevention
8. **Three Point**: Long-range shooting ability

All stats range from 0-100. Overall rating is the average of all 8 stats.

### Storage Schema

**SharedPreferences Keys**:
- `saves_list`: JSON array of save names
- `save_{name}_teams`: JSON array of all teams
- `save_{name}_season`: JSON object of current season
- `save_{name}_user_team`: String ID of user's team

## Error Handling

### Storage Errors
- **Save Failure**: Display error message, retain in-memory state
- **Load Failure**: Display error message, offer to create new game
- **Corrupted Data**: Attempt partial recovery, offer fresh start if critical

### Validation Errors
- **Invalid Lineup**: Prevent saving, show error message indicating exactly 5 starters required
- **Missing Data**: Use default values, log warning

### Simulation Errors
- **Invalid Team Data**: Skip simulation, display error
- **Calculation Errors**: Use fallback random scores

**Error Display**: All errors shown via SnackBar with accessible announcements

## Testing Strategy

### Unit Tests
- Player generation produces valid stats (0-100 range)
- Team rating calculation accuracy
- Game simulation produces valid scores
- Serialization/deserialization for all models

### Widget Tests
- Player card displays all 8 stats
- Team page shows 5 starters and 10 bench players
- Game result displays correctly
- Accessibility labels present on all interactive elements

### Integration Tests
- Complete game flow: create save → play game → save state → load state
- Lineup changes persist across saves
- Season progression tracks correctly through 82 games

### Accessibility Testing
- Screen reader navigation on all pages
- Semantic labels on all buttons and interactive elements
- Color contrast meets WCAG AA standards
- Keyboard navigation functional

**Testing Approach**: Test after each implementation step to ensure immediate feedback and catch issues early.

## Accessibility Implementation

### Semantic Labels
Every interactive element includes:
```dart
Semantics(
  label: 'Descriptive action',
  button: true,
  child: Widget(),
)
```

### Color Contrast
- Text on background: minimum 4.5:1 ratio
- Large text: minimum 3:1 ratio
- Use Flutter's built-in contrast checking

### Screen Reader Support
- Logical focus order
- Meaningful labels for all content
- Announce dynamic content changes (game results, errors)

### Visual Indicators
- Focus indicators on all interactive elements
- Clear visual feedback for button presses
- Loading states with accessible announcements

## Implementation Notes

### Incremental Development
Each implementation task should result in visible UI changes:
1. Create models → Display dummy data in UI
2. Add player generation → Show generated players
3. Implement simulation → Display game results
4. Add save system → Show save/load functionality

### Performance Considerations
- Lazy load team rosters (only load when viewing)
- Cache team ratings to avoid recalculation
- Limit save file size by excluding redundant data
- Target 60fps for all UI interactions

### Future Extensibility
While keeping current implementation simple, the design allows for:
- Adding more stats without breaking existing saves
- Expanding to playoffs/tournaments
- Adding player progression over seasons
- Enhanced simulation algorithms

## Dependencies

**Required Flutter Packages**:
- `shared_preferences`: ^2.2.0 - Local storage
- `uuid`: ^4.0.0 - Unique ID generation

**Accessibility**:
- Built-in Flutter Semantics (no additional packages)

**No Firebase or network dependencies required**
