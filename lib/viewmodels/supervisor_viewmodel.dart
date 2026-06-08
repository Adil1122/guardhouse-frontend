import 'package:flutter/foundation.dart';
// Note: inline ignores remain where specific collection-if cases need them.
import '../services/supervisor_api_service.dart';

class SupervisorViewModel extends ChangeNotifier {
  final SupervisorApiService _apiService;

  // Set to true for client-review / demo mode – all data is local mock.
  static const bool _mockMode = true;

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard data
  Map<String, dynamic>? _activeSiteVisit;
  List<Map<String, dynamic>> _assignedSites = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _recentReports = [];
  Map<String, dynamic>? _statistics;

  // Report details
  Map<String, dynamic>? _selectedReport;

  // Notifications
  List<Map<String, dynamic>> _notifications = [];

  SupervisorViewModel(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get activeSiteVisit => _activeSiteVisit;
  List<Map<String, dynamic>> get assignedSites => _assignedSites;
  List<Map<String, dynamic>> get workers => _workers;
  List<Map<String, dynamic>> get recentReports => _recentReports;
  Map<String, dynamic>? get statistics => _statistics;
  Map<String, dynamic>? get selectedReport => _selectedReport;
  List<Map<String, dynamic>> get notifications => _notifications;

  // Computed properties
  int get unreadNotifications =>
      _notifications.where((n) => !(n['read'] ?? true)).length;
  int get totalWorkers => _statistics?['totalWorkers'] ?? 0;
  int get reportsToday => _statistics?['reportsToday'] ?? 0;
  int get activeSites => _statistics?['activeSites'] ?? 0;

  // Initialize supervisor data
  Future<void> initialize() async {
    _setLoading(true);
    if (_mockMode) {
      _seedMockData();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      await Future.wait([
        _loadActiveSiteVisit(),
        _loadAssignedSites(),
        _loadWorkers(),
        _loadRecentReports(),
        _loadStatistics(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Load dashboard data
  Future<void> loadDashboardData() async {
    _setLoading(true);
    if (_mockMode) {
      _seedMockData();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      await Future.wait([
        _loadActiveSiteVisit(),
        _loadRecentReports(),
        _loadStatistics(),
      ]);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Load active site visit
  Future<void> _loadActiveSiteVisit() async {
    if (_mockMode) return;
    try {
      _activeSiteVisit = await _apiService.getActiveSiteVisit();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Load assigned sites
  Future<void> loadAssignedSites() async {
    _setLoading(true);
    if (_mockMode) {
      _assignedSites = _mockAssignedSites();
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      _assignedSites = await _apiService.getAssignedSites();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  Future<void> _loadAssignedSites() async {
    if (_mockMode) {
      _assignedSites = _mockAssignedSites();
      return;
    }
    try {
      _assignedSites = await _apiService.getAssignedSites();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Load workers from API
  Future<void> _loadWorkers() async {
    if (_mockMode) {
      _workers = _mockWorkers();
      return;
    }
    try {
      _workers = await _apiService.getSupervisorWorkers();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Load recent reports
  Future<void> _loadRecentReports() async {
    if (_mockMode) {
      _recentReports = _mockRecentReports();
      return;
    }
    try {
      _recentReports = await _apiService.getRecentReports();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Load statistics from API
  Future<void> _loadStatistics() async {
    if (_mockMode) {
      _statistics = _mockStatistics();
      return;
    }
    try {
      _statistics = await _apiService.getSupervisorStatistics();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Start site visit
  Future<bool> startSiteVisit({
    required String siteId,
    required String location,
    required String purpose,
    String? notes,
  }) async {
    _setLoading(true);
    if (_mockMode) {
      final site = _assignedSites.firstWhere(
        (s) => s['id'].toString() == siteId,
        orElse: () => _assignedSites.isNotEmpty
            ? _assignedSites.first
            : {'id': siteId, 'name': 'Demo Site'},
      );
      _activeSiteVisit = {
        'id': 'visit_mock_001',
        'siteId': siteId,
        'siteName': site['name'] ?? 'Demo Site',
        'location': location,
        'purpose': purpose,
        'notes': notes,
        'startTime': DateTime.now().toIso8601String(),
        'status': 'active',
      };
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final result = await _apiService.startSiteVisit({
        'site_id': siteId,
        'location': location,
        'purpose': purpose,
        ...?(notes != null ? {'notes': notes} : null),
      });

      if (result.isNotEmpty) {
        _activeSiteVisit = result;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
        return true;
      }

      _errorMessage = 'Failed to start site visit';
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // End site visit
  Future<bool> endSiteVisit({
    required String summary,
    bool hasIssues = false,
    String? issuesDescription,
  }) async {
    _setLoading(true);
    if (_mockMode) {
      _activeSiteVisit = null;
      _errorMessage = null;
      _statistics = _mockStatistics();
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.endSiteVisit({
        'summary': summary,
        'has_issues': hasIssues,
        ...?(issuesDescription != null
            ? {'issues_description': issuesDescription}
            : null),
      });

      if (success) {
        _activeSiteVisit = null;
        _errorMessage = null;
        await _loadStatistics();
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

  // Submit report
  Future<String?> submitReport({
    required String siteId,
    required String reportType,
    required String title,
    required String description,
    String? findings,
    String? recommendations,
    required String priority,
    bool requiresAction = false,
  }) async {
    _setLoading(true);
    if (_mockMode) {
      final fakeId = 'RPT-MOCK-${DateTime.now().millisecondsSinceEpoch}';
      _recentReports.insert(0, {
        'id': fakeId,
        'title': title,
        'type': reportType,
        'priority': priority,
        'siteId': siteId,
        'status': 'Submitted',
        'createdAt': DateTime.now().toIso8601String(),
      });
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      return fakeId;
    }
    try {
      final reportId = await _apiService.submitSupervisorReport({
        'site_id': siteId,
        'report_type': reportType,
        'title': title,
        'description': description,
        ...?(findings != null ? {'findings': findings} : null),
        ...?(recommendations != null
            ? {'recommendations': recommendations}
            : null),
        'priority': priority,
        'requires_action': requiresAction,
      });

      if (reportId != null) {
        _errorMessage = null;
        await _loadRecentReports();
      }

      _setLoading(false);
      notifyListeners();
      return reportId;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Load report details
  Future<void> loadReportDetails(String reportId) async {
    _setLoading(true);
    if (_mockMode) {
      _selectedReport = _recentReports.firstWhere(
        (r) => r['id'] == reportId,
        orElse: () => {
          'id': reportId,
          'title': 'Mock Report',
          'status': 'Submitted',
        },
      );
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      _selectedReport = await _apiService.getSupervisorReportDetails(reportId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Load notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    if (_mockMode) {
      _notifications = _mockNotifications();
      _errorMessage = null;
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      _notifications = await _apiService.getSupervisorNotifications();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    if (_mockMode) {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) _notifications[index]['read'] = true;
      notifyListeners();
      return;
    }
    try {
      final success = await _apiService.markSupervisorNotificationAsRead(
        notificationId,
      );
      if (success) {
        final index = _notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          _notifications[index]['read'] = true;
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    _setLoading(true);
    if (_mockMode) {
      for (var n in _notifications) {
        n['read'] = true;
      }
      _setLoading(false);
      notifyListeners();
      return;
    }
    try {
      final success = await _apiService.markAllSupervisorNotificationsAsRead();
      if (success) {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (_mockMode) {
      _notifications.removeWhere((n) => n['id'] == notificationId);
      notifyListeners();
      return;
    }
    try {
      final success = await _apiService.deleteSupervisorNotification(
        notificationId,
      );
      if (success) {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Assign task to worker
  Future<bool> assignTask(
    String workerId,
    Map<String, dynamic> taskData,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.assignTask(workerId, taskData);
      if (success) {
        await _loadWorkers();
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

  // Review and approve/reject report
  Future<bool> reviewReport(
    String reportId,
    String action,
    String? comments,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _recentReports.indexWhere((r) => r['id'] == reportId);
      if (idx != -1)
        _recentReports[idx]['status'] = action == 'approve'
            ? 'Approved'
            : 'Rejected';
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.reviewReport(
        reportId,
        action,
        comments,
      );
      if (success) {
        await _loadRecentReports();
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

  // Refresh data
  Future<void> refresh() async {
    await loadDashboardData();
  }

  // ─── Mock data helpers ────────────────────────────────────────────────────

  void _seedMockData() {
    _assignedSites = _mockAssignedSites();
    _workers = _mockWorkers();
    _recentReports = _mockRecentReports();
    _statistics = _mockStatistics();
    _notifications = _mockNotifications();
  }

  List<Map<String, dynamic>> _mockAssignedSites() => [
    {
      'id': '301',
      'name': 'Main Office Building',
      'address': '123 Business Street, London',
      'status': 'Active',
      'assignedWorkers': 3,
    },
    {
      'id': '302',
      'name': 'Market Place',
      'address': '45 Market Street, Manchester',
      'status': 'Active',
      'assignedWorkers': 2,
    },
    {
      'id': '303',
      'name': 'Tech Park East',
      'address': '99 Innovation Drive, Birmingham',
      'status': 'Active',
      'assignedWorkers': 2,
    },
  ];

  List<Map<String, dynamic>> _mockWorkers() => [
    {
      'id': 'W1',
      'name': 'Mark Williams',
      'role': 'Security Officer',
      'site': 'Main Office Building',
      'status': 'On Duty',
      'clockedIn': true,
    },
    {
      'id': 'W2',
      'name': 'Lisa Brown',
      'role': 'Security Officer',
      'site': 'Market Place',
      'status': 'On Duty',
      'clockedIn': true,
    },
    {
      'id': 'W3',
      'name': 'Tom Carter',
      'role': 'Security Guard',
      'site': 'Tech Park East',
      'status': 'Off Duty',
      'clockedIn': false,
    },
    {
      'id': 'W4',
      'name': 'Priya Patel',
      'role': 'Security Officer',
      'site': 'Main Office Building',
      'status': 'On Duty',
      'clockedIn': true,
    },
  ];

  List<Map<String, dynamic>> _mockRecentReports() => [
    {
      'id': 'RPT001',
      'title': 'Night Patrol Summary',
      'type': 'Patrol',
      'priority': 'Low',
      'siteId': '301',
      'status': 'Reviewed',
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 6))
          .toIso8601String(),
    },
    {
      'id': 'RPT002',
      'title': 'Access Control Incident',
      'type': 'Incident',
      'priority': 'High',
      'siteId': '302',
      'status': 'Pending',
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    },
    {
      'id': 'RPT003',
      'title': 'Welfare Check Complete',
      'type': 'Welfare',
      'priority': 'Normal',
      'siteId': '303',
      'status': 'Submitted',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];

  Map<String, dynamic> _mockStatistics() => {
    'totalWorkers': 4,
    'reportsToday': 2,
    'activeSites': 3,
    'pendingReports': 1,
    'completedVisitsThisWeek': 5,
  };

  List<Map<String, dynamic>> _mockNotifications() => [
    {
      'id': 'N1',
      'title': 'Worker Clocked In',
      'body': 'Mark Williams clocked in at Main Office',
      'read': false,
      'type': 'info',
      'createdAt': DateTime.now()
          .subtract(const Duration(minutes: 30))
          .toIso8601String(),
    },
    {
      'id': 'N2',
      'title': 'Report Submitted',
      'body': 'Night Patrol report ready for review',
      'read': false,
      'type': 'info',
      'createdAt': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    },
    {
      'id': 'N3',
      'title': 'SIA Badge Expiry',
      'body': 'Tom Carter SIA badge expires in 14 days',
      'read': true,
      'type': 'alert',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];

  // ─────────────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
