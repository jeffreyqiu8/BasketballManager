import 'package:BasketballManager/gameData/team_generation_service.dart';
import 'package:BasketballManager/gameData/nba_team_data.dart';
import 'package:BasketballManager/gameData/enhanced_team.dart';
import 'package:BasketballManager/gameData/enhanced_conference.dart';
import 'package:BasketballManager/gameData/game_class.dart';
import 'package:BasketballManager/gameData/coach_class.dart';
import 'package:BasketballManager/gameData/nba_conference_service.dart';

void populateTeamsWithPlayers(EnhancedConference conference) {
  final nbaTeams = RealTeamData.getAllNBATeams();
  
  for (int i = 0; i < conference.teams.length && i < nbaTeams.length; i++) {
    final team = conference.teams[i];
    final nbaTeam = nbaTeams[i];
    
    if (team is EnhancedTeam && team.players.isEmpty) {
      try {
        final generatedTeam = TeamGenerationService.generateNBATeamRoster(nbaTeam);
        team.players = generatedTeam.players;
        team.playerCount = generatedTeam.players.length;
        team.roleAssignments = Map.from(generatedTeam.roleAssignments);
        team.starters = List.from(generatedTeam.starters);
      } catch (e) {
        print('Error generating team ${team.name}: $e');
      }
    }
  }
}

void main() {
  print('Testing save/load process...');
  
  final conferences = NBAConferenceService.createNBAConferences();
  final conference = conferences.values.first;
  
  populateTeamsWithPlayers(conference);
  
  final manager = Manager(
    name: 'Test Manager',
    age: 30,
    team: 0,
    experienceYears: 5,
    nationality: 'USA',
    currentStatus: 'Active',
  );
  
  final game = Game(
    currentManager: manager,
    currentConference: conference,
  );
  
  print('Original managed team: ${conference.teams[0].name}');
  print('Original managed team players: ${conference.teams[0].players.length}');
  if (conference.teams[0].players.isNotEmpty) {
    print('First player: ${conference.teams[0].players.first.name}');
  }
  
  print('\n--- Testing Lightweight Save ---');
  final lightweightData = game.toLightweightMap();
  
  final divisions = lightweightData['currentConference']['divisions'] as List;
  bool foundManagedTeamData = false;
  for (var division in divisions) {
    final teams = division['teams'] as List;
    for (var team in teams) {
      if (team['fullTeamData'] != null) {
        foundManagedTeamData = true;
        print('Found managed team full data for: ${team['name']}');
        final fullData = team['fullTeamData'];
        if (fullData['players'] != null) {
          final players = fullData['players'] as List;
          print('Saved players count: ${players.length}');
        }
      }
    }
  }
  
  if (!foundManagedTeamData) {
    print('ERROR: No managed team full data found in save!');
  }
  
  print('\n--- Testing Load ---');
  final loadedGame = Game.fromMap(lightweightData);
  print('Loaded managed team: ${loadedGame.currentConference.teams[0].name}');
  print('Loaded managed team players: ${loadedGame.currentConference.teams[0].players.length}');
  if (loadedGame.currentConference.teams[0].players.isEmpty) {
    print('ERROR: No players loaded for managed team!');
  }
}