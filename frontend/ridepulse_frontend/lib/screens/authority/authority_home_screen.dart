import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/feature_card.dart';

/**
 * Authority Home Screen
 * 
 * Features:
 * - Monitoring
 * - Forecasting
 * - Complaint analytics
 * - Route optimization
 * - Emergency control
 */
class AuthorityHomeScreen extends StatelessWidget {
  const AuthorityHomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse - Transport Authority'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications - Coming Soon')),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
                    'Transport Authority',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Administrator',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // System Stats
                  Column(
                    children: [
                      Row(
                        children: [
                          _buildStatCard('Active Buses', '156', Icons.directions_bus),
                          const SizedBox(width: 12),
                          _buildStatCard('Routes', '42', Icons.route),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard('Passengers', '12.5K', Icons.people),
                          const SizedBox(width: 12),
                          _buildStatCard('Alerts', '3', Icons.warning),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Emergency Alerts Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Active Emergencies',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.emergency, color: Colors.white),
                        ),
                        title: const Text('Bus NA-1234 - Breakdown'),
                        subtitle: const Text('Colombo Road, 5 mins ago'),
                        trailing: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Respond'),
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
                    'System Management',
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
                      // Real-time Monitoring
                      FeatureCard(
                        icon: Icons.monitor,
                        title: 'Monitoring',
                        subtitle: 'Real-time tracking',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/monitoring');
                        },
                        badge: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // Demand Forecasting
                      FeatureCard(
                        icon: Icons.trending_up,
                        title: 'Forecasting',
                        subtitle: 'AI predictions',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/forecasting');
                        },
                      ),
                      
                      // Complaint Analytics
                      FeatureCard(
                        icon: Icons.analytics,
                        title: 'Complaints',
                        subtitle: 'Analytics & trends',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/complaints');
                        },
                      ),
                      
                      // Route Optimization
                      FeatureCard(
                        icon: Icons.route,
                        title: 'Route Optimization',
                        subtitle: 'AI-driven allocation',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/route-optimization');
                        },
                      ),
                      
                      // Emergency Control
                      FeatureCard(
                        icon: Icons.emergency,
                        title: 'Emergency Control',
                        subtitle: 'Incident management',
                        color: Colors.red,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/emergency');
                        },
                      ),
                      
                      // Reports
                      FeatureCard(
                        icon: Icons.description,
                        title: 'Reports',
                        subtitle: 'Generate reports',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pushNamed(context, '/authority/reports');
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
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}