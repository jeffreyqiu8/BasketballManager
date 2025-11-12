import 'package:flutter/material.dart';
import 'save_page.dart';
import '../services/league_service.dart';

/// Title screen - first screen shown when app launches
/// Provides navigation to load/create games
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  void _navigateToSaveScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavePage(
          leagueService: LeagueService(),
          isStartScreen: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    const Color(0xFF4A148C),
                    const Color(0xFF7B1FA2),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Basketball icon
                  Semantics(
                    label: 'Basketball Manager game logo',
                    child: Icon(
                      Icons.sports_basketball,
                      size: 120,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Semantics(
                    label: 'Basketball Manager',
                    header: true,
                    child: const Text(
                      'Basketball Manager',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Subtitle
                  Text(
                    'Manage your team to victory',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Start button
                  SizedBox(
                    width: 280,
                    child: Semantics(
                      label: 'Start game - load or create new save',
                      button: true,
                      child: ElevatedButton(
                        onPressed: () => _navigateToSaveScreen(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isDark
                              ? const Color(0xFF1A1A2E)
                              : const Color(0xFF4A148C),
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 32),
                            SizedBox(width: 12),
                            Text(
                              'START',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 120),
                  
                  // Version info
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
