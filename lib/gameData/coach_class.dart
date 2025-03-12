

class Manager {
  // Manager attributes
  String name;
  int age;
  int team;
  int experienceYears;
  String nationality;
  String currentStatus;
  
  // Constructor
  Manager({
    required this.name,
    required this.age,
    required this.team,
    required this.experienceYears,
    required this.nationality,
    required this.currentStatus,
  });



  // Method to display manager's details
  String displayInfo() {
    return 'Manager: $name\nAge: $age\nTeam: $team\nExperience: $experienceYears years\nNationality: $nationality\nStatus: $currentStatus';
  }

  // Method to update team
  void updateTeam(int newTeam) {
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

  // Method to retire the manager
  void retire() {
    currentStatus = 'Retired';
  }

  // Method to return the manager's current attributes as a map (useful for saving to a database, like Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'team': team,
      'experienceYears': experienceYears,
      'nationality': nationality,
      'currentStatus': currentStatus,
    };
  }

  // Factory method to create a Manager from a Map (useful when reading from a database)
  factory Manager.fromMap(Map<String, dynamic> map) {
    return Manager(
      name: map['name'] as String? ?? 'Unknown',
      age: map['age'] as int? ?? 0, // Ensure this is cast to int
      team: map['team'] as int? ?? 0,
      experienceYears: map['experienceYears'] as int? ?? 0,
      nationality: map['nationality'] as String? ?? 'Unknown',
      currentStatus: map['currentStatus'] as String? ?? 'Unknown',
    );
  }
}
