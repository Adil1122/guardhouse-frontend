import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storageService;

  ApiService(this._storageService)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Referer': 'http://localhost:3000',
            'User-Agent': 'GuardHouse-Mobile-App/1.0 (Dart)',
            'Connection': 'close',
          },
        ),
      ) {
    // Allow self-signed certificates for development (mobile only)
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 3);
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }
}
