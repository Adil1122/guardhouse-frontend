enum ShiftStatus { scheduled, inProgress, completed, cancelled }

class Shift {
  final String id;
  final String customerId;
  final String customerName;
  final String siteId;
  final String siteName;
  final String securityOfficerId;
  final String securityOfficerName;
  final String serviceType;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime date;
  final ShiftStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shift({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.siteId,
    required this.siteName,
    required this.securityOfficerId,
    required this.securityOfficerName,
    required this.serviceType,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.status = ShiftStatus.scheduled,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Duration get duration {
    return endTime.difference(startTime);
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      siteId: json['siteId'] as String? ?? '',
      siteName: json['siteName'] as String? ?? '',
      securityOfficerId: json['securityOfficerId'] as String? ?? '',
      securityOfficerName: json['securityOfficerName'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? '',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      date: DateTime.parse(json['date'] as String),
      status: ShiftStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ShiftStatus.scheduled,
      ),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'siteId': siteId,
      'siteName': siteName,
      'securityOfficerId': securityOfficerId,
      'securityOfficerName': securityOfficerName,
      'serviceType': serviceType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'date': date.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Shift copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? siteId,
    String? siteName,
    String? securityOfficerId,
    String? securityOfficerName,
    String? serviceType,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? date,
    ShiftStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      securityOfficerId: securityOfficerId ?? this.securityOfficerId,
      securityOfficerName: securityOfficerName ?? this.securityOfficerName,
      serviceType: serviceType ?? this.serviceType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
