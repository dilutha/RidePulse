import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import 'api_client.dart';

/**
 * Authentication Service
 * 
 * ENCAPSULATION (OOP Concept):
 * Encapsulates all authentication-related API calls
 * Hides implementation details from UI layer
 * 
 * SINGLETON PATTERN:
 * Single instance manages authentication state
 */
class AuthService {
  static final AuthService _instance = AuthService._internal();
  
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _fullNameKey = 'user_full_name';
  static const String _roleKey = 'user_role';
  
  // Private constructor
  AuthService._internal();
  
  // Factory constructor (Singleton)
  factory AuthService() {
    return _instance;
  }
  
  /**
   * Register new user
   * 
   * @param request Registration data
   * @return AuthResponse with user data and JWT token
   */
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.client.post(
        ApiConfig.registerUrl,
        data: request.toJson(),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save authentication data
      await _saveAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Login user
   * 
   * @param request Login credentials
   * @return AuthResponse with user data and JWT token
   */
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _apiClient.client.post(
        ApiConfig.loginUrl,
        data: request.toJson(),
      );
      
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save authentication data
      await _saveAuthData(authResponse);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Logout user
   * Clears stored authentication data
   */
  Future<void> logout() async {
    try {
      final token = await getToken();
      
      if (token != null) {
        // Call backend logout endpoint
        await _apiClient.client.post(
          ApiConfig.logoutUrl,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Clear stored data regardless of API call result
      await _clearAuthData();
    }
  }
  
  /**
   * Check if user is logged in
   */
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
  
  /**
   * Get stored JWT token
   */
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  /**
   * Get stored user data
   */
  Future<User?> getCurrentUser() async {
    final userId = await _secureStorage.read(key: _userIdKey);
    final email = await _secureStorage.read(key: _emailKey);
    final fullName = await _secureStorage.read(key: _fullNameKey);
    final role = await _secureStorage.read(key: _roleKey);
    
    if (userId != null && email != null && fullName != null && role != null) {
      return User(
        userId: userId,
        email: email,
        fullName: fullName,
        role: role,
      );
    }
    
    return null;
  }
  
  /**
   * ENCAPSULATION - Private helper methods
   */
  
  // Save authentication data to secure storage
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    await _secureStorage.write(key: _tokenKey, value: authResponse.token);
    await _secureStorage.write(key: _userIdKey, value: authResponse.userId);
    await _secureStorage.write(key: _emailKey, value: authResponse.email);
    await _secureStorage.write(key: _fullNameKey, value: authResponse.fullName);
    await _secureStorage.write(key: _roleKey, value: authResponse.role);
    
    // Set token in API client for future requests
    _apiClient.setAuthToken(authResponse.token);
  }
  
  // Clear all authentication data
  Future<void> _clearAuthData() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _fullNameKey);
    await _secureStorage.delete(key: _roleKey);
    
    // Clear token from API client
    _apiClient.clearAuthToken();
  }
  
  // Handle API errors
  String _handleError(DioException error) {
    if (error.response != null) {
      // Server responded with error
      final data = error.response?.data;
      
      if (data is Map<String, dynamic>) {
        return data['error'] ?? data['message'] ?? 'An error occurred';
      }
      
      return 'Server error: ${error.response?.statusCode}';
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return 'Server not responding. Please try again later.';
    } else {
      return 'Network error. Please check your connection.';
    }
  }
}