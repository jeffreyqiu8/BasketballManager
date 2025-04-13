import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/gameData/game_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BasketballManager/data/notifiers.dart';
import 'package:BasketballManager/views/pages/welcome_page.dart';


class ProfilePage extends StatefulWidget {
  final Game game;  // This is the object the widget will accept
  
  const ProfilePage({super.key, required this.game});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}



class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GameService _gameService = GameService();

  Future<void> saveGameProgress(Game currentGame, String userId) async {
    await _gameService.saveGame(currentGame, userId);
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          
          ListTile(
            title: Text('Logout'),
            onTap: () async{
              User? user = _auth.currentUser;

                if (user != null) {
                  String userId = user.uid;

                  // Wait for save operation to complete before navigating
                  await saveGameProgress(widget.game, userId);
                }

                selectedPageNotifier.value = 0;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WelcomePage(),
                  ),
                );
            }
          )
        ],
      )
    );
  }
}