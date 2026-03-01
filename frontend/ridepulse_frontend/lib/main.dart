import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/passenger/passenger_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';
import 'screens/conductor/conductor_home_screen.dart';
import 'screens/bus_owner/bus_owner_home_screen.dart';
import 'screens/authority/authority_home_screen.dart';

void main() {
  runApp(const MyApp());
}

/**
 * Main Application
 * 
 * POLYMORPHISM (OOP Concept):
 * Different home screens for different user roles
 */
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'Ride Pulse',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Handle all routes
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case '/home':
              return MaterialPageRoute(builder: (_) => const RoleBasedHome());
            default:
              // Handle feature routes (to be implemented)
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Coming Soon')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.construction,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Feature Under Development',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Route: ${settings.name}'),
                      ],
                    ),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

/**
 * Role-Based Home Screen Router
 * 
 * POLYMORPHISM:
 * Returns different home screen based on user role
 */
class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (user == null) {
      return const LoginScreen();
    }
    
    // Return appropriate home screen based on role
    switch (user.role.toUpperCase()) {
      case 'PASSENGER':
        return const PassengerHomeScreen();
      case 'DRIVER':
        return const DriverHomeScreen();
      case 'CONDUCTOR':
        return const ConductorHomeScreen();
      case 'BUS_OWNER':
        return const BusOwnerHomeScreen();
      case 'AUTHORITY':
        return const AuthorityHomeScreen();
      default:
        return const PassengerHomeScreen();
    }
  }
}

/**
 * Splash Screen
 * Shows loading while checking authentication
 */
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ride Pulse',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Digital Ticketing System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}