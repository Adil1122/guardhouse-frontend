import 'api_service.dart';
import 'storage_service.dart';

class SupervisorApiService extends ApiService {
  SupervisorApiService(StorageService storageService) : super(storageService);

  Future<List<Map<String, dynamic>>> getSupervisorDashboard() async {
    try {
      final response = await dio.get('supervisor/dashboard');
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } catch (e) {
      throw Exception('Failed to load supervisor dashboard');
    }
  }

  Future<Map<String, dynamic>> getActiveSiteVisit() async {
    try {
      final response = await dio.get('supervisor/active-site-visit');
      return response.data['site_visit'] ?? response.data;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAssignedSites() async {
    try {
      final response = await dio.get('supervisor/assigned-sites');
      return List<Map<String, dynamic>>.from(
        response.data['sites'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSupervisorWorkers() async {
    try {
      final response = await dio.get('supervisor/workers');
      return List<Map<String, dynamic>>.from(
        response.data['workers'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentReports() async {
    try {
      final response = await dio.get('supervisor/recent-reports');
      return List<Map<String, dynamic>>.from(
        response.data['reports'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getSupervisorStatistics() async {
    try {
      final response = await dio.get('supervisor/statistics');
      return response.data['statistics'] ?? response.data;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> startSiteVisit(
    Map<String, dynamic> visitData,
  ) async {
    try {
      final response = await dio.post(
        'supervisor/site-visits/start',
        data: visitData,
      );
      return response.data['site_visit'] ?? response.data;
    } catch (e) {
      return {};
    }
  }

  Future<bool> endSiteVisit(Map<String, dynamic> visitData) async {
    try {
      final response = await dio.post(
        'supervisor/site-visits/end',
        data: visitData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<String?> submitSupervisorReport(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final response = await dio.post('supervisor/reports', data: reportData);
      final reportId = response.data['report']?['id'] ?? response.data['id'];
      return reportId?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getSupervisorReportDetails(
    String reportId,
  ) async {
    try {
      final response = await dio.get('supervisor/reports/$reportId');
      return response.data['report'] ?? response.data;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getSupervisorNotifications() async {
    try {
      final response = await dio.get('supervisor/notifications');
      return List<Map<String, dynamic>>.from(
        response.data['notifications'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> markSupervisorNotificationAsRead(String notificationId) async {
    try {
      final response = await dio.post(
        'supervisor/notifications/$notificationId/read',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllSupervisorNotificationsAsRead() async {
    try {
      final response = await dio.post('supervisor/notifications/read-all');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSupervisorNotification(String notificationId) async {
    try {
      final response = await dio.delete(
        'supervisor/notifications/$notificationId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> assignTask(
    String workerId,
    Map<String, dynamic> taskData,
  ) async {
    try {
      final response = await dio.post(
        'supervisor/workers/$workerId/tasks/assign',
        data: taskData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reviewReport(
    String reportId,
    String action,
    String? comments,
  ) async {
    try {
      final response = await dio.post(
        'supervisor/reports/$reportId/review',
        data: {'action': action, if (comments != null) 'comments': comments},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitCheckin(Map<String, dynamic> checkinData) async {
    try {
      final response = await dio.post(
        'supervisor/checkins',
        data: checkinData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> saveQrScan(Map<String, dynamic> scanData) async {
    try {
      final response = await dio.post(
        'supervisor/qr-scans',
        data: scanData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllOfficers() async {
    try {
      final response = await dio.get('supervisor/all-officers');
      return List<Map<String, dynamic>>.from(
        response.data['officers'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAlarmHistory() async {
    try {
      final response = await dio.get('supervisor/alarms');
      return List<Map<String, dynamic>>.from(
        response.data['alarms'] ?? response.data['data'] ?? [],
      );
    } catch (e) {
      return [];
    }
  }

  Future<bool> raiseAlarm(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('supervisor/alarms', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendCheckCall(String workerId) async {
    try {
      final response = await dio.post('supervisor/workers/$workerId/check-calls', data: {});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
