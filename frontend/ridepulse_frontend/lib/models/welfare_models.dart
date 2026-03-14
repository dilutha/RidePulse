import 'package:json_annotation/json_annotation.dart';

part 'welfare_models.g.dart';

/**
 * WelfareRecord Model
 * 
 * ENCAPSULATION (OOP Concept):
 * Encapsulates welfare record data
 */
@JsonSerializable()
class WelfareRecord {
  final int? recordId;
  final int busId;
  final String? busNumber;
  final int staffId;
  final String? staffName;
  final String? employeeId;
  final String recordDate;
  final double dailyRevenue;
  final double? fuelCost;
  final double? maintenanceCost;
  final double? wages;
  final double? totalExpenses;
  final double? dailyProfit;
  final double? welfarePercentage;
  final double? welfareAmount;
  final String staffType;
  final String? status;
  
  WelfareRecord({
    this.recordId,
    required this.busId,
    this.busNumber,
    required this.staffId,
    this.staffName,
    this.employeeId,
    required this.recordDate,
    required this.dailyRevenue,
    this.fuelCost,
    this.maintenanceCost,
    this.wages,
    this.totalExpenses,
    this.dailyProfit,
    this.welfarePercentage,
    this.welfareAmount,
    required this.staffType,
    this.status,
  });
  
  factory WelfareRecord.fromJson(Map<String, dynamic> json) => 
      _$WelfareRecordFromJson(json);
  Map<String, dynamic> toJson() => _$WelfareRecordToJson(this);
}

/**
 * WelfareSummary Model
 */
@JsonSerializable()
class WelfareSummary {
  final int staffId;
  final String staffName;
  final String employeeId;
  final double totalWelfareAmount;
  final double pendingWelfareAmount;
  final double approvedWelfareAmount;
  final double paidWelfareAmount;
  final int totalRecords;
  
  WelfareSummary({
    required this.staffId,
    required this.staffName,
    required this.employeeId,
    required this.totalWelfareAmount,
    required this.pendingWelfareAmount,
    required this.approvedWelfareAmount,
    required this.paidWelfareAmount,
    required this.totalRecords,
  });
  
  factory WelfareSummary.fromJson(Map<String, dynamic> json) => 
      _$WelfareSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$WelfareSummaryToJson(this);
}

/**
 * CreateWelfareRequest Model
 */
@JsonSerializable()
class CreateWelfareRequest {
  final int busId;
  final int staffId;
  final String recordDate;
  final double dailyRevenue;
  final double fuelCost;
  final double maintenanceCost;
  final double wages;
  final String staffType;
  
  CreateWelfareRequest({
    required this.busId,
    required this.staffId,
    required this.recordDate,
    required this.dailyRevenue,
    required this.fuelCost,
    required this.maintenanceCost,
    required this.wages,
    required this.staffType,
  });
  
  Map<String, dynamic> toJson() => _$CreateWelfareRequestToJson(this);
}