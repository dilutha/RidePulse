
class RouteSearchResult {
  final int     routeId;
  final String  routeNumber;
  final String  routeName;
  final String  startLocation;
  final String  endLocation;
  final double? totalDistanceKm;
  final double  baseFare;
  final int     activeBusCount;

  RouteSearchResult({
    required this.routeId,      required this.routeNumber,
    required this.routeName,    required this.startLocation,
    required this.endLocation,  this.totalDistanceKm,
    required this.baseFare,     required this.activeBusCount,
  });

  factory RouteSearchResult.fromJson(Map<String, dynamic> j) =>
      RouteSearchResult(
    routeId:        j['routeId'],
    routeNumber:    j['routeNumber']    ?? '',
    routeName:      j['routeName']      ?? '',
    startLocation:  j['startLocation']  ?? '',
    endLocation:    j['endLocation']    ?? '',
    totalDistanceKm:(j['totalDistanceKm'] as num?)?.toDouble(),
    baseFare:       (j['baseFare']      as num?)?.toDouble() ?? 0,
    activeBusCount: (j['activeBusCount']as num?)?.toInt()   ?? 0,
  );

  // Encapsulation: display helpers on the model
  bool get hasBuses => activeBusCount > 0;
  String get displayDistance => totalDistanceKm != null
      ? '${totalDistanceKm!.toStringAsFixed(1)} km' : 'N/A';
}


class ActiveBus {
  final int     busId;
  final String  busNumber;
  final int     capacity;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final String  lastUpdated;
  final int     passengerCount;
  final double  capacityPercentage;
  final String  crowdCategory;  // low | medium | high
  final int?    tripId;
  final String? tripStartedAt;

  ActiveBus({
    required this.busId,          required this.busNumber,
    required this.capacity,       this.latitude,
    this.longitude,               this.speedKmh,
    required this.lastUpdated,    required this.passengerCount,
    required this.capacityPercentage,
    required this.crowdCategory,  this.tripId,
    this.tripStartedAt,
  });

  factory ActiveBus.fromJson(Map<String, dynamic> j) => ActiveBus(
    busId:               j['busId'],
    busNumber:           j['busNumber']           ?? '',
    capacity:            (j['capacity']           as num?)?.toInt()    ?? 0,
    latitude:            (j['latitude']           as num?)?.toDouble(),
    longitude:           (j['longitude']          as num?)?.toDouble(),
    speedKmh:            (j['speedKmh']           as num?)?.toDouble(),
    lastUpdated:          j['lastUpdated']         ?? 'Unknown',
    passengerCount:      (j['passengerCount']      as num?)?.toInt()    ?? 0,
    capacityPercentage:  (j['capacityPercentage']  as num?)?.toDouble() ?? 0,
    crowdCategory:        j['crowdCategory']        ?? 'unknown',
    tripId:              (j['tripId']              as num?)?.toInt(),
    tripStartedAt:        j['tripStartedAt'],
  );

  bool get hasLocation => latitude != null && longitude != null;

  // Polymorphism: same field, different semantic meaning by value
  bool get isCrowdLow    => crowdCategory == 'low';
  bool get isCrowdMedium => crowdCategory == 'medium';
  bool get isCrowdHigh   => crowdCategory == 'high';
}


class BusLiveDetail {
  final int       busId;
  final String    busNumber;
  final String    registrationNumber;
  final int       capacity;
  final int?      routeId;
  final String    routeName;
  final String    routeNumber;
  final List<Map<String, dynamic>> stops;  // {stopId, stopName, stopSequence}
  final double?   latitude;
  final double?   longitude;
  final double?   speedKmh;
  final double?   heading;
  final String    lastUpdated;
  final int       passengerCount;
  final double    capacityPercentage;
  final String    crowdCategory;
  final int?      tripId;
  final String?   tripStartedAt;

  BusLiveDetail({
    required this.busId,           required this.busNumber,
    required this.registrationNumber,
    required this.capacity,        this.routeId,
    required this.routeName,       required this.routeNumber,
    required this.stops,           this.latitude,
    this.longitude,                this.speedKmh,
    this.heading,                  required this.lastUpdated,
    required this.passengerCount,  required this.capacityPercentage,
    required this.crowdCategory,   this.tripId,
    this.tripStartedAt,
  });

  factory BusLiveDetail.fromJson(Map<String, dynamic> j) => BusLiveDetail(
    busId:               j['busId'],
    busNumber:           j['busNumber']           ?? '',
    registrationNumber:  j['registrationNumber']  ?? '',
    capacity:            (j['capacity']           as num?)?.toInt()    ?? 0,
    routeId:             (j['routeId']            as num?)?.toInt(),
    routeName:            j['routeName']           ?? '',
    routeNumber:          j['routeNumber']         ?? '',
    stops:      (j['stops'] as List<dynamic>?)
        ?.map((s) => Map<String, dynamic>.from(s as Map)).toList() ?? [],
    latitude:            (j['latitude']           as num?)?.toDouble(),
    longitude:           (j['longitude']          as num?)?.toDouble(),
    speedKmh:            (j['speedKmh']           as num?)?.toDouble(),
    heading:             (j['heading']            as num?)?.toDouble(),
    lastUpdated:          j['lastUpdated']         ?? 'Unknown',
    passengerCount:      (j['passengerCount']      as num?)?.toInt()    ?? 0,
    capacityPercentage:  (j['capacityPercentage']  as num?)?.toDouble() ?? 0,
    crowdCategory:        j['crowdCategory']        ?? 'unknown',
    tripId:              (j['tripId']              as num?)?.toInt(),
    tripStartedAt:        j['tripStartedAt'],
  );

  bool get hasLocation => latitude != null && longitude != null;
  bool get isOnTrip    => tripId != null;
}


class CrowdPredictionSlot {
  final String  timeSlot;
  final double  predictedPercentage;
  final String  predictedCategory;
  final double? confidenceScore;
  final bool    isAvailable;
  final String? message;

  CrowdPredictionSlot({
    required this.timeSlot,
    required this.predictedPercentage,
    required this.predictedCategory,
    this.confidenceScore,
    required this.isAvailable,
    this.message,
  });

  factory CrowdPredictionSlot.fromJson(Map<String, dynamic> j) =>
      CrowdPredictionSlot(
    timeSlot:             j['timeSlot'] ?? j['time_slot'] ?? '',
    predictedPercentage:  ((j['predictedPercentage'] ??
            j['predicted_percentage']) as num?)?.toDouble() ?? 0,
    predictedCategory:    j['predictedCategory'] ??
            j['predicted_category'] ?? 'unknown',
    confidenceScore:      ((j['confidenceScore'] ??
            j['confidence_score']) as num?)?.toDouble(),
    isAvailable:          j['isAvailable'] ?? j['is_available'] ?? false,
    message:              j['message'],
  );
}


class RoutePredictionSchedule {
  final int    routeId;
  final String routeName;
  final String date;
  final bool   hasData;
  final List<CrowdPredictionSlot> slots;

  RoutePredictionSchedule({
    required this.routeId,  required this.routeName,
    required this.date,     required this.hasData,
    required this.slots,
  });

  factory RoutePredictionSchedule.fromJson(Map<String, dynamic> j) =>
      RoutePredictionSchedule(
    routeId:   j['routeId'],
    routeName:  j['routeName'] ?? '',
    date:       j['date']      ?? '',
    hasData:    j['hasData']   ?? false,
    slots: (j['slots'] as List<dynamic>?)
        ?.map((s) => CrowdPredictionSlot.fromJson(
            Map<String, dynamic>.from(s as Map)))
        .toList() ?? [],
  );
}
