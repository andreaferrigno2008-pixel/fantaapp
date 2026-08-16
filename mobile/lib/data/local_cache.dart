import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/player.dart';

// Cache locale minima (SharedPreferences) per consultare l'ultima lista
// giocatori sincronizzata anche senza connessione al backend.
class LocalCache {
  static const _playersKey = 'cached_players';
  static const _lastSyncKey = 'cached_players_last_sync';

  Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = players.map((p) => p.toCacheJson()).toList();
    await prefs.setString(_playersKey, jsonEncode(jsonList));
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playersKey);
    if (raw == null) return [];
    final jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList.map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DateTime?> lastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw != null ? DateTime.parse(raw) : null;
  }
}
