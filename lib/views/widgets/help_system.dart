import 'package:flutter/material.dart';

/// Help system for providing contextual assistance and tutorials
class HelpSystem {
  static final HelpSystem _instance = HelpSystem._internal();
  factory HelpSystem() => _instance;
  HelpSystem._internal();

  final Map<String, HelpContent> _helpContent = {};
  final Map<String, Tutorial> _tutorials = {};
  bool _isEnabled = true;

  /// Register help content for a specific context
  void registerHelpContent(String contextId, HelpContent content) {
    _helpContent[contextId] = content;
  }

  /// Register a tutorial
  void registerTutorial(String tutorialId, Tutorial tutorial) {
    _tutorials[tutorialId] = tutorial;
  }

  /// Get help content for a context
  HelpContent? getHelpContent(String contextId) {
    return _helpContent[contextId];
  }

  /// Get tutorial by ID
  Tutorial? getTutorial(String tutorialId) {
    return _tutorials[tutorialId];
  }

  /// Show help dialog for a context
  void showHelp(BuildContext context, String contextId) {
    final content = getHelpContent(contextId);
    if (content != null && _isEnabled) {
      showDialog(
        context: context,
        builder: (context) => HelpDialog(content: content),
      );
    }
  }

  /// Start a tutorial
  void startTutorial(BuildContext context, String tutorialId) {
    final tutorial = getTutorial(tutorialId);
    if (tutorial != null && _isEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TutorialScreen(tutorial: tutorial),
        ),
      );
    }
  }

  /// Enable or disable help system
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Get all available tutorials
  List<Tutorial> getAllTutorials() {
    return _tutorials.values.toList();
  }

  /// Initialize default help content
  void initializeDefaultContent() {
    // Coach Profile Help
    registerHelpContent('coach_profile', HelpContent(
      title: 'Coach Profile',
      sections: [
        HelpSection(
          title: 'Coaching Specializations',
          content: 'Choose your coaching focus to provide bonuses to your team:\n\n'
              '• Offensive: Improves team shooting and ball movement\n'
              '• Defensive: Enhances team defense and steals\n'
              '• Player Development: Accelerates player skill growth\n'
              '• Team Chemistry: Improves player compatibility',
        ),
        HelpSection(
          title: 'Experience and Progression',
          content: 'Gain experience by winning games and developing players. '
              'Higher experience unlocks new coaching abilities and improves your specialization bonuses.',
        ),
      ],
    ));

    // Player Development Help
    registerHelpContent('player_development', HelpContent(
      title: 'Player Development',
      sections: [
        HelpSection(
          title: 'Skill Development',
          content: 'Players gain experience through games and training:\n\n'
              '• Young players (under 25) develop faster\n'
              '• Experience can be allocated to specific skills\n'
              '• Each player has a potential cap for each skill\n'
              '• Coaching specialization affects development speed',
        ),
        HelpSection(
          title: 'Aging and Decline',
          content: 'Players over 30 begin to decline gradually. '
              'Plan for the future by developing younger players and managing veteran minutes.',
        ),
      ],
    ));

    // Playbook Help
    registerHelpContent('playbook_manager', HelpContent(
      title: 'Playbook Management',
      sections: [
        HelpSection(
          title: 'Offensive Strategies',
          content: 'Choose strategies that match your team composition:\n\n'
              '• Fast Break: Emphasizes speed and transition scoring\n'
              '• Half Court: Balanced approach with set plays\n'
              '• Pick and Roll: Requires good guards and big men\n'
              '• Post-Up: Focuses on inside scoring with centers\n'
              '• Three-Point Heavy: Emphasizes perimeter shooting',
        ),
        HelpSection(
          title: 'Defensive Strategies',
          content: 'Defensive schemes affect opponent shooting:\n\n'
              '• Man-to-Man: Balanced defense\n'
              '• Zone Defense: Protects the paint\n'
              '• Press Defense: Forces turnovers but allows easy shots\n'
              '• Switch Defense: Requires versatile defenders',
        ),
      ],
    ));

    // Player Roles Help
    registerHelpContent('player_roles', HelpContent(
      title: 'Player Roles',
      sections: [
        HelpSection(
          title: 'Position Requirements',
          content: 'Each position has specific skill requirements:\n\n'
              '• Point Guard: Ball handling and passing\n'
              '• Shooting Guard: Shooting and perimeter defense\n'
              '• Small Forward: Balanced skills\n'
              '• Power Forward: Rebounding and inside play\n'
              '• Center: Post defense and rebounding',
        ),
        HelpSection(
          title: 'Role Compatibility',
          content: 'Players perform better in roles that match their skills. '
              'Check compatibility ratings when assigning positions.',
        ),
      ],
    ));

    // Initialize tutorials
    _initializeTutorials();
  }

  void _initializeTutorials() {
    // Getting Started Tutorial
    registerTutorial('getting_started', Tutorial(
      id: 'getting_started',
      title: 'Getting Started',
      description: 'Learn the basics of managing your basketball team',
      steps: [
        TutorialStep(
          title: 'Welcome to Basketball Manager',
          content: 'This tutorial will guide you through the essential features of the game.',
          image: 'assets/images/tutorial/welcome.png',
        ),
        TutorialStep(
          title: 'Your Team',
          content: 'Start by exploring your team roster. Each player has unique skills and a position.',
          image: 'assets/images/tutorial/team.png',
        ),
        TutorialStep(
          title: 'Coach Profile',
          content: 'Set up your coaching profile to provide bonuses to your team.',
          image: 'assets/images/tutorial/coach.png',
        ),
        TutorialStep(
          title: 'Player Roles',
          content: 'Assign roles to your players based on their skills for optimal performance.',
          image: 'assets/images/tutorial/roles.png',
        ),
        TutorialStep(
          title: 'Playbooks',
          content: 'Create playbooks with offensive and defensive strategies.',
          image: 'assets/images/tutorial/playbooks.png',
        ),
      ],
    ));

    // Advanced Features Tutorial
    registerTutorial('advanced_features', Tutorial(
      id: 'advanced_features',
      title: 'Advanced Features',
      description: 'Master the advanced systems for competitive play',
      steps: [
        TutorialStep(
          title: 'Player Development',
          content: 'Learn how to develop your players\' skills over time through training and experience.',
          image: 'assets/images/tutorial/development.png',
        ),
        TutorialStep(
          title: 'Conference Management',
          content: 'Navigate the conference system, track standings, and plan for playoffs.',
          image: 'assets/images/tutorial/conference.png',
        ),
        TutorialStep(
          title: 'Strategy Optimization',
          content: 'Fine-tune your playbooks and coaching approach for maximum effectiveness.',
          image: 'assets/images/tutorial/strategy.png',
        ),
      ],
    ));
  }
}

/// Help content structure
class HelpContent {
  final String title;
  final List<HelpSection> sections;
  final String? videoUrl;
  final List<String>? relatedTopics;

  HelpContent({
    required this.title,
    required this.sections,
    this.videoUrl,
    this.relatedTopics,
  });
}

/// Help section within content
class HelpSection {
  final String title;
  final String content;
  final String? imageUrl;

  HelpSection({
    required this.title,
    required this.content,
    this.imageUrl,
  });
}

/// Tutorial structure
class Tutorial {
  final String id;
  final String title;
  final String description;
  final List<TutorialStep> steps;
  final String? category;

  Tutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.category,
  });
}

/// Individual tutorial step
class TutorialStep {
  final String title;
  final String content;
  final String? image;
  final String? videoUrl;
  final Map<String, dynamic>? interactiveElements;

  TutorialStep({
    required this.title,
    required this.content,
    this.image,
    this.videoUrl,
    this.interactiveElements,
  });
}

/// Help dialog widget
class HelpDialog extends StatelessWidget {
  final HelpContent content;

  const HelpDialog({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  content.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close help',
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: content.sections.length,
                itemBuilder: (context, index) {
                  final section = content.sections[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(section.content),
                          if (section.imageUrl != null) ...[
                            SizedBox(height: 8),
                            Image.asset(
                              section.imageUrl!,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 150,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (content.relatedTopics != null) ...[
              Divider(),
              Text(
                'Related Topics',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: content.relatedTopics!
                    .map((topic) => Chip(label: Text(topic)))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tutorial screen widget
class TutorialScreen extends StatefulWidget {
  final Tutorial tutorial;

  const TutorialScreen({super.key, required this.tutorial});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int currentStep = 0;
  PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep < widget.tutorial.steps.length - 1) {
      setState(() {
        currentStep++;
      });
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tutorial.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentStep + 1) / widget.tutorial.steps.length,
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = index;
                });
              },
              itemCount: widget.tutorial.steps.length,
              itemBuilder: (context, index) {
                final step = widget.tutorial.steps[index];
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${index + 1} of ${widget.tutorial.steps.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: 8),
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      if (step.image != null) ...[
                        Center(
                          child: Image.asset(
                            step.image!,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            step.content,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Navigation buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: currentStep > 0 ? previousStep : null,
                  child: Text('Previous'),
                ),
                Text(
                  '${currentStep + 1} / ${widget.tutorial.steps.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ElevatedButton(
                  onPressed: nextStep,
                  child: Text(
                    currentStep < widget.tutorial.steps.length - 1
                        ? 'Next'
                        : 'Finish',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Help button widget for easy access
class HelpButton extends StatelessWidget {
  final String contextId;
  final IconData icon;
  final String tooltip;

  const HelpButton({
    super.key,
    required this.contextId,
    this.icon = Icons.help_outline,
    this.tooltip = 'Get help',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => HelpSystem().showHelp(context, contextId),
    );
  }
}

/// Tutorial launcher widget
class TutorialLauncher extends StatelessWidget {
  final String tutorialId;
  final Widget child;

  const TutorialLauncher({
    super.key,
    required this.tutorialId,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HelpSystem().startTutorial(context, tutorialId),
      child: child,
    );
  }
}