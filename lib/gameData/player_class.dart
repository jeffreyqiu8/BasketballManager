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
  int ballHandling;
  int perimeterDefense;
  int postDefense;
  int insideShooting;

  // Performance tracking per matchday
  Map<int, Map<String, int>> performances;

  // Season Totals
  int points;
  int rebounds;
  int assists;
  int gamesPlayed;

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
    required this.ballHandling,
    required this.perimeterDefense,
    required this.postDefense,
    required this.insideShooting,
    required this.performances,
    this.points = 0,
    this.rebounds = 0,
    this.assists = 0,
    this.gamesPlayed = 0, 
  });


  // Display player info
  String displayInfo() {
    return 'Player: $name\nAge: $age\nTeam: $team\nExperience: $experienceYears years\nNationality: $nationality\nStatus: $currentStatus';
  }

  void updateTeam(String newTeam) {
    team = newTeam;
  }

  void updateStatus(String newStatus) {
    currentStatus = newStatus;
  }

  void addExperience(int years) {
    experienceYears += years;
  }

  void retire() {
    currentStatus = 'Retired';
  }

  // Record matchday performance
  void recordPerformance(int matchday, List<int> stats) {
    // Only increment gamesPlayed if this matchday wasn't already recorded
    if (!performances.containsKey(matchday)) {
      gamesPlayed++;
    }

    performances[matchday] = {
      'points': stats[0],
      'rebounds': stats[1],
      'assists': stats[2],
      'FGM': stats[3],
      'FGA': stats[4],
      '3PM': stats[5],
      '3PA': stats[6],
      'FG%': stats[4] > 0 ? ((stats[3] / stats[4]) * 100).round() : 0,
      '3PT%': stats[6] > 0 ? ((stats[5] / stats[6]) * 100).round() : 0,
    };

    updateSeasonTotals();
  }

  Map<String, int>? getPerformance(int matchday) {
    return performances[matchday];
  }

  void updateSeasonTotals() {
    points = 0;
    rebounds = 0;
    assists = 0;

    for (var game in performances.values) {
      points += game['points'] ?? 0;
      rebounds += game['rebounds'] ?? 0;
      assists += game['assists'] ?? 0;
    }
  }

  // toMap
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
      'points': points.toString(),
      'rebounds': rebounds.toString(),
      'assists': assists.toString(),
      'gamesPlayed': gamesPlayed.toString(), // 👈 include in map
      'performances': performances.map(
        (key, value) => MapEntry(
          key.toString(),
          value.map((stat, num) => MapEntry(stat, num.toString())),
        ),
      ),
    };
  }

  // fromMap
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
      points: int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      rebounds: int.tryParse(map['rebounds']?.toString() ?? '0') ?? 0,
      assists: int.tryParse(map['assists']?.toString() ?? '0') ?? 0,
      gamesPlayed: int.tryParse(map['gamesPlayed']?.toString() ?? '0') ?? 0, // 👈 load it
      performances: (map['performances'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              int.tryParse(key) ?? 0,
              (value as Map<String, dynamic>).map(
                (stat, num) => MapEntry(stat, int.tryParse(num.toString()) ?? 0),
              ),
            ),
          ) ??
          {},
    );
  }
}
