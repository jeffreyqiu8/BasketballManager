# Design Document

## Overview

This design document outlines the architecture for adding advanced features to the existing basketball manager application. The features include team selection during save creation, possession-by-possession match simulation, and comprehensive player statistics tracking. The design maintains the existing principles of simplicity, offline-first functionality, and accessibility while adding gameplay depth.

### Core Design Principles

1. **Build on Existing Foundation**: Extend current models and services rather than replacing them
2. **Maintain Simplicity**: Keep class structure clean with minimal new dependencies
3. **Performance First**: Ensure possession simulation completes within 3 seconds
4. **Accessibility**: All new UI elements include semantic labels and proper contrast
5. **Incremental Updates**: Each feature update is immediately visible in the UI

## Architecture

### High-Level Changes

```
Existing Architecture + New Components:

┌─────────────────────────────────────────────────────────┐
│                     UI Layer (Views)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Home    │  │  Team    │  │  Game    │  │  Save   │ │
│  │  Page    │  │  Page    │  │  Page    │  │  Page   │ │
│  │          │  │ +Stats   │  │ +BoxScore│  │+TeamPick│ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Game    │  │  League  │  │  Save    │              │
│  │ Service  │  │ Service  │  │ Service  │              │
│  │+Poss Sim │  │          │  │          │              │
│  └──────────┘  └──────────┘  └──────────┘              │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Player  │  │   Team   │  │  Season  │  │  Game   │ │
│  │  Model   │  │  Model   │  │  Model   │  │  Model  │ │
│  │ +Stats   │  │          │  │          │  │+BoxScore│ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────┘
```


## Components and Interfaces

### Extended Data Models

#### PlayerGameStats (New Model)
```dart
class PlayerGameStats {
  final String playerId;
  final int points;
  final int rebounds;
  final int assists;
  final int fieldGoalsMade;
  final int fieldGoalsAttempted;
  final int threePointersMade;
  final int threePointersAttempted;
  
  double get fieldGoalPercentage;
  double get threePointPercentage;
  
  Map<String, dynamic> toJson();
  factory PlayerGameStats.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Tracks individual player performance in a single game. Separates game stats from player attributes.

#### PlayerSeasonStats (New Model)
```dart
class PlayerSeasonStats {
  final String playerId;
  final int gamesPlayed;
  final int totalPoints;
  final int totalRebounds;
  final int totalAssists;
  final int totalFieldGoalsMade;
  final int totalFieldGoalsAttempted;
  final int totalThreePointersMade;
  final int totalThreePointersAttempted;
  
  double get pointsPerGame;
  double get reboundsPerGame;
  double get assistsPerGame;
  double get fieldGoalPercentage;
  double get threePointPercentage;
  
  void addGameStats(PlayerGameStats gameStats);
  
  Map<String, dynamic> toJson();
  factory PlayerSeasonStats.fromJson(Map<String, dynamic> json);
}
```

**Rationale**: Accumulates statistics across season. Provides per-game averages and percentages.


#### Game Model Extensions
```dart
class Game {
  // Existing fields...
  final Map<String, PlayerGameStats>? boxScore; // New: player stats by playerId
  
  // New method
  Game copyWithBoxScore(Map<String, PlayerGameStats> boxScore);
}
```

**Rationale**: Adds box score to existing Game model without breaking current functionality.

#### Season Model Extensions
```dart
class Season {
  // Existing fields...
  final Map<String, PlayerSeasonStats>? seasonStats; // New: season stats by playerId
  
  // New methods
  void updateSeasonStats(Map<String, PlayerGameStats> gameStats);
  PlayerSeasonStats? getPlayerStats(String playerId);
}
```

**Rationale**: Tracks cumulative season statistics for all players on user's team.

### Extended Service Layer

#### GameService Extensions

**New Possession-Based Simulation**:
```dart
class GameService {
  // Existing methods...
  
  /// Simulate game possession by possession
  /// Returns Game with scores and box score
  Game simulateGameDetailed(Team homeTeam, Team awayTeam) {
    final simulation = PossessionSimulation(homeTeam, awayTeam);
    return simulation.simulate();
  }
}
```

#### PossessionSimulation (New Helper Class)
```dart
class PossessionSimulation {
  final Team homeTeam;
  final Team awayTeam;
  final Map<String, PlayerGameStats> boxScore = {};
  int homeScore = 0;
  int awayScore = 0;
  int possessionCount = 0;
  
  Game simulate() {
    // Simulate ~100 possessions per team (realistic for basketball)
    while (possessionCount < 200) {
      final isHomeTeam = possessionCount % 2 == 0;
      _simulatePossession(isHomeTeam ? homeTeam : awayTeam, isHomeTeam);
      possessionCount++;
    }
    
    return Game(..., boxScore: boxScore);
  }
  
  void _simulatePossession(Team team, bool isHome);
  Player _selectShooter(List<Player> lineup);
  bool _attemptShot(Player shooter, bool isThreePoint);
  bool _checkRebound(Team team, bool isOffensive);
  void _recordStat(String playerId, StatType type, int value);
}
```

**Rationale**: Encapsulates possession logic. Keeps GameService clean while adding complexity.


### Possession Simulation Algorithm

**Possession Flow**:
1. Select random shooter from starting lineup (weighted by shooting/threePoint attributes)
2. Determine shot type (2pt vs 3pt) based on player's threePoint attribute
3. Calculate shot success probability using player attributes
4. If miss, determine rebound (offensive vs defensive) using rebounding attributes
5. Record statistics (points, rebounds, assists, attempts)

**Attribute Influence on Outcomes**:

| Outcome | Primary Attribute | Formula |
|---------|------------------|---------|
| 2PT Shot Success | shooting | base 45% + (shooting/100 * 15%) |
| 3PT Shot Success | threePoint | base 35% + (threePoint/100 * 10%) |
| Offensive Rebound | rebounding | base 25% + (rebounding/100 * 15%) |
| Turnover | ballHandling | base 15% - (ballHandling/100 * 10%) |
| Assist | passing | base 50% + (passing/100 * 20%) |

**Performance Optimization**:
- Pre-calculate attribute-based probabilities before simulation
- Use simple random number generation (no complex distributions)
- Limit to ~200 total possessions per game
- Target: < 3 seconds total simulation time

### UI Layer Changes

#### SavePage Extensions
```dart
// Add team selection dialog before save creation
Future<Team?> _showTeamSelectionDialog(List<Team> teams);

// Modified save creation flow:
// 1. User enters save name
// 2. Show team selection dialog
// 3. Create save with selected team
```

**UI Components**:
- Scrollable list of 30 teams with city and name
- Team rating displayed for each team
- Search/filter functionality for finding teams
- Accessible labels for each team option


#### GamePage Extensions
```dart
// Add box score display after game simulation
Widget _buildBoxScore(Map<String, PlayerGameStats> boxScore);

// Display format:
// Player Name | PTS | REB | AST | FG% | 3PT%
// Sorted by points descending
// Show only players with > 0 minutes (participated)
```

**UI Components**:
- Scrollable table with player statistics
- Color-coded performance indicators (high/low stats)
- Accessible table with proper semantic labels
- Summary statistics (team totals)

#### TeamPage Extensions
```dart
// Add season statistics tab
Widget _buildSeasonStatsTab(Map<String, PlayerSeasonStats> seasonStats);

// Display format:
// Player Name | PPG | RPG | APG | FG% | 3PT%
// Sortable by any column
// Show games played for each player
```

**UI Components**:
- Tab navigation (Roster / Season Stats)
- Sortable statistics table
- Per-game averages prominently displayed
- Accessible table navigation

## Data Flow

### Team Selection Flow
```
User clicks "New Save" 
  → Enter save name
  → Show team selection dialog (30 teams)
  → User selects team
  → Initialize league with selected team as userTeam
  → Create season schedule
  → Save to local storage
```

### Possession Simulation Flow
```
User clicks "Play Game"
  → Load home and away teams
  → Initialize PossessionSimulation
  → For each possession:
    - Select shooter
    - Attempt shot
    - Handle rebound if miss
    - Record stats
  → Generate final Game with boxScore
  → Update season stats
  → Display results with box score
  → Save updated game state
```


### Statistics Tracking Flow
```
Game simulated with possession system
  → PlayerGameStats created for each player
  → Game saved with boxScore
  → Season.updateSeasonStats() called
  → PlayerSeasonStats updated for each player
  → Season saved with updated seasonStats
  → UI displays updated statistics
```

## Error Handling

### Team Selection Errors
- **No Team Selected**: Prevent save creation, show error message
- **Invalid Team**: Fallback to first team in list, log warning

### Simulation Errors
- **Invalid Player Data**: Skip player, use team average for calculations
- **Calculation Overflow**: Clamp values to realistic ranges
- **Performance Issues**: If simulation takes > 3 seconds, show warning and continue

### Statistics Errors
- **Missing Stats**: Initialize with zeros, continue simulation
- **Division by Zero**: Return 0.0 for percentage calculations
- **Corrupted Season Stats**: Recalculate from game history if available

**Error Display**: All errors shown via SnackBar with accessible announcements

## Testing Strategy

### Unit Tests
- Possession simulation produces valid scores and stats
- Player attribute influence on shot success rates
- Season stats accumulation accuracy
- Box score serialization/deserialization

### Widget Tests
- Team selection dialog displays all 30 teams
- Box score table displays correctly
- Season stats table sorts properly
- Accessibility labels present on all new elements

### Integration Tests
- Complete flow: select team → play game → view stats
- Statistics persist across save/load cycles
- Multiple games accumulate season stats correctly


## Accessibility Implementation

### Team Selection Dialog
- Semantic labels for each team option
- Keyboard navigation support (arrow keys, enter to select)
- Screen reader announces team name, city, and rating
- Focus management when dialog opens/closes

### Box Score Display
- Table with proper semantic structure (headers, rows, cells)
- Screen reader announces column headers
- Row-by-row navigation support
- Summary statistics announced accessibly

### Season Statistics
- Tab navigation with semantic labels
- Sortable columns with accessible sort indicators
- Screen reader announces sort order changes
- Keyboard shortcuts for common actions

## Implementation Notes

### Backward Compatibility
- Existing saves without boxScore/seasonStats continue to work
- Null checks for optional fields in Game and Season models
- Graceful degradation if stats unavailable

### Performance Considerations
- Possession simulation optimized for speed (< 3 seconds)
- Statistics calculated incrementally, not recalculated each time
- Box score only stored for completed games
- Season stats cached in memory during gameplay

### Future Extensibility
- Possession system allows for play-by-play display in future
- Statistics framework supports additional metrics (steals, blocks, etc.)
- Team selection can be extended to difficulty ratings
- Box score can include quarter-by-quarter breakdown

## Player Position System

### Position Roles

Five traditional basketball positions with distinct gameplay characteristics:

| Position | Abbreviation | Primary Attributes | Height Range |
|----------|-------------|-------------------|--------------|
| Point Guard | PG | Passing, Ball Handling, Speed | 70-76" |
| Shooting Guard | SG | Shooting, Three-Point, Speed | 73-78" |
| Small Forward | SF | Shooting, Defense, Speed+Stamina | 76-80" |
| Power Forward | PF | Rebounding, Defense, Shooting | 78-82" |
| Center | C | Rebounding, Blocks, Defense | 80-86" |

### Position Affinity Calculation

Each player has an affinity score (0-100) for each position calculated as:

```dart
class PositionAffinity {
  static double calculatePGAffinity(Player player) {
    // Weight: passing (40%), ballHandling (30%), speed (20%), height penalty (10%)
    double baseScore = (player.passing * 0.4) + 
                       (player.ballHandling * 0.3) + 
                       (player.speed * 0.2);
    double heightPenalty = (player.heightInches - 72) * 0.5; // Penalty for being tall
    return (baseScore - heightPenalty).clamp(0, 100);
  }
  
  static double calculateSGAffinity(Player player) {
    // Weight: shooting (35%), threePoint (35%), speed (20%), height factor (10%)
    double baseScore = (player.shooting * 0.35) + 
                       (player.threePoint * 0.35) + 
                       (player.speed * 0.2);
    double heightBonus = (player.heightInches >= 73 && player.heightInches <= 78) ? 10 : 0;
    return (baseScore + heightBonus).clamp(0, 100);
  }
  
  static double calculateSFAffinity(Player player) {
    // Weight: shooting (25%), defense (25%), athleticism (25%), balanced height (25%)
    double athleticism = (player.speed + player.stamina) / 2;
    double baseScore = (player.shooting * 0.25) + 
                       (player.defense * 0.25) + 
                       (athleticism * 0.25);
    double heightBonus = (player.heightInches >= 76 && player.heightInches <= 80) ? 25 : 0;
    return (baseScore + heightBonus).clamp(0, 100);
  }
  
  static double calculatePFAffinity(Player player) {
    // Weight: rebounding (35%), defense (25%), shooting (20%), height bonus (20%)
    double baseScore = (player.rebounding * 0.35) + 
                       (player.defense * 0.25) + 
                       (player.shooting * 0.2);
    double heightBonus = (player.heightInches - 76) * 1.0; // Bonus for being tall
    return (baseScore + heightBonus).clamp(0, 100);
  }
  
  static double calculateCAffinity(Player player) {
    // Weight: rebounding (35%), blocks (30%), defense (25%), height bonus (10%)
    double baseScore = (player.rebounding * 0.35) + 
                       (player.blocks * 0.3) + 
                       (player.defense * 0.25);
    double heightBonus = (player.heightInches - 78) * 1.5; // Strong bonus for being tall
    return (baseScore + heightBonus).clamp(0, 100);
  }
}
```

### Player Model Extensions

```dart
class Player {
  // Existing fields...
  final int blocks; // New: 0-100 blocking ability
  final int steals; // New: 0-100 stealing ability
  final String position; // New: 'PG', 'SG', 'SF', 'PF', or 'C'
  
  // New methods
  Map<String, double> getPositionAffinities();
  Player copyWithPosition(String newPosition);
}
```

### Height-Based Player Generation

When generating players, attributes are adjusted based on height:

```dart
class PlayerGenerator {
  Player generatePlayer() {
    // Generate base height first
    int height = _generateHeight();
    
    // Generate base attributes
    Map<String, int> baseAttributes = _generateBaseAttributes();
    
    // Apply height modifiers
    if (height >= 80) { // Tall players (6'8"+)
      baseAttributes['rebounding'] += 15;
      baseAttributes['blocks'] += 20;
      baseAttributes['steals'] -= 8;
      baseAttributes['shooting'] -= 5;
      baseAttributes['speed'] -= 10;
    } else if (height <= 72) { // Short players (6'0" and under)
      baseAttributes['steals'] += 20;
      baseAttributes['shooting'] += 15;
      baseAttributes['speed'] += 10;
      baseAttributes['rebounding'] -= 10;
      baseAttributes['blocks'] -= 15;
    }
    
    // Clamp all attributes to 0-100
    baseAttributes.forEach((key, value) {
      baseAttributes[key] = value.clamp(0, 100);
    });
    
    // Assign best-fit position based on affinities
    String position = _assignBestPosition(height, baseAttributes);
    
    return Player(..., position: position);
  }
}
```

### Position Impact on Gameplay

During possession simulation, position modifiers affect probabilities:

```dart
class PossessionSimulation {
  double _getAssistProbability(Player player) {
    double base = 0.5 + (player.passing / 100 * 0.2);
    if (player.position == 'PG') base *= 1.15; // +15% for point guards
    return base;
  }
  
  double _getThreePointAttemptProbability(Player player) {
    double base = player.threePoint / 100 * 0.4;
    if (player.position == 'SG') base *= 1.20; // +20% for shooting guards
    return base;
  }
  
  double _getReboundProbability(Player player, bool isOffensive) {
    double base = 0.25 + (player.rebounding / 100 * 0.15);
    if (player.position == 'PF') base *= 1.15; // +15% for power forwards
    if (player.position == 'C') base *= 1.25; // +25% for centers
    return base;
  }
  
  double _getBlockProbability(Player player) {
    double base = player.blocks / 100 * 0.15;
    if (player.position == 'C') base *= 1.20; // +20% for centers
    return base;
  }
}
```

### UI Components for Position Management

#### TeamPage Position Assignment
```dart
// New position assignment UI on team page
Widget _buildPositionAssignment(Player player) {
  return Column(
    children: [
      // Current position display
      Text('Current Position: ${player.position}'),
      
      // Position affinity display
      _buildAffinityBars(player.getPositionAffinities()),
      
      // Position selector dropdown
      DropdownButton<String>(
        value: player.position,
        items: ['PG', 'SG', 'SF', 'PF', 'C'].map((pos) {
          return DropdownMenuItem(
            value: pos,
            child: Text('$pos (${player.getPositionAffinities()[pos]}% fit)'),
          );
        }).toList(),
        onChanged: (newPosition) => _updatePlayerPosition(player, newPosition),
      ),
    ],
  );
}

Widget _buildAffinityBars(Map<String, double> affinities) {
  return Column(
    children: affinities.entries.map((entry) {
      return Row(
        children: [
          Text('${entry.key}:'),
          LinearProgressIndicator(
            value: entry.value / 100,
            color: _getAffinityColor(entry.value),
          ),
          Text('${entry.value.toStringAsFixed(0)}%'),
        ],
      );
    }).toList(),
  );
}

Color _getAffinityColor(double affinity) {
  if (affinity >= 80) return Colors.green;
  if (affinity >= 60) return Colors.yellow;
  return Colors.red;
}
```

## Dependencies

**No new dependencies required** - all features use existing packages:
- `shared_preferences`: Already included for save system
- `uuid`: Already included for ID generation
- Built-in Flutter widgets for UI components

