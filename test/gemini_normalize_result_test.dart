import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/services/gemini_service.dart';

void main() {
  group('GeminiService.normalizeResult', () {
    test('resolves cities from names and codes', () {
      final r = GeminiService.normalizeResult({
        'head': 'Travel',
        'subHead': 'Flight',
        'fromCity': 'Indira Gandhi International Airport',
        'fromCode': 'DEL',
        'toCity': 'Bombay',
        'amount': 5230,
      });
      expect(r['fromCity'], 'Delhi');
      expect(r['toCity'], 'Mumbai');
      expect(r['rawFromCity'], isNull);
      expect(r['rawToCity'], isNull);
    });

    test('drops unrecognised cities but keeps the raw text for a hint', () {
      final r = GeminiService.normalizeResult({
        'head': 'Travel',
        'subHead': 'Cab',
        'fromCity': 'Terminal 1D',
        'toCity': 'Sector 18',
      });
      expect(r['fromCity'], isNull);
      expect(r['toCity'], isNull);
      expect(r['rawFromCity'], 'Terminal 1D');
      expect(r['rawToCity'], 'Sector 18');
    });

    test('toCity is only kept for travel', () {
      final r = GeminiService.normalizeResult({
        'head': 'Food',
        'subHead': 'Lunch',
        'fromCity': 'Pune',
        'toCity': 'Mumbai',
      });
      expect(r['fromCity'], 'Pune');
      expect(r['toCity'], isNull);
      expect(r['rawToCity'], isNull);
    });

    test('sub-head must belong to the head', () {
      final r = GeminiService.normalizeResult({'head': 'food', 'subHead': 'Flight'});
      expect(r['head'], 'Food');
      expect(r['subHead'], isNull);

      final ok = GeminiService.normalizeResult({'head': 'Travel', 'subHead': 'flight'});
      expect(ok['subHead'], 'Flight');
    });

    test('unknown head gives null head and sub-head', () {
      final r = GeminiService.normalizeResult({'head': 'Shopping', 'subHead': 'Cab'});
      expect(r['head'], isNull);
      expect(r['subHead'], isNull);
    });

    test('amount, dates and pax are validated', () {
      final r = GeminiService.normalizeResult({
        'head': 'Accommodation',
        'amount': '1,234.50',
        'date': '2026-02-30',
        'endDate': '2026-03-02',
        'pax': 0,
      });
      expect(r['amount'], 1234.5);
      expect(r['date'], isNull);
      expect(r['endDate'], '2026-03-02');
      expect(r['pax'], isNull);

      final r2 = GeminiService.normalizeResult({'amount': -5, 'pax': '2'});
      expect(r2['amount'], isNull);
      expect(r2['pax'], 2);
    });

    test('trip cities help resolve close spellings', () {
      final r = GeminiService.normalizeResult(
        {'head': 'Food', 'fromCity': 'Dehli'},
        tripCities: ['Delhi', 'Some Garbage Value'],
      );
      expect(r['fromCity'], 'Delhi');
    });
  });
}
