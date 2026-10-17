class ExpenseConstants {
  static const List<String> heads = [
    'Travel',
    'Accommodation',
    'Food',
    'Event',
    'Miscellaneous',
    'Subscription',
  ];

  /// Heads where the city is optional (the expense is not tied to a place).
  static const Set<String> headsWithOptionalCity = {'Subscription'};

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
    'Subscription': ['Software / App', 'Others'],
  };
}
