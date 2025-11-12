import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Consistent loading indicator widget with accessibility support
class LoadingIndicator extends StatelessWidget {
  final String message;
  final bool showMessage;

  const LoadingIndicator({
    super.key,
    this.message = 'Loading...',
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Semantics(
        label: '$message, please wait',
        liveRegion: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
            ),
            if (showMessage) ...[
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small inline loading indicator
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;

  const InlineLoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? AppTheme.primaryColorDark : AppTheme.primaryColor,
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: AppTheme.spacingMedium),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }
}
