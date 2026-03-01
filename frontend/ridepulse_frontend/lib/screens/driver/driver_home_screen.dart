import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/feature_card.dart';

/**
 * Driver Home Screen
 * 
 * Features:
 * - Schedule
 * - Welfare tracking
 * - Emergency alert
 * - Route updates
 */
class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse - Driver'),
        elevation: 0,
        actions: [
          // Quick Emergency Button
          IconButton(
            icon: const Icon(Icons.warning, color: Colors.red),
            onPressed: () {
              _showEmergencyDialog(context);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good day,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Driver',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'On Duty',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Today's Schedule Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Today\'s Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.access_time),
                        title: Text('Morning Shift'),
                        subtitle: Text('6:00 AM - 2:00 PM'),
                        trailing: Chip(
                          label: Text('Active'),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Features Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      // Schedule
                      FeatureCard(
                        icon: Icons.schedule,
                        title: 'My Schedule',
                        subtitle: 'View duty roster',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/driver/schedule');
                        },
                      ),
                      
                      // Welfare Tracking
                      FeatureCard(
                        icon: Icons.health_and_safety,
                        title: 'Welfare',
                        subtitle: 'Hours & benefits',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/driver/welfare');
                        },
                      ),
                      
                      // Emergency Alert
                      FeatureCard(
                        icon: Icons.emergency,
                        title: 'Emergency',
                        subtitle: 'Send alert',
                        color: Colors.red,
                        onTap: () {
                          _showEmergencyDialog(context);
                        },
                      ),
                      
                      // Route Updates
                      FeatureCard(
                        icon: Icons.route,
                        title: 'Route Updates',
                        subtitle: 'Current route info',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/driver/route-updates');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Alert'),
          ],
        ),
        content: const Text(
          'Are you sure you want to send an emergency alert? '
          'This will notify the transport authority immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}