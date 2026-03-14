import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/welfare_models.dart';
import 'api_client.dart';

/**
 * Welfare Service
 * 
 * ENCAPSULATION (OOP Concept):
 * Encapsulates all welfare-related API calls
 */
class WelfareService {
  static final WelfareService _instance = WelfareService._internal();
  final ApiClient _apiClient = ApiClient();
  
  WelfareService._internal();
  
  factory WelfareService() {
    return _instance;
  }
  
  /**
   * Create welfare record
   */
  Future<WelfareRecord> createWelfareRecord(CreateWelfareRequest request) async {
    try {
      final response = await _apiClient.client.post(
        '/welfare',
        data: request.toJson(),
      );
      
      return WelfareRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get welfare record by ID
   */
  Future<WelfareRecord> getWelfareRecordById(int recordId) async {
    try {
      final response = await _apiClient.client.get('/welfare/$recordId');
      return WelfareRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get welfare records by staff
   */
  Future<List<WelfareRecord>> getWelfareRecordsByStaff(int staffId) async {
    try {
      final response = await _apiClient.client.get('/welfare/staff/$staffId');
      
      final List<dynamic> data = response.data;
      return data.map((json) => WelfareRecord.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get welfare records by bus
   */
  Future<List<WelfareRecord>> getWelfareRecordsByBus(int busId) async {
    try {
      final response = await _apiClient.client.get('/welfare/bus/$busId');
      
      final List<dynamic> data = response.data;
      return data.map((json) => WelfareRecord.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get welfare summary for staff
   */
  Future<WelfareSummary> getWelfareSummary(int staffId) async {
    try {
      final response = await _apiClient.client.get(
        '/welfare/staff/$staffId/summary',
      );
      
      return WelfareSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get welfare records by status
   */
  Future<List<WelfareRecord>> getWelfareRecordsByStatus(String status) async {
    try {
      final response = await _apiClient.client.get('/welfare/status/$status');
      
      final List<dynamic> data = response.data;
      return data.map((json) => WelfareRecord.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Approve welfare record
   */
  Future<WelfareRecord> approveWelfareRecord(int recordId) async {
    try {
      final response = await _apiClient.client.put('/welfare/$recordId/approve');
      return WelfareRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Reject welfare record
   */
  Future<WelfareRecord> rejectWelfareRecord(int recordId) async {
    try {
      final response = await _apiClient.client.put('/welfare/$recordId/reject');
      return WelfareRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * ENCAPSULATION - Private helper method
   */
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data['error'] ?? data['message'] ?? 'An error occurred';
      }
      return 'Server error: ${error.response?.statusCode}';
    }
    return 'Network error. Please check your connection.';
  }
}