import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../models/gemini_key.dart';
import '../../core/services/account_backup_service.dart';

class GeminiRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _keysKey = 'gemini_keys';
  static const String _modelKey = 'gemini_model_version';

  static const String defaultModel = 'gemini-3.7-flash';
  static const List<String> presetModels = [
    'gemini-3.7-flash',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_modelKey);
    if (saved != null && saved.trim().isNotEmpty) {
      return saved.trim();
    }
    return defaultModel;
  }

  Future<void> setSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model.trim());
    await AccountBackupService().syncAccountBackup(activeModel: model.trim());
  }

  Future<List<GeminiKey>> getKeys() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final String? keysJson = prefs.getString(_keysKey);
      if (keysJson != null) {
        final List<dynamic> decoded = jsonDecode(keysJson);
        return decoded.map((item) => GeminiKey.fromMap(item)).toList();
      }

      // Check persistent backup on fresh web session
      final restored = await AccountBackupService().autoRestoreIfEmpty();
      return restored.keys ?? [];
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('gemini_keys');
    if (maps.isNotEmpty) {
      return maps.map((item) => GeminiKey.fromMap(item)).toList();
    }

    // SQLite table is empty (e.g. fresh install). Attempt auto-restore from persistent backup!
    final restored = await AccountBackupService().autoRestoreIfEmpty();
    return restored.keys ?? [];
  }

  Future<void> saveKey(GeminiKey key) async {
    if (kIsWeb) {
      final keys = await getKeys();
      final index = keys.indexWhere((k) => k.id == key.id);

      // If setting this one to active, deactivate others
      if (key.isActive) {
        for (var i = 0; i < keys.length; i++) {
          keys[i] = keys[i].copyWith(isActive: false);
        }
      }

      if (index >= 0) {
        keys[index] = key;
      } else {
        keys.add(key);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keysKey,
        jsonEncode(keys.map((k) => k.toMap()).toList()),
      );
      await AccountBackupService().syncAccountBackup(keys: keys);
      return;
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      if (key.isActive) {
        await txn.update('gemini_keys', {'is_active': 0});
      }

      final existing = await txn.query(
        'gemini_keys',
        where: 'id = ?',
        whereArgs: [key.id],
      );

      if (existing.isEmpty) {
        await txn.insert('gemini_keys', key.toMap());
      } else {
        await txn.update(
          'gemini_keys',
          key.toMap(),
          where: 'id = ?',
          whereArgs: [key.id],
        );
      }
    });

    final updatedKeys = await getKeys();
    await AccountBackupService().syncAccountBackup(keys: updatedKeys);
  }

  Future<void> deleteKey(String id) async {
    if (kIsWeb) {
      final keys = await getKeys();
      keys.removeWhere((k) => k.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keysKey,
        jsonEncode(keys.map((k) => k.toMap()).toList()),
      );
      await AccountBackupService().syncAccountBackup(keys: keys);
      return;
    }

    final db = await _dbHelper.database;
    await db.delete('gemini_keys', where: 'id = ?', whereArgs: [id]);
    final updatedKeys = await getKeys();
    await AccountBackupService().syncAccountBackup(keys: updatedKeys);
  }

  Future<void> setActive(String id) async {
    if (kIsWeb) {
      final keys = await getKeys();
      for (var i = 0; i < keys.length; i++) {
        keys[i] = keys[i].copyWith(isActive: keys[i].id == id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keysKey,
        jsonEncode(keys.map((k) => k.toMap()).toList()),
      );
      await AccountBackupService().syncAccountBackup(keys: keys);
      return;
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('gemini_keys', {'is_active': 0});
      await txn.update(
        'gemini_keys',
        {'is_active': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });

    final updatedKeys = await getKeys();
    await AccountBackupService().syncAccountBackup(keys: updatedKeys);
  }
}
