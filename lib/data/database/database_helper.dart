import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const _dbName = 'field_expenses_v1.db';
  static const _secureStorage = FlutterSecureStorage();
  static const _kDbPassKey = 'db_pass_key';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Store DB in Expenza/db (alongside bills) for better persistence.
    // This path is in application documents, not cache, so it survives "Clear cache".
    // Note: "Clear data" still removes everything - export regularly to backup.
    final appDoc = await getApplicationDocumentsDirectory();
    final dbDir = Directory(join(appDoc.path, 'Expenza', 'db'));
    if (!await dbDir.exists()) await dbDir.create(recursive: true);
    final path = join(dbDir.path, _dbName);

    // Migrate from old sqflite databases path if DB exists there and not in new location
    if (!await File(path).exists()) {
      final legacyDbPath = await getDatabasesPath();
      final legacyPath = join(legacyDbPath, _dbName);
      final legacyFile = File(legacyPath);
      if (await legacyFile.exists()) {
        await legacyFile.copy(path);
      }
    }

    // Ensure we have a secure encryption key
    String? password = await _secureStorage.read(key: _kDbPassKey);
    if (password == null) {
      // In a real app with Biometrics, we might ask the user to set a pin/password or generate one
      // and protect it with biometrics. For this phase, we generate a random key.
      password = _generateRandomPassword();
      await _secureStorage.write(key: _kDbPassKey, value: password);
    }

    return await openDatabase(
      path,
      version: 9,
      password: password, // SQLCipher encryption
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUserProfileTable(db);
    }
    if (oldVersion < 3) {
      // Add new fields for UserProfile
      await db.execute('ALTER TABLE user_profile ADD COLUMN nick_name TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN account_name TEXT');
      await db.execute(
        'ALTER TABLE user_profile ADD COLUMN account_number TEXT',
      );
      await db.execute('ALTER TABLE user_profile ADD COLUMN ifsc_code TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN bank_name TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN branch TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN upi_id TEXT');
      await db.execute('ALTER TABLE user_profile ADD COLUMN upi_name TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE user_profile ADD COLUMN company TEXT');
    }
    if (oldVersion < 4) {
      await _createGeminiKeysTable(db);
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE expenses ADD COLUMN to_city TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE expenses ADD COLUMN pax INTEGER');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE expenses ADD COLUMN display_order INTEGER');
      // Initialize displayOrder for existing expenses based on creation date
      await _initializeDisplayOrderForExistingExpenses(db);
    }
    if (oldVersion < 9) {
      await _createAdvancesTable(db);
    }
  }

  Future<void> _initializeDisplayOrderForExistingExpenses(Database db) async {
    // Get all expenses with NULL displayOrder, grouped by trip_id, ordered by created_at DESC
    final expenses = await db.query(
      'expenses',
      where: 'display_order IS NULL',
      orderBy: 'trip_id ASC, created_at DESC',
    );

    if (expenses.isEmpty) return;

    // Group by trip_id and assign displayOrder within each trip
    int? currentTripId;
    int orderIndex = 0;
    final batch = db.batch();

    for (final expense in expenses) {
      final tripId = expense['trip_id'] as int;
      
      // If we're starting a new trip, reset the order index
      if (currentTripId != tripId) {
        currentTripId = tripId;
        orderIndex = 0;
      }

      final expenseId = expense['id'] as int;
      batch.update(
        'expenses',
        {'display_order': orderIndex},
        where: 'id = ?',
        whereArgs: [expenseId],
      );

      orderIndex++;
    }

    await batch.commit(noResult: true);
  }

  Future<void> _createGeminiKeysTable(Database db) async {
    await db.execute('''
      CREATE TABLE gemini_keys (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        api_key TEXT NOT NULL,
        is_active INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _createUserProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        full_name TEXT NOT NULL,
        nick_name TEXT,
        employee_id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        whatsapp_number TEXT NOT NULL,
        company TEXT,
        is_whatsapp_same_as_phone INTEGER DEFAULT 0,
        profile_picture_base64 TEXT,
        account_name TEXT,
        account_number TEXT,
        ifsc_code TEXT,
        bank_name TEXT,
        branch TEXT,
        upi_id TEXT,
        upi_name TEXT
      )
    ''');
  }

  // Generate cryptographically secure random password
  String _generateRandomPassword() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Trip Table
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        project_name TEXT,
        cities TEXT, -- JSON Array of strings
        start_date TEXT NOT NULL,
        end_date TEXT,
        status TEXT NOT NULL, -- Active, In-process, Settled
        submitted_at TEXT,
        last_modified_at TEXT,
        is_archived INTEGER DEFAULT 0
      )
    ''');

    // Expense Table
    // Uniform schema as requested: start_date and end_date always present.
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        head TEXT NOT NULL,
        sub_head TEXT,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        city TEXT NOT NULL,
        to_city TEXT,
        pax INTEGER,
        amount REAL NOT NULL,
        bill_path TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        created_by TEXT,
        display_order INTEGER,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Index for performance
    await db.execute('CREATE INDEX idx_expenses_trip_id ON expenses(trip_id)');

    // Advances Table
    await _createAdvancesTable(db);

    // User Profile Table
    await _createUserProfileTable(db);

    // Gemini Keys Table
    await _createGeminiKeysTable(db);
  }

  Future<void> _createAdvancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE advances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips (id) ON DELETE CASCADE
      )
    ''');

    // Index for performance
    await db.execute('CREATE INDEX idx_advances_trip_id ON advances(trip_id)');
  }
}
