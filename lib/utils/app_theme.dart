import 'package:flutter/material.dart';

/// Centralized theme configuration for the Basketball Manager app
/// Ensures consistent styling and WCAG AA color contrast compliance
class AppTheme {
  // Primary colors (Light mode)
  static const Color primaryColor = Color(0xFF6750A4); // Deep purple
  static const Color primaryColorDark = Color(
    0xFFD0BCFF,
  ); // Light purple for dark mode
  static const Color secondaryColor = Color(0xFFFF6B35); // Basketball orange
  static const Color secondaryColorDark = Color(
    0xFFFFB4A0,
  ); // Light orange for dark mode

  // Status colors (WCAG AA compliant for both modes)
  static const Color successColor = Color(0xFF2E7D32); // Dark green
  static const Color successColorDark = Color(
    0xFF81C784,
  ); // Light green for dark mode
  static const Color errorColor = Color(0xFFC62828); // Dark red
  static const Color errorColorDark = Color(
    0xFFEF5350,
  ); // Light red for dark mode
  static const Color warningColor = Color(0xFFEF6C00); // Dark orange
  static const Color warningColorDark = Color(
    0xFFFFB74D,
  ); // Light orange for dark mode
  static const Color infoColor = Color.fromARGB(255, 96, 19, 168); // Dark purple
  static const Color infoColorDark = Color.fromARGB(255, 137, 84, 206); // Light purple for dark mode

  // Light mode colors
  static const Color backgroundColorLight = Color(0xFFFAFAFA);
  static const Color surfaceColorLight = Colors.white;
  static const Color dividerColorLight = Color(0xFFE0E0E0);
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFF9E9E9E);

  // Dark mode colors (WCAG AA compliant)
  static const Color backgroundColorDark = Color(0xFF121212);
  static const Color surfaceColorDark = Color(0xFF1E1E1E);
  static const Color dividerColorDark = Color(0xFF3E3E3E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textDisabledDark = Color(0xFF6E6E6E);

  // Legacy aliases for backward compatibility (use light mode colors)
  static const Color backgroundColor = backgroundColorLight;
  static const Color surfaceColor = surfaceColorLight;
  static const Color dividerColor = dividerColorLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textDisabled = textDisabledLight;

  // Card elevation
  static const double cardElevationLow = 1.0;
  static const double cardElevationMedium = 2.0;
  static const double cardElevationHigh = 4.0;

  // Border radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Button padding
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );
  static const EdgeInsets buttonPaddingMedium = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.all(20.0);

  /// Light theme data for the app
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColorLight,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: cardElevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: spacingSmall,
          horizontal: spacingMedium,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: buttonPaddingMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPaddingMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          side: const BorderSide(color: primaryColor, width: 2),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: buttonPaddingSmall,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColorLight,
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }

  /// Dark theme data for the app
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColorDark,
        brightness: Brightness.dark,
        primary: primaryColorDark,
        secondary: secondaryColorDark,
        error: errorColorDark,
        surface: surfaceColorDark,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surfaceColorDark,
        foregroundColor: textPrimaryDark,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: cardElevationMedium,
        color: surfaceColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: spacingSmall,
          horizontal: spacingMedium,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: buttonPaddingMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: buttonPaddingMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          side: const BorderSide(color: primaryColorDark, width: 2),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: buttonPaddingSmall,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColorDark,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: dividerColorDark,
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }

  /// Get color based on rating (0-100) with dark mode support
  static Color getRatingColor(int rating, {bool isDark = false}) {
    if (isDark) {
      if (rating >= 80) {
        return const Color(0xFF81C784); // Excellent - Light green
      }
      if (rating >= 70) return const Color(0xFF64B5F6); // Good - Light blue
      if (rating >= 60) {
        return const Color(0xFFFFB74D); // Average - Light orange
      }
      return const Color(0xFFEF5350); // Poor - Light red
    } else {
      if (rating >= 80) {
        return const Color(0xFF2E7D32); // Excellent - Dark green
      }
      if (rating >= 70) return const Color(0xFF1565C0); // Good - Dark blue
      if (rating >= 60) return const Color(0xFFEF6C00); // Average - Dark orange
      return const Color(0xFFC62828); // Poor - Dark red
    }
  }

  /// Get color for win/loss display with dark mode support
  static Color getWinLossColor(bool isWin, {bool isDark = false}) {
    if (isDark) {
      return isWin ? successColorDark : errorColorDark;
    } else {
      return isWin ? successColor : errorColor;
    }
  }

  /// Standard page padding
  static const EdgeInsets pagePadding = EdgeInsets.all(spacingMedium);

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingMedium);

  /// Standard section spacing
  static const double sectionSpacing = spacingLarge;
}
