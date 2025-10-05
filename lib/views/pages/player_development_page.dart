import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/development_service.dart';
import 'package:BasketballManager/gameData/development_system.dart';
import 'package:BasketballManager/gameData/enums.dart';

class PlayerDevelopmentPage extends StatefulWidget {
  final EnhancedPlayer player;
  final CoachProfile? coach;

  const PlayerDevelopmentPage({
    super.key,
    required this.player,
    this.coach,
  });

  @override
  State<PlayerDevelopmentPage> createState() => _PlayerDevelopmentPageState();
}

class _PlayerDevelopmentPageState extends State<PlayerDevelopmentPage> {
  late EnhancedPlayer _player;
  String _selectedTab = 'development'; // 'development', 'potential', 'milestones'
  String? _selectedSkill;
  int _skillPointsToAllocate = 0;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _calculateAvailableSkillPoints();
  }

  void _calculateAvailableSkillPoints() {
    // Calculate how many skill points can be allocated based on experience
    int totalPoints = 0;
    for (String skill in _player.development.skillExperience.keys) {
      while (_player.development.hasEnoughExperienceForUpgrade(skill)) {
        totalPoints++;
        // Simulate consuming experience to count available upgrades
        final currentExp = _player.development.skillExperience[skill] ?? 0;
        final currentLevel = (currentExp / 100).floor();
        final expToConsume = (currentLevel + 1) * 100;
        _player.development.skillExperience[skill] = currentExp - expToConsume;
      }
    }
    _skillPointsToAllocate = totalPoints;
    
    // Restore original experience values
    _player = widget.player;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          '${_player.name} Development',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_skillPointsToAllocate > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_skillPointsToAllocate points',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
                Expanded(child: _tabButton('Development', 'development')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Potential', 'potential')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Milestones', 'milestones')),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, String value) {
    bool isSelected = _selectedTab == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
          ? const Color.fromARGB(255, 82, 50, 168)
          : const Color.fromARGB(255, 44, 44, 44),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'potential':
        return _buildPotentialTab();
      case 'milestones':
        return _buildMilestonesTab();
      default:
        return _buildDevelopmentTab();
    }
  }

  Widget _buildDevelopmentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Overview Card
          _buildPlayerOverviewCard(),
          const SizedBox(height: 16),
          
          // Coaching Influence Card
          if (widget.coach != null) ...[
            _buildCoachingInfluenceCard(),
            const SizedBox(height: 16),
          ],
          
          // Skill Development Card
          _buildSkillDevelopmentCard(),
          const SizedBox(height: 16),
          
          // Experience Allocation Card
          _buildExperienceAllocationCard(),
        ],
      ),
    );
  }

  Widget _buildPlayerOverviewCard() {
    double overallRating = _calculateOverallRating();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _player.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_player.primaryRole.displayName} • Age ${_player.age}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getOverallRatingColor(overallRating),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      overallRating.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'OVR',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Development Stats
          Row(
            children: [
              Expanded(
                child: _developmentStatItem(
                  'Total XP',
                  '${_player.development.totalExperience}',
                  Icons.star,
                  Colors.purple[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _developmentStatItem(
                  'Dev Rate',
                  '${(_player.development.getCurrentDevelopmentRate(_player.age) * 100).toStringAsFixed(0)}%',
                  Icons.trending_up,
                  Colors.green[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _developmentStatItem(
                  'Potential',
                  _player.potential.tier.displayName,
                  Icons.emoji_events,
                  _getPotentialTierColor(_player.potential.tier),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _developmentStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingInfluenceCard() {
    double developmentBonus = widget.coach!.getDevelopmentBonus();
    double coachingEffectiveness = _calculateCoachingEffectiveness();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.blue[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Coaching Influence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Coach Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.coach!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.coach!.primarySpecialization.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${(developmentBonus * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[400],
                      ),
                    ),
                    Text(
                      'Dev Bonus',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Coaching Effectiveness Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coaching Effectiveness',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                  Text(
                    '${coachingEffectiveness.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[400],
                    ),
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
                  widthFactor: (coachingEffectiveness / 100.0).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillDevelopmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Development Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Skills List
          ..._getSkillsList().map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSkillProgressItem(skill),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSkillProgressItem(String skill) {
    int currentValue = _getCurrentSkillValue(skill);
    int maxPotential = _player.potential.maxSkills[skill] ?? 99;
    int experience = _player.development.skillExperience[skill] ?? 0;
    int expForNext = _player.development.getExperienceForNextSkillPoint(skill);
    bool canUpgrade = _player.development.canUpgradeSkill(skill, _player.potential, currentValue);
    
    double progressPercentage = (experience % 100) / 100.0;
    Color skillColor = _getSkillColor(skill);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: _selectedSkill == skill 
          ? Border.all(color: skillColor, width: 2)
          : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedSkill = _selectedSkill == skill ? null : skill;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSkillIcon(skill),
                  color: skillColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSkillDisplayName(skill),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$currentValue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: skillColor,
                  ),
                ),
                Text(
                  '/$maxPotential',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                if (canUpgrade) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'UP',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            // Experience Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience: $experience',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      'Next: $expForNext XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: skillColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Skill Details (when selected)
            if (_selectedSkill == skill) ...[
              const SizedBox(height: 12),
              _buildSkillDetails(skill),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillDetails(String skill) {
    int currentValue = _getCurrentSkillValue(skill);
    int maxPotential = _player.potential.maxSkills[skill] ?? 99;
    int remainingPotential = maxPotential - currentValue;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _skillDetailItem('Current', '$currentValue'),
              ),
              Expanded(
                child: _skillDetailItem('Potential', '$maxPotential'),
              ),
              Expanded(
                child: _skillDetailItem('Remaining', '$remainingPotential'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            _getSkillDescription(skill),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceAllocationCard() {
    if (_skillPointsToAllocate == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'No skill points available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Play games and train to gain experience',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upgrade,
                color: Colors.green[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Skill Point Allocation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_skillPointsToAllocate available',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'Select skills to upgrade with available experience points:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          
          // Upgradeable Skills
          ..._getUpgradeableSkills().map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildUpgradeSkillItem(skill),
            );
          }),
          
          if (_getUpgradeableSkills().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processAllUpgrades,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply All Upgrades',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradeSkillItem(String skill) {
    int currentValue = _getCurrentSkillValue(skill);
    Color skillColor = _getSkillColor(skill);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[400]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _getSkillIcon(skill),
            color: skillColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSkillDisplayName(skill),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$currentValue → ${currentValue + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _upgradeSkill(skill),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  } 
 Widget _buildPotentialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Potential Overview Card
          _buildPotentialOverviewCard(),
          const SizedBox(height: 16),
          
          // Potential Breakdown Card
          _buildPotentialBreakdownCard(),
          const SizedBox(height: 16),
          
          // Aging Curve Card
          _buildAgingCurveCard(),
        ],
      ),
    );
  }

  Widget _buildPotentialOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: _getPotentialTierColor(_player.potential.tier),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Player Potential',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_player.potential.isHidden)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'HIDDEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Potential Tier Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPotentialTierColor(_player.potential.tier).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPotentialTierColor(_player.potential.tier),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_player.potential.tier.displayName} Potential',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getPotentialTierColor(_player.potential.tier),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _player.potential.tier.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_player.potential.overallPotential}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _getPotentialTierColor(_player.potential.tier),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Potential Stats
          Row(
            children: [
              Expanded(
                child: _potentialStatItem(
                  'Current OVR',
                  _calculateOverallRating().toStringAsFixed(0),
                  Icons.person,
                  Colors.blue[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _potentialStatItem(
                  'Max OVR',
                  '${_player.potential.overallPotential}',
                  Icons.trending_up,
                  Colors.green[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _potentialStatItem(
                  'Growth Left',
                  '${_player.potential.overallPotential - _calculateOverallRating().toInt()}',
                  Icons.arrow_upward,
                  Colors.orange[400]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _potentialStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPotentialBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Potential Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._getSkillsList().map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPotentialSkillItem(skill),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPotentialSkillItem(String skill) {
    int currentValue = _getCurrentSkillValue(skill);
    int maxPotential = _player.potential.maxSkills[skill] ?? 99;
    int remainingGrowth = maxPotential - currentValue;
    double progressPercentage = currentValue / maxPotential;
    
    Color skillColor = _getSkillColor(skill);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSkillIcon(skill),
                color: skillColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getSkillDisplayName(skill),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$currentValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: skillColor,
                ),
              ),
              Text(
                ' / $maxPotential',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+$remainingGrowth',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: remainingGrowth > 0 ? Colors.green[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: skillColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgingCurveCard() {
    AgingCurve agingCurve = _player.development.agingCurve;
    double currentAgeModifier = agingCurve.getAgeModifier(_player.age);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Development Curve',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Age Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAgePhaseColor(_player.age, agingCurve).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getAgePhaseColor(_player.age, agingCurve),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getAgePhaseIcon(_player.age, agingCurve),
                  color: _getAgePhaseColor(_player.age, agingCurve),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAgePhaseDescription(_player.age, agingCurve),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getAgePhaseColor(_player.age, agingCurve),
                        ),
                      ),
                      Text(
                        'Development rate: ${(currentAgeModifier * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Age Milestones
          Column(
            children: [
              _ageMilestoneItem('Peak Age', agingCurve.peakAge, Icons.trending_up),
              _ageMilestoneItem('Decline Starts', agingCurve.declineStartAge, Icons.trending_down),
              _ageMilestoneItem('Retirement Age', agingCurve.retirementAge, Icons.exit_to_app),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ageMilestoneItem(String label, int age, IconData icon) {
    bool isPassed = _player.age >= age;
    Color color = isPassed ? Colors.grey[500]! : Colors.blue[400]!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          Text(
            'Age $age',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (isPassed) ...[
            const SizedBox(width: 8),
            Icon(Icons.check, color: color, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestonesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone Progress Card
          _buildMilestoneProgressCard(),
          const SizedBox(height: 16),
          
          // Milestones List Card
          _buildMilestonesListCard(),
          const SizedBox(height: 16),
          
          // Achievement Celebration Card
          _buildAchievementCelebrationCard(),
        ],
      ),
    );
  }

  Widget _buildMilestoneProgressCard() {
    List<DevelopmentMilestone> milestones = _player.development.milestones;
    int completedMilestones = milestones.where((m) => m.isAchieved).length;
    double progressPercentage = completedMilestones / milestones.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Development Milestones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Overview
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress: $completedMilestones / ${milestones.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progressPercentage * 100).toStringAsFixed(0)}% Complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
                strokeWidth: 6,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercentage,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber[400]!,
                      Colors.orange[400]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesListCard() {
    List<DevelopmentMilestone> milestones = _player.development.milestones;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850]?.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Milestone List',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          ...milestones.map((milestone) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMilestoneItem(milestone),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(DevelopmentMilestone milestone) {
    bool isAchieved = milestone.isAchieved;
    bool canAchieve = _player.development.totalExperience >= milestone.experienceRequired;
    
    Color statusColor = isAchieved 
      ? Colors.green[400]! 
      : canAchieve 
        ? Colors.orange[400]! 
        : Colors.grey[500]!;
    
    IconData statusIcon = isAchieved 
      ? Icons.check_circle 
      : canAchieve 
        ? Icons.radio_button_unchecked 
        : Icons.lock;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: isAchieved 
          ? Border.all(color: Colors.green[400]!, width: 1)
          : canAchieve 
            ? Border.all(color: Colors.orange[400]!, width: 1)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  milestone.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Required: ${milestone.experienceRequired} XP',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (isAchieved && milestone.achievedDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Achieved: ${_formatDate(milestone.achievedDate!)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isAchieved) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_player.development.totalExperience}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  '/ ${milestone.experienceRequired}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementCelebrationCard() {
    // Find recently achieved milestones (within last 7 days)
    List<DevelopmentMilestone> recentAchievements = _player.development.milestones
        .where((milestone) => 
          milestone.isAchieved && 
          milestone.achievedDate != null &&
          DateTime.now().difference(milestone.achievedDate!).inDays <= 7)
        .toList();
    
    if (recentAchievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[850]?.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'No recent achievements',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Keep developing to unlock milestones!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[400]!.withValues(alpha: 0.3),
            Colors.orange[400]!.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[400]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.amber[400],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recent Achievements!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...recentAchievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[400]?.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[400],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[400],
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(achievement.achievedDate!),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  } 
 // Helper methods
  List<String> _getSkillsList() {
    return [
      'shooting',
      'rebounding', 
      'passing',
      'ballHandling',
      'perimeterDefense',
      'postDefense',
      'insideShooting',
    ];
  }

  int _getCurrentSkillValue(String skill) {
    switch (skill) {
      case 'shooting':
        return _player.shooting;
      case 'rebounding':
        return _player.rebounding;
      case 'passing':
        return _player.passing;
      case 'ballHandling':
        return _player.ballHandling;
      case 'perimeterDefense':
        return _player.perimeterDefense;
      case 'postDefense':
        return _player.postDefense;
      case 'insideShooting':
        return _player.insideShooting;
      default:
        return 50;
    }
  }

  String _getSkillDisplayName(String skill) {
    switch (skill) {
      case 'shooting':
        return 'Shooting';
      case 'rebounding':
        return 'Rebounding';
      case 'passing':
        return 'Passing';
      case 'ballHandling':
        return 'Ball Handling';
      case 'perimeterDefense':
        return 'Perimeter Defense';
      case 'postDefense':
        return 'Post Defense';
      case 'insideShooting':
        return 'Inside Shooting';
      default:
        return skill;
    }
  }

  IconData _getSkillIcon(String skill) {
    switch (skill) {
      case 'shooting':
        return Icons.sports_basketball;
      case 'rebounding':
        return Icons.height;
      case 'passing':
        return Icons.swap_horiz;
      case 'ballHandling':
        return Icons.control_camera;
      case 'perimeterDefense':
        return Icons.shield;
      case 'postDefense':
        return Icons.security;
      case 'insideShooting':
        return Icons.gps_fixed;
      default:
        return Icons.sports;
    }
  }

  Color _getSkillColor(String skill) {
    switch (skill) {
      case 'shooting':
        return Colors.orange[400]!;
      case 'rebounding':
        return Colors.purple[400]!;
      case 'passing':
        return Colors.blue[400]!;
      case 'ballHandling':
        return Colors.green[400]!;
      case 'perimeterDefense':
        return Colors.red[400]!;
      case 'postDefense':
        return Colors.brown[400]!;
      case 'insideShooting':
        return Colors.amber[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getSkillDescription(String skill) {
    switch (skill) {
      case 'shooting':
        return 'Ability to make shots from mid-range and three-point range';
      case 'rebounding':
        return 'Ability to secure rebounds on both offensive and defensive ends';
      case 'passing':
        return 'Vision and accuracy when distributing the ball to teammates';
      case 'ballHandling':
        return 'Dribbling skills and ability to maintain possession under pressure';
      case 'perimeterDefense':
        return 'Defensive skills against guards and perimeter players';
      case 'postDefense':
        return 'Defensive skills in the paint against bigger players';
      case 'insideShooting':
        return 'Ability to score close to the basket with layups and dunks';
      default:
        return 'Basketball skill attribute';
    }
  }

  double _calculateOverallRating() {
    return (_player.shooting + 
            _player.rebounding + 
            _player.passing + 
            _player.ballHandling + 
            _player.perimeterDefense + 
            _player.postDefense + 
            _player.insideShooting) / 7.0;
  }

  Color _getOverallRatingColor(double rating) {
    if (rating >= 90) return Colors.purple[400]!;
    if (rating >= 80) return Colors.blue[400]!;
    if (rating >= 70) return Colors.green[400]!;
    if (rating >= 60) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  Color _getPotentialTierColor(PotentialTier tier) {
    switch (tier) {
      case PotentialTier.bronze:
        return Colors.brown[400]!;
      case PotentialTier.silver:
        return Colors.grey[400]!;
      case PotentialTier.gold:
        return Colors.amber[400]!;
      case PotentialTier.elite:
        return Colors.purple[400]!;
    }
  }

  double _calculateCoachingEffectiveness() {
    if (widget.coach == null) return 0.0;
    
    // Simple calculation based on coach attributes
    final attributes = widget.coach!.coachingAttributes.values;
    final average = attributes.fold<double>(0.0, (sum, value) => sum + value) / attributes.length;
    return average.clamp(0.0, 100.0);
  }

  List<String> _getUpgradeableSkills() {
    List<String> upgradeable = [];
    for (String skill in _getSkillsList()) {
      int currentValue = _getCurrentSkillValue(skill);
      if (_player.development.canUpgradeSkill(skill, _player.potential, currentValue)) {
        upgradeable.add(skill);
      }
    }
    return upgradeable;
  }

  void _upgradeSkill(String skill) {
    setState(() {
      int currentValue = _getCurrentSkillValue(skill);
      if (_player.development.upgradeSkill(skill, _player.potential, currentValue)) {
        // Apply the skill upgrade to the player
        _applySkillUpgrade(skill);
        _calculateAvailableSkillPoints();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getSkillDisplayName(skill)} upgraded!'),
            backgroundColor: Colors.green[400],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _applySkillUpgrade(String skill) {
    switch (skill) {
      case 'shooting':
        _player.shooting = (_player.shooting + 1).clamp(0, 99);
        break;
      case 'rebounding':
        _player.rebounding = (_player.rebounding + 1).clamp(0, 99);
        break;
      case 'passing':
        _player.passing = (_player.passing + 1).clamp(0, 99);
        break;
      case 'ballHandling':
        _player.ballHandling = (_player.ballHandling + 1).clamp(0, 99);
        break;
      case 'perimeterDefense':
        _player.perimeterDefense = (_player.perimeterDefense + 1).clamp(0, 99);
        break;
      case 'postDefense':
        _player.postDefense = (_player.postDefense + 1).clamp(0, 99);
        break;
      case 'insideShooting':
        _player.insideShooting = (_player.insideShooting + 1).clamp(0, 99);
        break;
    }
  }

  void _processAllUpgrades() {
    setState(() {
      List<String> upgradedSkills = DevelopmentService.processSkillDevelopment(_player);
      _calculateAvailableSkillPoints();
      
      if (upgradedSkills.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgraded ${upgradedSkills.length} skills!'),
            backgroundColor: Colors.green[400],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Color _getAgePhaseColor(int age, AgingCurve curve) {
    if (age < curve.peakAge) return Colors.green[400]!;
    if (age < curve.declineStartAge) return Colors.blue[400]!;
    if (age < curve.retirementAge) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  IconData _getAgePhaseIcon(int age, AgingCurve curve) {
    if (age < curve.peakAge) return Icons.trending_up;
    if (age < curve.declineStartAge) return Icons.star;
    if (age < curve.retirementAge) return Icons.trending_down;
    return Icons.exit_to_app;
  }

  String _getAgePhaseDescription(int age, AgingCurve curve) {
    if (age < curve.peakAge) return 'Development Phase';
    if (age < curve.declineStartAge) return 'Peak Performance';
    if (age < curve.retirementAge) return 'Decline Phase';
    return 'Retirement Age';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}