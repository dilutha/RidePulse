import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/passenger_models.dart';

class PassengerRouteDetailScreen extends ConsumerWidget {
  final int routeId;
  const PassengerRouteDetailScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(allRoutesProvider);
    final busesAsync  = ref.watch(activeBusesProvider(routeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Route Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/passenger/search')),
        actions: [
          // Refresh
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            ref.invalidate(activeBusesProvider(routeId));
          }),
          // Crowd prediction
          IconButton(
            icon: const Icon(Icons.auto_graph),
            tooltip: 'Crowd Prediction',
            onPressed: () => context.go('/passenger/routes/$routeId/prediction')),
        ],
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (routes) {
          final route = routes.where((r) => r.routeId == routeId).firstOrNull;
          return Column(children: [
            // Route info banner
            if (route != null) _RouteBanner(route: route),

            // Active buses
            Expanded(child: busesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data: (buses) => buses.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      const Icon(Icons.directions_bus_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No buses currently on this route',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Check back later or view crowd forecast',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 13)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.go(
                            '/passenger/routes/$routeId/prediction'),
                        icon: const Icon(Icons.auto_graph, size: 16),
                        label: const Text('View Crowd Forecast')),
                    ]))
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(children: [
                          Text('\${buses.length} bus${buses.length == 1 ? "" : "es"} on this route',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.circle,
                              color: Color(0xFF10B981), size: 10),
                          const SizedBox(width: 4),
                          const Text('Live',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ]),
                      ),
                      Expanded(child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: buses.length,
                        itemBuilder: (_, i) => _BusCard(
                          bus: buses[i],
                          onTap: () => context.go(
                              '/passenger/buses/${buses[i].busId}/live')),
                      )),
                    ]),
            )),
          ]);
        },
      ),
    );
  }
}

class _RouteBanner extends StatelessWidget {
  final RouteSearchResult route;
  const _RouteBanner({required this.route});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(route.routeNumber,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A56DB)))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(route.routeName,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        Text('\${route.startLocation} → \${route.endLocation}',
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Text('Base fare: LKR \${route.baseFare.toStringAsFixed(0)}',
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12)),
      ])),
      const Divider(),
    ]),
  );
}

class _BusCard extends StatelessWidget {
  final ActiveBus bus;
  final VoidCallback onTap;
  const _BusCard({required this.bus, required this.onTap});

  Color get _crowdColor => switch (bus.crowdCategory) {
    'low'    => const Color(0xFF10B981),
    'medium' => const Color(0xFFF59E0B),
    'high'   => const Color(0xFFEF4444),
    _        => Colors.grey,
  };

  String get _crowdLabel => switch (bus.crowdCategory) {
    'low'    => 'Not Crowded',
    'medium' => 'Moderate',
    'high'   => 'Very Crowded',
    _        => 'Unknown',
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            // Bus number
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB),
                borderRadius: BorderRadius.circular(8)),
              child: Text(bus.busNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Capacity: \${bus.passengerCount}/\${bus.capacity}',
                  style: TextStyle(fontSize: 13)),
              Text('Updated \${bus.lastUpdated}',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11)),
            ]),
            const Spacer(),
            // Crowd badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _crowdColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.people, size: 14, color: _crowdColor),
                const SizedBox(width: 4),
                Text(_crowdLabel,
                    style: TextStyle(
                        color: _crowdColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          // Crowd progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: bus.capacityPercentage / 100,
              minHeight: 8,
              backgroundColor: _crowdColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_crowdColor))),
          const SizedBox(height: 6),
          Row(children: [
            Text('\${bus.capacityPercentage.toStringAsFixed(0)}% full',
                style: TextStyle(color: _crowdColor,
                    fontWeight: FontWeight.w600, fontSize: 12)),
            const Spacer(),
            if (bus.speedKmh != null)
              const Text('\${bus.speedKmh!.toStringAsFixed(0)} km/h',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 8),
            const Text('Tap for live map →',
                style: TextStyle(
                    color: Color(0xFF1A56DB),
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    ),
  );
}
