// ============================================================
// core/models/conductor_models.dart
// OOP Encapsulation: each model hides JSON parsing internally.
//     Helper getters provide computed values without exposing logic.
// ============================================================

class RosterModel {
  final int     rosterId;
  final String  dutyDate;
  final String  shiftStart;
  final String  shiftEnd;
  final String  status;
  // Bus
  final int     busId;
  final String  busNumber;
  final String  registrationNumber;
  final int     busCapacity;
  // Route
  final int     routeId;
  final String  routeNumber;
  final String  routeName;
  final String  startLocation;
  final String  endLocation;
  final double  baseFare;
  final String  staffName;
  final String  staffType;
  final String  employeeId;
  final int?    staffId;
  // Active trip (null if not started)
  final int?    activeTripId;
  final String? tripStatus;

  RosterModel({
    required this.rosterId,    required this.dutyDate,
    required this.shiftStart,  required this.shiftEnd,
    required this.status,      required this.busId,
    required this.busNumber,   required this.registrationNumber,
    required this.busCapacity, required this.routeId,
    required this.routeNumber, required this.routeName,
    required this.startLocation, required this.endLocation,
    required this.baseFare,    this.staffName = '',
    this.staffType = '',       this.employeeId = '',
    this.staffId,              this.activeTripId,
    this.tripStatus,
  });

  factory RosterModel.fromJson(Map<String, dynamic> j) => RosterModel(
    rosterId:           j['rosterId'],
    dutyDate:           j['dutyDate']           ?? '',
    shiftStart:         j['shiftStart']         ?? '',
    shiftEnd:           j['shiftEnd']           ?? '',
    status:             j['status']             ?? 'scheduled',
    busId:              j['busId'],
    busNumber:          j['busNumber']          ?? '',
    registrationNumber: j['registrationNumber'] ?? '',
    busCapacity:        j['busCapacity']        ?? 0,
    routeId:            j['routeId'],
    routeNumber:        j['routeNumber']        ?? '',
    routeName:          j['routeName']          ?? '',
    startLocation:      j['startLocation']      ?? '',
    endLocation:        j['endLocation']        ?? '',
    baseFare:           (j['baseFare']  as num?)?.toDouble() ?? 0,
    staffName:          j['staffName']          ?? '',
    staffType:          j['staffType']          ?? '',
    employeeId:         j['employeeId']         ?? '',
    staffId:            (j['staffId'] as num?)?.toInt(),
    activeTripId:       j['activeTripId'],
    tripStatus:         j['tripStatus'],
  );

  factory RosterModel.fromRosterDetail(Map<String, dynamic> j) =>
      RosterModel.fromJson(j);

  // Encapsulation: status helpers computed from status string
  bool get isScheduled => status == 'scheduled';
  bool get isActive     => status == 'active';
  bool get isCompleted  => status == 'completed';
  bool get hasTripActive => activeTripId != null && tripStatus == 'in_progress';
  bool get isDriver => staffType == 'driver';
}


class TripModel {
  final int     tripId;
  final String  busNumber;
  final String  routeName;
  final String  status;
  final String  tripStart;
  final String? tripEnd;
  final int     ticketsIssuedCount;
  final double  totalFareCollected;
  final int     currentPassengerCount;

  TripModel({
    required this.tripId,              required this.busNumber,
    required this.routeName,           required this.status,
    required this.tripStart,           this.tripEnd,
    required this.ticketsIssuedCount,
    required this.totalFareCollected,  required this.currentPassengerCount,
  });

  factory TripModel.fromJson(Map<String, dynamic> j) => TripModel(
    tripId:               j['tripId'],
    busNumber:            j['busNumber']            ?? '',
    routeName:            j['routeName']            ?? '',
    status:               j['status']               ?? '',
    tripStart:            j['tripStart']            ?? '',
    tripEnd:              j['tripEnd'],
    ticketsIssuedCount:   (j['ticketsIssuedCount']  as num?)?.toInt()    ?? 0,
    totalFareCollected:   (j['totalFareCollected']  as num?)?.toDouble() ?? 0,
    currentPassengerCount:(j['currentPassengerCount']as num?)?.toInt()   ?? 0,
  );

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted  => status == 'completed';
}


class TicketModel {
  final int    ticketId;
  final String ticketNumber;
  final String qrCode;
  final String boardingStop;
  final String alightingStop;
  final double fareAmount;
  final String paymentMethod;
  final String ticketStatus;
  final String issuedAt;

  TicketModel({
    required this.ticketId,      required this.ticketNumber,
    required this.qrCode,        required this.boardingStop,
    required this.alightingStop, required this.fareAmount,
    required this.paymentMethod, required this.ticketStatus,
    required this.issuedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> j) => TicketModel(
    ticketId:      j['ticketId'],
    ticketNumber:  j['ticketNumber']  ?? '',
    qrCode:        j['qrCode']        ?? '',
    boardingStop:  j['boardingStop']  ?? '',
    alightingStop: j['alightingStop'] ?? '',
    fareAmount:    (j['fareAmount']   as num?)?.toDouble() ?? 0,
    paymentMethod: j['paymentMethod'] ?? 'cash',
    ticketStatus:  j['ticketStatus']  ?? 'active',
    issuedAt:      j['issuedAt']      ?? '',
  );
}


class StopModel {
  final int    stopId;
  final String stopName;
  final int    stopSequence;

  StopModel({required this.stopId, required this.stopName,
      required this.stopSequence});

  factory StopModel.fromJson(Map<String, dynamic> j) => StopModel(
    stopId:       j['stopId'],
    stopName:     j['stopName']     ?? '',
    stopSequence: j['stopSequence'] ?? 0,
  );
}


class ConductorDashboardModel {
  final String         conductorName;
  final String         employeeId;
  final int            staffId;
  final RosterModel?   todayRoster;
  final TripModel?     activeTrip;
  final int            dutyDaysThisMonth;
  final int            ticketsIssuedThisMonth;
  final double         totalFareThisMonth;
  final double         welfareThisMonth;
  final double         totalWelfareBalance;

  ConductorDashboardModel({
    required this.conductorName,        required this.employeeId,
    required this.staffId,              this.todayRoster,
    this.activeTrip,                    required this.dutyDaysThisMonth,
    required this.ticketsIssuedThisMonth,
    required this.totalFareThisMonth,  required this.welfareThisMonth,
    required this.totalWelfareBalance,
  });

  factory ConductorDashboardModel.fromJson(Map<String, dynamic> j) =>
      ConductorDashboardModel(
    conductorName:           j['conductorName']           ?? '',
    employeeId:              j['employeeId']              ?? '',
    staffId:                 j['staffId'],
    todayRoster:  j['todayRoster'] != null
        ? RosterModel.fromJson(j['todayRoster']) : null,
    activeTrip:   j['activeTrip'] != null
        ? TripModel.fromJson(j['activeTrip']) : null,
    dutyDaysThisMonth:       (j['dutyDaysThisMonth']       as num?)?.toInt()    ?? 0,
    ticketsIssuedThisMonth:  (j['ticketsIssuedThisMonth']  as num?)?.toInt()    ?? 0,
    totalFareThisMonth:      (j['totalFareThisMonth']      as num?)?.toDouble() ?? 0,
    welfareThisMonth:        (j['welfareThisMonth']        as num?)?.toDouble() ?? 0,
    totalWelfareBalance:     (j['totalWelfareBalance']     as num?)?.toDouble() ?? 0,
  );
}


class ConductorWelfareModel {
  final int    month;
  final int    year;
  final double welfareAmount;
  final double cumulativeBalance;
  final String busNumber;

  ConductorWelfareModel({
    required this.month,   required this.year,
    required this.welfareAmount, required this.cumulativeBalance,
    required this.busNumber,
  });

  factory ConductorWelfareModel.fromJson(Map<String, dynamic> j) =>
      ConductorWelfareModel(
    month:             (j['month']             as num?)?.toInt()    ?? 0,
    year:              (j['year']              as num?)?.toInt()    ?? 0,
    welfareAmount:     (j['welfareAmount']     as num?)?.toDouble() ?? 0,
    cumulativeBalance: (j['cumulativeBalance'] as num?)?.toDouble() ?? 0,
    busNumber:          j['busNumber']                              ?? '',
  );

  static const _months = ['', 'Jan','Feb','Mar','Apr','May','Jun',
                           'Jul','Aug','Sep','Oct','Nov','Dec'];
  String get monthLabel => '${_months[month]} $year';
}
