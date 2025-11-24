import 'package:flutter/material.dart';
import '../models/playoff_bracket.dart';
import '../models/playoff_series.dart';
import '../models/team.dart';
import '../services/league_service.dart';
import '../utils/app_theme.dart';

/// Playoff bracket page displaying tournament structure and progress
/// Shows all playoff matchups organized by conference and round
class PlayoffBracketPage extends StatelessWidget {
  final PlayoffBracket bracket;
  final String userTeamId;
  final LeagueService leagueService;

  const PlayoffBracketPage({
    super.key,
    required this.bracket,
    required this.userTeamId,
    required this.leagueService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoundName(bracket.currentRound)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoundIndicator(context),
            const SizedBox(height: 24),
            _buildBracketVisualization(context),
          ],
        ),
      ),
    );
  }

  /// Get human-readable round name
  String _getRoundName(String round) {
    switch (round) {
      case 'play-in':
        return 'Play-In Tournament';
      case 'first-round':
        return 'First Round';
      case 'conf-semis':
        return 'Conference Semifinals';
      case 'conf-finals':
        return 'Conference Finals';
      case 'finals':
        return 'NBA Finals';
      case 'complete':
        return 'Playoffs Complete';
      default:
        return 'Playoffs';
    }
  }

  /// Build round indicator showing current playoff stage
  Widget _buildRoundIndicator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Semantics(
      label: 'Current playoff round: ${_getRoundName(bracket.currentRound)}',
      child: Card(
        elevation: AppTheme.cardElevationMedium,
        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor)
            .withValues(alpha: 0.1),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            children: [
              Icon(
                Icons.emoji_events,
                size: 40,
                color: isDark ? AppTheme.infoColorDark : AppTheme.infoColor,
              ),
              const SizedBox(height: 8),
              Text(
                _getRoundName(bracket.currentRound),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the complete bracket visualization with three columns
  Widget _buildBracketVisualization(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For narrow screens, show conferences stacked vertically
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _buildConferenceBracket(context, 'east'),
              const SizedBox(height: 24),
              _buildFinalsBracket(context),
              const SizedBox(height: 24),
              _buildConferenceBracket(context, 'west'),
            ],
          );
        }
        
        // For wider screens, show three columns side by side
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildConferenceBracket(context, 'east')),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: _buildFinalsBracket(context),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildConferenceBracket(context, 'west')),
          ],
        );
      },
    );
  }

  /// Build bracket for one conference showing all rounds
  Widget _buildConferenceBracket(BuildContext context, String conference) {
    final conferenceName = conference == 'east' ? 'Eastern Conference' : 'Western Conference';
    
    return Semantics(
      label: '$conferenceName playoff bracket',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conference header
          Text(
            conferenceName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Play-in games (if applicable)
          if (bracket.playInGames.isNotEmpty)
            _buildRoundSection(
              context,
              'Play-In',
              bracket.playInGames.where((s) => s.conference == conference).toList(),
            ),
          
          // First round
          if (bracket.firstRound.isNotEmpty)
            _buildRoundSection(
              context,
              'First Round',
              bracket.firstRound.where((s) => s.conference == conference).toList(),
            ),
          
          // Conference semifinals
          if (bracket.conferenceSemis.isNotEmpty)
            _buildRoundSection(
              context,
              'Semifinals',
              bracket.conferenceSemis.where((s) => s.conference == conference).toList(),
            ),
          
          // Conference finals
          if (bracket.conferenceFinals.isNotEmpty)
            _buildRoundSection(
              context,
              'Finals',
              bracket.conferenceFinals.where((s) => s.conference == conference).toList(),
            ),
        ],
      ),
    );
  }

  /// Build the NBA Finals bracket in the center
  Widget _buildFinalsBracket(BuildContext context) {
    if (bracket.nbaFinals == null) {
      return const SizedBox.shrink();
    }
    
    return Semantics(
      label: 'NBA Finals matchup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'NBA Finals',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildSeriesCard(context, bracket.nbaFinals!),
        ],
      ),
    );
  }

  /// Build a section for one round showing all series
  Widget _buildRoundSection(
    BuildContext context,
    String roundName,
    List<PlayoffSeries> series,
  ) {
    if (series.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            roundName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ...series.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildSeriesCard(context, s),
        )),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build a card displaying a playoff series matchup
  Widget _buildSeriesCard(BuildContext context, PlayoffSeries series) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUserTeamInSeries = series.homeTeamId == userTeamId || 
                                series.awayTeamId == userTeamId;
    
    final homeTeam = leagueService.getTeam(series.homeTeamId);
    final awayTeam = leagueService.getTeam(series.awayTeamId);
    
    // Handle case where teams might not be found
    if (homeTeam == null || awayTeam == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Error: Team not found'),
        ),
      );
    }
    
    // Determine background color
    Color? backgroundColor;
    if (isUserTeamInSeries) {
      backgroundColor = (isDark ? Colors.blue.shade900 : Colors.blue.shade50);
    }
    
    // Build accessibility label
    String accessibilityLabel;
    if (series.isComplete) {
      final winnerTeam = leagueService.getTeam(series.winnerId!);
      if (winnerTeam != null) {
        accessibilityLabel = 
            'Series complete. ${winnerTeam.city} ${winnerTeam.name} wins ${series.seriesScore}';
      } else {
        accessibilityLabel = 'Series complete. ${series.seriesScore}';
      }
    } else {
      accessibilityLabel = 
          'Series in progress. ${homeTeam.city} ${homeTeam.name} versus ${awayTeam.city} ${awayTeam.name}. Current score: ${series.seriesScore}';
    }
    
    return Semantics(
      label: accessibilityLabel,
      child: Card(
        elevation: isUserTeamInSeries ? AppTheme.cardElevationHigh : AppTheme.cardElevationLow,
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Home team
              _buildTeamRow(
                context,
                homeTeam,
                series.homeWins,
                isHome: true,
                isWinner: series.isComplete && series.winnerId == series.homeTeamId,
                isUserTeam: series.homeTeamId == userTeamId,
              ),
              
              const Divider(height: 16),
              
              // Away team
              _buildTeamRow(
                context,
                awayTeam,
                series.awayWins,
                isHome: false,
                isWinner: series.isComplete && series.winnerId == series.awayTeamId,
                isUserTeam: series.awayTeamId == userTeamId,
              ),
              
              // Series status
              if (series.isComplete) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Series Complete',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.successColorDark : AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Series: ${series.seriesScore}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a row displaying team name and wins
  Widget _buildTeamRow(
    BuildContext context,
    Team team,
    int wins, {
    required bool isHome,
    bool isWinner = false,
    bool isUserTeam = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        // Team name
        Expanded(
          child: Row(
            children: [
              if (isUserTeam) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  '${team.city} ${team.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                    color: isWinner
                        ? (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Wins count
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isWinner
                ? (isDark ? AppTheme.successColorDark : AppTheme.successColor)
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$wins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.white : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
