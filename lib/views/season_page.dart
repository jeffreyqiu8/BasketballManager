import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/game.dart';
import '../services/league_service.dart';
import '../utils/app_theme.dart';

/// Page to display season schedule and statistics
class SeasonPage extends StatelessWidget {
  final Season season;
  final LeagueService leagueService;

  const SeasonPage({
    super.key,
    required this.season,
    required this.leagueService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Season Schedule'),
      ),
      body: Column(
        children: [
          _buildSeasonHeader(context),
          Expanded(
            child: _buildScheduleList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winPercentage = season.gamesPlayed > 0
        ? (season.wins / season.gamesPlayed * 100).toStringAsFixed(1)
        : '0.0';

    return Semantics(
      label: 'Season ${season.year} summary: ${season.wins} wins, ${season.losses} losses, $winPercentage percent win rate',
      child: Container(
        padding: AppTheme.cardPadding,
        color: (isDark ? AppTheme.infoColorDark : AppTheme.infoColor).withOpacity(0.1),
        child: Column(
          children: [
            Text(
              'Season ${season.year}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Wins',
                  '${season.wins}',
                  isDark ? AppTheme.successColorDark : AppTheme.successColor,
                ),
                _buildStatItem(
                  context,
                  'Losses',
                  '${season.losses}',
                  isDark ? AppTheme.errorColorDark : AppTheme.errorColor,
                ),
                _buildStatItem(
                  context,
                  'Win %',
                  '$winPercentage%',
                  isDark ? AppTheme.infoColorDark : AppTheme.infoColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Games: ${season.gamesPlayed} / 82',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    return Semantics(
      label: 'Schedule of 82 games, ${season.gamesPlayed} played, ${season.gamesRemaining} remaining',
      child: ListView.builder(
        itemCount: season.games.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final game = season.games[index];
          return _buildGameCard(context, game, index + 1);
        },
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, Game game, int gameNumber) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeTeam = leagueService.getTeam(game.homeTeamId);
    final awayTeam = leagueService.getTeam(game.awayTeamId);

    if (homeTeam == null || awayTeam == null) {
      return const SizedBox.shrink();
    }

    final isUserHome = game.homeTeamId == season.userTeamId;
    final opponent = isUserHome ? awayTeam : homeTeam;
    final isHome = isUserHome;
    
    String gameLabel;
    if (game.isPlayed) {
      final userWon = (isUserHome && game.homeTeamWon) || (!isUserHome && game.awayTeamWon);
      final userScore = isUserHome ? game.homeScore : game.awayScore;
      final opponentScore = isUserHome ? game.awayScore : game.homeScore;
      gameLabel = 'Game $gameNumber: ${userWon ? "Won" : "Lost"} ${isHome ? "vs" : "at"} ${opponent.city} ${opponent.name}, score $userScore to $opponentScore';
    } else {
      gameLabel = 'Game $gameNumber: Upcoming game ${isHome ? "vs" : "at"} ${opponent.city} ${opponent.name}';
    }

    return Semantics(
      label: gameLabel,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXSmall, horizontal: AppTheme.spacingSmall),
        elevation: game.isPlayed ? AppTheme.cardElevationLow : AppTheme.cardElevationMedium,
        color: game.isPlayed 
            ? (isDark ? const Color(0xFF2A2A2A) : AppTheme.dividerColorLight)
            : (isDark ? AppTheme.surfaceColorDark : AppTheme.surfaceColorLight),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: game.isPlayed
                ? (isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight)
                : (isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor),
            child: Text(
              '$gameNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                isHome ? 'vs' : '@',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${opponent.city} ${opponent.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: game.isPlayed
              ? _buildGameResult(context, game, isUserHome)
              : Text(
                  isHome ? 'Home Game' : 'Away Game',
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
          trailing: game.isPlayed
              ? _buildResultIcon(context, game, isUserHome)
              : Icon(
                  Icons.schedule,
                  color: isDark ? AppTheme.textDisabledDark : AppTheme.textDisabledLight,
                ),
        ),
      ),
    );
  }

  Widget _buildGameResult(BuildContext context, Game game, bool isUserHome) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userScore = isUserHome ? game.homeScore : game.awayScore;
    final opponentScore = isUserHome ? game.awayScore : game.homeScore;
    final userWon = (isUserHome && game.homeTeamWon) || (!isUserHome && game.awayTeamWon);

    return Text(
      '${userWon ? "W" : "L"} $userScore - $opponentScore',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: AppTheme.getWinLossColor(userWon, isDark: isDark),
        fontSize: 16,
      ),
    );
  }

  Widget _buildResultIcon(BuildContext context, Game game, bool isUserHome) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userWon = (isUserHome && game.homeTeamWon) || (!isUserHome && game.awayTeamWon);

    return Icon(
      userWon ? Icons.check_circle : Icons.cancel,
      color: AppTheme.getWinLossColor(userWon, isDark: isDark),
      size: 28,
    );
  }
}
