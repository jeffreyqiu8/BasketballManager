import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/playbook.dart';
import 'package:BasketballManager/gameData/playbook_service.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enums.dart';

class InGameStrategySelector extends StatefulWidget {
  final EnhancedTeam team;
  final Function(Playbook)? onStrategyChanged;
  final bool isGameActive;

  const InGameStrategySelector({
    super.key,
    required this.team,
    this.onStrategyChanged,
    this.isGameActive = false,
  });

  @override
  State<InGameStrategySelector> createState() => _InGameStrategySelectorState();
}

class _InGameStrategySelectorState extends State<InGameStrategySelector> {
  late PlaybookLibrary _playbookLibrary;
  List<PlaybookRecommendation> _recommendations = [];
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playbookLibrary = widget.team.playbookLibrary;
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _recommendations = PlaybookService.recommendPlaybooks(widget.team);
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isGameActive 
            ? Colors.orange[400]! 
            : Colors.grey[600]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with current strategy
          _buildHeader(),
          
          // Expandable content
          if (_isExpanded) ...[
            const Divider(color: Colors.grey, height: 1),
            _buildExpandedContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    Playbook? activePlaybook = _playbookLibrary.activePlaybook;
    double effectiveness = activePlaybook != null 
      ? PlaybookService.calculateStrategyEffectiveness(activePlaybook, widget.team)
      : 0.0;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.sports_basketball,
              color: widget.isGameActive ? Colors.orange[400] : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strategy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activePlaybook?.name ?? 'No Strategy',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (activePlaybook != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${activePlaybook.offensiveStrategy.displayName} • ${activePlaybook.defensiveStrategy.displayName}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            if (activePlaybook != null)
              _buildEffectivenessIndicator(effectiveness),
            
            const SizedBox(width: 8),
            
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick strategy buttons
          _buildQuickStrategyButtons(),
          
          const SizedBox(height: 12),
          
          // Available playbooks
          if (_playbookLibrary.playbooks.isNotEmpty) ...[
            _buildPlaybooksList(),
            const SizedBox(height: 12),
          ],
          
          // Real-time recommendations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildQuickStrategyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Adjustments',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickStrategyButton(
              'Aggressive',
              Icons.trending_up,
              Colors.red[400]!,
              () => _applyQuickStrategy('aggressive'),
            ),
            _buildQuickStrategyButton(
              'Defensive',
              Icons.shield,
              Colors.blue[400]!,
              () => _applyQuickStrategy('defensive'),
            ),
            _buildQuickStrategyButton(
              'Balanced',
              Icons.balance,
              Colors.green[400]!,
              () => _applyQuickStrategy('balanced'),
            ),
            _buildQuickStrategyButton(
              'Fast Pace',
              Icons.speed,
              Colors.orange[400]!,
              () => _applyQuickStrategy('fast_pace'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStrategyButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: color, width: 1),
      ),
    );
  }

  Widget _buildPlaybooksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Playbooks',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 8),
        
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _playbookLibrary.playbooks.length,
            itemBuilder: (context, index) {
              Playbook playbook = _playbookLibrary.playbooks[index];
              bool isActive = _playbookLibrary.activePlaybook == playbook;
              double effectiveness = PlaybookService.calculateStrategyEffectiveness(
                playbook, 
                widget.team
              );
              
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                child: _buildPlaybookCard(playbook, isActive, effectiveness),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybookCard(Playbook playbook, bool isActive, double effectiveness) {
    return InkWell(
      onTap: () => _selectPlaybook(playbook),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive 
            ? const Color.fromARGB(255, 82, 50, 168).withValues(alpha: 0.3)
            : Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: isActive 
            ? Border.all(color: const Color.fromARGB(255, 82, 50, 168), width: 2)
            : Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    playbook.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color.fromARGB(255, 82, 50, 168) : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: const Color.fromARGB(255, 82, 50, 168),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            
            Text(
              playbook.offensiveStrategy.displayName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              playbook.defensiveStrategy.displayName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            _buildEffectivenessIndicator(effectiveness),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'AI Recommendations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_recommendations.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  'No recommendations available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          )
        else
          ..._recommendations.take(2).map((recommendation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildRecommendationItem(recommendation),
            );
          }),
      ],
    );
  }

  Widget _buildRecommendationItem(PlaybookRecommendation recommendation) {
    return InkWell(
      onTap: () => _selectPlaybook(recommendation.playbook),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[800]?.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[600]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Colors.amber[400],
            ),
            const SizedBox(width: 8),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.playbook.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    recommendation.reason,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[300],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            _buildEffectivenessIndicator(recommendation.effectiveness),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectivenessIndicator(double effectiveness) {
    Color color;
    String label;
    
    if (effectiveness >= 0.8) {
      color = Colors.green[400]!;
      label = 'Excellent';
    } else if (effectiveness >= 0.6) {
      color = Colors.orange[400]!;
      label = 'Good';
    } else if (effectiveness >= 0.4) {
      color = Colors.yellow[600]!;
      label = 'Fair';
    } else {
      color = Colors.red[400]!;
      label = 'Poor';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '${(effectiveness * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _selectPlaybook(Playbook playbook) {
    setState(() {
      _playbookLibrary.setActivePlaybook(playbook.name);
    });
    
    if (widget.onStrategyChanged != null) {
      widget.onStrategyChanged!(playbook);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Strategy changed to ${playbook.name}'),
        backgroundColor: const Color.fromARGB(255, 82, 50, 168),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyQuickStrategy(String strategyType) {
    Playbook? newPlaybook;
    
    switch (strategyType) {
      case 'aggressive':
        newPlaybook = Playbook.createPreset('run_and_gun');
        break;
      case 'defensive':
        newPlaybook = Playbook.createPreset('defensive_minded');
        break;
      case 'balanced':
        newPlaybook = Playbook.createPreset('balanced_attack');
        break;
      case 'fast_pace':
        newPlaybook = PlaybookService.createPlaybook(
          name: 'Fast Pace',
          offensiveStrategy: OffensiveStrategy.fastBreak,
          defensiveStrategy: DefensiveStrategy.pressDefense,
        );
        break;
    }
    
    if (newPlaybook != null) {
      // Add to library if not already there
      bool exists = _playbookLibrary.playbooks.any((p) => p.name == newPlaybook!.name);
      if (!exists) {
        _playbookLibrary.addPlaybook(newPlaybook);
      }
      
      _selectPlaybook(newPlaybook);
    }
  }
}