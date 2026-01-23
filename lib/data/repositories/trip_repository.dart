import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../../models/trip.dart';
import '../../models/expense.dart';
import '../../models/advance.dart';

class TripRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Mock data for Web
  static List<Trip> _mockTrips = [];
  static bool _initialized = false;

  // Expense Methods
  Future<int> createExpense(Expense expense) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final newId = (_mockExpenses.lastOrNull?.id ?? 0) + 1;
      final tripExpenses = _mockExpenses.where((e) => e.tripId == expense.tripId).toList();
      final maxOrder = tripExpenses.fold<int>(-1, (m, e) {
        final o = e.displayOrder ?? -1;
        return o > m ? o : m;
      });
      final displayOrder = maxOrder + 1;
      final newExpense = expense.copyWith(id: newId, displayOrder: displayOrder);
      _mockExpenses.add(newExpense);
      await _saveMockData();
      return newId;
    }
    final db = await _dbHelper.database;
    final tripExpenses = await getExpenses(expense.tripId);
    final maxOrder = tripExpenses.fold<int>(-1, (m, e) {
      final o = e.displayOrder ?? -1;
      return o > m ? o : m;
    });
    final displayOrder = maxOrder + 1;
    final expenseMap = expense.toMap();
    expenseMap['display_order'] = displayOrder;
    return await db.insert('expenses', expenseMap);
  }

  Future<List<Expense>> getExpenses(int tripId) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final expenses = _mockExpenses.where((e) => e.tripId == tripId).toList();
      // Sort by displayOrder (nulls last), then by start_date DESC
      expenses.sort((a, b) {
        final aOrder = a.displayOrder ?? 999999;
        final bOrder = b.displayOrder ?? 999999;
        if (aOrder != bOrder) {
          return aOrder.compareTo(bOrder);
        }
        return b.startDate.compareTo(a.startDate);
      });
      return expenses;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'CASE WHEN display_order IS NULL THEN 1 ELSE 0 END, display_order ASC, start_date DESC',
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> deleteExpense(int id) async {
    if (kIsWeb) {
      await _ensureInitialized();
      _mockExpenses.removeWhere((e) => e.id == id);
      await _saveMockData();
      return;
    }
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateExpense(Expense expense) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockExpenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _mockExpenses[index] = expense;
        await _saveMockData();
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> updateExpensesOrder(List<Expense> expenses) async {
    if (kIsWeb) {
      await _ensureInitialized();
      for (int i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final index = _mockExpenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _mockExpenses[index] = expense.copyWith(displayOrder: i);
        }
      }
      await _saveMockData();
      return;
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      batch.update(
        'expenses',
        {'display_order': i},
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    }
    await batch.commit(noResult: true);
  }

  // Helper properties (mock expenses and advances)
  static List<Expense> _mockExpenses = [];
  static List<Advance> _mockAdvances = [];

  // Update _ensureInitialized to also load expenses
  Future<void> _ensureInitialized() async {
    if (kIsWeb && !_initialized) {
      final prefs = await SharedPreferences.getInstance();

      // Load Trips
      final String? tripsJson = prefs.getString('mock_trips');
      if (tripsJson != null) {
        final List<dynamic> decoded = jsonDecode(tripsJson);
        _mockTrips = decoded.map((e) => Trip.fromMap(e)).toList();
      }

      // Load Expenses
      final String? expensesJson = prefs.getString('mock_expenses');
      if (expensesJson != null) {
        final List<dynamic> decoded = jsonDecode(expensesJson);
        _mockExpenses = decoded.map((e) => Expense.fromMap(e)).toList();
        
        // Initialize displayOrder for expenses that don't have it
        final hasUninitializedBefore = _mockExpenses.any((e) => e.displayOrder == null);
        if (hasUninitializedBefore) {
          _initializeDisplayOrderForMockExpenses();
          // Save updated expenses after initialization
          await _saveMockData();
        }
      }

      // Load Advances
      final String? advancesJson = prefs.getString('mock_advances');
      if (advancesJson != null) {
        final List<dynamic> decoded = jsonDecode(advancesJson);
        _mockAdvances = decoded.map((e) => Advance.fromMap(e)).toList();
      }

      _initialized = true;
    }
  }

  void _initializeDisplayOrderForMockExpenses() {
    // Group expenses by trip_id
    final expensesByTrip = <int, List<Expense>>{};
    for (final expense in _mockExpenses) {
      if (expense.displayOrder == null) {
        expensesByTrip.putIfAbsent(expense.tripId, () => []).add(expense);
      }
    }

    // Sort by createdAt DESC within each trip and assign displayOrder
    for (final tripExpenses in expensesByTrip.values) {
      // Get current max displayOrder for this trip
      final tripId = tripExpenses.first.tripId;
      final existingExpenses = _mockExpenses
          .where((e) => e.tripId == tripId && e.displayOrder != null)
          .toList();
      int startOrder = existingExpenses.isEmpty
          ? 0
          : (existingExpenses.map((e) => e.displayOrder!).reduce((a, b) => a > b ? a : b) + 1);

      // Sort by createdAt DESC (newest first)
      tripExpenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Assign displayOrder
      for (int i = 0; i < tripExpenses.length; i++) {
        final expense = tripExpenses[i];
        final index = _mockExpenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _mockExpenses[index] = expense.copyWith(displayOrder: startOrder + i);
        }
      }
    }
  }

  // Update _saveMockData to also save expenses
  Future<void> _saveMockData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();

      // Save Trips
      final String encodedTrips = jsonEncode(
        _mockTrips.map((e) => e.toMap()).toList(),
      );
      await prefs.setString('mock_trips', encodedTrips);

      // Save Expenses
      final String encodedExpenses = jsonEncode(
        _mockExpenses.map((e) => e.toMap()).toList(),
      );
      await prefs.setString('mock_expenses', encodedExpenses);

      // Save Advances
      final String encodedAdvances = jsonEncode(
        _mockAdvances.map((e) => e.toMap()).toList(),
      );
      await prefs.setString('mock_advances', encodedAdvances);
    }
  }

  Future<int> createTrip(Trip trip) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final newId = _mockTrips.length + 1;
      final newTrip = trip.copyWith(id: newId);
      _mockTrips.add(newTrip);
      await _saveMockData();
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('trips', trip.toMap());
  }

  Future<List<Trip>> getTrips() async {
    if (kIsWeb) {
      await _ensureInitialized();
      final sorted = List<Trip>.from(_mockTrips);
      _sortTrips(sorted);
      return sorted;
    }
    final db = await _dbHelper.database;
    final maps = await db.query('trips', orderBy: 'start_date DESC, name ASC');
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  Future<List<Trip>> getActiveTrips() async {
    if (kIsWeb) {
      await _ensureInitialized();
      final filtered = _mockTrips
          .where((t) => t.status == 'Active' && !t.isArchived)
          .toList();
      _sortTrips(filtered);
      return filtered;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'trips',
      where: 'status = ? AND is_archived = 0',
      whereArgs: ['Active'],
      orderBy: 'start_date DESC, name ASC',
    );
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  void _sortTrips(List<Trip> trips) {
    trips.sort((a, b) {
      final dateCompare = b.startDate.compareTo(a.startDate);
      if (dateCompare != 0) return dateCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<int> updateTrip(Trip trip) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockTrips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _mockTrips[index] = trip;
        await _saveMockData();
        return 1;
      }
      return 0;
    }
    final db = await _dbHelper.database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> archiveTrip(int id) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockTrips.indexWhere((t) => t.id == id);
      if (index != -1) {
        _mockTrips[index] = _mockTrips[index].copyWith(
          status: 'Settled',
          isArchived: true,
        );
        await _saveMockData();
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'trips',
      {'status': 'Settled', 'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> submitTrip(int id) async {
    final now = DateTime.now();
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockTrips.indexWhere((t) => t.id == id);
      if (index != -1) {
        _mockTrips[index] = _mockTrips[index].copyWith(
          status: 'In-process',
          submittedAt: now,
        );
        await _saveMockData();
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'trips',
      {'status': 'In-process', 'submitted_at': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reopenTrip(int id) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockTrips.indexWhere((t) => t.id == id);
      if (index != -1) {
        _mockTrips[index] = _mockTrips[index].copyWith(
          status: 'Active',
          submittedAt: null,
          isArchived: false,
        );
        await _saveMockData();
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'trips',
      {'status': 'Active', 'submitted_at': null, 'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTripStatus(int id, String status) async {
    final now = DateTime.now();

    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockTrips.indexWhere((t) => t.id == id);
      if (index != -1) {
        final currentTrip = _mockTrips[index];
        DateTime? newSubmittedAt;

        // Update submitted_at based on status
        if (status == 'In-process') {
          newSubmittedAt = now;
        } else if (status == 'Active') {
          newSubmittedAt = null;
        } else if (status == 'Settled') {
          // Keep existing submittedAt if it exists
          newSubmittedAt = currentTrip.submittedAt ?? now;
        }

        _mockTrips[index] = currentTrip.copyWith(
          status: status,
          submittedAt: newSubmittedAt,
          lastModifiedAt: now,
          isArchived: status == 'Settled',
        );
        await _saveMockData();
      }
      return;
    }

    // For database, get current trip first to preserve submitted_at
    final db = await _dbHelper.database;
    final tripMaps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    
    if (tripMaps.isEmpty) return;
    
    final currentTrip = Trip.fromMap(tripMaps.first);
    final Map<String, dynamic> updates = {
      'status': status,
      'last_modified_at': now.toIso8601String(),
    };

    // Update submitted_at based on status
    if (status == 'In-process') {
      updates['submitted_at'] = now.toIso8601String();
    } else if (status == 'Active') {
      updates['submitted_at'] = null;
      updates['is_archived'] = 0;
    } else if (status == 'Settled') {
      updates['is_archived'] = 1;
      // Keep existing submitted_at if it exists, otherwise set to now
      if (currentTrip.submittedAt != null) {
        updates['submitted_at'] = currentTrip.submittedAt!.toIso8601String();
      } else {
        updates['submitted_at'] = now.toIso8601String();
      }
    }

    await db.update(
      'trips',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Advance Methods
  Future<int> createAdvance(Advance advance) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final newId = (_mockAdvances.lastOrNull?.id ?? 0) + 1;
      final newAdvance = advance.copyWith(id: newId);
      _mockAdvances.add(newAdvance);
      await _saveMockData();
      return newId;
    }
    final db = await _dbHelper.database;
    return await db.insert('advances', advance.toMap());
  }

  Future<List<Advance>> getAdvances(int tripId) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final advances = _mockAdvances.where((a) => a.tripId == tripId).toList();
      advances.sort((a, b) => b.date.compareTo(a.date));
      return advances;
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'advances',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Advance.fromMap(maps[i]));
  }

  Future<void> deleteAdvance(int id) async {
    if (kIsWeb) {
      await _ensureInitialized();
      _mockAdvances.removeWhere((a) => a.id == id);
      await _saveMockData();
      return;
    }
    final db = await _dbHelper.database;
    await db.delete('advances', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAdvance(Advance advance) async {
    if (kIsWeb) {
      await _ensureInitialized();
      final index = _mockAdvances.indexWhere((a) => a.id == advance.id);
      if (index != -1) {
        _mockAdvances[index] = advance;
        await _saveMockData();
      }
      return;
    }
    final db = await _dbHelper.database;
    await db.update(
      'advances',
      advance.toMap(),
      where: 'id = ?',
      whereArgs: [advance.id],
    );
  }

  // Debug/Dev only
  Future<void> deleteAllTrips() async {
    if (kIsWeb) {
      _mockTrips.clear();
      _mockExpenses.clear();
      _mockAdvances.clear();
      await _saveMockData();
      return;
    }
    final db = await _dbHelper.database;
    await db.delete('trips');
    await db.delete('expenses'); // Also clear expenses
    await db.delete('advances'); // Also clear advances
  }
}
