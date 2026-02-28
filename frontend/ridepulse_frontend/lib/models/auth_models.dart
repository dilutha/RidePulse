import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

/**
 * Login Request DTO
 * 
 * ENCAPSULATION:
 * Data Transfer Object for login requests
 */
@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
  
  LoginRequest({
    required this.email,
    required this.password,
  });
  
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

/**
 * Register Request DTO
 */
@JsonSerializable()
class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String role;
  
  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });
  
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

/**
 * Authentication Response DTO
 * Matches backend AuthResponse
 */
@JsonSerializable()
class AuthResponse {
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String token;
  final String tokenType;
  
  AuthResponse({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.token,
    this.tokenType = 'Bearer',
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) => 
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}