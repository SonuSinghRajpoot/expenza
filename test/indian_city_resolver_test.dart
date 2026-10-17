import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/core/utils/indian_city_resolver.dart';

void main() {
  String? resolve(String? text, {String? code, List<String> preferred = const []}) =>
      IndianCityResolver.canonicalName(text, code: code, preferred: preferred);

  group('IndianCityResolver aliases and official names', () {
    test('maps old names and spellings to canonical names', () {
      expect(resolve('New Delhi'), 'Delhi');
      expect(resolve('Bangalore'), 'Bengaluru');
      expect(resolve('Bombay'), 'Mumbai');
      expect(resolve('Gurgaon'), 'Gurugram');
      expect(resolve('Allahabad'), 'Prayagraj');
      expect(resolve('Aurangabad'), 'Chhatrapati Sambhajinagar');
      expect(resolve('Calicut'), 'Kozhikode');
      expect(resolve('Secunderabad'), 'Hyderabad');
      expect(resolve('Vizag'), 'Visakhapatnam');
    });

    test('is case and punctuation insensitive', () {
      expect(resolve('  MUMBAI  '), 'Mumbai');
      expect(resolve('gurugram, haryana'), 'Gurugram');
    });
  });

  group('IndianCityResolver airport, station and address text', () {
    test('extracts the city from airport and station names', () {
      expect(resolve('Indira Gandhi International Airport, New Delhi'), 'Delhi');
      expect(resolve('Kempegowda International Airport Bengaluru'), 'Bengaluru');
      expect(
        resolve('Chhatrapati Shivaji Maharaj International Airport, Mumbai (BOM)'),
        'Mumbai',
      );
      expect(resolve('Mumbai Central'), 'Mumbai');
      expect(resolve('Pune Jn'), 'Pune');
      expect(resolve('Chennai Egmore'), 'Chennai');
      expect(resolve('North Goa'), 'Goa');
    });

    test('extracts the city from addresses', () {
      expect(resolve('Andheri East, Mumbai, Maharashtra 400069'), 'Mumbai');
      expect(resolve('Ratna Sagar Hotel, Jaipur'), 'Jaipur');
      expect(resolve('Sabzi Mandi, Delhi'), 'Delhi');
      expect(resolve('Noida Sector 62'), 'Noida');
    });

    test('resolves airport and station codes', () {
      expect(resolve(null, code: 'BOM'), 'Mumbai');
      expect(resolve('XYZ Airport', code: 'maa'), 'Chennai');
      expect(resolve('Delhi (DEL)'), 'Delhi');
      expect(resolve('Lucknow (LKO)'), 'Lucknow');
      expect(resolve('Some Station', code: 'NDLS'), 'Delhi');
    });
  });

  group('IndianCityResolver rejects non-cities', () {
    test('returns null for terminals, areas and junk', () {
      expect(resolve('Terminal 1D'), isNull);
      expect(resolve('Sector 18'), isNull);
      expect(resolve('MG Road'), isNull);
      expect(resolve('HOTEL'), isNull);
      expect(resolve('GST'), isNull);
      expect(resolve('NA'), isNull);
      expect(resolve(''), isNull);
      expect(resolve(null), isNull);
    });

    test('does not pick ambiguous words out of longer text', () {
      expect(resolve('Anand Vihar'), isNull);
      expect(resolve('Dwarka Sector 21'), isNull);
    });
  });

  group('IndianCityResolver spelling tolerance', () {
    test('corrects very close misspellings', () {
      expect(resolve('Banglore'), 'Bengaluru');
    });

    test('does not turn a different town into a nearby big city', () {
      expect(resolve('Jaitpur'), isNull);
    });

    test('accepts looser matches when they are trip cities', () {
      expect(resolve('Dehli'), isNull);
      expect(resolve('Dehli', preferred: ['Delhi']), 'Delhi');
      expect(resolve('Hyderbad', preferred: ['Hyderabad']), 'Hyderabad');
      expect(resolve('Mumbia', preferred: ['Mumbai']), 'Mumbai');
    });
  });

  group('IndianCityResolver.comparisonKey', () {
    test('treats different spellings of the same city as equal', () {
      final key = IndianCityResolver.comparisonKey('Delhi');
      expect(IndianCityResolver.comparisonKey('New Delhi'), key);
      expect(IndianCityResolver.comparisonKey('DELHI (DEL)'), key);
    });

    test('falls back to normalised text for unknown names', () {
      expect(IndianCityResolver.comparisonKey(' Jaitpur '), 'jaitpur');
      expect(IndianCityResolver.comparisonKey(null), '');
    });
  });

  test('city list is sorted and contains no duplicates', () {
    final names = IndianCityResolver.allCityNames;
    expect(names.toSet().length, names.length);
    expect(names, contains('Mumbai'));
  });
}
