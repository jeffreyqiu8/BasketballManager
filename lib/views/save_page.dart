import 'package:flutter/material.dart';
import '../services/save_service.dart';
import '../services/league_service.dart';
import '../services/game_service.dart';
import '../models/game_state.dart';
import '../models/season.dart';
import '../models/team.dart';
import '../utils/accessibility_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_indicator.dart';
import 'home_page.dart';

/// SavePage for managing game saves
/// Provides UI for save, load, and delete operations
class SavePage extends StatefulWidget {
  final LeagueService leagueService;
  final Season? currentSeason;
  final String? userTeamId;
  final Function(GameState)? onLoadGame;
  final bool isStartScreen;

  const SavePage({
    super.key,
    required this.leagueService,
    this.currentSeason,
    this.userTeamId,
    this.onLoadGame,
    this.isStartScreen = false,
  });

  @override
  State<SavePage> createState() => _SavePageState();
}

class _SavePageState extends State<SavePage> {
  final SaveService _saveService = SaveService();
  final TextEditingController _saveNameController = TextEditingController();
  List<String> _saves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavesList();
  }

  @override
  void dispose() {
    _saveNameController.dispose();
    super.dispose();
  }

  /// Load the list of available saves
  Future<void> _loadSavesList() async {
    setState(() {
      _isLoading = true;
    });

    final saves = await _saveService.listSaves();

    setState(() {
      _saves = saves;
      _isLoading = false;
    });
  }

  /// Show dialog to create a new save
  /// Includes accessibility features for screen readers and keyboard navigation
  Future<void> _showSaveDialog() async {
    if (widget.currentSeason == null || widget.userTeamId == null) {
      if (mounted) {
        AccessibilityUtils.showAccessibleError(context, 'No active game to save');
      }
      return;
    }

    _saveNameController.clear();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Game'),
        content: Semantics(
          label: 'Enter save name',
          textField: true,
          child: TextField(
            controller: _saveNameController,
            decoration: const InputDecoration(
              labelText: 'Save Name',
              hintText: 'Enter a name for your save',
            ),
            autofocus: true,
          ),
        ),
        actions: [
          Semantics(
            label: 'Cancel save',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            label: 'Confirm save',
            button: true,
            child: ElevatedButton(
              onPressed: () {
                final saveName = _saveNameController.text.trim();
                if (saveName.isNotEmpty) {
                  Navigator.of(context).pop(saveName);
                }
              },
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _performSave(result);
    }
  }

  /// Show dialog to create a new save with team selection
  /// Includes accessibility features for screen readers and keyboard navigation
  Future<void> _showNewSaveDialog() async {
    _saveNameController.clear();

    // Step 1: Get save name
    final saveName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Save'),
        content: Semantics(
          label: 'Enter save name',
          textField: true,
          child: TextField(
            controller: _saveNameController,
            decoration: const InputDecoration(
              labelText: 'Save Name',
              hintText: 'Enter a name for your save',
            ),
            autofocus: true,
          ),
        ),
        actions: [
          Semantics(
            label: 'Cancel save creation',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            label: 'Continue to team selection',
            button: true,
            child: ElevatedButton(
              onPressed: () {
                final name = _saveNameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop(name);
                }
              },
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );

    if (saveName == null || saveName.isEmpty) {
      return;
    }

    // Check if save already exists
    final exists = await _saveService.saveExists(saveName);
    if (exists) {
      final overwrite = await _showConfirmDialog(
        'Overwrite Save?',
        'A save with this name already exists. Do you want to overwrite it?',
      );

      if (overwrite != true) {
        return;
      }
    }

    // Step 2: Initialize new league first (so team IDs are fresh)
    if (!mounted) return;
    
    // Show loading indicator while initializing league
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingIndicator(
        message: 'Initializing league...',
      ),
    );

    try {
      // Create a temporary league service for the new game
      final newLeagueService = LeagueService();
      await newLeagueService.initializeLeague();
      
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Step 3: Show team selection dialog with newly initialized teams
      final selectedTeamId = await _showTeamSelectionDialog(newLeagueService);

      if (selectedTeamId == null) {
        return;
      }

      // Step 4: Create new game with selected team
      await _createNewSave(saveName, selectedTeamId, newLeagueService);
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        AccessibilityUtils.showAccessibleError(
          context,
          'Error initializing league: ${e.toString()}',
        );
      }
    }
  }

  /// Show team selection dialog
  /// Returns the selected team ID or null if cancelled
  Future<String?> _showTeamSelectionDialog(LeagueService leagueService) async {
    // Get all teams from the provided league service
    final teams = leagueService.getAllTeams();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TeamSelectionDialog(teams: teams),
    );
  }

  /// Create a new save with the selected team
  Future<void> _createNewSave(
    String saveName,
    String selectedTeamId,
    LeagueService leagueService,
  ) async {
    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingIndicator(
        message: 'Creating new game...',
      ),
    );

    try {
      // Get the selected team (league is already initialized)
      final userTeam = leagueService.getTeam(selectedTeamId);
      if (userTeam == null) {
        throw Exception('Selected team not found');
      }

      // Generate season schedule
      final teams = leagueService.getAllTeams();
      final gameService = GameService();
      final schedule = gameService.generateSchedule(selectedTeamId, teams);
      
      final newSeason = Season(
        id: 'season-2024',
        year: 2024,
        games: schedule,
        userTeamId: selectedTeamId,
      );

      // Create game state
      final gameState = GameState(
        teams: teams,
        currentSeason: newSeason,
        userTeamId: selectedTeamId,
      );

      // Save the game
      final success = await _saveService.saveGame(saveName, gameState);

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        if (success) {
          if (widget.isStartScreen) {
            // Navigate to home page with the new game
            _navigateToHomePage(gameState, leagueService);
          } else {
            AccessibilityUtils.showAccessibleSuccess(
              context,
              'New game created and saved as $saveName',
            );
            await _loadSavesList();
          }
        } else {
          AccessibilityUtils.showAccessibleError(
            context,
            'Failed to create new game',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
        AccessibilityUtils.showAccessibleError(
          context,
          'Error creating new game: ${e.toString()}',
        );
      }
    }
  }

  /// Perform the save operation with accessibility announcements
  Future<void> _performSave(String saveName) async {
    // Check if save already exists
    final exists = await _saveService.saveExists(saveName);
    if (exists) {
      final overwrite = await _showConfirmDialog(
        'Overwrite Save?',
        'A save with this name already exists. Do you want to overwrite it?',
      );

      if (overwrite != true) {
        return;
      }
    }

    // Create game state
    final gameState = GameState(
      teams: widget.leagueService.getAllTeams(),
      currentSeason: widget.currentSeason!,
      userTeamId: widget.userTeamId!,
    );

    // Save the game
    final success = await _saveService.saveGame(saveName, gameState);

    if (mounted) {
      if (success) {
        AccessibilityUtils.showAccessibleSuccess(context, 'Game saved successfully as $saveName');
        await _loadSavesList();
      } else {
        AccessibilityUtils.showAccessibleError(context, 'Failed to save game');
      }
    }
  }

  /// Load a save file with accessibility announcements
  Future<void> _loadSave(String saveName) async {
    final gameState = await _saveService.loadGame(saveName);

    if (gameState == null) {
      if (mounted) {
        AccessibilityUtils.showAccessibleError(context, 'Failed to load save $saveName');
      }
      return;
    }

    if (!mounted) return;

    if (widget.isStartScreen) {
      // Navigate to home page with loaded game
      final leagueService = LeagueService();
      final teamsList = leagueService.getTeamsList();
      teamsList.clear();
      teamsList.addAll(gameState.teams);
      
      _navigateToHomePage(gameState, leagueService);
    } else if (widget.onLoadGame != null) {
      // Call the callback to update the game state
      widget.onLoadGame!(gameState);
      AccessibilityUtils.showAccessibleSuccess(context, 'Game $saveName loaded successfully');
      
      // Navigate back to home
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Navigate to home page with game state
  void _navigateToHomePage(GameState gameState, LeagueService leagueService) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          leagueService: leagueService,
          initialSeason: gameState.currentSeason,
          initialUserTeamId: gameState.userTeamId,
        ),
      ),
    );
  }

  /// Update an existing save with current game state
  /// Includes accessibility announcements for screen readers
  Future<void> _updateSave(String saveName) async {
    if (widget.currentSeason == null || widget.userTeamId == null) {
      if (mounted) {
        AccessibilityUtils.showAccessibleError(context, 'No active game to save');
      }
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Update Save?',
      'Do you want to overwrite "$saveName" with your current game progress?',
    );

    if (confirmed != true) {
      return;
    }

    // Create game state
    final gameState = GameState(
      teams: widget.leagueService.getAllTeams(),
      currentSeason: widget.currentSeason!,
      userTeamId: widget.userTeamId!,
    );

    // Save the game (overwrite existing)
    final success = await _saveService.saveGame(saveName, gameState);

    if (mounted) {
      if (success) {
        AccessibilityUtils.showAccessibleSuccess(context, 'Save $saveName updated successfully');
      } else {
        AccessibilityUtils.showAccessibleError(context, 'Failed to update save $saveName');
      }
    }
  }

  /// Delete a save file with confirmation and accessibility announcements
  Future<void> _deleteSave(String saveName) async {
    final confirmed = await _showConfirmDialog(
      'Delete Save?',
      'Are you sure you want to delete "$saveName"? This action cannot be undone.',
    );

    if (confirmed != true) {
      return;
    }

    final success = await _saveService.deleteSave(saveName);

    if (mounted) {
      if (success) {
        AccessibilityUtils.showAccessibleSuccess(context, 'Save $saveName deleted successfully');
        await _loadSavesList();
      } else {
        AccessibilityUtils.showAccessibleError(context, 'Failed to delete save $saveName');
      }
    }
  }

  /// Show confirmation dialog with accessibility features
  Future<bool?> _showConfirmDialog(String title, String message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => Semantics(
        namesRoute: true,
        label: '$title dialog',
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            Semantics(
              label: 'Cancel',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            Semantics(
              label: 'Confirm action',
              button: true,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Management'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading saves')
          : Column(
              children: [
                // Save buttons
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Semantics(
                          label: 'Create new save with team selection',
                          button: true,
                          child: ElevatedButton.icon(
                            onPressed: _showNewSaveDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Save'),
                            style: ElevatedButton.styleFrom(
                              padding: AppTheme.buttonPaddingMedium,
                            ),
                          ),
                        ),
                      ),
                      if (widget.currentSeason != null && widget.userTeamId != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Semantics(
                            label: 'Save current game',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: _showSaveDialog,
                              icon: const Icon(Icons.save),
                              label: const Text('Save Current Game'),
                              style: OutlinedButton.styleFrom(
                                padding: AppTheme.buttonPaddingMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(),

                // Saves list header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Saved Games',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        '(${_saves.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Saves list
                Expanded(
                  child: _saves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 64,
                                color: isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight,
                              ),
                              const SizedBox(height: AppTheme.spacingMedium),
                              Text(
                                'No saved games',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingSmall),
                              Text(
                                'Create a new save to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _saves.length,
                          itemBuilder: (context, index) {
                            final saveName = _saves[index];
                            return Semantics(
                              label: 'Save file: $saveName',
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMedium,
                                  vertical: AppTheme.spacingSmall,
                                ),
                                elevation: AppTheme.cardElevationMedium,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.save_alt,
                                    size: 32,
                                  ),
                                  title: Text(
                                    saveName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        label: 'Update save: $saveName',
                                        button: true,
                                        child: IconButton(
                                          icon: const Icon(Icons.upload),
                                          color: isDark ? AppTheme.warningColorDark : AppTheme.warningColor,
                                          onPressed: (widget.currentSeason != null && 
                                                     widget.userTeamId != null)
                                              ? () => _updateSave(saveName)
                                              : null,
                                          tooltip: 'Update',
                                        ),
                                      ),
                                      Semantics(
                                        label: 'Load save: $saveName',
                                        button: true,
                                        child: IconButton(
                                          icon: const Icon(Icons.folder_open),
                                          color: isDark ? AppTheme.infoColorDark : AppTheme.infoColor,
                                          onPressed: () => _loadSave(saveName),
                                          tooltip: 'Load',
                                        ),
                                      ),
                                      Semantics(
                                        label: 'Delete save: $saveName',
                                        button: true,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                                          onPressed: () => _deleteSave(saveName),
                                          tooltip: 'Delete',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Team selection dialog widget
/// Displays all 30 teams with search/filter functionality
class _TeamSelectionDialog extends StatefulWidget {
  final List<Team> teams;

  const _TeamSelectionDialog({required this.teams});

  @override
  State<_TeamSelectionDialog> createState() => _TeamSelectionDialogState();
}

class _TeamSelectionDialogState extends State<_TeamSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Team> _filteredTeams = [];
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _filteredTeams = List.from(widget.teams);
    _searchController.addListener(_filterTeams);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTeams() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = List.from(widget.teams);
      } else {
        _filteredTeams = widget.teams.where((team) {
          final cityName = '${team.city} ${team.name}'.toLowerCase();
          return cityName.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      namesRoute: true,
      label: 'Select your team dialog',
      child: AlertDialog(
        title: const Text('Select Your Team'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              // Search field
              Semantics(
                label: 'Search teams by city or name',
                textField: true,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Teams',
                    hintText: 'Enter city or team name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? Semantics(
                            label: 'Clear search',
                            button: true,
                            child: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Results count
              Semantics(
                label: '${_filteredTeams.length} teams found',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_filteredTeams.length} teams',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Teams list
              Expanded(
                child: _filteredTeams.isEmpty
                    ? Center(
                        child: Text(
                          'No teams found',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = _filteredTeams[index];
                          final isSelected = _selectedTeamId == team.id;
                          
                          return Semantics(
                            label: 'Select ${team.city} ${team.name}, overall rating ${team.teamRating}',
                            button: true,
                            selected: isSelected,
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 0,
                              ),
                              elevation: isSelected ? 4 : 1,
                              color: isSelected
                                  ? (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withValues(alpha: 0.2)
                                  : null,
                              child: ListTile(
                                leading: Icon(
                                  Icons.sports_basketball,
                                  color: isSelected
                                      ? (isDark ? AppTheme.infoColorDark : AppTheme.infoColor)
                                      : null,
                                ),
                                title: Text(
                                  '${team.city} ${team.name}',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text('Overall: ${team.teamRating}'),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedTeamId = team.id;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          Semantics(
            label: 'Cancel team selection',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            label: _selectedTeamId == null
                ? 'Select a team to continue'
                : 'Confirm team selection',
            button: true,
            enabled: _selectedTeamId != null,
            child: ElevatedButton(
              onPressed: _selectedTeamId == null
                  ? null
                  : () => Navigator.of(context).pop(_selectedTeamId),
              child: const Text('Select Team'),
            ),
          ),
        ],
      ),
    );
  }
}
