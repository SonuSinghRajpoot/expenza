import 'package:flutter/material.dart';

/// Returns the appropriate icon for a given expense head and optional subHead.
/// Used in Add Expense dialog, trip details, and expense detail view.
IconData getExpenseIcon(String head, String? subHead) {
  // Travel subheads
  if (head == 'Travel' && subHead != null) {
    switch (subHead) {
      case 'Cab':
        return Icons.directions_car_outlined;
      case 'Bus':
        return Icons.directions_bus;
      case 'Train':
        return Icons.train;
      case 'Flight':
        return Icons.flight;
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Bike':
        return Icons.directions_bike;
      case 'Auto':
        return Icons.local_taxi;
      case 'E-Rickshaw':
        return Icons.electric_rickshaw;
      case 'Local':
        return Icons.pin_drop_outlined;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.directions_car_outlined;
    }
  }

  // Accommodation subheads
  if (head == 'Accommodation' && subHead != null) {
    switch (subHead) {
      case 'Hotel':
        return Icons.hotel_outlined;
      case 'PG':
        return Icons.apartment_outlined;
      case 'Guest House':
        return Icons.night_shelter;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.hotel_outlined;
    }
  }

  // Food subheads
  if (head == 'Food' && subHead != null) {
    switch (subHead) {
      case 'Breakfast':
        return Icons.free_breakfast;
      case 'Lunch':
        return Icons.lunch_dining_outlined;
      case 'Dinner':
        return Icons.dinner_dining_outlined;
      case 'Snacks':
        return Icons.bakery_dining_outlined;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.restaurant_outlined;
    }
  }

  // Event subheads
  if (head == 'Event' && subHead != null) {
    switch (subHead) {
      case 'Event Fee':
        return Icons.event;
      case 'Equipments Rent':
        return Icons.construction_outlined;
      case 'Printing Fee':
        return Icons.print_outlined;
      case 'Courier Charges':
        return Icons.local_shipping_outlined;
      case 'Stationary':
        return Icons.edit_note;
      case 'Gift Item':
        return Icons.card_giftcard_outlined;
      case 'TV Rent':
        return Icons.tv;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.event_note_outlined;
    }
  }

  // Miscellaneous subheads
  if (head == 'Miscellaneous' && subHead != null) {
    switch (subHead) {
      case 'Printing':
        return Icons.print_outlined;
      case 'Stationary':
        return Icons.edit_note;
      case 'Others':
        return Icons.more_horiz;
      default:
        return Icons.receipt_outlined;
    }
  }

  // Fallback to head-level icons
  switch (head) {
    case 'Travel':
      return Icons.directions_car_outlined;
    case 'Accommodation':
      return Icons.hotel_outlined;
    case 'Food':
      return Icons.restaurant_outlined;
    case 'Event':
      return Icons.event_note_outlined;
    case 'Miscellaneous':
      return Icons.receipt_outlined;
    default:
      return Icons.receipt_outlined;
  }
}
