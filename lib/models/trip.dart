import 'dart:convert';

class Trip {
  final int? id;
  final String name;
  final String? projectName;
  final List<String> cities;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'Active', 'In-process', 'Settled'
  final DateTime? submittedAt;
  final DateTime lastModifiedAt;
  final bool isArchived;

  Trip({
    this.id,
    required this.name,
    this.projectName,
    required this.cities,
    required this.startDate,
    this.endDate,
    this.status = 'Active',
    this.submittedAt,
    required this.lastModifiedAt,
    this.isArchived = false,
  });

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'project_name': projectName,
      'cities': jsonEncode(cities),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'last_modified_at': lastModifiedAt.toIso8601String(),
      'is_archived': isArchived ? 1 : 0,
    };
  }

  // Create from Map (Database)
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      name: map['name'],
      projectName: map['project_name'],
      cities: List<String>.from(jsonDecode(map['cities'] ?? '[]')),
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      status: map['status'] ?? 'Active',
      submittedAt: map['submitted_at'] != null
          ? DateTime.parse(map['submitted_at'])
          : null,
      lastModifiedAt: DateTime.parse(map['last_modified_at']),
      isArchived: (map['is_archived'] ?? 0) == 1,
    );
  }

  Trip copyWith({
    int? id,
    String? name,
    String? projectName,
    List<String>? cities,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? submittedAt,
    DateTime? lastModifiedAt,
    bool? isArchived,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      projectName: projectName ?? this.projectName,
      cities: cities ?? this.cities,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
