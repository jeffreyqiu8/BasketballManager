import 'package:flutter/material.dart';
import 'dart:async';

/// User feedback system for collecting user input and testing
class UserFeedbackSystem {
  static final UserFeedbackSystem _instance = UserFeedbackSystem._internal();
  factory UserFeedbackSystem() => _instance;
  UserFeedbackSystem._internal();

  final List<FeedbackEntry> _feedbackEntries = [];
  final Map<String, UsabilityTest> _usabilityTests = {};
  bool _isEnabled = true;

  /// Submit feedback
  void submitFeedback(FeedbackEntry feedback) {
    if (_isEnabled) {
      _feedbackEntries.add(feedback);
      _processFeedback(feedback);
    }
  }

  /// Show feedback dialog
  void showFeedbackDialog(BuildContext context, {String? feature}) {
    if (!_isEnabled) return;

    showDialog(
      context: context,
      builder: (context) => FeedbackDialog(feature: feature),
    );
  }

  /// Show quick rating dialog
  void showQuickRating(BuildContext context, String feature) {
    if (!_isEnabled) return;

    showDialog(
      context: context,
      builder: (context) => QuickRatingDialog(feature: feature),
    );
  }

  /// Start usability test
  void startUsabilityTest(BuildContext context, String testId) {
    final test = _usabilityTests[testId];
    if (test != null && _isEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UsabilityTestScreen(test: test),
        ),
      );
    }
  }

  /// Register usability test
  void registerUsabilityTest(String testId, UsabilityTest test) {
    _usabilityTests[testId] = test;
  }

  /// Get all feedback entries
  List<FeedbackEntry> getAllFeedback() {
    return List.from(_feedbackEntries);
  }

  /// Get feedback for specific feature
  List<FeedbackEntry> getFeedbackForFeature(String feature) {
    return _feedbackEntries.where((f) => f.feature == feature).toList();
  }

  /// Get feedback analytics
  FeedbackAnalytics getAnalytics() {
    final totalFeedback = _feedbackEntries.length;
    final averageRating = _feedbackEntries.isNotEmpty
        ? _feedbackEntries.map((f) => f.rating).reduce((a, b) => a + b) / totalFeedback
        : 0.0;

    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = _feedbackEntries.where((f) => f.rating == i).length;
    }

    final featureFeedback = <String, List<FeedbackEntry>>{};
    for (final feedback in _feedbackEntries) {
      featureFeedback.putIfAbsent(feedback.feature, () => []).add(feedback);
    }

    return FeedbackAnalytics(
      totalFeedback: totalFeedback,
      averageRating: averageRating,
      ratingDistribution: ratingDistribution,
      featureFeedback: featureFeedback,
    );
  }

  /// Enable or disable feedback system
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Initialize default usability tests
  void initializeDefaultTests() {
    registerUsabilityTest('coach_profile_test', UsabilityTest(
      id: 'coach_profile_test',
      title: 'Coach Profile Usability Test',
      description: 'Test the coach profile creation and management features',
      tasks: [
        UsabilityTask(
          id: 'create_coach',
          title: 'Create Coach Profile',
          description: 'Create a new coach profile with your preferred specializations',
          instructions: 'Navigate to the coach profile page and create a new profile',
          expectedDuration: Duration(minutes: 2),
        ),
        UsabilityTask(
          id: 'modify_specialization',
          title: 'Modify Specialization',
          description: 'Change your coaching specialization',
          instructions: 'Edit your coach profile and change the primary specialization',
          expectedDuration: Duration(minutes: 1),
        ),
      ],
    ));

    registerUsabilityTest('player_development_test', UsabilityTest(
      id: 'player_development_test',
      title: 'Player Development Test',
      description: 'Test the player development and training features',
      tasks: [
        UsabilityTask(
          id: 'allocate_experience',
          title: 'Allocate Experience Points',
          description: 'Allocate experience points to improve a player\'s skills',
          instructions: 'Go to player development and allocate points to shooting skill',
          expectedDuration: Duration(minutes: 3),
        ),
        UsabilityTask(
          id: 'view_potential',
          title: 'View Player Potential',
          description: 'Check a player\'s potential and development progress',
          instructions: 'View the potential tab for any player',
          expectedDuration: Duration(minutes: 1),
        ),
      ],
    ));
  }

  void _processFeedback(FeedbackEntry feedback) {
    // Process feedback (could send to analytics service, etc.)
    print('Feedback received: ${feedback.feature} - Rating: ${feedback.rating}');
    if (feedback.comment.isNotEmpty) {
      print('Comment: ${feedback.comment}');
    }
  }
}

/// Feedback entry structure
class FeedbackEntry {
  final String feature;
  final int rating; // 1-5 stars
  final String comment;
  final FeedbackType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  FeedbackEntry({
    required this.feature,
    required this.rating,
    required this.comment,
    required this.type,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();
}

enum FeedbackType {
  general,
  bug,
  feature_request,
  usability,
  performance,
}

/// Feedback analytics structure
class FeedbackAnalytics {
  final int totalFeedback;
  final double averageRating;
  final Map<int, int> ratingDistribution;
  final Map<String, List<FeedbackEntry>> featureFeedback;

  FeedbackAnalytics({
    required this.totalFeedback,
    required this.averageRating,
    required this.ratingDistribution,
    required this.featureFeedback,
  });
}

/// Usability test structure
class UsabilityTest {
  final String id;
  final String title;
  final String description;
  final List<UsabilityTask> tasks;

  UsabilityTest({
    required this.id,
    required this.title,
    required this.description,
    required this.tasks,
  });
}

/// Usability task structure
class UsabilityTask {
  final String id;
  final String title;
  final String description;
  final String instructions;
  final Duration expectedDuration;

  UsabilityTask({
    required this.id,
    required this.title,
    required this.description,
    required this.instructions,
    required this.expectedDuration,
  });
}

/// Feedback dialog widget
class FeedbackDialog extends StatefulWidget {
  final String? feature;

  const FeedbackDialog({Key? key, this.feature}) : super(key: key);

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 5;
  String _comment = '';
  FeedbackType _type = FeedbackType.general;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final feedback = FeedbackEntry(
      feature: widget.feature ?? 'General',
      rating: _rating,
      comment: _comment,
      type: _type,
    );

    UserFeedbackSystem().submitFeedback(feedback);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (widget.feature != null) ...[
              SizedBox(height: 8),
              Text(
                'Feature: ${widget.feature}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            SizedBox(height: 24),
            
            // Rating
            Text('Rating', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                );
              }),
            ),
            
            SizedBox(height: 16),
            
            // Feedback type
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            DropdownButtonFormField<FeedbackType>(
              value: _type,
              items: FeedbackType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getFeedbackTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Comment
            Text('Comment (optional)', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              onChanged: (value) {
                _comment = value;
              },
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitFeedback,
                  child: Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFeedbackTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.general:
        return 'General Feedback';
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature_request:
        return 'Feature Request';
      case FeedbackType.usability:
        return 'Usability Issue';
      case FeedbackType.performance:
        return 'Performance Issue';
    }
  }
}

/// Quick rating dialog
class QuickRatingDialog extends StatelessWidget {
  final String feature;

  const QuickRatingDialog({Key? key, required this.feature}) : super(key: key);

  void _submitRating(BuildContext context, int rating) {
    final feedback = FeedbackEntry(
      feature: feature,
      rating: rating,
      comment: '',
      type: FeedbackType.general,
    );

    UserFeedbackSystem().submitFeedback(feedback);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you for rating $feature!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate this feature',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => _submitRating(context, index + 1),
                );
              }),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Usability test screen
class UsabilityTestScreen extends StatefulWidget {
  final UsabilityTest test;

  const UsabilityTestScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<UsabilityTestScreen> createState() => _UsabilityTestScreenState();
}

class _UsabilityTestScreenState extends State<UsabilityTestScreen> {
  int currentTaskIndex = 0;
  DateTime? taskStartTime;
  final List<Duration> taskDurations = [];
  final List<String> taskNotes = [];

  @override
  void initState() {
    super.initState();
    _startCurrentTask();
  }

  void _startCurrentTask() {
    taskStartTime = DateTime.now();
  }

  void _completeCurrentTask() {
    if (taskStartTime != null) {
      final duration = DateTime.now().difference(taskStartTime!);
      taskDurations.add(duration);
    }

    if (currentTaskIndex < widget.test.tasks.length - 1) {
      setState(() {
        currentTaskIndex++;
      });
      _startCurrentTask();
    } else {
      _completeTest();
    }
  }

  void _completeTest() {
    // Submit test results
    final feedback = FeedbackEntry(
      feature: widget.test.title,
      rating: 5, // Default rating, could be collected
      comment: 'Usability test completed',
      type: FeedbackType.usability,
      metadata: {
        'testId': widget.test.id,
        'taskDurations': taskDurations.map((d) => d.inMilliseconds).toList(),
        'taskNotes': taskNotes,
      },
    );

    UserFeedbackSystem().submitFeedback(feedback);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usability test completed. Thank you!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTask = widget.test.tasks[currentTaskIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Exit Test', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentTaskIndex + 1) / widget.test.tasks.length,
            ),
            SizedBox(height: 16),
            Text(
              'Task ${currentTaskIndex + 1} of ${widget.test.tasks.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 8),
            Text(
              currentTask.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(currentTask.description),
                    SizedBox(height: 16),
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(currentTask.instructions),
                    SizedBox(height: 16),
                    Text(
                      'Expected Duration: ${currentTask.expectedDuration.inMinutes} minutes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _completeCurrentTask,
                  child: Text(
                    currentTaskIndex < widget.test.tasks.length - 1
                        ? 'Task Complete'
                        : 'Finish Test',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Feedback button widget
class FeedbackButton extends StatelessWidget {
  final String? feature;
  final IconData icon;
  final String tooltip;

  const FeedbackButton({
    Key? key,
    this.feature,
    this.icon = Icons.feedback_outlined,
    this.tooltip = 'Give feedback',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => UserFeedbackSystem().showFeedbackDialog(context, feature: feature),
    );
  }
}