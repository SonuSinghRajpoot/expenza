import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../models/user_profile.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _profileKey = 'user_profile';

  Future<UserProfile?> getUserProfile() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        return UserProfile.fromMap(jsonDecode(profileJson));
      }
      return null;
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toMap()));
      return;
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );

    if (maps.isEmpty) {
      await db.insert('user_profile', profile.toMap());
    } else {
      await db.update(
        'user_profile',
        profile.toMap(),
        where: 'employee_id = ?',
        whereArgs: [maps.first['employee_id']],
      );
    }
  }
}
