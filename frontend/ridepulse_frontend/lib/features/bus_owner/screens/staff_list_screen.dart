// ============================================================
// features/bus_owner/screens/staff_list_screen.dart
// UPDATED: Added assign-to-bus button on each staff card
// OOP Polymorphism: same tab widget handles both staff types.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/bus_models.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});
  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: const Text('Staff Management'),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Duty Roster',
          onPressed: () => context.go('/bus-owner/roster')),
        IconButton(
          icon: const Icon(Icons.person_add),
          tooltip: 'Register Staff',
          onPressed: () => context.go('/bus-owner/staff/register')),
      ],
      bottom: TabBar(
        controller: _tab,
        labelColor: const Color(0xFF1A56DB),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF1A56DB),
        tabs: const [
          Tab(icon: Icon(Icons.drive_eta, size: 18), text: 'Drivers'),
          Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Conductors'),
        ]),
    ),
    body: TabBarView(
      controller: _tab,
      children: [
        _StaffTab(staffType: 'driver'),
        _StaffTab(staffType: 'conductor'),
      ]),
  );
}

class _StaffTab extends ConsumerWidget {
  final String staffType;
  const _StaffTab({required this.staffType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffListProvider(staffType));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text('Error: $e')),
      data: (list) => list.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text('No ${staffType}s registered yet',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.go('/bus-owner/staff/register'),
                icon: const Icon(Icons.person_add),
                label: const Text('Register Staff')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _StaffCard(
                staff: list[i],
                staffType: staffType,
                onToggle: (val) async {
                  await ref.read(apiServiceProvider)
                      .toggleStaffStatus(list[i].staffId, val);
                  ref.invalidate(staffListProvider(staffType));
                },
                onAssign: () => _showAssignDialog(
                    context, ref, list[i], staffType),
                onTap: () => context.go(
                    '/bus-owner/staff/${list[i].staffId}'),
              ),
            ),
    );
  }

  void _showAssignDialog(BuildContext context, WidgetRef ref,
      StaffModel staff, String staffType) {
    showDialog(
      context: context,
      builder: (_) => _AssignBusDialog(
        staff: staff,
        onSaved: () {
          ref.invalidate(staffListProvider(staffType));
          ref.invalidate(busListProvider);
        },
      ),
    );
  }
}

// ── Staff Card ────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final String     staffType;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAssign;
  final VoidCallback onTap;

  const _StaffCard({
    required this.staff,    required this.staffType,
    required this.onToggle, required this.onAssign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: staff.isActive
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.grey.shade100,
              child: Text(staff.fullName[0].toUpperCase(),
                  style: TextStyle(
                      color: staff.isActive
                          ? const Color(0xFF3B82F6) : Colors.grey,
                      fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(staff.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(staff.phone,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ])),
            // Active toggle
            Switch(
              value: staff.isActive,
              onChanged: onToggle,
              activeColor: const Color(0xFF10B981)),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Bus assignment row
          Row(children: [
            const Icon(Icons.directions_bus_outlined,
                size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(
              staff.assignedBusNumber == 'Unassigned'
                  ? 'Not assigned to any bus'
                  : 'Bus: ${staff.assignedBusNumber}',
              style: TextStyle(
                  fontSize: 13,
                  color: staff.assignedBusNumber == 'Unassigned'
                      ? Colors.orange.shade700 : Colors.grey.shade700))),
            // Assign button
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A56DB),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4)),
              onPressed: onAssign,
              icon: const Icon(Icons.link, size: 15),
              label: Text(
                staff.assignedBusNumber == 'Unassigned'
                    ? 'Assign Bus' : 'Change Bus',
                style: const TextStyle(fontSize: 12))),
          ]),

          // Salary row
          Row(children: [
            const Icon(Icons.payments_outlined,
                size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'LKR ${staff.baseSalary.toStringAsFixed(0)} / month',
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 13)),
          ]),
        ]),
      ),
    ),
  );
}

// ── Assign Bus Dialog ─────────────────────────────────────────

class _AssignBusDialog extends ConsumerStatefulWidget {
  final StaffModel staff;
  final VoidCallback onSaved;
  const _AssignBusDialog({required this.staff, required this.onSaved});
  @override
  ConsumerState<_AssignBusDialog> createState() =>
      _AssignBusDialogState();
}

class _AssignBusDialogState extends ConsumerState<_AssignBusDialog> {
  BusModel? _selectedBus;
  bool      _loading = false;
  String?   _error;

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(busListProvider);

    return AlertDialog(
      title: Text('Assign Bus — ${widget.staff.fullName}'),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Current assignment info
          if (widget.staff.assignedBusNumber != 'Unassigned')
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Currently assigned to Bus '
                  '${widget.staff.assignedBusNumber}',
                  style: const TextStyle(fontSize: 13)),
              ])),

          // Bus dropdown
          busesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error:   (e, _) => Text('Error: $e'),
            data: (buses) {
              final active = buses
                  .where((b) => b.isActive).toList();
              return DropdownButtonFormField<BusModel>(
                value: _selectedBus,
                isExpanded: true,
                hint: const Text('Select a bus'),
                decoration: const InputDecoration(
                  labelText: 'Bus',
                  prefixIcon: Icon(Icons.directions_bus, size: 20),
                  border: OutlineInputBorder()),
                items: active.map((b) => DropdownMenuItem(
                  value: b,
                  child: Text(
                    '${b.busNumber} — '
                    '${b.route?.routeName ?? "No route"}',
                    overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (b) => setState(() => _selectedBus = b),
              );
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 12))),
          ],
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedBus == null || _loading)
              ? null
              : () async {
            setState(() { _loading = true; _error = null; });
            try {
              await ref.read(apiServiceProvider).assignStaffToBus(
                widget.staff.staffId, _selectedBus!.busId);
              if (mounted) {
                Navigator.pop(context);
                widget.onSaved();
              }
            } catch (e) {
              setState(() =>
                  _error = e.toString().replaceFirst('Exception: ', ''));
            } finally {
              setState(() => _loading = false);
            }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Assign',
                  style: TextStyle(color: Colors.white))),
      ],
    );
  }
}
