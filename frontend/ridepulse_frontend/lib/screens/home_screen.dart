import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/**
 * Home Screen
 * Displayed after successful login
 */
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Welcome, ${user?.fullName ?? 'User'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Role'),
                        subtitle: Text(user?.role ?? 'N/A'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Account Status'),
                        subtitle: Text(user?.isActive == true ? 'Active' : 'Inactive'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              const Text(
                '✅ Successfully connected to backend!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              const Text(
                'Your Flutter app is now communicating\nwith Spring Boot backend using JWT authentication.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}