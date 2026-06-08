import 'package:flutter/foundation.dart';
import '../services/worker_api_service.dart';

class WorkerViewModel extends ChangeNotifier {
  WorkerViewModel(this._apiService) {
    _seedFrontendMockData();
  }

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
      await _loadRecentActivities();
      await loadNotifications();
      await loadAvailableSites();
      _ensureFallbackUIData();
    } catch (e) {
      _errorMessage = e.toString();
      _seedFrontendMockData();
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
        'location': location,
        'notes': notes,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      };
      final success = await _apiService.submitCheckin(checkinData);
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
      if (_availableSites.isEmpty) {
        _availableSites = _mockSites();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _availableSites = _mockSites();
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
      if (_tasks.isEmpty) {
        _tasks = _mockTasks();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _tasks = _mockTasks();
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
    _availableSites = _mockSites();
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
}
