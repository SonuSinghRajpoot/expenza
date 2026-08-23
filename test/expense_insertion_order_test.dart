import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/data/repositories/trip_repository.dart';
import 'package:field_expense_manager/models/expense.dart';

void main() {
  Expense makeExpense({
    required int id,
    required DateTime date,
    int? displayOrder,
    String head = 'Food',
  }) {
    return Expense(
      id: id,
      tripId: 1,
      head: head,
      startDate: date,
      endDate: date,
      city: 'Delhi',
      amount: 100.0,
      createdAt: DateTime.now(),
      displayOrder: displayOrder,
    );
  }

  group('TripRepository.calculateInsertionIndex', () {
    test('returns 0 when existing list is empty', () {
      final existing = <Expense>[];
      final targetDate = DateTime(2026, 10, 12);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      expect(index, equals(0));
    });

    test('inserts at 0 when new date is earlier than all existing', () {
      final existing = [
        makeExpense(id: 1, date: DateTime(2026, 10, 12), displayOrder: 0),
        makeExpense(id: 2, date: DateTime(2026, 10, 14), displayOrder: 1),
      ];
      final targetDate = DateTime(2026, 10, 10);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      expect(index, equals(0));
    });

    test('inserts at end when new date is later than all existing', () {
      final existing = [
        makeExpense(id: 1, date: DateTime(2026, 10, 10), displayOrder: 0),
        makeExpense(id: 2, date: DateTime(2026, 10, 12), displayOrder: 1),
      ];
      final targetDate = DateTime(2026, 10, 15);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      expect(index, equals(2));
    });

    test('inserts in between different dates', () {
      final existing = [
        makeExpense(id: 1, date: DateTime(2026, 10, 10), displayOrder: 0),
        makeExpense(id: 2, date: DateTime(2026, 10, 14), displayOrder: 1),
      ];
      final targetDate = DateTime(2026, 10, 12);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      expect(index, equals(1));
    });

    test('inserts after all same-day expenses (FIFO on same day)', () {
      final existing = [
        makeExpense(id: 1, date: DateTime(2026, 10, 10), displayOrder: 0),
        makeExpense(id: 2, date: DateTime(2026, 10, 12, 8, 30), displayOrder: 1), // Breakfast
        makeExpense(id: 3, date: DateTime(2026, 10, 12, 13, 0), displayOrder: 2), // Lunch
        makeExpense(id: 4, date: DateTime(2026, 10, 14), displayOrder: 3),
      ];
      // Adding Dinner on Oct 12
      final targetDate = DateTime(2026, 10, 12, 20, 0);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      // Must be inserted at index 3 (after Oct 12 Lunch, before Oct 14)
      expect(index, equals(3));
    });

    test('ignores time component when comparing calendar dates', () {
      final existing = [
        makeExpense(id: 1, date: DateTime(2026, 10, 12, 23, 59), displayOrder: 0),
      ];
      // Adding an expense with earlier time on same calendar day
      final targetDate = DateTime(2026, 10, 12, 6, 0);
      final index = TripRepository.calculateInsertionIndex(existing, targetDate);
      // Because it's on the same day, it should be appended after the existing Oct 12 entry (FIFO)
      expect(index, equals(1));
    });
  });
}
