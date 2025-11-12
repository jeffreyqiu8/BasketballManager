# Project Analysis Tools

This directory contains tools for analyzing the Basketball Manager project structure and identifying cleanup opportunities.

## Tools

### 1. analyze_project.dart
Main analysis script that scans the entire project and generates a comprehensive report.

**Usage:**
```bash
dart run tools/analyze_project.dart
```

**Output:**
- Console output with detailed analysis
- Can be redirected to a file: `dart run tools/analyze_project.dart > tools/analysis_output.txt`

**Features:**
- Scans all Dart files in `lib/` and `test/` directories
- Builds import dependency graph
- Identifies unused files
- Categorizes files by status (active, testOnly, unused, duplicate, example, documentation)
- Identifies duplicate implementations
- Shows files with most dependents
- Provides actionable recommendations

### 2. generate_json_report.dart
Generates a structured JSON report for programmatic use.

**Usage:**
```bash
dart run tools/generate_json_report.dart
```

**Output:**
- `tools/analysis_report.json` - Structured JSON data

**JSON Structure:**
```json
{
  "summary": {
    "totalFiles": 97,
    "active": 81,
    "unused": 5,
    "testOnly": 9,
    "example": 2,
    "documentation": 0,
    "duplicate": 2
  },
  "categories": {
    "unused": [...],
    "testOnly": [...],
    "example": [...],
    "documentation": [...],
    "duplicate": [...]
  },
  "topDependencies": [...],
  "recommendations": [...]
}
```

### 3. project_analysis_report.md
Human-readable markdown report with detailed findings and recommendations.

**Contents:**
- Executive summary
- Detailed analysis by category
- Specific recommendations for each file
- Action plan organized by risk level
- Metrics and projections

## Generated Files

- `analysis_output.txt` - Full console output from analyze_project.dart
- `analysis_report.json` - Structured JSON data
- `project_analysis_report.md` - Detailed markdown report

## Analysis Results Summary

### Key Findings

- **Total files in lib/**: 97
- **Active (production)**: 81 (83.5%)
- **Test-only**: 9 (9.3%)
- **Unused**: 5 (5.2%)
- **Example files**: 2 (2.1%)
- **Duplicate implementations**: 2 (2.1%)

### Files to Remove

#### Unused Files (5)
1. `lib/main.dart` ⚠️ (verify - should be entry point!)
2. `lib/views/pages/career_statistics_page.dart`
3. `lib/views/pages/save_management_page.dart`
4. `lib/views/widgets/enhanced_tooltips.dart`
5. `lib/views/widgets/save_recovery_widget.dart`

#### Duplicate Files (2)
1. `lib/gameData/optimized_match_history_service.dart` (duplicate of match_history_service.dart)
2. `lib/gameData/optimized_save_manager.dart` (duplicate of save_manager.dart)

#### Example Files to Move (2)
1. `lib/gameData/league_expansion_example.dart` → `examples/`
2. `lib/gameData/save_backup_integration_example.dart` → `examples/`

#### Test-Only Files to Review (9)
1. `lib/gameData/aging_service.dart`
2. `lib/gameData/optimized_league_service.dart`
3. `lib/gameData/strategy_history.dart`
4. `lib/main_accessibility.dart`
5. `lib/views/pages/enhanced_schedule_page.dart`
6. `lib/views/widgets/in_game_strategy_selector.dart`
7. `lib/views/widgets/lazy_loading_widget.dart`
8. Plus 2 duplicates listed above

### Most Critical Dependencies

Files with the most dependents (core to the system):

1. `enums.dart` - 63 dependents
2. `enhanced_player.dart` - 36 dependents
3. `enhanced_team.dart` - 28 dependents
4. `enhanced_coach.dart` - 26 dependents
5. `player_class.dart` - 22 dependents
6. `team_class.dart` - 20 dependents
7. `development_system.dart` - 18 dependents
8. `enhanced_conference.dart` - 17 dependents
9. `game_result.dart` - 15 dependents
10. `playbook.dart` - 14 dependents

## How to Use These Tools

### Step 1: Run Analysis
```bash
# Generate all reports
dart run tools/analyze_project.dart
dart run tools/generate_json_report.dart
```

### Step 2: Review Reports
1. Read `project_analysis_report.md` for detailed findings
2. Check `analysis_report.json` for structured data
3. Review console output for quick overview

### Step 3: Follow Action Plan
See `project_analysis_report.md` for phased action plan organized by risk level.

### Step 4: Re-run After Changes
After making changes, re-run the analysis to verify:
```bash
dart run tools/analyze_project.dart
```

## Notes

- **Backup before removal**: Always use git branches for safety
- **Test after changes**: Run full test suite after each phase
- **Verify main.dart**: The analysis shows main.dart as unused, which is suspicious - verify build configuration
- **Enhanced classes**: These are the primary implementations - base classes are extended by them

## Integration with Cleanup Tasks

These tools support the tasks defined in `.kiro/specs/project-cleanup-and-streamlining/tasks.md`:

- **Task 1**: ✅ Create analysis and verification tools (this directory)
- **Task 2**: Use reports to identify files for removal
- **Task 3**: Use reports to identify files to move
- **Task 4**: Use reports to verify service file usage
- **Task 5**: Use reports to guide removal of verified unused files
- **Tasks 6-10**: Use dependency graph to safely refactor and reorganize

## Maintenance

Re-run these tools periodically to:
- Identify new unused files
- Track dependency changes
- Monitor codebase health
- Verify cleanup progress

---

*Last updated: Analysis run on current codebase*
