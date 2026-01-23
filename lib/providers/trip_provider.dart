import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/trip_repository.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import '../models/advance.dart';

final tripRepositoryProvider = Provider((ref) => TripRepository());

final citySuggestionsProvider = Provider<List<String>>((ref) {
  final tripsAsync = ref.watch(tripListProvider);
  return tripsAsync.maybeWhen(
    data: (trips) {
      final cities = <String>{};
      for (final trip in trips) {
        cities.addAll(trip.cities);
      }
      final sortedList = cities.toList()..sort();
      return sortedList;
    },
    orElse: () => [],
  );
});

final tripListProvider = AsyncNotifierProvider<TripListNotifier, List<Trip>>(
  () {
    return TripListNotifier();
  },
);

class TripListNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    final repository = ref.read(tripRepositoryProvider);
    return repository.getTrips();
  }

  Future<void> addTrip(Trip trip) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.createTrip(trip);
      return repository.getTrips();
    });
  }

  Future<void> archiveTrip(int tripId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.archiveTrip(tripId);
      return repository.getTrips();
    });
  }

  Future<void> submitTrip(int tripId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.submitTrip(tripId);
      return repository.getTrips();
    });
  }

  Future<void> reopenTrip(int tripId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.reopenTrip(tripId);
      return repository.getTrips();
    });
  }

  Future<void> updateTrip(Trip trip) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.updateTrip(trip);
      return repository.getTrips();
    });
  }

  Future<void> updateTripStatus(int tripId, String status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(tripRepositoryProvider);
      await repository.updateTripStatus(tripId, status);
      return repository.getTrips();
    });
  }
}

final expensesProvider =
    AsyncNotifierProvider.family<ExpensesNotifier, List<Expense>, int>(
      (arg) => ExpensesNotifier(arg),
    );

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  final int tripId;
  ExpensesNotifier(this.tripId);

  @override
  Future<List<Expense>> build() async {
    final repository = ref.read(tripRepositoryProvider);
    return repository.getExpenses(tripId);
  }

  Future<void> addExpense(Expense expense) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.createExpense(expense);
    // Refresh the list after adding
    state = await AsyncValue.guard(() => repository.getExpenses(tripId));
  }

  Future<void> deleteExpense(int expenseId) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.deleteExpense(expenseId);
    state = await AsyncValue.guard(() => repository.getExpenses(tripId));
  }

  Future<void> updateExpense(Expense expense) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.updateExpense(expense);
    state = await AsyncValue.guard(() => repository.getExpenses(tripId));
  }

  Future<void> reorderExpenses(List<Expense> reorderedExpenses) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.updateExpensesOrder(reorderedExpenses);
    state = await AsyncValue.guard(() => repository.getExpenses(tripId));
  }
}

final tripTotalAmountProvider = Provider.family<double, int>((ref, tripId) {
  final expensesAsync = ref.watch(expensesProvider(tripId));
  return expensesAsync.maybeWhen(
    data: (expenses) => expenses.fold(0.0, (sum, item) => sum + item.amount),
    orElse: () => 0.0,
  );
});

final advancesProvider =
    AsyncNotifierProvider.family<AdvancesNotifier, List<Advance>, int>(
      (arg) => AdvancesNotifier(arg),
    );

class AdvancesNotifier extends AsyncNotifier<List<Advance>> {
  final int tripId;
  AdvancesNotifier(this.tripId);

  @override
  Future<List<Advance>> build() async {
    final repository = ref.read(tripRepositoryProvider);
    return repository.getAdvances(tripId);
  }

  Future<void> addAdvance(Advance advance) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.createAdvance(advance);
    // Refresh the list after adding
    state = await AsyncValue.guard(() => repository.getAdvances(tripId));
  }

  Future<void> deleteAdvance(int advanceId) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.deleteAdvance(advanceId);
    state = await AsyncValue.guard(() => repository.getAdvances(tripId));
  }

  Future<void> updateAdvance(Advance advance) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.updateAdvance(advance);
    state = await AsyncValue.guard(() => repository.getAdvances(tripId));
  }
}
