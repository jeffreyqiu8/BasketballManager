import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

/// Service for managing local save files
/// Handles save, load, list, and delete operations using shared_preferences
class SaveService {
  static const String _savesListKey = 'saves_list';
  static const String _savePrefix = 'save_';

  /// Save game state to local storage
  /// Returns true if save was successful, false otherwise
  Future<bool> saveGame(String saveName, GameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert game state to JSON string
      final jsonString = jsonEncode(state.toJson());

      // Save the game state
      final saveKey = '$_savePrefix$saveName';
      await prefs.setString(saveKey, jsonString);

      // Update saves list
      final savesList = await listSaves();
      if (!savesList.contains(saveName)) {
        savesList.add(saveName);
        await prefs.setStringList(_savesListKey, savesList);
      }

      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  /// Load game state from local storage
  /// Returns GameState if successful, null if save doesn't exist or error occurs
  Future<GameState?> loadGame(String saveName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the saved game state
      final saveKey = '$_savePrefix$saveName';
      final jsonString = prefs.getString(saveKey);

      if (jsonString == null) {
        return null;
      }

      // Parse JSON and create GameState
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameState.fromJson(jsonMap);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }

  /// List all save file names
  /// Returns list of save names (empty list if none exist)
  Future<List<String>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savesList = prefs.getStringList(_savesListKey);
      return savesList ?? [];
    } catch (e) {
      print('Error listing saves: $e');
      return [];
    }
  }

  /// Delete a save file from local storage
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteSave(String saveName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove the save data
      final saveKey = '$_savePrefix$saveName';
      await prefs.remove(saveKey);

      // Update saves list
      final savesList = await listSaves();
      savesList.remove(saveName);
      await prefs.setStringList(_savesListKey, savesList);

      return true;
    } catch (e) {
      print('Error deleting save: $e');
      return false;
    }
  }

  /// Check if a save exists
  Future<bool> saveExists(String saveName) async {
    final saves = await listSaves();
    return saves.contains(saveName);
  }
}
