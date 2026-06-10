import 'package:flutter/foundation.dart';
import '../models/digital_occurrence_log_model.dart';
import '../services/admin_api_service.dart';

class DigitalOccurrenceLogViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  static const bool _mockMode = false;

  List<DigitalOccurrenceLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  List<DigitalOccurrenceLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stats
  int get draftCount =>
      _logs.where((l) => l.status == DigitalOccurrenceStatus.draft).length;
  int get submittedCount =>
      _logs.where((l) => l.status == DigitalOccurrenceStatus.submitted).length;
  int get reviewedCount =>
      _logs.where((l) => l.status == DigitalOccurrenceStatus.reviewed).length;
  int get closedCount =>
      _logs.where((l) => l.status == DigitalOccurrenceStatus.closed).length;
  int get shownToCustomerCount =>
      _logs.where((l) => l.showToCustomer == true).length;

  DigitalOccurrenceLogViewModel(this._apiService);

  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_mockMode) {
      _logs = _getFallbackLogs();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final logsData = await _apiService.getDigitalOccurrenceLogs();
      _logs = logsData
          .map((data) => DigitalOccurrenceLog.fromJson(data))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (_logs.isEmpty) _logs = _getFallbackLogs();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createLog(DigitalOccurrenceLog log) async {
    if (_mockMode) {
      _logs.insert(0, log);
      notifyListeners();
      return;
    }
    try {
      final result = await _apiService.createDigitalOccurrenceLog(log.toJson());
      final newLog = DigitalOccurrenceLog.fromJson(result);
      _logs.insert(0, newLog);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateLog(DigitalOccurrenceLog log) async {
    if (_mockMode) {
      final index = _logs.indexWhere((l) => l.id == log.id);
      if (index != -1) {
        _logs[index] = log;
        notifyListeners();
      }
      return;
    }
    try {
      await _apiService.updateDigitalOccurrenceLog(log.id, log.toJson());
      final index = _logs.indexWhere((l) => l.id == log.id);
      if (index != -1) {
        _logs[index] = log;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    if (_mockMode) {
      _logs.removeWhere((l) => l.id == id);
      notifyListeners();
      return;
    }
    try {
      await _apiService.deleteDigitalOccurrenceLog(id);
      _logs.removeWhere((l) => l.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleShowToCustomer(String id) async {
    final index = _logs.indexWhere((l) => l.id == id);
    if (index != -1) {
      final log = _logs[index];
      final updatedLog = log.copyWith(
        showToCustomer: !log.showToCustomer,
        updatedAt: DateTime.now(),
      );
      if (_mockMode) {
        _logs[index] = updatedLog;
        notifyListeners();
        return;
      }
      try {
        await _apiService.updateDigitalOccurrenceLog(id, updatedLog.toJson());
        _logs[index] = updatedLog;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> submitLog(String id) async {
    final index = _logs.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updatedLog = _logs[index].copyWith(
        status: DigitalOccurrenceStatus.submitted,
        updatedAt: DateTime.now(),
      );
      if (_mockMode) {
        _logs[index] = updatedLog;
        notifyListeners();
        return;
      }
      try {
        await _apiService.updateDigitalOccurrenceLog(id, updatedLog.toJson());
        _logs[index] = updatedLog;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> reviewLog(String id) async {
    final index = _logs.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updatedLog = _logs[index].copyWith(
        status: DigitalOccurrenceStatus.reviewed,
        updatedAt: DateTime.now(),
      );
      if (_mockMode) {
        _logs[index] = updatedLog;
        notifyListeners();
        return;
      }
      try {
        await _apiService.updateDigitalOccurrenceLog(id, updatedLog.toJson());
        _logs[index] = updatedLog;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> closeLog(String id) async {
    final index = _logs.indexWhere((l) => l.id == id);
    if (index != -1) {
      final updatedLog = _logs[index].copyWith(
        status: DigitalOccurrenceStatus.closed,
        updatedAt: DateTime.now(),
      );
      if (_mockMode) {
        _logs[index] = updatedLog;
        notifyListeners();
        return;
      }
      try {
        await _apiService.updateDigitalOccurrenceLog(id, updatedLog.toJson());
        _logs[index] = updatedLog;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<String> downloadPdf(String id) async {
    try {
      // In a real app, this would call an API to generate PDF
      return '/path/to/pdf/occurrence_log_$id.pdf';
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  List<DigitalOccurrenceLog> _getFallbackLogs() {
    final now = DateTime.now();
    return [
      DigitalOccurrenceLog(
        date: now.subtract(const Duration(days: 2)),
        customerId: '1',
        customerName: 'ABC Corp',
        siteId: '1',
        siteName: 'Downtown Office',
        staffId: '1',
        staffName: 'John Smith',
        incidentDescription: 'Unauthorized access attempt at main gate',
        category: 'Security Incident',
        showToCustomer: true,
        status: DigitalOccurrenceStatus.submitted,
        notes: 'Incident was resolved by security team',
      ),
      DigitalOccurrenceLog(
        date: now.subtract(const Duration(days: 1)),
        customerId: '1',
        customerName: 'ABC Corp',
        siteId: '2',
        siteName: 'Market Place',
        staffId: '2',
        staffName: 'Jane Doe',
        incidentDescription: 'Fire alarm triggered in equipment room',
        category: 'Safety Alert',
        showToCustomer: true,
        status: DigitalOccurrenceStatus.reviewed,
        notes: 'False alarm - HVAC maintenance',
      ),
      DigitalOccurrenceLog(
        date: now,
        customerId: '2',
        customerName: 'XYZ Industries',
        siteId: '3',
        siteName: 'Warehouse A',
        staffId: '3',
        staffName: 'Mike Johnson',
        incidentDescription: 'Parking lot lighting malfunction',
        category: 'Maintenance',
        showToCustomer: false,
        status: DigitalOccurrenceStatus.draft,
        notes: 'Reported to facility management',
      ),
      DigitalOccurrenceLog(
        date: now.subtract(const Duration(days: 3)),
        customerId: '3',
        customerName: 'Global Solutions Ltd',
        siteId: '4',
        siteName: 'Office Complex C',
        staffId: '4',
        staffName: 'Sarah Williams',
        incidentDescription: 'CCTV system offline - North entrance',
        category: 'Equipment Failure',
        showToCustomer: true,
        status: DigitalOccurrenceStatus.closed,
        notes: 'System replaced and operational',
      ),
    ];
  }

  // ── Log Type Settings ──────────────────────────────────────────────────────

  List<OccurrenceLogTypeSetting> _logTypes = [
    const OccurrenceLogTypeSetting(
      id: 'clock_in',
      name: 'Clock-in',
      description:
          'Logged when a staff member clocks in at the start of a shift.',
      isActive: true,
    ),
    const OccurrenceLogTypeSetting(
      id: 'clock_out',
      name: 'Clock-out',
      description:
          'Logged when a staff member clocks out at the end of a shift.',
      isActive: true,
    ),
    const OccurrenceLogTypeSetting(
      id: 'missed_alert',
      name: 'Missed Alert',
      description: 'Logged when a scheduled alert is not acknowledged in time.',
      isActive: true,
    ),
    const OccurrenceLogTypeSetting(
      id: 'acknowledged_alert',
      name: 'Acknowledged Alert',
      description: 'Logged when a staff member acknowledges a scheduled alert.',
      isActive: true,
    ),
    const OccurrenceLogTypeSetting(
      id: 'qr_scan',
      name: 'QR Scans',
      description: 'Logged when a staff member scans a site QR checkpoint.',
      isActive: true,
    ),
  ];

  List<OccurrenceLogTypeSetting> get logTypes => _logTypes;

  void toggleLogType(String id) {
    final index = _logTypes.indexWhere((t) => t.id == id);
    if (index != -1) {
      _logTypes = List.from(_logTypes);
      _logTypes[index] = _logTypes[index].copyWith(
        isActive: !_logTypes[index].isActive,
      );
      notifyListeners();
    }
  }
}
