import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/enhanced_coach.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_player.dart';
import 'package:BasketballManager/gameData/enums.dart';
import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

class CoachingEffectivenessDashboard extends StatefulWidget {
  final CoachProfile coach;
  final EnhancedTeam? currentTeam;
  final List<EnhancedPlayer>? teamPlayers;

  const CoachingEffectivenessDashboard({
    super.key,
    required this.coach,
    this.currentTeam,
    this.teamPlayers,
  });

  @override
  State<CoachingEffectivenessDashboard> createState() => _CoachingEffectivenessDashboardState();
}

class _CoachingEffectivenessDashboardState extends State<CoachingEffectivenessDashboard> {
  String _selectedTimeframe = 'season'; // 'season', 'career', 'recent'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Coaching Effectiveness',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          HelpButton(contextId: 'coaching_effectiveness'),
          FeedbackButton(feature: 'coaching_effectiveness'),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String value) {
              setState(() {
                _selectedTimeframe = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'season',
                child: Text('Current Season'),
              ),
              const PopupMenuItem(
                value: 'career',
                child: Text('Career'),
              ),
              const PopupMenuItem(
                value: 'recent',
                child: Text('Last 10 Games'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Performance Overview Card
            _buildPerformanceOverviewCard(),
            const SizedBox(height: 16),
            
            // Team Improvement Metrics
            _buildTeamImprovementCard(),
            const SizedBox(height: 16),
            
            // Coaching Bonuses Visualization
            _buildCoachingBonusesCard(),
            const SizedBox(height: 16),
            
            // Player Development Impact
            _buildPlayerDevelopmentCard(),
            const SizedBox(height: 16),
            
            // Strategy Effectiveness
            _buildStrategyEffectivenessCard(),
            const SizedBox(height: 16),
            
            // Career Milestones
            _buildCareerMilestonesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverviewCard() {
    CoachingHistory history = widget.coach.history;
    
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Performance Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTimeframeColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTimeframeLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Performance Metrics Grid
          Row(
            children: [
              Expanded(
                child: _performanceMetricCard(
                  'Win Rate',
                  '${(history.winPercentage * 100).toStringAsFixed(1)}%',
                  _getWinRateColor(history.winPercentage),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _performanceMetricCard(
                  'Total Wins',
                  '${history.totalWins}',
                  Colors.green[400]!,
                  Icons.sports_basketball,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _performanceMetricCard(
                  'Championships',
                  '${history.championships}',
                  Colors.amber[400]!,
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _performanceMetricCard(
                  'Playoff Apps',
                  '${history.playoffAppearances}',
                  Colors.orange[400]!,
                  Icons.military_tech,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _performanceMetricCard(
                  'Experience',
                  'Level ${widget.coach.experienceLevel}',
                  Colors.purple[400]!,
                  Icons.star,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _performanceMetricCard(
                  'Seasons',
                  '${history.seasonRecords.length}',
                  Colors.blue[400]!,
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceMetricCard(String label, String value, Color color, IconData icon) {
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

  Widget _buildTeamImprovementCard() {
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
            'Team Performance Impact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (widget.currentTeam != null) ...[
            // Team Rating Improvements
            _buildImprovementMetric(
              'Offensive Rating',
              _calculateOffensiveImprovement(),
              'Points per 100 possessions',
            ),
            const SizedBox(height: 12),
            
            _buildImprovementMetric(
              'Defensive Rating',
              _calculateDefensiveImprovement(),
              'Opponent points per 100 possessions',
            ),
            const SizedBox(height: 12),
            
            _buildImprovementMetric(
              'Team Chemistry',
              _calculateChemistryImprovement(),
              'Team cohesion and coordination',
            ),
            const SizedBox(height: 12),
            
            _buildImprovementMetric(
              'Player Development Rate',
              _calculateDevelopmentRateImprovement(),
              'Average skill improvement per season',
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.group_off,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No current team assigned',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Assign to a team to see performance impact',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImprovementMetric(String title, double improvement, String description) {
    Color improvementColor = improvement >= 0 ? Colors.green[400]! : Colors.red[400]!;
    IconData improvementIcon = improvement >= 0 ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: improvementColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              improvementIcon,
              color: improvementColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: improvementColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingBonusesCard() {
    Map<String, double> bonuses = widget.coach.calculateTeamBonuses();
    
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
            'Active Coaching Bonuses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          if (bonuses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_flat,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active bonuses',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Improve coaching attributes to unlock bonuses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...bonuses.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBonusVisualization(entry.key, entry.value),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBonusVisualization(String bonusType, double bonusValue) {
    Color bonusColor = _getBonusColor(bonusType);
    IconData bonusIcon = _getBonusIcon(bonusType);
    String bonusName = _getBonusDisplayName(bonusType);
    
    double percentage = (bonusValue * 100).abs();
    double barWidth = (percentage / 20.0).clamp(0.0, 1.0); // Max 20% bonus for full bar
    
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
              Icon(bonusIcon, color: bonusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bonusName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '${bonusValue >= 0 ? '+' : ''}${(bonusValue * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bonusValue >= 0 ? Colors.green[400] : Colors.red[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Bonus Strength Visualization
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: bonusColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerDevelopmentCard() {
    Map<String, int> playersDeveloped = widget.coach.history.playersDeveloped;
    double developmentBonus = widget.coach.getDevelopmentBonus();
    
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
          
          // Development Bonus Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[400]?.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[400]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[400], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Development Bonus',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Players develop ${(developmentBonus * 100).toStringAsFixed(1)}% faster under your coaching',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${(developmentBonus * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Team Players Development (if available)
          if (widget.teamPlayers != null && widget.teamPlayers!.isNotEmpty) ...[
            const Text(
              'Current Team Development Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            ...widget.teamPlayers!.take(5).map((player) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildPlayerDevelopmentItem(player),
              );
            }),
            
            if (widget.teamPlayers!.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Showing top 5 players (${widget.teamPlayers!.length} total)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No current team players to track development',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerDevelopmentItem(EnhancedPlayer player) {
    // Calculate development progress (mock calculation)
    double developmentProgress = _calculatePlayerDevelopmentProgress(player);
    Color progressColor = _getProgressColor(developmentProgress);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${player.primaryRole.displayName} • Age ${player.age}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: developmentProgress / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${developmentProgress.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyEffectivenessCard() {
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
            'Strategy Effectiveness',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Specialization Effectiveness
          _buildSpecializationEffectiveness(
            widget.coach.primarySpecialization,
            isPrimary: true,
          ),
          
          if (widget.coach.secondarySpecialization != null) ...[
            const SizedBox(height: 12),
            _buildSpecializationEffectiveness(
              widget.coach.secondarySpecialization!,
              isPrimary: false,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Strategy Recommendations
          _buildStrategyRecommendations(),
        ],
      ),
    );
  }

  Widget _buildSpecializationEffectiveness(CoachingSpecialization specialization, {required bool isPrimary}) {
    double effectiveness = _calculateSpecializationEffectiveness(specialization, isPrimary);
    Color effectivenessColor = _getEffectivenessColor(effectiveness);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary 
          ? Border.all(color: const Color.fromARGB(255, 82, 50, 168), width: 1)
          : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: effectivenessColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getSpecializationIcon(specialization),
              color: effectivenessColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      specialization.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 82, 50, 168),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PRIMARY',
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
                const SizedBox(height: 2),
                Text(
                  _getEffectivenessDescription(effectiveness),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${effectiveness.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: effectivenessColor,
                ),
              ),
              Text(
                'Effective',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyRecommendations() {
    List<String> recommendations = _getStrategyRecommendations();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Strategy Recommendations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        ...recommendations.map((recommendation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCareerMilestonesCard() {
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
            'Career Milestones & Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Next Milestones
          _buildNextMilestones(),
          const SizedBox(height: 16),
          
          // Recent Achievements
          _buildRecentAchievements(),
        ],
      ),
    );
  }

  Widget _buildNextMilestones() {
    List<Map<String, dynamic>> nextMilestones = _getNextMilestones();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next Milestones',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        ...nextMilestones.map((milestone) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildMilestoneItem(milestone),
          );
        }),
      ],
    );
  }

  Widget _buildMilestoneItem(Map<String, dynamic> milestone) {
    double progress = milestone['progress'] as double;
    Color progressColor = _getProgressColor(progress);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                milestone['name'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress / 100.0,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            milestone['description'] as String,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    List<Achievement> recentAchievements = widget.coach.achievements
        .where((achievement) => 
          DateTime.now().difference(achievement.unlockedDate).inDays <= 30)
        .toList()
        ..sort((a, b) => b.unlockedDate.compareTo(a.unlockedDate));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Achievements (Last 30 Days)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        if (recentAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No recent achievements',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          )
        else
          ...recentAchievements.take(3).map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getAchievementTypeColor(achievement.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _getAchievementTypeIcon(achievement.type),
                      color: _getAchievementTypeColor(achievement.type),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${DateTime.now().difference(achievement.unlockedDate).inDays} days ago',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // Helper methods for calculations and styling
  Color _getTimeframeColor() {
    switch (_selectedTimeframe) {
      case 'season':
        return Colors.blue[400]!;
      case 'career':
        return Colors.purple[400]!;
      case 'recent':
        return Colors.green[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  String _getTimeframeLabel() {
    switch (_selectedTimeframe) {
      case 'season':
        return 'Current Season';
      case 'career':
        return 'Career';
      case 'recent':
        return 'Last 10 Games';
      default:
        return 'Unknown';
    }
  }

  Color _getWinRateColor(double winRate) {
    if (winRate >= 0.7) return Colors.green[400]!;
    if (winRate >= 0.5) return Colors.orange[400]!;
    return Colors.red[400]!;
  }

  double _calculateOffensiveImprovement() {
    // Mock calculation - in real implementation, compare before/after coaching stats
    double baseImprovement = (widget.coach.coachingAttributes['offensive']! - 50) * 0.2;
    if (widget.coach.primarySpecialization == CoachingSpecialization.offensive) {
      baseImprovement += 5.0;
    }
    return baseImprovement;
  }

  double _calculateDefensiveImprovement() {
    double baseImprovement = (widget.coach.coachingAttributes['defensive']! - 50) * 0.2;
    if (widget.coach.primarySpecialization == CoachingSpecialization.defensive) {
      baseImprovement += 5.0;
    }
    return baseImprovement;
  }

  double _calculateChemistryImprovement() {
    double baseImprovement = (widget.coach.coachingAttributes['chemistry']! - 50) * 0.15;
    if (widget.coach.primarySpecialization == CoachingSpecialization.teamChemistry) {
      baseImprovement += 4.0;
    }
    return baseImprovement;
  }

  double _calculateDevelopmentRateImprovement() {
    double baseImprovement = (widget.coach.coachingAttributes['development']! - 50) * 0.3;
    if (widget.coach.primarySpecialization == CoachingSpecialization.playerDevelopment) {
      baseImprovement += 8.0;
    }
    return baseImprovement;
  }

  Color _getBonusColor(String bonusType) {
    switch (bonusType) {
      case 'offensiveRating':
        return Colors.orange[400]!;
      case 'defensiveRating':
        return Colors.blue[400]!;
      case 'developmentRate':
        return Colors.green[400]!;
      case 'teamChemistry':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  IconData _getBonusIcon(String bonusType) {
    switch (bonusType) {
      case 'offensiveRating':
        return Icons.sports_basketball;
      case 'defensiveRating':
        return Icons.shield;
      case 'developmentRate':
        return Icons.trending_up;
      case 'teamChemistry':
        return Icons.group;
      default:
        return Icons.help;
    }
  }

  String _getBonusDisplayName(String bonusType) {
    switch (bonusType) {
      case 'offensiveRating':
        return 'Offensive Rating Bonus';
      case 'defensiveRating':
        return 'Defensive Rating Bonus';
      case 'developmentRate':
        return 'Development Rate Bonus';
      case 'teamChemistry':
        return 'Team Chemistry Bonus';
      default:
        return bonusType;
    }
  }

  double _calculatePlayerDevelopmentProgress(EnhancedPlayer player) {
    // Mock calculation based on player age and potential
    double baseProgress = 100 - player.age * 2.0; // Younger players have more room to grow
    double coachBonus = widget.coach.getDevelopmentBonus() * 20;
    return (baseProgress + coachBonus).clamp(0.0, 100.0);
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green[400]!;
    if (progress >= 60) return Colors.orange[400]!;
    if (progress >= 40) return Colors.yellow[400]!;
    return Colors.red[400]!;
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

  double _calculateSpecializationEffectiveness(CoachingSpecialization specialization, bool isPrimary) {
    String attributeKey = _getAttributeKeyForSpecialization(specialization);
    double baseEffectiveness = widget.coach.coachingAttributes[attributeKey]!.toDouble();
    
    if (isPrimary) {
      baseEffectiveness += 10; // Primary specialization bonus
    }
    
    // Experience level bonus
    baseEffectiveness += widget.coach.experienceLevel * 2;
    
    return baseEffectiveness.clamp(0.0, 100.0);
  }

  String _getAttributeKeyForSpecialization(CoachingSpecialization specialization) {
    switch (specialization) {
      case CoachingSpecialization.offensive:
        return 'offensive';
      case CoachingSpecialization.defensive:
        return 'defensive';
      case CoachingSpecialization.playerDevelopment:
        return 'development';
      case CoachingSpecialization.teamChemistry:
        return 'chemistry';
    }
  }

  Color _getEffectivenessColor(double effectiveness) {
    if (effectiveness >= 80) return Colors.green[400]!;
    if (effectiveness >= 60) return Colors.orange[400]!;
    if (effectiveness >= 40) return Colors.yellow[400]!;
    return Colors.red[400]!;
  }

  String _getEffectivenessDescription(double effectiveness) {
    if (effectiveness >= 80) return 'Highly effective strategy';
    if (effectiveness >= 60) return 'Moderately effective';
    if (effectiveness >= 40) return 'Somewhat effective';
    return 'Needs improvement';
  }

  List<String> _getStrategyRecommendations() {
    List<String> recommendations = [];
    
    // Analyze coaching attributes and provide recommendations
    Map<String, int> attributes = widget.coach.coachingAttributes;
    
    if (attributes['offensive']! < 60) {
      recommendations.add('Focus on offensive drills to improve team scoring');
    }
    
    if (attributes['defensive']! < 60) {
      recommendations.add('Implement defensive schemes to reduce opponent scoring');
    }
    
    if (attributes['development']! < 70) {
      recommendations.add('Spend more time on individual player development');
    }
    
    if (attributes['chemistry']! < 65) {
      recommendations.add('Organize team building activities to improve chemistry');
    }
    
    // Experience-based recommendations
    if (widget.coach.experienceLevel < 3) {
      recommendations.add('Gain more experience through coaching different situations');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Continue current coaching approach - all areas are strong');
    }
    
    return recommendations;
  }

  List<Map<String, dynamic>> _getNextMilestones() {
    List<Map<String, dynamic>> milestones = [];
    CoachingHistory history = widget.coach.history;
    
    // Win-based milestones
    if (history.totalWins < 50) {
      milestones.add({
        'name': '50 Career Wins',
        'description': '${50 - history.totalWins} wins remaining',
        'progress': (history.totalWins / 50.0 * 100).clamp(0.0, 100.0),
      });
    } else if (history.totalWins < 100) {
      milestones.add({
        'name': '100 Career Wins',
        'description': '${100 - history.totalWins} wins remaining',
        'progress': (history.totalWins / 100.0 * 100).clamp(0.0, 100.0),
      });
    }
    
    // Championship milestones
    if (history.championships == 0) {
      milestones.add({
        'name': 'First Championship',
        'description': 'Win your first championship title',
        'progress': 0.0,
      });
    }
    
    // Experience milestones
    int nextLevelExp = widget.coach.experienceLevel * 1000;
    int currentExp = history.totalExperience;
    if (currentExp < nextLevelExp) {
      milestones.add({
        'name': 'Level ${widget.coach.experienceLevel + 1}',
        'description': '${nextLevelExp - currentExp} XP remaining',
        'progress': ((currentExp % 1000) / 1000.0 * 100).clamp(0.0, 100.0),
      });
    }
    
    return milestones.take(3).toList();
  }

  Color _getAchievementTypeColor(AchievementType type) {
    switch (type) {
      case AchievementType.wins:
        return Colors.green[400]!;
      case AchievementType.championships:
        return Colors.amber[400]!;
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
        return Icons.emoji_events;
      case AchievementType.development:
        return Icons.trending_up;
      case AchievementType.experience:
        return Icons.star;
    }
  }
}