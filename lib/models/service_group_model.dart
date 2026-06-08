import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

enum ServiceType {
  hourly,
  flat;

  String get displayName {
    switch (this) {
      case ServiceType.hourly:
        return 'Hourly';
      case ServiceType.flat:
        return 'Flat';
    }
  }

  String get apiValue => name;
}

class ServiceRate {
  final String id;
  final List<String> selectedDays;
  final double rate;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final DateTime? createdAt;

  ServiceRate({
    String? id,
    required this.selectedDays,
    required this.rate,
    required this.fromTime,
    required this.toTime,
    this.createdAt,
  }) : id = id ?? const Uuid().v4();

  ServiceRate copyWith({
    String? id,
    List<String>? selectedDays,
    double? rate,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    DateTime? createdAt,
  }) {
    return ServiceRate(
      id: id ?? this.id,
      selectedDays: selectedDays ?? this.selectedDays,
      rate: rate ?? this.rate,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      createdAt: createdAt ?? this.createdAt,
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
      default:
        return day;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': selectedDays.map(_shortenDay).toList(),
      'rate': rate,
      'from_time':
          '${fromTime.hour.toString().padLeft(2, '0')}:${fromTime.minute.toString().padLeft(2, '0')}:00',
      'to_time':
          '${toTime.hour.toString().padLeft(2, '0')}:${toTime.minute.toString().padLeft(2, '0')}:00',
    };
  }

  factory ServiceRate.fromJson(Map<String, dynamic> json) {
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

    return ServiceRate(
      id: json['id']?.toString(),
      selectedDays: selectedDays.map(_expandDay).toList(),
      rate: _parseDouble(json['rate']),
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
}

class ServiceGroup {
  final String id;
  final String name;
  final ServiceType type;
  final double baseRate;
  final List<ServiceRate> rates;
  final DateTime? createdAt;

  ServiceGroup({
    String? id,
    required this.name,
    required this.type,
    required this.baseRate,
    this.rates = const [],
    this.createdAt,
  }) : id = id ?? const Uuid().v4();

  ServiceGroup copyWith({
    String? id,
    String? name,
    ServiceType? type,
    double? baseRate,
    List<ServiceRate>? rates,
    DateTime? createdAt,
  }) {
    return ServiceGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      baseRate: baseRate ?? this.baseRate,
      rates: rates ?? this.rates,
      createdAt: createdAt ?? this.createdAt,
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

  factory ServiceGroup.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] as String?) ?? 'hourly';
    final type = modeStr == 'flat' ? ServiceType.flat : ServiceType.hourly;

    final ratesData = json['rates'];
    List<ServiceRate> ratesList = [];
    if (ratesData is List) {
      ratesList = ratesData
          .map((r) => ServiceRate.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return ServiceGroup(
      id: (json['id'] is int ? json['id'].toString() : json['id']?.toString()) ?? '',
      name: json['name'] as String? ?? '',
      type: type,
      baseRate: _parseDouble(json['base_rate']),
      rates: ratesList,
    );
  }
}
