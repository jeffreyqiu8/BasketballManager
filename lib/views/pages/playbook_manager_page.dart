import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enums.dart';
import '../widgets/accessible_widgets.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

class PlaybookManagerPage extends StatefulWidget {
  final EnhancedTeam team;
  final PlaybookLibrary? initialLibrary;

  const PlaybookManagerPage({
    super.key,
    required this.team,
    this.initialLibrary,
  });

  @override
  State<PlaybookManagerPage> createState() => _PlaybookManagerPageState();
}

class _PlaybookManagerPageState extends State<PlaybookManagerPage> {
  late PlaybookLibrary _playbookLibrary;
  String _selectedTab = 'library';
  List<Playbook> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _initializePlaybookLibrary();
    _loadRecommendations();
  }

  void _initializePlaybookLibrary() {
    if (widget.initialLibrary != null) {
      _playbookLibrary = widget.initialLibrary!;
    } else {
      _playbookLibrary = PlaybookLibrary();
      _playbookLibrary.initializeWithDefaults();
    }
    // Active playbook is managed by the library
  }

  Future<void> _loadRecommendations() async {
    // Load playbook recommendations

    try {
      // Create some basic recommended playbooks
      _recommendations = [
        Playbook(
          name: 'Balanced Attack',
          offensiveStrategy: OffensiveStrategy.halfCourt,
          defensiveStrategy: DefensiveStrategy.manToMan,
        ),
        Playbook(
          name: 'Fast Break',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.pressDefense,
        ),
        Playbook(
          name: 'Three Point Heavy',
          offensiveStrategy: OffensiveStrategy.threePointHeavy,
          defensiveStrategy: DefensiveStrategy.manToMan,
        ),
      ];
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      setState(() {
        // Loading complete
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Playbook Manager',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          HelpButton(contextId: 'playbook_manager'),
          FeedbackButton(feature: 'playbook_manager'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreatePlaybookDialog(),
            tooltip: 'Create new playbook',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: 'Refresh recommendations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _tabButton('Library', 'library')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Create', 'create')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Analysis', 'analysis')),
              ],
            ),
          ),

          // Tab Content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String value) {
    bool isSelected = _selectedTab == value;

    return AccessibleButton(
      text: label,
      onPressed: () {
        setState(() {
          _selectedTab = value;
        });
      },
      backgroundColor:
          isSelected
              ? const Color.fromARGB(255, 82, 50, 168)
              : const Color.fromARGB(255, 44, 44, 44),
      semanticLabel: '$label tab${isSelected ? ' (selected)' : ''}',
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'create':
        return _buildCreateTab();
      case 'analysis':
        return _buildAnalysisTab();
      default:
        return _buildLibraryTab();
    }
  }

  Widget _buildLibraryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Playbook
          if (_playbookLibrary.activePlaybook != null) ...[
            const Text(
              'Active Playbook',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildPlaybookCard(
              _playbookLibrary.activePlaybook!,
              isActive: true,
            ),
            const SizedBox(height: 24),
          ],

          // Available Playbooks
          const Text(
            'Available Playbooks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          if (_playbookLibrary.playbooks.isEmpty)
            const Center(
              child: Text(
                'No playbooks available. Create one to get started!',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(_playbookLibrary.playbooks
                .where((p) => p != _playbookLibrary.activePlaybook)
                .map(
                  (playbook) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPlaybookCard(playbook),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Playbook',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          AccessibleButton(
            text: 'Create Custom Playbook',
            icon: Icons.add_circle,
            onPressed: _showCreatePlaybookDialog,
            semanticLabel: 'Create a new custom playbook',
          ),

          const SizedBox(height: 24),

          if (_recommendations.isNotEmpty) ...[
            const Text(
              'Recommended Playbooks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            ..._recommendations.map(
              (playbook) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPlaybookCard(playbook, showAddButton: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Playbook Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          if (_playbookLibrary.activePlaybook != null)
            _buildPlaybookAnalysis(_playbookLibrary.activePlaybook!)
          else
            const Center(
              child: Text(
                'No active playbook to analyze',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybookCard(
    Playbook playbook, {
    bool isActive = false,
    bool showAddButton = false,
  }) {
    return AccessibleCard(
      onTap: () => _selectPlaybook(playbook),
      semanticLabel:
          '${playbook.name} playbook, ${playbook.offensiveStrategy.name} offense, ${playbook.defensiveStrategy.name} defense${isActive ? ' (currently active)' : ''}',
      semanticHint:
          showAddButton ? 'Tap to add to library' : 'Tap to select playbook',
      selected: isActive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  playbook.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.blue[300] : Colors.white,
                  ),
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (showAddButton)
                AccessibleButton(
                  text: 'Add',
                  onPressed: () => _addPlaybook(playbook),
                  semanticLabel: 'Add ${playbook.name} to library',
                ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Offense: ${playbook.offensiveStrategy.displayName}',
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            'Defense: ${playbook.defensiveStrategy.displayName}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybookAnalysis(Playbook playbook) {
    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis: ${playbook.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Effectiveness Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          _buildEffectivenessBar('Overall', 0.85),
          const SizedBox(height: 8),
          _buildEffectivenessBar('Offensive', 0.80),
          const SizedBox(height: 8),
          _buildEffectivenessBar('Defensive', 0.75),

          const SizedBox(height: 16),

          const Text(
            'Strengths',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            '• Balanced approach suitable for most situations\n'
            '• Good ball movement and spacing\n'
            '• Solid defensive fundamentals',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectivenessBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _selectPlaybook(Playbook playbook) {
    setState(() {
      _playbookLibrary.setActivePlaybook(playbook.name);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${playbook.name} is now active'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addPlaybook(Playbook playbook) {
    _playbookLibrary.addPlaybook(playbook);
    setState(() {
      _recommendations.remove(playbook);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${playbook.name} added to library'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCreatePlaybookDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CreatePlaybookDialog(
            onPlaybookCreated: (playbook) {
              _playbookLibrary.addPlaybook(playbook);
              setState(() {});
            },
          ),
    );
  }
}

class _CreatePlaybookDialog extends StatefulWidget {
  final Function(Playbook) onPlaybookCreated;

  const _CreatePlaybookDialog({required this.onPlaybookCreated});

  @override
  State<_CreatePlaybookDialog> createState() => _CreatePlaybookDialogState();
}

class _CreatePlaybookDialogState extends State<_CreatePlaybookDialog> {
  final _nameController = TextEditingController();
  OffensiveStrategy _offensiveStrategy = OffensiveStrategy.halfCourt;
  DefensiveStrategy _defensiveStrategy = DefensiveStrategy.manToMan;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Playbook',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            AccessibleTextField(
              label: 'Playbook Name',
              controller: _nameController,
              required: true,
              hint: 'Enter playbook name',
            ),

            const SizedBox(height: 16),

            AccessibleDropdown<OffensiveStrategy>(
              label: 'Offensive Strategy',
              value: _offensiveStrategy,
              items:
                  OffensiveStrategy.values.map((strategy) {
                    return DropdownMenuItem(
                      value: strategy,
                      child: Text(strategy.displayName),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _offensiveStrategy = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            AccessibleDropdown<DefensiveStrategy>(
              label: 'Defensive Strategy',
              value: _defensiveStrategy,
              items:
                  DefensiveStrategy.values.map((strategy) {
                    return DropdownMenuItem(
                      value: strategy,
                      child: Text(strategy.displayName),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _defensiveStrategy = value;
                  });
                }
              },
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AccessibleButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                AccessibleButton(
                  text: 'Create',
                  onPressed: _createPlaybook,
                  semanticLabel: 'Create new playbook',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createPlaybook() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a playbook name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final playbook = Playbook(
      name: _nameController.text.trim(),
      offensiveStrategy: _offensiveStrategy,
      defensiveStrategy: _defensiveStrategy,
    );

    widget.onPlaybookCreated(playbook);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${playbook.name} created successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
