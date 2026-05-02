// ============================================================
// core/router/app_router.dart
// GoRouter with role-based auth guards — ALL modules wired
// OOP Polymorphism: redirect logic branches per user role
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../layouts/bus_owner_shell.dart';
import '../layouts/authority_shell.dart';

// Auth
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// Passenger
import '../../features/passenger/screens/passenger_home_screen.dart';
import '../../features/passenger/screens/passenger_search_screen.dart';
import '../../features/passenger/screens/passenger_route_detail_screen.dart';
import '../../features/passenger/screens/passenger_bus_live_screen.dart';
import '../../features/passenger/screens/passenger_crowd_prediction_screen.dart';
import '../../features/passenger/screens/passenger_complaint_list_screen.dart';
import '../../features/passenger/screens/passenger_complaint_submit_screen.dart';
import '../../features/passenger/screens/passenger_complaint_detail_screen.dart';

// Driver
import '../../features/driver/screens/driver_home_screen.dart';
import '../../features/driver/screens/driver_trip_screen.dart';
import '../../features/driver/screens/driver_emergency_screen.dart';
import '../../features/driver/screens/driver_roster_screen.dart';
import '../../features/driver/screens/driver_welfare_screen.dart';
import '../../features/driver/screens/driver_income_screen.dart';

// Conductor
import '../../features/conductor/screens/conductor_home_screen.dart';
import '../../features/conductor/screens/conductor_trip_screen.dart';
import '../../features/conductor/screens/conductor_issue_ticket_screen.dart';
import '../../features/conductor/screens/conductor_roster_screen.dart';
import '../../features/conductor/screens/conductor_welfare_screen.dart';

// Bus Owner
import '../../features/bus_owner/screens/dashboard_screen.dart';
import '../../features/bus_owner/screens/bus_management_screen.dart';
import '../../features/bus_owner/screens/staff_list_screen.dart';
import '../../features/bus_owner/screens/register_staff_screen.dart';
import '../../features/bus_owner/screens/staff_profile_screen.dart';
import '../../features/bus_owner/screens/revenue_screen.dart';
import '../../features/bus_owner/screens/welfare_screen.dart';
import '../../features/bus_owner/screens/live_map_screen.dart';
import '../../features/bus_owner/screens/bus_owner_complaints_screen.dart';
import '../../features/bus_owner/screens/bus_owner_roster_screen.dart';

// Authority
import '../../features/authority/screens/authority_dashboard_screen.dart';
import '../../features/authority/screens/authority_complaint_list_screen.dart';
import '../../features/authority/screens/authority_complaint_detail_screen.dart';
import '../../features/authority/screens/authority_buses_screen.dart';
import '../../features/authority/screens/authority_staff_screen.dart';
import '../../features/authority/screens/authority_owners_screen.dart';
import '../../features/authority/screens/authority_fare_screen.dart';
import '../../features/authority/screens/authority_roster_screen.dart';
import '../../features/authority/screens/authority_route_optimization_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth     = ref.read(authProvider);
      final loggedIn = auth.isLoggedIn;
      final role     = auth.role ?? '';
      final loc      = state.matchedLocation;

      const publicPaths = [
        '/login', '/register/passenger',
        '/register/bus-owner', '/register/authority',
      ];
      final isPublic = publicPaths.any((p) => loc.startsWith(p));

      if (!loggedIn && !isPublic) return '/login';

      if (loggedIn && isPublic) {
        return switch (role) {
          'bus_owner'  => '/bus-owner/dashboard',
          'driver'     => '/driver/home',
          'conductor'  => '/conductor/home',
          'passenger'  => '/passenger/home',
          'authority'  => '/authority/dashboard',
          _            => '/login',
        };
      }

      if (loc.startsWith('/bus-owner') && role != 'bus_owner')  return '/login';
      if (loc.startsWith('/authority') && role != 'authority')  return '/login';
      if (loc.startsWith('/driver')    && role != 'driver')     return '/login';
      if (loc.startsWith('/conductor') && role != 'conductor')  return '/login';
      if (loc.startsWith('/passenger') && role != 'passenger')  return '/login';

      return null;
    },

    routes: [
      // ── Public ─────────────────────────────────────────────
      GoRoute(path: '/login',
          builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register/passenger',
          builder: (context, state) => const RegisterScreen(type: 'passenger')),
      GoRoute(path: '/register/bus-owner',
          builder: (context, state) => const RegisterScreen(type: 'bus_owner')),
      GoRoute(path: '/register/authority',
          builder: (context, state) => const RegisterScreen(type: 'authority')),

      // ── Passenger ──────────────────────────────────────────
      GoRoute(path: '/passenger/home',
          builder: (context, state) => const PassengerHomeScreen()),
      GoRoute(path: '/passenger/search',
          builder: (context, state) => const PassengerSearchScreen()),
      GoRoute(path: '/passenger/routes/:routeId',
          builder: (context, state) => PassengerRouteDetailScreen(
              routeId: int.parse(state.pathParameters['routeId']!))),
      GoRoute(path: '/passenger/buses/:busId/live',
          builder: (context, state) => PassengerBusLiveScreen(
              busId: int.parse(state.pathParameters['busId']!))),
      GoRoute(path: '/passenger/routes/:routeId/prediction',
          builder: (context, state) => PassengerCrowdPredictionScreen(
              routeId: int.parse(state.pathParameters['routeId']!))),
      GoRoute(path: '/passenger/complaints',
          builder: (context, state) => const PassengerComplaintListScreen()),
      GoRoute(path: '/passenger/complaints/submit',
          builder: (context, state) => const PassengerComplaintSubmitScreen()),
      GoRoute(path: '/passenger/complaints/:id',
          builder: (context, state) => PassengerComplaintDetailScreen(
              complaintId: int.parse(state.pathParameters['id']!))),

      // ── Driver ─────────────────────────────────────────────
      GoRoute(path: '/driver/home',
          builder: (context, state) => const DriverHomeScreen()),
      GoRoute(path: '/driver/trip',
          builder: (context, state) => const DriverTripScreen()),
      GoRoute(path: '/driver/emergency',
          builder: (context, state) => const DriverEmergencyScreen()),
      GoRoute(path: '/driver/roster',
          builder: (context, state) => const DriverRosterScreen()),
      GoRoute(path: '/driver/welfare',
          builder: (context, state) => const DriverWelfareScreen()),
      GoRoute(path: '/driver/income',
          builder: (context, state) => const DriverIncomeScreen()),

      // ── Conductor ──────────────────────────────────────────
      GoRoute(path: '/conductor/home',
          builder: (context, state) => const ConductorHomeScreen()),
      GoRoute(path: '/conductor/trip',
          builder: (context, state) => const ConductorTripScreen()),
      GoRoute(path: '/conductor/ticket/issue',
          builder: (context, state) => const ConductorIssueTicketScreen()),
      GoRoute(path: '/conductor/roster',
          builder: (context, state) => const ConductorRosterScreen()),
      GoRoute(path: '/conductor/welfare',
          builder: (context, state) => const ConductorWelfareScreen()),

      // ── Bus Owner (sidebar shell) ───────────────────────────
      ShellRoute(
        builder: (context, state, child) => BusOwnerShell(child: child),
        routes: [
          GoRoute(path: '/bus-owner/dashboard',
              builder: (context, state) => const BusOwnerDashboardScreen()),
          GoRoute(path: '/bus-owner/buses',
              builder: (context, state) => const BusManagementScreen()),
          GoRoute(path: '/bus-owner/staff',
              builder: (context, state) => const StaffListScreen()),
          GoRoute(path: '/bus-owner/staff/register',
              builder: (context, state) => const RegisterStaffScreen()),
          GoRoute(path: '/bus-owner/staff/:id',
              builder: (context, state) => StaffProfileScreen(
                  staffId: int.parse(state.pathParameters['id']!))),
          GoRoute(path: '/bus-owner/roster',
              builder: (context, state) => const BusOwnerRosterScreen()),
          GoRoute(path: '/bus-owner/revenue',
              builder: (context, state) => const RevenueScreen()),
          GoRoute(path: '/bus-owner/welfare',
              builder: (context, state) => const WelfareScreen()),
          GoRoute(path: '/bus-owner/live-map',
              builder: (context, state) => const LiveMapScreen()),
          GoRoute(path: '/bus-owner/complaints',
              builder: (context, state) => const BusOwnerComplaintsScreen()),
        ],
      ),

      // ── Authority (sidebar shell) ───────────────────────────
      ShellRoute(
        builder: (context, state, child) => AuthorityShell(child: child),
        routes: [
          GoRoute(path: '/authority/dashboard',
              builder: (context, state) => const AuthorityDashboardScreen()),
          GoRoute(path: '/authority/complaints',
              builder: (context, state) => const AuthorityComplaintListScreen()),
          GoRoute(path: '/authority/complaints/:id',
              builder: (context, state) => AuthorityComplaintDetailScreen(
                  complaintId: int.parse(state.pathParameters['id']!))),
          GoRoute(path: '/authority/buses',
              builder: (context, state) => const AuthorityBusesScreen()),
          GoRoute(path: '/authority/staff',
              builder: (context, state) => const AuthorityStaffScreen()),
          GoRoute(path: '/authority/owners',
              builder: (context, state) => const AuthorityOwnersScreen()),
          GoRoute(path: '/authority/fares',
              builder: (context, state) => const AuthorityFareScreen()),
          GoRoute(path: '/authority/roster',
              builder: (context, state) => const AuthorityRosterScreen()),
          GoRoute(path: '/authority/route-optimization',
              builder: (context, state) =>
                  const AuthorityRouteOptimizationScreen()),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
