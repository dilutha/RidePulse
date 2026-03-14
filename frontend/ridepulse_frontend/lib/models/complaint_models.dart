import 'package:json_annotation/json_annotation.dart';

part 'complaint_models.g.dart';

/**
 * Complaint Model
 * 
 * ENCAPSULATION (OOP Concept):
 * Encapsulates complaint data
 */
@JsonSerializable()
class Complaint {
  final int? complaintId;
  final String? complaintNumber;
  final String? passengerId;
  final String? passengerName;
  final String? passengerEmail;
  final int? busId;
  final String? busNumber;
  final int? staffId;
  final String? staffName;
  final String category;
  final String? categoryDescription;
  final String description;
  final String? photoUrl;
  final String? priority;
  final String? status;
  final String? assignedToId;
  final String? assignedToName;
  final String? resolutionNotes;
  final String? submittedAt;
  final String? resolvedAt;
  
  Complaint({
    this.complaintId,
    this.complaintNumber,
    this.passengerId,
    this.passengerName,
    this.passengerEmail,
    this.busId,
    this.busNumber,
    this.staffId,
    this.staffName,
    required this.category,
    this.categoryDescription,
    required this.description,
    this.photoUrl,
    this.priority,
    this.status,
    this.assignedToId,
    this.assignedToName,
    this.resolutionNotes,
    this.submittedAt,
    this.resolvedAt,
  });
  
  factory Complaint.fromJson(Map<String, dynamic> json) => 
      _$ComplaintFromJson(json);
  Map<String, dynamic> toJson() => _$ComplaintToJson(this);
}

/**
 * CreateComplaintRequest Model
 */
@JsonSerializable()
class CreateComplaintRequest {
  final String passengerId;
  final int? busId;
  final int? staffId;
  final String category;
  final String description;
  final String? photoUrl;
  
  CreateComplaintRequest({
    required this.passengerId,
    this.busId,
    this.staffId,
    required this.category,
    required this.description,
    this.photoUrl,
  });
  
  Map<String, dynamic> toJson() => _$CreateComplaintRequestToJson(this);
}

/**
 * Complaint Categories
 */
class ComplaintCategory {
  static const String DISRUPTIVE_DRIVING = 'DISRUPTIVE_DRIVING';
  static const String INCORRECT_CHANGE = 'INCORRECT_CHANGE';
  static const String UNFAIR_PRICING = 'UNFAIR_PRICING';
  static const String SLOW_DRIVING = 'SLOW_DRIVING';
  static const String FAST_DRIVING = 'FAST_DRIVING';
  static const String OVERCROWDED = 'OVERCROWDED';
  static const String POOR_MAINTENANCE = 'POOR_MAINTENANCE';
  static const String RUDE_BEHAVIOR = 'RUDE_BEHAVIOR';
  static const String OTHER = 'OTHER';
  
  static const Map<String, String> descriptions = {
    DISRUPTIVE_DRIVING: 'Disruptive or unsafe driving',
    INCORRECT_CHANGE: 'Not providing correct ticket change',
    UNFAIR_PRICING: 'Unfair ticket pricing',
    SLOW_DRIVING: 'Slow driving',
    FAST_DRIVING: 'Excessively fast driving',
    OVERCROWDED: 'Overcrowded bus',
    POOR_MAINTENANCE: 'Poorly maintained bus',
    RUDE_BEHAVIOR: 'Rude behavior',
    OTHER: 'Other',
  };
  
  static List<String> get all => descriptions.keys.toList();
  
  static String getDescription(String category) {
    return descriptions[category] ?? category;
  }
}

/**
 * Complaint Status
 */
class ComplaintStatus {
  static const String SUBMITTED = 'SUBMITTED';
  static const String UNDER_REVIEW = 'UNDER_REVIEW';
  static const String RESOLVED = 'RESOLVED';
  static const String CLOSED = 'CLOSED';
  static const String REJECTED = 'REJECTED';
}