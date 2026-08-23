import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../models/gemini_key.dart';
import '../../data/repositories/gemini_repository.dart';
import '../../data/database/database_helper.dart';

/// Manages persistent local backup and auto-restore of all Account & Gemini settings.
/// Saves to external/public storage (Documents/Expenza and Download/Expenza) so that
/// configurations survive app uninstalls and can be automatically restored on new installs.
class AccountBackupService {
  static final AccountBackupService _instance =
      AccountBackupService._internal();
  factory AccountBackupService() => _instance;
  AccountBackupService._internal();

  static const String _configFileName = 'expenza_account_config.json';
  static const String _spBackupKey = 'local_account_backup_json';
  bool _isRestoring = false;

  /// Candidate directory paths for persistent storage on Android and desktop platforms.
  Future<List<Directory>> _getPersistentCandidateDirs() async {
    final dirs = <Directory>[];

    if (kIsWeb) return dirs;

    if (!kIsWeb && Platform.isAndroid) {
      // 1. Primary external Documents directory (survives app uninstall)
      final docDir = Directory('/storage/emulated/0/Documents/Expenza');
      dirs.add(docDir);

      // 2. Primary external Download directory (survives app uninstall)
      final downloadDir = Directory('/storage/emulated/0/Download/Expenza');
      dirs.add(downloadDir);

      // 3. Fallback via getExternalStorageDirectory()
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          // Walk up to root /storage/emulated/0/
          final rootDoc = Directory(
            p.join(
              ext.parent.parent.parent.parent.path,
              'Documents',
              'Expenza',
            ),
          );
          dirs.add(rootDoc);
        }
      } catch (_) {}
    }

    // Standard application documents directory fallback
    try {
      final appDoc = await getApplicationDocumentsDirectory();
      dirs.add(Directory(p.join(appDoc.path, 'Expenza', 'config')));
    } catch (_) {}

    return dirs;
  }

  /// Locates the existing backup file across candidate directories.
  Future<File?> getBackupFile() async {
    if (kIsWeb) return null;

    final candidates = await _getPersistentCandidateDirs();
    for (final dir in candidates) {
      try {
        final file = File(p.join(dir.path, _configFileName));
        if (await file.exists()) {
          return file;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Gets the last modified timestamp of the persistent backup.
  Future<DateTime?> getLastBackupTime() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_spBackupKey);
      if (savedJson != null) {
        try {
          final map = jsonDecode(savedJson) as Map<String, dynamic>;
          final timestamp = map['last_updated'] as String?;
          if (timestamp != null) return DateTime.tryParse(timestamp);
        } catch (_) {}
      }
      return null;
    }

    final file = await getBackupFile();
    if (file != null) {
      try {
        return await file.lastModified();
      } catch (_) {}
    }

    // Fallback to SharedPreferences if file is unavailable (e.g., in unit tests or storage permission pending)
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_spBackupKey);
      if (savedJson != null) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        final timestamp = map['last_updated'] as String?;
        if (timestamp != null) return DateTime.tryParse(timestamp);
      }
    } catch (_) {}

    return null;
  }

  /// Synchronizes full Account profile + Gemini settings into persistent local storage.
  Future<void> syncAccountBackup({
    UserProfile? profile,
    List<GeminiKey>? keys,
    String? activeModel,
  }) async {
    if (_isRestoring) return; // Prevent loop during restore

    try {
      // 1. Fetch current profile if not provided
      UserProfile? currentProfile = profile;
      if (currentProfile == null && !kIsWeb) {
        try {
          final db = await DatabaseHelper().database;
          final maps = await db.query('user_profile', limit: 1);
          if (maps.isNotEmpty) {
            currentProfile = UserProfile.fromMap(maps.first);
          }
        } catch (_) {}
      }

      // 2. Fetch current Gemini keys if not provided
      List<GeminiKey>? currentKeys = keys;
      if (currentKeys == null) {
        try {
          currentKeys = await GeminiRepository().getKeys();
        } catch (_) {
          currentKeys = [];
        }
      }

      // 3. Fetch active Gemini model if not provided
      String? currentModel = activeModel;
      if (currentModel == null) {
        try {
          currentModel = await GeminiRepository().getSelectedModel();
        } catch (_) {}
      }

      // Don't save empty/useless backups
      if (currentProfile == null && (currentKeys.isEmpty)) {
        return;
      }

      final backupData = {
        'version': 1,
        'app_name': 'Expenza',
        'last_updated': DateTime.now().toIso8601String(),
        'user_profile': currentProfile?.toMap(),
        'gemini_config': {
          'active_model': currentModel ?? GeminiRepository.defaultModel,
          'keys': currentKeys.map((k) => k.toMap()).toList(),
        },
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      // Web / SharedPreferences backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spBackupKey, jsonStr);

      if (kIsWeb) return;

      // Write to persistent external storage directories
      final candidateDirs = await _getPersistentCandidateDirs();
      for (final dir in candidateDirs) {
        try {
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          final file = File(p.join(dir.path, _configFileName));
          await file.writeAsString(jsonStr, flush: true);
        } catch (e) {
          debugPrint('AccountBackupService: failed writing to ${dir.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('AccountBackupService.syncAccountBackup error: $e');
    }
  }

  /// Automatically restores profile and keys if the local SQLite DB is empty.
  Future<({
    bool restored,
    UserProfile? profile,
    List<GeminiKey>? keys,
    String? activeModel,
  })> autoRestoreIfEmpty() async {
    if (_isRestoring) {
      return (restored: false, profile: null, keys: null, activeModel: null);
    }

    try {
      final backupData = await _readBackupData();
      if (backupData == null) {
        return (restored: false, profile: null, keys: null, activeModel: null);
      }

      _isRestoring = true;
      UserProfile? restoredProfile;
      List<GeminiKey> restoredKeys = [];
      String? restoredModel;

      // 1. Restore User Profile
      if (backupData['user_profile'] != null) {
        final profileMap =
            Map<String, dynamic>.from(backupData['user_profile'] as Map);
        restoredProfile = UserProfile.fromMap(profileMap);

        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(profileMap));
        } else {
          try {
            final db = await DatabaseHelper().database;
            final existing = await db.query('user_profile', limit: 1);
            if (existing.isEmpty) {
              await db.insert('user_profile', restoredProfile.toMap());
            }
          } catch (e) {
            debugPrint('AccountBackupService: database insert profile skipped ($e)');
          }
        }
      }

      // 2. Restore Gemini Configuration
      if (backupData['gemini_config'] != null) {
        final geminiMap =
            Map<String, dynamic>.from(backupData['gemini_config'] as Map);

        // Active Model
        restoredModel = geminiMap['active_model'] as String?;
        if (restoredModel != null && restoredModel.isNotEmpty) {
          try {
            await GeminiRepository().setSelectedModel(restoredModel);
          } catch (_) {}
        }

        // Keys
        if (geminiMap['keys'] != null) {
          final rawKeys = geminiMap['keys'] as List;
          try {
            final geminiRepo = GeminiRepository();
            final existingKeys = await geminiRepo.getKeys();

            if (existingKeys.isEmpty) {
              for (final rawKey in rawKeys) {
                final keyObj =
                    GeminiKey.fromMap(Map<String, dynamic>.from(rawKey as Map));
                restoredKeys.add(keyObj);
                await geminiRepo.saveKey(keyObj);
              }
            } else {
              restoredKeys = existingKeys;
            }
          } catch (_) {
            for (final rawKey in rawKeys) {
              final keyObj =
                  GeminiKey.fromMap(Map<String, dynamic>.from(rawKey as Map));
              restoredKeys.add(keyObj);
            }
          }
        }
      }

      _isRestoring = false;
      return (
        restored: true,
        profile: restoredProfile,
        keys: restoredKeys,
        activeModel: restoredModel,
      );
    } catch (e) {
      _isRestoring = false;
      debugPrint('AccountBackupService.autoRestoreIfEmpty error: $e');
      return (restored: false, profile: null, keys: null, activeModel: null);
    }
  }

  /// Manually restores account profile and Gemini keys from the persistent backup file.
  Future<({
    bool restored,
    UserProfile? profile,
    List<GeminiKey>? keys,
    String? activeModel,
  })> manualRestore() async {
    try {
      final backupData = await _readBackupData();
      if (backupData == null) {
        return (restored: false, profile: null, keys: null, activeModel: null);
      }

      _isRestoring = true;
      UserProfile? restoredProfile;
      List<GeminiKey> restoredKeys = [];
      String? restoredModel;

      // Restore User Profile
      if (backupData['user_profile'] != null) {
        final profileMap =
            Map<String, dynamic>.from(backupData['user_profile'] as Map);
        restoredProfile = UserProfile.fromMap(profileMap);

        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(profileMap));
        } else {
          final db = await DatabaseHelper().database;
          await db.delete('user_profile');
          await db.insert('user_profile', restoredProfile.toMap());
        }
      }

      // Restore Gemini Config
      if (backupData['gemini_config'] != null) {
        final geminiMap =
            Map<String, dynamic>.from(backupData['gemini_config'] as Map);

        restoredModel = geminiMap['active_model'] as String?;
        if (restoredModel != null && restoredModel.isNotEmpty) {
          await GeminiRepository().setSelectedModel(restoredModel);
        }

        if (geminiMap['keys'] != null) {
          final rawKeys = geminiMap['keys'] as List;
          final geminiRepo = GeminiRepository();

          if (!kIsWeb) {
            final db = await DatabaseHelper().database;
            await db.delete('gemini_keys');
          }

          for (final rawKey in rawKeys) {
            final keyObj =
                GeminiKey.fromMap(Map<String, dynamic>.from(rawKey as Map));
            restoredKeys.add(keyObj);
            await geminiRepo.saveKey(keyObj);
          }
        }
      }

      _isRestoring = false;
      return (
        restored: true,
        profile: restoredProfile,
        keys: restoredKeys,
        activeModel: restoredModel,
      );
    } catch (e) {
      _isRestoring = false;
      debugPrint('AccountBackupService.manualRestore error: $e');
      return (restored: false, profile: null, keys: null, activeModel: null);
    }
  }

  /// Internal helper to read backup data from file or SharedPreferences.
  Future<Map<String, dynamic>?> _readBackupData() async {
    // 1. Check persistent file first
    final file = await getBackupFile();
    if (file != null) {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('AccountBackupService: failed reading file: $e');
      }
    }

    // 2. Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_spBackupKey);
    if (savedJson != null && savedJson.trim().isNotEmpty) {
      try {
        return jsonDecode(savedJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    return null;
  }
}
