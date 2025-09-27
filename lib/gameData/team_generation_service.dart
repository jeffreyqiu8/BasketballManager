import 'dart:math';
import 'enhanced_player.dart';
import 'enhanced_team.dart';
import 'nba_team_data.dart';
import 'enums.dart';
import 'development_system.dart';
import 'role_manager.dart';
import 'player_class.dart';

/// Service for generating realistic NBA team rosters with authentic players
class TeamGenerationService {
  static final Random _random = Random();
  
  // NBA roster and salary constraints (2024-25 season)
  static const double salaryCap = 140.6; // NBA salary cap in millions
  static const double luxuryTax = 170.8; // Luxury tax threshold in millions
  static const double minimumSalary = 1.157; // Minimum salary in millions
  static const double maximumSalary = 51.2; // Maximum salary (35% of cap) in millions
  static const int minRosterSize = 13; // Minimum roster size
  static const int maxRosterSize = 17; // Maximum roster size (including two-way contracts)
  static const int startingLineupSize = 5; // Starting lineup size
  static const int maxTwoWayContracts = 2; // Maximum two-way contracts
  
  // Player salary ranges by role and skill level
  static const Map<PlayerRole, Map<String, double>> salaryRanges = {
    PlayerRole.pointGuard: {'min': 1.5, 'max': 45.0, 'average': 12.0},
    PlayerRole.shootingGuard: {'min': 1.2, 'max': 40.0, 'average': 10.5},
    PlayerRole.smallForward: {'min': 1.8, 'max': 50.0, 'average': 14.0},
    PlayerRole.powerForward: {'min': 2.0, 'max': 35.0, 'average': 11.5},
    PlayerRole.center: {'min': 2.5, 'max': 42.0, 'average': 13.5},
  };

  /// Generate a complete realistic NBA team roster with salary cap management
  static EnhancedTeam generateNBATeamRoster(NBATeam nbaTeam, {
    int? rosterSize,
    double? targetSalaryCap,
    int? averageAge,
  }) {
    rosterSize ??= _random.nextInt(maxRosterSize - minRosterSize + 1) + minRosterSize;
    targetSalaryCap ??= salaryCap * (0.85 + _random.nextDouble() * 0.3); // 85-115% of cap
    averageAge ??= 26 + _random.nextInt(4); // 26-29 average age
    
    List<EnhancedPlayer> roster = [];
    List<PlayerTier> playerTiers = [];
    Set<String> teamUsedNames = {}; // Track names within this team
    
    // Generate position-balanced roster
    Map<PlayerRole, int> positionCounts = _calculatePositionDistribution(rosterSize);
    
    // Generate players for each position
    for (PlayerRole role in PlayerRole.values) {
      int count = positionCounts[role] ?? 0;
      
      for (int i = 0; i < count; i++) {
        // Determine if this should be a star, starter, or bench player
        PlayerTier tier = _determinePlayerTier(i, count, role);
        
        // Generate player with appropriate skill level
        EnhancedPlayer player = _generatePlayerForRoleWithUniqueName(
          role: role,
          tier: tier,
          teamName: nbaTeam.fullName,
          targetAge: _generateAgeForTier(tier, averageAge),
          usedNames: teamUsedNames,
        );
        
        roster.add(player);
        playerTiers.add(tier);
        teamUsedNames.add(player.name);
      }
    }
    
    // Generate salary distribution that fits under cap
    Map<EnhancedPlayer, double> salaryDistribution = _generateSalaryDistribution(
      roster, 
      targetSalaryCap, 
      playerTiers,
    );
    
    // Validate roster composition
    if (!_validateRosterComposition(roster)) {
      throw Exception('Generated roster does not meet NBA composition requirements');
    }
    
    // Select best starting lineup based on overall ratings
    List<EnhancedPlayer> starters = _selectOptimalStartingLineup(roster);
    
    // Create enhanced team with generated roster
    EnhancedTeam team = EnhancedTeam(
      name: nbaTeam.name,
      reputation: _calculateTeamReputation(roster),
      playerCount: roster.length,
      teamSize: maxRosterSize,
      players: List<Player>.from(roster),
      starters: List<Player>.from(starters),
      branding: nbaTeam.branding,
      conference: nbaTeam.conference,
      division: nbaTeam.division,
      history: nbaTeam.history,
    );
    
    return team;
  }

  /// Select optimal starting lineup ensuring all positions are covered
  static List<EnhancedPlayer> _selectOptimalStartingLineup(List<EnhancedPlayer> roster) {
    List<EnhancedPlayer> starters = [];
    Set<PlayerRole> assignedRoles = {};
    
    // First pass: assign best player for each position
    for (PlayerRole role in PlayerRole.values) {
      EnhancedPlayer? bestPlayer;
      double bestOverall = 0.0;
      
      for (EnhancedPlayer player in roster) {
        if (player.primaryRole == role && !starters.contains(player)) {
          double overall = (player.shooting + player.rebounding + player.passing + 
                           player.ballHandling + player.perimeterDefense + 
                           player.postDefense + player.insideShooting) / 7.0;
          
          if (overall > bestOverall) {
            bestOverall = overall;
            bestPlayer = player;
          }
        }
      }
      
      if (bestPlayer != null) {
        starters.add(bestPlayer);
        assignedRoles.add(role);
      }
    }
    
    // Second pass: fill any missing positions with versatile players
    for (PlayerRole role in PlayerRole.values) {
      if (!assignedRoles.contains(role) && starters.length < 5) {
        EnhancedPlayer? bestAvailable;
        double bestCompatibility = 0.0;
        
        for (EnhancedPlayer player in roster) {
          if (!starters.contains(player)) {
            double compatibility = player.calculateRoleCompatibility(role);
            if (compatibility > bestCompatibility) {
              bestCompatibility = compatibility;
              bestAvailable = player;
            }
          }
        }
        
        if (bestAvailable != null) {
          starters.add(bestAvailable);
          assignedRoles.add(role);
        }
      }
    }
    
    // Ensure we have exactly 5 starters
    while (starters.length < 5 && starters.length < roster.length) {
      for (EnhancedPlayer player in roster) {
        if (!starters.contains(player)) {
          starters.add(player);
          break;
        }
      }
    }
    
    return starters.take(5).toList();
  }

  /// Generate all 30 NBA teams with realistic rosters
  static List<EnhancedTeam> generateAllNBATeams({
    Map<String, int>? customRosterSizes,
    Map<String, double>? customSalaryCaps,
  }) {
    List<NBATeam> nbaTeams = RealTeamData.getAllNBATeams();
    List<EnhancedTeam> generatedTeams = [];
    Set<String> usedNames = {}; // Track used names across all teams
    
    for (NBATeam nbaTeam in nbaTeams) {
      int rosterSize = customRosterSizes?[nbaTeam.fullName] ?? 
                     (_random.nextInt(maxRosterSize - minRosterSize + 1) + minRosterSize);
      double targetCap = customSalaryCaps?[nbaTeam.fullName] ?? 
                        (salaryCap * (0.85 + _random.nextDouble() * 0.3));
      
      EnhancedTeam team = _generateNBATeamRosterWithUniqueNames(
        nbaTeam,
        usedNames,
        rosterSize: rosterSize,
        targetSalaryCap: targetCap,
      );
      
      generatedTeams.add(team);
    }
    
    return generatedTeams;
  }

  /// Calculate optimal position distribution for roster size
  static Map<PlayerRole, int> _calculatePositionDistribution(int rosterSize) {
    // Base distribution: 2-3 guards, 3-4 forwards, 2-3 centers
    Map<PlayerRole, int> distribution = {
      PlayerRole.pointGuard: 2,
      PlayerRole.shootingGuard: 3,
      PlayerRole.smallForward: 3,
      PlayerRole.powerForward: 3,
      PlayerRole.center: 2,
    };
    
    int currentTotal = distribution.values.reduce((a, b) => a + b);
    int remaining = rosterSize - currentTotal;
    
    // Distribute remaining spots based on modern NBA trends
    List<PlayerRole> preferredAdditions = [
      PlayerRole.smallForward, // Versatile wings
      PlayerRole.shootingGuard, // Shooting depth
      PlayerRole.powerForward, // Stretch bigs
      PlayerRole.pointGuard, // Backup guards
      PlayerRole.center, // Big man depth
    ];
    
    for (int i = 0; i < remaining; i++) {
      PlayerRole roleToAdd = preferredAdditions[i % preferredAdditions.length];
      distribution[roleToAdd] = (distribution[roleToAdd] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Determine player tier based on position in depth chart
  static PlayerTier _determinePlayerTier(int positionIndex, int totalAtPosition, PlayerRole role) {
    if (positionIndex == 0) {
      // First player at position - could be star or starter
      return _random.nextDouble() < 0.3 ? PlayerTier.star : PlayerTier.starter;
    } else if (positionIndex == 1 && totalAtPosition > 2) {
      // Second player - usually starter or sixth man
      return _random.nextDouble() < 0.4 ? PlayerTier.starter : PlayerTier.sixthMan;
    } else if (positionIndex == 2) {
      // Third player - sixth man or bench
      return _random.nextDouble() < 0.3 ? PlayerTier.sixthMan : PlayerTier.bench;
    } else {
      // Deep bench players
      return PlayerTier.bench;
    }
  }

  /// Generate age appropriate for player tier
  static int _generateAgeForTier(PlayerTier tier, int teamAverageAge) {
    switch (tier) {
      case PlayerTier.star:
        return 25 + _random.nextInt(6); // 25-30 (prime years)
      case PlayerTier.starter:
        return 23 + _random.nextInt(8); // 23-30
      case PlayerTier.sixthMan:
        return 22 + _random.nextInt(10); // 22-31
      case PlayerTier.bench:
        return 20 + _random.nextInt(12); // 20-31 (wider range)
    }
  }



  /// Generate role-based attributes with appropriate distributions
  static Map<String, int> _generateRoleBasedAttributes(PlayerRole role, PlayerTier tier) {
    // Base attribute ranges by tier
    Map<PlayerTier, Map<String, int>> tierRanges = {
      PlayerTier.star: {'min': 80, 'max': 99, 'average': 88},
      PlayerTier.starter: {'min': 70, 'max': 90, 'average': 78},
      PlayerTier.sixthMan: {'min': 65, 'max': 85, 'average': 73},
      PlayerTier.bench: {'min': 50, 'max': 75, 'average': 62},
    };
    
    Map<String, int> tierRange = tierRanges[tier]!;
    Map<String, int> attributes = {};
    
    // Get role weights for attribute generation
    Map<String, double> roleWeights = RoleManager.roleWeights[role]!;
    
    // Generate each attribute
    for (String attribute in ['shooting', 'rebounding', 'passing', 'ballHandling', 
                             'perimeterDefense', 'postDefense', 'insideShooting']) {
      
      double weight = roleWeights[attribute] ?? 1.0;
      int baseValue = tierRange['average']!;
      
      // Adjust base value based on role importance
      if (weight >= 2.0) {
        // Primary skill - boost significantly
        baseValue = (baseValue * 1.15).round();
      } else if (weight >= 1.5) {
        // Important skill - moderate boost
        baseValue = (baseValue * 1.08).round();
      } else if (weight <= 0.5) {
        // Weak skill - reduce significantly
        baseValue = (baseValue * 0.75).round();
      }
      
      // Add random variation
      int variation = (tierRange['max']! - tierRange['min']!) ~/ 4;
      int finalValue = baseValue + _random.nextInt(variation * 2) - variation;
      
      // Clamp to tier limits
      finalValue = finalValue.clamp(tierRange['min']!, tierRange['max']!);
      
      attributes[attribute] = finalValue;
    }
    
    return attributes;
  }

  /// Generate realistic height for role
  static int _generateHeightForRole(PlayerRole role) {
    Map<PlayerRole, Map<String, int>> heightRanges = {
      PlayerRole.pointGuard: {'min': 175, 'max': 195, 'average': 185},
      PlayerRole.shootingGuard: {'min': 185, 'max': 205, 'average': 195},
      PlayerRole.smallForward: {'min': 195, 'max': 210, 'average': 203},
      PlayerRole.powerForward: {'min': 200, 'max': 215, 'average': 208},
      PlayerRole.center: {'min': 205, 'max': 225, 'average': 213},
    };
    
    Map<String, int> range = heightRanges[role]!;
    int variation = (range['max']! - range['min']!) ~/ 3;
    
    return range['average']! + _random.nextInt(variation * 2) - variation;
  }

  /// Select random nationality with realistic NBA distribution
  static String _selectRandomNationality() {
    // Updated nationality distribution based on current NBA demographics
    Map<String, double> nationalityWeights = {
      'USA': 0.73,        // ~73% American players
      'Canada': 0.07,     // ~7% Canadian players
      'France': 0.025,    // ~2.5% French players
      'Germany': 0.02,    // ~2% German players
      'Australia': 0.02,  // ~2% Australian players
      'Spain': 0.015,     // ~1.5% Spanish players
      'Serbia': 0.015,    // ~1.5% Serbian players
      'Greece': 0.01,     // ~1% Greek players
      'Lithuania': 0.008, // ~0.8% Lithuanian players
      'Croatia': 0.008,   // ~0.8% Croatian players
      'Slovenia': 0.005,  // ~0.5% Slovenian players
      'Turkey': 0.008,    // ~0.8% Turkish players
      'Brazil': 0.008,    // ~0.8% Brazilian players
      'Argentina': 0.008, // ~0.8% Argentinian players
      'Nigeria': 0.012,   // ~1.2% Nigerian players
      'Cameroon': 0.008,  // ~0.8% Cameroonian players
      'Other': 0.037,     // ~3.7% other nationalities
    };
    
    double random = _random.nextDouble();
    double cumulative = 0.0;
    
    for (MapEntry<String, double> entry in nationalityWeights.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        if (entry.key == 'Other') {
          // Return a random nationality from the expanded list
          List<String> otherNationalities = ['Italy', 'Latvia', 'Poland', 'Israel', 'Japan', 'South Korea', 'Mexico', 'Dominican Republic'];
          return otherNationalities[_random.nextInt(otherNationalities.length)];
        }
        return entry.key;
      }
    }
    
    return 'USA'; // Fallback
  }

  /// Generate NBA team roster with unique names across all teams
  static EnhancedTeam _generateNBATeamRosterWithUniqueNames(
    NBATeam nbaTeam,
    Set<String> usedNames, {
    int? rosterSize,
    double? targetSalaryCap,
    int? averageAge,
  }) {
    rosterSize ??= _random.nextInt(maxRosterSize - minRosterSize + 1) + minRosterSize;
    targetSalaryCap ??= salaryCap * (0.85 + _random.nextDouble() * 0.3);
    averageAge ??= 26 + _random.nextInt(4);
    
    List<EnhancedPlayer> roster = [];
    double currentSalary = 0.0;
    
    // Generate position-balanced roster
    Map<PlayerRole, int> positionCounts = _calculatePositionDistribution(rosterSize);
    
    // Generate players for each position
    for (PlayerRole role in PlayerRole.values) {
      int count = positionCounts[role] ?? 0;
      
      for (int i = 0; i < count; i++) {
        PlayerTier tier = _determinePlayerTier(i, count, role);
        
        EnhancedPlayer player = _generatePlayerForRoleWithUniqueName(
          role: role,
          tier: tier,
          teamName: nbaTeam.fullName,
          targetAge: _generateAgeForTier(tier, averageAge),
          usedNames: usedNames,
        );
        
        double salary = _calculatePlayerSalary(player, tier);
        
        if (currentSalary + salary <= targetSalaryCap || roster.length < 8) {
          roster.add(player);
          currentSalary += salary;
          usedNames.add(player.name);
        } else {
          EnhancedPlayer cheaperPlayer = _generatePlayerForRoleWithUniqueName(
            role: role,
            tier: PlayerTier.bench,
            teamName: nbaTeam.fullName,
            targetAge: _generateAgeForTier(PlayerTier.bench, averageAge),
            usedNames: usedNames,
          );
          roster.add(cheaperPlayer);
          currentSalary += _calculatePlayerSalary(cheaperPlayer, PlayerTier.bench);
          usedNames.add(cheaperPlayer.name);
        }
      }
    }
    
    // Create enhanced team
    EnhancedTeam team = EnhancedTeam(
      name: nbaTeam.name,
      reputation: _calculateTeamReputation(roster),
      playerCount: roster.length,
      teamSize: maxRosterSize,
      players: List<Player>.from(roster),
      starters: List<Player>.from(roster.take(5)), // Set starters in constructor
      branding: nbaTeam.branding,
      conference: nbaTeam.conference,
      division: nbaTeam.division,
      history: nbaTeam.history,
    );
    
    return team;
  }

  /// Generate a player with unique name
  static EnhancedPlayer _generatePlayerForRoleWithUniqueName({
    required PlayerRole role,
    required PlayerTier tier,
    required String teamName,
    required int targetAge,
    required Set<String> usedNames,
  }) {
    String name;
    String nationality;
    int attempts = 0;
    
    // Try to generate unique name
    do {
      nationality = _selectRandomNationality();
      name = _generateRealisticName(nationality);
      attempts++;
      
      // If we can't find unique name after many attempts, add suffix
      if (attempts > 50) {
        name = '$name ${attempts - 50}';
        break;
      }
    } while (usedNames.contains(name));
    
    // Generate other attributes
    Map<String, int> attributes = _generateRoleBasedAttributes(role, tier);
    int height = _generateHeightForRole(role);
    PlayerPotential potential = _generatePotential(targetAge, tier);
    
    return EnhancedPlayer(
      name: name,
      age: targetAge,
      team: teamName,
      experienceYears: _calculateExperienceYears(targetAge),
      nationality: nationality,
      currentStatus: 'Active',
      height: height,
      shooting: attributes['shooting']!,
      rebounding: attributes['rebounding']!,
      passing: attributes['passing']!,
      ballHandling: attributes['ballHandling']!,
      perimeterDefense: attributes['perimeterDefense']!,
      postDefense: attributes['postDefense']!,
      insideShooting: attributes['insideShooting']!,
      performances: {},
      primaryRole: role,
      potential: potential,
      development: DevelopmentTracker.initial(),
    );
  }

  /// Generate realistic names by nationality with expanded name pools
  static String _generateRealisticName(String nationality) {
    Map<String, List<String>> firstNamesByNationality = {
      'USA': ['Michael', 'LeBron', 'Stephen', 'Kevin', 'James', 'Chris', 'Russell', 'Damian', 'Anthony', 'Kyle', 
              'Jayson', 'Devin', 'Donovan', 'Trae', 'Zion', 'Ja', 'Tyler', 'Brandon', 'CJ', 'Kemba',
              'Jimmy', 'Bam', 'Khris', 'Jrue', 'Draymond', 'Klay', 'Paul', 'Kawhi', 'Joel', 'Ben'],
      'Canada': ['Jamal', 'Andrew', 'Tristan', 'Cory', 'Kelly', 'Dwight', 'Nik', 'Trey', 'RJ', 'Shai',
                 'Chris', 'Dillon', 'Lu', 'Khem', 'Melvin', 'Mychal', 'Nickeil', 'Oshae', 'Karim', 'Ignas'],
      'France': ['Tony', 'Nicolas', 'Rudy', 'Evan', 'Frank', 'Timothe', 'Sekou', 'Theo', 'Killian', 'Moussa',
                 'Vincent', 'Nando', 'Axel', 'Petr', 'Yakuba', 'Mathias', 'Elie', 'Yabusele', 'Adam', 'Bilal'],
      'Germany': ['Dirk', 'Dennis', 'Maxi', 'Daniel', 'Moritz', 'Isaiah', 'Franz', 'Moe', 'Paul', 'Johannes',
                  'Robin', 'Tibor', 'Niels', 'Andreas', 'Joshiko', 'Ariel', 'Kostja', 'Per', 'Elias', 'Leon'],
      'Australia': ['Ben', 'Joe', 'Patty', 'Matthew', 'Aron', 'Ryan', 'Dante', 'Josh', 'Dyson', 'Jock',
                    'Thon', 'Xavier', 'Mitch', 'Nathan', 'Duop', 'Isaac', 'Will', 'Keanu', 'Samson', 'Kai'],
      'Spain': ['Pau', 'Marc', 'Ricky', 'Jose', 'Sergio', 'Juan', 'Willy', 'Juancho', 'Santi', 'Usman',
                'Alex', 'Victor', 'Alberto', 'Xavi', 'Dario', 'Nikola', 'Luka', 'Jaime', 'Carlos', 'Ruben'],
      'Serbia': ['Nikola', 'Bogdan', 'Nemanja', 'Milos', 'Boban', 'Marko', 'Aleksej', 'Stefan', 'Vasilije', 'Ognjen',
                 'Nikola', 'Vanja', 'Dusan', 'Marko', 'Luka', 'Petar', 'Milan', 'Dragan', 'Zoran', 'Dejan'],
      'Greece': ['Giannis', 'Thanasis', 'Kostas', 'Tyler', 'Georgios', 'Ioannis', 'Nikos', 'Dimitrios', 'Andreas', 'Vassilis',
                 'Panagiotis', 'Michalis', 'Christos', 'Alexandros', 'Konstantinos', 'Spiros', 'Yannis', 'Lefteris', 'Manolis', 'Takis'],
      'Lithuania': ['Jonas', 'Domantas', 'Mindaugas', 'Donatas mindaugas', 'Arvydas', 'Sarunas', 'Robertas', 'Paulius', 'Tomas', 'Lukas'],
      'Croatia': ['Dario', 'Bojan', 'Mario', 'Ante', 'Dragan', 'Roko', 'Luka', 'Krunoslav', 'Damjan', 'Mateo'],
      'Slovenia': ['Luka', 'Goran', 'Zoran', 'Vlatko', 'Aleksander', 'Jaka', 'Klemen', 'Matej', 'Anze', 'Miha'],
      'Turkey': ['Cedi', 'Furkan', 'Ersan', 'Omer', 'Alperen', 'Semih', 'Kerem', 'Berk', 'Dogus', 'Metecan'],
      'Brazil': ['Anderson', 'Leandro', 'Nene', 'Raul', 'Bruno', 'Cristiano', 'Marcelo', 'Guilherme', 'Rafael', 'Lucas'],
      'Argentina': ['Manu', 'Luis', 'Carlos', 'Fabricio', 'Nicolas', 'Patricio', 'Facundo', 'Luca', 'Gabriel', 'Marcos'],
      'Nigeria': ['Giannis', 'Precious', 'Josh', 'KZ', 'Chimezie', 'Semi', 'Ike', 'Ekpe', 'Jordan', 'Caleb'],
      'Cameroon': ['Joel', 'Pascal', 'Luc', 'Christian', 'Nicolas', 'Yannick', 'Benoit', 'Ruben', 'Ulrich', 'Landry'],
    };
    
    Map<String, List<String>> lastNamesByNationality = {
      'USA': ['Johnson', 'Williams', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas',
              'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson', 'Clark', 'Rodriguez',
              'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'Hernandez', 'King', 'Wright', 'Lopez'],
      'Canada': ['Murray', 'Wiggins', 'Thompson', 'Joseph', 'Olynyk', 'Powell', 'Stauskas', 'Lyles', 'Barrett', 'Alexander',
                 'Brooks', 'Clarke', 'Ejim', 'Frazier', 'Mulder', 'Thompson-Boling', 'Alexander-Walker', 'Dort', 'Birch', 'Boucher'],
      'France': ['Parker', 'Batum', 'Gobert', 'Fournier', 'Ntilikina', 'Luwawu-Cabarrot', 'Doumbouya', 'Maledon', 'Hayes', 'Diabate',
                 'Poirier', 'De Colo', 'Toupane', 'Lessort', 'Yabusele', 'Cornelie', 'Begarin', 'Coulibaly', 'Risacher', 'Sarr'],
      'Germany': ['Nowitzki', 'Schroder', 'Kleber', 'Theis', 'Wagner', 'Hartenstein', 'Zipser', 'Voigtmann', 'Pleiss', 'Saibou',
                  'Giffey', 'Benzing', 'Weiler-Babb', 'Obst', 'Thiemann', 'Wank', 'Sengfelder', 'Vargas', 'Hollatz', 'Kayser'],
      'Australia': ['Simmons', 'Ingles', 'Mills', 'Dellavedova', 'Baynes', 'Broekhoff', 'Exum', 'Green', 'Daniels', 'Landale',
                    'Maker', 'Cooks', 'Creek', 'Sobey', 'Kay', 'Gliddon', 'Trimble', 'Reath', 'Magnay', 'Pinder'],
      'Spain': ['Gasol', 'Rubio', 'Calderon', 'Rodriguez', 'Hernangomez', 'Aldama', 'Garuba', 'Abrines', 'Mirotic', 'Ibaka',
                'Claver', 'Oriola', 'Sastre', 'Prepelic', 'Brizuela', 'Deck', 'Pradilla', 'Yusta', 'Diez', 'Vicedo'],
      'Serbia': ['Jokic', 'Bogdanovic', 'Bjelica', 'Teodosic', 'Marjanovic', 'Guduric', 'Pokusevski', 'Petrusev', 'Micic', 'Avramovic',
                 'Kalinic', 'Raduljica', 'Simonovic', 'Lucic', 'Davidovac', 'Milutinov', 'Dobric', 'Jaramaz', 'Smailagic', 'Pecarski'],
      'Greece': ['Antetokounmpo', 'Papagiannis', 'Calathes', 'Sloukas', 'Mitoglou', 'Toliopoulos', 'Kalaitzakis', 'Papanikolaou', 'Printezis', 'Bourousis',
                 'Koufos', 'Mantzaris', 'Kavaliauskas', 'Agravanis', 'Bochoridis', 'Charalampopoulos', 'Moraitis', 'Larentzakis', 'Walkup', 'Bentil'],
      'Lithuania': ['Valanciunas', 'Sabonis', 'Kuzminskas', 'Motiejunas', 'Kleiza', 'Jasikevicius', 'Javtokas', 'Seibutis', 'Maciulis', 'Grigonis'],
      'Croatia': ['Saric', 'Bogdanovic', 'Hezonja', 'Bender', 'Zubac', 'Zizic', 'Ukic', 'Prkacin', 'Kalinic', 'Mateo'],
      'Slovenia': ['Doncic', 'Dragic', 'Prepelic', 'Cancar', 'Blazic', 'Randolph', 'Muric', 'Hrovat', 'Lorbek', 'Nachbar'],
      'Turkey': ['Osman', 'Korkmaz', 'Ilyasova', 'Sengun', 'Erden', 'Tuncer', 'Aldemir', 'Sipahi', 'Balbay', 'Arslan'],
      'Brazil': ['Varejao', 'Barbosa', 'Nene', 'Splitter', 'Caboclo', 'Felicio', 'Huertas', 'Lima', 'Oliveira', 'Santos'],
      'Argentina': ['Ginobili', 'Scola', 'Delfino', 'Nocioni', 'Campazzo', 'Garino', 'Brussino', 'Bolmaro', 'Deck', 'Laprovittola'],
      'Nigeria': ['Antetokounmpo', 'Achiuwa', 'Okogie', 'Okpala', 'Metu', 'Ojeleye', 'Anigbogu', 'Udoka', 'Nwora', 'Okongwu'],
      'Cameroon': ['Embiid', 'Siakam', 'Mbah a Moute', 'Batum', 'Biyombo', 'Niang', 'Tchewa', 'Fokou', 'Kingue', 'Eyenga'],
    };
    
    List<String> firstNames = firstNamesByNationality[nationality] ?? firstNamesByNationality['USA']!;
    List<String> lastNames = lastNamesByNationality[nationality] ?? lastNamesByNationality['USA']!;
    
    String firstName = firstNames[_random.nextInt(firstNames.length)];
    String lastName = lastNames[_random.nextInt(lastNames.length)];
    
    return '$firstName $lastName';
  }

  /// Generate player potential based on age and tier
  static PlayerPotential _generatePotential(int age, PlayerTier tier) {
    // Younger players have higher potential
    double ageFactor = (30 - age) / 10.0; // 0.0 to 1.0
    ageFactor = ageFactor.clamp(0.0, 1.0);
    
    // Tier affects potential tier
    PotentialTier potentialTier;
    if (tier == PlayerTier.star) {
      potentialTier = _random.nextDouble() < 0.5 ? PotentialTier.elite : PotentialTier.gold;
    } else if (tier == PlayerTier.starter) {
      potentialTier = _random.nextDouble() < 0.4 ? PotentialTier.gold : PotentialTier.silver;
    } else if (tier == PlayerTier.sixthMan) {
      potentialTier = _random.nextDouble() < 0.3 ? PotentialTier.silver : PotentialTier.bronze;
    } else {
      potentialTier = _random.nextDouble() < 0.2 ? PotentialTier.silver : PotentialTier.bronze;
    }
    
    // Adjust for age - younger players get better potential
    if (age < 23 && potentialTier == PotentialTier.bronze) {
      potentialTier = PotentialTier.silver;
    } else if (age < 21 && potentialTier == PotentialTier.silver) {
      potentialTier = PotentialTier.gold;
    }
    
    return PlayerPotential.fromTier(potentialTier, isHidden: true);
  }

  /// Calculate experience years based on age
  static int _calculateExperienceYears(int age) {
    if (age <= 19) return 0; // Rookie
    if (age <= 22) return _random.nextInt(2); // 0-1 years
    if (age <= 25) return 1 + _random.nextInt(4); // 1-4 years
    if (age <= 30) return 3 + _random.nextInt(8); // 3-10 years
    return 8 + _random.nextInt(12); // 8-19 years for veterans
  }

  /// Calculate player salary based on attributes and tier
  static double _calculatePlayerSalary(EnhancedPlayer player, PlayerTier tier) {
    Map<String, double> salaryRange = salaryRanges[player.primaryRole]!;
    
    // Base salary by tier
    Map<PlayerTier, double> tierSalaryMultipliers = {
      PlayerTier.star: 0.8, // 80% of max
      PlayerTier.starter: 0.5, // 50% of max
      PlayerTier.sixthMan: 0.3, // 30% of max
      PlayerTier.bench: 0.15, // 15% of max
    };
    
    double baseMultiplier = tierSalaryMultipliers[tier]!;
    double baseSalary = salaryRange['min']! + 
                      (salaryRange['max']! - salaryRange['min']!) * baseMultiplier;
    
    // Adjust for age (prime years get premium)
    double ageFactor = 1.0;
    if (player.age >= 25 && player.age <= 29) {
      ageFactor = 1.2; // Prime years premium
    } else if (player.age < 23) {
      ageFactor = 0.8; // Rookie scale discount
    } else if (player.age > 32) {
      ageFactor = 0.7; // Veteran discount
    }
    
    double finalSalary = baseSalary * ageFactor * (0.8 + _random.nextDouble() * 0.4);
    
    // Ensure salary is within valid range
    return finalSalary.clamp(minimumSalary, maximumSalary);
  }

  /// Calculate team reputation based on roster quality
  static int _calculateTeamReputation(List<EnhancedPlayer> roster) {
    if (roster.isEmpty) return 50;
    
    double averageOverall = 0.0;
    double starPlayerBonus = 0.0;
    
    for (EnhancedPlayer player in roster) {
      // Calculate overall rating
      double overall = (player.shooting + player.rebounding + player.passing + 
                       player.ballHandling + player.perimeterDefense + 
                       player.postDefense + player.insideShooting) / 7.0;
      averageOverall += overall;
      
      // Add bonus for star players (85+ overall)
      if (overall >= 85) {
        starPlayerBonus += (overall - 85) * 0.5;
      }
    }
    
    averageOverall /= roster.length;
    
    // Convert to reputation scale (30-95) with star player bonus
    int baseReputation = (30 + (averageOverall - 50) * 1.3).round();
    int finalReputation = (baseReputation + starPlayerBonus).round().clamp(30, 95);
    
    return finalReputation;
  }

  /// Validate roster composition meets NBA requirements
  static bool _validateRosterComposition(List<EnhancedPlayer> roster) {
    if (roster.length < minRosterSize || roster.length > maxRosterSize) {
      return false;
    }
    
    // Check position distribution - must have at least one of each position
    Map<PlayerRole, int> positionCounts = {};
    for (EnhancedPlayer player in roster) {
      positionCounts[player.primaryRole] = (positionCounts[player.primaryRole] ?? 0) + 1;
    }
    
    // Ensure all positions are represented
    for (PlayerRole role in PlayerRole.values) {
      if ((positionCounts[role] ?? 0) == 0) {
        return false;
      }
    }
    
    return true;
  }

  /// Calculate total team salary
  static double _calculateTotalSalary(List<EnhancedPlayer> roster, Map<EnhancedPlayer, double> salaries) {
    double total = 0.0;
    for (EnhancedPlayer player in roster) {
      total += salaries[player] ?? minimumSalary;
    }
    return total;
  }

  /// Generate salary distribution that fits under cap
  static Map<EnhancedPlayer, double> _generateSalaryDistribution(
    List<EnhancedPlayer> roster, 
    double targetSalaryCap,
    List<PlayerTier> playerTiers,
  ) {
    Map<EnhancedPlayer, double> salaries = {};
    
    // Calculate base salaries for all players
    List<double> baseSalaries = [];
    for (int i = 0; i < roster.length; i++) {
      double salary = _calculatePlayerSalary(roster[i], playerTiers[i]);
      baseSalaries.add(salary);
    }
    
    // Calculate total of base salaries
    double totalBaseSalaries = baseSalaries.reduce((a, b) => a + b);
    
    // If total exceeds cap, scale down proportionally
    if (totalBaseSalaries > targetSalaryCap) {
      double scaleFactor = targetSalaryCap / totalBaseSalaries;
      
      for (int i = 0; i < roster.length; i++) {
        double scaledSalary = baseSalaries[i] * scaleFactor;
        // Ensure salary doesn't go below minimum
        double finalSalary = scaledSalary.clamp(minimumSalary, maximumSalary);
        salaries[roster[i]] = finalSalary;
      }
    } else {
      // Total is under cap, use base salaries
      for (int i = 0; i < roster.length; i++) {
        salaries[roster[i]] = baseSalaries[i];
      }
    }
    
    return salaries;
  }
}

/// Player tier classification for roster generation
enum PlayerTier {
  star,      // Superstar/All-Star level
  starter,   // Solid starter
  sixthMan,  // Sixth man/key reserve
  bench,     // Role player/deep bench
}