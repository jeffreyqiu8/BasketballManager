import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_class.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveGame(Game game, String userId) async {
    try {
      await _firestore
            .collection('users') // User's document
            .doc(userId) // Document using userId
            .collection('gameFiles') // Subcollection for game data
            .add(game.toMap());
      print('Game saved successfully!');
    } catch (e) {
      print('Error saving game: $e');
    }
  }

  
}
