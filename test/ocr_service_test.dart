import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/core/utils/ocr_service.dart';

void main() {
  group('OcrService.isOcrSufficient', () {
    test('returns false for null', () {
      expect(OcrService.isOcrSufficient(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(OcrService.isOcrSufficient(''), isFalse);
    });

    test('returns false when length < 80', () {
      expect(OcrService.isOcrSufficient('x' * 79), isFalse);
    });

    test('returns false when no digit', () {
      expect(OcrService.isOcrSufficient('a' * 80), isFalse);
    });

    test('returns false for long string without digits', () {
      expect(OcrService.isOcrSufficient('no digits at all ' * 6), isFalse);
    });

    test('returns true when length >= 80 and has digit', () {
      expect(OcrService.isOcrSufficient('a' * 80 + '1'), isTrue);
    });

    test('returns true for receipt-like text with amount', () {
      const base = 'Coffee Rs 120 total 150. ';
      final long = base + 'item ' * 12; // 24 + 60 = 84 chars, has digit
      expect(OcrService.isOcrSufficient(long), isTrue);
    });
  });
}
