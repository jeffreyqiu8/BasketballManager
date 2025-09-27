import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/enums.dart';
import 'package:BasketballManager/views/pages/coaching_effectiveness_dashboard.dart';

class CoachProfilePage extends StatefulWidget {
  final CoachProfile coach;

  const CoachProfilePage({super.key, required this.coach});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  late CoachProfile _coach;
  String _selectedTab = 'profile'; // 'profile', 'achievements', 'history'

  @override
  void initState() {
    super.initState();
    _coach = widget.coach;
    // Calculate current team bonuses
    _coach.calculateTeamBonuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          _coach.name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => _showEffectivenessDashboard(),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(),
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
                Expanded(child: _tabButton('Profile', 'profile')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('Achievements', 'achievements')),
                const SizedBox(width: 8),
                Expanded(child: _tabButton('History', 'history')),
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

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
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
      case 'achievements':
        return _buildAchievementsTab();
      case 'history':
        return _buildHistoryTab();
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Card
          _buildBasicInfoCard(),
          const SizedBox(height: 16),

          // Specializations Card
          _buildSpecializationsCard(),
          const SizedBox(height: 16),

          // Coaching Attributes Card
          _buildCoachingAttributesCard(),
          const SizedBox(height: 16),

          // Team Bonuses Card
          _buildTeamBonusesCard(),
          const SizedBox(height: 16),

          // Experience Progress Card
          _buildExperienceCard(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _infoItem('Age', '${_coach.age}')),
              Expanded(
                child: _infoItem(
                  'Experience',
                  '${_coach.experienceYears} years',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: _infoItem('Nationality', _coach.nationality)),
              Expanded(child: _infoItem('Status', _coach.currentStatus)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationsCard() {
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
            'Coaching Specializations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Primary Specialization
          _buildSpecializationItem(
            'Primary Specialization',
            _coach.primarySpecialization,
            isPrimary: true,
          ),

          if (_coach.secondarySpecialization != null) ...[
            const SizedBox(height: 12),
            _buildSpecializationItem(
              'Secondary Specialization',
              _coach.secondarySpecialization!,
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecializationItem(
    String title,
    CoachingSpecialization specialization, {
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isPrimary
                ? const Color.fromARGB(255, 82, 50, 168).withValues(alpha: 0.3)
                : Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border:
            isPrimary
                ? Border.all(
                  color: const Color.fromARGB(255, 82, 50, 168),
                  width: 2,
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSpecializationIcon(specialization),
                color:
                    isPrimary
                        ? const Color.fromARGB(255, 82, 50, 168)
                        : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            specialization.displayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialization.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  IconData _getSpecializationIcon(CoachingSpecialization specialization) {
    switch (specialization) {
      case CoachingSpecialization.offensive:
        return Icons.sports_basketball;
      case CoachingSpecialization.defensive:
        return Icons.shield;
      case CoachingSpecialization.playerDevelopment:
        return Icons.trending_up;
      case CoachingSpecialization.teamChemistry:
        return Icons.group;
    }
  }

  Widget _buildCoachingAttributesCard() {
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
            'Coaching Attributes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          ..._coach.coachingAttributes.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAttributeBar(entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttributeBar(String attributeName, int value) {
    String displayName = _getAttributeDisplayName(attributeName);
    Color barColor = _getAttributeColor(attributeName);
    double percentage = value / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: barColor,
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
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getAttributeDisplayName(String attributeName) {
    switch (attributeName) {
      case 'offensive':
        return 'Offensive Coaching';
      case 'defensive':
        return 'Defensive Coaching';
      case 'development':
        return 'Player Development';
      case 'chemistry':
        return 'Team Chemistry';
      default:
        return attributeName.toUpperCase();
    }
  }

  Color _getAttributeColor(String attributeName) {
    switch (attributeName) {
      case 'offensive':
        return Colors.orange[400]!;
      case 'defensive':
        return Colors.blue[400]!;
      case 'development':
        return Colors.green[400]!;
      case 'chemistry':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Widget _buildTeamBonusesCard() {
    Map<String, double> bonuses = _coach.teamBonuses;

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
            'Team Bonuses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          if (bonuses.isEmpty)
            Text(
              'No active team bonuses',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            )
          else
            ...bonuses.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getBonusDisplayName(entry.key),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      '${entry.value >= 0 ? '+' : ''}${(entry.value * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            entry.value >= 0
                                ? Colors.green[400]
                                : Colors.red[400],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _getBonusDisplayName(String bonusKey) {
    switch (bonusKey) {
      case 'offensiveRating':
        return 'Offensive Rating';
      case 'defensiveRating':
        return 'Defensive Rating';
      case 'developmentRate':
        return 'Development Rate';
      case 'teamChemistry':
        return 'Team Chemistry';
      default:
        return bonusKey;
    }
  }

  Widget _buildExperienceCard() {
    int currentExp = _coach.history.totalExperience;
    int currentLevel = _coach.experienceLevel;
    int expForCurrentLevel = (currentLevel - 1) * 1000;
    int expForNextLevel = currentLevel * 1000;
    int expInCurrentLevel = currentExp - expForCurrentLevel;
    int expNeededForNext = expForNextLevel - currentExp;
    double progressPercentage = expInCurrentLevel / 1000.0;

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
            'Experience & Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Level Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Total Experience: $currentExp',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 82, 50, 168),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$expNeededForNext XP to next level',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  Text(
                    '$expInCurrentLevel / 1000 XP',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 82, 50, 168),
                          Color.fromARGB(255, 120, 80, 200),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
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

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Achievement Stats Overview
          _buildAchievementStatsCard(),
          const SizedBox(height: 16),

          // Achievements List
          _buildAchievementsListCard(),
        ],
      ),
    );
  }

  Widget _buildAchievementStatsCard() {
    Map<AchievementType, int> achievementCounts = {};
    for (var achievement in _coach.achievements) {
      achievementCounts[achievement.type] =
          (achievementCounts[achievement.type] ?? 0) + 1;
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
          const Text(
            'Achievement Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _achievementStatItem(
                  'Total',
                  '${_coach.achievements.length}',
                  Icons.emoji_events,
                  Colors.amber[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _achievementStatItem(
                  'Wins',
                  '${achievementCounts[AchievementType.wins] ?? 0}',
                  Icons.sports_basketball,
                  Colors.green[400]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _achievementStatItem(
                  'Championships',
                  '${achievementCounts[AchievementType.championships] ?? 0}',
                  Icons.military_tech,
                  Colors.orange[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _achievementStatItem(
                  'Development',
                  '${achievementCounts[AchievementType.development] ?? 0}',
                  Icons.trending_up,
                  Colors.blue[400]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildAchievementsListCard() {
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
            'Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (_coach.achievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No achievements yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep coaching to unlock achievements!',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ..._coach.achievements.map((achievement) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAchievementItem(achievement),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAchievementTypeColor(achievement.type),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getAchievementTypeColor(
                achievement.type,
              ).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getAchievementTypeIcon(achievement.type),
              color: _getAchievementTypeColor(achievement.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlocked: ${_formatDate(achievement.unlockedDate)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAchievementTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.wins:
        return Colors.green[400]!;
      case AchievementType.championships:
        return Colors.orange[400]!;
      case AchievementType.development:
        return Colors.blue[400]!;
      case AchievementType.experience:
        return Colors.purple[400]!;
    }
  }

  IconData _getAchievementTypeIcon(AchievementType type) {
    switch (type) {
      case AchievementType.wins:
        return Icons.sports_basketball;
      case AchievementType.championships:
        return Icons.military_tech;
      case AchievementType.development:
        return Icons.trending_up;
      case AchievementType.experience:
        return Icons.star;
    }
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Career Stats Overview
          _buildCareerStatsCard(),
          const SizedBox(height: 16),

          // Season History
          _buildSeasonHistoryCard(),
          const SizedBox(height: 16),

          // Player Development History
          _buildPlayerDevelopmentCard(),
        ],
      ),
    );
  }

  Widget _buildCareerStatsCard() {
    CoachingHistory history = _coach.history;

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
            'Career Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // First Row
          Row(
            children: [
              Expanded(
                child: _careerStatItem(
                  'Total Wins',
                  '${history.totalWins}',
                  Colors.green[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careerStatItem(
                  'Total Losses',
                  '${history.totalLosses}',
                  Colors.red[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careerStatItem(
                  'Win %',
                  '${(history.winPercentage * 100).toStringAsFixed(1)}%',
                  Colors.blue[400]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Second Row
          Row(
            children: [
              Expanded(
                child: _careerStatItem(
                  'Championships',
                  '${history.championships}',
                  Colors.amber[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careerStatItem(
                  'Playoff Apps',
                  '${history.playoffAppearances}',
                  Colors.orange[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careerStatItem(
                  'Seasons',
                  '${history.seasonRecords.length}',
                  Colors.purple[400]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _careerStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonHistoryCard() {
    List<SeasonRecord> seasons = _coach.history.seasonRecords;

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
            'Season History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (seasons.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'No season history yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete a season to see your coaching history!',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ...seasons.reversed.take(5).map((season) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSeasonItem(season),
              );
            }),

          if (seasons.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'Showing last 5 seasons (${seasons.length} total)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeasonItem(SeasonRecord season) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Season Number
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 82, 50, 168),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'S${season.season}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Season Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${season.wins}-${season.losses}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${(season.winPercentage * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (season.teamName != null)
                  Text(
                    season.teamName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                  ),
              ],
            ),
          ),

          // Achievements
          Column(
            children: [
              if (season.wonChampionship)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CHAMP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                )
              else if (season.madePlayoffs)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PLAYOFFS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDevelopmentCard() {
    Map<String, int> playersDeveloped = _coach.history.playersDeveloped;

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
            'Player Development Impact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          if (playersDeveloped.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.trending_up, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text(
                    'No player development tracked yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help players improve to see your development impact!',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Summary Stats
                Row(
                  children: [
                    Expanded(
                      child: _developmentStatItem(
                        'Players Developed',
                        '${playersDeveloped.length}',
                        Icons.group,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _developmentStatItem(
                        'Total Improvements',
                        '${playersDeveloped.values.fold(0, (sum, improvements) => sum + improvements)}',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Top Developed Players
                const Text(
                  'Top Developed Players',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                ...(playersDeveloped.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .take(5)
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[300],
                              ),
                            ),
                            Text(
                              '+${entry.value} improvements',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[400],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _developmentStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green[400], size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[400],
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEffectivenessDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => CoachingEffectivenessDashboard(
              coach: _coach,
              // In a real implementation, you would pass the current team and players
              // currentTeam: currentTeam,
              // teamPlayers: teamPlayers,
            ),
      ),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Edit Coach Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Coach profile editing will be available in a future update.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
