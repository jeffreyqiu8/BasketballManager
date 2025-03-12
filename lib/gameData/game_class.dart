import 'package:test1/gameData/coach_class.dart';
import 'package:test1/gameData/conference_class.dart';

class Game {
  Manager currentManager;
  Conference currentConference;

  
  Game({required this.currentManager, required this.currentConference});
  
  Manager get getCurrentManager => currentManager;
  Conference get getCurrentConference => currentConference;

  // Convert the Game to a Map for storage (e.g., Firebase)
  Map<String, dynamic> toMap() {
    return {
      'currentManager': currentManager.toMap(),
      'currentConference': currentConference.toMap(),
    };
  }

  // Convert a Map back into a Game object (e.g., after retrieving from Firebase)
  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      currentManager: Manager.fromMap(map['currentManager']  as Map<String, dynamic>),
      currentConference: Conference.fromMap(map['currentConference'] as Map<String, dynamic>),
    );
  }
}
