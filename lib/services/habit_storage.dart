import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

/// Local persistence for habits. Stores the whole list as one JSON string.
class HabitStorage {
  static const String _key = 'habits';

  static Future<List<Habit>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((e) => Habit.fromJson(e)).toList();
  }

  static Future<void> save(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
