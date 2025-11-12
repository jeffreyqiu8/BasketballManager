import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for the Basketball Manager app
/// 
/// This file provides helper functions and constants to ensure
/// the app meets WCAG AA accessibility standards.
/// 
/// Key features:
/// - Color contrast validation
/// - Semantic announcement helpers
/// - Focus management utilities
/// - Accessible error messaging

/// Accessibility helper class for managing semantic announcements
/// and ensuring proper accessibility features throughout the app
class AccessibilityUtils {
  /// Announce a message to screen readers
  /// 
  /// This creates a semantic announcement that will be read by screen readers
  /// without displaying any visual content. Useful for dynamic content changes.
  /// 
  /// Example:
  /// ```dart
  /// AccessibilityUtils.announce(context, 'Game completed successfully');
  /// ```
  static void announce(BuildContext context, String message) {
    // Use SemanticsService to announce to screen readers
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Show an accessible error message via SnackBar
  /// 
  /// Displays an error message with proper semantic labeling and
  /// color contrast for accessibility. The message is also announced
  /// to screen readers.
  /// 
  /// Parameters:
  /// - context: BuildContext for showing the SnackBar
  /// - message: Error message to display
  /// - duration: How long to show the message (default: 3 seconds)
  static void showAccessibleError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    // Announce to screen readers
    announce(context, 'Error: $message');

    // Show visual SnackBar with high contrast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: 'Error: $message',
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red.shade700, // WCAG AA compliant
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show an accessible success message via SnackBar
  /// 
  /// Displays a success message with proper semantic labeling and
  /// color contrast for accessibility. The message is also announced
  /// to screen readers.
  /// 
  /// Parameters:
  /// - context: BuildContext for showing the SnackBar
  /// - message: Success message to display
  /// - duration: How long to show the message (default: 3 seconds)
  static void showAccessibleSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    // Announce to screen readers
    announce(context, message);

    // Show visual SnackBar with high contrast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: message,
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade700, // WCAG AA compliant
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Show an accessible info message via SnackBar
  /// 
  /// Displays an informational message with proper semantic labeling and
  /// color contrast for accessibility. The message is also announced
  /// to screen readers.
  /// 
  /// Parameters:
  /// - context: BuildContext for showing the SnackBar
  /// - message: Info message to display
  /// - duration: How long to show the message (default: 3 seconds)
  static void showAccessibleInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    // Announce to screen readers
    announce(context, message);

    // Show visual SnackBar with high contrast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          label: message,
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue.shade700, // WCAG AA compliant
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  /// Wrap a widget with proper focus management
  /// 
  /// Ensures that interactive elements can be properly focused
  /// for keyboard navigation and screen readers.
  /// 
  /// Parameters:
  /// - child: The widget to wrap
  /// - focusNode: Optional FocusNode for manual focus control
  /// - autofocus: Whether to autofocus this widget
  static Widget withFocusManagement(
    Widget child, {
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      child: child,
    );
  }

  /// Create an accessible button with proper semantics
  /// 
  /// Wraps a button widget with comprehensive semantic information
  /// for screen readers and assistive technologies.
  /// 
  /// Parameters:
  /// - label: Descriptive label for screen readers
  /// - hint: Optional hint text for additional context
  /// - enabled: Whether the button is enabled
  /// - child: The button widget
  static Widget accessibleButton({
    required String label,
    String? hint,
    bool enabled = true,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: child,
    );
  }

  /// Create an accessible text field with proper semantics
  /// 
  /// Wraps a text field with comprehensive semantic information
  /// for screen readers and assistive technologies.
  /// 
  /// Parameters:
  /// - label: Descriptive label for screen readers
  /// - hint: Optional hint text for additional context
  /// - value: Current value of the text field
  /// - child: The text field widget
  static Widget accessibleTextField({
    required String label,
    String? hint,
    String? value,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      value: value,
      child: child,
    );
  }

  /// Validate color contrast ratio
  /// 
  /// Checks if the contrast ratio between two colors meets WCAG AA standards.
  /// WCAG AA requires:
  /// - 4.5:1 for normal text
  /// - 3:1 for large text (18pt+ or 14pt+ bold)
  /// 
  /// Returns true if the contrast ratio is sufficient.
  static bool hasGoodContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 4.5; // WCAG AA standard for normal text
  }

  /// Calculate the contrast ratio between two colors
  /// 
  /// Uses the WCAG formula: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 is the lighter color's relative luminance
  /// and L2 is the darker color's relative luminance.
  static double _calculateContrastRatio(Color color1, Color color2) {
    final lum1 = _getRelativeLuminance(color1);
    final lum2 = _getRelativeLuminance(color2);

    final lighter = lum1 > lum2 ? lum1 : lum2;
    final darker = lum1 > lum2 ? lum2 : lum1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  /// 
  /// Uses the WCAG formula for relative luminance calculation.
  static double _getRelativeLuminance(Color color) {
    // Extract RGB values (0-255) and normalize to 0-1
    final r = _linearize((color.value >> 16 & 0xFF) / 255.0);
    final g = _linearize((color.value >> 8 & 0xFF) / 255.0);
    final b = _linearize((color.value & 0xFF) / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize an RGB color component
  static double _linearize(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }
}
