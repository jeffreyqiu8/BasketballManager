import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../gameData/save_creation_data.dart';
import '../../gameData/save_manager.dart';
import '../../gameData/enums.dart';
import '../widgets/team_selection_widget.dart';
import '../widgets/coach_creation_widget.dart';
import '../widgets/league_settings_widget.dart';
import '../widgets/difficulty_settings_widget.dart';
import '../widgets/smooth_animations.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';
import '../widget_tree.dart';

/// Enhanced save creation page with multi-step wizard interface
class SaveCreationPage extends StatefulWidget {
  const SaveCreationPage({super.key});

  @override
  State<SaveCreationPage> createState() => _SaveCreationPageState();
}

class _SaveCreationPageState extends State<SaveCreationPage> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  int _currentStep = 0;
  final int _totalSteps = 5;
  
  // Save creation data
  late SaveCreationData _saveData;
  
  // Form controllers
  final TextEditingController _saveNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // Loading state
  bool _isCreating = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSaveData();
  }
  
  void _initializeSaveData() {
    _saveData = SaveCreationData(
      saveName: '',
      description: '',
      selectedTeam: '',
      coachData: CoachCreationData(
        name: '',
        primarySpecialization: CoachingSpecialization.offensive,
      ),
      difficulty: DifficultySettings.normal(),
      leagueSettings: LeagueSettings.nbaStyle(),
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _saveNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _saveNameController.text.isNotEmpty;
      case 1: // Team Selection
        return _saveData.selectedTeam.isNotEmpty;
      case 2: // Coach Creation
        return _saveData.coachData.name.isNotEmpty;
      case 3: // League Settings
        return _saveData.leagueSettings.isValid();
      case 4: // Difficulty Settings
        return true; // Always valid
      default:
        return false;
    }
  }
  
  Future<void> _createSave() async {
    if (!_saveData.isValid()) {
      _showErrorDialog('Please complete all required fields.');
      return;
    }
    
    setState(() {
      _isCreating = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Update save data with form values
      _saveData = SaveCreationData(
        saveName: _saveNameController.text,
        description: _descriptionController.text,
        selectedTeam: _saveData.selectedTeam,
        coachData: _saveData.coachData,
        difficulty: _saveData.difficulty,
        leagueSettings: _saveData.leagueSettings,
        useRealTeams: _saveData.useRealTeams,
        startingSeason: _saveData.startingSeason,
      );
      
      final saveManager = SaveManager();
      final saveId = await saveManager.createNewSave(_saveData, user.uid);
      
      if (mounted) {
        _showSuccessDialog(saveId);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create save: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessDialog(String saveId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Created Successfully!'),
        content: Text('Your save "${_saveData.saveName}" has been created. What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to saves list
            },
            child: const Text('View Saves'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                // Load the created save and start playing
                final saveManager = SaveManager();
                final user = FirebaseAuth.instance.currentUser!;
                final game = await saveManager.loadSave(saveId, user.uid);
                
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WidgetTree(game: game),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showErrorDialog('Failed to load save: $e');
                }
              }
            },
            child: const Text('Start Playing'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Save'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          HelpButton(
            contextId: 'save_creation',
            tooltip: 'Get help with save creation',
          ),
          FeedbackButton(
            feature: 'Save Creation',
            tooltip: 'Give feedback on save creation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator with animation
          SmoothFadeTransition(
            duration: const Duration(milliseconds: 500),
            child: _buildProgressIndicator(),
          ),
          
          // Page content with slide transitions
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SmoothSlideTransition(
                  visible: _currentStep == 0,
                  child: _buildBasicInfoStep(),
                ),
                SmoothSlideTransition(
                  visible: _currentStep == 1,
                  child: _buildTeamSelectionStep(),
                ),
                SmoothSlideTransition(
                  visible: _currentStep == 2,
                  child: _buildCoachCreationStep(),
                ),
                SmoothSlideTransition(
                  visible: _currentStep == 3,
                  child: _buildLeagueSettingsStep(),
                ),
                SmoothSlideTransition(
                  visible: _currentStep == 4,
                  child: _buildDifficultySettingsStep(),
                ),
              ],
            ),
          ),
          
          // Navigation buttons with animations
          SmoothFadeTransition(
            duration: const Duration(milliseconds: 300),
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Semantics(
      label: 'Save creation progress: Step ${_currentStep + 1} of $_totalSteps',
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_totalSteps, (index) {
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= _currentStep 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade300,
                    boxShadow: isCurrent ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              key: ValueKey('check'),
                            )
                          : Text(
                              '${index + 1}',
                              key: ValueKey('number_$index'),
                              style: TextStyle(
                                color: index <= _currentStep ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            AnimatedProgressBar(
              value: (_currentStep + 1) / _totalSteps,
              duration: const Duration(milliseconds: 500),
              height: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 4),
            Text(
              _getStepTitle(_currentStep),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Basic Information';
      case 1: return 'Team Selection';
      case 2: return 'Coach Creation';
      case 3: return 'League Settings';
      case 4: return 'Difficulty Settings';
      default: return 'Step ${step + 1}';
    }
  }
  
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                HelpButton(
                  contextId: 'save_creation_basic',
                  tooltip: 'Help with basic information',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AccessibleTextField(
              label: 'Save Name',
              hint: 'Enter a name for your save file',
              controller: _saveNameController,
              required: true,
              onChanged: (value) {
                setState(() {}); // Trigger rebuild to update button state
              },
              semanticLabel: 'Save name input field, required',
            ),
            const SizedBox(height: 16),
            AccessibleTextField(
              label: 'Description',
              hint: 'Describe your save file (optional)',
              controller: _descriptionController,
              maxLines: 3,
              semanticLabel: 'Save description input field, optional',
            ),
            const SizedBox(height: 24),
            AccessibleCard(
              semanticLabel: 'Information about next steps in save creation',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What\'s Next?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('After naming your save, you\'ll complete these steps:'),
                  const SizedBox(height: 8),
                  _buildNextStepItem(Icons.sports_basketball, 'Choose your team from 30 NBA franchises'),
                  _buildNextStepItem(Icons.person, 'Create your coach profile and specializations'),
                  _buildNextStepItem(Icons.settings, 'Configure league settings and structure'),
                  _buildNextStepItem(Icons.tune, 'Set difficulty and gameplay preferences'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamSelectionStep() {
    return TeamSelectionWidget(
      selectedTeam: _saveData.selectedTeam,
      onTeamSelected: (team) {
        setState(() {
          _saveData = SaveCreationData(
            saveName: _saveData.saveName,
            description: _saveData.description,
            selectedTeam: team,
            coachData: _saveData.coachData,
            difficulty: _saveData.difficulty,
            leagueSettings: _saveData.leagueSettings,
            useRealTeams: _saveData.useRealTeams,
            startingSeason: _saveData.startingSeason,
          );
        });
      },
    );
  }
  
  Widget _buildCoachCreationStep() {
    return CoachCreationWidget(
      coachData: _saveData.coachData,
      onCoachDataChanged: (coachData) {
        setState(() {
          _saveData = SaveCreationData(
            saveName: _saveData.saveName,
            description: _saveData.description,
            selectedTeam: _saveData.selectedTeam,
            coachData: coachData,
            difficulty: _saveData.difficulty,
            leagueSettings: _saveData.leagueSettings,
            useRealTeams: _saveData.useRealTeams,
            startingSeason: _saveData.startingSeason,
          );
        });
      },
    );
  }
  
  Widget _buildLeagueSettingsStep() {
    return LeagueSettingsWidget(
      leagueSettings: _saveData.leagueSettings,
      onSettingsChanged: (settings) {
        setState(() {
          _saveData = SaveCreationData(
            saveName: _saveData.saveName,
            description: _saveData.description,
            selectedTeam: _saveData.selectedTeam,
            coachData: _saveData.coachData,
            difficulty: _saveData.difficulty,
            leagueSettings: settings,
            useRealTeams: _saveData.useRealTeams,
            startingSeason: _saveData.startingSeason,
          );
        });
      },
    );
  }
  
  Widget _buildDifficultySettingsStep() {
    return DifficultySettingsWidget(
      difficulty: _saveData.difficulty,
      onDifficultyChanged: (difficulty) {
        setState(() {
          _saveData = SaveCreationData(
            saveName: _saveData.saveName,
            description: _saveData.description,
            selectedTeam: _saveData.selectedTeam,
            coachData: _saveData.coachData,
            difficulty: difficulty,
            leagueSettings: _saveData.leagueSettings,
            useRealTeams: _saveData.useRealTeams,
            startingSeason: _saveData.startingSeason,
          );
        });
      },
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _currentStep > 0
              ? AccessibleButton(
                  text: 'Previous',
                  icon: Icons.arrow_back,
                  onPressed: _previousStep,
                  semanticLabel: 'Go to previous step',
                )
              : const SizedBox.shrink(),
          
          // Step indicator
          if (_currentStep > 0 && _currentStep < _totalSteps - 1)
            Text(
              'Step ${_currentStep + 1} of $_totalSteps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          
          // Next/Create button
          _currentStep < _totalSteps - 1
              ? AccessibleButton(
                  text: 'Next',
                  icon: Icons.arrow_forward,
                  onPressed: _canProceed() ? _nextStep : null,
                  semanticLabel: 'Continue to next step',
                )
              : AccessibleButton(
                  text: 'Create Save',
                  icon: Icons.save,
                  onPressed: _canProceed() && !_isCreating ? _createSave : null,
                  isLoading: _isCreating,
                  semanticLabel: 'Create the new save file',
                ),
        ],
      ),
    );
  }
}