import 'package:flutter/foundation.dart';
import '../models/organization_compliance_model.dart';
import '../services/admin_api_service.dart';

class OrganizationComplianceViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  // Keep false in normal app flow so compliances use backend APIs.
  static const bool _mockMode = false;

  List<OrganizationCompliance> _compliances = [];
  bool _isLoading = false;
  String? _error;

  List<OrganizationCompliance> get compliances => _compliances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stats
  int get totalCompliances => _compliances.length;
  int get criticalCompliancesCount =>
      _compliances.where((c) => c.isCritical).length;
  int get customerVisibleCount =>
      _compliances.where((c) => c.showToCustomer).length;
  double get averageRemindDays => _compliances.isEmpty
      ? 0.0
      : _compliances.map((c) => c.remindInDays).reduce((a, b) => a + b) /
            _compliances.length;

  OrganizationComplianceViewModel(this._apiService) {
    loadCompliances();
  }

  Future<void> loadCompliances() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_mockMode) {
      _compliances = _fallbackCompliances();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final compliancesData = await _apiService.getOrganizationCompliances();
      _compliances = compliancesData
          .map((data) => OrganizationCompliance.fromJson(data))
          .toList();
    } catch (e) {
      _error = e.toString();
      if (_compliances.isEmpty) {
        _compliances = _fallbackCompliances();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCompliance(OrganizationCompliance compliance) async {
    if (_mockMode) {
      _compliances.add(compliance);
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createOrganizationCompliance(
        compliance.toJson(),
      );
      final newCompliance = OrganizationCompliance.fromJson(result);
      _compliances.add(newCompliance);
    } catch (e) {
      _error = e.toString();
      _compliances.add(compliance);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCompliance(OrganizationCompliance compliance) async {
    if (_mockMode) {
      final index = _compliances.indexWhere((c) => c.id == compliance.id);
      if (index != -1) {
        _compliances[index] = compliance.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateOrganizationCompliance(
        compliance.id,
        compliance.toJson(),
      );
      final index = _compliances.indexWhere((c) => c.id == compliance.id);
      if (index != -1) {
        _compliances[index] = compliance.copyWith(updatedAt: DateTime.now());
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCompliance(String id) async {
    if (_mockMode) {
      _compliances.removeWhere((c) => c.id == id);
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteOrganizationCompliance(id);
      _compliances.removeWhere((c) => c.id == id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleCriticalStatus(String id) async {
    final compliance = _compliances.firstWhere((c) => c.id == id);
    await updateCompliance(
      compliance.copyWith(isCritical: !compliance.isCritical),
    );
  }

  Future<void> toggleCustomerVisibility(String id) async {
    final compliance = _compliances.firstWhere((c) => c.id == id);
    await updateCompliance(
      compliance.copyWith(showToCustomer: !compliance.showToCustomer),
    );
  }

  List<OrganizationCompliance> _fallbackCompliances() {
    final now = DateTime.now();
    return [
      OrganizationCompliance(
        id: 'comp-1',
        name: 'SIA Licence',
        remindInDays: 30,
        isCritical: true,
        showToCustomer: true,
        createdAt: now,
        updatedAt: now,
      ),
      OrganizationCompliance(
        id: 'comp-2',
        name: 'First Aid Certificate',
        remindInDays: 60,
        isCritical: false,
        showToCustomer: false,
        createdAt: now,
        updatedAt: now,
      ),
      OrganizationCompliance(
        id: 'comp-3',
        name: 'Public Liability Insurance',
        remindInDays: 90,
        isCritical: true,
        showToCustomer: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
