import 'dart:math';

import 'package:BasketballManager/gameData/player.dart';
import 'package:BasketballManager/gameData/team_class.dart';

class Conference {
  String name;
  List<Team> teams;
  List<Map<String, dynamic>> schedule = [];
  int matchday = 1; // Start with matchday 1

  Conference({required this.name})
      : teams = List.generate(8, (i) {
          // Create 8 teams (Team A to Team H)
          return Team(
            name: 'Team ${String.fromCharCode(65 + i)}', // Team A, Team B, ..., Team H
            reputation: Random().nextInt(100), // Random reputation between 0-100
            playerCount: 15, // Each team has 5 players
            teamSize: 15, // Fixed size of 5 players
            players: List.generate(15, (index) {
              // Generate 5 players for each team
              return Player(
                name: 'Player ${String.fromCharCode(65 + i)}-${index + 1}', // Player names like Player A-1, Player A-2...
                age: Random().nextInt(10) + 20, // Random age between 20-30
                team: 'Team ${String.fromCharCode(65 + i)}', // Team name
                experienceYears: Random().nextInt(5) + 1, // Random experience between 1-5 years
                nationality: ['USA', 'Canada', 'Spain', 'France', 'Australia'][Random().nextInt(5)], // Random nationality
                currentStatus: ['Active', 'Injured', 'Suspended'][0], // Random status
                height: Random().nextInt(30) + 170, // Random height between 170-200 cm
                shooting: 5 + Random().nextInt(15), // Random shooting skill between 0-100
                rebounding: 3 + Random().nextInt(18), // Random rebounding skill between 0-100
                passing: 5 + Random().nextInt(15), // Random passing skill between 0-100
                ballHandling: 5 + Random().nextInt(15),
                perimeterDefense: 5 + Random().nextInt(15),
                postDefense: 5 + Random().nextInt(15),
                insideShooting: 5 + Random().nextInt(15),
                performances: {},
              );
            }) ,
          ) ;
        }) {
    // Automatically generate the schedule upon initialization of the conference
    generateSchedule();
  }

  Conference.custom({required this.name, required this.teams});

  String get getName => name;
  List<Team> get getTeams => teams;
  int get getMatchday => matchday;  // Getter for matchday

  Team getTeam(String name) {
    try {
      return teams.firstWhere((team) {
        return team.name == name;
      });
    } catch (e) {
      throw ArgumentError('Team "$name" not found in conference "${this.name}". Available teams: ${teams.map((t) => t.name).join(', ')}');
    }
  }

  Map<String, dynamic> getMatch(String homeTeam, int matchday) {
    try {
      return schedule.firstWhere((game) {
        return game['home'] == homeTeam && game['matchday'] == matchday;
      });
    } catch (e) {
      throw ArgumentError('Match not found for home team "$homeTeam" on matchday $matchday');
    }
  }
  // Method to get the schedule for a specific team
  List<Map<String, dynamic>> getScheduleForTeam(String teamName) {
    // Filter the games where the team is either the home or away team
    return schedule.where((game) {
      return game['home'] == teamName || game['away'] == teamName;
    }).toList();
  }

  

  // Generate a round robin schedule where each team plays against every other team
  void generateSchedule() {
  matchday = 1;
  schedule.clear();  // Clear any existing schedule

  int totalTeams = teams.length;
  int totalMatchdays = totalTeams - 1; // Max number of matchdays = teams - 1
  List<bool> teamsScheduled = List.generate(totalTeams, (_) => false); // To track if a team is already scheduled on the matchday
  
  // Clear player performances
  for (var team in teams) {
    team.clearTeamPerformances();
  }

  // Loop over each matchday
  for (int currMatchday = 0; currMatchday < totalMatchdays; currMatchday++) {
    // Reset the scheduled teams for each matchday
    teamsScheduled.fillRange(0, totalTeams, false);
    
    // Loop through teams to generate matches for this matchday
    for (int i = 0; i < totalTeams; i++) {
      // Skip if this team is already scheduled for the current matchday
      
      if (teamsScheduled[i]) continue;

      // Find a team to pair with for the match (i.e., the away team)
      for (int j = i + 1 + currMatchday; j < i + totalTeams; j++) {
        int index = j % totalTeams;
        if (!teamsScheduled[index]) {
          // Create a match for this matchday
          schedule.add({
            'home': teams[i].name,
            'away': teams[index].name,
            'homeScore': 0, // Placeholder for scores
            'awayScore': 0, // Placeholder for scores
            'matchday': currMatchday + 1, // Matchday starts from 1
          });

          // Mark both teams as scheduled for this matchday
          teamsScheduled[i] = true;
          teamsScheduled[index] = true;
          break;  // Break to the next team after pairing
        }
      }
    }

    for (int i = 0; i < teams.length; i++) { // Resets the wins of each team.
      teams[i].losses = 0;
      teams[i].wins = 0;
    }
  }

}


  // Function to simulate playing the next matchday
  void playNextMatchday() {
    // Get all the games for the current matchday
    List<Map<String, dynamic>> currentMatchdayGames = schedule
        .where((game) => game['matchday'] == matchday) // Find games that are played on this day
        .toList();

    if (currentMatchdayGames.isEmpty) {
      print('No more games to play.');
      return;
    }

    print('Playing matchday $matchday');

    // Simulate the results of the games
    for (var game in currentMatchdayGames) {
      // Find home team with error handling
      Team? homeTeamNullable;
      try {
        homeTeamNullable = teams.firstWhere((team) => team.name == game['home']);
      } catch (e) {
        print('Error: Could not find home team "${game['home']}" in teams list');
        print('Available teams: ${teams.map((t) => t.name).join(', ')}');
        continue; // Skip this game
      }
      
      // Find away team with error handling
      Team? awayTeamNullable;
      try {
        awayTeamNullable = teams.firstWhere((team) => team.name == game['away']);
      } catch (e) {
        print('Error: Could not find away team "${game['away']}" in teams list');
        print('Available teams: ${teams.map((t) => t.name).join(', ')}');
        continue; // Skip this game
      }
      
      // At this point, both teams are guaranteed to be non-null
      final Team homeTeam = homeTeamNullable;
      final Team awayTeam = awayTeamNullable;
      

      // Simulate scores
      int homeScore = 0;
      int awayScore = 0;

      int possessions = 180 + Random().nextInt(40); // Determines the total number of possessions
      bool teamPossession = Random().nextBool(); // Which team starts with possession
      List<List<int>> boxScore = List.generate(
        homeTeam.teamSize + awayTeam.teamSize, 
        (_) => List<int>.filled(7, 0)  // Creates a new List<int> of size 7 filled with 0 for each player
      );



   for (int i = 0; i < possessions; i++) {
      if (teamPossession) {
        // Home team possession
        int playerIndex = Random().nextInt(homeTeam.teamSize); // Get a random player from home team
        Player player = homeTeam.players[playerIndex]; // Get the player
        int shotType = Random().nextInt(3); // Random shot type (0 -> inside, 1 -> midrange, 2 -> 3pt)
        int shotQuality = Random().nextInt(100); // Quality of the shot
        
        // Determine shot success based on quality and shooting ability
        switch (shotType) {
          case 0: // Inside shot
            if (shotQuality >= (100 - (30 + player.insideShooting * 2))) {

              homeScore += 2;
              boxScore[playerIndex][0] += 2; // Points


              boxScore[playerIndex][3] += 1; // Shots Made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[playerIndex][4] += 1; // Shots Attempted

          case 1: // Midrange shot
            if (shotQuality >= (100 - (25 + player.shooting * 2))) {
              homeScore += 2;
              boxScore[playerIndex][0] += 2; // Points


              boxScore[playerIndex][3] += 1; // Shots Made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[playerIndex][4] += 1; // Shots Attempted

          case 2: // 3PT shot
            if (shotQuality >= (100 - (25 + player.shooting))) {
              homeScore += 3;
              boxScore[playerIndex][0] += 3; // Points
              boxScore[playerIndex][3] += 1; // Shots Made
              boxScore[playerIndex][5] += 1; // 3pt shots made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[playerIndex][4] += 1; // Shots Attempted
            boxScore[playerIndex][6] += 1; // 3pt shots attempted
        }
        
        // Rebound attempt
        if (teamPossession) {
          playerIndex = Random().nextInt(homeTeam.teamSize); // Get random player from home team for rebound
          player = homeTeam.players[playerIndex];
          int reboundQuality = Random().nextInt(100); // Quality of rebound
          if (reboundQuality >= (100 - (player.rebounding * 1))) {
            boxScore[playerIndex][1] += 1; // Increment rebound for the player
          } else {
            // If the home team player misses the rebound, the away team gets it
            int awayPlayerIndex = Random().nextInt(awayTeam.teamSize);
            boxScore[homeTeam.teamSize + awayPlayerIndex][1] += 1; // Away team gets the rebound
            teamPossession = !teamPossession;
          }
        }
        
      } else {
        // Away team possession
        int playerIndex = Random().nextInt(awayTeam.teamSize); // Get a random player from away team
        Player player = awayTeam.players[playerIndex]; // Get the player
        int shotType = Random().nextInt(3); // Random shot type (0 -> inside, 1 -> midrange, 2 -> 3pt)
        int shotQuality = Random().nextInt(100); // Quality of the shot
        
        // Determine shot success based on quality and shooting ability
        switch (shotType) {
          case 0: // Inside shot
            if (shotQuality >= (100 - (30 + player.insideShooting * 2))) {
              awayScore += 2;
              boxScore[homeTeam.teamSize + playerIndex][0] += 2; // Points
              boxScore[homeTeam.teamSize + playerIndex][3] += 1; // Shots Made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[homeTeam.teamSize + playerIndex][4] += 1; // Shots Attempted

          case 1: // Midrange shot
            if (shotQuality >= (100 - (25 + player.shooting * 2))) {
              awayScore += 2;
              boxScore[homeTeam.teamSize + playerIndex][0] += 2; // Points
              boxScore[homeTeam.teamSize + playerIndex][3] += 1; // Shots Made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[homeTeam.teamSize + playerIndex][4] += 1; // Shots Attempted

          case 2: // 3PT shot
            if (shotQuality >= (100 - (25 + player.shooting))) {
              awayScore += 3;
              boxScore[homeTeam.teamSize + playerIndex][0] += 3; // Points
              boxScore[homeTeam.teamSize + playerIndex][3] += 1; // Shots Made
              boxScore[homeTeam.teamSize + playerIndex][5] += 1; // 3pt shots made
              teamPossession = !teamPossession; // Switch possession
            }
            boxScore[homeTeam.teamSize + playerIndex][4] += 1; // Shots Attempted
            boxScore[homeTeam.teamSize + playerIndex][6] += 1; // 3pt shots attempted
        }
        
        // Rebound attempt
        if (!teamPossession) {
          playerIndex = Random().nextInt(awayTeam.teamSize); // Get random player from away team for rebound
          player = awayTeam.players[playerIndex];
          int reboundQuality = Random().nextInt(100); // Quality of rebound
          if (reboundQuality >= (100 - (player.rebounding * 1))) {
            boxScore[homeTeam.teamSize + playerIndex][1] += 1; // Increment rebound for the away player
          } else {
            // If the away team player misses the rebound, the home team gets it
            int homePlayerIndex = Random().nextInt(homeTeam.teamSize);
            boxScore[homePlayerIndex][1] += 1; // Home team gets the rebound
            teamPossession = !teamPossession;
          }
        }
        
      }
    }

    // Recording the performances
    for (int i = 0; i < homeTeam.teamSize; i++) {
      homeTeam.players[i].recordPerformance(matchday, boxScore[i]);
    }
    for (int i = homeTeam.teamSize; i < boxScore.length; i++) {
      awayTeam.players[i - homeTeam.teamSize].recordPerformance(matchday, boxScore[i]);
    }


      // // Update the game scores in the schedule
      game['homeScore'] = homeScore;
      game['awayScore'] = awayScore;

      // Find the teams involved
      

      // Update the win/loss record for each team
      if (homeScore > awayScore) {
        homeTeam.updateRecord(true);  // Home team wins
        awayTeam.updateRecord(false); // Away team loses
      } else if (homeScore < awayScore) {
        homeTeam.updateRecord(false); // Home team loses
        awayTeam.updateRecord(true);  // Away team wins
      } else {
        // In case of a draw, no wins or losses are updated
      }
    }

    // After playing the current matchday, increment the matchday
    matchday++;
  }

  // Convert the conference object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'teams': teams.map((team) => team.toMap()).toList(),
      'matchday': matchday.toString(),
      'schedule': schedule.map((game) => {
          'home': game['home'],
          'away': game['away'],
          'homeScore': game['homeScore'].toString(),
          'awayScore': game['awayScore'].toString(),
          'matchday': game['matchday'].toString(),
      }).toList(),

    };
  }

  // Factory constructor to create a Conference instance from a map (for Firestore)
  factory Conference.fromMap(Map<String, dynamic> map) {
    // Recreate the teams list from the map
    List<Team> teams = List<Team>.from(
      map['teams'].map((teamMap) => Team.fromMap(teamMap)),
    );

    // Create a new Conference object
    Conference conference = Conference.custom(
      name: map['name'],
      teams: teams,
    );

    // Recreate the schedule from the map
    conference.matchday = int.tryParse(map['matchday'].toString()) ?? 1;
    conference.schedule = List<Map<String, dynamic>>.from(
      map['schedule']?.map((game) => {
        'home': game['home'],
        'away': game['away'],
        'homeScore': int.tryParse(game['homeScore'].toString()) ?? 0,
        'awayScore': int.tryParse(game['awayScore'].toString()) ?? 0,
        'matchday': int.tryParse(game['matchday'].toString()) ?? 1,
      }) ?? []
    );


    // Call generateSchedule() to ensure the schedule is populated in case Firebase didn't provide it
    if (conference.schedule.isEmpty) {
      conference.generateSchedule();
    } else {
      // Check if schedule team names match current team names
      final currentTeamNames = conference.teams.map((team) => team.name).toSet();
      bool mismatch = false;
      
      // Check a few games from the schedule to see if team names exist
      for (final game in conference.schedule.take(5)) {
        final homeName = game['home'] as String?;
        final awayName = game['away'] as String?;
        
        if (homeName != null && !currentTeamNames.contains(homeName)) {
          mismatch = true;
          break;
        }
        if (awayName != null && !currentTeamNames.contains(awayName)) {
          mismatch = true;
          break;
        }
      }
      
      if (mismatch) {
        print('Schedule team names don\'t match current teams. Regenerating schedule...');
        conference.generateSchedule();
      }
    }

    return conference;
  }
}
