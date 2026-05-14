// ============================================================
// features/conductor/screens/conductor_roster_screen.dart
// Shows today and selected date duty roster
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class ConductorRosterScreen extends ConsumerStatefulWidget {
  const ConductorRosterScreen({super.key});
  @override
  ConsumerState<ConductorRosterScreen> createState() =>
      _ConductorRosterScreenState();
}

class _ConductorRosterScreenState extends ConsumerState<ConductorRosterScreen> {
  DateTime _selectedDate = DateTime.now();

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, "0")}-${_selectedDate.day.toString().padLeft(2, "0")}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _dateStr == DateTime.now().toIso8601String().split('T')[0];
    final rosterAsync = isToday
        ? ref.watch(conductorRosterTodayProvider)
        : ref.watch(FutureProvider.autoDispose((r) =>
        r.read(apiServiceProvider).getConductorRosterForDate(_dateStr)));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        title: const Text('Duty Roster'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/conductor/home')),
      ),
      body: Column(children: [
        // Date picker row
        Container(
          color: Colors.white.withOpacity(0.03),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() =>
                _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
            Expanded(child: InkWell(
              onTap: _pickDate,
              child: Center(child: Text(
                  isToday ? 'Today — $_dateStr' : _dateStr,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15))),
            )),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() =>
                _selectedDate = _selectedDate.add(const Duration(days: 1)))),
          ]),
        ),
        Divider(height: 1, color: Colors.white.withOpacity(0.08)),
        Expanded(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => _EmptyRosterState(
              title: 'Could not load duty roster',
              message: e.toString().replaceFirst('Exception: ', ''),
            ),
            data: (rosters) => rosters.isEmpty
                ? _EmptyRosterState(
              title: isToday
                  ? 'No duty assignment today'
                  : 'No roster for this date',
              message: 'Assigned duties will appear here.',
            )
                : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rosters.length,
                itemBuilder: (_, i) => _RosterCard(roster: rosters[i])),
          ),
        ),
      ]),
    );
  }
}

class _RosterCard extends StatelessWidget {
  final RosterModel roster;
  const _RosterCard({required this.roster});

  Color get _statusColor => switch (roster.status) {
    'active'    => const Color(0xFF10B981),
    'completed' => const Color(0xFF6B7280),
    'cancelled' => const Color(0xFFEF4444),
    _           => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(roster.status.toUpperCase(),
                  style: TextStyle(color: _statusColor,
                      fontSize: 11, fontWeight: FontWeight.w700))),
          const Spacer(),
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text('${roster.shiftStart} – ${roster.shiftEnd}',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 12),
        // Bus info
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFB45309).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_bus,
                  color: Color(0xFFB45309), size: 24)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(roster.busNumber,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
            Text(roster.registrationNumber,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ]),
        ]),
        const Divider(height: 20),
        // Route info
        Row(children: [
          const Icon(Icons.route, size: 16, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 6),
          Expanded(child: Text(
              '${roster.routeNumber} — ${roster.routeName}',
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 22),
          Text('${roster.startLocation} → ${roster.endLocation}',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 22),
          Text('Base Fare: LKR ${roster.baseFare.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
          const Spacer(),
          Text('Capacity: ${roster.busCapacity}',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
        ]),
      ]),
    ),
  );
}

class _EmptyRosterState extends StatelessWidget {
  final String title;
  final String message;
  const _EmptyRosterState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.event_busy, size: 56, color: Colors.white.withOpacity(0.35)),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13)),
      ]),
    ),
  );
}
