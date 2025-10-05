import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/views/widget_tree.dart';
import 'package:BasketballManager/views/pages/manager_creation_page.dart';

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

  // Refresh the game files when returning to this page
  void _refreshGameFiles() {
    setState(() {
      _isLoading = true;
    });
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
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManagerProfilePage()),
              );
              // Refresh the list when returning from manager creation
              _refreshGameFiles();
            },
            icon: Icon(Icons.add),
            tooltip: 'Create New Save',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while data is being fetched
          : Column(
              children: [
                // Create New Save Button (when no saves exist)
                if (_gameFiles.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_basketball,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No game profiles found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first manager profile to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ManagerProfilePage()),
                              );
                              // Refresh the list when returning from manager creation
                              _refreshGameFiles();
                            },
                            icon: Icon(Icons.add),
                            label: Text('Create New Save'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Existing saves list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _gameFiles.length,
                      itemBuilder: (context, index) {
                        final Game game= _gameFiles[index];
                        return ListTile(
                          title: Text(game.currentManager.name),
                          subtitle: Text('${game.currentManager.team} | ${game.currentManager.experienceYears} years experience'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushReplacement(
                               context,
                               MaterialPageRoute(builder: (context) => WidgetTree(game: game,)),
                            );
                          },
                        );
                      },
                    ),
                  ),
                
                // Create New Save Button (when saves exist)
                if (_gameFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ManagerProfilePage()),
                          );
                          // Refresh the list when returning from manager creation
                          _refreshGameFiles();
                        },
                        icon: Icon(Icons.add),
                        label: Text('Create New Save'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}