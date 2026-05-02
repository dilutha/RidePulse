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
      '\${_selectedDate.year}-\${_selectedDate.month.toString().padLeft(2, "0")}-\${_selectedDate.day.toString().padLeft(2, "0")}';

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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Duty Roster'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/conductor/home')),
      ),
      body: Column(children: [
        // Date picker row
        Container(
          color: Colors.white,
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
        const Divider(height: 1),
        Expanded(
          child: rosterAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Error: $e')),
            data: (rosters) => rosters.isEmpty
                ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.event_busy, size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(isToday
                  ? 'No duty assignment today'
                  : 'No roster for this date',
                  style: const TextStyle(color: Colors.grey)),
            ]))
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
          const Row(children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text('\${roster.shiftStart} – \${roster.shiftEnd}',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ]),
        const Divider(height: 20),
        // Route info
        const Row(children: [
          Icon(Icons.route, size: 16, color: Color(0xFF3B82F6)),
          SizedBox(width: 6),
          Expanded(child: Text(
              '\${roster.routeNumber} — \${roster.routeName}',
              style: TextStyle(fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 22),
          Text('\${roster.startLocation} → \${roster.endLocation}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const SizedBox(width: 22),
          Text('Base Fare: LKR \${roster.baseFare.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Text('Capacity: \${roster.busCapacity}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ]),
      ]),
    ),
  );
}
