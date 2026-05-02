// ============================================================
// features/driver/screens/driver_trip_screen.dart
// Start / stop trip + live GPS update loop
// ============================================================
import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/driver_models.dart";
import "../../../core/models/conductor_models.dart";

class DriverTripScreen extends ConsumerStatefulWidget {
  const DriverTripScreen({super.key});
  @override
  ConsumerState<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends ConsumerState<DriverTripScreen> {
  bool   _loading  = false;
  String? _error;
  Timer?  _gpsTimer;

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startGpsLoop(int tripId) {
    _gpsTimer?.cancel();
    // Send GPS every 15 seconds — in production integrate geolocator package
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        // Placeholder coords — replace with geolocator position in production
        await ref.read(apiServiceProvider).sendGpsUpdate(
          tripId: tripId, latitude: 6.9271, longitude: 79.8612);
      } catch (_) {}
    });
  }

  Future<void> _startTrip(RosterModel roster) async {
    setState(() { _loading = true; _error = null; });
    try {
      final trip = await ref.read(apiServiceProvider).driverStartTrip(roster.rosterId);
      _startGpsLoop(trip.tripId);
      ref.invalidate(driverDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip started — GPS tracking active"),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally { setState(() => _loading = false); }
  }

  Future<void> _stopTrip(TripModel trip) async {
    final confirm = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        title: const Text("Stop Trip"),
        content: const Text("Complete trip on \${trip.busNumber}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Stop Trip", style: TextStyle(color: Colors.white))),
        ],
      ));
    if (confirm != true) return;

    setState(() { _loading = true; _error = null; });
    _gpsTimer?.cancel();
    try {
      await ref.read(apiServiceProvider).driverStopTrip(trip.tripId);
      ref.invalidate(driverDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip completed"),
              backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(driverDashboardProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Trip Management"),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go("/driver/home")),
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => const Center(child: Text("Error: \$e")),
        data: (dash) {
          final roster = dash.todayRoster;
          final trip   = dash.activeTrip;

          if (roster == null) {
            return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text("No duty today", style: TextStyle(color: Colors.grey)),
          ]));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Roster info
              _RosterCard(roster: roster),
              const SizedBox(height: 14),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(color: Colors.red))),

              if (trip == null) ...[
                // Start trip
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Column(children: [
                    const Icon(Icons.play_circle_outline,
                        size: 60, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    const Text("Ready to Drive",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(roster.routeName,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981)),
                        onPressed: _loading ? null : () => _startTrip(roster),
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.play_arrow, size: 22),
                        label: const Text("Start Trip", style: TextStyle(fontSize: 16))),
                    ),
                  ]),
                ),
              ] else ...[
                // Live trip card
                _TripLiveCard(trip: trip),
                const SizedBox(height: 16),

                // GPS status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.gps_fixed,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(_gpsTimer?.isActive == true
                        ? "GPS tracking active — sending every 15s"
                        : "GPS tracking paused",
                        style: const TextStyle(
                            color: Color(0xFF065F46), fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 16),

                // Emergency shortcut
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  onPressed: () => context.go("/driver/emergency"),
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text("Raise Emergency Alert")),
                const SizedBox(height: 16),

                // Stop trip
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444)),
                    onPressed: _loading ? null : () => _stopTrip(trip),
                    icon: const Icon(Icons.stop_circle_outlined, size: 22),
                    label: const Text("Stop Trip", style: TextStyle(fontSize: 16))),
                ),
              ],
            ]),
          );
        },
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  final RosterModel roster;
  const _RosterCard({required this.roster});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.event_note, color: Color(0xFF1E40AF), size: 18),
        const SizedBox(width: 8),
        const Text("Today's Assignment",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(roster.dutyDate,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
      const Divider(height: 16),
      _r("Bus",    "\${roster.busNumber} (\${roster.registrationNumber})"),
      _r("Route",  roster.routeName),
      _r("From",   roster.startLocation),
      _r("To",     roster.endLocation),
      _r("Shift",  "\${roster.shiftStart} – \${roster.shiftEnd}"),
    ])),
  );
  Widget _r(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 50, child: Text(k,
          style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}

class _TripLiveCard extends StatelessWidget {
  final TripModel trip;
  const _TripLiveCard({required this.trip});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.circle, color: Colors.greenAccent, size: 10),
        SizedBox(width: 6),
        Text("TRIP IN PROGRESS", style: TextStyle(
            color: Colors.white70, fontSize: 12, letterSpacing: 1)),
      ]),
      const SizedBox(height: 8),
      Text(trip.routeName, style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const Text("Started: \${trip.tripStart}",
          style: TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  );
}
