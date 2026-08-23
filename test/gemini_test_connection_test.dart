import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiService.testConnection', () {
    test('returns failure immediately when API key is empty', () async {
      final service = GeminiService();
      final result = await service.testConnection(apiKey: '');
      expect(result.success, isFalse);
      expect(result.message, contains('API key cannot be empty'));
    });

    test('returns failure immediately when API key is whitespace only', () async {
      final service = GeminiService();
      final result = await service.testConnection(apiKey: '   ');
      expect(result.success, isFalse);
      expect(result.message, contains('API key cannot be empty'));
    });
  });
}
