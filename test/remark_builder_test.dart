import 'package:flutter_test/flutter_test.dart';
import 'package:field_expense_manager/core/utils/remark_builder.dart';

void main() {
  group('RemarkBuilder travel', () {
    test('route with ticketed mode', () {
      expect(
        RemarkBuilder.build(
          head: 'Travel',
          subHead: 'Flight',
          fromCity: 'Delhi',
          toCity: 'Mumbai',
          pax: 1,
        ),
        'Delhi to Mumbai flight ticket for 1 person',
      );
      expect(
        RemarkBuilder.build(
          head: 'Travel',
          subHead: 'Train',
          fromCity: 'Pune',
          toCity: 'Nagpur',
          pax: 2,
        ),
        'Pune to Nagpur train ticket for 2 persons',
      );
    });

    test('single city uses "in", or "from" for tickets', () {
      expect(
        RemarkBuilder.build(head: 'Travel', subHead: 'Cab', fromCity: 'Pune', toCity: 'Pune', pax: 2),
        'Cab in Pune for 2 persons',
      );
      expect(
        RemarkBuilder.build(head: 'Travel', subHead: 'Flight', fromCity: 'Delhi', pax: 1),
        'Flight ticket from Delhi for 1 person',
      );
    });

    test('no city and Others sub-head', () {
      expect(RemarkBuilder.build(head: 'Travel', subHead: 'Auto', pax: 1), 'Auto for 1 person');
      expect(RemarkBuilder.build(head: 'Travel', subHead: 'Others', pax: 1), 'Travel for 1 person');
      expect(RemarkBuilder.build(head: 'Travel', pax: 1), 'Travel for 1 person');
    });
  });

  group('RemarkBuilder other heads', () {
    test('accommodation', () {
      expect(
        RemarkBuilder.build(head: 'Accommodation', subHead: 'Hotel', fromCity: 'Jaipur', pax: 2),
        'Hotel stay in Jaipur for 2 persons',
      );
      expect(
        RemarkBuilder.build(head: 'Accommodation', subHead: 'Others', pax: 1),
        'Accommodation for 1 person',
      );
    });

    test('food', () {
      expect(
        RemarkBuilder.build(head: 'Food', subHead: 'Lunch', fromCity: 'Pune', pax: 3),
        'Lunch in Pune for 3 persons',
      );
      expect(RemarkBuilder.build(head: 'Food', pax: 1), 'Meal for 1 person');
    });

    test('event and miscellaneous ignore pax', () {
      expect(
        RemarkBuilder.build(head: 'Event', subHead: 'Printing Fee', fromCity: 'Delhi', pax: 4),
        'Printing Fee in Delhi',
      );
      expect(
        RemarkBuilder.build(head: 'Miscellaneous', subHead: 'Others'),
        'Miscellaneous expense',
      );
    });
  });

  test('subscription has no city or pax', () {
    expect(
      RemarkBuilder.build(
        head: 'Subscription',
        subHead: 'Software / App',
        fromCity: 'Delhi',
        pax: 1,
      ),
      'Software / App subscription',
    );
    expect(
      RemarkBuilder.build(head: 'Subscription', subHead: 'Others'),
      'Subscription',
    );
  });

  test('same inputs always give the same remark', () {
    String build() => RemarkBuilder.build(
          head: 'Travel',
          subHead: 'Bus',
          fromCity: ' Indore ',
          toCity: 'Bhopal',
          pax: 2,
        );
    expect(build(), build());
    expect(build(), 'Indore to Bhopal bus ticket for 2 persons');
  });
}
