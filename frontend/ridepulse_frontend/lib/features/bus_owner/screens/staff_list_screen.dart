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
  ConsumerState<StaffListScreen> createState() =>
      _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1220),
    body: Stack(children: [
      // Ambient orbs
      Positioned(top: -50, right: -60,
          child: _Orb(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              size: 280)),
      Positioned(bottom: 80, left: -40,
          child: _Orb(
              color: const Color(0xFFC084FC).withOpacity(0.1),
              size: 220)),

      Column(children: [
        // ── App bar ────────────────────────────────────
        _DarkAppBar(
          onRoster:   () => context.go('/bus-owner/roster'),
          onRegister: () => context.go('/bus-owner/staff/register'),
        ),

        // ── Tab bar ────────────────────────────────────
        _DarkTabBar(controller: _tab),

        // ── Tab views ──────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _StaffTab(staffType: 'driver'),
              _StaffTab(staffType: 'conductor'),
            ],
          ),
        ),
      ]),
    ]),
  );
}

// ── App bar ───────────────────────────────────────────────────

class _DarkAppBar extends StatelessWidget {
  final VoidCallback onRoster, onRegister;
  const _DarkAppBar(
      {required this.onRoster, required this.onRegister});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 12, bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.badge_rounded,
            size: 18, color: Colors.white),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Staff Management',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Drivers & Conductors',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
      const Spacer(),
      _IconBtn(
          icon: Icons.calendar_month_rounded,
          tooltip: 'Duty Roster',
          onTap: onRoster),
      const SizedBox(width: 6),
      _IconBtn(
          icon: Icons.person_add_rounded,
          tooltip: 'Register Staff',
          onTap: onRegister),
    ]),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final String tooltip; final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withOpacity(0.09)),
        ),
        child: Icon(icon,
            size: 16, color: Colors.white.withOpacity(0.6)),
      ),
    ),
  );
}

// ── Tab bar ───────────────────────────────────────────────────

class _DarkTabBar extends StatelessWidget {
  final TabController controller;
  const _DarkTabBar({required this.controller});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      border: Border(
          bottom: BorderSide(
              color: Colors.white.withOpacity(0.07))),
    ),
    child: TabBar(
      controller: controller,
      labelColor: const Color(0xFF0EA5E9),
      unselectedLabelColor: Colors.white.withOpacity(0.3),
      indicatorColor: const Color(0xFF0EA5E9),
      indicatorWeight: 2,
      labelStyle: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 13),
      unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 13),
      tabs: const [
        Tab(
          icon: Icon(Icons.drive_eta_rounded, size: 17),
          text: 'Drivers'),
        Tab(
          icon: Icon(Icons.confirmation_number_rounded, size: 17),
          text: 'Conductors'),
      ],
    ),
  );
}

// ── Staff tab ─────────────────────────────────────────────────

class _StaffTab extends ConsumerStatefulWidget {
  final String staffType;
  const _StaffTab({required this.staffType});
  @override
  ConsumerState<_StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends ConsumerState<_StaffTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showAssignDialog(StaffModel staff) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _AssignBusDialog(
        staff: staff,
        onSaved: () {
          ref.invalidate(staffListProvider(widget.staffType));
          ref.invalidate(busListProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final async = ref.watch(staffListProvider(widget.staffType));
    final color = widget.staffType == 'driver'
        ? const Color(0xFF38BDF8)
        : const Color(0xFFC084FC);

    return async.when(
      loading: () => const _LoadingState(),
      error:   (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', '')),
      data: (list) => list.isEmpty
          ? _EmptyState(
              staffType: widget.staffType,
              onRegister: () =>
                  context.go('/bus-owner/staff/register'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              itemCount: list.length,
              itemBuilder: (_, i) => _StaffCard(
                staff:     list[i],
                color:     color,
                onToggle:  (val) async {
                  await ref.read(apiServiceProvider)
                      .toggleStaffStatus(list[i].staffId, val);
                  ref.invalidate(
                      staffListProvider(widget.staffType));
                },
                onAssign: () => _showAssignDialog(list[i]),
                onTap: () => context.go(
                    '/bus-owner/staff/${list[i].staffId}'),
              ),
            ),
    );
  }
}

// ── Staff card ────────────────────────────────────────────────

class _StaffCard extends StatefulWidget {
  final StaffModel         staff;
  final Color              color;
  final ValueChanged<bool> onToggle;
  final VoidCallback       onAssign, onTap;
  const _StaffCard({
    required this.staff,    required this.color,
    required this.onToggle, required this.onAssign,
    required this.onTap,
  });
  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  bool _pressed = false;

  bool get _isUnassigned =>
      widget.staff.assignedBusNumber == 'Unassigned';

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final color = widget.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: [
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(children: [
                // Avatar
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: (staff.isActive ? color : const Color(0xFF94A3B8))
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: (staff.isActive ? color : const Color(0xFF94A3B8))
                            .withOpacity(0.25)),
                  ),
                  child: Center(
                    child: Text(
                      staff.fullName[0].toUpperCase(),
                      style: TextStyle(
                          color: staff.isActive
                              ? color : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(staff.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(staff.phone,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12)),
                ])),
                // Active toggle
                _DarkSwitch(
                  value:     staff.isActive,
                  onChanged: widget.onToggle,
                  color:     color,
                ),
              ]),
            ),

            Divider(height: 1,
                color: Colors.white.withOpacity(0.06)),

            // ── Bus assignment ───────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(Icons.directions_bus_rounded,
                    size: 14,
                    color: _isUnassigned
                        ? const Color(0xFFFB923C).withOpacity(0.7)
                        : Colors.white.withOpacity(0.3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isUnassigned
                        ? 'Not assigned to any bus'
                        : 'Bus ${staff.assignedBusNumber}',
                    style: TextStyle(
                        color: _isUnassigned
                            ? const Color(0xFFFB923C).withOpacity(0.8)
                            : Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                ),
                // Assign button
                GestureDetector(
                  onTap: widget.onAssign,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: color.withOpacity(0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                      Icon(Icons.link_rounded,
                          size: 12, color: color),
                      const SizedBox(width: 5),
                      Text(
                        _isUnassigned ? 'Assign' : 'Change',
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Salary row ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Icon(Icons.payments_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.25)),
                const SizedBox(width: 8),
                Text(
                  'LKR ${staff.baseSalary.toStringAsFixed(0)} / month',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.white.withOpacity(0.2)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Dark switch ───────────────────────────────────────────────

class _DarkSwitch extends StatelessWidget {
  final bool             value;
  final ValueChanged<bool> onChanged;
  final Color            color;
  const _DarkSwitch(
      {required this.value, required this.onChanged,
      required this.color});

  @override
  Widget build(BuildContext context) => Transform.scale(
    scale: 0.85,
    child: Switch(
      value:      value,
      onChanged:  onChanged,
      activeColor: color,
      activeTrackColor: color.withOpacity(0.25),
      inactiveThumbColor: Colors.white.withOpacity(0.3),
      inactiveTrackColor: Colors.white.withOpacity(0.08),
    ),
  );
}

// ── Assign bus dialog ─────────────────────────────────────────

class _AssignBusDialog extends ConsumerStatefulWidget {
  final StaffModel   staff;
  final VoidCallback onSaved;
  const _AssignBusDialog(
      {required this.staff, required this.onSaved});
  @override
  ConsumerState<_AssignBusDialog> createState() =>
      _AssignBusDialogState();
}

class _AssignBusDialogState
    extends ConsumerState<_AssignBusDialog> {
  BusModel? _selectedBus;
  bool      _loading = false;
  String?   _error;

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(busListProvider);
    final isUnassigned =
        widget.staff.assignedBusNumber == 'Unassigned';

    return Dialog(
      backgroundColor: const Color(0xFF131C2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.link_rounded,
                  size: 17, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Assign Bus — ${widget.staff.fullName}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.close_rounded,
                    size: 14,
                    color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Current assignment info
          if (!isUnassigned) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF0EA5E9).withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF0EA5E9), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Currently assigned to Bus '
                  '${widget.staff.assignedBusNumber}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Bus dropdown
          busesAsync.when(
            loading: () => LinearProgressIndicator(
                color: const Color(0xFF0EA5E9),
                backgroundColor:
                    Colors.white.withOpacity(0.06)),
            error: (e, _) => Text('Error: $e',
                style:
                    TextStyle(color: Colors.red.shade300)),
            data: (buses) {
              final active =
                  buses.where((b) => b.isActive).toList();
              return _DarkDropdown<BusModel>(
                label: 'Select a bus',
                value: _selectedBus,
                items: active,
                displayText: (b) =>
                    '${b.busNumber}  —  '
                    '${b.route?.routeName ?? "No route"}',
                onChanged: (b) =>
                    setState(() => _selectedBus = b),
              );
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: _error!),
          ],

          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text('Cancel',
                        style: TextStyle(
                            color:
                                Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GradientBtn(
                label: 'Assign',
                isLoading: _loading,
                onPressed:
                    (_selectedBus == null || _loading)
                        ? null
                        : () async {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            try {
                              await ref
                                  .read(apiServiceProvider)
                                  .assignStaffToBus(
                                    widget.staff.staffId,
                                    _selectedBus!.busId);
                              if (mounted) {
                                Navigator.pop(context);
                                widget.onSaved();
                              }
                            } catch (e) {
                              setState(() => _error = e
                                  .toString()
                                  .replaceFirst(
                                      'Exception: ', ''));
                            } finally {
                              setState(
                                  () => _loading = false);
                            }
                          },
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────

class _DarkDropdown<T> extends StatelessWidget {
  final String         label;
  final T?             value;
  final List<T>        items;
  final String Function(T) displayText;
  final ValueChanged<T?>  onChanged;
  const _DarkDropdown({
    required this.label,   required this.value,
    required this.items,   required this.displayText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A2540),
        style:
            const TextStyle(color: Colors.white, fontSize: 13),
        icon: Icon(Icons.expand_more_rounded,
            color: Colors.white.withOpacity(0.4), size: 20),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9), width: 1.5)),
        ),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayText(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ))
            .toList(),
        onChanged: onChanged,
      );
}

class _GradientBtn extends StatefulWidget {
  final String     label;
  final bool       isLoading;
  final VoidCallback? onPressed;
  const _GradientBtn({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });
  @override
  State<_GradientBtn> createState() => _GradientBtnState();
}

class _GradientBtnState extends State<_GradientBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onPressed?.call();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: widget.onPressed == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
          ),
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded,
          size: 14, color: Colors.red.shade300),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: TextStyle(
              color: Colors.red.shade300, fontSize: 12))),
    ]),
  );
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color, color.withOpacity(0)]))),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 26, height: 26,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.4),
              strokeWidth: 2)),
      const SizedBox(height: 12),
      Text('Loading staff...',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 36,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load staff',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 12)),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String staffType; final VoidCallback onRegister;
  const _EmptyState(
      {required this.staffType, required this.onRegister});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle),
        child: Icon(Icons.people_outline_rounded, size: 28,
            color: Colors.white.withOpacity(0.2)),
      ),
      const SizedBox(height: 14),
      Text('No ${staffType}s registered yet',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 18),
      GestureDetector(
        onTap: onRegister,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min,
              children: [
            Icon(Icons.person_add_rounded,
                size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text('Register Staff',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ]),
        ),
      ),
    ]),
  );
}