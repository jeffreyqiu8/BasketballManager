import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:BasketballManager/views/widgets/accessible_widgets.dart';
import 'package:BasketballManager/views/widgets/help_system.dart';
import 'package:BasketballManager/views/widgets/smooth_animations.dart';
import 'package:BasketballManager/views/widgets/user_feedback_system.dart';
import 'package:BasketballManager/views/widgets/lazy_loading_widget.dart';

void main() {
  group('User Experience Tests', () {
    group('Accessible Widgets', () {
      testWidgets('AccessibleButton should have proper semantics', (tester) async {
        bool buttonPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                text: 'Test Button',
                onPressed: () => buttonPressed = true,
                semanticLabel: 'Test button for accessibility',
              ),
            ),
          ),
        );

        // Find the button
        final buttonFinder = find.text('Test Button');
        expect(buttonFinder, findsOneWidget);

        // Test button press
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(buttonPressed, isTrue);

        // Test semantics
        final semantics = tester.getSemantics(buttonFinder);
        expect(semantics.label, contains('Test button for accessibility'));
      });

      testWidgets('AccessibleTextField should have proper labels', (tester) async {
        final controller = TextEditingController();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleTextField(
                label: 'Test Field',
                controller: controller,
                required: true,
                hint: 'Enter test value',
              ),
            ),
          ),
        );

        // Find the text field
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        // Test required indicator
        expect(find.text('*'), findsOneWidget);

        // Test input
        await tester.enterText(textFieldFinder, 'test input');
        expect(controller.text, equals('test input'));
      });

      testWidgets('AccessibleCard should handle tap and selection', (tester) async {
        bool cardTapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleCard(
                onTap: () => cardTapped = true,
                selected: true,
                semanticLabel: 'Test card',
                child: Text('Card Content'),
              ),
            ),
          ),
        );

        // Find the card content
        final cardFinder = find.text('Card Content');
        expect(cardFinder, findsOneWidget);

        // Test tap
        await tester.tap(cardFinder);
        await tester.pump();
        expect(cardTapped, isTrue);
      });

      testWidgets('AccessibleSlider should show value changes', (tester) async {
        double sliderValue = 50.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return AccessibleSlider(
                    label: 'Test Slider',
                    value: sliderValue,
                    min: 0.0,
                    max: 100.0,
                    onChanged: (value) {
                      setState(() {
                        sliderValue = value;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Find the slider
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget);

        // Test value display
        expect(find.text('50.0'), findsOneWidget);
      });
    });

    group('Help System', () {
      testWidgets('HelpButton should show help dialog', (tester) async {
        // Initialize help system with test content
        final helpSystem = HelpSystem();
        helpSystem.registerHelpContent('test_context', HelpContent(
          title: 'Test Help',
          sections: [
            HelpSection(
              title: 'Test Section',
              content: 'This is test help content',
            ),
          ],
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HelpButton(contextId: 'test_context'),
            ),
          ),
        );

        // Find and tap help button
        final helpButtonFinder = find.byType(IconButton);
        expect(helpButtonFinder, findsOneWidget);

        await tester.tap(helpButtonFinder);
        await tester.pumpAndSettle();

        // Check if help dialog is shown
        expect(find.text('Test Help'), findsOneWidget);
        expect(find.text('This is test help content'), findsOneWidget);
      });

      testWidgets('Tutorial should navigate through steps', (tester) async {
        final tutorial = Tutorial(
          id: 'test_tutorial',
          title: 'Test Tutorial',
          description: 'A test tutorial',
          steps: [
            TutorialStep(
              title: 'Step 1',
              content: 'First step content',
            ),
            TutorialStep(
              title: 'Step 2',
              content: 'Second step content',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TutorialScreen(tutorial: tutorial),
          ),
        );

        // Check first step
        expect(find.text('Step 1'), findsOneWidget);
        expect(find.text('First step content'), findsOneWidget);

        // Navigate to next step
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Check second step
        expect(find.text('Step 2'), findsOneWidget);
        expect(find.text('Second step content'), findsOneWidget);

        // Check finish button
        expect(find.text('Finish'), findsOneWidget);
      });
    });

    group('Smooth Animations', () {
      testWidgets('SmoothFadeTransition should animate visibility', (tester) async {
        bool visible = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            visible = !visible;
                          });
                        },
                        child: Text('Toggle'),
                      ),
                      SmoothFadeTransition(
                        visible: visible,
                        child: Text('Animated Content'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Initially not visible
        expect(find.text('Animated Content'), findsOneWidget);
        
        // Toggle visibility
        await tester.tap(find.text('Toggle'));
        await tester.pump();
        await tester.pump(Duration(milliseconds: 150)); // Mid-animation
        await tester.pumpAndSettle(); // Complete animation
      });

      testWidgets('AnimatedCounter should count up', (tester) async {
        int counterValue = 0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            counterValue += 10;
                          });
                        },
                        child: Text('Increment'),
                      ),
                      AnimatedCounter(
                        value: counterValue,
                        duration: Duration(milliseconds: 100),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Initial value
        expect(find.text('0'), findsOneWidget);

        // Increment and animate
        await tester.tap(find.text('Increment'));
        await tester.pump();
        await tester.pump(Duration(milliseconds: 50)); // Mid-animation
        await tester.pumpAndSettle(); // Complete animation

        expect(find.text('10'), findsOneWidget);
      });

      testWidgets('StaggeredAnimationList should animate children', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StaggeredAnimationList(
                staggerDelay: Duration(milliseconds: 50),
                children: [
                  Text('Item 1'),
                  Text('Item 2'),
                  Text('Item 3'),
                ],
              ),
            ),
          ),
        );

        // All items should be present
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.text('Item 3'), findsOneWidget);

        // Let animations complete
        await tester.pumpAndSettle();
      });
    });

    group('User Feedback System', () {
      testWidgets('FeedbackButton should show feedback dialog', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedbackButton(feature: 'Test Feature'),
            ),
          ),
        );

        // Find and tap feedback button
        final feedbackButtonFinder = find.byType(IconButton);
        expect(feedbackButtonFinder, findsOneWidget);

        await tester.tap(feedbackButtonFinder);
        await tester.pumpAndSettle();

        // Check if feedback dialog is shown
        expect(find.text('Feedback'), findsOneWidget);
        expect(find.text('Feature: Test Feature'), findsOneWidget);
      });

      testWidgets('FeedbackDialog should collect user input', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => FeedbackDialog(feature: 'Test'),
                      );
                    },
                    child: Text('Show Feedback'),
                  );
                },
              ),
            ),
          ),
        );

        // Show dialog
        await tester.tap(find.text('Show Feedback'));
        await tester.pumpAndSettle();

        // Test rating selection
        final starButtons = find.byIcon(Icons.star_border);
        expect(starButtons, findsWidgets);

        // Tap first star (1-star rating)
        await tester.tap(starButtons.first);
        await tester.pump();

        // Enter comment
        final commentField = find.byType(TextField);
        await tester.enterText(commentField, 'Test feedback comment');

        // Submit feedback
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Thank you for your feedback!'), findsOneWidget);
      });

      test('UserFeedbackSystem should store feedback entries', () {
        final feedbackSystem = UserFeedbackSystem();
        
        final feedback = FeedbackEntry(
          feature: 'Test Feature',
          rating: 4,
          comment: 'Great feature!',
          type: FeedbackType.general,
        );

        feedbackSystem.submitFeedback(feedback);

        final allFeedback = feedbackSystem.getAllFeedback();
        expect(allFeedback.length, greaterThan(0));
        expect(allFeedback.last.feature, equals('Test Feature'));
        expect(allFeedback.last.rating, equals(4));
      });

      test('UserFeedbackSystem should generate analytics', () {
        final feedbackSystem = UserFeedbackSystem();
        
        // Add multiple feedback entries
        for (int i = 1; i <= 5; i++) {
          feedbackSystem.submitFeedback(FeedbackEntry(
            feature: 'Feature $i',
            rating: i,
            comment: 'Comment $i',
            type: FeedbackType.general,
          ));
        }

        final analytics = feedbackSystem.getAnalytics();
        expect(analytics.totalFeedback, greaterThanOrEqualTo(5));
        expect(analytics.averageRating, greaterThan(0));
        expect(analytics.ratingDistribution, isNotEmpty);
      });
    });

    group('Lazy Loading', () {
      testWidgets('LazyLoadingWidget should show loading state', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyLoadingWidget<String>(
                loader: () async {
                  await Future.delayed(Duration(milliseconds: 100));
                  return 'Loaded Content';
                },
                builder: (context, data) => Text(data),
                loadOnInit: true,
              ),
            ),
          ),
        );

        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Should show loaded content
        expect(find.text('Loaded Content'), findsOneWidget);
      });

      testWidgets('LazyLoadingWidget should handle errors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyLoadingWidget<String>(
                loader: () async {
                  throw Exception('Test error');
                },
                builder: (context, data) => Text(data),
                loadOnInit: true,
              ),
            ),
          ),
        );

        // Wait for error to occur
        await tester.pumpAndSettle();

        // Should show error state
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('LazyLoadingListView should load items progressively', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LazyLoadingListView<String>(
                loader: (offset, limit) async {
                  await Future.delayed(Duration(milliseconds: 50));
                  return List.generate(limit, (i) => 'Item ${offset + i}');
                },
                itemBuilder: (context, item, index) => ListTile(title: Text(item)),
                pageSize: 5,
              ),
            ),
          ),
        );

        // Wait for initial load
        await tester.pumpAndSettle();

        // Should show first batch of items
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 4'), findsOneWidget);

        // Scroll to trigger more loading
        await tester.drag(find.byType(ListView), Offset(0, -500));
        await tester.pumpAndSettle();

        // Should load more items
        expect(find.text('Item 5'), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('Accessibility and animations should work together', (tester) async {
        bool buttonPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmoothFadeTransition(
                visible: true,
                child: AccessibleButton(
                  text: 'Animated Accessible Button',
                  onPressed: () => buttonPressed = true,
                  semanticLabel: 'Animated button with accessibility',
                ),
              ),
            ),
          ),
        );

        // Wait for animation to complete
        await tester.pumpAndSettle();

        // Test button functionality
        await tester.tap(find.text('Animated Accessible Button'));
        await tester.pump();
        expect(buttonPressed, isTrue);
      });

      testWidgets('Help system should work with feedback system', (tester) async {
        // Initialize systems
        final helpSystem = HelpSystem();
        helpSystem.registerHelpContent('test_feature', HelpContent(
          title: 'Test Feature Help',
          sections: [
            HelpSection(
              title: 'How to use',
              content: 'This is how you use the feature',
            ),
          ],
        ));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  HelpButton(contextId: 'test_feature'),
                  FeedbackButton(feature: 'test_feature'),
                ],
              ),
            ),
          ),
        );

        // Test help button
        final helpButtons = find.byType(IconButton);
        await tester.tap(helpButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('Test Feature Help'), findsOneWidget);

        // Close help dialog
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Test feedback button
        await tester.tap(helpButtons.last);
        await tester.pumpAndSettle();

        expect(find.text('Feedback'), findsOneWidget);
        expect(find.text('Feature: test_feature'), findsOneWidget);
      });
    });
  });
}