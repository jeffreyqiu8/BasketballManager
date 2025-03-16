
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
      'age': age.toString(),
      'team': team,
      'experienceYears': experienceYears.toString(),
      'nationality': nationality,
      'currentStatus': currentStatus,
      'height': height.toString(),
      'shooting': shooting.toString(),
      'rebounding': rebounding.toString(),
      'passing': passing.toString(),
      'ballHandling': ballHandling.toString(),
      'perimeterDefense': perimeterDefense.toString(),
      'postDefense': postDefense.toString(),
      'insideShooting': insideShooting.toString(),
      'performances': performances.map((key, value) => MapEntry(
          key.toString(), value.map((stat, num) => MapEntry(stat, num.toString())))),
    };
  }

   // Factory method to create a Player from a Map
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'] ?? 'Unknown',
      age: int.tryParse(map['age'].toString()) ?? 18,
      team: map['team'] ?? 'Free Agent',
      experienceYears: int.tryParse(map['experienceYears'].toString()) ?? 0,
      nationality: map['nationality'] ?? 'Unknown',
      currentStatus: map['currentStatus'] ?? 'Active',
      height: int.tryParse(map['height'].toString()) ?? 180,
      shooting: int.tryParse(map['shooting'].toString()) ?? 50,
      rebounding: int.tryParse(map['rebounding'].toString()) ?? 50,
      passing: int.tryParse(map['passing'].toString()) ?? 50,
      ballHandling: int.tryParse(map['ballHandling'].toString()) ?? 50,
      perimeterDefense: int.tryParse(map['perimeterDefense'].toString()) ?? 50,
      postDefense: int.tryParse(map['postDefense'].toString()) ?? 50,
      insideShooting: int.tryParse(map['insideShooting'].toString()) ?? 50,
      performances: (map['performances'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.tryParse(key) ?? 0,
              (value as Map<String, dynamic>)
                  .map((stat, num) => MapEntry(stat, int.tryParse(num.toString()) ?? 0)),
            ),
          ) ??
          {},
    );
  }
}