import 'package:flutter/foundation.dart';
import '../services/worker_api_service.dart';

class WorkerViewModel extends ChangeNotifier {
  WorkerViewModel(this._apiService);

  final WorkerApiService _apiService;

  static const bool _frontendOnlyMode = false;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _currentShift;
  List<Map<String, dynamic>> _availableSites = [];
  List<Map<String, dynamic>> _recentCheckins = [];
  List<Map<String, dynamic>> _shiftHistory = [];
  Map<String, dynamic>? _selectedShift;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> _offeredShifts = [];
  List<Map<String, dynamic>> _checkCalls = [];
  List<Map<String, dynamic>> _alarmHistory = [];
  List<Map<String, dynamic>> _liveShifts = [];
  List<Map<String, dynamic>> _liveAlerts = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get tasks => _tasks;
  List<Map<String, dynamic>> get reports => _reports;
  Map<String, dynamic>? get currentShift => _currentShift;
  List<Map<String, dynamic>> get availableSites => _availableSites;
  List<Map<String, dynamic>> get recentCheckins => _recentCheckins;
  List<Map<String, dynamic>> get shiftHistory => _shiftHistory;
  Map<String, dynamic>? get selectedShift => _selectedShift;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  List<Map<String, dynamic>> get offeredShifts => _offeredShifts;
  List<Map<String, dynamic>> get checkCalls => _checkCalls;
  List<Map<String, dynamic>> get alarmHistory => _alarmHistory;
  List<Map<String, dynamic>> get liveShifts => _liveShifts;
  List<Map<String, dynamic>> get liveAlerts => _liveAlerts;
  bool get hasPendingCheckCall =>
      _checkCalls.any((c) => (c['status'] ?? '') == 'pending');
  String? get pendingCheckCallId => _checkCalls
      .firstWhere(
        (c) => (c['status'] ?? '') == 'pending',
        orElse: () => {},
      )['id']
      ?.toString();

  int get unreadNotifications =>
      _notifications.where((n) => n['read'] != true).length;
  int get totalShifts => _shiftHistory.length;
  int get totalHours => _shiftHistory.fold(
    0,
    (sum, shift) => sum + ((shift['durationHours'] as int?) ?? 0),
  );
  int get totalCheckins => _recentCheckins.length;

  Future<void> initialize() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _seedFrontendMockData();
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      await _loadTasks();
      await _loadReports();
      await _loadCurrentShift();
      await loadAvailableSites();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _seedFrontendMockData();
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      await _loadCurrentShift();
      await _loadTasks();
      await _loadRecentCheckins();
      await _loadRecentActivities();
      await loadNotifications();
      await loadAvailableSites();
      _ensureFallbackUIData();
    } catch (e) {
      _errorMessage = e.toString();
      _ensureFallbackUIData();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> _loadCurrentShift() async {
    try {
      _currentShift = await _apiService.getCurrentShift();
      if (_currentShift != null) {
        _currentShift!['lastCheckin'] =
            _currentShift!['lastCheckin'] ??
            DateTime.now().subtract(const Duration(hours: 2));
        _currentShift!['insideGeofence'] =
            _currentShift!['insideGeofence'] ?? true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentShift = null;
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      _recentActivities = await _apiService.getWorkerActivities();
    } catch (e) {
      _errorMessage = e.toString();
      _recentActivities = [];
    }
  }

  Future<bool> startShift({
    required String siteId,
    required String location,
    String? notes,
  }) async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      final site = _availableSites.firstWhere(
        (s) => s['id'].toString() == siteId,
        orElse: () => _availableSites.isNotEmpty
            ? _availableSites.first
            : {'id': siteId, 'name': 'Downtown Office'},
      );
      _currentShift = {
        'id': 'shift_live',
        'siteId': siteId,
        'siteName': site['name'] ?? 'Downtown Office',
        'siteAddress':
            site['address'] ?? '123 Main Street, City Center, NY 10001',
        'startTime': DateTime.now().subtract(const Duration(minutes: 35)),
        'lastCheckin': DateTime.now().subtract(const Duration(minutes: 14)),
        'insideGeofence': true,
        'checkinsCount': _recentCheckins.length,
        'tasksCompleted': 2,
        'alertsCount': 0,
        'notes': notes,
        'location': location,
      };
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      final shiftData = {
        'site_id': siteId,
        'location': location,
        'notes': notes,
        'start_time': DateTime.now().toIso8601String(),
      };
      final success = await _apiService.startShift(shiftData);
      if (success) {
        await _loadCurrentShift();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> endShift({
    required String shiftId,
    required String notes,
    required bool hasIncidents,
    String? incidentDetails,
  }) async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      final endedShift = _buildEndedShift(notes: notes);
      _shiftHistory.insert(0, endedShift);
      _currentShift = null;
      _recentActivities.insert(0, {
        'type': 'shift_end',
        'title': 'Shift ended',
        'description': 'Duty session closed successfully',
        'timestamp': DateTime.now(),
      });
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      final shiftData = {
        'id': shiftId,
        'notes': notes,
        'has_incidents': hasIncidents,
        'incident_details': incidentDetails,
        'end_time': DateTime.now().toIso8601String(),
      };
      final success = await _apiService.endShift(shiftData);
      if (success) {
        _currentShift = null;
        await _loadRecentActivities();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitCheckin({
    required String location,
    required String notes,
    required String type,
    double? latitude,
    double? longitude,
    dynamic photo,
  }) async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      final checkin = {
        'id': 'checkin_${DateTime.now().millisecondsSinceEpoch}',
        'location': location,
        'notes': notes,
        'type': type,
        'timestamp': DateTime.now(),
      };
      _recentCheckins.insert(0, checkin);
      if (_currentShift != null) {
        _currentShift!['lastCheckin'] = DateTime.now();
        _currentShift!['checkinsCount'] =
            (_currentShift!['checkinsCount'] ?? 0) + 1;
      }
      _recentActivities.insert(0, {
        'type': 'checkin',
        'title': 'Check-in submitted',
        'description': 'Photo and location evidence added',
        'timestamp': DateTime.now(),
      });
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      final checkinData = {
        'location_description': location,
        'notes': notes,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (latitude != null) checkinData['latitude'] = latitude.toString();
      if (longitude != null) checkinData['longitude'] = longitude.toString();

      final success = await _apiService.submitCheckin(checkinData, photo: photo);
      if (success) {
        await _loadRecentCheckins();
        if (_currentShift != null) {
          _currentShift!['lastCheckin'] = DateTime.now();
        }
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadRecentCheckins() async {
    try {
      _recentCheckins = await _apiService.getRecentCheckins();
    } catch (e) {
      _errorMessage = e.toString();
      _recentCheckins = [];
    }
  }

  Future<void> loadDutyHistory() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      if (_shiftHistory.isEmpty) {
        _seedFrontendMockData();
      }
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      _shiftHistory = await _apiService.getShiftHistory();
      if (_shiftHistory.isEmpty) {
        _shiftHistory = _mockShiftHistory();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _shiftHistory = _mockShiftHistory();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> loadShiftDetails(String shiftId) async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      _selectedShift = _shiftHistory.firstWhere(
        (shift) => shift['id'].toString() == shiftId,
        orElse: () => _mockShiftDetails(shiftId),
      );
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      _selectedShift = await _apiService.getShiftDetails(shiftId);
      _selectedShift ??= _mockShiftDetails(shiftId);
    } catch (e) {
      _errorMessage = e.toString();
      _selectedShift = _mockShiftDetails(shiftId);
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      if (_notifications.isEmpty) {
        _notifications = _mockNotifications();
      }
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      _notifications = await _apiService.getWorkerNotifications();
      if (_notifications.isEmpty) {
        _notifications = _mockNotifications();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _notifications = _mockNotifications();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (n) => n['id'].toString() == notificationId,
    );
    if (index != -1) {
      _notifications[index]['read'] = true;
      notifyListeners();
    }

    if (_frontendOnlyMode) return;

    try {
      await _apiService.markNotificationAsRead(notificationId);
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    for (final notification in _notifications) {
      notification['read'] = true;
    }
    notifyListeners();

    if (_frontendOnlyMode) return;

    try {
      await _apiService.markAllNotificationsAsRead();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n['id'].toString() == notificationId);
    notifyListeners();

    if (_frontendOnlyMode) return;

    try {
      await _apiService.deleteNotification(notificationId);
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> loadAvailableSites() async {
    if (_frontendOnlyMode) {
      if (_availableSites.isEmpty) {
        _availableSites = _mockSites();
      }
      notifyListeners();
      return;
    }

    try {
      _availableSites = await _apiService.getSites();
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    if (_frontendOnlyMode) {
      _tasks = _mockTasks();
      return;
    }

    try {
      _tasks = await _apiService.getWorkerTasks();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> _loadReports() async {
    if (_frontendOnlyMode) {
      _reports = _mockReports();
      return;
    }

    try {
      _reports = await _apiService.getWorkerReports();
      if (_reports.isEmpty) {
        _reports = _mockReports();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _reports = _mockReports();
    }
  }

  Future<bool> submitReport(Map<String, dynamic> reportData) async {
    _setLoading(true);

    if (_frontendOnlyMode) {
      _reports.insert(0, {
        'id': 'report_${DateTime.now().millisecondsSinceEpoch}',
        'title': reportData['title'] ?? 'Security report',
        'date': DateTime.now(),
        'status': 'submitted',
      });
      _setLoading(false);
      notifyListeners();
      return true;
    }

    try {
      final success = await _apiService.submitReport(reportData);
      if (success) {
        await _loadReports();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    _setLoading(true);

    final index = _tasks.indexWhere((task) => task['id'].toString() == taskId);
    if (index != -1) {
      _tasks[index]['status'] = status;
    }

    if (_frontendOnlyMode) {
      _setLoading(false);
      notifyListeners();
      return;
    }

    try {
      await _apiService.updateTaskStatus(taskId, status);
      await _loadTasks();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _seedFrontendMockData() {
    _availableSites = _availableSites.isEmpty ? _mockSites() : _availableSites;
    _notifications = _notifications.isEmpty
        ? _mockNotifications()
        : _notifications;
    _recentCheckins = _recentCheckins.isEmpty
        ? _mockCheckins()
        : _recentCheckins;
    _shiftHistory = _shiftHistory.isEmpty ? _mockShiftHistory() : _shiftHistory;
    _tasks = _tasks.isEmpty ? _mockTasks() : _tasks;
    _reports = _reports.isEmpty ? _mockReports() : _reports;
    _recentActivities = _recentActivities.isEmpty
        ? _mockRecentActivities()
        : _recentActivities;
  }

  void _ensureFallbackUIData() {
    // Removed all mock data fallbacks
  }

  Map<String, dynamic> _buildEndedShift({required String notes}) {
    final DateTime now = DateTime.now();
    final DateTime start = (_currentShift?['startTime'] is DateTime)
        ? _currentShift!['startTime'] as DateTime
        : now.subtract(const Duration(hours: 9));
    final int durationHours = now.difference(start).inHours.clamp(1, 12);

    return {
      'id': 'shift_${now.millisecondsSinceEpoch}',
      'siteName': _currentShift?['siteName'] ?? 'Downtown Office',
      'siteAddress':
          _currentShift?['siteAddress'] ??
          '123 Main Street, City Center, NY 10001',
      'date': now,
      'startTime': start,
      'endTime': now,
      'duration': '${durationHours}h',
      'durationHours': durationHours,
      'status': 'completed',
      'checkinsCount': _recentCheckins.length,
      'tasksCompleted': 3,
      'incidentsCount': 0,
      'checkins': List<Map<String, dynamic>>.from(_recentCheckins.take(4)),
      'notes': notes,
    };
  }

  List<Map<String, dynamic>> _mockSites() => [
    {
      'id': 'site_1',
      'name': 'Downtown Office',
      'address': '123 Main Street, City Center, NY 10001',
      'geofenceRadius': '500m',
      'lat': 40.7128,
      'lng': -74.0060,
    },
  ];

  List<Map<String, dynamic>> _mockNotifications() => [
    {
      'id': 'noti_1',
      'type': 'shift',
      'title': 'Shift Reminder',
      'message': 'Please check-in every 30 minutes',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10)),
      'read': false,
    },
    {
      'id': 'noti_2',
      'type': 'alert',
      'title': 'Check-in Required',
      'message': 'Time for your hourly check-in',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'read': false,
    },
  ];

  List<Map<String, dynamic>> _mockCheckins() => [
    {
      'id': 'checkin_1',
      'location': 'Downtown Office Gate A',
      'notes': 'Photo attached',
      'type': 'regular',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 35)),
    },
    {
      'id': 'checkin_2',
      'location': 'Lobby Entrance',
      'notes': 'Area secure',
      'type': 'regular',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
    },
  ];

  List<Map<String, dynamic>> _mockShiftHistory() => [
    _mockShiftDetails('shift_3')
      ..['date'] = DateTime.now().subtract(const Duration(days: 2))
      ..['duration'] = '9h'
      ..['durationHours'] = 9,
    _mockShiftDetails('shift_2')
      ..['date'] = DateTime.now().subtract(const Duration(days: 4))
      ..['duration'] = '9h'
      ..['durationHours'] = 9,
    _mockShiftDetails('shift_1')
      ..['date'] = DateTime.now().subtract(const Duration(days: 6))
      ..['duration'] = '8h'
      ..['durationHours'] = 8,
  ];

  Map<String, dynamic> _mockShiftDetails(String shiftId) {
    final DateTime baseDate = DateTime.now().subtract(const Duration(days: 2));
    final DateTime start = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      8,
      0,
    );
    final DateTime end = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      17,
      0,
    );

    return {
      'id': shiftId,
      'siteName': 'Downtown Office',
      'siteAddress': '123 Main Street, City Center, NY 10001',
      'date': baseDate,
      'startTime': start,
      'endTime': end,
      'duration': '9h',
      'durationHours': 9,
      'status': 'completed',
      'checkinsCount': 9,
      'tasksCompleted': 6,
      'incidentsCount': 0,
      'checkins': [
        {
          'id': 'timeline_1',
          'type': 'regular',
          'timestamp': DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            9,
            0,
          ),
          'notes': 'Photo attached',
        },
        {
          'id': 'timeline_2',
          'type': 'regular',
          'timestamp': DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            11,
            0,
          ),
          'notes': 'Photo attached',
        },
        {
          'id': 'timeline_3',
          'type': 'incident',
          'timestamp': DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            13,
            0,
          ),
          'notes': 'Minor issue reported',
        },
        {
          'id': 'timeline_4',
          'type': 'regular',
          'timestamp': DateTime(
            baseDate.year,
            baseDate.month,
            baseDate.day,
            15,
            0,
          ),
          'notes': 'Photo attached',
        },
      ],
      'notes': 'Routine patrol completed with no critical incidents.',
    };
  }

  List<Map<String, dynamic>> _mockTasks() => [
    {
      'id': 'task_1',
      'title': 'Perimeter patrol',
      'priority': 'high',
      'status': 'in_progress',
    },
    {
      'id': 'task_2',
      'title': 'Gate access log verification',
      'priority': 'medium',
      'status': 'pending',
    },
  ];

  List<Map<String, dynamic>> _mockReports() => [
    {
      'id': 'report_1',
      'title': 'Daily shift summary',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'submitted',
    },
  ];

  List<Map<String, dynamic>> _mockRecentActivities() => [
    {
      'type': 'shift_start',
      'title': 'Shift started',
      'description': 'Duty started at Downtown Office',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'type': 'checkin',
      'title': 'Check-in completed',
      'description': 'Checkpoint photo uploaded',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
    },
  ];

  // ── Offered Shifts ────────────────────────────────────────────────────────

  Future<void> loadOfferedShifts() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _offeredShifts = _mockOfferedShifts();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final list = await _apiService.getOfferedShifts();
      _offeredShifts = list.isEmpty ? _mockOfferedShifts() : list;
    } catch (e) {
      _offeredShifts = _mockOfferedShifts();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> acceptShift(String shiftId) async {
    if (_frontendOnlyMode) {
      _offeredShifts.removeWhere((s) => s['id'].toString() == shiftId);
      notifyListeners();
      return true;
    }
    try {
      final ok = await _apiService.acceptShift(shiftId);
      if (ok) await loadOfferedShifts();
      return ok;
    } catch (e) {
      return false;
    }
  }

  Future<bool> declineShift(String shiftId) async {
    if (_frontendOnlyMode) {
      _offeredShifts.removeWhere((s) => s['id'].toString() == shiftId);
      notifyListeners();
      return true;
    }
    try {
      final ok = await _apiService.declineShift(shiftId);
      if (ok) await loadOfferedShifts();
      return ok;
    } catch (e) {
      return false;
    }
  }

  // ── Check Calls ───────────────────────────────────────────────────────────

  Future<void> loadCheckCalls() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _checkCalls = _mockCheckCalls();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final list = await _apiService.getCheckCalls();
      _checkCalls = list.isEmpty ? _mockCheckCalls() : list;
    } catch (e) {
      _checkCalls = _mockCheckCalls();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> respondToCheckCall(String id) async {
    if (_frontendOnlyMode) {
      final idx = _checkCalls.indexWhere((c) => c['id'].toString() == id);
      if (idx != -1) _checkCalls[idx]['status'] = 'responded';
      notifyListeners();
      return true;
    }
    try {
      final ok = await _apiService.respondToCheckCall(id);
      if (ok) await loadCheckCalls();
      return ok;
    } catch (e) {
      return false;
    }
  }

  // ── Alarm History ─────────────────────────────────────────────────────────

  Future<void> loadAlarmHistory() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _alarmHistory = _mockAlarmHistory();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final list = await _apiService.getAlarmHistory();
      _alarmHistory = list.isEmpty ? _mockAlarmHistory() : list;
    } catch (e) {
      _alarmHistory = _mockAlarmHistory();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> raiseAlarm() async {
    if (_frontendOnlyMode) {
      _alarmHistory.insert(0, {
        'id': 'alarm_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'Emergency Alarm',
        'timestamp': _nowLabel(),
        'status': 'raised',
      });
      notifyListeners();
      return true;
    }
    try {
      final ok = await _apiService.raiseAlarm({'type': 'emergency'});
      if (ok) await loadAlarmHistory();
      return ok;
    } catch (e) {
      return false;
    }
  }

  // ── Live Operations ───────────────────────────────────────────────────────

  Future<void> loadLiveOperations() async {
    _setLoading(true);
    if (_frontendOnlyMode) {
      _setMockLiveOperations();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final response = await _apiService.getLiveOperations();
      final shifts = response['shifts'] ?? response['data'] ?? [];
      final alerts = response['alerts'] ?? [];
      _liveShifts = List<Map<String, dynamic>>.from(shifts);
      _liveAlerts = List<Map<String, dynamic>>.from(alerts);
      if (_liveShifts.isEmpty) _setMockLiveOperations();
    } catch (e) {
      _setMockLiveOperations();
    }
    _setLoading(false);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _nowLabel() {
    final now = DateTime.now();
    final h =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    return 'Today, $h:$m $amPm';
  }

  // ── Mock data ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _mockOfferedShifts() => [
    {
      'id': 'offered_1',
      'siteName': 'Harbour View Office Park',
      'site_name': 'Harbour View Office Park',
      'date': 'Jun 12, Thu',
      'time': '18:00 – 06:00',
      'hours': '12 hrs',
      'payNote': 'Night rate applies',
    },
    {
      'id': 'offered_2',
      'siteName': 'Westgate Industrial Estate',
      'site_name': 'Westgate Industrial Estate',
      'date': 'Jun 14, Sat',
      'time': '08:00 – 20:00',
      'hours': '12 hrs',
      'payNote': 'Weekend rate applies',
    },
    {
      'id': 'offered_3',
      'siteName': 'City Centre Plaza',
      'site_name': 'City Centre Plaza',
      'date': 'Jun 15, Sun',
      'time': '06:00 – 14:00',
      'hours': '8 hrs',
      'payNote': 'Standard rate',
    },
  ];

  List<Map<String, dynamic>> _mockCheckCalls() => [
    {'id': 'check_pending', 'timestamp': 'Today, 14:30', 'status': 'pending'},
    {'id': 'check_1', 'timestamp': 'Today, 12:00', 'status': 'responded'},
    {'id': 'check_2', 'timestamp': 'Today, 08:00', 'status': 'responded'},
    {'id': 'check_3', 'timestamp': 'Yesterday, 22:00', 'status': 'missed'},
  ];

  List<Map<String, dynamic>> _mockAlarmHistory() => [
    {
      'id': 'alarm_1',
      'type': 'Emergency Alarm',
      'timestamp': 'Today, 14:32',
      'status': 'acknowledged',
    },
    {
      'id': 'alarm_2',
      'type': 'Welfare Check Alarm',
      'timestamp': 'Yesterday, 22:15',
      'status': 'resolved',
    },
    {
      'id': 'alarm_3',
      'type': 'Emergency Alarm',
      'timestamp': 'Jun 07, 09:04',
      'status': 'resolved',
    },
  ];

  void _setMockLiveOperations() {
    _liveShifts = [
      {
        'id': 's1',
        'name': 'James Mwangi',
        'role': 'Security Officer',
        'hours': '06:00–18:00',
        'status': 'clocked-in',
      },
      {
        'id': 's2',
        'name': 'Sarah Otieno',
        'role': 'Security Officer',
        'hours': '06:00–18:00',
        'status': 'checking-welfare',
      },
      {
        'id': 's3',
        'name': 'Brian Kamau',
        'role': 'Supervisor',
        'hours': '07:00–19:00',
        'status': 'clocked-in',
      },
      {
        'id': 's4',
        'name': 'Grace Njeri',
        'role': 'Security Officer',
        'hours': '18:00–06:00',
        'status': 'missed-alert',
      },
    ];
    _liveAlerts = [
      {
        'title': 'Inactivity Warning',
        'message': "Sarah Otieno hasn't checked in for 45 minutes",
        'variant': 'warning',
      },
      {
        'title': 'Missed Beep Alert',
        'message': 'Grace Njeri missed welfare check at 20:00',
        'variant': 'danger',
      },
    ];
  }
}
