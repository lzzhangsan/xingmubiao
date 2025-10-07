import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalDataStore {
  LocalDataStore._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    await init();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await init();
    await _prefs!.setString(key, jsonEncode(value));
  }

  static Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  static Future<void> clearKey(String key) async {
    await init();
    await _prefs!.remove(key);
  }
}
