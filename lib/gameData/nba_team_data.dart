import 'enhanced_team.dart';

/// Represents an authentic NBA team with all official information
class NBATeam {
  final String name;
  final String city;
  final String abbreviation;
  final String conference;
  final String division;
  final TeamBranding branding;
  final TeamHistory history;

  NBATeam({
    required this.name,
    required this.city,
    required this.abbreviation,
    required this.conference,
    required this.division,
    required this.branding,
    required this.history,
  });

  /// Get full team name (city + name)
  String get fullName => '$city $name';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'abbreviation': abbreviation,
      'conference': conference,
      'division': division,
      'branding': branding.toMap(),
      'history': history.toMap(),
    };
  }

  factory NBATeam.fromMap(Map<String, dynamic> map) {
    return NBATeam(
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      abbreviation: map['abbreviation'] ?? '',
      conference: map['conference'] ?? '',
      division: map['division'] ?? '',
      branding: TeamBranding.fromMap(map['branding'] ?? {}),
      history: TeamHistory.fromMap(map['history'] ?? {}),
    );
  }
}

/// Central repository for all NBA team data and information
class RealTeamData {
  static final Map<String, NBATeam> _nbaTeams = {};
  static bool _initialized = false;

  /// Initialize all NBA teams data
  static void _initializeTeams() {
    if (_initialized) return;

    // Eastern Conference - Atlantic Division
    _nbaTeams['Boston Celtics'] = NBATeam(
      name: 'Celtics',
      city: 'Boston',
      abbreviation: 'BOS',
      conference: 'Eastern',
      division: 'Atlantic',
      branding: TeamBranding(
        primaryColor: '#007A33',
        secondaryColor: '#BA9653',
        logoUrl: 'assets/logos/celtics.png',
        abbreviation: 'BOS',
        city: 'Boston',
        mascot: 'Lucky the Leprechaun',
      ),
      history: TeamHistory(
        foundedYear: 1946,
        championships: 17,
        playoffAppearances: 58,
        retiredNumbers: ['1', '2', '3', '6', '10', '14', '15', '16', '17', '18', '19', '21', '22', '23', '24', '25', '32', '33', '34', '35'],
        hallOfFamers: ['Bill Russell', 'Larry Bird', 'John Havlicek', 'Bob Cousy', 'Paul Pierce'],
        rivalries: {
          'Los Angeles Lakers': 'Historic Finals rivalry',
          'Philadelphia 76ers': 'Division rivalry',
          'Miami Heat': 'Modern playoff rivalry'
        },
      ),
    );

    _nbaTeams['Brooklyn Nets'] = NBATeam(
      name: 'Nets',
      city: 'Brooklyn',
      abbreviation: 'BKN',
      conference: 'Eastern',
      division: 'Atlantic',
      branding: TeamBranding(
        primaryColor: '#000000',
        secondaryColor: '#FFFFFF',
        logoUrl: 'assets/logos/nets.png',
        abbreviation: 'BKN',
        city: 'Brooklyn',
        mascot: 'BrooklyKnight',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 0,
        playoffAppearances: 28,
        retiredNumbers: ['3', '4', '6', '23', '25', '32', '52'],
        hallOfFamers: ['Julius Erving', 'Drazen Petrovic'],
        rivalries: {
          'New York Knicks': 'New York rivalry',
          'Boston Celtics': 'Atlantic Division rivalry'
        },
      ),
    );

    _nbaTeams['New York Knicks'] = NBATeam(
      name: 'Knicks',
      city: 'New York',
      abbreviation: 'NYK',
      conference: 'Eastern',
      division: 'Atlantic',
      branding: TeamBranding(
        primaryColor: '#006BB6',
        secondaryColor: '#F58426',
        logoUrl: 'assets/logos/knicks.png',
        abbreviation: 'NYK',
        city: 'New York',
        mascot: 'None',
      ),
      history: TeamHistory(
        foundedYear: 1946,
        championships: 2,
        playoffAppearances: 43,
        retiredNumbers: ['10', '12', '15', '19', '22', '24', '33', '613'],
        hallOfFamers: ['Willis Reed', 'Walt Frazier', 'Patrick Ewing', 'Earl Monroe'],
        rivalries: {
          'Brooklyn Nets': 'New York rivalry',
          'Miami Heat': 'Playoff rivalry',
          'Indiana Pacers': '90s rivalry'
        },
      ),
    );

    _nbaTeams['Philadelphia 76ers'] = NBATeam(
      name: '76ers',
      city: 'Philadelphia',
      abbreviation: 'PHI',
      conference: 'Eastern',
      division: 'Atlantic',
      branding: TeamBranding(
        primaryColor: '#006BB6',
        secondaryColor: '#ED174C',
        logoUrl: 'assets/logos/76ers.png',
        abbreviation: 'PHI',
        city: 'Philadelphia',
        mascot: 'Franklin the Dog',
      ),
      history: TeamHistory(
        foundedYear: 1963,
        championships: 3,
        playoffAppearances: 47,
        retiredNumbers: ['2', '3', '4', '6', '10', '13', '15', '24', '32', '34'],
        hallOfFamers: ['Wilt Chamberlain', 'Julius Erving', 'Charles Barkley', 'Allen Iverson'],
        rivalries: {
          'Boston Celtics': 'Historic Eastern rivalry',
          'Los Angeles Lakers': '80s Finals rivalry'
        },
      ),
    );

    _nbaTeams['Toronto Raptors'] = NBATeam(
      name: 'Raptors',
      city: 'Toronto',
      abbreviation: 'TOR',
      conference: 'Eastern',
      division: 'Atlantic',
      branding: TeamBranding(
        primaryColor: '#CE1141',
        secondaryColor: '#000000',
        logoUrl: 'assets/logos/raptors.png',
        abbreviation: 'TOR',
        city: 'Toronto',
        mascot: 'The Raptor',
      ),
      history: TeamHistory(
        foundedYear: 1995,
        championships: 1,
        playoffAppearances: 12,
        retiredNumbers: ['15'],
        hallOfFamers: [],
        rivalries: {
          'Boston Celtics': 'Playoff rivalry',
          'Philadelphia 76ers': 'Division rivalry'
        },
      ),
    );

    // Eastern Conference - Central Division
    _nbaTeams['Chicago Bulls'] = NBATeam(
      name: 'Bulls',
      city: 'Chicago',
      abbreviation: 'CHI',
      conference: 'Eastern',
      division: 'Central',
      branding: TeamBranding(
        primaryColor: '#CE1141',
        secondaryColor: '#000000',
        logoUrl: 'assets/logos/bulls.png',
        abbreviation: 'CHI',
        city: 'Chicago',
        mascot: 'Benny the Bull',
      ),
      history: TeamHistory(
        foundedYear: 1966,
        championships: 6,
        playoffAppearances: 35,
        retiredNumbers: ['4', '10', '23', '33'],
        hallOfFamers: ['Michael Jordan', 'Scottie Pippen', 'Dennis Rodman'],
        rivalries: {
          'Detroit Pistons': 'Bad Boys rivalry',
          'Miami Heat': 'Modern playoff rivalry'
        },
      ),
    );

    _nbaTeams['Cleveland Cavaliers'] = NBATeam(
      name: 'Cavaliers',
      city: 'Cleveland',
      abbreviation: 'CLE',
      conference: 'Eastern',
      division: 'Central',
      branding: TeamBranding(
        primaryColor: '#860038',
        secondaryColor: '#FDBB30',
        logoUrl: 'assets/logos/cavaliers.png',
        abbreviation: 'CLE',
        city: 'Cleveland',
        mascot: 'Moondog',
      ),
      history: TeamHistory(
        foundedYear: 1970,
        championships: 1,
        playoffAppearances: 22,
        retiredNumbers: ['7', '25', '42', '43'],
        hallOfFamers: ['LeBron James'],
        rivalries: {
          'Golden State Warriors': '2010s Finals rivalry',
          'Boston Celtics': 'LeBron era rivalry'
        },
      ),
    );

    _nbaTeams['Detroit Pistons'] = NBATeam(
      name: 'Pistons',
      city: 'Detroit',
      abbreviation: 'DET',
      conference: 'Eastern',
      division: 'Central',
      branding: TeamBranding(
        primaryColor: '#C8102E',
        secondaryColor: '#006BB6',
        logoUrl: 'assets/logos/pistons.png',
        abbreviation: 'DET',
        city: 'Detroit',
        mascot: 'Hooper',
      ),
      history: TeamHistory(
        foundedYear: 1941,
        championships: 3,
        playoffAppearances: 41,
        retiredNumbers: ['1', '2', '3', '4', '10', '11', '15', '16', '21', '40'],
        hallOfFamers: ['Isiah Thomas', 'Joe Dumars', 'Dennis Rodman', 'Ben Wallace'],
        rivalries: {
          'Chicago Bulls': 'Jordan vs Bad Boys',
          'Indiana Pacers': 'Central Division rivalry'
        },
      ),
    );

    _nbaTeams['Indiana Pacers'] = NBATeam(
      name: 'Pacers',
      city: 'Indiana',
      abbreviation: 'IND',
      conference: 'Eastern',
      division: 'Central',
      branding: TeamBranding(
        primaryColor: '#002D62',
        secondaryColor: '#FDBB30',
        logoUrl: 'assets/logos/pacers.png',
        abbreviation: 'IND',
        city: 'Indiana',
        mascot: 'Boomer',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 0,
        playoffAppearances: 34,
        retiredNumbers: ['30', '31', '34'],
        hallOfFamers: ['Reggie Miller'],
        rivalries: {
          'New York Knicks': '90s playoff rivalry',
          'Detroit Pistons': 'Central Division rivalry'
        },
      ),
    );

    _nbaTeams['Milwaukee Bucks'] = NBATeam(
      name: 'Bucks',
      city: 'Milwaukee',
      abbreviation: 'MIL',
      conference: 'Eastern',
      division: 'Central',
      branding: TeamBranding(
        primaryColor: '#00471B',
        secondaryColor: '#EEE1C6',
        logoUrl: 'assets/logos/bucks.png',
        abbreviation: 'MIL',
        city: 'Milwaukee',
        mascot: 'Bango',
      ),
      history: TeamHistory(
        foundedYear: 1968,
        championships: 2,
        playoffAppearances: 33,
        retiredNumbers: ['1', '2', '4', '8', '10', '14', '16', '33', '34'],
        hallOfFamers: ['Kareem Abdul-Jabbar', 'Oscar Robertson', 'Giannis Antetokounmpo'],
        rivalries: {
          'Chicago Bulls': 'Central Division rivalry',
          'Boston Celtics': 'Recent playoff rivalry'
        },
      ),
    );

    // Eastern Conference - Southeast Division
    _nbaTeams['Atlanta Hawks'] = NBATeam(
      name: 'Hawks',
      city: 'Atlanta',
      abbreviation: 'ATL',
      conference: 'Eastern',
      division: 'Southeast',
      branding: TeamBranding(
        primaryColor: '#E03A3E',
        secondaryColor: '#C1D32F',
        logoUrl: 'assets/logos/hawks.png',
        abbreviation: 'ATL',
        city: 'Atlanta',
        mascot: 'Harry the Hawk',
      ),
      history: TeamHistory(
        foundedYear: 1946,
        championships: 1,
        playoffAppearances: 48,
        retiredNumbers: ['9', '17', '21', '23', '44'],
        hallOfFamers: ['Dominique Wilkins', 'Bob Pettit'],
        rivalries: {
          'Boston Celtics': 'Historic playoff rivalry',
          'Miami Heat': 'Southeast Division rivalry'
        },
      ),
    );

    _nbaTeams['Charlotte Hornets'] = NBATeam(
      name: 'Hornets',
      city: 'Charlotte',
      abbreviation: 'CHA',
      conference: 'Eastern',
      division: 'Southeast',
      branding: TeamBranding(
        primaryColor: '#1D1160',
        secondaryColor: '#00788C',
        logoUrl: 'assets/logos/hornets.png',
        abbreviation: 'CHA',
        city: 'Charlotte',
        mascot: 'Hugo the Hornet',
      ),
      history: TeamHistory(
        foundedYear: 1988,
        championships: 0,
        playoffAppearances: 10,
        retiredNumbers: ['13'],
        hallOfFamers: [],
        rivalries: {
          'Miami Heat': 'Southeast Division rivalry'
        },
      ),
    );

    _nbaTeams['Miami Heat'] = NBATeam(
      name: 'Heat',
      city: 'Miami',
      abbreviation: 'MIA',
      conference: 'Eastern',
      division: 'Southeast',
      branding: TeamBranding(
        primaryColor: '#98002E',
        secondaryColor: '#F9A01B',
        logoUrl: 'assets/logos/heat.png',
        abbreviation: 'MIA',
        city: 'Miami',
        mascot: 'Burnie',
      ),
      history: TeamHistory(
        foundedYear: 1988,
        championships: 3,
        playoffAppearances: 22,
        retiredNumbers: ['1', '3', '6', '23', '33'],
        hallOfFamers: ['Dwyane Wade', 'Shaquille O\'Neal', 'LeBron James'],
        rivalries: {
          'Boston Celtics': 'Big 3 era rivalry',
          'New York Knicks': 'Playoff rivalry',
          'Chicago Bulls': 'LeBron era rivalry'
        },
      ),
    );

    _nbaTeams['Orlando Magic'] = NBATeam(
      name: 'Magic',
      city: 'Orlando',
      abbreviation: 'ORL',
      conference: 'Eastern',
      division: 'Southeast',
      branding: TeamBranding(
        primaryColor: '#0077C0',
        secondaryColor: '#C4CED4',
        logoUrl: 'assets/logos/magic.png',
        abbreviation: 'ORL',
        city: 'Orlando',
        mascot: 'Stuff the Magic Dragon',
      ),
      history: TeamHistory(
        foundedYear: 1989,
        championships: 0,
        playoffAppearances: 16,
        retiredNumbers: ['6'],
        hallOfFamers: ['Shaquille O\'Neal', 'Tracy McGrady'],
        rivalries: {
          'Miami Heat': 'Florida rivalry'
        },
      ),
    );

    _nbaTeams['Washington Wizards'] = NBATeam(
      name: 'Wizards',
      city: 'Washington',
      abbreviation: 'WAS',
      conference: 'Eastern',
      division: 'Southeast',
      branding: TeamBranding(
        primaryColor: '#002B5C',
        secondaryColor: '#E31837',
        logoUrl: 'assets/logos/wizards.png',
        abbreviation: 'WAS',
        city: 'Washington',
        mascot: 'G-Wiz',
      ),
      history: TeamHistory(
        foundedYear: 1961,
        championships: 1,
        playoffAppearances: 28,
        retiredNumbers: ['10', '11', '25', '41'],
        hallOfFamers: ['Elvin Hayes', 'Wes Unseld'],
        rivalries: {
          'Chicago Bulls': 'Jordan era rivalry'
        },
      ),
    );

    // Western Conference - Northwest Division
    _nbaTeams['Denver Nuggets'] = NBATeam(
      name: 'Nuggets',
      city: 'Denver',
      abbreviation: 'DEN',
      conference: 'Western',
      division: 'Northwest',
      branding: TeamBranding(
        primaryColor: '#0E2240',
        secondaryColor: '#FEC524',
        logoUrl: 'assets/logos/nuggets.png',
        abbreviation: 'DEN',
        city: 'Denver',
        mascot: 'Rocky the Mountain Lion',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 1,
        playoffAppearances: 38,
        retiredNumbers: ['2', '12', '33', '40', '44', '55'],
        hallOfFamers: ['Alex English', 'Dikembe Mutombo', 'Nikola Jokic'],
        rivalries: {
          'Utah Jazz': 'Mountain rivalry',
          'Los Angeles Lakers': 'Western Conference rivalry'
        },
      ),
    );

    _nbaTeams['Minnesota Timberwolves'] = NBATeam(
      name: 'Timberwolves',
      city: 'Minnesota',
      abbreviation: 'MIN',
      conference: 'Western',
      division: 'Northwest',
      branding: TeamBranding(
        primaryColor: '#0C2340',
        secondaryColor: '#236192',
        logoUrl: 'assets/logos/timberwolves.png',
        abbreviation: 'MIN',
        city: 'Minnesota',
        mascot: 'Crunch the Wolf',
      ),
      history: TeamHistory(
        foundedYear: 1989,
        championships: 0,
        playoffAppearances: 9,
        retiredNumbers: ['2', '21'],
        hallOfFamers: ['Kevin Garnett'],
        rivalries: {
          'Chicago Bulls': 'KG vs Jordan'
        },
      ),
    );

    _nbaTeams['Oklahoma City Thunder'] = NBATeam(
      name: 'Thunder',
      city: 'Oklahoma City',
      abbreviation: 'OKC',
      conference: 'Western',
      division: 'Northwest',
      branding: TeamBranding(
        primaryColor: '#007AC1',
        secondaryColor: '#EF3B24',
        logoUrl: 'assets/logos/thunder.png',
        abbreviation: 'OKC',
        city: 'Oklahoma City',
        mascot: 'Rumble the Bison',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 1,
        playoffAppearances: 11,
        retiredNumbers: ['1', '4'],
        hallOfFamers: ['Gary Payton', 'Shawn Kemp'],
        rivalries: {
          'Golden State Warriors': 'KD rivalry',
          'San Antonio Spurs': 'Western Conference rivalry'
        },
      ),
    );

    _nbaTeams['Portland Trail Blazers'] = NBATeam(
      name: 'Trail Blazers',
      city: 'Portland',
      abbreviation: 'POR',
      conference: 'Western',
      division: 'Northwest',
      branding: TeamBranding(
        primaryColor: '#E03A3E',
        secondaryColor: '#000000',
        logoUrl: 'assets/logos/blazers.png',
        abbreviation: 'POR',
        city: 'Portland',
        mascot: 'Blaze the Trail Cat',
      ),
      history: TeamHistory(
        foundedYear: 1970,
        championships: 1,
        playoffAppearances: 37,
        retiredNumbers: ['1', '13', '14', '15', '20', '22', '30', '32', '36', '77'],
        hallOfFamers: ['Bill Walton', 'Clyde Drexler', 'Damian Lillard'],
        rivalries: {
          'Los Angeles Lakers': 'Western Conference rivalry',
          'Seattle SuperSonics': 'Pacific Northwest rivalry'
        },
      ),
    );

    _nbaTeams['Utah Jazz'] = NBATeam(
      name: 'Jazz',
      city: 'Utah',
      abbreviation: 'UTA',
      conference: 'Western',
      division: 'Northwest',
      branding: TeamBranding(
        primaryColor: '#002B5C',
        secondaryColor: '#00471B',
        logoUrl: 'assets/logos/jazz.png',
        abbreviation: 'UTA',
        city: 'Utah',
        mascot: 'Jazz Bear',
      ),
      history: TeamHistory(
        foundedYear: 1974,
        championships: 0,
        playoffAppearances: 30,
        retiredNumbers: ['1', '4', '7', '12', '14', '32', '35', '53'],
        hallOfFamers: ['Karl Malone', 'John Stockton'],
        rivalries: {
          'Chicago Bulls': '90s Finals rivalry',
          'Houston Rockets': 'Western Conference rivalry'
        },
      ),
    );

    // Western Conference - Pacific Division
    _nbaTeams['Golden State Warriors'] = NBATeam(
      name: 'Warriors',
      city: 'Golden State',
      abbreviation: 'GSW',
      conference: 'Western',
      division: 'Pacific',
      branding: TeamBranding(
        primaryColor: '#1D428A',
        secondaryColor: '#FFC72C',
        logoUrl: 'assets/logos/warriors.png',
        abbreviation: 'GSW',
        city: 'Golden State',
        mascot: 'Thunder',
      ),
      history: TeamHistory(
        foundedYear: 1946,
        championships: 7,
        playoffAppearances: 36,
        retiredNumbers: ['13', '14', '16', '17', '24', '42'],
        hallOfFamers: ['Wilt Chamberlain', 'Rick Barry', 'Stephen Curry'],
        rivalries: {
          'Cleveland Cavaliers': '2010s Finals rivalry',
          'Los Angeles Lakers': 'California rivalry'
        },
      ),
    );

    _nbaTeams['Los Angeles Clippers'] = NBATeam(
      name: 'Clippers',
      city: 'Los Angeles',
      abbreviation: 'LAC',
      conference: 'Western',
      division: 'Pacific',
      branding: TeamBranding(
        primaryColor: '#C8102E',
        secondaryColor: '#1D428A',
        logoUrl: 'assets/logos/clippers.png',
        abbreviation: 'LAC',
        city: 'Los Angeles',
        mascot: 'Chuck the Condor',
      ),
      history: TeamHistory(
        foundedYear: 1970,
        championships: 0,
        playoffAppearances: 15,
        retiredNumbers: ['32'],
        hallOfFamers: ['Chris Paul'],
        rivalries: {
          'Los Angeles Lakers': 'Battle of LA',
          'Golden State Warriors': 'California rivalry'
        },
      ),
    );

    _nbaTeams['Los Angeles Lakers'] = NBATeam(
      name: 'Lakers',
      city: 'Los Angeles',
      abbreviation: 'LAL',
      conference: 'Western',
      division: 'Pacific',
      branding: TeamBranding(
        primaryColor: '#552583',
        secondaryColor: '#FDB927',
        logoUrl: 'assets/logos/lakers.png',
        abbreviation: 'LAL',
        city: 'Los Angeles',
        mascot: 'None',
      ),
      history: TeamHistory(
        foundedYear: 1947,
        championships: 17,
        playoffAppearances: 62,
        retiredNumbers: ['8', '24', '25', '32', '33', '34', '42', '44', '52'],
        hallOfFamers: ['Magic Johnson', 'Kareem Abdul-Jabbar', 'Kobe Bryant', 'Shaquille O\'Neal', 'LeBron James'],
        rivalries: {
          'Boston Celtics': 'Greatest NBA rivalry',
          'Los Angeles Clippers': 'Battle of LA',
          'San Antonio Spurs': 'Western Conference rivalry'
        },
      ),
    );

    _nbaTeams['Phoenix Suns'] = NBATeam(
      name: 'Suns',
      city: 'Phoenix',
      abbreviation: 'PHX',
      conference: 'Western',
      division: 'Pacific',
      branding: TeamBranding(
        primaryColor: '#1D1160',
        secondaryColor: '#E56020',
        logoUrl: 'assets/logos/suns.png',
        abbreviation: 'PHX',
        city: 'Phoenix',
        mascot: 'Go the Gorilla',
      ),
      history: TeamHistory(
        foundedYear: 1968,
        championships: 0,
        playoffAppearances: 29,
        retiredNumbers: ['5', '6', '7', '9', '24', '33', '34', '42', '44'],
        hallOfFamers: ['Charles Barkley', 'Steve Nash', 'Walter Davis'],
        rivalries: {
          'San Antonio Spurs': 'Western Conference rivalry',
          'Los Angeles Lakers': 'Pacific Division rivalry'
        },
      ),
    );

    _nbaTeams['Sacramento Kings'] = NBATeam(
      name: 'Kings',
      city: 'Sacramento',
      abbreviation: 'SAC',
      conference: 'Western',
      division: 'Pacific',
      branding: TeamBranding(
        primaryColor: '#5A2D81',
        secondaryColor: '#63727A',
        logoUrl: 'assets/logos/kings.png',
        abbreviation: 'SAC',
        city: 'Sacramento',
        mascot: 'Slamson the Lion',
      ),
      history: TeamHistory(
        foundedYear: 1945,
        championships: 1,
        playoffAppearances: 29,
        retiredNumbers: ['1', '6', '11', '12', '14', '16', '21', '27'],
        hallOfFamers: ['Oscar Robertson', 'Jerry Lucas'],
        rivalries: {
          'Los Angeles Lakers': 'Early 2000s playoff rivalry'
        },
      ),
    );

    // Western Conference - Southwest Division
    _nbaTeams['Dallas Mavericks'] = NBATeam(
      name: 'Mavericks',
      city: 'Dallas',
      abbreviation: 'DAL',
      conference: 'Western',
      division: 'Southwest',
      branding: TeamBranding(
        primaryColor: '#00538C',
        secondaryColor: '#002F5F',
        logoUrl: 'assets/logos/mavericks.png',
        abbreviation: 'DAL',
        city: 'Dallas',
        mascot: 'Mavs Man',
      ),
      history: TeamHistory(
        foundedYear: 1980,
        championships: 1,
        playoffAppearances: 22,
        retiredNumbers: ['12', '15', '22', '24'],
        hallOfFamers: ['Dirk Nowitzki'],
        rivalries: {
          'San Antonio Spurs': 'Texas rivalry',
          'Miami Heat': '2006/2011 Finals rivalry'
        },
      ),
    );

    _nbaTeams['Houston Rockets'] = NBATeam(
      name: 'Rockets',
      city: 'Houston',
      abbreviation: 'HOU',
      conference: 'Western',
      division: 'Southwest',
      branding: TeamBranding(
        primaryColor: '#CE1141',
        secondaryColor: '#000000',
        logoUrl: 'assets/logos/rockets.png',
        abbreviation: 'HOU',
        city: 'Houston',
        mascot: 'Clutch the Rocket Bear',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 2,
        playoffAppearances: 34,
        retiredNumbers: ['11', '22', '23', '24', '34', '45'],
        hallOfFamers: ['Hakeem Olajuwon', 'Yao Ming', 'Tracy McGrady'],
        rivalries: {
          'San Antonio Spurs': 'Texas rivalry',
          'Utah Jazz': 'Western Conference rivalry'
        },
      ),
    );

    _nbaTeams['Memphis Grizzlies'] = NBATeam(
      name: 'Grizzlies',
      city: 'Memphis',
      abbreviation: 'MEM',
      conference: 'Western',
      division: 'Southwest',
      branding: TeamBranding(
        primaryColor: '#5D76A9',
        secondaryColor: '#12173F',
        logoUrl: 'assets/logos/grizzlies.png',
        abbreviation: 'MEM',
        city: 'Memphis',
        mascot: 'Grizz',
      ),
      history: TeamHistory(
        foundedYear: 1995,
        championships: 0,
        playoffAppearances: 10,
        retiredNumbers: ['3', '50'],
        hallOfFamers: [],
        rivalries: {
          'San Antonio Spurs': 'Grit and Grind era rivalry'
        },
      ),
    );

    _nbaTeams['New Orleans Pelicans'] = NBATeam(
      name: 'Pelicans',
      city: 'New Orleans',
      abbreviation: 'NOP',
      conference: 'Western',
      division: 'Southwest',
      branding: TeamBranding(
        primaryColor: '#0C2340',
        secondaryColor: '#C8102E',
        logoUrl: 'assets/logos/pelicans.png',
        abbreviation: 'NOP',
        city: 'New Orleans',
        mascot: 'Pierre the Pelican',
      ),
      history: TeamHistory(
        foundedYear: 1988,
        championships: 0,
        playoffAppearances: 8,
        retiredNumbers: ['7', '23'],
        hallOfFamers: [],
        rivalries: {
          'Los Angeles Lakers': 'Anthony Davis trade rivalry'
        },
      ),
    );

    _nbaTeams['San Antonio Spurs'] = NBATeam(
      name: 'Spurs',
      city: 'San Antonio',
      abbreviation: 'SAS',
      conference: 'Western',
      division: 'Southwest',
      branding: TeamBranding(
        primaryColor: '#C4CED4',
        secondaryColor: '#000000',
        logoUrl: 'assets/logos/spurs.png',
        abbreviation: 'SAS',
        city: 'San Antonio',
        mascot: 'The Coyote',
      ),
      history: TeamHistory(
        foundedYear: 1967,
        championships: 5,
        playoffAppearances: 47,
        retiredNumbers: ['00', '6', '12', '13', '20', '21', '32', '44', '50'],
        hallOfFamers: ['Tim Duncan', 'David Robinson', 'Manu Ginobili', 'Tony Parker'],
        rivalries: {
          'Dallas Mavericks': 'Texas rivalry',
          'Houston Rockets': 'Texas rivalry',
          'Miami Heat': '2013/2014 Finals rivalry'
        },
      ),
    );
    
    _initialized = true;
  }

  /// Get all NBA teams
  static List<NBATeam> getAllNBATeams() {
    _initializeTeams();
    return _nbaTeams.values.toList();
  }

  /// Get team by name
  static NBATeam? getTeamByName(String name) {
    _initializeTeams();
    return _nbaTeams[name];
  }

  /// Get teams by conference
  static List<NBATeam> getTeamsByConference(String conference) {
    _initializeTeams();
    return _nbaTeams.values
        .where((team) => team.conference == conference)
        .toList();
  }

  /// Get teams by division
  static List<NBATeam> getTeamsByDivision(String division) {
    _initializeTeams();
    return _nbaTeams.values
        .where((team) => team.division == division)
        .toList();
  }

  /// Get team branding by name
  static TeamBranding? getTeamBranding(String teamName) {
    _initializeTeams();
    return _nbaTeams[teamName]?.branding;
  }

  /// Get all conference names
  static List<String> getConferences() {
    return ['Eastern', 'Western'];
  }

  /// Get all division names for a conference
  static List<String> getDivisions(String conference) {
    if (conference == 'Eastern') {
      return ['Atlantic', 'Central', 'Southeast'];
    } else if (conference == 'Western') {
      return ['Northwest', 'Pacific', 'Southwest'];
    }
    return [];
  }

  /// Get team abbreviations mapped to full names
  static Map<String, String> getTeamAbbreviations() {
    _initializeTeams();
    return Map.fromEntries(
      _nbaTeams.values.map((team) => MapEntry(team.abbreviation, team.fullName))
    );
  }
}