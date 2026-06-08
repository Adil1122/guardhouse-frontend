import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../config/api_config.dart';
import 'storage_service.dart';

class AuthService {
  final Dio _dio;
  final StorageService _storageService;

  AuthService(this._storageService)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'GuardHouse-Mobile-App/1.0 (Dart)',
          },
        ),
      ) {
    // Allow self-signed certificates for development (mobile only)
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add token to requests
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            _storageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Login to Laravel backend
  Future<Map<String, dynamic>?> loginAsJson(
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        // Save token
        if (data['token'] != null) {
          await _storageService.saveToken(data['token']);
        }

        // Return user data as JSON
        if (data['user'] != null) {
          if (data['user'] is List) {
            final roles = (data['user'] as List).map((e) => e.toString()).toList();
            return {
              'id': 0,
              'email': email,
              'first_name': 'Admin',
              'last_name': 'User',
              'role': roles.isNotEmpty ? roles.first : 'user',
              'abilities': roles,
            };
          }
          return Map<String, dynamic>.from(data['user']);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          if (data['errors'] != null && data['errors'] is Map) {
            final errors = data['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              throw Exception(firstError is List ? firstError.first.toString() : firstError.toString());
            }
          }
          final message = data['message'] ?? data['error'];
          if (message != null) {
            throw Exception(message.toString());
          }
        } else if (data is String) {
           throw Exception(data);
        }
      }
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet.');
      }
      
      throw Exception(e.message ?? 'Login failed');
    } catch (e) {
      debugPrint('Login unexpected error: $e');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _dio.post(ApiConfig.logout);
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await _storageService.clearAll();
    }
  }

  // Get current user info
  Future<Map<String, dynamic>?> getCurrentUserJson() async {
    try {
      final response = await _dio.get(ApiConfig.me);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['user'] != null) {
          if (data['user'] is List) {
            final roles = (data['user'] as List).map((e) => e.toString()).toList();
            return {
              'id': 0,
              'email': '',
              'first_name': 'Admin',
              'last_name': 'User',
              'role': roles.isNotEmpty ? roles.first : 'user',
              'abilities': roles,
            };
          }
          return Map<String, dynamic>.from(data['user']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Validate token
  Future<bool> validateToken(String token) async {
    try {
      final response = await _dio.get(
        ApiConfig.me,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Register new user
  Future<Map<String, dynamic>?> registerAsJson({
    required String first_name,
    required String last_name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.register,
        data: {
          'first_name': first_name,
          'last_name': last_name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data;

        // Save token
        if (data['token'] != null) {
          await _storageService.saveToken(data['token']);
        }

        // Return user data as JSON
        if (data['user'] != null) {
          return Map<String, dynamic>.from(data['user']);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // Validation errors
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null) {
          final firstError = errors.values.first;
          throw Exception(firstError is List ? firstError.first : firstError);
        }
        throw Exception('Validation failed');
      }
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    } catch (e) {
      throw Exception('An error occurred during registration');
    }
  }

  // Send password reset email
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Email not found');
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to send reset link',
      );
    } catch (e) {
      throw Exception('An error occurred');
    }
  }

  // Reset password with token
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.resetPassword,
        data: {
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': password,
        },
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Invalid or expired reset token');
      }
      throw Exception(e.response?.data['message'] ?? 'Password reset failed');
    } catch (e) {
      throw Exception('An error occurred');
    }
  }
}
