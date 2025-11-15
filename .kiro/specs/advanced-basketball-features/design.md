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

## Player Role Archetype System

### Role Archetype Definitions

Each position has multiple specialized role archetypes that emphasize different playstyles:

#### Point Guard Archetypes

| Role | Key Attributes | Gameplay Modifiers |
|------|---------------|-------------------|
| All-Around PG | Balanced: passing, shooting, ballHandling, speed | Standard PG modifiers |
| Floor General | Passing (45%), ballHandling (30%), speed (15%) | +20% assists, -15% shot attempts |
| Slashing Playmaker | postShooting (35%), speed (25%), ballHandling (20%) | +25% post shots, -20% three-point attempts |
| Offensive Point | shooting (35%), threePoint (30%), passing (20%) | +15% shot attempts, -10% assists |

#### Shooting Guard Archetypes

| Role | Key Attributes | Gameplay Modifiers |
|------|---------------|-------------------|
| Three-Level Scorer | shooting (35%), threePoint (30%), ballHandling (25%) | +20% shot creation, -15% assists |
| 3-and-D | threePoint (40%), defense (30%), steals (20%) | +30% three-point attempts, +25% steals, +20% defense |
| Microwave Shooter | shooting (45%), threePoint (40%), speed (10%) | +35% catch-and-shoot, -25% ball handling usage |

#### Small Forward Archetypes

| Role | Key Attributes | Gameplay Modifiers |
|------|---------------|-------------------|
| Point Forward | passing (35%), ballHandling (25%), shooting (20%) | +25% assists, -20% post shots |
| 3-and-D Wing | threePoint (30%), defense (25%), steals (20%), blocks (15%), rebounding (10%) | +25% three-point attempts, +20% steals, +15% blocks, +10% rebounds |
| Athletic Finisher | postShooting (40%), speed (25%), rebounding (20%) | +30% post shots, -30% three-point attempts |

#### Power Forward Archetypes

| Role | Key Attributes | Gameplay Modifiers |
|------|---------------|-------------------|
| Playmaking Big | passing (35%), rebounding (30%), postShooting (20%) | +20% assists, -25% three-point attempts |
| Stretch Four | threePoint (35%), shooting (30%), rebounding (25%) | +25% three-point attempts |
| Rim Runner | postShooting (40%), rebounding (35%), blocks (20%) | +35% post shots, +20% rebounds, -90% three-point attempts |

#### Center Archetypes

| Role | Key Attributes | Gameplay Modifiers |
|------|---------------|-------------------|
| Paint Beast | postShooting (35%), blocks (30%), rebounding (25%), defense (10%) | +30% post shots, +35% blocks, no three-point attempts |
| Stretch Five | threePoint (35%), shooting (25%), rebounding (25%) | +30% three-point attempts, maintain rebounds |
| Standard Center | rebounding (30%), postShooting (25%), blocks (25%), defense (20%) | Balanced interior play, moderate three-point attempts |

### Role Fit Calculation

```dart
class RoleArchetype {
  final String id;
  final String name;
  final String position;
  final Map<String, double> attributeWeights; // attribute name -> weight (0-1)
  final Map<String, double> gameplayModifiers; // modifier type -> multiplier
  
  double calculateFitScore(Player player) {
    double score = 0.0;
    double totalWeight = 0.0;
    
    attributeWeights.forEach((attribute, weight) {
      int attributeValue = _getPlayerAttribute(player, attribute);
      score += attributeValue * weight;
      totalWeight += weight;
    });
    
    // Normalize to 0-100 scale
    return (score / totalWeight).clamp(0, 100);
  }
  
  int _getPlayerAttribute(Player player, String attribute) {
    switch (attribute) {
      case 'shooting': return player.shooting;
      case 'threePoint': return player.threePoint;
      case 'passing': return player.passing;
      case 'ballHandling': return player.ballHandling;
      case 'postShooting': return player.postShooting;
      case 'defense': return player.defense;
      case 'steals': return player.steals;
      case 'blocks': return player.blocks;
      case 'rebounding': return player.rebounding;
      case 'speed': return player.speed;
      case 'stamina': return player.stamina;
      default: return 0;
    }
  }
}
```

### Role Archetype Registry

```dart
class RoleArchetypeRegistry {
  static final Map<String, List<RoleArchetype>> _archetypesByPosition = {
    'PG': [
      RoleArchetype(
        id: 'pg_allaround',
        name: 'All-Around PG',
        position: 'PG',
        attributeWeights: {
          'passing': 0.25,
          'shooting': 0.20,
          'ballHandling': 0.25,
          'speed': 0.20,
          'threePoint': 0.10,
        },
        gameplayModifiers: {}, // Standard modifiers
      ),
      RoleArchetype(
        id: 'pg_floor_general',
        name: 'Floor General',
        position: 'PG',
        attributeWeights: {
          'passing': 0.45,
          'ballHandling': 0.30,
          'speed': 0.15,
          'defense': 0.10,
        },
        gameplayModifiers: {
          'assistProbability': 1.20,
          'shotAttemptProbability': 0.85,
        },
      ),
      // ... other PG archetypes
    ],
    'SG': [ /* SG archetypes */ ],
    'SF': [ /* SF archetypes */ ],
    'PF': [ /* PF archetypes */ ],
    'C': [ /* C archetypes */ ],
  };
  
  static List<RoleArchetype> getArchetypesForPosition(String position) {
    return _archetypesByPosition[position] ?? [];
  }
  
  static RoleArchetype? getArchetypeById(String id) {
    for (var archetypes in _archetypesByPosition.values) {
      for (var archetype in archetypes) {
        if (archetype.id == id) return archetype;
      }
    }
    return null;
  }
}
```

### Player Model Extensions for Roles

```dart
class Player {
  // Existing fields...
  final String? roleArchetypeId; // New: ID of assigned role archetype
  
  // New methods
  RoleArchetype? getRoleArchetype() {
    if (roleArchetypeId == null) return null;
    return RoleArchetypeRegistry.getArchetypeById(roleArchetypeId!);
  }
  
  Map<String, double> getRoleFitScores() {
    final archetypes = RoleArchetypeRegistry.getArchetypesForPosition(position);
    return Map.fromEntries(
      archetypes.map((archetype) => 
        MapEntry(archetype.id, archetype.calculateFitScore(this))
      )
    );
  }
  
  Player copyWithRoleArchetype(String? roleArchetypeId);
}
```

### Possession Simulation with Role Modifiers

```dart
class PossessionSimulation {
  double _getModifiedProbability(Player player, String baseType, double baseProbability) {
    double probability = baseProbability;
    
    // Apply position modifiers (existing)
    probability *= _getPositionModifier(player.position, baseType);
    
    // Apply role archetype modifiers (new)
    final role = player.getRoleArchetype();
    if (role != null) {
      final modifier = role.gameplayModifiers[baseType];
      if (modifier != null) {
        probability *= modifier;
      }
    }
    
    return probability.clamp(0.0, 1.0);
  }
  
  // Example usage in possession simulation
  void _simulatePossession(Team team, bool isHome) {
    final shooter = _selectShooter(team.startingLineup);
    
    // Determine shot type with role modifiers
    final threePointProb = _getModifiedProbability(
      shooter,
      'threePointAttemptProbability',
      shooter.threePoint / 100 * 0.4,
    );
    
    final isThreePoint = Random().nextDouble() < threePointProb;
    
    // ... rest of possession logic
  }
}
```

### UI Components for Role Management

#### TeamPage Role Assignment

```dart
Widget _buildRoleSelector(Player player) {
  final archetypes = RoleArchetypeRegistry.getArchetypesForPosition(player.position);
  final fitScores = player.getRoleFitScores();
  final currentRole = player.getRoleArchetype();
  
  return Column(
    children: [
      // Current role display
      Text('Role: ${currentRole?.name ?? "None"}'),
      
      // Role selector dropdown
      DropdownButton<String>(
        value: player.roleArchetypeId,
        items: archetypes.map((archetype) {
          final fitScore = fitScores[archetype.id] ?? 0;
          return DropdownMenuItem(
            value: archetype.id,
            child: Row(
              children: [
                Text(archetype.name),
                SizedBox(width: 8),
                _buildFitIndicator(fitScore),
                Text('${fitScore.toStringAsFixed(0)}% fit'),
              ],
            ),
          );
        }).toList(),
        onChanged: (newRoleId) => _updatePlayerRole(player, newRoleId),
      ),
      
      // Important attributes for selected role
      if (currentRole != null) _buildRoleAttributeHighlights(currentRole),
    ],
  );
}

Widget _buildRoleAttributeHighlights(RoleArchetype role) {
  final sortedAttributes = role.attributeWeights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Key Attributes:', style: TextStyle(fontWeight: FontWeight.bold)),
      ...sortedAttributes.take(3).map((entry) {
        return Row(
          children: [
            Icon(Icons.star, size: 16, color: Colors.amber),
            Text(_formatAttributeName(entry.key)),
          ],
        );
      }),
    ],
  );
}

Widget _buildFitIndicator(double fitScore) {
  Color color;
  if (fitScore >= 80) color = Colors.green;
  else if (fitScore >= 60) color = Colors.yellow;
  else color = Colors.red;
  
  return Container(
    width: 40,
    height: 8,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
```

#### PlayerProfilePage Role Fit Display

```dart
Widget _buildRoleFitSection(Player player) {
  final archetypes = RoleArchetypeRegistry.getArchetypesForPosition(player.position);
  final fitScores = player.getRoleFitScores();
  final currentRole = player.getRoleArchetype();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Role Fit Analysis', style: Theme.of(context).textTheme.headline6),
      SizedBox(height: 16),
      
      // List all roles with fit scores
      ...archetypes.map((archetype) {
        final fitScore = fitScores[archetype.id] ?? 0;
        final isCurrent = archetype.id == player.roleArchetypeId;
        
        return Card(
          color: isCurrent ? Colors.blue.shade50 : null,
          child: ListTile(
            leading: _buildFitScoreCircle(fitScore),
            title: Text(
              archetype.name,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: _buildAttributeChips(archetype.attributeWeights),
            trailing: isCurrent ? Icon(Icons.check_circle, color: Colors.blue) : null,
            onTap: () => _showRoleDetails(archetype, player),
          ),
        );
      }),
    ],
  );
}

Widget _buildFitScoreCircle(double fitScore) {
  Color color;
  if (fitScore >= 80) color = Colors.green;
  else if (fitScore >= 60) color = Colors.yellow;
  else color = Colors.red;
  
  return CircleAvatar(
    backgroundColor: color,
    child: Text(
      '${fitScore.toStringAsFixed(0)}',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _buildAttributeChips(Map<String, double> attributeWeights) {
  final topAttributes = attributeWeights.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return Wrap(
    spacing: 4,
    children: topAttributes.take(3).map((entry) {
      return Chip(
        label: Text(
          _formatAttributeName(entry.key),
          style: TextStyle(fontSize: 10),
        ),
        backgroundColor: Colors.blue.shade100,
        padding: EdgeInsets.all(2),
      );
    }).toList(),
  );
}

void _showRoleDetails(RoleArchetype archetype, Player player) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(archetype.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Attributes:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...archetype.attributeWeights.entries.map((entry) {
            final playerValue = _getPlayerAttribute(player, entry.key);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatAttributeName(entry.key)),
                Text('$playerValue', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            );
          }),
          SizedBox(height: 16),
          Text('Gameplay Impact:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...archetype.gameplayModifiers.entries.map((entry) {
            return Text('• ${_formatModifier(entry.key, entry.value)}');
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            _updatePlayerRole(player, archetype.id);
            Navigator.pop(context);
          },
          child: Text('Assign Role'),
        ),
      ],
    ),
  );
}
```

### Data Persistence

Role archetype assignments are stored in the Player model:

```dart
// Player JSON serialization
Map<String, dynamic> toJson() {
  return {
    // ... existing fields
    'roleArchetypeId': roleArchetypeId,
  };
}

// Player JSON deserialization
factory Player.fromJson(Map<String, dynamic> json) {
  return Player(
    // ... existing fields
    roleArchetypeId: json['roleArchetypeId'] as String?,
  );
}
```

### Backward Compatibility

- Players without `roleArchetypeId` will have no role assigned (null)
- UI will show "No role assigned" and allow selection
- Gameplay will use standard position modifiers without role modifiers
- Existing saves will continue to work without modification

## Post-Season Tournament System

### Overview

After 82 regular season games, the application enters the post-season phase with a tournament structure matching the NBA format: play-in games for seeds 7-10, followed by best-of-seven playoff series through four rounds (First Round, Conference Semifinals, Conference Finals, NBA Finals).

### Post-Season Data Models

#### PlayoffSeries (New Model)
```dart
class PlayoffSeries {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final int homeWins;
  final int awayWins;
  final String round; // 'play-in', 'first-round', 'conf-semis', 'conf-finals', 'finals'
  final String conference; // 'east', 'west', or 'finals'
  final List<String> gameIds; // References to Game objects
  final bool isComplete;
  
  String? get winnerId => isComplete ? (homeWins > awayWins ? homeTeamId : awayTeamId) : null;
  String get seriesScore => '$homeWins-$awayWins';
  
  PlayoffSeries copyWithGameResult(String gameId, String winnerId);
  
  Map<String, dynamic> toJson();
  factory PlayoffSeries.fromJson(Map<String, dynamic> json);
}
```

#### PlayoffBracket (New Model)
```dart
class PlayoffBracket {
  final String seasonId;
  final Map<String, int> teamSeedings; // teamId -> seed (1-15 per conference)
  final Map<String, String> teamConferences; // teamId -> 'east' or 'west'
  final List<PlayoffSeries> playInGames;
  final List<PlayoffSeries> firstRound;
  final List<PlayoffSeries> conferenceSemis;
  final List<PlayoffSeries> conferenceFinals;
  final PlayoffSeries? nbаFinals;
  final String currentRound; // 'play-in', 'first-round', 'conf-semis', 'conf-finals', 'finals', 'complete'
  
  List<PlayoffSeries> getCurrentRoundSeries();
  PlayoffSeries? getUserTeamSeries(String userTeamId);
  bool isRoundComplete();
  
  Map<String, dynamic> toJson();
  factory PlayoffBracket.fromJson(Map<String, dynamic> json);
}
```

#### PlayerPlayoffStats (New Model)
```dart
class PlayerPlayoffStats {
  final String playerId;
  final int gamesPlayed;
  final int totalPoints;
  final int totalRebounds;
  final int totalAssists;
  final int totalSteals;
  final int totalBlocks;
  final int totalTurnovers;
  final int totalFieldGoalsMade;
  final int totalFieldGoalsAttempted;
  final int totalThreePointersMade;
  final int totalThreePointersAttempted;
  final int totalFreeThrowsMade;
  final int totalFreeThrowsAttempted;
  
  double get pointsPerGame;
  double get reboundsPerGame;
  double get assistsPerGame;
  double get fieldGoalPercentage;
  double get threePointPercentage;
  double get freeThrowPercentage;
  
  void addGameStats(PlayerGameStats gameStats);
  
  Map<String, dynamic> toJson();
  factory PlayerPlayoffStats.fromJson(Map<String, dynamic> json);
}
```

#### Season Model Extensions
```dart
class Season {
  // Existing fields...
  final PlayoffBracket? playoffBracket; // New: playoff tournament structure
  final Map<String, PlayerPlayoffStats>? playoffStats; // New: playoff stats by playerId
  final bool isPostSeason; // New: flag indicating if season is in playoffs
  
  // New methods
  void startPostSeason(List<Team> allTeams);
  void updatePlayoffStats(Map<String, PlayerGameStats> gameStats);
  PlayerPlayoffStats? getPlayerPlayoffStats(String playerId);
}
```

### Post-Season Flow

#### Season Completion Detection
```dart
class LeagueService {
  bool isRegularSeasonComplete(Season season) {
    return season.games.length >= 82 * 15; // 82 games per team, 30 teams = 1230 total games
  }
  
  void checkAndStartPostSeason(Season season, List<Team> allTeams) {
    if (isRegularSeasonComplete(season) && !season.isPostSeason) {
      season.startPostSeason(allTeams);
      _saveSeasonState(season);
    }
  }
}
```

#### Playoff Seeding Algorithm
```dart
class PlayoffSeeding {
  static Map<String, int> calculateSeedings(List<Team> teams, Season season) {
    // Calculate win-loss records for each team
    final records = <String, int>{};
    for (var team in teams) {
      records[team.id] = _calculateWins(team.id, season.games);
    }
    
    // Separate teams by conference (based on team ID or division)
    final eastTeams = teams.where((t) => _isEasternConference(t)).toList();
    final westTeams = teams.where((t) => !_isEasternConference(t)).toList();
    
    // Sort by wins (descending)
    eastTeams.sort((a, b) => records[b.id]!.compareTo(records[a.id]!));
    westTeams.sort((a, b) => records[b.id]!.compareTo(records[a.id]!));
    
    // Assign seeds 1-15
    final seedings = <String, int>{};
    for (int i = 0; i < eastTeams.length; i++) {
      seedings[eastTeams[i].id] = i + 1;
    }
    for (int i = 0; i < westTeams.length; i++) {
      seedings[westTeams[i].id] = i + 1;
    }
    
    return seedings;
  }
  
  static bool _isEasternConference(Team team) {
    // Simple division: first 15 teams alphabetically are East
    // Or use team.conference field if available
    final eastCities = ['Atlanta', 'Boston', 'Brooklyn', 'Charlotte', 'Chicago',
                        'Cleveland', 'Detroit', 'Indiana', 'Miami', 'Milwaukee',
                        'New York', 'Orlando', 'Philadelphia', 'Toronto', 'Washington'];
    return eastCities.contains(team.city);
  }
}
```

#### Play-In Tournament Generation
```dart
class PlayoffBracketGenerator {
  static List<PlayoffSeries> generatePlayInGames(
    Map<String, int> seedings,
    Map<String, String> conferences,
  ) {
    final playInGames = <PlayoffSeries>[];
    
    // East play-in games
    final eastTeams = _getTeamsByConference(seedings, conferences, 'east');
    playInGames.add(_createSeries(eastTeams[6], eastTeams[7], 'play-in', 'east')); // 7 vs 8
    playInGames.add(_createSeries(eastTeams[8], eastTeams[9], 'play-in', 'east')); // 9 vs 10
    
    // West play-in games
    final westTeams = _getTeamsByConference(seedings, conferences, 'west');
    playInGames.add(_createSeries(westTeams[6], westTeams[7], 'play-in', 'west')); // 7 vs 8
    playInGames.add(_createSeries(westTeams[8], westTeams[9], 'play-in', 'west')); // 9 vs 10
    
    return playInGames;
  }
  
  static PlayoffSeries _createSeries(String team1, String team2, String round, String conference) {
    return PlayoffSeries(
      id: uuid.v4(),
      homeTeamId: team1,
      awayTeamId: team2,
      homeWins: 0,
      awayWins: 0,
      round: round,
      conference: conference,
      gameIds: [],
      isComplete: false,
    );
  }
}
```

#### Playoff Round Progression
```dart
class PlayoffService {
  void advancePlayoffRound(PlayoffBracket bracket) {
    if (!bracket.isRoundComplete()) return;
    
    switch (bracket.currentRound) {
      case 'play-in':
        _resolvePlayInAndGenerateFirstRound(bracket);
        break;
      case 'first-round':
        _generateConferenceSemis(bracket);
        break;
      case 'conf-semis':
        _generateConferenceFinals(bracket);
        break;
      case 'conf-finals':
        _generateNBAFinals(bracket);
        break;
      case 'finals':
        _completePlayoffs(bracket);
        break;
    }
  }
  
  void _resolvePlayInAndGenerateFirstRound(PlayoffBracket bracket) {
    // Resolve play-in games to determine seeds 7 and 8
    final eastSeed7 = _resolvePlayIn(bracket.playInGames, 'east');
    final westSeed7 = _resolvePlayIn(bracket.playInGames, 'west');
    
    // Generate first round matchups: 1v8, 2v7, 3v6, 4v5
    bracket.firstRound = _generateFirstRoundSeries(bracket.teamSeedings, eastSeed7, westSeed7);
    bracket.currentRound = 'first-round';
  }
  
  List<String> _resolvePlayIn(List<PlayoffSeries> playInGames, String conference) {
    // Find 7v8 and 9v10 games for this conference
    final game78 = playInGames.firstWhere((s) => 
      s.conference == conference && _isGame78(s));
    final game910 = playInGames.firstWhere((s) => 
      s.conference == conference && _isGame910(s));
    
    final winner78 = game78.winnerId!; // Seed 7
    final loser78 = game78.homeTeamId == winner78 ? game78.awayTeamId : game78.homeTeamId;
    final winner910 = game910.winnerId!;
    
    // Second play-in game: loser of 7v8 vs winner of 9v10
    final secondGame = _simulateSeries(loser78, winner910, 'play-in', conference, isSingleGame: true);
    final seed8 = secondGame.winnerId!;
    
    return [winner78, seed8];
  }
}
```

### UI Components

#### PlayoffBracketPage (New Page)
```dart
class PlayoffBracketPage extends StatelessWidget {
  final PlayoffBracket bracket;
  final String userTeamId;
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getRoundName(bracket.currentRound)} Playoffs'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRoundIndicator(),
            _buildBracketVisualization(),
            _buildUserTeamStatus(),
            _buildNextGameButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBracketVisualization() {
    return Row(
      children: [
        // Eastern Conference bracket
        Expanded(child: _buildConferenceBracket('east')),
        // Finals in center
        _buildFinalsBracket(),
        // Western Conference bracket
        Expanded(child: _buildConferenceBracket('west')),
      ],
    );
  }
  
  Widget _buildConferenceBracket(String conference) {
    return Column(
      children: [
        Text(conference == 'east' ? 'Eastern Conference' : 'Western Conference'),
        _buildRoundColumn(bracket.firstRound, conference),
        _buildRoundColumn(bracket.conferenceSemis, conference),
        _buildRoundColumn(bracket.conferenceFinals, conference),
      ],
    );
  }
  
  Widget _buildSeriesCard(PlayoffSeries series) {
    return Card(
      color: _isUserTeamInSeries(series) ? Colors.blue.shade50 : null,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            _buildTeamRow(series.homeTeamId, series.homeWins, isHome: true),
            Divider(),
            _buildTeamRow(series.awayTeamId, series.awayWins, isHome: false),
            if (series.isComplete)
              Text('Winner: ${_getTeamName(series.winnerId!)}',
                   style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
```

#### HomePage Extensions for Playoffs
```dart
class HomePage extends StatelessWidget {
  Widget _buildSeasonStatus(Season season) {
    if (season.isPostSeason) {
      final bracket = season.playoffBracket!;
      final userSeries = bracket.getUserTeamSeries(userTeamId);
      
      return Column(
        children: [
          Text('${_getRoundName(bracket.currentRound)}',
               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (userSeries != null) ...[
            Text('Series: ${userSeries.seriesScore}'),
            ElevatedButton(
              onPressed: () => _playNextPlayoffGame(),
              child: Text('Play Next Playoff Game'),
            ),
          ] else ...[
            Text('Your team has been eliminated'),
            ElevatedButton(
              onPressed: () => _viewPlayoffBracket(),
              child: Text('View Playoff Bracket'),
            ),
          ],
        ],
      );
    } else {
      // Regular season UI (existing)
      return _buildRegularSeasonStatus(season);
    }
  }
}
```

#### PlayerProfilePage Extensions
```dart
class PlayerProfilePage extends StatelessWidget {
  Widget _buildStatsSection(Player player, Season season) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Regular Season'),
              Tab(text: 'Playoffs'),
            ],
          ),
          TabBarView(
            children: [
              _buildSeasonStats(player, season.seasonStats),
              _buildPlayoffStats(player, season.playoffStats),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayoffStats(Player player, Map<String, PlayerPlayoffStats>? playoffStats) {
    final stats = playoffStats?[player.id];
    if (stats == null || stats.gamesPlayed == 0) {
      return Center(child: Text('No playoff games played'));
    }
    
    return _buildStatsTable(stats);
  }
}
```

### Playoff Game Simulation

Playoff games use the same possession-by-possession simulation as regular season games, but:
- Results are recorded in PlayoffSeries instead of regular season schedule
- Statistics are accumulated in PlayerPlayoffStats instead of PlayerSeasonStats
- Series advances when a team reaches 4 wins

```dart
class GameService {
  Game simulatePlayoffGame(Team homeTeam, Team awayTeam, PlayoffSeries series) {
    // Use existing detailed simulation
    final game = simulateGameDetailed(homeTeam, awayTeam);
    
    // Mark as playoff game
    game = game.copyWith(isPlayoffGame: true, seriesId: series.id);
    
    return game;
  }
}
```

### Data Persistence

Playoff data is stored in the Season model:

```dart
// Season JSON serialization
Map<String, dynamic> toJson() {
  return {
    // ... existing fields
    'isPostSeason': isPostSeason,
    'playoffBracket': playoffBracket?.toJson(),
    'playoffStats': playoffStats?.map((k, v) => MapEntry(k, v.toJson())),
  };
}
```

### Performance Considerations

- Playoff bracket generation happens once at season end (< 1 second)
- Non-user playoff games are simulated in batches (all games in a round)
- Bracket visualization uses efficient widget tree (no complex animations)
- Playoff stats are calculated incrementally like regular season stats

### Accessibility

- Playoff bracket has semantic structure with proper labels
- Series scores announced by screen readers
- Round progression announced accessibly
- Keyboard navigation for bracket exploration
- High contrast for completed vs ongoing series

## Dependencies

**No new dependencies required** - all features use existing packages:
- `shared_preferences`: Already included for save system
- `uuid`: Already included for ID generation
- Built-in Flutter widgets for UI components

