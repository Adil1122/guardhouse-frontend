class Timesheet {
  final String id;
  final String shiftId;
  final String entryType;
  final String siteId;
  final String siteName;
  final String customerId;
  final String customerName;
  final String staffId;
  final String staffName;
  DateTime? clockInTime;
  DateTime? clockOutTime;
  String serviceGroup;
  String serviceGroupId;
  String payGroup;
  String payGroupId;
  int breakMinutes;
  String notes;
  TimesheetStatus status;
  DateTime? startDate;
  DateTime? endDate;
  String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Timesheet({
    required this.id,
    required this.shiftId,
    required this.entryType,
    required this.siteId,
    required this.siteName,
    required this.customerId,
    required this.customerName,
    required this.staffId,
    required this.staffName,
    this.clockInTime,
    this.clockOutTime,
    this.serviceGroup = '',
    this.serviceGroupId = '',
    this.payGroup = '',
    this.payGroupId = '',
    this.breakMinutes = 0,
    this.notes = '',
    this.status = TimesheetStatus.drafted,
    required this.createdAt,
    required this.updatedAt,
    this.startDate,
    this.endDate,
    this.timezone = '',
  });

  static DateTime? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]),
          parts.length > 2 ? int.parse(parts[2]) : 0);
    } catch (e) {
      return null;
    }
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]));
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  factory Timesheet.fromJson(Map<String, dynamic> json) {
    final siteData = json['site'] as Map<String, dynamic>?;
    final customerData = json['customer'] as Map<String, dynamic>?;
    final employeeData = json['employee'] as Map<String, dynamic>?;
    final serviceDetail = json['service_detail'] as Map<String, dynamic>?;
    final payDetail = json['pay_detail'] as Map<String, dynamic>?;
    final serviceGroupData = serviceDetail?['group'] as Map<String, dynamic>?;
    final payGroupData = payDetail?['group'] as Map<String, dynamic>?;

    final startTime = json['start_time'] as String?;
    final endTime = json['end_time'] as String?;

    return Timesheet(
      id: json['id']?.toString() ?? '',
      shiftId: json['shift_id']?.toString() ?? '',
      entryType: json['entry_type']?.toString() ?? 'work',
      siteId: siteData?['id']?.toString() ?? '',
      siteName: siteData?['name']?.toString() ?? '',
      customerId: customerData?['id']?.toString() ?? '',
      customerName: customerData?['name']?.toString() ?? '',
      staffId: employeeData?['id']?.toString() ?? '',
      staffName: employeeData?['name']?.toString() ?? '',
      clockInTime: _parseTime(startTime),
      clockOutTime: _parseTime(endTime),
      serviceGroup: serviceGroupData?['name']?.toString() ?? '',
      serviceGroupId: serviceGroupData?['id']?.toString() ?? '',
      payGroup: payGroupData?['name']?.toString() ?? '',
      payGroupId: payGroupData?['id']?.toString() ?? '',
      breakMinutes: json['break_duration'] ?? 0,
      notes: json['notes']?.toString() ?? '',
      status: TimesheetStatus.fromApiValue(json['status']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.now(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      timezone: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shift_id': shiftId,
      'entry_type': entryType,
      'site_id': siteId,
      'service_group_id': serviceGroupId,
      'pay_group_id': payGroupId,
      'start_time': clockInTime != null
          ? '${clockInTime!.hour.toString().padLeft(2, '0')}:${clockInTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'end_time': clockOutTime != null
          ? '${clockOutTime!.hour.toString().padLeft(2, '0')}:${clockOutTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'break_duration': breakMinutes,
      'notes': notes,
      'status': status.apiValue,
      'start_date': startDate?.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'timezone': timezone,
    };
  }

  Timesheet copyWith({
    String? id,
    String? shiftId,
    String? entryType,
    String? siteId,
    String? siteName,
    String? customerId,
    String? customerName,
    String? staffId,
    String? staffName,
    DateTime? clockInTime,
    DateTime? clockOutTime,
    String? serviceGroup,
    String? serviceGroupId,
    String? payGroup,
    String? payGroupId,
    int? breakMinutes,
    String? notes,
    TimesheetStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    String? timezone,
  }) {
    return Timesheet(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      entryType: entryType ?? this.entryType,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      serviceGroup: serviceGroup ?? this.serviceGroup,
      serviceGroupId: serviceGroupId ?? this.serviceGroupId,
      payGroup: payGroup ?? this.payGroup,
      payGroupId: payGroupId ?? this.payGroupId,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timezone: timezone ?? this.timezone,
    );
  }

  String get customerSite => '$customerName / $siteName';

  DateTime get date => startDate ?? createdAt;

  String get clockTimeDisplay {
    final clockIn = clockInTime != null
        ? '${clockInTime!.hour.toString().padLeft(2, '0')}:${clockInTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final clockOut = clockOutTime != null
        ? '${clockOutTime!.hour.toString().padLeft(2, '0')}:${clockOutTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return '$clockIn - $clockOut';
  }

  Duration? get totalHours {
    if (clockInTime != null && clockOutTime != null) {
      final duration = clockOutTime!.difference(clockInTime!);
      return Duration(minutes: duration.inMinutes - breakMinutes);
    }
    return null;
  }
}

enum TimesheetStatus {
  drafted,
  approved,
  rejected,
  invoiced,
  paid,
  settled;

  String get apiValue => name;

  String get displayName {
    switch (this) {
      case TimesheetStatus.drafted:
        return 'Drafted';
      case TimesheetStatus.approved:
        return 'Approved';
      case TimesheetStatus.rejected:
        return 'Rejected';
      case TimesheetStatus.invoiced:
        return 'Invoiced';
      case TimesheetStatus.paid:
        return 'Paid';
      case TimesheetStatus.settled:
        return 'Settled';
    }
  }

  static TimesheetStatus fromApiValue(String? value) {
    switch (value?.toLowerCase()) {
      case 'drafted':
      case 'draft':
        return TimesheetStatus.drafted;
      case 'approved':
        return TimesheetStatus.approved;
      case 'rejected':
        return TimesheetStatus.rejected;
      case 'invoiced':
        return TimesheetStatus.invoiced;
      case 'paid':
        return TimesheetStatus.paid;
      case 'settled':
        return TimesheetStatus.settled;
      default:
        return TimesheetStatus.drafted;
    }
  }
}
