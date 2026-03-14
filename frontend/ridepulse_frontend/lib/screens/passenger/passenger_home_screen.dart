import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/feature_card.dart';

/*
  Passenger Home Screen

  COMPOSITION (OOP Concept):
  Screen composed of multiple feature cards
*/

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Pulse - Passenger'),
        elevation: 0,
      ),

      drawer: const AppDrawer(),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user?.fullName ?? 'Passenger',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// FEATURES
            Padding(
              padding: const EdgeInsets.all(16),

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

                      /// LIVE TRACKING
                      FeatureCard(
                        icon: Icons.location_on,
                        title: 'Live Tracking',
                        subtitle: 'Track buses in real-time',
                        color: Colors.green,
                        onTap: () {
                          context.push('/passenger/live-tracking');
                        },
                      ),

                      /// ETA
                      FeatureCard(
                        icon: Icons.access_time,
                        title: 'ETA',
                        subtitle: 'Estimated arrival times',
                        color: Colors.orange,
                        onTap: () {
                          context.push('/passenger/eta');
                        },
                      ),

                      /// CROWD LEVEL
                      FeatureCard(
                        icon: Icons.people,
                        title: 'Crowd Level',
                        subtitle: 'Current bus occupancy',
                        color: Colors.purple,
                        onTap: () {
                          context.push('/passenger/crowd-level');
                        },
                      ),

                      /// CROWD PREDICTION
                      FeatureCard(
                        icon: Icons.insights,
                        title: 'Crowd Prediction',
                        subtitle: 'AI-powered forecasts',
                        color: Colors.blue,
                        onTap: () {
                          context.push('/passenger/crowd-prediction');
                        },
                      ),

                      /// DIGITAL TICKET
                      FeatureCard(
                        icon: Icons.confirmation_number,
                        title: 'Digital Ticket',
                        subtitle: 'Book & manage tickets',
                        color: Colors.teal,
                        onTap: () {
                          context.push('/passenger/tickets');
                        },
                      ),

                      /// COMPLAINTS
                      FeatureCard(
                        icon: Icons.report_problem,
                        title: 'Complaints',
                        subtitle: 'Report issues',
                        color: Colors.red,
                        onTap: () {
                          context.push('/passenger/my_complaints');
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
}