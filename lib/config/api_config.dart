import 'env.dart';

class ApiConfig {
  // Change this to your Laravel backend URL
  static const String baseUrl = '${Env.baseUrl}/api/';
  
  // API Endpoints
  static const String login = 'auth/login';
  static const String register = 'auth/signup';
  static const String logout = 'auth/logout';
  static const String me = 'auth/me';
  static const String forgotPassword = 'auth/forget-password';
  static const String resetPassword = 'auth/reset-password';
  static const String verifyResetToken = 'auth/verify-reset-password-token';

  // Worker endpoints
  static const String workerTasks = 'worker/tasks';
  static const String workerReports = 'worker/reports';
  static const String updateTaskStatus = 'worker/tasks';

  // Supervisor endpoints
  static const String supervisorWorkers = 'supervisor/workers';
  static const String supervisorReports = 'supervisor/reports';
  static const String supervisorStats = 'supervisor/statistics';
  static const String assignTask = 'supervisor/tasks/assign';
  static const String reviewReport = 'supervisor/reports';

  // Admin endpoints
  static const String adminLogs = 'admin/logs';
  static const String adminStats = 'admin/statistics';

  // Request timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
