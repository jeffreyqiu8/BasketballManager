import 'package:test1/gameData/player_class.dart';

class Team {
  // General attributes
  String name;
  int reputation;
  int playerCount;
  int teamSize;

  int wins;
  int losses;

  List<Player> players;

  Team({
    required this.name,
    required this.reputation,
    required this.playerCount,
    required this.teamSize,
    required this.players,
    this.wins = 0,  // Default wins to 0
    this.losses = 0,  // Default losses to 0
  });


  // Method to add a player to the team
  void addPlayer(Player player) {
    if (playerCount < teamSize) {
      players.add(player);
      playerCount++;
    } else {
      print('Team is full. Cannot add more players.');
    }
  }

  void clearTeamPerformances() {
    for (var player in players) {
      player.performances.clear();  // Call the clearPerformances method for each player
    }
    print('All player performances have been cleared.');
  }
  // Method to update wins and losses after a game
  void updateRecord(bool isWin) {
    if (isWin) {
      wins++;
    } else {
      losses++;
    }
  }

  // Method to reset the team’s record at the start of a new season (optional)
  void resetRecord() {
    wins = 0;
    losses = 0;
  }

  // Convert the team object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reputation': reputation,
      'playerCount': playerCount,
      'teamSize': teamSize,
      'wins': wins,
      'losses': losses,
      'players': players.map((player) => player.toMap()).toList(),
    };
  }

  // Factory constructor to create a Team instance from a map (for Firestore)
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      name: map['name'],
      reputation: map['reputation'],
      playerCount: map['playerCount'],
      teamSize: map['teamSize'],
      players: List<Player>.from(
        map['players'].map((playerMap) => Player.fromMap(playerMap)),
      ),
      wins: map['wins'] ?? 0,  // Ensure wins is initialized
      losses: map['losses'] ?? 0,  // Ensure losses is initialized
    );
  }
}
