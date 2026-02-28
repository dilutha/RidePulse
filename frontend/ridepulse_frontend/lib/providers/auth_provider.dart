import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/**
 * Authentication Provider
 * 
 * STATE MANAGEMENT:
 * Manages authentication state across the app
 * Uses Provider pattern (Observer pattern from OOP)
 * 
 * ENCAPSULATION:
 * Encapsulates authentication logic and state
 */
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Current user
  User? _currentUser;
  
  // Loading state
  bool _isLoading = false;
  
  // Error message
  String? _errorMessage;
  
  // Getters (ENCAPSULATION)
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  /**
   * Initialize authentication state
   * Check if user is already logged in
   */
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        
        // Set token in API client
        final token = await _authService.getToken();
        if (token != null) {
          ApiClient().setAuthToken(token);
        }
      }
    } catch (e) {
      _setError('Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /**
   * Register new user
   */
  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final request = RegisterRequest(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      
      final response = await _authService.register(request);
      
      // Set current user
      _currentUser = User(
        userId: response.userId,
        email: response.email,
        fullName: response.fullName,
        role: response.role,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /**
   * Login user
   */
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );
      
      final response = await _authService.login(request);
      
      // Set current user
      _currentUser = User(
        userId: response.userId,
        email: response.email,
        fullName: response.fullName,
        role: response.role,
      );
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
  
  /**
   * Logout user
   */
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      _setError('Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /**
   * ENCAPSULATION - Private helper methods
   */
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}