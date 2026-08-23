import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../models/user_profile.dart';
import '../../core/services/account_backup_service.dart';

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

      // Check persistent backup on fresh web session
      final restored = await AccountBackupService().autoRestoreIfEmpty();
      return restored.profile;
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }

    // SQLite table is empty (e.g. fresh install). Attempt auto-restore from persistent backup file!
    final restored = await AccountBackupService().autoRestoreIfEmpty();
    return restored.profile;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(profile.toMap()));
      await AccountBackupService().syncAccountBackup(profile: profile);
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

    // Automatically sync persistent local backup
    await AccountBackupService().syncAccountBackup(profile: profile);
  }
}
