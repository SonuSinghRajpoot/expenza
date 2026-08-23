import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_expense_manager/main.dart';
import 'package:field_expense_manager/core/services/biometric_service.dart';

void main() {
  testWidgets('App root smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with unlocked session
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAppUnlockedProvider.overrideWith((ref) => true),
        ],
        child: const FieldExpenseApp(),
      ),
    );
    await tester.pump();

    // Smoke Test: Verify that the app launches and displays the dashboard
    expect(find.byType(FieldExpenseApp), findsOneWidget);
  });
}
