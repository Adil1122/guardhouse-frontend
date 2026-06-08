import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

enum PayType {
  hourly,
  flat;

  String get displayName {
    switch (this) {
      case PayType.hourly:
        return 'Hourly';
      case PayType.flat:
        return 'Flat';
    }
  }

  String get apiValue => name;
}

class PayRate {
  final String id;
  final List<String> selectedDays;
  final double payRate;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayRate({
    String? id,
    required this.selectedDays,
    required this.payRate,
    required this.fromTime,
    required this.toTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  PayRate copyWith({
    String? id,
    List<String>? selectedDays,
    double? payRate,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayRate(
      id: id ?? this.id,
      selectedDays: selectedDays ?? this.selectedDays,
      payRate: payRate ?? this.payRate,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _shortenDay(String day) {
    final lower = day.toLowerCase();
    switch (lower) {
      case 'monday':
      case 'mon':
        return 'mon';
      case 'tuesday':
      case 'tue':
        return 'tue';
      case 'wednesday':
      case 'wed':
        return 'wed';
      case 'thursday':
      case 'thu':
        return 'thu';
      case 'friday':
      case 'fri':
        return 'fri';
      case 'saturday':
      case 'sat':
        return 'sat';
      case 'sunday':
      case 'sun':
        return 'sun';
      case 'public holiday':
      case 'public_holiday':
        return 'public_holiday';
      default:
        return lower;
    }
  }

  static String _expandDay(String day) {
    final lower = day.toLowerCase();
    switch (lower) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      case 'public_holiday':
        return 'Public Holiday';
      default:
        return day;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': selectedDays.map(_shortenDay).toList(),
      'rate': payRate,
      'from_time':
          '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}:00',
      'to_time':
          '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}:00',
    };
  }

  factory PayRate.fromJson(Map<String, dynamic> json) {
    final fromTimeStr = (json['from_time'] as String?) ?? '00:00:00';
    final fromTimeParts = fromTimeStr.split(':');
    final toTimeStr = (json['to_time'] as String?) ?? '00:00:00';
    final toTimeParts = toTimeStr.split(':');

    final days = json['days'];
    List<String> selectedDays;
    if (days is List) {
      selectedDays = List<String>.from(days);
    } else if (days is String) {
      selectedDays = [days];
    } else {
      selectedDays = [];
    }

    return PayRate(
      id: json['id']?.toString(),
      selectedDays: selectedDays.map(_expandDay).toList(),
      payRate: _parseDouble(json['rate']),
      fromTime: TimeOfDay(
        hour: int.tryParse(fromTimeParts.isNotEmpty ? fromTimeParts[0] : '0') ?? 0,
        minute: int.tryParse(fromTimeParts.length > 1 ? fromTimeParts[1] : '0') ?? 0,
      ),
      toTime: TimeOfDay(
        hour: int.tryParse(toTimeParts.isNotEmpty ? toTimeParts[0] : '0') ?? 0,
        minute: int.tryParse(toTimeParts.length > 1 ? toTimeParts[1] : '0') ?? 0,
      ),
    );
  }

  @override
  String toString() =>
      'PayRate(days: ${selectedDays.join(", ")}, rate: $payRate)';
}

class PayGroup {
  final String id;
  final String name;
  final PayType type;
  final double baseRate;
  final List<PayRate> rates;
  final DateTime createdAt;
  final DateTime updatedAt;

  PayGroup({
    String? id,
    required this.name,
    required this.type,
    required this.baseRate,
    this.rates = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  PayGroup copyWith({
    String? id,
    String? name,
    PayType? type,
    double? baseRate,
    List<PayRate>? rates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseRate: baseRate ?? this.baseRate,
      rates: rates ?? this.rates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mode': type.apiValue,
      'base_rate': baseRate,
      'rates': rates.map((r) => r.toJson()).toList(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'rates': rates.map((r) => r.toJson()).toList(),
    };
  }

  factory PayGroup.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] as String?) ?? 'hourly';
    final type = modeStr == 'flat' ? PayType.flat : PayType.hourly;

    final ratesData = json['rates'];
    List<PayRate> ratesList = [];
    if (ratesData is List) {
      ratesList = ratesData
          .map((r) => PayRate.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return PayGroup(
      id: (json['id'] is int ? json['id'].toString() : json['id']?.toString()) ?? '',
      name: json['name'] as String? ?? '',
      type: type,
      baseRate: _parseDouble(json['base_rate']),
      rates: ratesList,
    );
  }

  @override
  String toString() =>
      'PayGroup(name: $name, type: ${type.displayName}, baseRate: $baseRate)';
}
