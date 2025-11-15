import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/player.dart';

/// Service for generating random players with realistic stats and names
class PlayerGenerator {
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  // Lists for random name generation - diverse names from various eras and backgrounds
  static const List<String> _firstNames = [
    // Modern Era Stars
    'James', 'Michael', 'Kobe', 'LeBron', 'Stephen', 'Kevin', 'Chris', 'Anthony',
    'Dwyane', 'Russell', 'Kawhi', 'Paul', 'Damian', 'Kyrie', 'Jimmy', 'Joel',
    'Giannis', 'Luka', 'Jayson', 'Devin', 'Trae', 'Donovan', 'Zion', 'Ja',
    'Brandon', 'Nikola', 'Karl', 'Rudy', 'Ben', 'Khris', 'Jrue', 'CJ',
    'Bradley', 'Pascal', 'Fred', 'Marcus', 'Julius', 'Tobias', 'DeMar', 'Kyle',
    'Kemba', 'Victor', 'Kristaps', 'Jamal', 'Shai', 'De\'Aaron', 'Bam', 'Domantas',
    'Malcolm', 'Tyrese', 'Cade', 'Evan', 'Jalen', 'Scottie', 'Franz', 'Paolo',
    // Classic Era Legends
    'Magic', 'Larry', 'Kareem', 'Wilt', 'Bill', 'Oscar', 'Jerry', 'Elgin',
    'Bob', 'Rick', 'George', 'Julius', 'Moses', 'Dave', 'John', 'Clyde',
    'Walt', 'Pete', 'Nate', 'Willis', 'Earl', 'Hal', 'Sam', 'Dolph',
    // 80s-90s Era
    'Charles', 'Patrick', 'Hakeem', 'David', 'Shaquille', 'Tim', 'Allen',
    'Gary', 'Scottie', 'Dennis', 'Reggie', 'Clyde', 'Dominique', 'Isiah',
    'Joe', 'Mitch', 'Mark', 'Glen', 'Detlef', 'Alonzo', 'Dikembe',
    // 2000s Era
    'Dirk', 'Steve', 'Ray', 'Vince', 'Tracy', 'Yao', 'Pau', 'Tony',
    'Manu', 'Chauncey', 'Richard', 'Amar\'e', 'Elton', 'Baron', 'Gilbert',
    'Antawn', 'Rashard', 'Shawn', 'Jermaine', 'Peja', 'Andrei',
    // International Stars
    'Drazen', 'Arvydas', 'Toni', 'Hedo', 'Mehmet', 'Andris', 'Sarunas',
    'Vlade', 'Predrag', 'Zydrunas', 'Hidayet', 'Leandro', 'Anderson', 'Nene',
    'Marcin', 'Ricky', 'Marc', 'Serge', 'Jonas', 'Dario', 'Bogdan', 'Bojan',
    'Danilo', 'Goran', 'Nikola', 'Jusuf', 'Clint', 'Rudy', 'Emmanuel',
    // Diverse Modern Names
    'Anfernee', 'Dejounte', 'Derrick', 'Darius', 'Desmond', 'Deandre', 'Dillon',
    'Collin', 'Coby', 'Cole', 'Christian', 'Caris', 'Cameron', 'Buddy',
    'Bobby', 'Austin', 'Aaron', 'Andrew', 'Alex', 'Alec', 'Al', 'Andre',
    'Antoine', 'Avery', 'Blake', 'Brook', 'Bruce', 'Bryn', 'Caleb', 'Cam',
    'Carmelo', 'Cedi', 'Chandler', 'Channing', 'Chet', 'Chuma', 'Corey',
    'Dalen', 'Damion', 'Danny', 'Dante', 'Dario', 'Darnell', 'Darren',
    'Davion', 'Davis', 'Delon', 'Deni', 'Denzel', 'Derek', 'Derrick',
    'Devon', 'Dewayne', 'Dion', 'Dorian', 'Doug', 'Draymond', 'Drew',
    'Dwight', 'Dylan', 'Eddie', 'Edrice', 'Eric', 'Erick', 'Ernie',
    'Garrison', 'Gary', 'Grayson', 'Hamidou', 'Harrison', 'Hassan', 'Herbert',
    'Immanuel', 'Isaac', 'Isaiah', 'Ivica', 'Jabari', 'Jacob', 'Jae',
    'Jaren', 'Jarred', 'Jarrett', 'Jason', 'Javonte', 'Jaylen', 'Jeremy',
    'Jerami', 'Jerome', 'JJ', 'Joe', 'John', 'Jonathan', 'Jordan',
    'Jose', 'Josh', 'Joshua', 'Juan', 'Justin', 'Justise', 'Keon',
    'Keegan', 'Keenan', 'Kelly', 'Keldon', 'Kenneth', 'Kentavious', 'Kenyon',
    'Kessler', 'Kevon', 'Klay', 'Kris', 'Lamar', 'Lauri', 'Lonnie',
    'Lonzo', 'Lou', 'Luguentz', 'Luke', 'Malik', 'Malachi', 'Markelle',
    'Marvin', 'Mason', 'Matisse', 'Matt', 'Maurice', 'Max', 'Mikal',
    'Miles', 'Mitchell', 'Monte', 'Montrezl', 'Moritz', 'Mychal', 'Naji',
    'Nassir', 'Nathan', 'Naz', 'Nick', 'Nicolas', 'Norman', 'Onyeka',
    'OG', 'Oshae', 'Otto', 'P.J.', 'Pat', 'Patty', 'Payton', 'Precious',
    'Quentin', 'RJ', 'Rajon', 'Raul', 'Reggie', 'Ricky', 'Robert',
    'Rodney', 'Royce', 'Ryan', 'Sam', 'Sandro', 'Scoot', 'Shake',
    'Shaedon', 'Svi', 'T.J.', 'Talen', 'Tari', 'Terance', 'Terrence',
    'Terry', 'Thaddeus', 'Theo', 'Thomas', 'Tomas', 'Torrey', 'Tre',
    'Trey', 'Troy', 'Tyler', 'Tyus', 'Udoka', 'Usman', 'Vernon',
    'Walker', 'Wendell', 'Wesley', 'Will', 'Willie', 'Xavier', 'Yuta',
    'Zach', 'Ziaire',
  ];

  static const List<String> _lastNames = [
    // Modern Era Stars
    'Johnson', 'Jordan', 'Bryant', 'James', 'Curry', 'Durant', 'Paul', 'Davis',
    'Wade', 'Westbrook', 'Leonard', 'George', 'Lillard', 'Irving', 'Butler',
    'Embiid', 'Antetokounmpo', 'Doncic', 'Tatum', 'Booker', 'Young', 'Mitchell',
    'Williamson', 'Morant', 'Ingram', 'Jokic', 'Towns', 'Gobert', 'Simmons',
    'Middleton', 'Holiday', 'McCollum', 'Beal', 'Siakam', 'VanVleet', 'Smart',
    'Randle', 'Harris', 'DeRozan', 'Lowry', 'Walker', 'Oladipo', 'Porzingis',
    'Murray', 'Gilgeous-Alexander', 'Fox', 'Adebayo', 'Sabonis', 'Brogdon',
    'Haliburton', 'Cunningham', 'Mobley', 'Green', 'Barnes', 'Wagner', 'Banchero',
    // Classic Era Legends
    'Abdul-Jabbar', 'Bird', 'Chamberlain', 'Russell', 'Robertson', 'West', 'Baylor',
    'Cousy', 'Pettit', 'Havlicek', 'Mikan', 'Erving', 'Malone', 'Cowens',
    'Frazier', 'Monroe', 'Reed', 'Archibald', 'Thurmond', 'Unseld', 'Schayes',
    // 80s-90s Era
    'Barkley', 'Ewing', 'Olajuwon', 'Robinson', 'O\'Neal', 'Duncan', 'Iverson',
    'Payton', 'Pippen', 'Rodman', 'Miller', 'Drexler', 'Wilkins', 'Thomas',
    'Dumars', 'Richmond', 'Price', 'Rice', 'Schrempf', 'Mourning', 'Mutombo',
    'Stockton', 'Kemp', 'Hardaway', 'Hill', 'Mashburn', 'Webber', 'Kidd',
    // 2000s Era
    'Nowitzki', 'Nash', 'Allen', 'Carter', 'McGrady', 'Ming', 'Gasol', 'Parker',
    'Ginobili', 'Billups', 'Hamilton', 'Stoudemire', 'Brand', 'Davis', 'Arenas',
    'Jamison', 'Lewis', 'Marion', 'O\'Neal', 'Stojakovic', 'Kirilenko',
    'Pierce', 'Garnett', 'Wallace', 'Rondo', 'Howard', 'Anthony', 'Bosh',
    // International Stars
    'Petrovic', 'Sabonis', 'Kukoc', 'Turkoglu', 'Okur', 'Biedrins', 'Marciulionis',
    'Divac', 'Stojakovic', 'Ilgauskas', 'Turkcan', 'Barbosa', 'Varejao', 'Hilario',
    'Gortat', 'Rubio', 'Gasol', 'Ibaka', 'Valanciunas', 'Saric', 'Bogdanovic',
    'Gallinari', 'Dragic', 'Vucevic', 'Nurkic', 'Capela', 'Gobert', 'Mudiay',
    // Diverse Modern Names
    'Simons', 'Murray', 'White', 'Garland', 'Bane', 'Poole', 'Herro', 'Maxey',
    'Sengun', 'Giddey', 'Suggs', 'Kuminga', 'Duarte', 'Dosunmu', 'Ayo',
    'Portis', 'Horford', 'Lopez', 'Thompson', 'Williams', 'Brown', 'Jackson',
    'Robinson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Martin', 'Garcia',
    'Martinez', 'Rodriguez', 'Wilson', 'Lee', 'Lewis', 'Clark', 'Wright',
    'Hill', 'Scott', 'Adams', 'Baker', 'Nelson', 'Carter', 'Mitchell',
    'Perez', 'Roberts', 'Turner', 'Phillips', 'Campbell', 'Parker', 'Evans',
    'Edwards', 'Collins', 'Stewart', 'Morris', 'Murphy', 'Cook', 'Rogers',
    'Morgan', 'Peterson', 'Cooper', 'Reed', 'Bailey', 'Bell', 'Gomez',
    'Kelly', 'Howard', 'Ward', 'Cox', 'Diaz', 'Richardson', 'Wood',
    'Watson', 'Brooks', 'Bennett', 'Gray', 'Mendoza', 'Ruiz', 'Hughes',
    'Price', 'Alvarez', 'Castillo', 'Sanders', 'Patel', 'Myers', 'Long',
    'Ross', 'Foster', 'Jimenez', 'Powell', 'Jenkins', 'Perry', 'Russell',
    'Sullivan', 'Bell', 'Coleman', 'Butler', 'Henderson', 'Barnes', 'Gonzales',
    'Fisher', 'Vasquez', 'Simmons', 'Romero', 'Jordan', 'Patterson', 'Reynolds',
    'Hamilton', 'Graham', 'Kim', 'Gonzalez', 'Alexander', 'Ramos', 'Wallace',
    'Griffin', 'West', 'Cole', 'Hayes', 'Chavez', 'Gibson', 'Bryant',
    'Ellis', 'Stevens', 'Murray', 'Ford', 'Marshall', 'Owens', 'McDonald',
    'Harrison', 'Ruiz', 'Kennedy', 'Wells', 'Alvarez', 'Woods', 'Mendez',
    'Castillo', 'Olson', 'Webb', 'Washington', 'Tucker', 'Freeman', 'Burns',
    'Henry', 'Vasquez', 'Snyder', 'Simpson', 'Crawford', 'Jimenez', 'Porter',
    'Mason', 'Shaw', 'Gordon', 'Wagner', 'Hunter', 'Romero', 'Hicks',
    'Dixon', 'Hunt', 'Palmer', 'Robertson', 'Black', 'Holmes', 'Stone',
    'Meyer', 'Boyd', 'Mills', 'Warren', 'Fox', 'Rose', 'Rice',
    'Moreno', 'Schmidt', 'Patel', 'Ferguson', 'Nichols', 'Herrera', 'Medina',
    'Ryan', 'Fernandez', 'Weaver', 'Daniels', 'Stephens', 'Gardner', 'Payne',
    'Kelley', 'Dunn', 'Pierce', 'Arnold', 'Tran', 'Spencer', 'Peters',
    'Hawkins', 'Grant', 'Hansen', 'Castro', 'Hoffman', 'Hart', 'Elliott',
    'Cunningham', 'Knight', 'Bradley', 'Carroll', 'Hudson', 'Duncan', 'Armstrong',
    'Berry', 'Andrews', 'Johnston', 'Ray', 'Lane', 'Riley', 'Carpenter',
    'Perkins', 'Aguilar', 'Silva', 'Richards', 'Willis', 'Matthews', 'Chapman',
    'Lawrence', 'Garza', 'Vargas', 'Watkins', 'Wheeler', 'Larson', 'Carlson',
    'Harper', 'George', 'Greene', 'Burke', 'Guzman', 'Morrison', 'Munoz',
    'Jacobs', 'Obrien', 'Lawson', 'Franklin', 'Lynch', 'Bishop', 'Carr',
  ];

  /// Generates a single player with random stats and name
  Player generatePlayer({String? name}) {
    final height = _generateHeight();
    
    // Generate base attributes
    int shooting = _generateStat();
    int defense = _generateStat();
    int speed = _generateStat();
    int postShooting = _generateStat();
    int passing = _generateStat();
    int rebounding = _generateStat();
    int ballHandling = _generateStat();
    int threePoint = _generateStat();
    int blocks = _generateStat();
    int steals = _generateStat();
    
    // Apply height-based modifiers
    if (height >= 80) {
      // Tall players (6'8"+): better at rebounding, blocks, and post shooting, worse at steals, shooting, and speed
      rebounding = (rebounding + 15).clamp(0, 100);
      blocks = (blocks + 20).clamp(0, 100);
      postShooting = (postShooting + 15).clamp(0, 100);
      steals = (steals - 8).clamp(0, 100);
      shooting = (shooting - 5).clamp(0, 100);
      speed = (speed - 10).clamp(0, 100);
    } else if (height <= 72) {
      // Short players (6'0" and under): better at steals, shooting, and speed, worse at rebounding, blocks, and post shooting
      steals = (steals + 20).clamp(0, 100);
      shooting = (shooting + 15).clamp(0, 100);
      speed = (speed + 10).clamp(0, 100);
      rebounding = (rebounding - 10).clamp(0, 100);
      blocks = (blocks - 15).clamp(0, 100);
      postShooting = (postShooting - 10).clamp(0, 100);
    }
    
    // Assign position based on attributes and height
    final position = _assignBestPosition(
      height,
      passing,
      ballHandling,
      shooting,
      threePoint,
      rebounding,
      blocks,
      defense,
      speed,
      postShooting,
    );
    
    return Player(
      id: _uuid.v4(),
      name: name ?? _generateRandomName(),
      heightInches: height,
      shooting: shooting,
      defense: defense,
      speed: speed,
      postShooting: postShooting,
      passing: passing,
      rebounding: rebounding,
      ballHandling: ballHandling,
      threePoint: threePoint,
      blocks: blocks,
      steals: steals,
      position: position,
    );
  }

  /// Assign best-fit position based on player attributes and height
  /// Uses the same formulas as PositionAffinity class for consistency
  String _assignBestPosition(
    int height,
    int passing,
    int ballHandling,
    int shooting,
    int threePoint,
    int rebounding,
    int blocks,
    int defense,
    int speed,
    int postShooting,
  ) {
    // PG: passing (40%), ballHandling (30%), speed (20%), height penalty
    final pgScore = (passing * 0.4) + (ballHandling * 0.3) + (speed * 0.2) - 
                    ((height - 72) * 0.5);
    
    // SG: shooting (35%), threePoint (35%), speed (20%), height bonus for 73-78"
    final sgScore = (shooting * 0.35) + (threePoint * 0.35) + (speed * 0.2) + 
                    ((height >= 73 && height <= 78) ? 10.0 : 0.0);
    
    // SF: shooting (25%), defense (25%), speed (20%), height bonus for 76-80"
    final sfScore = (shooting * 0.25) + (defense * 0.25) + (speed * 0.2) + 
                    ((height >= 76 && height <= 80) ? 25.0 : 0.0);
    
    // PF: rebounding (35%), defense (25%), postShooting (25%), height bonus
    final pfScore = (rebounding * 0.35) + (defense * 0.25) + (postShooting * 0.25) + 
                    ((height - 76) * 1.0);
    
    // C: rebounding (35%), blocks (30%), postShooting (25%), height bonus
    final cScore = (rebounding * 0.35) + (blocks * 0.3) + (postShooting * 0.25) + 
                   ((height - 78) * 1.5);
    
    // Find position with highest affinity
    final scores = {
      'PG': pgScore,
      'SG': sgScore,
      'SF': sfScore,
      'PF': pfScore,
      'C': cScore,
    };
    
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Generates a random height for a basketball player
  /// Returns height in inches, ranging from 5'10" (70") to 7'2" (86")
  /// Uses normal distribution centered around 6'6" (78") with standard deviation of 3"
  int _generateHeight() {
    // Generate a value using Box-Muller transform for normal distribution
    double u1 = _random.nextDouble();
    double u2 = _random.nextDouble();
    double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

    // Mean of 78 inches (6'6"), standard deviation of 3 inches
    double value = 78 + (z0 * 3);

    // Clamp to realistic basketball player height range: 70" (5'10") to 86" (7'2")
    return value.clamp(70, 86).round();
  }

  /// Generates a list of players for a team roster
  /// [count] specifies how many players to generate (default: 15)
  /// Ensures balanced position distribution: 3 PG, 3 SG, 3 SF, 3 PF, 3 C
  List<Player> generateTeamRoster(int count) {
    if (count != 15) {
      // For non-standard roster sizes, use random generation
      return List.generate(count, (_) => generatePlayer());
    }
    
    // For standard 15-player roster, ensure balanced distribution
    final positions = ['PG', 'SG', 'SF', 'PF', 'C'];
    final players = <Player>[];
    
    // Generate 3 players for each position
    for (var position in positions) {
      for (var i = 0; i < 3; i++) {
        players.add(_generatePlayerForPosition(position));
      }
    }
    
    // Shuffle to randomize order
    players.shuffle(_random);
    return players;
  }
  
  /// Generates a player optimized for a specific position
  Player _generatePlayerForPosition(String targetPosition) {
    Player player;
    int attempts = 0;
    const maxAttempts = 50;
    
    // Keep generating until we get a player that naturally fits the target position
    // or we hit max attempts
    do {
      player = generatePlayer();
      attempts++;
    } while (player.position != targetPosition && attempts < maxAttempts);
    
    // If we couldn't generate a natural fit, force the position
    if (player.position != targetPosition) {
      player = player.copyWithPosition(targetPosition);
    }
    
    return player;
  }

  /// Generates a random player name by combining first and last names
  String _generateRandomName() {
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    return '$firstName $lastName';
  }

  /// Generates a random stat value in the range 0-100
  /// Uses a normal distribution centered around 75 with standard deviation of 15
  /// This creates stats averaging 70-80 with some outliers
  int _generateStat() {
    // Generate a value using Box-Muller transform for normal distribution
    double u1 = _random.nextDouble();
    double u2 = _random.nextDouble();
    double z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

    // Mean of 75, standard deviation of 15
    double value = 75 + (z0 * 15);

    // Clamp to 0-100 range
    return value.clamp(0, 100).round();
  }
}
