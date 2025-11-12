import 'package:flutter/material.dart';

/// Enhanced theme data for better visual design
class UIThemeEnhancements {
  static ThemeData enhanceTheme(ThemeData baseTheme) {
    return baseTheme.copyWith(
      // Enhanced card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      ),
      
      // Enhanced elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      
      // Enhanced input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: baseTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Enhanced app bar theme
      appBarTheme: baseTheme.appBarTheme.copyWith(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      
      // Enhanced floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Custom color schemes for different contexts
  static ColorScheme getSaveManagementColorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF81C784),
        surface: Color(0xFF1E1E1E),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFF66BB6A),
        surface: Color(0xFFFAFAFA),
      );
    }
  }

  static ColorScheme getMatchHistoryColorScheme(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const ColorScheme.dark(
        primary: Color(0xFF2196F3),
        secondary: Color(0xFF64B5F6),
        surface: Color(0xFF1E1E1E),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF1976D2),
        secondary: Color(0xFF42A5F5),
        surface: Color(0xFFFAFAFA),
      );
    }
  }
}

/// Enhanced visual effects and decorations
class VisualEffects {
  /// Glassmorphism effect for modern UI
  static BoxDecoration glassmorphism({
    Color? color,
    double blur = 10,
    double opacity = 0.1,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Neumorphism effect for subtle depth
  static BoxDecoration neumorphism({
    Color? backgroundColor,
    double depth = 4,
    BorderRadius? borderRadius,
  }) {
    final bgColor = backgroundColor ?? Colors.grey.shade100;
    return BoxDecoration(
      color: bgColor,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.white,
          offset: Offset(-depth, -depth),
          blurRadius: depth * 2,
        ),
        BoxShadow(
          color: Colors.grey.shade400,
          offset: Offset(depth, depth),
          blurRadius: depth * 2,
        ),
      ],
    );
  }

  /// Gradient background for cards
  static BoxDecoration gradientCard({
    List<Color>? colors,
    BorderRadius? borderRadius,
    double elevation = 2,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ?? [
          Colors.white,
          Colors.grey.shade50,
        ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  /// Animated border effect
  static Widget animatedBorder({
    required Widget child,
    Color? borderColor,
    double width = 2,
    Duration duration = const Duration(seconds: 2),
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? Colors.blue,
          width: width,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Enhanced spacing and layout utilities
class LayoutEnhancements {
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;

  static const EdgeInsets smallPadding = EdgeInsets.all(smallSpacing);
  static const EdgeInsets mediumPadding = EdgeInsets.all(mediumSpacing);
  static const EdgeInsets largePadding = EdgeInsets.all(largeSpacing);

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(20.0);

  /// Responsive breakpoints
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  /// Responsive grid columns
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  /// Responsive font sizes
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.1;
    if (isTablet(context)) return baseSize * 1.05;
    return baseSize;
  }
}

/// Enhanced icon set for basketball management
class BasketballIcons {
  static const IconData basketball = Icons.sports_basketball;
  static const IconData coach = Icons.person;
  static const IconData team = Icons.group;
  static const IconData stats = Icons.analytics;
  static const IconData trophy = Icons.emoji_events;
  static const IconData playbook = Icons.menu_book;
  static const IconData development = Icons.trending_up;
  static const IconData save = Icons.save;
  static const IconData load = Icons.folder_open;
  static const IconData settings = Icons.settings;
  static const IconData help = Icons.help_outline;
  static const IconData feedback = Icons.feedback_outlined;
  static const IconData history = Icons.history;
  static const IconData calendar = Icons.calendar_today;
  static const IconData conference = Icons.account_tree;
  static const IconData playoffs = Icons.military_tech;
  static const IconData championship = Icons.workspace_premium;
}

/// Color palette for basketball management theme
class BasketballColors {
  // Primary colors
  static const Color courtOrange = Color(0xFFFF6B35);
  static const Color basketballBrown = Color(0xFFD2691E);
  static const Color courtGreen = Color(0xFF228B22);
  
  // Team colors
  static const Color homeTeam = Color(0xFF1976D2);
  static const Color awayTeam = Color(0xFFD32F2F);
  
  // Status colors
  static const Color win = Color(0xFF4CAF50);
  static const Color loss = Color(0xFFF44336);
  static const Color tie = Color(0xFFFF9800);
  
  // Performance colors
  static const Color excellent = Color(0xFF4CAF50);
  static const Color good = Color(0xFF8BC34A);
  static const Color average = Color(0xFFFFEB3B);
  static const Color poor = Color(0xFFFF9800);
  static const Color terrible = Color(0xFFF44336);
  
  // UI colors
  static const Color cardBackground = Color(0xFFFAFAFA);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
}

/// Typography enhancements for basketball management
class BasketballTypography {
  static TextStyle getStatNumberStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle getStatLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      color: BasketballColors.textSecondary,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle getTeamNameStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getScoreStyle(BuildContext context) {
    return Theme.of(context).textTheme.displaySmall!.copyWith(
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Animation presets for common UI patterns
class AnimationPresets {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;

  // Common animation combinations
  static const Duration cardHover = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalAppear = Duration(milliseconds: 250);
  static const Duration loadingSpinner = Duration(milliseconds: 1000);
}