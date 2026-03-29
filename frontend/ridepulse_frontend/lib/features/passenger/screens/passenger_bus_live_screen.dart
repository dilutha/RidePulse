import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/passenger_models.dart';

class PassengerBusLiveScreen extends ConsumerWidget {
  final int busId;
  const PassengerBusLiveScreen({super.key, required this.busId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(busLiveDetailProvider(busId));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: async.when(
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(busLiveDetailProvider(busId)),
        ),
        data: (bus) => _Body(
          bus: bus,
          onRefresh: () => ref.invalidate(busLiveDetailProvider(busId)),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final BusLiveDetail bus;
  final VoidCallback  onRefresh;
  const _Body({required this.bus, required this.onRefresh});

  Color get _crowdColor => switch (bus.crowdCategory) {
    'low'    => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFBBF24),
    'high'   => const Color(0xFFF87171),
    _        => const Color(0xFF94A3B8),
  };

  String get _crowdLabel => switch (bus.crowdCategory) {
    'low'    => 'Not Crowded',
    'medium' => 'Moderate',
    'high'   => 'Very Crowded',
    _        => 'Unknown',
  };

  IconData get _crowdIcon => switch (bus.crowdCategory) {
    'low'    => Icons.sentiment_satisfied_rounded,
    'medium' => Icons.sentiment_neutral_rounded,
    'high'   => Icons.sentiment_very_dissatisfied_rounded,
    _        => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final defaultCenter = const LatLng(6.9271, 79.8612);
    final busCenter     = bus.hasLocation
        ? LatLng(bus.latitude!, bus.longitude!)
        : defaultCenter;

    return Column(children: [
      // ── Map — 60% ────────────────────────────────────────
      Expanded(
        flex: 3,
        child: Stack(children: [
          FlutterMap(
            options: MapOptions(
                initialCenter: busCenter,
                initialZoom: 14),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ridepulse.app'),

              // Route polyline
              if (bus.stops.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(
                    points: bus.stops
                        .where((s) => s['latitude'] != null)
                        .map((s) => LatLng(
                            (s['latitude']  as num).toDouble(),
                            (s['longitude'] as num).toDouble()))
                        .toList(),
                    color: const Color(0xFF1A56DB).withOpacity(0.65),
                    strokeWidth: 4,
                  ),
                ]),

              // Bus marker
              if (bus.hasLocation)
                MarkerLayer(markers: [
                  Marker(
                    point: busCenter,
                    width: 80, height: 80,
                    child: _BusMapPin(
                        busNumber: bus.busNumber,
                        crowdColor: _crowdColor)),
                ]),
            ],
          ),

          // Floating app bar over map
          Positioned(top: 0, left: 0, right: 0,
            child: _MapTopBar(
              busNumber:  bus.busNumber,
              onBack:     () => Navigator.pop(context),
              onRefresh:  onRefresh,
            ),
          ),

          // Speed pill (bottom-left of map)
          if (bus.speedKmh != null)
            Positioned(bottom: 12, left: 12,
              child: _SpeedPill(speed: bus.speedKmh!),
            ),

          // Last updated pill (bottom-right of map)
          Positioned(bottom: 12, right: 12,
            child: _UpdatedPill(time: bus.lastUpdated),
          ),
        ]),
      ),

      // ── Info panel — 40% ──────────────────────────────────
      Expanded(
        flex: 2,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1626),
            border: Border(
                top: BorderSide(
                    color: Colors.white.withOpacity(0.08))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(children: [

              // Route header
              _RouteHeader(bus: bus),
              const SizedBox(height: 14),

              Divider(height: 1,
                  color: Colors.white.withOpacity(0.07)),
              const SizedBox(height: 14),

              // Crowd section
              _CrowdSection(
                bus:        bus,
                color:      _crowdColor,
                label:      _crowdLabel,
                icon:       _crowdIcon,
              ),

              // Alert banners
              if (!bus.hasLocation) ...[
                const SizedBox(height: 12),
                _AlertBanner(
                  icon: Icons.gps_not_fixed_rounded,
                  message: 'GPS location not available for this bus',
                  color: const Color(0xFFFB923C),
                ),
              ],
              if (!bus.isOnTrip) ...[
                const SizedBox(height: 10),
                _AlertBanner(
                  icon: Icons.info_outline_rounded,
                  message: 'This bus is not currently on a trip',
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ── Floating map top bar ──────────────────────────────────────

class _MapTopBar extends StatelessWidget {
  final String       busNumber;
  final VoidCallback onBack, onRefresh;
  const _MapTopBar({
    required this.busNumber,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 10, right: 10, bottom: 6),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0B1220).withOpacity(0.92),
          Colors.transparent,
        ],
      ),
    ),
    child: Row(children: [
      _MapBtn(icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack),
      const SizedBox(width: 10),
      Expanded(
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.location_on_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const Text('Live Tracking',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text('Bus $busNumber',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11)),
          ]),
        ]),
      ),
      _MapBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
    ]),
  );
}

class _MapBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Icon(icon,
          size: 16, color: Colors.white.withOpacity(0.8)),
    ),
  );
}

// ── Map pills ─────────────────────────────────────────────────

class _SpeedPill extends StatelessWidget {
  final double speed;
  const _SpeedPill({required this.speed});

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1220).withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.speed_rounded,
          size: 13, color: Color(0xFF38BDF8)),
      const SizedBox(width: 5),
      Text('${speed.toStringAsFixed(0)} km/h',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class _UpdatedPill extends StatelessWidget {
  final String time;
  const _UpdatedPill({required this.time});

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1220).withOpacity(0.85),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.15)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
            color: Color(0xFF4ADE80), shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(time,
          style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 11)),
    ]),
  );
}

// ── Route header ──────────────────────────────────────────────

class _RouteHeader extends StatelessWidget {
  final BusLiveDetail bus;
  const _RouteHeader({required this.bus});

  @override
  Widget build(BuildContext context) => Row(children: [
    // Bus number badge
    Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(bus.busNumber,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    ),
    const SizedBox(width: 12),
    // Route info
    Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text(bus.routeName,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14)),
      const SizedBox(height: 2),
      Text('Route ${bus.routeNumber}',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12)),
    ])),
  ]);
}

// ── Crowd section ─────────────────────────────────────────────

class _CrowdSection extends StatelessWidget {
  final BusLiveDetail bus;
  final Color         color;
  final String        label;
  final IconData      icon;
  const _CrowdSection({
    required this.bus, required this.color,
    required this.label, required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text('Current Crowd',
          style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
      const Spacer(),
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    ]),
    const SizedBox(height: 10),
    // Progress bar
    ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(children: [
        Container(
            height: 10, color: Colors.white.withOpacity(0.06)),
        FractionallySizedBox(
          widthFactor: (bus.capacityPercentage / 100).clamp(0.0, 1.0),
          child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              )),
        ),
      ]),
    ),
    const SizedBox(height: 8),
    Row(children: [
      Text('${bus.capacityPercentage.toStringAsFixed(0)}% full',
          style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12)),
      const Spacer(),
      Text('${bus.passengerCount} / ${bus.capacity}',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
      Text(' passengers',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12)),
    ]),
  ]);
}

// ── Alert banner ──────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String   message;
  final Color    color;
  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style:
                TextStyle(color: color, fontSize: 13)),
      ),
    ]),
  );
}

// ── Bus map pin ───────────────────────────────────────────────

class _BusMapPin extends StatelessWidget {
  final String busNumber;
  final Color  crowdColor;
  const _BusMapPin(
      {required this.busNumber, required this.crowdColor});

  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: crowdColor,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
              color: crowdColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1),
        ],
      ),
      child: Text(busNumber,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800)),
    ),
    Icon(Icons.directions_bus_rounded,
        color: crowdColor, size: 32),
  ]);
}

// ── Utility ───────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0B1220),
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 28, height: 28,
            child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9), strokeWidth: 2)),
        SizedBox(height: 14),
        Text('Loading bus location...',
            style: TextStyle(
                color: Color(0xFF64748B), fontSize: 13)),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1220),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(Icons.gps_off_rounded,
                  size: 30,
                  color: Colors.white.withOpacity(0.25)),
            ),
            const SizedBox(height: 18),
            const Text('Could not load bus location',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A56DB), Color(0xFF0EA5E9)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min,
                    children: [
                  const Icon(Icons.refresh_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Retry',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('Go back',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13)),
            ),
          ]),
        ),
      ),
    ),
  );
}