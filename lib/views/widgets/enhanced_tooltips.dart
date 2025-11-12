import 'package:flutter/material.dart';

/// Enhanced tooltip with rich content and better styling
class EnhancedTooltip extends StatelessWidget {
  final Widget child;
  final String title;
  final String? description;
  final List<String>? bulletPoints;
  final IconData? icon;
  final Color? backgroundColor;
  final Duration showDuration;
  final Duration waitDuration;

  const EnhancedTooltip({
    super.key,
    required this.child,
    required this.title,
    this.description,
    this.bulletPoints,
    this.icon,
    this.backgroundColor,
    this.showDuration = const Duration(seconds: 3),
    this.waitDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '', // Empty message to prevent default tooltip
      richMessage: _buildRichTooltip(context),
      showDuration: showDuration,
      waitDuration: waitDuration,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: child,
    );
  }

  InlineSpan _buildRichTooltip(BuildContext context) {
    final theme = Theme.of(context);
    final children = <InlineSpan>[];

    // Add icon and title
    if (icon != null) {
      children.add(WidgetSpan(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            icon,
            size: 16,
            color: theme.primaryColor,
          ),
        ),
      ));
    }

    children.add(TextSpan(
      text: title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    ));

    // Add description
    if (description != null) {
      children.add(const TextSpan(text: '\n\n'));
      children.add(TextSpan(
        text: description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ));
    }

    // Add bullet points
    if (bulletPoints != null && bulletPoints!.isNotEmpty) {
      children.add(const TextSpan(text: '\n\n'));
      for (int i = 0; i < bulletPoints!.length; i++) {
        children.add(TextSpan(
          text: '• ${bulletPoints![i]}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ));
        if (i < bulletPoints!.length - 1) {
          children.add(const TextSpan(text: '\n'));
        }
      }
    }

    return TextSpan(children: children);
  }
}

/// Interactive help overlay for complex features
class HelpOverlay extends StatefulWidget {
  final Widget child;
  final String title;
  final String content;
  final List<HelpStep>? steps;
  final VoidCallback? onComplete;

  const HelpOverlay({
    super.key,
    required this.child,
    required this.title,
    required this.content,
    this.steps,
    this.onComplete,
  });

  @override
  State<HelpOverlay> createState() => _HelpOverlayState();
}

class _HelpOverlayState extends State<HelpOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showOverlay() {
    setState(() {
      _isVisible = true;
      _currentStep = 0;
    });
    _controller.forward();
  }

  void _hideOverlay() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _nextStep() {
    if (widget.steps != null && _currentStep < widget.steps!.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _hideOverlay();
      widget.onComplete?.call();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onLongPress: _showOverlay,
          child: widget.child,
        ),
        if (_isVisible)
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _buildOverlayContent(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildOverlayContent() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.7),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _hideOverlay,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.steps != null && widget.steps!.isNotEmpty
                              ? widget.steps![_currentStep].content
                              : widget.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (widget.steps != null && widget.steps!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (_currentStep + 1) / widget.steps!.length,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step ${_currentStep + 1} of ${widget.steps!.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.steps != null && _currentStep > 0)
                              TextButton(
                                onPressed: _previousStep,
                                child: const Text('Previous'),
                              )
                            else
                              const SizedBox.shrink(),
                            ElevatedButton(
                              onPressed: _nextStep,
                              child: Text(
                                widget.steps != null && _currentStep < widget.steps!.length - 1
                                    ? 'Next'
                                    : 'Got it!',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Help step for interactive overlays
class HelpStep {
  final String title;
  final String content;
  final Widget? targetWidget;

  HelpStep({
    required this.title,
    required this.content,
    this.targetWidget,
  });
}

/// Contextual help button with enhanced styling
class ContextualHelpButton extends StatelessWidget {
  final String helpText;
  final String? title;
  final List<String>? tips;
  final IconData icon;
  final Color? color;

  const ContextualHelpButton({
    super.key,
    required this.helpText,
    this.title,
    this.tips,
    this.icon = Icons.help_outline,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedTooltip(
      title: title ?? 'Help',
      description: helpText,
      bulletPoints: tips,
      icon: icon,
      child: Icon(
        icon,
        size: 16,
        color: color ?? Theme.of(context).primaryColor.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Progress indicator with help text
class HelpfulProgressIndicator extends StatelessWidget {
  final double value;
  final String label;
  final String? helpText;
  final Color? color;

  const HelpfulProgressIndicator({
    super.key,
    required this.value,
    required this.label,
    this.helpText,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (helpText != null)
              ContextualHelpButton(
                helpText: helpText!,
                title: label,
              ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Smart tooltip that adapts based on user experience level
class SmartTooltip extends StatefulWidget {
  final Widget child;
  final String basicMessage;
  final String? advancedMessage;
  final String? expertMessage;
  final String featureId;

  const SmartTooltip({
    super.key,
    required this.child,
    required this.basicMessage,
    this.advancedMessage,
    this.expertMessage,
    required this.featureId,
  });

  @override
  State<SmartTooltip> createState() => _SmartTooltipState();
}

class _SmartTooltipState extends State<SmartTooltip> {
  UserExperienceLevel _getUserExperienceLevel() {
    // This would typically check user preferences or usage analytics
    // For now, return basic level
    return UserExperienceLevel.basic;
  }

  String _getAppropriateMessage() {
    final level = _getUserExperienceLevel();
    switch (level) {
      case UserExperienceLevel.basic:
        return widget.basicMessage;
      case UserExperienceLevel.advanced:
        return widget.advancedMessage ?? widget.basicMessage;
      case UserExperienceLevel.expert:
        return widget.expertMessage ?? widget.advancedMessage ?? widget.basicMessage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getAppropriateMessage(),
      child: widget.child,
    );
  }
}

enum UserExperienceLevel {
  basic,
  advanced,
  expert,
}