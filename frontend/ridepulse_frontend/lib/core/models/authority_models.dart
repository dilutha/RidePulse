class AuthorityDashboardStats {
  final int totalComplaints, openComplaints, resolvedComplaints;
  final int totalBuses, activeBuses, busesOnTrip;
  final int totalDrivers, totalConductors;
  final int totalBusOwners, totalRoutes;

  AuthorityDashboardStats({
    required this.totalComplaints, required this.openComplaints,
    required this.resolvedComplaints, required this.totalBuses,
    required this.activeBuses, required this.busesOnTrip,
    required this.totalDrivers, required this.totalConductors,
    required this.totalBusOwners, required this.totalRoutes,
  });

  factory AuthorityDashboardStats.fromJson(Map<String, dynamic> j) =>
      AuthorityDashboardStats(
    totalComplaints:  (j['totalComplaints']  as num?)?.toInt() ?? 0,
    openComplaints:   (j['openComplaints']   as num?)?.toInt() ?? 0,
    resolvedComplaints:(j['resolvedComplaints']as num?)?.toInt() ?? 0,
    totalBuses:       (j['totalBuses']       as num?)?.toInt() ?? 0,
    activeBuses:      (j['activeBuses']      as num?)?.toInt() ?? 0,
    busesOnTrip:      (j['busesOnTrip']      as num?)?.toInt() ?? 0,
    totalDrivers:     (j['totalDrivers']     as num?)?.toInt() ?? 0,
    totalConductors:  (j['totalConductors']  as num?)?.toInt() ?? 0,
    totalBusOwners:   (j['totalBusOwners']   as num?)?.toInt() ?? 0,
    totalRoutes:      (j['totalRoutes']      as num?)?.toInt() ?? 0,
  );
}


class AuthorityBus {
  final int     busId;
  final String  busNumber, registrationNumber;
  final String  ownerName, ownerBusinessName;
  final String  routeNumber, routeName;
  final int     capacity;
  final String? model;
  final bool    isActive, hasGps, isOnTrip;
  final double? latitude, longitude, speedKmh;
  final String  lastGpsUpdate;
  final String  crowdCategory;
  final int     passengerCount;

  AuthorityBus({
    required this.busId,         required this.busNumber,
    required this.registrationNumber, required this.ownerName,
    required this.ownerBusinessName,  required this.routeNumber,
    required this.routeName,     required this.capacity,
    this.model,                  required this.isActive,
    required this.hasGps,        required this.isOnTrip,
    this.latitude,               this.longitude,
    this.speedKmh,               required this.lastGpsUpdate,
    required this.crowdCategory, required this.passengerCount,
  });

  factory AuthorityBus.fromJson(Map<String, dynamic> j) => AuthorityBus(
    busId:              j['busId'],
    busNumber:          j['busNumber']          ?? '',
    registrationNumber: j['registrationNumber'] ?? '',
    ownerName:          j['ownerName']          ?? '',
    ownerBusinessName:  j['ownerBusinessName']  ?? '',
    routeNumber:        j['routeNumber']        ?? '',
    routeName:          j['routeName']          ?? '',
    capacity:           (j['capacity']          as num?)?.toInt()    ?? 0,
    model:               j['model'],
    isActive:            j['isActive']           ?? false,
    hasGps:              j['hasGps']             ?? false,
    isOnTrip:            j['isOnTrip']           ?? false,
    latitude:           (j['latitude']           as num?)?.toDouble(),
    longitude:          (j['longitude']          as num?)?.toDouble(),
    speedKmh:           (j['speedKmh']           as num?)?.toDouble(),
    lastGpsUpdate:       j['lastGpsUpdate']       ?? 'Unknown',
    crowdCategory:       j['crowdCategory']       ?? 'unknown',
    passengerCount:     (j['passengerCount']      as num?)?.toInt()   ?? 0,
  );

  bool get hasLocation => latitude != null && longitude != null;
}


class AuthorityStaff {
  final int     staffId;
  final String  fullName, email, phone, employeeId, staffType;
  final String? licenseNumber, assignedBusNumber;
  final String? ownerName, ownerBusinessName;
  final bool    isActive;
  final String? dateOfJoining;

  AuthorityStaff({
    required this.staffId,       required this.fullName,
    required this.email,         required this.phone,
    required this.employeeId,    required this.staffType,
    this.licenseNumber,          this.assignedBusNumber,
    this.ownerName,              this.ownerBusinessName,
    required this.isActive,      this.dateOfJoining,
  });

  factory AuthorityStaff.fromJson(Map<String, dynamic> j) => AuthorityStaff(
    staffId:           j['staffId'],
    fullName:          j['fullName']          ?? '',
    email:             j['email']             ?? '',
    phone:             j['phone']             ?? '',
    employeeId:        j['employeeId']        ?? '',
    staffType:         j['staffType']         ?? '',
    licenseNumber:     j['licenseNumber'],
    assignedBusNumber: j['assignedBusNumber'],
    ownerName:         j['ownerName'],
    ownerBusinessName: j['ownerBusinessName'],
    isActive:          j['isActive']          ?? true,
    dateOfJoining:     j['dateOfJoining'],
  );
}


class AuthorityOwner {
  final int     ownerId;
  final String  fullName, email, phone, businessName, nicNumber;
  final String? address, registeredAt;
  final int     totalBuses, activeBuses, totalStaff;

  AuthorityOwner({
    required this.ownerId,      required this.fullName,
    required this.email,        required this.phone,
    required this.businessName, required this.nicNumber,
    this.address,               this.registeredAt,
    required this.totalBuses,   required this.activeBuses,
    required this.totalStaff,
  });

  factory AuthorityOwner.fromJson(Map<String, dynamic> j) => AuthorityOwner(
    ownerId:      j['ownerId'],
    fullName:     j['fullName']     ?? '',
    email:        j['email']        ?? '',
    phone:        j['phone']        ?? '',
    businessName: j['businessName'] ?? '',
    nicNumber:    j['nicNumber']    ?? '',
    address:      j['address'],
    registeredAt: j['registeredAt'],
    totalBuses:   (j['totalBuses']  as num?)?.toInt() ?? 0,
    activeBuses:  (j['activeBuses'] as num?)?.toInt() ?? 0,
    totalStaff:   (j['totalStaff']  as num?)?.toInt() ?? 0,
  );
}


class StopFarePreview {
  final int    stopCount;
  final double fare;
  StopFarePreview({required this.stopCount, required this.fare});
  factory StopFarePreview.fromJson(Map<String, dynamic> j) =>
      StopFarePreview(
    stopCount: (j['stopCount'] as num?)?.toInt()    ?? 0,
    fare:      (j['fare']      as num?)?.toDouble() ?? 0,
  );
}


class FareConfig {
  final int    routeId;
  final String routeNumber, routeName, startLocation, endLocation;
  final int    totalStops;
  final double minimumFare, farePerStop, maximumFare, currentBaseFare;
  final String? updatedAt;
  final List<StopFarePreview> farePreview;

  FareConfig({
    required this.routeId,        required this.routeNumber,
    required this.routeName,      required this.startLocation,
    required this.endLocation,    required this.totalStops,
    required this.minimumFare,    required this.farePerStop,
    required this.maximumFare,    required this.currentBaseFare,
    this.updatedAt,               required this.farePreview,
  });

  factory FareConfig.fromJson(Map<String, dynamic> j) => FareConfig(
    routeId:        j['routeId'],
    routeNumber:    j['routeNumber']    ?? '',
    routeName:      j['routeName']      ?? '',
    startLocation:  j['startLocation']  ?? '',
    endLocation:    j['endLocation']    ?? '',
    totalStops:     (j['totalStops']    as num?)?.toInt()    ?? 0,
    minimumFare:    (j['minimumFare']   as num?)?.toDouble() ?? 30.0,
    farePerStop:    (j['farePerStop']   as num?)?.toDouble() ?? 8.0,
    maximumFare:    (j['maximumFare']   as num?)?.toDouble() ?? 2422.0,
    currentBaseFare:(j['currentBaseFare']as num?)?.toDouble()?? 30.0,
    updatedAt:       j['updatedAt'],
    farePreview: (j['farePreview'] as List<dynamic>?)
        ?.map((e) => StopFarePreview.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList() ?? [],
  );

  // Encapsulation: compute fare from client side for instant preview
  double computeFare(int stopCount) {
    double fare = currentBaseFare + (stopCount - 1) * farePerStop;
    return fare.clamp(minimumFare, maximumFare);
  }
}
