import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/views/pages/welcome_page.dart';
import 'package:BasketballManager/views/widget_tree.dart';

class LoadingManagerProfilesPage extends StatefulWidget {
  const LoadingManagerProfilesPage({super.key});

  @override
  _LoadingManagerProfilesPageState createState() => _LoadingManagerProfilesPageState();
}

class _LoadingManagerProfilesPageState extends State<LoadingManagerProfilesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  bool _isLoading = true;
  List<Game> _gameFiles = [];

  @override
  void initState() {
    super.initState();
    _loadGameFiles();
  }

  // Load the manager profiles from Firestore
  Future<void> _loadGameFiles() async {
    _user = _auth.currentUser!;

    try {
      // Get the manager profiles stored in the Firestore database for the current user
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(_user.uid).get();

      // Assuming manager profiles are stored in a subcollection under 'gameFiles'
      QuerySnapshot profileSnapshot = await userSnapshot.reference.collection('gameFiles').get();

      // Map the data to the Manager class
      setState(() {
        _gameFiles = profileSnapshot.docs.map((doc) {
          return Game.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profiles: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Profiles'),
        leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return WelcomePage();
                    }
                  )
                );
            },
            icon:Icon(Icons.arrow_back),
          ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while data is being fetched
          : _gameFiles.isEmpty
              ? Center(child: Text('No game profiles found.'))  // Show message if no profiles are found
              : ListView.builder(
                  itemCount: _gameFiles.length,
                  itemBuilder: (context, index) {
                    final Game game= _gameFiles[index];
                    return ListTile(
                      title: Text(game.currentManager.name),
                      subtitle: Text('${game.currentManager.team} | ${game.currentManager.experienceYears} years experience'),
                      onTap: () {
                        Navigator.pushReplacement(
                           context,
                           MaterialPageRoute(builder: (context) => WidgetTree(game: game,)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}