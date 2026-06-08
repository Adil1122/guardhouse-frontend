import 'package:flutter/foundation.dart';
import '../models/company_settings_model.dart';
import '../services/admin_api_service.dart';

class CompanySettingsViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  // Keep false in normal app flow so company settings use backend APIs.
  static const bool _mockMode = false;

  CompanySettings _settings = CompanySettings();
  bool _isLoading = false;
  String? _error;

  CompanySettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CompanySettingsViewModel(this._apiService);

  Future<void> loadSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_mockMode) {
      _settings = _fallbackSettings();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final settingsData = await _apiService.getCompanySettings();
      if (settingsData.isNotEmpty) {
        _settings = CompanySettings.fromJson(settingsData);
      }
    } catch (e) {
      _settings = _fallbackSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(CompanySettings updatedSettings) async {
    if (_mockMode) {
      _settings = updatedSettings.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateCompanySettings(updatedSettings.toJson());
      _settings = updatedSettings.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      _settings = updatedSettings.copyWith(updatedAt: DateTime.now());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CompanySettings _fallbackSettings() {
    return CompanySettings(
      enableDigitalOccurrenceLogs: true,
      enableTwoFactorAuthentication: false,
      liveOperationsListSorting: 'time-asc',
      geofenceCheckInDistance: 100,
      shiftAlertResponseTime: 10,
    );
  }
}
