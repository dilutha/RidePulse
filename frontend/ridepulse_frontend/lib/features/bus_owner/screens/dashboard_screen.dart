import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';

class BusOwnerDashboardScreen extends ConsumerStatefulWidget {
  const BusOwnerDashboardScreen({super.key});
  @override
  ConsumerState<BusOwnerDashboardScreen> createState() =>
      _BusOwnerDashboardScreenState();
}

class _BusOwnerDashboardScreenState
    extends ConsumerState<BusOwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busesAsync = ref.watch(busListProvider);
    final size       = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs — orange identity for bus owner
        Positioned(top: -50, right: -70,
            child: _Orb(
                color: const Color(0xFFFB923C).withOpacity(0.14),
                size: 300)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.15),
                size: 240)),
        Positioned(top: size.height * 0.45, left: size.width * 0.5,
            child: _Orb(
                color: const Color(0xFF4ADE80).withOpacity(0.07),
                size: 180)),

        Column(children: [
          // ── App bar ──────────────────────────────────────
          _DarkAppBar(),

          // ── Body ─────────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: busesAsync.when(
                  loading: () => const _LoadingState(),
                  error:   (e, _) => _ErrorState(
                      message: e.toString()
                          .replaceFirst('Exception: ', '')),
                  data: (buses) => _DashBody(buses: buses),
                ),
              ),
            ),
          ),
        ]),
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.directions_bus_rounded,
            size: 20, color: Colors.white),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Dashboard',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3)),
        Text('Bus owner portal',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Main dashboard body ───────────────────────────────────────

class _DashBody extends StatelessWidget {
  final List<dynamic> buses;
  const _DashBody({required this.buses});

  @override
  Widget build(BuildContext context) {
    final totalBuses  = buses.length;
    final activeBuses = buses.where((b) => b.isActive).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

        // ── Stats row ──────────────────────────────────
        Row(children: [
          _StatCard(
            label: 'Total Buses',
            value: '$totalBuses',
            icon: Icons.directions_bus_rounded,
            color: const Color(0xFF38BDF8),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Active Buses',
            value: '$activeBuses',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF4ADE80),
          ),
        ]),

        const SizedBox(height: 26),

        // ── Quick actions ──────────────────────────────
        _SectionLabel('Quick Actions'),
        const SizedBox(height: 12),
        Row(children: [
          _ActionBtn(
            label: 'Add Bus',
            icon: Icons.add_rounded,
            color: const Color(0xFF38BDF8),
            onTap: () => context.go('/bus-owner/buses')),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'Register Staff',
            icon: Icons.person_add_rounded,
            color: const Color(0xFFC084FC),
            onTap: () =>
                context.go('/bus-owner/staff/register')),
          const SizedBox(width: 10),
          _ActionBtn(
            label: 'Live Map',
            icon: Icons.location_on_rounded,
            color: const Color(0xFF4ADE80),
            onTap: () => context.go('/bus-owner/live-map')),
        ]),

        const SizedBox(height: 28),

        // ── Fleet list ─────────────────────────────────
        Row(children: [
          _SectionLabel('Your Fleet'),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF4ADE80).withOpacity(0.25)),
            ),
            child: Text('$activeBuses active',
                style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),

        if (buses.isEmpty)
          _EmptyFleet()
        else
          ...buses.map((bus) => _BusSummaryCard(
            busNumber: bus.busNumber,
            route:     bus.route?.displayName ?? 'No route',
            driver:    bus.assignedDriverName,
            conductor: bus.assignedConductorName,
            isActive:  bus.isActive,
          )),
      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _StatCard({
    required this.label, required this.value,
    required this.icon,  required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11)),
        ]),
      ]),
    ),
  );
}

// ── Action button ─────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });
  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: widget.color.withOpacity(0.2)),
          ),
          child: Column(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(widget.icon,
                  color: widget.color, size: 17),
            ),
            const SizedBox(height: 8),
            Text(widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: widget.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  );
}

// ── Bus summary card ──────────────────────────────────────────

class _BusSummaryCard extends StatefulWidget {
  final String busNumber, route, driver, conductor;
  final bool   isActive;
  const _BusSummaryCard({
    required this.busNumber, required this.route,
    required this.driver,    required this.conductor,
    required this.isActive,
  });
  @override
  State<_BusSummaryCard> createState() => _BusSummaryCardState();
}

class _BusSummaryCardState extends State<_BusSummaryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isActive
        ? const Color(0xFF4ADE80)
        : const Color(0xFF94A3B8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(children: [
            // Bus icon badge
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: statusColor.withOpacity(0.25)),
              ),
              child: Icon(Icons.directions_bus_rounded,
                  color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Route info
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(widget.busNumber,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: statusColor.withOpacity(0.25)),
                    ),
                    child: Text(
                        widget.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(widget.route,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12)),
              ]),
            ),

            // Staff info
            Column(crossAxisAlignment: CrossAxisAlignment.end,
                children: [
              _StaffTag(
                  name: widget.driver,
                  icon: Icons.person_rounded,
                  color: const Color(0xFF38BDF8)),
              const SizedBox(height: 4),
              _StaffTag(
                  name: widget.conductor,
                  icon: Icons.confirmation_number_rounded,
                  color: const Color(0xFFC084FC)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _StaffTag extends StatelessWidget {
  final String   name;
  final IconData icon;
  final Color    color;
  const _StaffTag(
      {required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(
      mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: color.withOpacity(0.6)),
    const SizedBox(width: 4),
    Text(name,
        style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11)),
  ]);
}

// ── Utility widgets ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.3))),
    const SizedBox(width: 10),
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _EmptyFleet extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.directions_bus_rounded,
              size: 26,
              color: Colors.white.withOpacity(0.2)),
        ),
        const SizedBox(height: 12),
        Text('No buses registered',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Tap "Add Bus" to get started',
            style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12)),
      ]),
    ),
  );
}

class _Orb extends StatelessWidget {
  final Color  color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withOpacity(0)]),
      ),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.4),
              strokeWidth: 2)),
      const SizedBox(height: 14),
      Text('Loading dashboard...',
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
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.red.withOpacity(0.2)),
          ),
          child: Icon(Icons.error_outline_rounded,
              color: Colors.red.shade300, size: 26),
        ),
        const SizedBox(height: 14),
        Text('Failed to load',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.28),
                fontSize: 12)),
      ]),
    ),
  );
}