class GeminiKey {
  final String id;
  final String label;
  final String apiKey;
  final bool isActive;

  GeminiKey({
    required this.id,
    required this.label,
    required this.apiKey,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'api_key': apiKey,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory GeminiKey.fromMap(Map<String, dynamic> map) {
    return GeminiKey(
      id: map['id'],
      label: map['label'],
      apiKey: map['api_key'],
      isActive: (map['is_active'] ?? 0) == 1,
    );
  }

  GeminiKey copyWith({
    String? id,
    String? label,
    String? apiKey,
    bool? isActive,
  }) {
    return GeminiKey(
      id: id ?? this.id,
      label: label ?? this.label,
      apiKey: apiKey ?? this.apiKey,
      isActive: isActive ?? this.isActive,
    );
  }

  String get maskedKey {
    if (apiKey.length <= 8) return apiKey;
    return '${apiKey.substring(0, 4)}****${apiKey.substring(apiKey.length - 4)}';
  }
}
