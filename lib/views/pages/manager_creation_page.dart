import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/coach_class.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/nba_conference_service.dart';
import 'package:BasketballManager/gameData/team_generation_service.dart';
import 'package:BasketballManager/gameData/nba_team_data.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/player_class.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/views/widget_tree.dart';

class ManagerProfilePage extends StatefulWidget {
  const ManagerProfilePage({super.key});

  @override
  _ManagerProfilePageState createState() => _ManagerProfilePageState();
}

class _ManagerProfilePageState extends State<ManagerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dropdown value for team selection (1 to 8)
  int _selectedTeam = 1;

  // List of available teams for selection (Team 1 to Team 8)
  List<String> teamNames = List.generate(8, (index) => 'Team ${index + 1}');

  // Method to populate teams with players
  void _populateTeamsWithPlayers(EnhancedConference conference) {
    final nbaTeams = RealTeamData.getAllNBATeams();
    
    for (int i = 0; i < conference.teams.length && i < nbaTeams.length; i++) {
      final team = conference.teams[i];
      final nbaTeam = nbaTeams[i];
      
      if (team is EnhancedTeam && team.players.isEmpty) {
        try {
          // Generate a roster for this team
          final generatedTeam = TeamGenerationService.generateNBATeamRoster(nbaTeam);
          team.players = generatedTeam.players;
          team.playerCount = generatedTeam.players.length;
        } catch (e) {
          // If generation fails, create a simple roster
          team.players = _createSimpleRoster(team.name);
          team.playerCount = team.players.length;
        }
      }
    }
  }

  // Fallback method to create a simple roster if generation fails
  List<Player> _createSimpleRoster(String teamName) {
    List<Player> players = [];
    List<String> nationalities = ['USA', 'Canada', 'Spain', 'France', 'Germany'];
    
    for (int i = 0; i < 15; i++) {
      players.add(Player(
        name: 'Player ${i + 1}',
        age: 22 + (i % 10),
        team: teamName,
        experienceYears: i % 8,
        nationality: nationalities[i % nationalities.length],
        currentStatus: 'Active',
        height: 180 + (i % 20),
        shooting: 50 + (i % 30),
        rebounding: 50 + (i % 30),
        passing: 50 + (i % 30),
        ballHandling: 50 + (i % 30),
        perimeterDefense: 50 + (i % 30),
        postDefense: 50 + (i % 30),
        insideShooting: 50 + (i % 30),
        performances: {},
      ));
    }
    
    return players;
  }

  // Method to save profile and create game, manager, and conference
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Generate NBA conferences with enhanced features
      final conferences = NBAConferenceService.createNBAConferences();
      EnhancedConference conference = conferences['Eastern']!;
      
      // Populate teams with players
      _populateTeamsWithPlayers(conference);
      
      final manager = Manager(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        team: _selectedTeam - 1,
        experienceYears: int.parse(_experienceController.text),
        nationality: _nationalityController.text,
        currentStatus: _statusController.text,
      );
      // Create a Game object
      Game game = Game(currentManager: manager, currentConference: conference);
      // Create a Manager object with the form data
      
      
      try {
        // Get the current authenticated user's UID
        User user = _auth.currentUser!;
        String userId = user.uid;


        // Save the Game object to the 'gameFiles' collection
        await _firestore
            .collection('users') // User's document
            .doc(userId) // Document using userId
            .collection('gameFiles') // Subcollection for game data
            .doc(game.currentManager.name)
            .set(game.toMap());

        // Show success message and ask user what to do next
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Save Created Successfully!'),
              content: Text('Your manager profile "${game.currentManager.name}" has been saved. What would you like to do?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context); // Go back to saves list
                  },
                  child: Text('View Saves'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WidgetTree(game: game),
                      ),
                    );
                  },
                  child: Text('Start Playing'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<int>(
                value: _selectedTeam,
                onChanged: (newValue) {
                  setState(() {
                    _selectedTeam = newValue!;
                  });
                },
                items: List.generate(8, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('Team ${index + 1}'),
                  );
                }),
                decoration: const InputDecoration(labelText: 'Select Team'),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a team';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Experience (in years)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the experience in years';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(labelText: 'Nationality'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the nationality';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Current Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the current status';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
