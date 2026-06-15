import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';

class WorkerApiService extends ApiService {
  WorkerApiService(StorageService storageService) : super(storageService);

  Future<Map<String, dynamic>?> getAssignedSite() async {
    try {
      final response = await dio.get('worker/assigned-site');
      final data = response.data;
      if (data is Map && data['site'] != null) {
        return Map<String, dynamic>.from(data['site']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getSites() async {
    try {
      final response = await dio.get('worker/sites');
      return List<Map<String, dynamic>>.from(
        response.data is List ? response.data : (response.data['sites'] ?? response.data['data'] ?? [])
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerTasks() async {
    try {
      final response = await dio.get('worker/tasks');
      return List<Map<String, dynamic>>.from(
        response.data is List ? response.data : (response.data['tasks'] ?? [])
      );
    } catch (e) {
      throw Exception('Failed to load tasks');
    }
  }

  Future<bool> clockIn(String taskId) async {
    try {
      final response = await dio.post(
        'worker/clock-in',
        data: {'task_id': taskId},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Failed to clock in');
    }
  }

  Future<bool> clockOut(String taskId) async {
    try {
      final response = await dio.post(
        'worker/clock-out',
        data: {'task_id': taskId},
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to clock out');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerAttendance() async {
    try {
      final response = await dio.get('worker/attendance');
      return List<Map<String, dynamic>>.from(response.data is List ? response.data : (response.data['attendance'] ?? []));
    } catch (e) {
      throw Exception('Failed to load attendance records');
    }
  }

  Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final response = await dio.get('worker/current-shift');
      final data = response.data;
      if (data is Map && data['shift'] != null) {
        return Map<String, dynamic>.from(data['shift']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerActivities() async {
    try {
      final response = await dio.get('worker/activities');
      return List<Map<String, dynamic>>.from(
        response.data is List ? response.data : (response.data['activities'] ?? response.data['data'] ?? [])
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> startShift(Map<String, dynamic> shiftData) async {
    try {
      final response = await dio.post('worker/shift/start', data: shiftData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> endShift(Map<String, dynamic> shiftData) async {
    try {
      final shiftId = shiftData['id'] ?? shiftData['shift_id'] ?? '';
      final response = await dio.post(
        'worker/shift/$shiftId/end',
        data: shiftData,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitCheckin(Map<String, dynamic> checkinData, {File? photo}) async {
    try {
      final formData = FormData.fromMap(checkinData);

      if (photo != null) {
        final fileName = photo.path.split('/').last;
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photo.path, filename: fileName),
        ));
      }

      final response = await dio.post('worker/checkin', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 'Failed to submit check-in';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Failed to submit check-in');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentCheckins() async {
    try {
      final response = await dio.get('worker/recent-checkins');
      return List<Map<String, dynamic>>.from(
        response.data is List ? response.data : (response.data['checkins'] ?? response.data['data'] ?? [])
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getShiftHistory() async {
    try {
      final response = await dio.get('worker/shift-history');
      return List<Map<String, dynamic>>.from(
        response.data is List ? response.data : (response.data['shifts'] ?? response.data['data'] ?? [])
      );
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getShiftDetails(String shiftId) async {
    try {
      final response = await dio.get('worker/shifts/$shiftId');
      final data = response.data;
      if (data is Map && data['shift'] != null) {
        return Map<String, dynamic>.from(data['shift']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerNotifications() async {
    try {
      final response = await dio.get('worker/notifications');
      final data = response.data;
      final List list = data is List
          ? data
          : (data['notifications'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await dio.post(
        'worker/notifications/$notificationId/read',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllNotificationsAsRead() async {
    try {
      final response = await dio.post('worker/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await dio.delete(
        'worker/notifications/$notificationId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWorkerReports() async {
    try {
      final response = await dio.get('worker/reports');
      return List<Map<String, dynamic>>.from(
        response.data['reports'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitReport(Map<String, dynamic> reportData) async {
    try {
      final response = await dio.post('worker/reports', data: reportData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      final response = await dio.post(
        'worker/tasks/$taskId/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMyShifts() async {
    try {
      final response = await dio.get('worker/my-shifts');
      final data = response.data;
      if (data is List) return List<Map<String, dynamic>>.from(data);
      return List<Map<String, dynamic>>.from(
        data['shifts'] ?? data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getOfferedShifts() async {
    try {
      final response = await dio.get('worker/offered-shifts');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(
        data['shifts'] ?? data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> acceptShift(String shiftId) async {
    try {
      final response = await dio.post('worker/shifts/$shiftId/accept');
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      debugPrint('acceptShift ${e.response?.statusCode}: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('acceptShift error: $e');
      return false;
    }
  }

  Future<bool> declineShift(String shiftId) async {
    try {
      final response = await dio.post('worker/shifts/$shiftId/decline');
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      debugPrint('declineShift ${e.response?.statusCode}: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('declineShift error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCheckCalls() async {
    try {
      final response = await dio.get('worker/check-calls');
      final data = response.data;
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return List<Map<String, dynamic>>.from(
        data['check_calls'] ?? data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> respondToCheckCall(String id) async {
    try {
      final response = await dio.post('worker/check-calls/$id/respond');
      return (response.statusCode ?? 0) >= 200 && (response.statusCode ?? 0) < 300;
    } on DioException catch (e) {
      debugPrint('respondToCheckCall ${e.response?.statusCode}: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('respondToCheckCall error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAlarmHistory() async {
    try {
      final response = await dio.get('worker/alarms');
      final data = response.data;
      final List list = data is List ? data : (data['alarms'] ?? data['data'] ?? []);
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      return [];
    }
  }

  Future<bool> raiseAlarm(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('worker/alarms', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getLiveOperations() async {
    try {
      final response = await dio.get('live-operations');
      return response.data is Map ? Map<String, dynamic>.from(response.data) : {};
    } catch (e) {
      return {};
    }
  }
}
