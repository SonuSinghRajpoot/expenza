import 'package:flutter/material.dart';

/// One icon per head, all from the outlined Material set so they look alike.
const Map<String, IconData> _headIcons = {
  'Travel': Icons.luggage_outlined,
  'Accommodation': Icons.hotel_outlined,
  'Food': Icons.restaurant_outlined,
  'Event': Icons.event_outlined,
  'Miscellaneous': Icons.receipt_long_outlined,
  'Subscription': Icons.autorenew,
};

/// One icon per sub-head. "Others" is intentionally absent: it falls back to
/// the head's icon, so an "Others" row still shows what kind of expense it is.
const Map<String, Map<String, IconData>> _subHeadIcons = {
  'Travel': {
    'Cab': Icons.directions_car_outlined,
    'Bus': Icons.directions_bus_outlined,
    'Train': Icons.train_outlined,
    'Flight': Icons.flight_outlined,
    'Fuel': Icons.local_gas_station_outlined,
    'Bike': Icons.two_wheeler_outlined, // motorbike / bike taxi
    'Auto': Icons.local_taxi_outlined,
    'E-Rickshaw': Icons.electric_rickshaw_outlined,
    'Local': Icons.commute_outlined,
  },
  'Accommodation': {
    'Hotel': Icons.room_service_outlined,
    'PG': Icons.apartment_outlined,
    'Guest House': Icons.cottage_outlined,
  },
  'Food': {
    'Breakfast': Icons.free_breakfast_outlined,
    'Lunch': Icons.lunch_dining_outlined,
    'Dinner': Icons.dinner_dining_outlined,
    'Snacks': Icons.bakery_dining_outlined,
  },
  'Event': {
    'Event Fee': Icons.confirmation_number_outlined,
    'Equipments Rent': Icons.handyman_outlined,
    'Printing Fee': Icons.print_outlined,
    'Courier Charges': Icons.local_shipping_outlined,
    'Stationary': Icons.edit_outlined,
    'Gift Item': Icons.card_giftcard_outlined,
    'TV Rent': Icons.tv_outlined,
  },
  'Miscellaneous': {
    'Printing': Icons.print_outlined,
    'Stationary': Icons.edit_outlined,
  },
  'Subscription': {
    'Software / App': Icons.apps_outlined,
  },
};

/// Returns the appropriate icon for a given expense head and optional subHead.
/// Used in Add Expense dialog, trip details, and expense detail view.
IconData getExpenseIcon(String head, String? subHead) {
  final subHeadIcon = subHead == null ? null : _subHeadIcons[head]?[subHead];
  return subHeadIcon ?? _headIcons[head] ?? Icons.receipt_outlined;
}
