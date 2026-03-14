// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Complaint _$ComplaintFromJson(Map<String, dynamic> json) => Complaint(
  complaintId: (json['complaintId'] as num?)?.toInt(),
  complaintNumber: json['complaintNumber'] as String?,
  passengerId: json['passengerId'] as String?,
  passengerName: json['passengerName'] as String?,
  passengerEmail: json['passengerEmail'] as String?,
  busId: (json['busId'] as num?)?.toInt(),
  busNumber: json['busNumber'] as String?,
  staffId: (json['staffId'] as num?)?.toInt(),
  staffName: json['staffName'] as String?,
  category: json['category'] as String,
  categoryDescription: json['categoryDescription'] as String?,
  description: json['description'] as String,
  photoUrl: json['photoUrl'] as String?,
  priority: json['priority'] as String?,
  status: json['status'] as String?,
  assignedToId: json['assignedToId'] as String?,
  assignedToName: json['assignedToName'] as String?,
  resolutionNotes: json['resolutionNotes'] as String?,
  submittedAt: json['submittedAt'] as String?,
  resolvedAt: json['resolvedAt'] as String?,
);

Map<String, dynamic> _$ComplaintToJson(Complaint instance) => <String, dynamic>{
  'complaintId': instance.complaintId,
  'complaintNumber': instance.complaintNumber,
  'passengerId': instance.passengerId,
  'passengerName': instance.passengerName,
  'passengerEmail': instance.passengerEmail,
  'busId': instance.busId,
  'busNumber': instance.busNumber,
  'staffId': instance.staffId,
  'staffName': instance.staffName,
  'category': instance.category,
  'categoryDescription': instance.categoryDescription,
  'description': instance.description,
  'photoUrl': instance.photoUrl,
  'priority': instance.priority,
  'status': instance.status,
  'assignedToId': instance.assignedToId,
  'assignedToName': instance.assignedToName,
  'resolutionNotes': instance.resolutionNotes,
  'submittedAt': instance.submittedAt,
  'resolvedAt': instance.resolvedAt,
};

CreateComplaintRequest _$CreateComplaintRequestFromJson(
  Map<String, dynamic> json,
) => CreateComplaintRequest(
  passengerId: json['passengerId'] as String,
  busId: (json['busId'] as num?)?.toInt(),
  staffId: (json['staffId'] as num?)?.toInt(),
  category: json['category'] as String,
  description: json['description'] as String,
  photoUrl: json['photoUrl'] as String?,
);

Map<String, dynamic> _$CreateComplaintRequestToJson(
  CreateComplaintRequest instance,
) => <String, dynamic>{
  'passengerId': instance.passengerId,
  'busId': instance.busId,
  'staffId': instance.staffId,
  'category': instance.category,
  'description': instance.description,
  'photoUrl': instance.photoUrl,
};
