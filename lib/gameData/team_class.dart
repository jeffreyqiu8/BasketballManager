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
  List<Player> starters; // 🆕 New attribute for starters

  Team({
    required this.name,
    required this.reputation,
    required this.playerCount,
    required this.teamSize,
    required this.players,
    this.wins = 0,
    this.losses = 0,
    List<Player>? starters, // Optional parameter
  }) : starters = starters ?? players.take(5).toList(); // Default first 5 players as starters if not specified

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
      player.performances.clear();
      player.gamesPlayed = 0;
    }
  }

  void updateRecord(bool isWin) {
    if (isWin) {
      wins++;
    } else {
      losses++;
    }
  }

    

  void resetRecord() {
    wins = 0;
    losses = 0;
  }


  // Method to set the team's starters
  void setStarters(List<Player> newStarters) {
    // Ensure all new starters are part of the team
    final validStarters = newStarters.where((p) => players.contains(p)).toList();

    if (validStarters.length != newStarters.length) {
      print("Some players in starters are not on the team. Ignoring invalid entries.");
    }

    if (validStarters.length > teamSize) {
      print("Too many starters provided. Limiting to team size.");
      starters = validStarters.take(teamSize).toList();
    } else {
      starters = validStarters;
    }
  }
  // 🔄 Serialize the team to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reputation': reputation.toString(),
      'playerCount': playerCount.toString(),
      'teamSize': teamSize.toString(),
      'wins': wins.toString(),
      'losses': losses.toString(),
      'players': players.map((player) => player.toMap()).toList(),
      'starters': starters.map((player) => player.toMap()).toList(), // 🆕 Add starters
    };
  }

  // 🏗️ Factory constructor to create from a Map
  factory Team.fromMap(Map<String, dynamic> map) {
    List<Player> allPlayers = List<Player>.from(
      (map['players'] ?? []).map((playerMap) => Player.fromMap(playerMap)),
    );

    List<Player> startersFromMap = [];
    if (map['starters'] != null) {
      startersFromMap = List<Player>.from(
        (map['starters'] as List).map((p) => Player.fromMap(p)),
      );
    } else {
      startersFromMap = allPlayers.take(5).toList();
    }

    return Team(
      name: map['name'] ?? 'Unknown Team',
      reputation: int.tryParse(map['reputation'].toString()) ?? 0,
      playerCount: int.tryParse(map['playerCount'].toString()) ?? 0,
      teamSize: int.tryParse(map['teamSize'].toString()) ?? 5,
      wins: int.tryParse(map['wins'].toString()) ?? 0,
      losses: int.tryParse(map['losses'].toString()) ?? 0,
      players: allPlayers,
      starters: startersFromMap,
    );
  }
}
