// ============================================================
// core/models/bus_models.dart
// ============================================================

class RouteModel {
  final int routeId;
  final String routeNumber;
  final String routeName;
  final String startLocation;
  final String endLocation;
  final double baseFare;

  RouteModel({
    required this.routeId,
    required this.routeNumber,
    required this.routeName,
    required this.startLocation,
    required this.endLocation,
    required this.baseFare,
  });

  factory RouteModel.fromJson(Map<String, dynamic> j) => RouteModel(
        routeId: j['routeId'],
        routeNumber: j['routeNumber'] ?? '',
        routeName: j['routeName'] ?? '',
        startLocation: j['startLocation'] ?? '',
        endLocation: j['endLocation'] ?? '',
        baseFare: (j['baseFare'] as num?)?.toDouble() ?? 0,
      );

  // Encapsulation: display string is built by the model
  String get displayName => '$routeNumber — $routeName';
}

class BusModel {
  final int busId;
  final String busNumber;
  final String registrationNumber;
  final int capacity;
  final String? model;
  final bool isActive;
  final RouteModel? route;
  final String assignedDriverName;
  final String assignedConductorName;

  BusModel({
    required this.busId,
    required this.busNumber,
    required this.registrationNumber,
    required this.capacity,
    this.model,
    required this.isActive,
    this.route,
    required this.assignedDriverName,
    required this.assignedConductorName,
  });

  factory BusModel.fromJson(Map<String, dynamic> j) => BusModel(
        busId: j['busId'],
        busNumber: j['busNumber'] ?? '',
        registrationNumber: j['registrationNumber'] ?? '',
        capacity: j['capacity'] ?? 0,
        model: j['model'],
        isActive: j['isActive'] ?? true,
        route: j['route'] != null ? RouteModel.fromJson(j['route']) : null,
        assignedDriverName: j['assignedDriverName'] ?? 'Unassigned',
        assignedConductorName: j['assignedConductorName'] ?? 'Unassigned',
      );
}

class BusOwnerDashboardModel {
  final String ownerName;
  final String businessName;
  final int totalBuses;
  final int activeBuses;
  final int totalStaff;
  final int activeStaff;
  final double totalMonthGrossRevenue;
  final double totalMonthNetProfit;
  final double totalDriverWelfare;
  final double totalConductorWelfare;
  final int totalOpenComplaints;
  final List<BusDashboardCardModel> buses;

  BusOwnerDashboardModel({
    required this.ownerName,
    required this.businessName,
    required this.totalBuses,
    required this.activeBuses,
    required this.totalStaff,
    required this.activeStaff,
    required this.totalMonthGrossRevenue,
    required this.totalMonthNetProfit,
    required this.totalDriverWelfare,
    required this.totalConductorWelfare,
    required this.totalOpenComplaints,
    required this.buses,
  });

  factory BusOwnerDashboardModel.fromJson(Map<String, dynamic> j) =>
      BusOwnerDashboardModel(
        ownerName: j['ownerName'] ?? '',
        businessName: j['businessName'] ?? '',
        totalBuses: (j['totalBuses'] as num?)?.toInt() ?? 0,
        activeBuses: (j['activeBuses'] as num?)?.toInt() ?? 0,
        totalStaff: (j['totalStaff'] as num?)?.toInt() ?? 0,
        activeStaff: (j['activeStaff'] as num?)?.toInt() ?? 0,
        totalMonthGrossRevenue:
            (j['totalMonthGrossRevenue'] as num?)?.toDouble() ?? 0,
        totalMonthNetProfit:
            (j['totalMonthNetProfit'] as num?)?.toDouble() ?? 0,
        totalDriverWelfare: (j['totalDriverWelfare'] as num?)?.toDouble() ?? 0,
        totalConductorWelfare:
            (j['totalConductorWelfare'] as num?)?.toDouble() ?? 0,
        totalOpenComplaints: (j['totalOpenComplaints'] as num?)?.toInt() ?? 0,
        buses: (j['buses'] as List<dynamic>?)
                ?.map((e) => BusDashboardCardModel.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}

class BusDashboardCardModel {
  final int busId;
  final String busNumber;
  final String registrationNumber;
  final String routeName;
  final bool isActive;
  final int capacity;
  final double? currentLatitude;
  final double? currentLongitude;
  final String crowdCategory;
  final int currentPassengerCount;
  final double monthGrossRevenue;
  final double monthNetProfit;
  final int openComplaintsCount;
  final String assignedDriverName;
  final String assignedConductorName;

  BusDashboardCardModel({
    required this.busId,
    required this.busNumber,
    required this.registrationNumber,
    required this.routeName,
    required this.isActive,
    required this.capacity,
    this.currentLatitude,
    this.currentLongitude,
    required this.crowdCategory,
    required this.currentPassengerCount,
    required this.monthGrossRevenue,
    required this.monthNetProfit,
    required this.openComplaintsCount,
    required this.assignedDriverName,
    required this.assignedConductorName,
  });

  factory BusDashboardCardModel.fromJson(Map<String, dynamic> j) =>
      BusDashboardCardModel(
        busId: j['busId'],
        busNumber: j['busNumber'] ?? '',
        registrationNumber: j['registrationNumber'] ?? '',
        routeName: j['routeName'] ?? 'No route',
        isActive: j['isActive'] ?? false,
        capacity: (j['capacity'] as num?)?.toInt() ?? 0,
        currentLatitude: (j['currentLatitude'] as num?)?.toDouble(),
        currentLongitude: (j['currentLongitude'] as num?)?.toDouble(),
        crowdCategory: j['crowdCategory'] ?? 'unknown',
        currentPassengerCount:
            (j['currentPassengerCount'] as num?)?.toInt() ?? 0,
        monthGrossRevenue: (j['monthGrossRevenue'] as num?)?.toDouble() ?? 0,
        monthNetProfit: (j['monthNetProfit'] as num?)?.toDouble() ?? 0,
        openComplaintsCount: (j['openComplaintsCount'] as num?)?.toInt() ?? 0,
        assignedDriverName: j['assignedDriverName'] ?? 'Unassigned',
        assignedConductorName: j['assignedConductorName'] ?? 'Unassigned',
      );

  bool get hasLocation => currentLatitude != null && currentLongitude != null;
}

class StaffModel {
  final int staffId;
  final String fullName;
  final String phone;
  final String employeeId;
  final String staffType;
  final String? licenseNumber;
  final double baseSalary;
  final bool isActive;
  final String assignedBusNumber;
  final int dutyDaysThisMonth;
  final double welfareBalanceThisMonth;
  final double cumulativeWelfareBalance;

  StaffModel({
    required this.staffId,
    required this.fullName,
    required this.phone,
    required this.employeeId,
    required this.staffType,
    this.licenseNumber,
    required this.baseSalary,
    required this.isActive,
    required this.assignedBusNumber,
    required this.dutyDaysThisMonth,
    required this.welfareBalanceThisMonth,
    required this.cumulativeWelfareBalance,
  });

  factory StaffModel.fromJson(Map<String, dynamic> j) => StaffModel(
        staffId: j['staffId'],
        fullName: j['fullName'] ?? '',
        phone: j['phone'] ?? '',
        employeeId: j['employeeId'] ?? '',
        staffType: j['staffType'] ?? '',
        licenseNumber: j['licenseNumber'],
        baseSalary: (j['baseSalary'] as num?)?.toDouble() ?? 0,
        isActive: j['isActive'] ?? true,
        assignedBusNumber: j['assignedBusNumber'] ?? 'Unassigned',
        dutyDaysThisMonth: j['dutyDaysThisMonth'] ?? 0,
        welfareBalanceThisMonth:
            (j['welfareBalanceThisMonth'] as num?)?.toDouble() ?? 0,
        cumulativeWelfareBalance:
            (j['cumulativeWelfareBalance'] as num?)?.toDouble() ?? 0,
      );
}

class MonthlyRevenueModel {
  final int busId;
  final String busNumber;
  final int month;
  final int year;
  final double grossRevenue;
  final double totalFuelCost;
  final double maintenanceCost;
  final double totalStaffSalaries;
  final double netProfit;
  final double driverWelfareAmount;
  final double conductorWelfareAmount;
  final bool isFinalized;

  MonthlyRevenueModel({
    required this.busId,
    required this.busNumber,
    required this.month,
    required this.year,
    required this.grossRevenue,
    required this.totalFuelCost,
    required this.maintenanceCost,
    required this.totalStaffSalaries,
    required this.netProfit,
    required this.driverWelfareAmount,
    required this.conductorWelfareAmount,
    required this.isFinalized,
  });

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> j) =>
      MonthlyRevenueModel(
        busId: j['busId'],
        busNumber: j['busNumber'] ?? '',
        month: j['month'] ?? 0,
        year: j['year'] ?? 0,
        grossRevenue: (j['grossRevenue'] as num?)?.toDouble() ?? 0,
        totalFuelCost: (j['totalFuelCost'] as num?)?.toDouble() ?? 0,
        maintenanceCost: (j['maintenanceCost'] as num?)?.toDouble() ?? 0,
        totalStaffSalaries: (j['totalStaffSalaries'] as num?)?.toDouble() ?? 0,
        netProfit: (j['netProfit'] as num?)?.toDouble() ?? 0,
        driverWelfareAmount:
            (j['driverWelfareAmount'] as num?)?.toDouble() ?? 0,
        conductorWelfareAmount:
            (j['conductorWelfareAmount'] as num?)?.toDouble() ?? 0,
        isFinalized: j['isFinalized'] ?? false,
      );
}

class BusLocationModel {
  final int busId;
  final String busNumber;
  final double latitude;
  final double longitude;
  final double? speedKmh;
  final String crowdCategory;
  final String recordedAt;

  BusLocationModel({
    required this.busId,
    required this.busNumber,
    required this.latitude,
    required this.longitude,
    this.speedKmh,
    required this.crowdCategory,
    required this.recordedAt,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> j) => BusLocationModel(
        busId: j['busId'],
        busNumber: j['busNumber'] ?? '',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        speedKmh: (j['speedKmh'] as num?)?.toDouble(),
        crowdCategory: j['crowdCategory'] ?? 'unknown',
        recordedAt: j['recordedAt'] ?? '',
      );
}
