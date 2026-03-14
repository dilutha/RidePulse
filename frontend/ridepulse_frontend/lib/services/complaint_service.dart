import 'package:dio/dio.dart';
import '../models/complaint_model.dart';
import 'api_client.dart';

/**
 * Complaint Service
 * 
 * ENCAPSULATION (OOP Concept):
 * Encapsulates all complaint-related API calls
 */
class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  final ApiClient _apiClient = ApiClient();
  
  ComplaintService._internal();
  
  factory ComplaintService() {
    return _instance;
  }
  
  /**
   * Create complaint
   */
  Future<Complaint> createComplaint(CreateComplaintRequest request) async {
    try {
      final response = await _apiClient.client.post(
        '/complaints',
        data: request.toJson(),
      );
      
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get complaint by ID
   */
  Future<Complaint> getComplaintById(int complaintId) async {
    try {
      final response = await _apiClient.client.get('/complaints/$complaintId');
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get complaint by number
   */
  Future<Complaint> getComplaintByNumber(String complaintNumber) async {
    try {
      final response = await _apiClient.client.get(
        '/complaints/number/$complaintNumber',
      );
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get complaints by passenger
   */
  Future<List<Complaint>> getComplaintsByPassenger(String passengerId) async {
    try {
      final response = await _apiClient.client.get(
        '/complaints/passenger/$passengerId',
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => Complaint.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get all complaints
   */
  Future<List<Complaint>> getAllComplaints() async {
    try {
      final response = await _apiClient.client.get('/complaints');
      
      final List<dynamic> data = response.data;
      return data.map((json) => Complaint.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get unresolved complaints
   */
  Future<List<Complaint>> getUnresolvedComplaints() async {
    try {
      final response = await _apiClient.client.get('/complaints/unresolved');
      
      final List<dynamic> data = response.data;
      return data.map((json) => Complaint.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get complaints by status
   */
  Future<List<Complaint>> getComplaintsByStatus(String status) async {
    try {
      final response = await _apiClient.client.get('/complaints/status/$status');
      
      final List<dynamic> data = response.data;
      return data.map((json) => Complaint.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Assign complaint to authority
   */
  Future<Complaint> assignComplaint(int complaintId, String authorityId) async {
    try {
      final response = await _apiClient.client.put(
        '/complaints/$complaintId/assign/$authorityId',
      );
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Resolve complaint
   */
  Future<Complaint> resolveComplaint(
    int complaintId,
    String resolutionNotes,
  ) async {
    try {
      final response = await _apiClient.client.put(
        '/complaints/$complaintId/resolve',
        data: {'resolutionNotes': resolutionNotes},
      );
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Reject complaint
   */
  Future<Complaint> rejectComplaint(int complaintId, String reason) async {
    try {
      final response = await _apiClient.client.put(
        '/complaints/$complaintId/reject',
        data: {'reason': reason},
      );
      return Complaint.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  /**
   * Get complaint statistics
   */
  Future<Map<String, int>> getComplaintStatistics() async {
    try {
      final response = await _apiClient.client.get('/complaints/statistics');
      
      final Map<String, dynamic> data = response.data;
      return data.map((key, value) => MapEntry(key, value as int));
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