// ============================================================
// core/services/auth_service.dart — FIXED VERSION
//
// Fix: registerStaff() now sends dateOfJoining (today's date).
// The Spring Boot RegisterStaffRequest had @NotNull on this field.
// Without it, Spring's @Valid threw 400 which looked like 403.
//
// Also added cleaner error extraction from Spring's error response body.
// ============================================================
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

const String _base = 'http://localhost:8080/api/v1';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  // ── Headers ────────────────────────────────────────────────

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Auth endpoints ─────────────────────────────────────────

  Future<AuthResponse> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    _check(res);
    return AuthResponse.fromJson(jsonDecode(res.body));
  }

  Future<AuthResponse> registerPassenger({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register/passenger'),
      headers: _headers,
      body: jsonEncode({
        'fullName': fullName,
        'email':    email,
        'phone':    phone,
        'password': password,
      }),
    );
    _check(res);
    return AuthResponse.fromJson(jsonDecode(res.body));
  }

  Future<AuthResponse> registerBusOwner({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String businessName,
    required String nicNumber,
    String? address,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register/bus-owner'),
      headers: _headers,
      body: jsonEncode({
        'fullName':     fullName,
        'email':        email,
        'phone':        phone,
        'password':     password,
        'businessName': businessName,
        'nicNumber':    nicNumber,
        'address':      address,
      }),
    );
    _check(res);
    return AuthResponse.fromJson(jsonDecode(res.body));
  }

  Future<AuthResponse> registerAuthority({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String designation,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register/authority'),
      headers: _headers,
      body: jsonEncode({
        'fullName':    fullName,
        'email':       email,
        'phone':       phone,
        'password':    password,
        'designation': designation,
      }),
    );
    _check(res);
    return AuthResponse.fromJson(jsonDecode(res.body));
  }

  /// Register staff (driver or conductor).
  /// IMPORTANT: called by BUS OWNER — sends their JWT token.
  /// The bus owner must be logged in for this to work.
  Future<AuthResponse> registerStaff({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String staffType,   // "driver" | "conductor"
    required String employeeId,
    String? licenseNumber,
    double? baseSalary,
    int?    busId,
  }) async {
    // FIX: always send the bus owner's JWT
    final headers = await _authHeaders;

    // FIX: send dateOfJoining — was @NotNull in Spring DTO,
    // omitting it caused validation error (400 → appeared as 403)
    final today = DateTime.now().toIso8601String().split('T')[0]; // "YYYY-MM-DD"

    final res = await http.post(
      Uri.parse('$_base/auth/register/staff'),
      headers: headers,
      body: jsonEncode({
        'fullName':      fullName,
        'email':         email,
        'phone':         phone,
        'password':      password,
        'staffType':     staffType,
        'employeeId':    employeeId,
        'dateOfJoining': today,       // FIX: was missing
        'licenseNumber': licenseNumber,
        'baseSalary':    baseSalary,
        'busId':         busId,
      }),
    );
    _check(res);
    return AuthResponse.fromJson(jsonDecode(res.body));
  }

  // ── Session management ─────────────────────────────────────

  Future<void> saveSession(AuthResponse r) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', r.accessToken);
    await prefs.setString('role',         r.role);
    await prefs.setString('full_name',    r.fullName);
    await prefs.setString('email',        r.email);
    if (r.ownerId != null) await prefs.setInt('owner_id', r.ownerId!);
    if (r.staffId != null) await prefs.setInt('staff_id', r.staffId!);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<AuthResponse?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) return null;
    return AuthResponse(
      accessToken: token,
      role:     prefs.getString('role')      ?? '',
      fullName: prefs.getString('full_name') ?? '',
      email:    prefs.getString('email')     ?? '',
      ownerId:  prefs.getInt('owner_id'),
      staffId:  prefs.getInt('staff_id'),
    );
  }

  // ── Error handling ─────────────────────────────────────────

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      String message = 'Error ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        // Spring Boot returns different shapes depending on error type
        if (body is Map) {
          message = body['message']
              ?? body['error']
              ?? body['detail']
              ?? message;
          // Handle Spring validation errors (400)
          if (body['errors'] is List) {
            final errs = (body['errors'] as List)
                .map((e) => e['defaultMessage'] ?? e.toString())
                .join(', ');
            message = 'Validation: $errs';
          }
        }
      } catch (_) {
        // body wasn't JSON — use status code message
        if (res.statusCode == 401) message = 'Invalid credentials';
        if (res.statusCode == 403) {
          message = 'Access denied — make sure you are logged in as Bus Owner';
        }
        if (res.statusCode == 409) message = 'Email already registered';
      }
      throw Exception(message);
    }
  }
}
