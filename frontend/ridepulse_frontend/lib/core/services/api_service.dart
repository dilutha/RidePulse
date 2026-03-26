// ============================================================
// core/services/api_service.dart
// OOP Encapsulation: all authenticated API calls + Riverpod providers
// ============================================================
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../models/bus_models.dart';
import '../models/complaint_models.dart';
import '../models/conductor_models.dart';
import '../models/driver_models.dart';
import '../models/passenger_models.dart';

const String _base = 'http://localhost:8080/api/v1';

// ── Provider declarations ────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Bus owner providers
final busListProvider = FutureProvider.autoDispose<List<BusModel>>((ref) async {
  return ref.read(apiServiceProvider).getBuses();
});

final routeDropdownProvider = FutureProvider.autoDispose<List<RouteModel>>((ref) async {
  return ref.read(apiServiceProvider).getRoutes();
});

final busServiceProvider = Provider<ApiService>((ref) => ApiService());

final busLocationsProvider = FutureProvider.autoDispose<List<BusLocationModel>>((ref) async {
  return ref.read(apiServiceProvider).getLiveBusLocations();
});

// Staff providers
// OOP Polymorphism: same provider factory works for both driver and conductor
final staffListProvider = FutureProvider.autoDispose
    .family<List<StaffModel>, String>((ref, staffType) async {
  return ref.read(apiServiceProvider).getStaff(staffType: staffType);
});

final staffServiceProvider = Provider<ApiService>((ref) => ApiService());

// Revenue providers
final monthlyRevenueProvider = FutureProvider.autoDispose
    .family<List<MonthlyRevenueModel>, ({int month, int year})>(
        (ref, params) async {
  return ref.read(apiServiceProvider)
      .getMonthlyRevenue(month: params.month, year: params.year);
});

// Welfare provider
final welfareProvider = FutureProvider.autoDispose
    .family<List<StaffModel>, ({int month, int year})>(
        (ref, params) async {
  return ref.read(apiServiceProvider)
      .getWelfareSummary(month: params.month, year: params.year);
});

// Complaint providers
final myComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintSummary>>((ref) async {
  return ref.read(apiServiceProvider).getMyComplaints();
});

final authorityComplaintsProvider = FutureProvider.autoDispose
    .family<List<ComplaintSummary>, ({String? status, String? category})>(
        (ref, params) async {
  return ref.read(apiServiceProvider)
      .getAuthorityComplaints(status: params.status, category: params.category);
});

final complaintStatsProvider =
    FutureProvider.autoDispose<ComplaintStats>((ref) async {
  return ref.read(apiServiceProvider).getComplaintStats();
});

// ── Conductor providers ───────────────────────────────────────
final conductorDashboardProvider =
    FutureProvider.autoDispose<ConductorDashboardModel>((ref) async {
  return ref.read(apiServiceProvider).getConductorDashboard();
});

final conductorRosterTodayProvider =
    FutureProvider.autoDispose<List<RosterModel>>((ref) async {
  return ref.read(apiServiceProvider).getConductorTodayRoster();
});

final routeStopsProvider = FutureProvider.autoDispose
    .family<List<StopModel>, int>((ref, routeId) async {
  return ref.read(apiServiceProvider).getRouteStops(routeId);
});

final tripTicketsProvider = FutureProvider.autoDispose
    .family<List<TicketModel>, int>((ref, tripId) async {
  return ref.read(apiServiceProvider).getTripTickets(tripId);
});

final conductorWelfareProvider =
    FutureProvider.autoDispose<List<ConductorWelfareModel>>((ref) async {
  return ref.read(apiServiceProvider).getConductorWelfare();
});

// ── Passenger providers ───────────────────────────────────────
final allRoutesProvider =
    FutureProvider.autoDispose<List<RouteSearchResult>>((ref) async {
  return ref.read(apiServiceProvider).getPassengerRoutes();
});

final routeSearchProvider = FutureProvider.autoDispose
    .family<List<RouteSearchResult>, String>((ref, query) async {
  return ref.read(apiServiceProvider).searchRoutes(query);
});

final activeBusesProvider = FutureProvider.autoDispose
    .family<List<ActiveBus>, int>((ref, routeId) async {
  return ref.read(apiServiceProvider).getActiveBusesOnRoute(routeId);
});

final busLiveDetailProvider = FutureProvider.autoDispose
    .family<BusLiveDetail, int>((ref, busId) async {
  return ref.read(apiServiceProvider).getBusLiveDetail(busId);
});

final crowdPredictionProvider = FutureProvider.autoDispose
    .family<RoutePredictionSchedule, ({int routeId, String date})>(
        (ref, params) async {
  return ref.read(apiServiceProvider)
      .getCrowdPredictions(params.routeId, params.date);
});

// ── Driver providers ──────────────────────────────────────────
final driverDashboardProvider =
    FutureProvider.autoDispose<DriverDashboardModel>((ref) async {
  return ref.read(apiServiceProvider).getDriverDashboard();
});

final driverRosterTodayProvider =
    FutureProvider.autoDispose<List<RosterModel>>((ref) async {
  return ref.read(apiServiceProvider).getDriverTodayRoster();
});

final driverAlertsProvider =
    FutureProvider.autoDispose<List<EmergencyAlertModel>>((ref) async {
  return ref.read(apiServiceProvider).getDriverAlerts();
});

final driverWelfareProvider =
    FutureProvider.autoDispose<List<ConductorWelfareModel>>((ref) async {
  return ref.read(apiServiceProvider).getDriverWelfare();
});

// ── ApiService class ─────────────────────────────────────────

class ApiService {
  Future<Map<String, String>> get _headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$_base$path'),
        headers: await _headers);
    _check(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$_base$path'),
        headers: await _headers, body: jsonEncode(body));
    _check(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(Uri.parse('$_base$path'),
        headers: await _headers, body: jsonEncode(body));
    _check(res);
    return jsonDecode(res.body);
  }

  Future<dynamic> _delete(String path) async {
    final res = await http.delete(Uri.parse('$_base$path'),
        headers: await _headers);
    _check(res);
    return jsonDecode(res.body);
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Error ${res.statusCode}');
    }
  }

  // ── Routes ────────────────────────────────────────────────
  Future<List<RouteModel>> getRoutes() async {
    final data = await _get('/routes') as List;
    return data.map((e) => RouteModel.fromJson(e)).toList();
  }

  // ── Bus Owner — Buses ─────────────────────────────────────
  Future<List<BusModel>> getBuses() async {
    final data = await _get('/bus-owner/buses') as List;
    return data.map((e) => BusModel.fromJson(e)).toList();
  }

  Future<BusModel> addBus({
    required String busNumber,
    required String registrationNumber,
    required int routeId,
    required int capacity,
    String? model,
  }) async {
    final data = await _post('/bus-owner/buses', {
      'busNumber': busNumber,
      'registrationNumber': registrationNumber,
      'routeId': routeId,
      'capacity': capacity,
      'model': model,
    });
    return BusModel.fromJson(data);
  }

  Future<void> deleteBus(int busId) async {
    await _delete('/bus-owner/buses/$busId');
  }

  Future<BusModel> updateBusRoute(int busId, int routeId) async {
    final data = await _patch(
        '/bus-owner/buses/route', {'busId': busId, 'routeId': routeId});
    return BusModel.fromJson(data);
  }

  // ── Bus Owner — Staff ─────────────────────────────────────
  Future<List<StaffModel>> getStaff({String? staffType}) async {
    final data = await _get('/bus-owner/staff') as List;
    final all = data.map((e) => StaffModel.fromJson(e)).toList();
    if (staffType == null) return all;
    return all.where((s) => s.staffType == staffType).toList();
  }

  Future<void> toggleStaffStatus(int staffId, bool isActive) async {
    await _patch('/bus-owner/staff/toggle-status',
        {'staffId': staffId, 'isActive': isActive});
  }

  Future<void> updateSalary(int staffId, double salary) async {
    await _patch('/bus-owner/staff/salary',
        {'staffId': staffId, 'baseSalary': salary});
  }

  Future<void> assignStaffToBus(int staffId, int busId) async {
    await _post('/bus-owner/staff/assign', {
      'staffId': staffId,
      'busId': busId,
      'assignedDate': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  // ── Bus Owner — Revenue ───────────────────────────────────
  Future<List<MonthlyRevenueModel>> getMonthlyRevenue(
      {required int month, required int year}) async {
    final data =
        await _get('/bus-owner/revenue/monthly?month=$month&year=$year') as List;
    return data.map((e) => MonthlyRevenueModel.fromJson(e)).toList();
  }

  Future<void> recordFuelExpense(
      {required int busId,
      required String date,
      required double amount}) async {
    await _post('/bus-owner/revenue/fuel',
        {'busId': busId, 'expenseDate': date, 'fuelAmount': amount});
  }

  Future<void> setMaintenanceConfig(int busId, double amount) async {
    await _patch('/bus-owner/revenue/maintenance-config',
        {'busId': busId, 'monthlyAmount': amount});
  }

  Future<List<StaffModel>> getWelfareSummary(
      {required int month, required int year}) async {
    final data = await _get(
        '/bus-owner/revenue/welfare?month=$month&year=$year') as List;
    return data.map((e) => StaffModel.fromJson(e)).toList();
  }

  // ── Bus Owner — Dashboard / Map ───────────────────────────
  Future<List<BusLocationModel>> getLiveBusLocations() async {
    final data =
        await _get('/bus-owner/dashboard/live-locations') as List;
    return data.map((e) => BusLocationModel.fromJson(e)).toList();
  }

  Future<List<ComplaintSummary>> getBusOwnerComplaints(
      {String status = 'all'}) async {
    final data =
        await _get('/bus-owner/dashboard/complaints?status=$status') as List;
    return data.map((e) => ComplaintSummary.fromJson(e)).toList();
  }

  // ── Passenger — Complaints ────────────────────────────────
  Future<ComplaintDetail> submitComplaint({
    int? busId,
    int? tripId,
    required String category,
    required String description,
    String? photoUrl,
  }) async {
    final data = await _post('/complaints', {
      'busId': busId,
      'tripId': tripId,
      'category': category,
      'description': description,
      'photoUrl': photoUrl,
    });
    return ComplaintDetail.fromJson(data);
  }

  Future<List<ComplaintSummary>> getMyComplaints() async {
    final data = await _get('/complaints/my') as List;
    return data.map((e) => ComplaintSummary.fromJson(e)).toList();
  }

  Future<ComplaintDetail> getComplaintDetail(int id) async {
    final data = await _get('/complaints/$id');
    return ComplaintDetail.fromJson(data);
  }

  // ── Authority — Complaints ────────────────────────────────
  Future<List<ComplaintSummary>> getAuthorityComplaints(
      {String? status, String? category}) async {
    var path = '/authority/complaints';
    final params = <String>[];
    if (status   != null) params.add('status=$status');
    if (category != null) params.add('category=$category');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    final data = await _get(path) as List;
    return data.map((e) => ComplaintSummary.fromJson(e)).toList();
  }

  Future<ComplaintStats> getComplaintStats() async {
    final data = await _get('/authority/complaints/stats');
    return ComplaintStats.fromJson(data);
  }

  Future<ComplaintDetail> makeComplaintDecision({
    required int complaintId,
    required String action,
    required String resolutionNote,
    required String authorityFeedback,
  }) async {
    final data = await _patch('/authority/complaints/decision', {
      'complaintId':      complaintId,
      'action':           action,
      'resolutionNote':   resolutionNote,
      'authorityFeedback': authorityFeedback,
    });
    return ComplaintDetail.fromJson(data);
  }

  // ── Conductor — Dashboard ──────────────────────────────────
  Future<ConductorDashboardModel> getConductorDashboard() async {
    final data = await _get('/conductor/dashboard');
    return ConductorDashboardModel.fromJson(data);
  }

  // ── Conductor — Roster ─────────────────────────────────────
  Future<List<RosterModel>> getConductorTodayRoster() async {
    final data = await _get('/conductor/roster/today') as List;
    return data.map((e) => RosterModel.fromJson(e)).toList();
  }

  Future<List<RosterModel>> getConductorRosterForDate(String date) async {
    final data = await _get('/conductor/roster?date=$date') as List;
    return data.map((e) => RosterModel.fromJson(e)).toList();
  }

  // ── Conductor — Trip Lifecycle ─────────────────────────────
  Future<TripModel> startTrip(int rosterId) async {
    final data = await _post('/conductor/trip/start', {'rosterId': rosterId});
    return TripModel.fromJson(data);
  }

  Future<TripModel> stopTrip(int tripId) async {
    final data = await _post('/conductor/trip/$tripId/stop', {});
    return TripModel.fromJson(data);
  }

  Future<TripModel> getActiveTrip() async {
    final data = await _get('/conductor/trip/active');
    return TripModel.fromJson(data);
  }

  Future<List<TicketModel>> getTripTickets(int tripId) async {
    final data = await _get('/conductor/trip/$tripId/tickets') as List;
    return data.map((e) => TicketModel.fromJson(e)).toList();
  }

  // ── Conductor — Ticketing ──────────────────────────────────
  Future<TicketModel> issueTicket({
    required int tripId,
    required int routeId,
    required int boardingStopId,
    required int alightingStopId,
    String paymentMethod = 'cash',
    String? passengerUserId,
  }) async {
    final data = await _post('/conductor/ticket/issue', {
      'tripId':          tripId,
      'routeId':         routeId,
      'boardingStopId':  boardingStopId,
      'alightingStopId': alightingStopId,
      'paymentMethod':   paymentMethod,
      'passengerUserId': passengerUserId,
    });
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> validateTicket(String qrCode) async {
    final data = await _post('/conductor/ticket/validate', {'qrCode': qrCode});
    return TicketModel.fromJson(data);
  }

  // ── Conductor — Crowd ──────────────────────────────────────
  Future<TripModel> updateCrowdLevel(int tripId, int count) async {
    final data = await _post('/conductor/crowd/update',
        {'tripId': tripId, 'passengerCount': count});
    return TripModel.fromJson(data);
  }

  // ── Conductor — Route Stops ────────────────────────────────
  Future<List<StopModel>> getRouteStops(int routeId) async {
    final data = await _get('/conductor/route/$routeId/stops') as List;
    return data.map((e) => StopModel.fromJson(e)).toList();
  }

  // ── Conductor — Welfare ────────────────────────────────────
  Future<List<ConductorWelfareModel>> getConductorWelfare() async {
    final data = await _get('/conductor/welfare') as List;
    return data.map((e) => ConductorWelfareModel.fromJson(e)).toList();
  }

  // ── Passenger — Routes ─────────────────────────────────────
  Future<List<RouteSearchResult>> getPassengerRoutes() async {
    final data = await _get('/passenger/routes') as List;
    return data.map((e) => RouteSearchResult.fromJson(e)).toList();
  }

  Future<List<RouteSearchResult>> searchRoutes(String query) async {
    final path = query.trim().isEmpty
        ? '/passenger/routes'
        : '/passenger/routes/search?q=${Uri.encodeComponent(query)}';
    final data = await _get(path) as List;
    return data.map((e) => RouteSearchResult.fromJson(e)).toList();
  }

  // ── Passenger — Live Buses ─────────────────────────────────
  Future<List<ActiveBus>> getActiveBusesOnRoute(int routeId) async {
    final data = await _get('/passenger/routes/$routeId/buses') as List;
    return data.map((e) => ActiveBus.fromJson(e)).toList();
  }

  Future<BusLiveDetail> getBusLiveDetail(int busId) async {
    final data = await _get('/passenger/buses/$busId/live');
    return BusLiveDetail.fromJson(data);
  }

  // ── Passenger — Crowd Prediction ───────────────────────────
  Future<RoutePredictionSchedule> getCrowdPredictions(
      int routeId, String date) async {
    final data = await _get(
        '/passenger/routes/$routeId/predictions?date=$date');
    return RoutePredictionSchedule.fromJson(data);
  }

  // ── Authority — Prediction trigger ────────────────────────
  Future<void> generateTodayPredictions({
    String weather      = 'clear',
    double rain         = 0.0,
    String trafficLevel = 'medium',
  }) async {
    await _post('/authority/predictions/generate/today', {
      'weather':      weather,
      'rain':         rain,
      'trafficLevel': trafficLevel,
    });
  }

  // ── Driver — Dashboard ─────────────────────────────────────
  Future<DriverDashboardModel> getDriverDashboard() async {
    final data = await _get('/driver/dashboard');
    return DriverDashboardModel.fromJson(data);
  }

  // ── Driver — Roster ────────────────────────────────────────
  Future<List<RosterModel>> getDriverTodayRoster() async {
    final data = await _get('/driver/roster/today') as List;
    return data.map((e) => RosterModel.fromJson(e)).toList();
  }

  Future<List<RosterModel>> getDriverRosterForDate(String date) async {
    final data = await _get('/driver/roster?date=$date') as List;
    return data.map((e) => RosterModel.fromJson(e)).toList();
  }

  // ── Driver — Trip ──────────────────────────────────────────
  Future<TripModel> driverStartTrip(int rosterId) async {
    final data = await _post('/driver/trip/start', {'rosterId': rosterId});
    return TripModel.fromJson(data);
  }

  Future<TripModel> driverStopTrip(int tripId) async {
    final data = await _post('/driver/trip/$tripId/stop', {});
    return TripModel.fromJson(data);
  }

  // ── Driver — GPS ───────────────────────────────────────────
  Future<void> sendGpsUpdate({
    required int tripId,
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? heading,
  }) async {
    await _post('/driver/gps/update', {
      'tripId':    tripId,
      'latitude':  latitude,
      'longitude': longitude,
      'speedKmh':  speedKmh,
      'heading':   heading,
    });
  }

  // ── Driver — Emergency ─────────────────────────────────────
  Future<EmergencyAlertModel> raiseEmergencyAlert({
    required int    tripId,
    required String alertType,
    String?         description,
    double?         latitude,
    double?         longitude,
  }) async {
    final data = await _post('/driver/emergency/raise', {
      'tripId':      tripId,
      'alertType':   alertType,
      'description': description,
      'latitude':    latitude,
      'longitude':   longitude,
    });
    return EmergencyAlertModel.fromJson(data);
  }

  Future<EmergencyAlertModel> resolveEmergencyAlert(int alertId) async {
    final data = await _post('/driver/emergency/$alertId/resolve', {});
    return EmergencyAlertModel.fromJson(data);
  }

  Future<List<EmergencyAlertModel>> getDriverAlerts() async {
    final data = await _get('/driver/emergency') as List;
    return data.map((e) => EmergencyAlertModel.fromJson(e)).toList();
  }

  // ── Driver — Welfare ───────────────────────────────────────
  Future<List<ConductorWelfareModel>> getDriverWelfare() async {
    final data = await _get('/driver/welfare') as List;
    return data.map((e) => ConductorWelfareModel.fromJson(e)).toList();
  }
}
