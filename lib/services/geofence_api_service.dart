import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:security_app/config/api_config.dart';
import 'package:security_app/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class GeofenceApiService {
  final Dio _dio;
  final StorageService _storageService;

  GeofenceApiService(this._storageService) : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'User-Agent': 'GuardHouseApp/1.0.0',
      'Connection': 'keep-alive',
    },
  )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getAuthToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Clear token and redirect to login
          await _storageService.clearAuthToken();
        }
        handler.next(error);
      },
    ));

    // Add logging interceptor for debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
      ));
    }
  }

  /// Get current shift with geofence status
  Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final response = await _dio.get('/worker/current-shift');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Error getting current shift: ${e.message}');
      if (e.response?.statusCode == 404) {
        return null; // No active shift
      }
      throw Exception('Failed to get current shift: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error getting current shift: $e');
      throw Exception('Failed to get current shift');
    }
  }

  /// Update worker location and check geofence status
  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.post('/worker/location', data: {
        'latitude': latitude,
        'longitude': longitude,
      });

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to update location');
    } on DioException catch (e) {
      debugPrint('Error updating location: ${e.message}');
      throw Exception('Failed to update location: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error updating location: $e');
      throw Exception('Failed to update location');
    }
  }

  /// Submit checkin with optional photo
  Future<Map<String, dynamic>> submitCheckin({
    required double latitude,
    required double longitude,
    String? locationDescription,
    String? notes,
    String type = 'regular',
    int? siteCheckpointId,
    File? photo,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'type': type,
      };

      if (locationDescription != null && locationDescription.isNotEmpty) {
        data['location_description'] = locationDescription;
      }

      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      if (siteCheckpointId != null) {
        data['site_checkpoint_id'] = siteCheckpointId.toString();
      }

      FormData formData = FormData.fromMap(data);

      // Add photo if provided
      if (photo != null) {
        final String fileName = photo.path.split('/').last;
        formData.files.add(MapEntry(
          'photo',
          MultipartFile.fromFileSync(
            photo.path,
            filename: fileName,
          ),
        ));
      }

      final response = await _dio.post('/worker/checkin', data: formData);

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to submit checkin');
    } on DioException catch (e) {
      debugPrint('Error submitting checkin: ${e.message}');
      final String errorMessage = e.response?.data?['message'] ?? 'Failed to submit checkin';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error submitting checkin: $e');
      throw Exception('Failed to submit checkin');
    }
  }

  /// Get checkin history for current shift
  /// Get a specific checkin details
  Future<Map<String, dynamic>> getCheckin(String checkinId) async {
    try {
      final response = await _dio.get('/worker/checkins/$checkinId');
      
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception('Failed to get checkin details');
    } on DioException catch (e) {
      debugPrint('Error getting checkin details: ${e.message}');
      final String errorMessage = e.response?.data?['message'] ?? 'Failed to get checkin details';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error getting checkin details: $e');
      throw Exception('Failed to get checkin details');
    }
  }

  /// Update a specific checkin
  Future<Map<String, dynamic>> updateCheckin(String checkinId, {
    String? locationDescription,
    String? notes,
    String? type,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (locationDescription != null) data['location_description'] = locationDescription;
      if (notes != null) data['notes'] = notes;
      if (type != null) data['type'] = type;

      final response = await _dio.put('/worker/checkins/$checkinId', data: data);
      
      if (response.statusCode == 200) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception('Failed to update checkin');
    } on DioException catch (e) {
      debugPrint('Error updating checkin: ${e.message}');
      final String errorMessage = e.response?.data?['message'] ?? 'Failed to update checkin';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error updating checkin: $e');
      throw Exception('Failed to update checkin');
    }
  }

  /// Delete a specific checkin
  Future<bool> deleteCheckin(String checkinId) async {
    try {
      final response = await _dio.delete('/worker/checkins/$checkinId');
      
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to delete checkin');
    } on DioException catch (e) {
      debugPrint('Error deleting checkin: ${e.message}');
      final String errorMessage = e.response?.data?['message'] ?? 'Failed to delete checkin';
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected error deleting checkin: $e');
      throw Exception('Failed to delete checkin');
    }
  }

  /// Get checkin history for current shift
  Future<List<Map<String, dynamic>>> getCheckinHistory() async {
    try {
      final response = await _dio.get('/worker/checkin-history');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Error getting checkin history: ${e.message}');
      throw Exception('Failed to get checkin history: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error getting checkin history: $e');
      throw Exception('Failed to get checkin history');
    }
  }

  /// Get duty history for worker
  Future<Map<String, dynamic>> getDutyHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get('/worker/duty-history', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get duty history');
    } on DioException catch (e) {
      debugPrint('Error getting duty history: ${e.message}');
      throw Exception('Failed to get duty history: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error getting duty history: $e');
      throw Exception('Failed to get duty history');
    }
  }

  /// Get shift details with all checkins
  Future<Map<String, dynamic>> getShiftDetails(String shiftId) async {
    try {
      final response = await _dio.get('/worker/shift-details/$shiftId');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception('Shift not found');
    } on DioException catch (e) {
      debugPrint('Error getting shift details: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('Shift not found');
      }
      throw Exception('Failed to get shift details: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error getting shift details: $e');
      throw Exception('Failed to get shift details');
    }
  }

  /// Get photo URL from path
  String getPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }
    
    // Assuming photos are stored in storage/app/public/checkin_photos
    // and accessible via URL
    return '${ApiConfig.baseUrl.replaceAll('/api', '')}/storage/$photoPath';
  }

  /// Download photo from URL
  Future<File?> downloadPhoto(String photoPath) async {
    try {
      final String photoUrl = getPhotoUrl(photoPath);
      if (photoUrl.isEmpty) return null;

      final response = await _dio.get(photoUrl);
      
      if (response.statusCode == 200) {
        // Save to temporary file
        final Directory tempDir = Directory.systemTemp;
        final String fileName = photoPath.split('/').last;
        final File tempFile = File('${tempDir.path}/$fileName');
        
        await tempFile.writeAsBytes(response.data);
        return tempFile;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading photo: $e');
      return null;
    }
  }
}
