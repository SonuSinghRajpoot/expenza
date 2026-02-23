class ExpenseConstants {
  static const List<String> heads = [
    'Travel',
    'Accommodation',
    'Food',
    'Event',
    'Miscellaneous',
  ];

  static const Map<String, List<String>> subHeads = {
    'Travel': ['Cab', 'Bus', 'Train', 'Flight', 'Fuel', 'Bike', 'Auto', 'E-Rickshaw', 'Local', 'Others'],
    'Accommodation': ['Hotel', 'PG', 'Guest House', 'Others'],
    'Food': ['Breakfast', 'Lunch', 'Dinner', 'Snacks', 'Others'],
    'Event': [
      'Event Fee',
      'Equipments Rent',
      'Printing Fee',
      'Courier Charges',
      'Stationary',
      'Gift Item',
      'TV Rent',
      'Others',
    ],
    'Miscellaneous': ['Printing', 'Stationary', 'Others'],
  };
}
