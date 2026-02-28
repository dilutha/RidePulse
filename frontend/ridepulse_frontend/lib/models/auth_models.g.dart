// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'email': instance.email,
      'phone': instance.phone,
      'password': instance.password,
      'role': instance.role,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  userId: json['userId'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  role: json['role'] as String,
  token: json['token'] as String,
  tokenType: json['tokenType'] as String? ?? 'Bearer',
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'fullName': instance.fullName,
      'role': instance.role,
      'token': instance.token,
      'tokenType': instance.tokenType,
    };
