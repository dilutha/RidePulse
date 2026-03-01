import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/feature_card.dart';

/**
 * Bus Owner Home Screen
 * 
 * Features:
 * - Revenue report
 * - Tax calculation
 * - Maintenance records
 * - Welfare overview
 */
class BusOwnerHomeScreen extends StatelessWidget {
  const BusOwnerHomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse - Bus Owner'),
        elevation: 0,
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
                    'Welcome,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Bus Owner',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Fleet Overview
                  Row(
                    children: [
                      _buildStatCard('Active Buses', '12', Icons.directions_bus),
                      const SizedBox(width: 12),
                      _buildStatCard('Routes', '5', Icons.route),
                    ],
                  ),
                ],
              ),
            ),
            
            // Revenue Summary Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Today\'s Revenue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Refreshing...')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rs 245,780.00',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '+12.5% from yesterday',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                    'Business Management',
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
                      // Revenue Report
                      FeatureCard(
                        icon: Icons.assessment,
                        title: 'Revenue Reports',
                        subtitle: 'View detailed analytics',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/revenue');
                        },
                      ),
                      
                      // Tax Calculation
                      FeatureCard(
                        icon: Icons.calculate,
                        title: 'Tax Calculation',
                        subtitle: 'Manage tax & costs',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/tax');
                        },
                      ),
                      
                      // Maintenance Records
                      FeatureCard(
                        icon: Icons.build,
                        title: 'Maintenance',
                        subtitle: 'Service history',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/maintenance');
                        },
                      ),
                      
                      // Welfare Overview
                      FeatureCard(
                        icon: Icons.people,
                        title: 'Staff Welfare',
                        subtitle: 'Employee benefits',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/welfare');
                        },
                      ),
                      
                      // My Buses
                      FeatureCard(
                        icon: Icons.directions_bus,
                        title: 'My Buses',
                        subtitle: 'Manage fleet',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/buses');
                        },
                      ),
                      
                      // Performance
                      FeatureCard(
                        icon: Icons.show_chart,
                        title: 'Performance',
                        subtitle: 'Analytics dashboard',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pushNamed(context, '/bus-owner/performance');
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
  
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}