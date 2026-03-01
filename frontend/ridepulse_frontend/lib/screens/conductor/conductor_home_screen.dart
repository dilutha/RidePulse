import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/feature_card.dart';

/**
 * Conductor Home Screen
 * 
 * Features:
 * - Issue ticket
 * - Verify ticket
 * - GPS update
 * - Emergency alert
 * - Schedule
 * - Welfare
 */
class ConductorHomeScreen extends StatelessWidget {
  const ConductorHomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse - Conductor'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/conductor/scan-ticket');
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
                    'Welcome,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.fullName ?? 'Conductor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Today's Stats
                  Row(
                    children: [
                      _buildStatCard('Tickets Issued', '45', Icons.confirmation_number),
                      const SizedBox(width: 12),
                      _buildStatCard('Revenue', 'Rs 15,240', Icons.payments),
                    ],
                  ),
                ],
              ),
            ),
            
            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/conductor/issue-ticket');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Issue Ticket'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/conductor/scan-ticket');
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Ticket'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Features Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Features',
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
                      // Issue Ticket
                      FeatureCard(
                        icon: Icons.confirmation_number,
                        title: 'Issue Ticket',
                        subtitle: 'Create new tickets',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/conductor/issue-ticket');
                        },
                      ),
                      
                      // Verify Ticket
                      FeatureCard(
                        icon: Icons.verified,
                        title: 'Verify Ticket',
                        subtitle: 'Scan & validate',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/conductor/scan-ticket');
                        },
                      ),
                      
                      // GPS Update
                      FeatureCard(
                        icon: Icons.gps_fixed,
                        title: 'GPS Update',
                        subtitle: 'Update location',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/conductor/gps-update');
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
                      
                      // Schedule
                      FeatureCard(
                        icon: Icons.schedule,
                        title: 'My Schedule',
                        subtitle: 'View duty roster',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, '/conductor/schedule');
                        },
                      ),
                      
                      // Welfare
                      FeatureCard(
                        icon: Icons.health_and_safety,
                        title: 'Welfare',
                        subtitle: 'Hours & benefits',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pushNamed(context, '/conductor/welfare');
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
        content: const Text('Send emergency alert to transport authority?'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}