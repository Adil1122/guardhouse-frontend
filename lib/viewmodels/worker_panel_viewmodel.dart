import 'package:flutter/foundation.dart';
import '../services/location_service.dart';
import '../services/geofence_api_service.dart';
import '../services/storage_service.dart';

enum WorkerHistoryFilter { week, month, all }

enum WorkerNotificationFilter { all, unread, alert, info, task }

class WorkerPanelViewModel extends ChangeNotifier {
  WorkerHistoryFilter _historyFilter = WorkerHistoryFilter.week;
  WorkerNotificationFilter _notificationFilter = WorkerNotificationFilter.all;
  bool _isInsideGeofence = false;
  int _bottomNavIndex = 0;
  DateTime? _insideGeofenceSince;
  
  // Location and geofence services
  final LocationService _locationService = LocationService();
  GeofenceApiService? _geofenceApiService;
  Map<String, dynamic>? _currentShiftData;
  bool _isLocationServiceInitialized = false;
  String? _errorMessage;

  WorkerHistoryFilter get historyFilter => _historyFilter;
  WorkerNotificationFilter get notificationFilter => _notificationFilter;
  bool get isInsideGeofence => _isInsideGeofence;
  int get bottomNavIndex => _bottomNavIndex;
  DateTime? get insideGeofenceSince => _insideGeofenceSince;
  bool get isLocationServiceInitialized => _isLocationServiceInitialized;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get currentShiftData => _currentShiftData;

  void setHistoryFilter(WorkerHistoryFilter value) {
    if (_historyFilter == value) return;
    _historyFilter = value;
    notifyListeners();
  }

  void setNotificationFilter(WorkerNotificationFilter value) {
    if (_notificationFilter == value) return;
    _notificationFilter = value;
    notifyListeners();
  }

  void setBottomNavIndex(int value) {
    if (_bottomNavIndex == value) return;
    _bottomNavIndex = value;
    notifyListeners();
  }

  void setGeofenceStatus(bool value) {
    if (_isInsideGeofence == value) return;
    _isInsideGeofence = value;
    if (value) {
      _insideGeofenceSince ??= DateTime.now();
    } else {
      _insideGeofenceSince = null;
    }
    notifyListeners();
  }

  
  List<Map<String, dynamic>> filterShiftHistory(
    List<Map<String, dynamic>> shifts,
  ) {
    final now = DateTime.now();
    switch (_historyFilter) {
      case WorkerHistoryFilter.week:
        return shifts.where((shift) {
          final date = shift['date'] as DateTime?;
          return date != null &&
              date.isAfter(now.subtract(const Duration(days: 7)));
        }).toList();
      case WorkerHistoryFilter.month:
        return shifts.where((shift) {
          final date = shift['date'] as DateTime?;
          return date != null &&
              date.isAfter(now.subtract(const Duration(days: 30)));
        }).toList();
      case WorkerHistoryFilter.all:
        return shifts;
    }
  }

  List<Map<String, dynamic>> filterNotifications(
    List<Map<String, dynamic>> notifications,
  ) {
    switch (_notificationFilter) {
      case WorkerNotificationFilter.unread:
        return notifications.where((n) => n['read'] != true).toList();
      case WorkerNotificationFilter.alert:
        return notifications.where((n) => n['type'] == 'alert').toList();
      case WorkerNotificationFilter.info:
        return notifications.where((n) => n['type'] == 'info').toList();
      case WorkerNotificationFilter.task:
        return notifications.where((n) => n['type'] == 'task').toList();
      case WorkerNotificationFilter.all:
        return notifications;
    }
  }

  /// Initialize geofence service with storage
  void initialize(StorageService storageService) {
    _geofenceApiService = GeofenceApiService(storageService);
  }

  /// Initialize location service and start monitoring
  Future<bool> initializeLocationService() async {
    if (_isLocationServiceInitialized) return true;

    try {
      final bool initialized = await _locationService.initialize();
      if (initialized) {
        _isLocationServiceInitialized = true;
        
        // Listen to location updates
        _locationService.locationStream.listen((locationUpdate) {
          _handleLocationUpdate(locationUpdate);
        });
        
        notifyListeners();
      }
      return initialized;
    } catch (e) {
      _errorMessage = 'Failed to initialize location service: $e';
      notifyListeners();
      return false;
    }
  }

  /// Handle location updates and check geofence status
  void _handleLocationUpdate(LocationUpdate locationUpdate) {
    if (_currentShiftData == null || _currentShiftData!['geofence'] == null) {
      return;
    }

    final Map<String, dynamic> geofence = _currentShiftData!['geofence'];
    final GeofenceStatus status = _locationService.getGeofenceStatus(geofence: geofence);

    // Update geofence status if changed
    if (_isInsideGeofence != status.insideGeofence) {
      _isInsideGeofence = status.insideGeofence;
      
      if (status.insideGeofence && _insideGeofenceSince == null) {
        _insideGeofenceSince = DateTime.now();
      } else if (!status.insideGeofence) {
        _insideGeofenceSince = null;
      }
      
      // Update server with new location
      _updateLocationOnServer(locationUpdate.latitude, locationUpdate.longitude);
      
      notifyListeners();
    }
  }

  /// Update location on server
  Future<void> _updateLocationOnServer(double latitude, double longitude) async {
    if (_geofenceApiService == null) return;

    try {
      await _geofenceApiService!.updateLocation(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('Failed to update location on server: $e');
      _errorMessage = 'Location update failed: $e';
      notifyListeners();
    }
  }

  /// Sync geofence status with current shift data
  Future<void> syncGeofenceStatus(Map<String, dynamic>? currentShift) async {
    _currentShiftData = currentShift;
    
    if (currentShift == null) {
      _isInsideGeofence = false;
      _insideGeofenceSince = null;
      notifyListeners();
      return;
    }

    // If location service is initialized, check current geofence status
    if (_isLocationServiceInitialized && _locationService.currentPosition != null) {
      final Map<String, dynamic>? geofence = currentShift['geofence'];
      if (geofence != null) {
        final GeofenceStatus status = _locationService.getGeofenceStatus(geofence: geofence);
        
        _isInsideGeofence = status.insideGeofence;
        if (status.insideGeofence && _insideGeofenceSince == null) {
          _insideGeofenceSince = currentShift['inside_geofence_since'] != null
              ? DateTime.tryParse(currentShift['inside_geofence_since'])
              : DateTime.now();
        } else if (!status.insideGeofence) {
          _insideGeofenceSince = null;
        }
      }
    } else {
      // Use server-provided geofence status
      _isInsideGeofence = currentShift['inside_geofence'] ?? false;
      if (_isInsideGeofence && _insideGeofenceSince == null) {
        final String? sinceString = currentShift['inside_geofence_since'];
        _insideGeofenceSince = sinceString != null ? DateTime.tryParse(sinceString) : null;
      }
    }

    notifyListeners();
  }

  /// Get current geofence status details
  GeofenceStatus? getCurrentGeofenceStatus() {
    if (_currentShiftData == null || _currentShiftData!['geofence'] == null) {
      return null;
    }

    final Map<String, dynamic> geofence = _currentShiftData!['geofence'];
    return _locationService.getGeofenceStatus(geofence: geofence);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
