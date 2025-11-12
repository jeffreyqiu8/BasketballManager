import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/player.dart';

/// Service for generating random players with realistic stats and names
class PlayerGenerator {
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  // Lists for random name generation
  static const List<String> _firstNames = [
    'James', 'Michael', 'Kobe', 'LeBron', 'Stephen', 'Kevin', 'Chris',
    'Anthony', 'Dwyane', 'Russell', 'Kawhi', 'Paul', 'Damian', 'Kyrie',
    'Jimmy', 'Joel', 'Giannis', 'Luka', 'Jayson', 'Devin', 'Trae',
    'Donovan', 'Zion', 'Ja', 'Brandon', 'Nikola', 'Karl', 'Rudy',
    'Ben', 'Khris', 'Jrue', 'CJ', 'Bradley', 'Pascal', 'Fred',
    'Marcus', 'Julius', 'Tobias', 'DeMar', 'Kyle', 'Kemba', 'Victor',
    'Kristaps', 'Jamal', 'Shai', 'De\'Aaron', 'Bam', 'Domantas', 'Malcolm'
  ];

  static const List<String> _lastNames = [
    'Johnson', 'Jordan', 'Bryant', 'James', 'Curry', 'Durant', 'Paul',
    'Davis', 'Wade', 'Westbrook', 'Leonard', 'George', 'Lillard', 'Irving',
    'Butler', 'Embiid', 'Antetokounmpo', 'Doncic', 'Tatum', 'Booker', 'Young',
    'Mitchell', 'Williamson', 'Morant', 'Ingram', 'Jokic', 'Towns', 'Gobert',
    'Simmons', 'Middleton', 'Holiday', 'McCollum', 'Beal', 'Siakam', 'VanVleet',
    'Smart', 'Randle', 'Harris', 'DeRozan', 'Lowry', 'Walker', 'Oladipo',
    'Porzingis', 'Murray', 'Gilgeous-Alexander', 'Fox', 'Adebayo', 'Sabonis', 'Brogdon'
  ];

  /// Generates a single player with random stats and name
  Player generatePlayer({String? name}) {
    return Player(
      id: _uuid.v4(),
      name: name ?? _generateRandomName(),
      shooting: _generateStat(),
      defense: _generateStat(),
      speed: _generateStat(),
      stamina: _generateStat(),
      passing: _generateStat(),
      rebounding: _generateStat(),
      ballHandling: _generateStat(),
      threePoint: _generateStat(),
    );
  }

  /// Generates a list of players for a team roster
  /// [count] specifies how many players to generate (default: 15)
  List<Player> generateTeamRoster(int count) {
    return List.generate(count, (_) => generatePlayer());
  }

  /// Generates a random player name by combining first and last names
  String _generateRandomName() {
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    return '$firstName $lastName';
  }

  /// Generates a random stat value in the range 0-100
  int _generateStat() {
    return _random.nextInt(101); // 0 to 100 inclusive
  }
}
