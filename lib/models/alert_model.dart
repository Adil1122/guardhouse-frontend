enum AlertSeverity { critical, warning, info }

class Alert {
  final String id;
  final String title;
  final String message;
  final String workerName;
  final String location;
  final AlertSeverity severity;
  final DateTime createdAt;
  final bool isRead;

  Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.workerName,
    required this.location,
    this.severity = AlertSeverity.warning,
    required this.createdAt,
    this.isRead = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return createdAt.toString().split(' ')[0];
    }
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    String parseSeverity(String rawSeverity) {
      final lower = rawSeverity.toLowerCase();
      if (lower.contains('critical') || lower.contains('high')) {
        return 'critical';
      }
      return 'warning';
    }

    final severityStr = parseSeverity(json['severity'] as String? ?? 'warning');

    return Alert(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Alert',
      message:
          json['message'] as String? ?? json['description'] as String? ?? '',
      workerName:
          json['workerName'] as String? ??
          json['worker_name'] as String? ??
          'Unknown',
      location:
          json['location'] as String? ??
          json['site_name'] as String? ??
          'Unknown Site',
      severity: AlertSeverity.values.firstWhere(
        (s) => s.name == severityStr,
        orElse: () => AlertSeverity.warning,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'workerName': workerName,
      'location': location,
      'severity': severity.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  Alert copyWith({
    String? id,
    String? title,
    String? message,
    String? workerName,
    String? location,
    AlertSeverity? severity,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      workerName: workerName ?? this.workerName,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
