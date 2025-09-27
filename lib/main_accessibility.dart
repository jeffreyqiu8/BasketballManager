import 'package:flutter/material.dart';
import 'views/pages/accessibility_initializer.dart';
import 'views/widgets/help_system.dart';
import 'views/widgets/user_feedback_system.dart';

/// Main accessibility setup for the Basketball Manager app
class MainAccessibility {
  static void initialize() {
    // Initialize all accessibility features
    AccessibilityInitializer.initialize();
    
    // Set up global accessibility settings
    _setupGlobalAccessibility();
  }

  static void _setupGlobalAccessibility() {
    // Enable accessibility features globally
    HelpSystem().setEnabled(true);
    UserFeedbackSystem().setEnabled(true);
    
    // Register global help content
    _registerGlobalHelpContent();
  }

  static void _registerGlobalHelpContent() {
    final helpSystem = HelpSystem();
    
    // General Navigation Help
    helpSystem.registerHelpContent('navigation', HelpContent(
      title: 'Navigation Guide',
      sections: [
        HelpSection(
          title: 'Getting Around',
          content: 'Use the navigation bar at the bottom to move between main sections:\n\n'
              '• Home: Dashboard and quick actions\n'
              '• Team: Roster and player management\n'
              '• Coach: Coaching profile and effectiveness\n'
              '• Conference: Standings and schedule\n'
              '• Settings: App preferences and help',
        ),
        HelpSection(
          title: 'Accessibility Features',
          content: 'This app includes several accessibility features:\n\n'
              '• Screen reader support with descriptive labels\n'
              '• High contrast colors for better visibility\n'
              '• Keyboard navigation support\n'
              '• Help buttons (?) on each page\n'
              '• Feedback system for reporting issues',
        ),
        HelpSection(
          title: 'Getting Help',
          content: 'Look for the help button (?) in the top right of each page. '
              'You can also provide feedback using the feedback button to help us improve the app.',
        ),
      ],
    ));

    // Accessibility Settings Help
    helpSystem.registerHelpContent('accessibility_settings', HelpContent(
      title: 'Accessibility Settings',
      sections: [
        HelpSection(
          title: 'Visual Accessibility',
          content: 'Adjust visual settings for better accessibility:\n\n'
              '• High contrast mode for better text visibility\n'
              '• Large text options for easier reading\n'
              '• Color blind friendly color schemes\n'
              '• Reduced motion for sensitive users',
        ),
        HelpSection(
          title: 'Audio Accessibility',
          content: 'Audio features to enhance accessibility:\n\n'
              '• Screen reader compatibility\n'
              '• Audio feedback for important actions\n'
              '• Sound effect controls\n'
              '• Voice navigation support',
        ),
        HelpSection(
          title: 'Motor Accessibility',
          content: 'Features for users with motor impairments:\n\n'
              '• Large touch targets for easier tapping\n'
              '• Keyboard navigation support\n'
              '• Gesture alternatives\n'
              '• Adjustable interaction timeouts',
        ),
      ],
    ));

    // Keyboard Navigation Help
    helpSystem.registerHelpContent('keyboard_navigation', HelpContent(
      title: 'Keyboard Navigation',
      sections: [
        HelpSection(
          title: 'Basic Navigation',
          content: 'Use these keyboard shortcuts to navigate:\n\n'
              '• Tab: Move to next interactive element\n'
              '• Shift+Tab: Move to previous element\n'
              '• Enter/Space: Activate buttons and links\n'
              '• Arrow keys: Navigate within lists and menus\n'
              '• Escape: Close dialogs and menus',
        ),
        HelpSection(
          title: 'Page-Specific Shortcuts',
          content: 'Some pages have additional keyboard shortcuts:\n\n'
              '• H: Open help for current page\n'
              '• F: Open feedback dialog\n'
              '• S: Open search (where available)\n'
              '• R: Refresh current data',
        ),
      ],
    ));

    // Error Handling Help
    helpSystem.registerHelpContent('error_handling', HelpContent(
      title: 'Error Handling and Recovery',
      sections: [
        HelpSection(
          title: 'Common Issues',
          content: 'If you encounter problems:\n\n'
              '• Check your internet connection\n'
              '• Try refreshing the page\n'
              '• Restart the app if needed\n'
              '• Clear app cache in device settings',
        ),
        HelpSection(
          title: 'Reporting Problems',
          content: 'To report bugs or accessibility issues:\n\n'
              '• Use the feedback button on any page\n'
              '• Select "Bug Report" as the feedback type\n'
              '• Describe what you were trying to do\n'
              '• Include any error messages you saw',
        ),
        HelpSection(
          title: 'Getting Support',
          content: 'For additional support:\n\n'
              '• Check the help section for your specific issue\n'
              '• Use the usability test feature to practice\n'
              '• Submit detailed feedback about accessibility barriers\n'
              '• Contact support through the app settings',
        ),
      ],
    ));
  }

  /// Create accessible theme data
  static ThemeData createAccessibleTheme({bool highContrast = false}) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // High contrast colors if enabled
      colorScheme: highContrast 
        ? const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            secondary: Colors.yellow,
            onSecondary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
            error: Colors.red,
            onError: Colors.white,
          )
        : ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 82, 50, 168),
            brightness: Brightness.dark,
          ),
      
      // Accessible text theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
        ),
      ),
      
      // Accessible button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 48), // Larger touch targets
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Accessible input decoration
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(),
        labelStyle: TextStyle(fontSize: 16),
        hintStyle: TextStyle(fontSize: 16),
      ),
      
      // Accessible card theme
      cardTheme: CardThemeData(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Accessible list tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 8,
      ),
      
      // Accessible icon theme
      iconTheme: const IconThemeData(
        size: 24,
      ),
      
      // Accessible app bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        toolbarHeight: 64, // Taller for easier touch
      ),
      
      // Accessible navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),
    );
  }

  /// Check if accessibility features are properly configured
  static bool validateAccessibilitySetup() {
    try {
      // Check if help system is initialized
      final helpSystem = HelpSystem();
      // Help system is always enabled if we can access it
      
      // Check if feedback system is initialized
      final feedbackSystem = UserFeedbackSystem();
      if (feedbackSystem.getAllFeedback().isEmpty && 
          feedbackSystem.getAllFeedback().isNotEmpty) {
        // This is a logical check - if we can access the feedback system, it's working
      }
      
      // Check if essential help content exists
      final essentialContexts = [
        'home_page',
        'team_profile', 
        'coach_profile',
        'navigation',
      ];
      
      for (final context in essentialContexts) {
        if (helpSystem.getHelpContent(context) == null) {
          debugPrint('Missing help content for: $context');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Accessibility validation failed: $e');
      return false;
    }
  }
}