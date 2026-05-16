// ============================================================
// features/conductor/screens/conductor_trip_screen.dart
// Start trip, view live stats, stop trip
// ============================================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class ConductorTripScreen extends ConsumerStatefulWidget {
  const ConductorTripScreen({super.key});
  @override
  ConsumerState<ConductorTripScreen> createState() =>
      _ConductorTripScreenState();
}

class _ConductorTripScreenState extends ConsumerState<ConductorTripScreen> {
  bool _loading = false;
  String? _error;
  Timer? _gpsTimer;
  int _gpsIndex = 0;

  static const _demoPath = [
    (6.9344, 79.8428),
    (6.8721, 79.8890),
    (6.8480, 79.9265),
    (6.8405, 80.0024),
  ];

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _startGpsLoop(int tripId) {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        _gpsIndex = (_gpsIndex + 1) % _demoPath.length;
        final point = _demoPath[_gpsIndex];
        await ref.read(apiServiceProvider).sendConductorGpsUpdate(
              tripId: tripId,
              latitude: point.$1,
              longitude: point.$2,
            );
      } catch (_) {}
    });
  }

  Future<void> _startTrip(RosterModel roster) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trip =
          await ref.read(apiServiceProvider).startTrip(roster.rosterId);
      _gpsIndex = 0;
      final point = _demoPath[_gpsIndex];
      await ref.read(apiServiceProvider).sendConductorGpsUpdate(
            tripId: trip.tripId,
            latitude: point.$1,
            longitude: point.$2,
          );
      _startGpsLoop(trip.tripId);
      ref.invalidate(conductorDashboardProvider);
      ref.invalidate(conductorRosterTodayProvider);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _stopTrip(TripModel trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Stop Trip'),
        content: Text('Stop the current trip on ${trip.busNumber}?\n'
            'Tickets issued: ${trip.ticketsIssuedCount}\n'
            'Fare collected: LKR ${trip.totalFareCollected.toStringAsFixed(2)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Stop Trip',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    _gpsTimer?.cancel();
    try {
      await ref.read(apiServiceProvider).stopTrip(trip.tripId);
      ref.invalidate(conductorDashboardProvider);
      ref.invalidate(conductorRosterTodayProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Trip completed successfully'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(conductorDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Trip Management'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/conductor/home')),
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _TripEmptyState(
          title: 'Could not load trip',
          message: e.toString().replaceFirst('Exception: ', ''),
        ),
        data: (dash) {
          final roster = dash.todayRoster;
          final activeTrip = dash.activeTrip;

          if (roster == null) {
            return const _TripEmptyState(
              title: 'No duty assignment today',
              message: 'Assigned trips will appear here.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Roster info card
              _RosterCard(roster: roster),
              const SizedBox(height: 16),

              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red))),
                  ]),
                ),

              // No active trip → Show Start button
              if (activeTrip == null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1))),
                  child: Column(children: [
                    const Icon(Icons.play_circle_outline,
                        size: 60, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    const Text('Ready to Start Trip',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Route: ${roster.routeName}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5))),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981)),
                          onPressed: _loading ? null : () => _startTrip(roster),
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.play_arrow, size: 22),
                          label: const Text('Start Trip',
                              style: TextStyle(fontSize: 16))),
                    ),
                  ]),
                ),
              ] else ...[
                // Active trip dashboard
                _TripLiveCard(trip: activeTrip),
                const SizedBox(height: 16),

                // Ticket-derived crowd status
                _TicketCrowdStatus(
                    trip: activeTrip, busCapacity: roster.busCapacity),
                const SizedBox(height: 16),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context.go('/conductor/ticket/issue'),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('Issue Ticket')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: () => context
                            .go('/conductor/trip/${activeTrip.tripId}/tickets'),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Tickets')),
                  ),
                ]),
                const SizedBox(height: 16),

                // Stop trip
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444)),
                      onPressed: _loading ? null : () => _stopTrip(activeTrip),
                      icon: const Icon(Icons.stop_circle_outlined, size: 22),
                      label: const Text('Stop Trip',
                          style: TextStyle(fontSize: 16))),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.event_note, color: Color(0xFFB45309), size: 20),
              const SizedBox(width: 8),
              const Text("Today's Assignment",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(roster.dutyDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const Divider(height: 16),
            _row('Bus', '${roster.busNumber} (${roster.registrationNumber})'),
            _row('Route', roster.routeName),
            _row('From', roster.startLocation),
            _row('To', roster.endLocation),
            _row('Shift', '${roster.shiftStart} – ${roster.shiftEnd}'),
            _row('Base Fare', 'LKR ${roster.baseFare.toStringAsFixed(2)}'),
          ]),
        ),
      );
  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          SizedBox(
              width: 70,
              child: Text(k,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ]),
      );
}

class _TripEmptyState extends StatelessWidget {
  final String title;
  final String message;
  const _TripEmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_busy,
                size: 60, color: Colors.white.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
          ]),
        ),
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
                colors: [Color(0xFF065F46), Color(0xFF10B981)]),
            borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            SizedBox(width: 6),
            Text('TRIP IN PROGRESS',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12, letterSpacing: 1)),
          ]),
          const SizedBox(height: 10),
          Text(trip.routeName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text('Started: ${trip.tripStart}',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            _LiveStat('Tickets', '${trip.ticketsIssuedCount}',
                Icons.confirmation_number),
            const SizedBox(width: 20),
            _LiveStat(
                'Fare Collected',
                'LKR ${trip.totalFareCollected.toStringAsFixed(2)}',
                Icons.payments_outlined),
            const SizedBox(width: 20),
            _LiveStat('Passengers', '${trip.currentPassengerCount}',
                Icons.people_outline),
          ]),
        ]),
      );
}

class _LiveStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _LiveStat(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]);
}

class _TicketCrowdStatus extends StatelessWidget {
  final TripModel trip;
  final int busCapacity;
  const _TicketCrowdStatus({required this.trip, required this.busCapacity});

  double get _pct => busCapacity > 0
      ? (trip.currentPassengerCount / busCapacity).clamp(0.0, 1.0)
      : 0;

  Color get _color => _pct < 0.4
      ? const Color(0xFF10B981)
      : _pct < 0.75
          ? const Color(0xFFF59E0B)
          : const Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.people, size: 18, color: Color(0xFFB45309)),
              SizedBox(width: 8),
              Text('Passenger Count',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: _pct,
                    minHeight: 14,
                    backgroundColor: _color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(_color))),
            const SizedBox(height: 8),
            Text(
                '${trip.currentPassengerCount} / $busCapacity passengers  '
                '(${(_pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: _color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              'Crowd is calculated automatically from active issued tickets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
          ]),
        ),
      );
}
