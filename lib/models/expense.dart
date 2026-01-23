import 'dart:convert';

class Expense {
  final int? id;
  final int tripId;
  final String head; // Travel, Accommodation, Food, Miscellaneous
  final String? subHead; // e.g. 'Cab', 'Dinner'
  final DateTime startDate;
  final DateTime endDate;
  final String city; // For travel, this is 'From City'
  final String? toCity; // For travel, this is 'To City'
  final int? pax; // For Accommodation
  final double amount;
  final List<String> billPaths;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;
  final int? displayOrder; // Order for display and export

  Expense({
    this.id,
    required this.tripId,
    required this.head,
    this.subHead,
    required this.startDate,
    required this.endDate,
    required this.city,
    this.toCity,
    this.pax,
    required this.amount,
    this.billPaths = const [],
    this.notes,
    required this.createdAt,
    this.createdBy,
    this.displayOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'head': head,
      'sub_head': subHead,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'city': city,
      'to_city': toCity,
      'pax': pax,
      'amount': amount,
      'bill_path': jsonEncode(billPaths),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'display_order': displayOrder,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    List<String> paths = [];
    if (map['bill_path'] != null) {
      try {
        final decoded = jsonDecode(map['bill_path']);
        if (decoded is List) {
          paths = List<String>.from(decoded);
        } else if (decoded is String) {
          paths = [decoded];
        }
      } catch (e) {
        // Fallback for legacy single string paths
        paths = [map['bill_path'] as String];
      }
    }

    return Expense(
      id: map['id'],
      tripId: map['trip_id'],
      head: map['head'],
      subHead: map['sub_head'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      city: map['city'],
      toCity: map['to_city'],
      pax: map['pax'],
      amount: map['amount'],
      billPaths: paths,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      createdBy: map['created_by'],
      displayOrder: map['display_order'],
    );
  }

  Expense copyWith({
    int? id,
    int? tripId,
    String? head,
    String? subHead,
    DateTime? startDate,
    DateTime? endDate,
    String? city,
    String? toCity,
    int? pax,
    double? amount,
    List<String>? billPaths,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    int? displayOrder,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      head: head ?? this.head,
      subHead: subHead ?? this.subHead, // Fixed typo
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      city: city ?? this.city,
      toCity: toCity ?? this.toCity,
      pax: pax ?? this.pax,
      amount: amount ?? this.amount,
      billPaths: billPaths ?? this.billPaths,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
