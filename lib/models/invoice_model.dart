enum InvoiceStatus {
  draft,
  approved,
  sent,
  paid,
  overdue,
  cancelled;

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.approved:
        return 'Approved';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get apiValue => name;

  static InvoiceStatus fromApiValue(String? value) {
    switch (value) {
      case 'draft':
        return InvoiceStatus.draft;
      case 'approved':
      case 'complete':
        return InvoiceStatus.approved;
      case 'sent':
        return InvoiceStatus.sent;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      case 'cancelled':
        return InvoiceStatus.cancelled;
      default:
        return InvoiceStatus.draft;
    }
  }
}

class InvoiceItem {
  final String id;
  final String referenceType;
  final Map<String, dynamic>? reference;
  final DateTime? createdAt;
  final String? itemName;
  final double? itemAmount;

  InvoiceItem({
    required this.id,
    required this.referenceType,
    this.reference,
    this.createdAt,
    this.itemName,
    this.itemAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? ref;
    if (json['resource'] is Map) {
      ref = Map<String, dynamic>.from(json['resource']);
    }
    String? name;
    double? amount;

    if (ref != null) {
      if (json['resource_type'] == 'manual-billable') {
        if (ref['service'] is Map) {
          name = ref['service']?['name']?.toString();
        }
        amount = _toDouble(ref['total_amount']);
      } else if (json['resource_type'] == 'timesheet') {
        name = 'Timesheet #${ref['id']}';
        if (ref['service_detail'] is Map) {
          final serviceDetail = ref['service_detail'] as Map<String, dynamic>;
          amount = _toDouble(serviceDetail['total_amount']);
        }
      }
    }

    DateTime? parsedCreatedAt;
    final createdAtValue = json['created_at'];
    if (createdAtValue != null && createdAtValue is String) {
      parsedCreatedAt = _parseApiDate(createdAtValue);
    }

    return InvoiceItem(
      id: json['id']?.toString() ?? '',
      referenceType: json['resource_type']?.toString() ?? '',
      reference: ref,
      createdAt: parsedCreatedAt,
      itemName: name,
      itemAmount: amount,
    );
  }
}

DateTime? _parseApiDate(String dateStr) {
  try {
    // Handle dd/mm/yyyy format
    if (dateStr.contains('/')) {
      final parts = dateStr.split(RegExp(r'[\/\s:]'));
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        int hour = 0;
        int minute = 0;
        if (parts.length >= 5) {
          hour = int.parse(parts[3]);
          minute = int.parse(parts[4]);
        }
        return DateTime(year, month, day, hour, minute);
      }
    }
    // Handle yyyy-mm-dd format with possible PM/AM suffix
    String cleaned = dateStr.replaceAll(RegExp(r'\s*(AM|PM)\s*$', caseSensitive: false), '').trim();
    return DateTime.tryParse(cleaned);
  } catch (_) {
    return null;
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

class ManualBillableItem {
  final String id;
  final String name;
  final double rate;
  final double units;
  final double totalAmount;
  final String note;
  final DateTime? date;

  ManualBillableItem({
    required this.id,
    required this.name,
    required this.rate,
    required this.units,
    this.note = '',
    this.date,
  }) : totalAmount = rate * units;

  ManualBillableItem copyWith({
    String? id,
    String? name,
    double? rate,
    double? units,
    String? note,
    DateTime? date,
  }) {
    return ManualBillableItem(
      id: id ?? this.id,
      name: name ?? this.name,
      rate: rate ?? this.rate,
      units: units ?? this.units,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rate': rate,
      'units': units,
      'total_amount': totalAmount,
      'note': note,
      'date': date?.toIso8601String().split('T')[0],
    };
  }

  factory ManualBillableItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    String name = '';
    double rate = 0;
    double units = 0;

    if (service is Map) {
      name = service['name']?.toString() ?? '';
      rate = _toDouble(service['rate']);
      units = _toDouble(service['units']);
    }

    DateTime? parsedDate;
    final dateValue = json['date'];
    if (dateValue != null) {
      if (dateValue is String) {
        if (dateValue.contains('/')) {
          parsedDate = _parseApiDate(dateValue);
        } else {
          parsedDate = DateTime.tryParse(dateValue);
        }
      } else if (dateValue is DateTime) {
        parsedDate = dateValue;
      }
    }

    return ManualBillableItem(
      id: json['id']?.toString() ?? '',
      name: name,
      rate: rate,
      units: units,
      note: json['note']?.toString() ?? '',
      date: parsedDate,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final List<String> timesheetIds;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final List<ManualBillableItem> manualItems;
  final List<InvoiceItem> items;
  final InvoiceStatus status;
  final String customerId;
  final String customerName;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? customerInvoiceProfile;
  final Map<String, dynamic>? tax;
  final double paidAmount;
  final String? paymentStatus;
  final String? paymentStatusNote;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.timesheetIds,
    required this.invoiceDate,
    this.dueDate,
    this.manualItems = const [],
    this.items = const [],
    this.status = InvoiceStatus.draft,
    this.customerId = '',
    this.customerName = '',
    required this.subtotal,
    this.taxAmount = 0,
    required this.totalAmount,
    this.notes,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.customerInvoiceProfile,
    this.tax,
    this.paidAmount = 0,
    this.paymentStatus,
    this.paymentStatusNote,
  });

  double get grandTotal => totalAmount;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    List<String>? timesheetIds,
    DateTime? invoiceDate,
    DateTime? dueDate,
    List<ManualBillableItem>? manualItems,
    List<InvoiceItem>? items,
    InvoiceStatus? status,
    String? customerId,
    String? customerName,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? notes,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      timesheetIds: timesheetIds ?? this.timesheetIds,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      manualItems: manualItems ?? this.manualItems,
      items: items ?? this.items,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'];
    List<InvoiceItem> invoiceItems = [];
    if (itemsData is List) {
      invoiceItems = itemsData
          .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Extract timesheet IDs from items
    final timesheetIds = <String>[];
    for (final item in invoiceItems) {
      if (item.referenceType == 'timesheet' && item.reference != null) {
        final ref = item.reference!;
        if (ref['id'] != null) {
          timesheetIds.add(ref['id'].toString());
        }
      }
    }

    DateTime? parsedDueDate;
    final dueDateValue = json['due_date'];
    if (dueDateValue != null) {
      if (dueDateValue is String && dueDateValue.contains('/')) {
        try {
          final parts = dueDateValue.split('/');
          parsedDueDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        } catch (_) {}
      } else if (dueDateValue is String) {
        parsedDueDate = DateTime.tryParse(dueDateValue);
      }
    }

    DateTime? parsedCreatedAt;
    final createdAtValue = json['created_at'];
    if (createdAtValue != null && createdAtValue is String) {
      parsedCreatedAt = _parseApiDate(createdAtValue);
    }

    String customerName = '';
    String customerId = '';
    
    if (json['customer'] != null && json['customer'] is Map) {
      final cust = json['customer'] as Map<String, dynamic>;
      final firstName = cust['first_name']?.toString() ?? '';
      final lastName = cust['last_name']?.toString() ?? '';
      customerName = '$firstName $lastName'.trim();
      if (customerName.isEmpty) {
        customerName = cust['name']?.toString() ?? '';
      }
      customerId = cust['user_id']?.toString() ?? cust['id']?.toString() ?? '';
    }
    
    if (customerName.isEmpty && json['customer_invoice_profile'] != null) {
      final profile = json['customer_invoice_profile'] as Map<String, dynamic>;
      customerName = profile['company_name']?.toString() ?? '';
    }
    
    if (customerName.isEmpty && invoiceItems.isNotEmpty) {
      for (final item in invoiceItems) {
        if (item.referenceType == 'timesheet' && item.reference != null) {
          final ref = item.reference!;
          final itemCustomer = ref['customer'];
          if (itemCustomer is Map<String, dynamic>) {
            customerName = itemCustomer['name']?.toString() ?? '';
            customerId = itemCustomer['id']?.toString() ?? '';
            break;
          }
        }
      }
    }

    double taxPercentage = 0;
    double taxAmt = 0;
    if (json['tax'] != null && json['tax'] is Map) {
      final taxData = json['tax'] as Map<String, dynamic>;
      taxPercentage = _toDouble(taxData['percentage']);
      taxAmt = _toDouble(taxData['amount']);
    }

    // Extract manual items
    final manualItems = <ManualBillableItem>[];
    for (final item in invoiceItems) {
      if (item.referenceType == 'manual-billable' && item.reference != null) {
        manualItems.add(ManualBillableItem.fromJson(item.reference!));
      }
    }

    return Invoice(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['reference_number']?.toString() ?? '',
      timesheetIds: timesheetIds,
      invoiceDate: parsedCreatedAt ?? DateTime.now(),
      dueDate: parsedDueDate,
      manualItems: manualItems,
      items: invoiceItems,
      status: InvoiceStatus.fromApiValue(json['status']?.toString()),
      customerId: customerId,
      customerName: customerName,
      subtotal: _toDouble(json['sub_total']),
      taxAmount: taxAmt,
      totalAmount: _toDouble(json['grand_total']),
      notes: json['notes']?.toString(),
      isLocked: false,
      createdAt: parsedCreatedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      customer: json['customer'] as Map<String, dynamic>?,
      customerInvoiceProfile: json['customer_invoice_profile'] as Map<String, dynamic>?,
      tax: json['tax'] as Map<String, dynamic>?,
      paidAmount: _toDouble(json['paid_amount']),
      paymentStatus: json['payment_status']?.toString(),
      paymentStatusNote: json['payment_status_note']?.toString(),
    );
  }
}
