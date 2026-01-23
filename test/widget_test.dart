import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_expense_manager/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: FieldExpenseApp()));

    // Phase 1 Smoke Test: Just verify the App Bar title exists
    expect(find.text('My Trips'), findsOneWidget);
    expect(
      find.text('New Trip'),
      findsNothing,
    ); // FAB label not found initially
  });
}
