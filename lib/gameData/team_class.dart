import 'package:BasketballManager/gameData/player_class.dart';

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
      player.performances.clear();// Call the clearPerformances method for each player
      player.gamesPlayed = 0;  
    }
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

  // Convert the team object to a map for Firestore (store numbers as strings)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reputation': reputation.toString(),  // Convert int to String
      'playerCount': playerCount.toString(),
      'teamSize': teamSize.toString(),
      'wins': wins.toString(),
      'losses': losses.toString(),
      'players': players.map((player) => player.toMap()).toList(),
    };
  }

  // Factory constructor to create a Team instance from a map (convert strings back to int)
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      name: map['name'] ?? 'Unknown Team',
      reputation: int.tryParse(map['reputation'].toString()) ?? 0,
      playerCount: int.tryParse(map['playerCount'].toString()) ?? 0,
      teamSize: int.tryParse(map['teamSize'].toString()) ?? 5,
      wins: int.tryParse(map['wins'].toString()) ?? 0,
      losses: int.tryParse(map['losses'].toString()) ?? 0,
      players: List<Player>.from(
        (map['players'] ?? []).map((playerMap) => Player.fromMap(playerMap)),
      ),
    );
  }
}
