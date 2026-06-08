import 'package:uuid/uuid.dart';

enum DigitalOccurrenceStatus {
  draft,
  submitted,
  reviewed,
  closed;

  String get displayName {
    switch (this) {
      case DigitalOccurrenceStatus.draft:
        return 'Draft';
      case DigitalOccurrenceStatus.submitted:
        return 'Submitted';
      case DigitalOccurrenceStatus.reviewed:
        return 'Reviewed';
      case DigitalOccurrenceStatus.closed:
        return 'Closed';
    }
  }
}

class DigitalOccurrenceLog {
  final String id;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String siteId;
  final String siteName;
  final String staffId;
  final String staffName;
  final String incidentDescription;
  final String category;
  final List<String> attachmentUrls;
  final bool showToCustomer;
  final DigitalOccurrenceStatus status;
  final String? pdfUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  DigitalOccurrenceLog({
    String? id,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.siteId,
    required this.siteName,
    required this.staffId,
    required this.staffName,
    required this.incidentDescription,
    required this.category,
    this.attachmentUrls = const [],
    this.showToCustomer = false,
    this.status = DigitalOccurrenceStatus.draft,
    this.pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  DigitalOccurrenceLog copyWith({
    String? id,
    DateTime? date,
    String? customerId,
    String? customerName,
    String? siteId,
    String? siteName,
    String? staffId,
    String? staffName,
    String? incidentDescription,
    String? category,
    List<String>? attachmentUrls,
    bool? showToCustomer,
    DigitalOccurrenceStatus? status,
    String? pdfUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return DigitalOccurrenceLog(
      id: id ?? this.id,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      category: category ?? this.category,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      showToCustomer: showToCustomer ?? this.showToCustomer,
      status: status ?? this.status,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'siteId': siteId,
      'siteName': siteName,
      'staffId': staffId,
      'staffName': staffName,
      'incidentDescription': incidentDescription,
      'category': category,
      'attachmentUrls': attachmentUrls,
      'showToCustomer': showToCustomer,
      'status': status.name,
      'pdfUrl': pdfUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory DigitalOccurrenceLog.fromJson(Map<String, dynamic> json) {
    return DigitalOccurrenceLog(
      id: json['id'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      siteId: json['siteId'] as String? ?? '',
      siteName: json['siteName'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      incidentDescription: json['incidentDescription'] as String? ?? '',
      category: json['category'] as String? ?? '',
      attachmentUrls: List<String>.from(json['attachmentUrls'] as List? ?? []),
      showToCustomer: json['showToCustomer'] as bool? ?? false,
      status: DigitalOccurrenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DigitalOccurrenceStatus.draft,
      ),
      pdfUrl: json['pdfUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'DigitalOccurrenceLog(id: $id, date: $date, customer: $customerName)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Occurrence Log Type Setting — configurable per-shift log categories
// ─────────────────────────────────────────────────────────────────────────────

class OccurrenceLogTypeSetting {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const OccurrenceLogTypeSetting({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  OccurrenceLogTypeSetting copyWith({bool? isActive}) {
    return OccurrenceLogTypeSetting(
      id: id,
      name: name,
      description: description,
      isActive: isActive ?? this.isActive,
    );
  }
}
