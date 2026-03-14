// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welfare_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WelfareRecord _$WelfareRecordFromJson(Map<String, dynamic> json) =>
    WelfareRecord(
      recordId: (json['recordId'] as num?)?.toInt(),
      busId: (json['busId'] as num).toInt(),
      busNumber: json['busNumber'] as String?,
      staffId: (json['staffId'] as num).toInt(),
      staffName: json['staffName'] as String?,
      employeeId: json['employeeId'] as String?,
      recordDate: json['recordDate'] as String,
      dailyRevenue: (json['dailyRevenue'] as num).toDouble(),
      fuelCost: (json['fuelCost'] as num?)?.toDouble(),
      maintenanceCost: (json['maintenanceCost'] as num?)?.toDouble(),
      wages: (json['wages'] as num?)?.toDouble(),
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble(),
      dailyProfit: (json['dailyProfit'] as num?)?.toDouble(),
      welfarePercentage: (json['welfarePercentage'] as num?)?.toDouble(),
      welfareAmount: (json['welfareAmount'] as num?)?.toDouble(),
      staffType: json['staffType'] as String,
      status: json['status'] as String?,
    );

Map<String, dynamic> _$WelfareRecordToJson(WelfareRecord instance) =>
    <String, dynamic>{
      'recordId': instance.recordId,
      'busId': instance.busId,
      'busNumber': instance.busNumber,
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'employeeId': instance.employeeId,
      'recordDate': instance.recordDate,
      'dailyRevenue': instance.dailyRevenue,
      'fuelCost': instance.fuelCost,
      'maintenanceCost': instance.maintenanceCost,
      'wages': instance.wages,
      'totalExpenses': instance.totalExpenses,
      'dailyProfit': instance.dailyProfit,
      'welfarePercentage': instance.welfarePercentage,
      'welfareAmount': instance.welfareAmount,
      'staffType': instance.staffType,
      'status': instance.status,
    };

WelfareSummary _$WelfareSummaryFromJson(Map<String, dynamic> json) =>
    WelfareSummary(
      staffId: (json['staffId'] as num).toInt(),
      staffName: json['staffName'] as String,
      employeeId: json['employeeId'] as String,
      totalWelfareAmount: (json['totalWelfareAmount'] as num).toDouble(),
      pendingWelfareAmount: (json['pendingWelfareAmount'] as num).toDouble(),
      approvedWelfareAmount: (json['approvedWelfareAmount'] as num).toDouble(),
      paidWelfareAmount: (json['paidWelfareAmount'] as num).toDouble(),
      totalRecords: (json['totalRecords'] as num).toInt(),
    );

Map<String, dynamic> _$WelfareSummaryToJson(WelfareSummary instance) =>
    <String, dynamic>{
      'staffId': instance.staffId,
      'staffName': instance.staffName,
      'employeeId': instance.employeeId,
      'totalWelfareAmount': instance.totalWelfareAmount,
      'pendingWelfareAmount': instance.pendingWelfareAmount,
      'approvedWelfareAmount': instance.approvedWelfareAmount,
      'paidWelfareAmount': instance.paidWelfareAmount,
      'totalRecords': instance.totalRecords,
    };

CreateWelfareRequest _$CreateWelfareRequestFromJson(
  Map<String, dynamic> json,
) => CreateWelfareRequest(
  busId: (json['busId'] as num).toInt(),
  staffId: (json['staffId'] as num).toInt(),
  recordDate: json['recordDate'] as String,
  dailyRevenue: (json['dailyRevenue'] as num).toDouble(),
  fuelCost: (json['fuelCost'] as num).toDouble(),
  maintenanceCost: (json['maintenanceCost'] as num).toDouble(),
  wages: (json['wages'] as num).toDouble(),
  staffType: json['staffType'] as String,
);

Map<String, dynamic> _$CreateWelfareRequestToJson(
  CreateWelfareRequest instance,
) => <String, dynamic>{
  'busId': instance.busId,
  'staffId': instance.staffId,
  'recordDate': instance.recordDate,
  'dailyRevenue': instance.dailyRevenue,
  'fuelCost': instance.fuelCost,
  'maintenanceCost': instance.maintenanceCost,
  'wages': instance.wages,
  'staffType': instance.staffType,
};
