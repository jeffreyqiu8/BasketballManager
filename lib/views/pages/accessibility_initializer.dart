import '../widgets/help_system.dart';
import '../widgets/user_feedback_system.dart';

/// Initialize accessibility features for all pages
class AccessibilityInitializer {
  static void initialize() {
    _initializeHelpSystem();
    _initializeUserFeedbackSystem();
  }

  static void _initializeHelpSystem() {
    final helpSystem = HelpSystem();
    
    // Home Page Help
    helpSystem.registerHelpContent('home_page', HelpContent(
      title: 'Home Dashboard',
      sections: [
        HelpSection(
          title: 'Team Overview',
          content: 'View your team\'s current record, upcoming matchups, and top performing players. '
              'Tap on any card to navigate to detailed views.',
        ),
        HelpSection(
          title: 'Quick Actions',
          content: 'Use the quick action buttons to:\n\n'
              '• View conference standings\n'
              '• Manage your playbook\n'
              '• Play the next scheduled game\n'
              '• Regenerate the season schedule',
        ),
        HelpSection(
          title: 'Coaching Dashboard',
          content: 'If you have a coach profile, you\'ll see coaching effectiveness metrics '
              'and recent player development progress.',
        ),
      ],
    ));

    // Team Profile Help
    helpSystem.registerHelpContent('team_profile', HelpContent(
      title: 'Team Profile',
      sections: [
        HelpSection(
          title: 'Team Strategy',
          content: 'Manage your team\'s active playbook and view strategic information. '
              'Different playbooks provide various bonuses to your team\'s performance.',
        ),
        HelpSection(
          title: 'Player Development',
          content: 'Track which players are actively developing their skills. '
              'Young players under 28 have the highest development potential.',
        ),
        HelpSection(
          title: 'Starting Lineup',
          content: 'View and manage role assignments for your starting five players. '
              'Each position has specific requirements, and compatibility percentages '
              'show how well each player fits their assigned role.',
        ),
        HelpSection(
          title: 'Player List',
          content: 'Browse all players on your roster. Enhanced players show additional '
              'information like experience points and role compatibility.',
        ),
      ],
    ));

    // Coach Profile Help
    helpSystem.registerHelpContent('coach_profile', HelpContent(
      title: 'Coach Profile Management',
      sections: [
        HelpSection(
          title: 'Coaching Specializations',
          content: 'Choose your primary and secondary coaching specializations:\n\n'
              '• Offensive: Improves team shooting and ball movement\n'
              '• Defensive: Enhances team defense and steals\n'
              '• Player Development: Accelerates player skill growth\n'
              '• Team Chemistry: Improves player compatibility',
        ),
        HelpSection(
          title: 'Coaching Attributes',
          content: 'Your coaching attributes determine the effectiveness of your specializations. '
              'Higher attributes provide better team bonuses and player development rates.',
        ),
        HelpSection(
          title: 'Experience and Progression',
          content: 'Gain experience by winning games and developing players. '
              'Higher experience levels unlock new coaching abilities and improve your bonuses.',
        ),
        HelpSection(
          title: 'Achievements',
          content: 'Unlock achievements by reaching coaching milestones. '
              'Achievements provide permanent bonuses and showcase your coaching success.',
        ),
      ],
    ));

    // Player Development Help
    helpSystem.registerHelpContent('player_development', HelpContent(
      title: 'Player Development System',
      sections: [
        HelpSection(
          title: 'Skill Development',
          content: 'Players gain experience through games and training:\n\n'
              '• Young players (under 25) develop faster\n'
              '• Experience can be allocated to specific skills\n'
              '• Each player has a potential cap for each skill\n'
              '• Coaching specialization affects development speed',
        ),
        HelpSection(
          title: 'Experience Allocation',
          content: 'Distribute experience points to improve player skills. '
              'Focus on skills that match the player\'s role for maximum effectiveness.',
        ),
        HelpSection(
          title: 'Aging and Decline',
          content: 'Players over 30 begin to decline gradually. '
              'Plan for the future by developing younger players and managing veteran minutes.',
        ),
        HelpSection(
          title: 'Potential System',
          content: 'Each player has hidden potential that determines their maximum skill levels. '
              'Some players may surprise you with higher potential than initially apparent.',
        ),
      ],
    ));

    // Role Assignment Help
    helpSystem.registerHelpContent('role_assignment', HelpContent(
      title: 'Player Role Assignment',
      sections: [
        HelpSection(
          title: 'Position Requirements',
          content: 'Each position has specific skill requirements:\n\n'
              '• Point Guard: Ball handling and passing\n'
              '• Shooting Guard: Shooting and perimeter defense\n'
              '• Small Forward: Balanced skills\n'
              '• Power Forward: Rebounding and inside play\n'
              '• Center: Post defense and rebounding',
        ),
        HelpSection(
          title: 'Role Compatibility',
          content: 'Players perform better in roles that match their skills. '
              'Compatibility ratings show how well each player fits each position.',
        ),
        HelpSection(
          title: 'Optimal Lineups',
          content: 'Use the automatic assignment feature to find the best role '
              'combinations for your team\'s overall performance.',
        ),
      ],
    ));

    // Playbook Manager Help
    helpSystem.registerHelpContent('playbook_manager', HelpContent(
      title: 'Playbook Management',
      sections: [
        HelpSection(
          title: 'Offensive Strategies',
          content: 'Choose strategies that match your team composition:\n\n'
              '• Fast Break: Emphasizes speed and transition scoring\n'
              '• Half Court: Balanced approach with set plays\n'
              '• Pick and Roll: Requires good guards and big men\n'
              '• Post-Up: Focuses on inside scoring with centers\n'
              '• Three-Point Heavy: Emphasizes perimeter shooting',
        ),
        HelpSection(
          title: 'Defensive Strategies',
          content: 'Defensive schemes affect opponent shooting:\n\n'
              '• Man-to-Man: Balanced defense\n'
              '• Zone Defense: Protects the paint\n'
              '• Press Defense: Forces turnovers but allows easy shots\n'
              '• Switch Defense: Requires versatile defenders',
        ),
        HelpSection(
          title: 'Playbook Effectiveness',
          content: 'Different playbooks work better with different team compositions. '
              'Check effectiveness ratings to see how well your playbook matches your roster.',
        ),
      ],
    ));

    // Conference Standings Help
    helpSystem.registerHelpContent('conference_standings', HelpContent(
      title: 'Conference Standings',
      sections: [
        HelpSection(
          title: 'Standings Table',
          content: 'View team rankings, win-loss records, and playoff positioning. '
              'Teams are ranked by winning percentage and playoff seeding.',
        ),
        HelpSection(
          title: 'Playoff Race',
          content: 'Track which teams are in playoff contention and monitor '
              'your team\'s position relative to playoff cutoffs.',
        ),
        HelpSection(
          title: 'Team Comparison',
          content: 'Compare your team\'s performance against conference rivals '
              'and identify areas for improvement.',
        ),
      ],
    ));

    // Initialize default content
    helpSystem.initializeDefaultContent();
  }

  static void _initializeUserFeedbackSystem() {
    final feedbackSystem = UserFeedbackSystem();
    
    // Initialize default usability tests
    feedbackSystem.initializeDefaultTests();
    
    // Register additional tests specific to basketball manager
    feedbackSystem.registerUsabilityTest('team_management_test', UsabilityTest(
      id: 'team_management_test',
      title: 'Team Management Usability Test',
      description: 'Test the team management and roster features',
      tasks: [
        UsabilityTask(
          id: 'view_team_profile',
          title: 'View Team Profile',
          description: 'Navigate to and explore the team profile page',
          instructions: 'From the home page, tap on your team card to view the team profile',
          expectedDuration: Duration(minutes: 1),
        ),
        UsabilityTask(
          id: 'assign_player_roles',
          title: 'Assign Player Roles',
          description: 'Assign or modify player roles in the starting lineup',
          instructions: 'Go to role assignment and change at least one player\'s position',
          expectedDuration: Duration(minutes: 2),
        ),
        UsabilityTask(
          id: 'develop_player',
          title: 'Develop Player Skills',
          description: 'Allocate experience points to improve a player\'s skills',
          instructions: 'Navigate to player development and allocate experience to any skill',
          expectedDuration: Duration(minutes: 2),
        ),
      ],
    ));

    feedbackSystem.registerUsabilityTest('coaching_test', UsabilityTest(
      id: 'coaching_test',
      title: 'Coaching System Test',
      description: 'Test the coaching profile and effectiveness features',
      tasks: [
        UsabilityTask(
          id: 'create_coach_profile',
          title: 'Create or Edit Coach Profile',
          description: 'Set up your coaching specializations and attributes',
          instructions: 'Navigate to coach profile and modify your specializations',
          expectedDuration: Duration(minutes: 3),
        ),
        UsabilityTask(
          id: 'view_coaching_effectiveness',
          title: 'View Coaching Effectiveness',
          description: 'Check your coaching effectiveness and team bonuses',
          instructions: 'View the coaching effectiveness dashboard',
          expectedDuration: Duration(minutes: 1),
        ),
      ],
    ));
  }
}