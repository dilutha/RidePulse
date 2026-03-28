// ============================================================
// features/authority/screens/authority_roster_screen.dart
// Authority: monitor all duty rosters + edit status
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/roster_models.dart";

final _authorityRosterProvider = FutureProvider.autoDispose
    .family<List<RosterModel>, ({String from, String to})>(
        (ref, params) async {
  final data = await ref.read(apiServiceProvider)
      .getAuthorityRosters(from: params.from, to: params.to) as List;
  return data.map((e) => RosterModel.fromRosterDetail(e)).toList();
});

class AuthorityRosterScreen extends ConsumerStatefulWidget {
  const AuthorityRosterScreen({super.key});
  @override
  ConsumerState<AuthorityRosterScreen> createState() =>
      _AuthorityRosterScreenState();
}

class _AuthorityRosterScreenState
    extends ConsumerState<AuthorityRosterScreen> {
  DateTime _weekStart = _monday(DateTime.now());
  String   _filter    = 'all'; // all | driver | conductor | scheduled

  static DateTime _monday(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,"0")}-'
      '${d.day.toString().padLeft(2,"0")}';

  String _label(DateTime d) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final params = (from: _fmt(_weekStart),
                    to:   _fmt(_weekStart.add(const Duration(days: 6))));
    final async  = ref.watch(_authorityRosterProvider(params));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Duty Roster Monitor'),
        actions: [IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(_authorityRosterProvider(params)))],
      ),
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
              '${_label(_weekStart)} – '
              '${_label(_weekStart.add(const Duration(days: 6)))}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)))),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() =>
                  _weekStart = _weekStart.add(
                      const Duration(days: 7)))),
          ]),
        ),

        // Filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _chip('All',       'all'),
              const SizedBox(width: 6),
              _chip('Drivers',   'driver'),
              const SizedBox(width: 6),
              _chip('Conductors','conductor'),
              const SizedBox(width: 6),
              _chip('Scheduled', 'scheduled'),
              const SizedBox(width: 6),
              _chip('Active',    'active'),
            ]),
          ),
        ),
        const Divider(height: 1),

        // Roster list
        Expanded(child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (all) {
            final filtered = all.where((r) {
              if (_filter == 'driver'    && !r.isDriver)   return false;
              if (_filter == 'conductor' &&  r.isDriver)   return false;
              if (_filter == 'scheduled' && !r.isScheduled)return false;
              if (_filter == 'active'    && !r.isActive)   return false;
              return true;
            }).toList();

            if (filtered.isEmpty) return const Center(
                child: Text('No rosters found',
                    style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _AuthRosterCard(
                roster: filtered[i],
                onEdit: () => _showEditDialog(
                    context, filtered[i], params),
              ));
          },
        )),
      ]),
    );
  }

  Widget _chip(String label, String val) => GestureDetector(
    onTap: () => setState(() => _filter = val),
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: _filter == val
              ? const Color(0xFF1E1B4B)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
          color: _filter == val ? Colors.white : Colors.grey.shade700,
          fontSize: 12, fontWeight: FontWeight.w500))));

  void _showEditDialog(BuildContext context, RosterModel roster,
      dynamic params) {
    showDialog(
      context: context,
      builder: (_) => _EditRosterDialog(
        roster: roster,
        onSaved: () => ref.invalidate(
            _authorityRosterProvider(params))));
  }
}

class _AuthRosterCard extends StatelessWidget {
  final RosterModel roster;
  final VoidCallback onEdit;
  const _AuthRosterCard({required this.roster, required this.onEdit});

  Color get _sc => switch (roster.status) {
    'active'    => const Color(0xFF059669),
    'completed' => const Color(0xFF6B7280),
    'cancelled' => const Color(0xFFDC2626),
    _           => const Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(padding: const EdgeInsets.all(14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Date badge
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B).withOpacity(0.07),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(roster.dutyDate.substring(8),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15,
                      color: Color(0xFF1E1B4B))),
              Text(_monthShort(roster.dutyDate),
                  style: const TextStyle(
                      color: Color(0xFF1E1B4B), fontSize: 9)),
            ])),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(roster.isDriver ? Icons.drive_eta : Icons.person,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(roster.staffName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: _sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(roster.status.toUpperCase(),
                    style: TextStyle(color: _sc, fontSize: 9,
                        fontWeight: FontWeight.w700))),
            ]),
            Text('${roster.busNumber}  ·  '
                '${roster.shiftStart}–${roster.shiftEnd}',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
            Text(roster.routeName,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ])),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF1E1B4B), size: 20),
            onPressed: onEdit),
        ]),
      ])),
  );

  String _monthShort(String date) {
    const m = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    try { return m[int.parse(date.substring(5, 7))]; }
    catch (_) { return ''; }
  }
}

class _EditRosterDialog extends ConsumerStatefulWidget {
  final RosterModel  roster;
  final VoidCallback onSaved;
  const _EditRosterDialog({required this.roster, required this.onSaved});
  @override
  ConsumerState<_EditRosterDialog> createState() => _EditState();
}

class _EditState extends ConsumerState<_EditRosterDialog> {
  late String  _status;
  TimeOfDay?   _start, _end;
  bool         _loading = false;
  String?      _error;

  static const _statuses = [
    'scheduled', 'active', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _status = widget.roster.status;
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,"0")}:'
      '${t.minute.toString().padLeft(2,"0")}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Edit Roster — ${widget.roster.staffName}'),
    content: SizedBox(width: 420, child: Column(
        mainAxisSize: MainAxisSize.min, children: [
      Text('${widget.roster.dutyDate}  ·  ${widget.roster.busNumber}',
          style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 16),

      // Status
      DropdownButtonFormField<String>(
        value: _status,
        decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder()),
        items: _statuses.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.toUpperCase()))).toList(),
        onChanged: (s) => setState(() => _status = s!),
      ),
      const SizedBox(height: 14),

      // Shift times (optional override)
      Row(children: [
        Expanded(child: InkWell(
          onTap: () async {
            final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: int.parse(
                        widget.roster.shiftStart.split(':')[0]),
                    minute: int.parse(
                        widget.roster.shiftStart.split(':')[1])));
            if (t != null) setState(() => _start = t);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Shift Start',
                border: OutlineInputBorder()),
            child: Text(_start != null
                ? _fmtTime(_start!)
                : widget.roster.shiftStart)),
        )),
        const SizedBox(width: 12),
        Expanded(child: InkWell(
          onTap: () async {
            final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                    hour: int.parse(
                        widget.roster.shiftEnd.split(':')[0]),
                    minute: int.parse(
                        widget.roster.shiftEnd.split(':')[1])));
            if (t != null) setState(() => _end = t);
          },
          child: InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Shift End',
                border: OutlineInputBorder()),
            child: Text(_end != null
                ? _fmtTime(_end!)
                : widget.roster.shiftEnd)),
        )),
      ]),

      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(
            color: Colors.red, fontSize: 12)),
      ],
    ])),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
      ElevatedButton(
        onPressed: _loading ? null : _submit,
        child: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Save',
                style: TextStyle(color: Colors.white))),
    ],
  );

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).updateRosterByAuthority(
        rosterId:   widget.roster.rosterId,
        status:     _status,
        shiftStart: _start != null ? _fmtTime(_start!) : null,
        shiftEnd:   _end   != null ? _fmtTime(_end!)   : null,
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
