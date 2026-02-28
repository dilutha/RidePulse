import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/**
 * User Model
 * 
 * ENCAPSULATION (OOP Concept):
 * Represents user data structure
 * Matches backend User entity
 * 
 * @JsonSerializable generates fromJson and toJson methods
 */
@JsonSerializable()
class User {
  @JsonKey(name: 'userId')
  final String userId;
  
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  
  @JsonKey(name: 'isActive')
  final bool isActive;
  
  User({
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    this.isActive = true,
  });
  
  // JSON serialization
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
  
  // Create a copy with modified fields
  User copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? phone,
    String? role,
    bool? isActive,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
