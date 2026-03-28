// ============================================================
// features/bus_owner/screens/bus_owner_roster_screen.dart
// Bus Owner: view, create, and manage duty rosters
// OOP Encapsulation: all state in ConsumerStateful.
//     Abstraction: one button creates a complete roster entry.
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/bus_models.dart";
import "../../../core/models/roster_models.dart";

// ── Providers ─────────────────────────────────────────────────

final _rosterRangeProvider = FutureProvider.autoDispose
    .family<List<RosterModel>, ({String from, String to})>(
        (ref, params) async {
  final data = await ref.read(apiServiceProvider)
      .getBusOwnerRosters(from: params.from, to: params.to) as List;
  return data.map((e) => RosterModel.fromRosterDetail(e)).toList();
});


class BusOwnerRosterScreen extends ConsumerStatefulWidget {
  const BusOwnerRosterScreen({super.key});
  @override
  ConsumerState<BusOwnerRosterScreen> createState() =>
      _BusOwnerRosterScreenState();
}

class _BusOwnerRosterScreenState
    extends ConsumerState<BusOwnerRosterScreen> {
  DateTime _weekStart = _monday(DateTime.now());

  static DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  String get _from => _fmt(_weekStart);
  String get _to   => _fmt(_weekStart.add(const Duration(days: 6)));

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,"0")}-'
      '${d.day.toString().padLeft(2,"0")}';

  String _label(DateTime d) {
    final months = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final params   = (from: _from, to: _to);
    final rAsync   = ref.watch(_rosterRangeProvider(params));
    final busAsync = ref.watch(busListProvider);
    final staffD   = ref.watch(staffListProvider('driver'));
    final staffC   = ref.watch(staffListProvider('conductor'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Duty Roster'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/bus-owner/staff')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_rosterRangeProvider(params))),
        ],
      ),
      floatingActionButton: busAsync.maybeWhen(
        data: (buses) => staffD.maybeWhen(
          data: (drivers) => staffC.maybeWhen(
            data: (conductors) => FloatingActionButton.extended(
              onPressed: () => _showCreateDialog(
                  context, buses, [...drivers, ...conductors], params),
              icon: const Icon(Icons.add),
              label: const Text('Add Roster'),
              backgroundColor: const Color(0xFF1A56DB)),
            orElse: () => null),
          orElse: () => null),
        orElse: () => null),
      body: Column(children: [
        // Week navigator
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 10),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() =>
                  _weekStart = _weekStart.subtract(
                      const Duration(days: 7)))),
            Expanded(child: Center(child: Text(
              '${_label(_weekStart)} – ${_label(_weekStart.add(const Duration(days: 6)))}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)))),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() =>
                  _weekStart = _weekStart.add(
                      const Duration(days: 7)))),
          ]),
        ),
        const Divider(height: 1),

        // Roster list
        Expanded(child: rAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (rosters) => rosters.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Icon(Icons.event_busy,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No rosters this week',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text('Tap + to add roster entries',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: rosters.length,
                  itemBuilder: (_, i) => _RosterCard(
                    roster: rosters[i],
                    onDelete: () => _delete(rosters[i], params),
                  )),
        )),
      ]),
    );
  }

  void _showCreateDialog(BuildContext ctx, List<BusModel> buses,
      List<StaffModel> staff, dynamic params) {
    showDialog(context: ctx, barrierDismissible: false,
        builder: (_) => _CreateRosterDialog(
            buses: buses.where((b) => b.isActive).toList(),
            staff: staff,
            initialDate: _weekStart,
            onSaved: () => ref.invalidate(
                _rosterRangeProvider(params))));
  }

  Future<void> _delete(RosterModel r, dynamic params) async {
    final ok = await showDialog<bool>(context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete Roster'),
          content: Text(
            'Delete duty for ${r.staffName} on ${r.dutyDate}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.white))),
          ]));
    if (ok != true) return;
    try {
      await ref.read(apiServiceProvider).deleteRoster(r.rosterId);
      ref.invalidate(_rosterRangeProvider(params));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red));
    }
  }
}

class _RosterCard extends StatelessWidget {
  final RosterModel roster;
  final VoidCallback onDelete;
  const _RosterCard({required this.roster, required this.onDelete});

  Color get _sc => switch (roster.status) {
    'active'    => const Color(0xFF059669),
    'completed' => const Color(0xFF6B7280),
    'cancelled' => const Color(0xFFDC2626),
    _           => const Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      // Date column
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(roster.dutyDate.substring(8),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16,
                  color: Color(0xFF1A56DB))),
          Text(_monthShort(roster.dutyDate),
              style: const TextStyle(
                  color: Color(0xFF1A56DB), fontSize: 10)),
        ])),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(roster.isDriver ? Icons.drive_eta : Icons.person,
              size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(roster.staffName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: _sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(roster.status.toUpperCase(),
                style: TextStyle(color: _sc, fontSize: 9,
                    fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.directions_bus_outlined,
              size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(roster.busNumber,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(width: 10),
          const Icon(Icons.access_time, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text('${roster.shiftStart} – ${roster.shiftEnd}',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12)),
        ]),
        Text(roster.routeName,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 11),
            overflow: TextOverflow.ellipsis),
      ])),
      // Delete button (only for scheduled)
      if (roster.isScheduled)
        IconButton(
          icon: const Icon(Icons.delete_outline,
              color: Colors.red, size: 20),
          tooltip: 'Delete',
          onPressed: onDelete),
    ])),
  );

  String _monthShort(String date) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    try { return m[int.parse(date.substring(5, 7))]; }
    catch (_) { return ''; }
  }
}

class _CreateRosterDialog extends ConsumerStatefulWidget {
  final List<BusModel>   buses;
  final List<StaffModel> staff;
  final DateTime         initialDate;
  final VoidCallback     onSaved;
  const _CreateRosterDialog({required this.buses, required this.staff,
      required this.initialDate, required this.onSaved});
  @override
  ConsumerState<_CreateRosterDialog> createState() =>
      _CreateRosterDialogState();
}

class _CreateRosterDialogState
    extends ConsumerState<_CreateRosterDialog> {
  StaffModel? _staff;
  BusModel?   _bus;
  DateTime    _date   = DateTime.now();
  TimeOfDay   _start  = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay   _end    = const TimeOfDay(hour: 14, minute: 0);
  bool        _loading = false;
  String?     _error;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,"0")}-'
      '${d.day.toString().padLeft(2,"0")}';
  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,"0")}:'
      '${t.minute.toString().padLeft(2,"0")}';

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Duty Roster'),
    content: SizedBox(width: 480, child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Staff dropdown
        DropdownButtonFormField<StaffModel>(
          value: _staff, isExpanded: true,
          hint: const Text('Select staff member'),
          decoration: const InputDecoration(
              labelText: 'Staff *',
              prefixIcon: Icon(Icons.person, size: 20),
              border: OutlineInputBorder()),
          items: widget.staff.map((s) => DropdownMenuItem(
            value: s,
            child: Text(
              '${s.staffType.toUpperCase()} — ${s.fullName}',
              overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (s) => setState(() => _staff = s),
        ),
        const SizedBox(height: 14),

        // Bus dropdown
        DropdownButtonFormField<BusModel>(
          value: _bus, isExpanded: true,
          hint: const Text('Select bus'),
          decoration: const InputDecoration(
              labelText: 'Bus *',
              prefixIcon: Icon(Icons.directions_bus, size: 20),
              border: OutlineInputBorder()),
          items: widget.buses.map((b) => DropdownMenuItem(
            value: b,
            child: Text(
              '${b.busNumber} — '
              '${b.route?.routeName ?? "No route"}',
              overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (b) => setState(() => _bus = b),
        ),
        const SizedBox(height: 14),

        // Date picker
        InkWell(
          onTap: () async {
            final p = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now()
                    .subtract(const Duration(days: 7)),
                lastDate: DateTime.now()
                    .add(const Duration(days: 60)));
            if (p != null) setState(() => _date = p);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Duty Date *',
                prefixIcon: Icon(Icons.calendar_today, size: 20),
                border: OutlineInputBorder()),
            child: Text(_fmtDate(_date)),
          ),
        ),
        const SizedBox(height: 14),

        // Shift times
        Row(children: [
          Expanded(child: InkWell(
            onTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _start);
              if (t != null) setState(() => _start = t);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Shift Start *',
                  border: OutlineInputBorder()),
              child: Text(_fmtTime(_start))),
          )),
          const SizedBox(width: 12),
          Expanded(child: InkWell(
            onTap: () async {
              final t = await showTimePicker(
                  context: context, initialTime: _end);
              if (t != null) setState(() => _end = t);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Shift End *',
                  border: OutlineInputBorder()),
              child: Text(_fmtTime(_end))),
          )),
        ]),

        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6)),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ]),
    )),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
      ElevatedButton(
        onPressed: (_staff == null || _bus == null || _loading)
            ? null
            : _submit,
        child: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Create Roster',
                style: TextStyle(color: Colors.white))),
    ],
  );

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).createRoster(
        staffId:    _staff!.staffId,
        busId:      _bus!.busId,
        dutyDate:   _fmtDate(_date),
        shiftStart: _fmtTime(_start),
        shiftEnd:   _fmtTime(_end),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally { setState(() => _loading = false); }
  }
}
