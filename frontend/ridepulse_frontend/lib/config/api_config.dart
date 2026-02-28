/**
 * API Configuration Class
 * 
 * ENCAPSULATION (OOP Concept):
 * Centralizes all API-related configuration
 * Makes it easy to change backend URL
 */
class ApiConfig {
  // Base URL for your Spring Boot backend
  // Change this to your actual backend URL
  static const String baseUrl = 'http://localhost:8080/api';
  
  // For Android Emulator, use: http://10.0.2.2:8080/api
  // For iOS Simulator, use: http://localhost:8080/api
  // For Real Device, use: http://YOUR_COMPUTER_IP:8080/api
  
  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String routesEndpoint = '/routes';
  static const String busesEndpoint = '/buses';
  static const String ticketsEndpoint = '/tickets';
  
  // Authentication endpoints
  static const String loginUrl = '$authEndpoint/login';
  static const String registerUrl = '$authEndpoint/register';
  static const String logoutUrl = '$authEndpoint/logout';
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}