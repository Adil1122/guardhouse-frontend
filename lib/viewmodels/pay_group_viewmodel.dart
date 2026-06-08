import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/pay_group_model.dart';
import '../services/admin_api_service.dart';

class PayGroupViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  // Set to true to work locally without API integration.
  static const bool _mockMode = false;

  List<PayGroup> _payGroups = [];
  bool _isLoading = false;
  String? _error;

  List<PayGroup> get payGroups => _payGroups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalPayGroups => _payGroups.length;
  int get hourlyGroupsCount =>
      _payGroups.where((g) => g.type == PayType.hourly).length;
  int get flatGroupsCount =>
      _payGroups.where((g) => g.type == PayType.flat).length;

  PayGroupViewModel(this._apiService);

  Future<void> loadPayGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('loadPayGroups: mockMode=$_mockMode');

    if (_mockMode) {
      _payGroups = _getFallbackPayGroups();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final groupsData = await _apiService.getPayGroups();
      debugPrint('API returned ${groupsData.length} items');
      for (final data in groupsData) {
        debugPrint('Item: id=${data['id']}, name=${data['name']}');
        try {
          final pg = PayGroup.fromJson(data);
          debugPrint('Parsed: id=${pg.id}, name=${pg.name}');
        } catch (e) {
          debugPrint('Error parsing: $e');
        }
      }
      _payGroups = groupsData.map((data) => PayGroup.fromJson(data)).toList();
      _isLoading = false;
      notifyListeners();
      
      // Debug: print loaded groups
      debugPrint('Loaded ${_payGroups.length} pay groups');
      for (final g in _payGroups) {
        debugPrint('PayGroup: id=${g.id}, name=${g.name}, type=${g.type}, baseRate=${g.baseRate}, rates=${g.rates.length}');
      }
    } catch (e, stackTrace) {
      _error = e.toString();
      _isLoading = false;
      _payGroups = [];
      notifyListeners();
      debugPrint('Error loading pay groups: $_error');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> createPayGroup(PayGroup payGroup) async {
    if (_mockMode) {
      _payGroups.insert(0, payGroup);
      notifyListeners();
      return;
    }
    try {
      // Create on server
      await _apiService.createPayGroup(payGroup.toJson());
      
      // Try to reload, but don't fail if reload fails
      try {
        await loadPayGroups();
      } catch (e) {
        debugPrint('Reload after create failed: $e');
        // Add the new group to local list manually
        _payGroups.insert(0, payGroup);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePayGroup(PayGroup payGroup) async {
    if (_mockMode) {
      final index = _payGroups.indexWhere((g) => g.id == payGroup.id);
      if (index != -1) {
        _payGroups[index] = payGroup;
        notifyListeners();
      }
      return;
    }
    try {
      // Send full data for update including mode, name, base_rate, and rates
      debugPrint('Updating pay group ${payGroup.id}');
      await _apiService.updatePayGroup(payGroup.id, payGroup.toJson());
      debugPrint('Update API call succeeded');
      
      // Try to reload, but don't fail if reload fails
      try {
        await loadPayGroups();
        debugPrint('Reload succeeded');
      } catch (e) {
        debugPrint('Reload failed but continuing: $e');
        // Update local data manually
        final index = _payGroups.indexWhere((g) => g.id == payGroup.id);
        if (index != -1) {
          _payGroups[index] = payGroup;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error updating pay group: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deletePayGroup(String id) async {
    if (_mockMode) {
      _payGroups.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    }
    try {
      await _apiService.deletePayGroup(id);
      _payGroups.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addRateToGroup(String groupId, PayRate rate) async {
    final index = _payGroups.indexWhere((g) => g.id == groupId);
    if (index == -1) return false;

    if (_mockMode) {
      final group = _payGroups[index];
      _payGroups[index] = group.copyWith(
        rates: [...group.rates, rate],
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }

    try {
      await _apiService.createPayRate(groupId, rate.toJson());
      // Reload the pay group to get the new rate with server-generated ID
      await loadPayGroups();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRateInGroup(String groupId, PayRate rate) async {
    if (rate.id.isEmpty) return false;

    if (_mockMode) {
      final index = _payGroups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _payGroups[index];
        final rateIndex = group.rates.indexWhere((r) => r.id == rate.id);
        if (rateIndex != -1) {
          final updatedRates = [...group.rates];
          updatedRates[rateIndex] = rate;
          _payGroups[index] = group.copyWith(
            rates: updatedRates,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
          return true;
        }
      }
      return false;
    }

    try {
      await _apiService.updatePayRate(rate.id, rate.toJson());
      // Reload the pay group to get updated rates
      await loadPayGroups();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRateFromGroup(String groupId, String rateId) async {
    if (_mockMode) {
      final index = _payGroups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        final group = _payGroups[index];
        final updatedRates = group.rates.where((r) => r.id != rateId).toList();
        _payGroups[index] = group.copyWith(
          rates: updatedRates,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        return true;
      }
      return false;
    }

    try {
      await _apiService.deletePayRate(rateId);
      // Reload the pay group to update rates
      await loadPayGroups();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<PayGroup> _getFallbackPayGroups() {
    return [
      PayGroup(
        name: 'Security Officers',
        type: PayType.hourly,
        baseRate: 25.00,
        rates: [
          PayRate(
            selectedDays: [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
            ],
            payRate: 25.00,
            fromTime: const TimeOfDay(hour: 8, minute: 0),
            toTime: const TimeOfDay(hour: 17, minute: 0),
          ),
          PayRate(
            selectedDays: ['Saturday', 'Sunday'],
            payRate: 30.00,
            fromTime: const TimeOfDay(hour: 10, minute: 0),
            toTime: const TimeOfDay(hour: 18, minute: 0),
          ),
          PayRate(
            selectedDays: ['Public Holiday'],
            payRate: 40.00,
            fromTime: const TimeOfDay(hour: 8, minute: 0),
            toTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
      ),
      PayGroup(
        name: 'Night Shift',
        type: PayType.hourly,
        baseRate: 28.00,
        rates: [
          PayRate(
            selectedDays: [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
            ],
            payRate: 28.00,
            fromTime: const TimeOfDay(hour: 22, minute: 0),
            toTime: const TimeOfDay(hour: 6, minute: 0),
          ),
          PayRate(
            selectedDays: ['Saturday', 'Sunday', 'Public Holiday'],
            payRate: 35.00,
            fromTime: const TimeOfDay(hour: 22, minute: 0),
            toTime: const TimeOfDay(hour: 6, minute: 0),
          ),
        ],
      ),
      PayGroup(
        name: 'Manager - Daily Rate',
        type: PayType.flat,
        baseRate: 200.00,
        rates: [
          PayRate(
            selectedDays: [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
            ],
            payRate: 200.00,
            fromTime: const TimeOfDay(hour: 8, minute: 0),
            toTime: const TimeOfDay(hour: 17, minute: 0),
          ),
          PayRate(
            selectedDays: ['Saturday', 'Sunday'],
            payRate: 250.00,
            fromTime: const TimeOfDay(hour: 10, minute: 0),
            toTime: const TimeOfDay(hour: 18, minute: 0),
          ),
        ],
      ),
    ];
  }
}
