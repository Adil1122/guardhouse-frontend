import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  final StreamController<LocationUpdate> _locationController = StreamController<LocationUpdate>.broadcast();

  Stream<LocationUpdate> get locationStream => _locationController.stream;
  Position? get currentPosition => _currentPosition;

  /// Initialize location service and request permissions
  Future<bool> initialize() async {
    try {
      // Request location permissions
      bool hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission denied');
        return false;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Start location updates
      _startLocationUpdates();

      return true;
    } catch (e) {
      debugPrint('Error initializing location service: $e');
      return false;
    }
  }

  /// Request location permissions
  Future<bool> _requestLocationPermission() async {
    try {
      // Request location permission
      var status = await Permission.location.request();
      
      if (status.isGranted) {
        // For Android, also request background location if needed
        if (defaultTargetPlatform == TargetPlatform.android) {
          var backgroundStatus = await Permission.locationAlways.request();
          return backgroundStatus.isGranted || status.isGranted;
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  /// Start continuous location updates
  void _startLocationUpdates() {
    // Cancel any existing subscription
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: Duration(seconds: 30),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _locationController.add(LocationUpdate(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
          isInsideGeofence: false, // Will be calculated by caller
        ));
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );

    // Fallback timer for periodic updates (every 30 seconds)
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        _currentPosition = position;
        _locationController.add(LocationUpdate(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
          isInsideGeofence: false,
        ));
      } catch (e) {
        debugPrint('Error getting periodic location update: $e');
      }
    });
  }

  /// Stop location updates
  void stopLocationUpdates() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _positionStreamSubscription = null;
    _locationUpdateTimer = null;
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  /// Check if point is within geofence
  bool isWithinGeofence({
    required double latitude,
    required double longitude,
    required double centerLat,
    required double centerLon,
    required double radius,
  }) {
    final double distance = calculateDistance(latitude, longitude, centerLat, centerLon);
    return distance <= radius;
  }

  /// Get geofence status for current location
  GeofenceStatus getGeofenceStatus({
    required Map<String, dynamic> geofence,
  }) {
    if (_currentPosition == null || 
        !geofence.containsKey('latitude') || 
        !geofence.containsKey('longitude')) {
      return GeofenceStatus(
        insideGeofence: false,
        distanceFromSite: null,
        checkInDistance: geofence['radius']?.toDouble() ?? 100.0,
        status: 'invalid_geofence',
      );
    }

    final double centerLat = double.parse(geofence['latitude'].toString());
    final double centerLon = double.parse(geofence['longitude'].toString());
    final double checkInDistance = (geofence['radius']?.toDouble() ?? 100.0);

    final double distance = calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      centerLat,
      centerLon,
    );

    final bool insideGeofence = distance <= checkInDistance;

    return GeofenceStatus(
      insideGeofence: insideGeofence,
      distanceFromSite: distance,
      checkInDistance: checkInDistance,
      status: insideGeofence ? 'inside' : 'outside',
    );
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
    _locationController.close();
  }
}

class LocationUpdate {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool isInsideGeofence;

  LocationUpdate({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.isInsideGeofence,
  });
}

class GeofenceStatus {
  final bool insideGeofence;
  final double? distanceFromSite;
  final double checkInDistance;
  final String status;

  GeofenceStatus({
    required this.insideGeofence,
    this.distanceFromSite,
    required this.checkInDistance,
    required this.status,
  });
}
