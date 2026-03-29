import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/bus_models.dart';

class BusManagementScreen extends ConsumerStatefulWidget {
  const BusManagementScreen({super.key});
  @override
  ConsumerState<BusManagementScreen> createState() =>
      _BusManagementScreenState();
}

class _BusManagementScreenState
    extends ConsumerState<BusManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showAddBusDialog() => showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _AddBusDialog(
        onSaved: () => ref.invalidate(busListProvider)));

  void _showChangeRouteDialog(BusModel bus) => showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => _ChangeRouteDialog(
        bus: bus, onSaved: () => ref.invalidate(busListProvider)));

  void _confirmDelete(BusModel bus) => showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) => _ConfirmDialog(
      title: 'Deactivate Bus',
      message: 'Deactivate bus ${bus.busNumber}?',
      confirmLabel: 'Deactivate',
      confirmColor: const Color(0xFFF87171),
      onConfirm: () async {
        Navigator.pop(ctx);
        await ref.read(apiServiceProvider).deleteBus(bus.busId);
        ref.invalidate(busListProvider);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(busListProvider);
    final size       = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFFFB923C).withOpacity(0.14),
                size: 280)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.14),
                size: 220)),

        Column(children: [
          _DarkAppBar(),

          Expanded(
            child: busesAsync.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(
                  message: e.toString()
                      .replaceFirst('Exception: ', '')),
              data: (buses) => buses.isEmpty
                  ? _EmptyState(onAdd: _showAddBusDialog)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 16, 16, 100),
                          itemCount: buses.length,
                          itemBuilder: (_, i) => _BusCard(
                            bus: buses[i],
                            onDelete: () =>
                                _confirmDelete(buses[i]),
                            onChangeRoute: () =>
                                _showChangeRouteDialog(buses[i]),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ]),

        // Floating add button
        Positioned(bottom: 24, right: 20,
          child: _AddFab(onTap: _showAddBusDialog),
        ),
      ]),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────

class _DarkAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14),
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
            colors: [Color(0xFFB45309), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_bus_rounded,
            size: 18, color: Colors.white),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Bus Management',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Manage your fleet',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── FAB ───────────────────────────────────────────────────────

class _AddFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFab({required this.onTap});
  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF1A56DB).withOpacity(0.4),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(mainAxisSize: MainAxisSize.min,
            children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Add Bus',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

// ── Bus card ──────────────────────────────────────────────────

class _BusCard extends StatefulWidget {
  final BusModel     bus;
  final VoidCallback onDelete, onChangeRoute;
  const _BusCard({
    required this.bus,
    required this.onDelete,
    required this.onChangeRoute,
  });
  @override
  State<_BusCard> createState() => _BusCardState();
}

class _BusCardState extends State<_BusCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bus         = widget.bus;
    final statusColor = bus.isActive
        ? const Color(0xFF4ADE80)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            // ── Header row ──────────────────────────────
            Row(children: [
              // Bus number badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(bus.busNumber,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(bus.registrationNumber,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 12)),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                    bus.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Route row ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(children: [
                Icon(Icons.route_rounded,
                    size: 14,
                    color: const Color(0xFF38BDF8)
                        .withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      bus.route?.displayName ??
                          'No route assigned',
                      style: TextStyle(
                          color: bus.route != null
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.25),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
                GestureDetector(
                  onTap: widget.onChangeRoute,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF38BDF8)
                              .withOpacity(0.25)),
                    ),
                    child: const Text('Change',
                        style: TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 10),

            // ── Staff row ───────────────────────────────
            Row(children: [
              _StaffChip(
                icon: Icons.drive_eta_rounded,
                name: bus.assignedDriverName,
                color: const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              _StaffChip(
                icon: Icons.confirmation_number_rounded,
                name: bus.assignedConductorName,
                color: const Color(0xFFC084FC)),
              const Spacer(),
              Icon(Icons.event_seat_rounded,
                  size: 13,
                  color: Colors.white.withOpacity(0.25)),
              const SizedBox(width: 4),
              Text('${bus.capacity} seats',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12)),
            ]),

            const SizedBox(height: 10),
            Divider(height: 1,
                color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 6),

            // ── Deactivate ──────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Row(mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 14,
                      color: Colors.red.shade400
                          .withOpacity(0.7)),
                  const SizedBox(width: 5),
                  Text('Deactivate',
                      style: TextStyle(
                          color: Colors.red.shade400
                              .withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StaffChip extends StatelessWidget {
  final IconData icon;
  final String   name;
  final Color    color;
  const _StaffChip(
      {required this.icon, required this.name, required this.color});

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color.withOpacity(0.6)),
    const SizedBox(width: 4),
    Text(name,
        style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 12)),
  ]);
}

// ── Add bus dialog ────────────────────────────────────────────

class _AddBusDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddBusDialog({required this.onSaved});
  @override
  ConsumerState<_AddBusDialog> createState() =>
      _AddBusDialogState();
}

class _AddBusDialogState extends ConsumerState<_AddBusDialog> {
  final _form  = GlobalKey<FormState>();
  final _num   = TextEditingController();
  final _reg   = TextEditingController();
  final _cap   = TextEditingController();
  final _model = TextEditingController();
  RouteModel? _route;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _num.dispose(); _reg.dispose();
    _cap.dispose(); _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).addBus(
        busNumber:          _num.text,
        registrationNumber: _reg.text,
        routeId:            _route!.routeId,
        capacity:           int.parse(_cap.text),
        model: _model.text.isEmpty ? null : _model.text,
      );
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      setState(() => _error =
          e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeDropdownProvider);
    return Dialog(
      backgroundColor: const Color(0xFF131C2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 460,
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
                child: const Icon(Icons.add_rounded,
                    size: 17, color: Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 12),
              const Text('Add New Bus',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 15,
                      color: Colors.white.withOpacity(0.5)),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    _DarkField(
                        controller: _num,
                        label: 'Bus Number',
                        hint: 'e.g. NB-1234'),
                    const SizedBox(height: 12),
                    _DarkField(
                        controller: _reg,
                        label: 'Registration Number',
                        hint: 'e.g. CAB-1234'),
                    const SizedBox(height: 12),
                    _DarkField(
                        controller: _cap,
                        label: 'Capacity',
                        hint: 'e.g. 52',
                        keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    _DarkField(
                        controller: _model,
                        label: 'Model (optional)',
                        hint: 'e.g. Ashok Leyland',
                        required: false),
                    const SizedBox(height: 12),
                    routesAsync.when(
                      loading: () => LinearProgressIndicator(
                          color: const Color(0xFF0EA5E9),
                          backgroundColor:
                              Colors.white.withOpacity(0.06)),
                      error: (e, _) => Text('Error: $e',
                          style: TextStyle(
                              color: Colors.red.shade300)),
                      data: (routes) =>
                          _DarkDropdown<RouteModel>(
                        label: 'Select Route',
                        value: _route,
                        items: routes,
                        displayText: (r) => r.displayName,
                        onChanged: (r) =>
                            setState(() => _route = r),
                        validator: (_) => _route == null
                            ? 'Please select a route'
                            : null,
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _error!),
                    ],
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions
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
                  label: 'Add Bus',
                  isLoading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Change route dialog ───────────────────────────────────────

class _ChangeRouteDialog extends ConsumerStatefulWidget {
  final BusModel     bus;
  final VoidCallback onSaved;
  const _ChangeRouteDialog(
      {required this.bus, required this.onSaved});
  @override
  ConsumerState<_ChangeRouteDialog> createState() =>
      _ChangeRouteDialogState();
}

class _ChangeRouteDialogState
    extends ConsumerState<_ChangeRouteDialog> {
  RouteModel? _route;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(routeDropdownProvider);
    return Dialog(
      backgroundColor: const Color(0xFF131C2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route_rounded,
                  size: 16, color: Color(0xFF38BDF8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Change Route — ${widget.bus.busNumber}',
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
                    size: 15,
                    color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          routesAsync.when(
            loading: () => LinearProgressIndicator(
                color: const Color(0xFF0EA5E9),
                backgroundColor:
                    Colors.white.withOpacity(0.06)),
            error: (e, _) => Text('Error: $e',
                style:
                    TextStyle(color: Colors.red.shade300)),
            data: (routes) => _DarkDropdown<RouteModel>(
              label: 'Select new route',
              value: _route,
              items: routes,
              displayText: (r) => r.displayName,
              onChanged: (r) => setState(() => _route = r),
            ),
          ),
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
                label: 'Update',
                isLoading: _loading,
                onPressed: (_route == null || _loading)
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        await ref
                            .read(apiServiceProvider)
                            .updateBusRoute(
                                widget.bus.busId,
                                _route!.routeId);
                        if (mounted) {
                          Navigator.pop(context);
                          widget.onSaved();
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

// ── Confirm dialog ────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String       title, message, confirmLabel;
  final Color        confirmColor;
  final VoidCallback onConfirm;
  const _ConfirmDialog({
    required this.title,    required this.message,
    required this.confirmLabel, required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xFF131C2E),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min,
          children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: confirmColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: confirmColor.withOpacity(0.25)),
          ),
          child: Icon(Icons.warning_amber_rounded,
              color: confirmColor, size: 26),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 14)),
        const SizedBox(height: 22),
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
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: confirmColor.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(confirmLabel,
                      style: TextStyle(
                          color: confirmColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
        ]),
      ]),
    ),
  );
}

// ── Shared form widgets ───────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final bool   required;
  final TextInputType keyboard;
  const _DarkField({
    required this.controller,
    required this.label,
    required this.hint,
    this.required = true,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    validator: required
        ? (v) => (v == null || v.trim().isEmpty)
            ? '$label required' : null
        : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.4), fontSize: 13),
      hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.18), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF0EA5E9), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Colors.red.shade400.withOpacity(0.6))),
      errorStyle:
          TextStyle(color: Colors.red.shade300, fontSize: 12),
    ),
  );
}

class _DarkDropdown<T> extends StatelessWidget {
  final String         label;
  final T?             value;
  final List<T>        items;
  final String Function(T) displayText;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  const _DarkDropdown({
    required this.label,    required this.value,
    required this.items,    required this.displayText,
    required this.onChanged, this.validator,
  });

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A2540),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        icon: Icon(Icons.expand_more_rounded,
            color: Colors.white.withOpacity(0.4), size: 20),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 13),
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
          errorStyle: TextStyle(
              color: Colors.red.shade300, fontSize: 12),
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
  final String   label;
  final bool     isLoading;
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
      Expanded(
        child: Text(message,
            style: TextStyle(
                color: Colors.red.shade300, fontSize: 12)),
      ),
    ]),
  );
}

// ── Utility ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.3))),
    const SizedBox(width: 10),
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
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
      Text('Loading buses...',
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
        Icon(Icons.error_outline_rounded, size: 38,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load buses',
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
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle),
        child: Icon(Icons.directions_bus_rounded,
            size: 28, color: Colors.white.withOpacity(0.2)),
      ),
      const SizedBox(height: 14),
      Text('No buses yet',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 18),
      GestureDetector(
        onTap: onAdd,
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
            Icon(Icons.add_rounded,
                size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text('Add Your First Bus',
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