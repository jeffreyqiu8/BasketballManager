// Enhanced data model enums for basketball manager game

/// Player roles representing basketball positions
enum PlayerRole {
  pointGuard('PG', 'Point Guard'),
  shootingGuard('SG', 'Shooting Guard'),
  smallForward('SF', 'Small Forward'),
  powerForward('PF', 'Power Forward'),
  center('C', 'Center');

  const PlayerRole(this.abbreviation, this.displayName);
  
  final String abbreviation;
  final String displayName;
}

/// Coaching specializations for enhanced coach profiles
enum CoachingSpecialization {
  offensive('Offensive', 'Focuses on improving team offensive capabilities'),
  defensive('Defensive', 'Specializes in defensive strategies and player development'),
  playerDevelopment('Player Development', 'Accelerates player skill growth and potential'),
  teamChemistry('Team Chemistry', 'Improves team cohesion and player relationships');

  const CoachingSpecialization(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Offensive strategies for playbook system
enum OffensiveStrategy {
  fastBreak('Fast Break', 'Quick transition offense focusing on speed'),
  halfCourt('Half Court', 'Methodical half-court offense with set plays'),
  pickAndRoll('Pick and Roll', 'Heavy emphasis on pick and roll plays'),
  postUp('Post-Up', 'Inside-focused offense through post players'),
  threePointHeavy('Three Point Heavy', 'Perimeter-focused offense with many 3-point attempts');

  const OffensiveStrategy(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Defensive strategies for playbook system
enum DefensiveStrategy {
  manToMan('Man-to-Man', 'Traditional man-to-man defense'),
  zoneDefense('Zone Defense', '2-3 or 3-2 zone defensive schemes'),
  pressDefense('Press Defense', 'Full-court or half-court press'),
  switchDefense('Switch Defense', 'Switch on all screens and picks');

  const DefensiveStrategy(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Achievement types for coach progression
enum AchievementType {
  wins('Wins', 'Achievements based on total wins'),
  championships('Championships', 'Achievements for winning championships'),
  development('Development', 'Achievements for player development success'),
  experience('Experience', 'Achievements for coaching experience milestones');

  const AchievementType(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

/// Player potential tiers for development system
enum PotentialTier {
  bronze('Bronze', 'Limited potential for growth'),
  silver('Silver', 'Moderate potential for improvement'),
  gold('Gold', 'High potential for significant growth'),
  elite('Elite', 'Exceptional potential for superstar development');

  const PotentialTier(this.displayName, this.description);
  
  final String displayName;
  final String description;
}