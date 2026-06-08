import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/service_group_model.dart';
import '../services/admin_api_service.dart';

class ServiceGroupViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  static const bool _mockMode = false;

  List<ServiceGroup> _groups = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalGroups => _groups.length;
  int get totalRates =>
      _groups.fold(0, (sum, group) => sum + group.rates.length);

  ServiceGroupViewModel(this._apiService);

  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_mockMode) {
      _groups = _getFallbackGroups();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final groupsData = await _apiService.getServiceGroups();
      _groups = groupsData.map((data) => ServiceGroup.fromJson(data)).toList();
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Loaded ${_groups.length} service groups');
      for (final g in _groups) {
        debugPrint('ServiceGroup: id=${g.id}, name=${g.name}, type=${g.type}, baseRate=${g.baseRate}, rates=${g.rates.length}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _groups = [];
      notifyListeners();
      debugPrint('Error loading service groups: $_error');
    }
  }

  Future<void> createGroup(ServiceGroup group) async {
    if (_mockMode) {
      _groups.insert(0, group);
      notifyListeners();
      return;
    }
    try {
      await _apiService.createServiceGroup(group.toJson());
      try {
        await loadGroups();
      } catch (e) {
        debugPrint('Reload after create failed: $e');
        _groups.insert(0, group);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGroup(ServiceGroup group) async {
    if (_mockMode) {
      final index = _groups.indexWhere((g) => g.id == group.id);
      if (index != -1) {
        _groups[index] = group;
        notifyListeners();
      }
      return;
    }
    try {
      await _apiService.updateServiceGroup(group.id, group.toJson());
      try {
        await loadGroups();
      } catch (e) {
        debugPrint('Reload after update failed: $e');
        final index = _groups.indexWhere((g) => g.id == group.id);
        if (index != -1) {
          _groups[index] = group;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteGroup(String id) async {
    if (_mockMode) {
      _groups.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    }
    try {
      await _apiService.deleteServiceGroup(id);
      _groups.removeWhere((g) => g.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addRate(String groupId, ServiceRate rate) async {
    if (_mockMode) {
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(
          rates: [..._groups[index].rates, rate],
        );
        notifyListeners();
      }
      return true;
    }
    try {
      await _apiService.createServiceRate(groupId, rate.toJson());
      try {
        await loadGroups();
      } catch (e) {
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = _groups[index].copyWith(
            rates: [..._groups[index].rates, rate],
          );
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRate(String groupId, ServiceRate rate) async {
    if (rate.id.isEmpty) return false;

    if (_mockMode) {
      final groupIndex = _groups.indexWhere((g) => g.id == groupId);
      if (groupIndex != -1) {
        final rateIndex = _groups[groupIndex].rates.indexWhere((r) => r.id == rate.id);
        if (rateIndex != -1) {
          final updatedRates = [..._groups[groupIndex].rates];
          updatedRates[rateIndex] = rate;
          _groups[groupIndex] = _groups[groupIndex].copyWith(rates: updatedRates);
          notifyListeners();
          return true;
        }
      }
      return false;
    }
    try {
      await _apiService.updateServiceRate(rate.id, rate.toJson());
      try {
        await loadGroups();
      } catch (e) {
        final groupIndex = _groups.indexWhere((g) => g.id == groupId);
        if (groupIndex != -1) {
          final rateIndex = _groups[groupIndex].rates.indexWhere((r) => r.id == rate.id);
          if (rateIndex != -1) {
            final updatedRates = [..._groups[groupIndex].rates];
            updatedRates[rateIndex] = rate;
            _groups[groupIndex] = _groups[groupIndex].copyWith(rates: updatedRates);
            notifyListeners();
          }
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRate(String groupId, String rateId) async {
    if (_mockMode) {
      final index = _groups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _groups[index] = _groups[index].copyWith(
          rates: _groups[index].rates.where((r) => r.id != rateId).toList(),
        );
        notifyListeners();
      }
      return true;
    }
    try {
      await _apiService.deleteServiceRate(rateId);
      try {
        await loadGroups();
      } catch (e) {
        final index = _groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          _groups[index] = _groups[index].copyWith(
            rates: _groups[index].rates.where((r) => r.id != rateId).toList(),
          );
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<ServiceGroup> _getFallbackGroups() {
    return [
      ServiceGroup(
        name: 'Weekday Security',
        type: ServiceType.hourly,
        baseRate: 25.0,
        rates: [
          ServiceRate(
            selectedDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
            rate: 25.0,
            fromTime: const TimeOfDay(hour: 9, minute: 0),
            toTime: const TimeOfDay(hour: 17, minute: 0),
          ),
        ],
      ),
      ServiceGroup(
        name: 'Weekend Service',
        type: ServiceType.hourly,
        baseRate: 30.0,
        rates: [
          ServiceRate(
            selectedDays: ['Saturday', 'Sunday'],
            rate: 30.0,
            fromTime: const TimeOfDay(hour: 10, minute: 0),
            toTime: const TimeOfDay(hour: 18, minute: 0),
          ),
        ],
      ),
    ];
  }
}
