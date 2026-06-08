class CompanySettings {
  final bool enableDigitalOccurrenceLogs;
  final bool enableTwoFactorAuthentication;
  final String liveOperationsListSorting;
  final List<String> customClockInQuestionnaire;
  final String? defaultPayGroupId;
  final String? defaultServiceGroupId;
  final double geofenceCheckInDistance;
  final int shiftAlertResponseTime;
  final DateTime? updatedAt;

  CompanySettings({
    this.enableDigitalOccurrenceLogs = true,
    this.enableTwoFactorAuthentication = false,
    this.liveOperationsListSorting = 'time-asc',
    List<String>? customClockInQuestionnaire,
    this.defaultPayGroupId,
    this.defaultServiceGroupId,
    this.geofenceCheckInDistance = 100,
    this.shiftAlertResponseTime = 10,
    this.updatedAt,
  }) : customClockInQuestionnaire =
           customClockInQuestionnaire ?? ['', '', '', '', ''];

  CompanySettings copyWith({
    bool? enableDigitalOccurrenceLogs,
    bool? enableTwoFactorAuthentication,
    String? liveOperationsListSorting,
    List<String>? customClockInQuestionnaire,
    String? defaultPayGroupId,
    String? defaultServiceGroupId,
    double? geofenceCheckInDistance,
    int? shiftAlertResponseTime,
    DateTime? updatedAt,
  }) {
    return CompanySettings(
      enableDigitalOccurrenceLogs:
          enableDigitalOccurrenceLogs ?? this.enableDigitalOccurrenceLogs,
      enableTwoFactorAuthentication:
          enableTwoFactorAuthentication ?? this.enableTwoFactorAuthentication,
      liveOperationsListSorting:
          liveOperationsListSorting ?? this.liveOperationsListSorting,
      customClockInQuestionnaire:
          customClockInQuestionnaire ?? this.customClockInQuestionnaire,
      defaultPayGroupId: defaultPayGroupId ?? this.defaultPayGroupId,
      defaultServiceGroupId:
          defaultServiceGroupId ?? this.defaultServiceGroupId,
      geofenceCheckInDistance:
          geofenceCheckInDistance ?? this.geofenceCheckInDistance,
      shiftAlertResponseTime:
          shiftAlertResponseTime ?? this.shiftAlertResponseTime,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable_digital_occurrence_logs': enableDigitalOccurrenceLogs,
      'enable_two_factor_authentication': enableTwoFactorAuthentication,
      'live_operations_list_sorting': liveOperationsListSorting,
      'custom_clock_in_questionnaire': customClockInQuestionnaire,
      'default_pay_group_id': defaultPayGroupId,
      'default_service_group_id': defaultServiceGroupId,
      'geofence_check_in_distance': geofenceCheckInDistance,
      'shift_alert_response_time': shiftAlertResponseTime,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory CompanySettings.fromJson(Map<String, dynamic> json) {
    final questions =
        (json['custom_clock_in_questionnaire'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    while (questions.length < 5) {
      questions.add('');
    }

    return CompanySettings(
      enableDigitalOccurrenceLogs:
          json['enable_digital_occurrence_logs'] as bool? ?? true,
      enableTwoFactorAuthentication:
          json['enable_two_factor_authentication'] as bool? ?? false,
      liveOperationsListSorting:
          json['live_operations_list_sorting'] as String? ?? 'time-asc',
      customClockInQuestionnaire: questions.take(5).toList(),
      defaultPayGroupId: json['default_pay_group_id'] as String?,
      defaultServiceGroupId: json['default_service_group_id'] as String?,
      geofenceCheckInDistance:
          (json['geofence_check_in_distance'] as num?)?.toDouble() ?? 100,
      shiftAlertResponseTime: json['shift_alert_response_time'] as int? ?? 10,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
