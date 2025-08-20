import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/coach_class.dart';
import 'package:BasketballManager/gameData/conference_class.dart';
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

  // Method to save profile and create game, manager, and conference
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Create a Conference with 8 teams
      Conference conference = Conference(name: 'Eastern Conference');
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

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manager Profile and Game Saved')),
        );

        // Navigate to the next page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return WidgetTree(game: game,); 
            }
          )
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
