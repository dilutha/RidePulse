// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  userId: json['userId'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'fullName': instance.fullName,
  'phone': instance.phone,
  'role': instance.role,
  'isActive': instance.isActive,
};
