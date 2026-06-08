class OrganizationCompliance {
  final String id;
  final String name;
  final int remindInDays;
  final bool isCritical;
  final bool showToCustomer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrganizationCompliance({
    required this.id,
    required this.name,
    required this.remindInDays,
    this.isCritical = false,
    this.showToCustomer = false,
    this.createdAt,
    this.updatedAt,
  });

  OrganizationCompliance copyWith({
    String? id,
    String? name,
    int? remindInDays,
    bool? isCritical,
    bool? showToCustomer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationCompliance(
      id: id ?? this.id,
      name: name ?? this.name,
      remindInDays: remindInDays ?? this.remindInDays,
      isCritical: isCritical ?? this.isCritical,
      showToCustomer: showToCustomer ?? this.showToCustomer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'remind_in_days': remindInDays,
      'is_critical': isCritical,
      'show_to_customer': showToCustomer,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory OrganizationCompliance.fromJson(Map<String, dynamic> json) {
    return OrganizationCompliance(
      id: json['id'] as String,
      name: json['name'] as String,
      remindInDays: json['remind_in_days'] as int,
      isCritical: json['is_critical'] as bool? ?? false,
      showToCustomer: json['show_to_customer'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
