import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/geofence_api_service.dart';
import '../services/location_service.dart';
import '../services/photo_service.dart';

class WorkerGeofenceViewModel extends ChangeNotifier {
  final GeofenceApiService _apiService;
  final LocationService _locationService;
  final PhotoService _photoService;

  WorkerGeofenceViewModel(
    this._apiService,
    this._locationService,
    this._photoService,
  );

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentShift;
  List<Map<String, dynamic>> _checkinHistory = [];
  List<Map<String, dynamic>> _dutyHistory = [];
  Map<String, dynamic>? _shiftDetails;
  PhotoResult? _pendingPhoto;
  bool _isSubmittingCheckin = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentShift => _currentShift;
  List<Map<String, dynamic>> get checkinHistory => _checkinHistory;
  List<Map<String, dynamic>> get dutyHistory => _dutyHistory;
  Map<String, dynamic>? get shiftDetails => _shiftDetails;
  PhotoResult? get pendingPhoto => _pendingPhoto;
  bool get isSubmittingCheckin => _isSubmittingCheckin;

  /// Load current shift with geofence status
  Future<void> loadCurrentShift() async {
    _setLoading(true);
    _clearError();

    try {
      final shiftData = await _apiService.getCurrentShift();
      _currentShift = shiftData;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current shift: $e');
      _currentShift = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Submit checkin with photo evidence
  Future<bool> submitCheckin({
    String? locationDescription,
    String? notes,
    String type = 'regular',
    int? siteCheckpointId,
    bool usePhoto = true,
  }) async {
    if (_currentShift == null) {
      _setError('No active shift found');
      return false;
    }

    _setSubmittingCheckin(true);
    _clearError();

    try {
      // Get current location
      final currentPosition = _locationService.currentPosition;
      if (currentPosition == null) {
        _setError('Unable to get current location');
        return false;
      }

      File? photoFile;
      if (usePhoto && _pendingPhoto != null) {
        photoFile = File(_pendingPhoto!.filePath);
      }

      final response = await _apiService.submitCheckin(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        locationDescription: locationDescription,
        notes: notes,
        type: type,
        siteCheckpointId: siteCheckpointId,
        photo: photoFile,
      );

      // Clear pending photo after successful submission
      if (_pendingPhoto != null) {
        await _photoService.deletePhoto(_pendingPhoto!.filePath);
        _pendingPhoto = null;
      }

      // Refresh checkin history
      await loadCheckinHistory();

      return true;
    } catch (e) {
      _setError('Failed to submit checkin: $e');
      return false;
    } finally {
      _setSubmittingCheckin(false);
    }
  }

  /// Take photo for checkin
  Future<bool> takePhoto() async {
    _clearError();

    try {
      final photoResult = await _photoService.takePhoto();
      if (photoResult == null) {
        _setError('Failed to take photo');
        return false;
      }

      // Add location data to photo
      final currentPosition = _locationService.currentPosition;
      if (currentPosition != null) {
        _pendingPhoto = _photoService.addLocationData(
          photoResult,
          currentPosition.latitude,
          currentPosition.longitude,
        );
      } else {
        _pendingPhoto = photoResult;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to take photo: $e');
      return false;
    }
  }

  /// Pick photo from gallery
  Future<bool> pickPhotoFromGallery() async {
    _clearError();

    try {
      final photoResult = await _photoService.pickPhotoFromGallery();
      if (photoResult == null) {
        _setError('No photo selected');
        return false;
      }

      // Add location data to photo
      final currentPosition = _locationService.currentPosition;
      if (currentPosition != null) {
        _pendingPhoto = _photoService.addLocationData(
          photoResult,
          currentPosition.latitude,
          currentPosition.longitude,
        );
      } else {
        _pendingPhoto = photoResult;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to pick photo: $e');
      return false;
    }
  }

  /// Clear pending photo
  void clearPendingPhoto() async {
    if (_pendingPhoto != null) {
      await _photoService.deletePhoto(_pendingPhoto!.filePath);
      _pendingPhoto = null;
      notifyListeners();
    }
  }

  /// Load checkin history for current shift
  Future<void> loadCheckinHistory() async {
    if (_currentShift == null) return;

    _setLoading(true);
    _clearError();

    try {
      final history = await _apiService.getCheckinHistory();
      _checkinHistory = history;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load checkin history: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get a specific checkin details
  Future<Map<String, dynamic>?> getCheckinDetails(String checkinId) async {
    _clearError();

    try {
      final checkin = await _apiService.getCheckin(checkinId);
      return checkin;
    } catch (e) {
      debugPrint('Error getting checkin details: $e');
      _setError(e.toString());
      return null;
    }
  }

  /// Update a specific checkin
  Future<bool> updateCheckin(String checkinId, {
    String? locationDescription,
    String? notes,
    String? type,
  }) async {
    _clearError();

    try {
      await _apiService.updateCheckin(
        checkinId,
        locationDescription: locationDescription,
        notes: notes,
        type: type,
      );
      
      // Refresh checkin history after update
      await loadCheckinHistory();
      return true;
    } catch (e) {
      debugPrint('Error updating checkin: $e');
      _setError(e.toString());
      return false;
    }
  }

  /// Delete a specific checkin
  Future<bool> deleteCheckin(String checkinId) async {
    _clearError();

    try {
      await _apiService.deleteCheckin(checkinId);
      
      // Refresh checkin history after delete
      await loadCheckinHistory();
      return true;
    } catch (e) {
      debugPrint('Error deleting checkin: $e');
      _setError(e.toString());
      return false;
    }
  }

  /// Load duty history
  Future<void> loadDutyHistory({int page = 1, int perPage = 20}) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Loading duty history from API...');
      final response = await _apiService.getDutyHistory(page: page, perPage: perPage);
      debugPrint('API Response: $response');
      
      // Fix type casting - convert dynamic list to List<Map<String, dynamic>>
      final dataList = response['data'] as List<dynamic>;
      _dutyHistory = dataList.map((item) => item as Map<String, dynamic>).toList();
      
      debugPrint('Duty history set: ${_dutyHistory.length} items');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading duty history: $e');
      _setError('Failed to load duty history: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load shift details
  Future<void> loadShiftDetails(String shiftId) async {
    _setLoading(true);
    _clearError();

    try {
      final details = await _apiService.getShiftDetails(shiftId);
      _shiftDetails = details;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load shift details: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get current geofence status
  GeofenceStatus? getCurrentGeofenceStatus() {
    if (_currentShift == null || _currentShift!['geofence'] == null) {
      return null;
    }

    final Map<String, dynamic> geofence = _currentShift!['geofence'];
    return _locationService.getGeofenceStatus(geofence: geofence);
  }

  /// Get photo URL for display
  String getPhotoUrl(String? photoPath) {
    return _apiService.getPhotoUrl(photoPath);
  }

  /// Format checkin time for display
  String formatCheckinTime(DateTime timestamp) {
    final hour = timestamp.hour > 12
        ? timestamp.hour - 12
        : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  /// Format date for display
  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Calculate duration between two times
  String calculateDuration(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) return '0h 0m';

    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get checkin statistics
  Map<String, dynamic> getCheckinStats() {
    if (_checkinHistory.isEmpty) {
      return {
        'total': 0,
        'withPhotos': 0,
        'insideGeofence': 0,
        'outsideGeofence': 0,
      };
    }

    final total = _checkinHistory.length;
    final withPhotos = _checkinHistory.where((c) => c['photo_path'] != null).length;
    final insideGeofence = _checkinHistory.where((c) => c['inside_geofence'] == true).length;
    final outsideGeofence = total - insideGeofence;

    return {
      'total': total,
      'withPhotos': withPhotos,
      'insideGeofence': insideGeofence,
      'outsideGeofence': outsideGeofence,
    };
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSubmittingCheckin(bool submitting) {
    _isSubmittingCheckin = submitting;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up pending photo
    if (_pendingPhoto != null) {
      _photoService.deletePhoto(_pendingPhoto!.filePath);
    }
    super.dispose();
  }
}
