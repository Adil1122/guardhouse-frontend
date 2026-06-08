class Metric {
  final String id;
  final String title;
  final String value;
  final String? trend;
  final String? detail;
  final DateTime date;

  Metric({
    required this.id,
    required this.title,
    required this.value,
    this.trend,
    this.detail,
    required this.date,
  });

  factory Metric.fromJson(Map<String, dynamic> json) {
    return Metric(
      id: json['id'] as String,
      title: json['title'] as String,
      value: json['value'] as String,
      trend: json['trend'] as String?,
      detail: json['detail'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'trend': trend,
      'detail': detail,
      'date': date.toIso8601String(),
    };
  }

  Metric copyWith({
    String? id,
    String? title,
    String? value,
    String? trend,
    String? detail,
    DateTime? date,
  }) {
    return Metric(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      trend: trend ?? this.trend,
      detail: detail ?? this.detail,
      date: date ?? this.date,
    );
  }
}

class Activity {
  final String id;
  final String day;
  final int workers;
  final int hours;

  Activity({
    required this.id,
    required this.day,
    required this.workers,
    required this.hours,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String? ?? '',
      day: json['day'] as String,
      workers: json['workers'] as int? ?? 0,
      hours: json['hours'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'day': day, 'workers': workers, 'hours': hours};
  }

  Activity copyWith({String? id, String? day, int? workers, int? hours}) {
    return Activity(
      id: id ?? this.id,
      day: day ?? this.day,
      workers: workers ?? this.workers,
      hours: hours ?? this.hours,
    );
  }
}

class Report {
  final String id;
  final List<Metric> metrics;
  final List<Activity> activities;
  final DateTime generatedAt;

  Report({
    required this.id,
    required this.metrics,
    required this.activities,
    required this.generatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      metrics:
          (json['metrics'] as List?)
              ?.map((m) => Metric.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      activities:
          (json['activities'] as List?)
              ?.map((a) => Activity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metrics': metrics.map((m) => m.toJson()).toList(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  Report copyWith({
    String? id,
    List<Metric>? metrics,
    List<Activity>? activities,
    DateTime? generatedAt,
  }) {
    return Report(
      id: id ?? this.id,
      metrics: metrics ?? this.metrics,
      activities: activities ?? this.activities,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
