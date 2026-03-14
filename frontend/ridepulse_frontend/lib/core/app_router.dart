import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

import '../screens/passenger/passenger_home_screen.dart';
import '../screens/passenger/my_complaints_screen.dart';
import '../screens/passenger/submit_complaint_screen.dart';

import '../screens/driver/driver_home_screen.dart';
import '../screens/driver/welfare_screen.dart';

import '../screens/conductor/conductor_home_screen.dart';

import '../screens/bus_owner/bus_owner_home_screen.dart';
import '../screens/bus_owner/manage_welfare_screen.dart';

import '../screens/authority/authority_home_screen.dart';
import '../screens/authority/manage_complaints_screen.dart';

class AppRouter {

  static GoRouter createRouter(AuthProvider authProvider) {

    return GoRouter(

      initialLocation: '/login',

      refreshListenable: authProvider,

      redirect: (context, state) {

        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.uri.path == '/login';
        final isRegister = state.uri.path == '/register';

        /// USER NOT LOGGED IN
        if (!isLoggedIn) {

          if (isLoggingIn || isRegister) {
            return null;
          }

          return '/login';
        }

        /// USER LOGGED IN → REDIRECT TO ROLE HOME
        if (isLoggingIn) {

          final role = authProvider.currentUser?.role;

          switch (role) {
            case 'PASSENGER':
              return '/passenger/home';

            case 'DRIVER':
              return '/driver/home';

            case 'CONDUCTOR':
              return '/conductor/home';

            case 'BUS_OWNER':
              return '/bus_owner/home';

            case 'AUTHORITY':
              return '/authority/home';
          }
        }

        return null;
      },

      routes: [

        /// LOGIN
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        /// REGISTER
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        /// PASSENGER
        GoRoute(
          path: '/passenger/home',
          builder: (context, state) => const PassengerHomeScreen(),
        ),

        GoRoute(
          path: '/passenger/my_complaints',
          builder: (context, state) => const MyComplaintsScreen(),
        ),

        GoRoute(
          path: '/passenger/submit_complaint',
          builder: (context, state) => const SubmitComplaintScreen(),
        ),

        /// DRIVER
        GoRoute(
          path: '/driver/home',
          builder: (context, state) => const DriverHomeScreen(),
        ),

        GoRoute(
          path: '/driver/welfare',
          builder: (context, state) => const WelfareScreen(),
        ),

        /// CONDUCTOR
        GoRoute(
          path: '/conductor/home',
          builder: (context, state) => const ConductorHomeScreen(),
        ),

        /// BUS OWNER
        GoRoute(
          path: '/bus_owner/home',
          builder: (context, state) => const BusOwnerHomeScreen(),
        ),

        GoRoute(
          path: '/bus_owner/manage_welfare',
          builder: (context, state) => const ManageWelfareScreen(),
        ),

        /// AUTHORITY
        GoRoute(
          path: '/authority/home',
          builder: (context, state) => const AuthorityHomeScreen(),
        ),

        GoRoute(
          path: '/authority/manage_complaints',
          builder: (context, state) => const ManageComplaintsScreen(),
        ),
      ],
    );
  }
}