import 'package:dio/dio.dart';
import '../config/api_config.dart';

/**
 * API Client Service
 * 
 * SINGLETON PATTERN (OOP Concept):
 * Single instance of HTTP client used throughout the app
 * 
 * ENCAPSULATION:
 * Wraps Dio HTTP client configuration
 */
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  
  // Private constructor
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add interceptors for logging and error handling
    dio.interceptors.add(_ApiInterceptor());
  }
  
  // Factory constructor returns same instance (Singleton)
  factory ApiClient() {
    return _instance;
  }
  
  // Get Dio instance
  Dio get client => dio;
  
  // Set authentication token
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Clear authentication token
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}

/**
 * API Interceptor
 * Logs requests and handles errors
 */
class _ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => MESSAGE: ${err.message}');
    super.onError(err, handler);
  }
}