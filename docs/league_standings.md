# League Standings Feature

## Overview

The League Standings feature provides a comprehensive view of all 30 NBA teams ranked by their win-loss records, organized by conference and league-wide.

## Features

### 1. Conference Standings

View standings separated by Eastern and Western conferences:
- **Eastern Conference**: 15 teams from the Eastern Conference
- **Western Conference**: 15 teams from the Western Conference
- **League**: All 30 teams ranked league-wide

### 2. Standings Information

Each team entry displays:
- **Rank**: Position in the standings (1-15 for conferences, 1-30 for league)
- **Team Name**: City and team name
- **Wins (W)**: Number of games won
- **Losses (L)**: Number of games lost
- **Win Percentage (PCT)**: Calculated as wins / (wins + losses)

### 3. Playoff Indicators

Visual indicators show playoff positioning:
- ⭐ **Star Icon** (Ranks 1-6): Direct playoff qualification
- ▶️ **Play Arrow** (Ranks 7-10): Play-in tournament qualification
- No icon (Ranks 11-15): Eliminated from playoffs

### 4. User Team Highlighting

The user's team is highlighted with:
- Light blue background color
- Bold text for better visibility
- Easy identification in the standings

### 5. Interactive Navigation

- **Tap any team** to view their full roster and statistics
- **Tab navigation** to switch between conferences and league view
- **Accessible** with screen reader support and semantic labels

## UI Components

### Tabs

Three tabs provide different views:
1. **Eastern Conference** - Shows only Eastern Conference teams
2. **Western Conference** - Shows only Western Conference teams
3. **League** - Shows all 30 teams

### Standings Table

| Column | Description | Width |
|--------|-------------|-------|
| Rank | Team's position (1-15 or 1-30) | 40px |
| Team | City and team name | Flexible |
| W | Wins | 50px |
| L | Losses | 50px |
| PCT | Win percentage (0.000-1.000) | 60px |

### Color Coding

- **User Team**: Light blue background (`AppTheme.primaryColor.withOpacity(0.15)`)
- **Header**: Light primary color background
- **Borders**: Light grey dividers between rows

## Navigation

### From HomePage

Access the standings via the "League Standings" button in the navigation section:

```dart
OutlinedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeagueStandingsPage(
          leagueService: leagueService,
          season: season,
          userTeamId: userTeamId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.leaderboard),
  label: const Text('League Standings'),
)
```

### To Team Pages

Tap any team in the standings to navigate to their detailed team page.

## Implementation Details

### Record Calculation

The standings calculate each team's record by:
1. Iterating through all games in the season
2. Counting wins and losses for each team
3. Calculating win percentage: `wins / (wins + losses)`
4. Sorting teams by wins (descending), then by win percentage

### Conference Assignment

Teams are assigned to conferences using the `PlayoffSeeding.getConference()` utility:
- Eastern Conference: Atlanta, Boston, Brooklyn, Charlotte, Chicago, Cleveland, Detroit, Indiana, Miami, Milwaukee, New York, Orlando, Philadelphia, Toronto, Washington
- Western Conference: Dallas, Denver, Golden State, Houston, LA, Los Angeles, Memphis, Minnesota, New Orleans, Oklahoma City, Phoenix, Portland, Sacramento, San Antonio, Utah

### Sorting Algorithm

Teams are sorted using a two-level sort:
1. **Primary**: Wins (descending)
2. **Secondary**: Win percentage (descending)

This ensures teams with the same number of wins are ranked by their win percentage.

## Accessibility

The standings page includes comprehensive accessibility features:

### Semantic Labels

Each team row has a descriptive label:
```
"Rank 1: Boston Celtics, 50 wins, 32 losses, 61.0 percent"
```

### Screen Reader Support

- Tab navigation is announced
- Table headers are properly labeled
- Interactive elements are marked as buttons
- Team selection is announced

### Keyboard Navigation

- Tab through teams using keyboard
- Enter to select a team
- Arrow keys to switch between conference tabs

## Testing

Comprehensive tests are available in `test/league_standings_test.dart`:

1. **Displays all 30 teams** - Verifies all teams appear in standings
2. **Highlights user team** - Confirms user team is visually distinct
3. **Can switch between conferences** - Tests tab navigation
4. **Shows playoff indicators** - Validates playoff qualification icons

All tests pass successfully!

## Example Usage

```dart
// Navigate to standings from anywhere in the app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LeagueStandingsPage(
      leagueService: leagueService,
      season: currentSeason,
      userTeamId: userTeamId,
    ),
  ),
);
```

## Data Model

### TeamRecord Class

Internal data class used to hold team record information:

```dart
class TeamRecord {
  final Team team;
  final int wins;
  final int losses;
  final double winPercentage;
  final String conference;
}
```

## Performance

- **Calculation**: O(n*m) where n = teams (30) and m = games (82)
- **Rendering**: Efficient ListView.builder for smooth scrolling
- **Memory**: Minimal - only stores calculated records
- **Updates**: Recalculates on page load (no real-time updates)

## Future Enhancements

Potential improvements for future versions:

1. **Games Behind (GB)** - Show games behind the leader
2. **Streak Indicator** - Show current win/loss streak
3. **Last 10 Games** - Display recent form (e.g., "7-3")
4. **Division Standings** - Group by divisions within conferences
5. **Sorting Options** - Allow sorting by different columns
6. **Filtering** - Filter by playoff teams, conference, etc.
7. **Historical Standings** - View standings from previous seasons
8. **Tiebreaker Rules** - Implement NBA tiebreaker rules
9. **Clinch Indicators** - Show when teams clinch playoffs/division
10. **Real-time Updates** - Auto-refresh when games are played

## Related Features

- **Season Simulation** - Simulate games to update standings
- **Playoff Seeding** - Standings determine playoff seeding
- **Team Pages** - View detailed team information from standings
- **Season Schedule** - See which games affect standings
