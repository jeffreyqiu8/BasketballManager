
class Player {
  // General attributes
  String name;
  int age;
  String team;
  int experienceYears;
  String nationality;
  String currentStatus;

  // Gameplay attributes
  int height;
  int shooting;
  int rebounding;
  int passing;
  
  // New gameplay attributes
  int ballHandling; // Added for ball control
  int perimeterDefense; // Added for defense against outside players
  int postDefense; // Added for defense against post players
  int insideShooting; // Added for inside scoring ability

  // New attribute for performance tracking
  Map<int, Map<String, int>> performances;  // Key is the matchday (int), and value is a map of stats (e.g., points, rebounds, assists)

  // Constructor
  Player({
    required this.name,
    required this.age,
    required this.team,
    required this.experienceYears,
    required this.nationality,
    required this.currentStatus,
    required this.height,
    required this.shooting,
    required this.rebounding,
    required this.passing,
    required this.ballHandling, // Added parameter
    required this.perimeterDefense, // Added parameter
    required this.postDefense, // Added parameter
    required this.insideShooting, // Added parameter
    required this.performances, // New parameter
  });

  // Method to display player's details
  String displayInfo() {
    return 'Player: $name\nAge: $age\nTeam: $team\nExperience: $experienceYears years\nNationality: $nationality\nStatus: $currentStatus';
  }

  // Method to update team
  void updateTeam(String newTeam) {
    team = newTeam;
  }

  // Method to update status
  void updateStatus(String newStatus) {
    currentStatus = newStatus;
  }

  // Method to increment years of experience
  void addExperience(int years) {
    experienceYears += years;
  }

  // Method to retire the player
  void retire() {
    currentStatus = 'Retired';
  }

  // Method to record performance for a matchday
  void recordPerformance(int matchday, List<int> stats) {
    performances[matchday] = {
      'points': stats[0],
      'rebounds': stats[1],
      'assists': stats[2],
      'FGM' : stats[3],
      'FGA' : stats[4],
      '3PM' : stats[5],
      '3PA' : stats[6],
      'FG%' : ((stats[3]/stats[4]) * 100).round(),
      '3PT%' : ((stats[5]/stats[6]) * 100).round(),
    };
  }

  // Method to get the performance for a specific matchday
  Map<String, int>? getPerformance(int matchday) {
    return performances[matchday];
  }

  // Method to return the player's current attributes as a map (useful for saving to a database, like Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'team': team,
      'experienceYears': experienceYears,
      'nationality': nationality,
      'currentStatus': currentStatus,
      'height': height,
      'shooting': shooting,
      'rebounding': rebounding,
      'passing': passing,
      'ballHandling': ballHandling, // Include the new attributes
      'perimeterDefense': perimeterDefense, // Include the new attributes
      'postDefense': postDefense, // Include the new attributes
      'insideShooting': insideShooting, // Include the new attribute
      'performances': performances,  // Include the performances map
    };
  }

  // Factory method to create a Player from a Map (useful when reading from a database)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'],
      age: map['age'],
      team: map['team'],
      experienceYears: map['experienceYears'],
      nationality: map['nationality'],
      currentStatus: map['currentStatus'],
      height: map['height'],
      shooting: map['shooting'],
      rebounding: map['rebounding'],
      passing: map['passing'],
      ballHandling: map['ballHandling'], // Deserialize new attribute
      perimeterDefense: map['perimeterDefense'], // Deserialize new attribute
      postDefense: map['postDefense'], // Deserialize new attribute
      insideShooting: map['insideShooting'], // Deserialize new attribute
      performances: Map<int, Map<String, int>>.from(map['performances'] ?? {}),  // Deserialize performances map
    );
  }
}
