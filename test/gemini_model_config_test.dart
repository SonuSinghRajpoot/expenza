import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_expense_manager/data/repositories/gemini_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeminiRepository Model Configuration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns default model (gemini-3.7-flash) when no model is saved', () async {
      final repo = GeminiRepository();
      final model = await repo.getSelectedModel();
      expect(model, equals(GeminiRepository.defaultModel));
      expect(model, equals('gemini-3.7-flash'));
    });

    test('preset models list contains only modern Gemini versions', () {
      final presets = GeminiRepository.presetModels;
      expect(presets, contains('gemini-3.7-flash'));
      expect(presets, contains('gemini-2.5-flash'));
      expect(presets, contains('gemini-2.5-pro'));
      expect(presets.length, equals(3));
    });

    test('can save and retrieve a preset model', () async {
      final repo = GeminiRepository();
      await repo.setSelectedModel('gemini-3.7-flash');
      final model = await repo.getSelectedModel();
      expect(model, equals('gemini-3.7-flash'));
    });

    test('can save and retrieve a custom/future model', () async {
      final repo = GeminiRepository();
      await repo.setSelectedModel('gemini-3.7-pro');
      final model = await repo.getSelectedModel();
      expect(model, equals('gemini-3.7-pro'));
    });

    test('handles whitespace trimming when saving model name', () async {
      final repo = GeminiRepository();
      await repo.setSelectedModel('   gemini-4.0-flash   ');
      final model = await repo.getSelectedModel();
      expect(model, equals('gemini-4.0-flash'));
    });

    test('falls back to default model if saved model is empty or blank', () async {
      final repo = GeminiRepository();
      await repo.setSelectedModel('   ');
      final model = await repo.getSelectedModel();
      expect(model, equals(GeminiRepository.defaultModel));
    });
  });
}
