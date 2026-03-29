// ============================================================
// features/driver/screens/driver_home_screen.dart
// OOP Abstraction: all data fetched in one dashboard call.
//     Polymorphism: action grid tiles behave differently —
//     active tiles navigate, Coming Soon tiles show a dialog.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/driver_models.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
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
    final async = ref.watch(driverDashboardProvider);
    final size  = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -70,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.2),
                size: 300)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF059669).withOpacity(0.12),
                size: 240)),
        Positioned(top: size.height * 0.4, left: size.width * 0.55,
            child: _Orb(
                color: const Color(0xFF0EA5E9).withOpacity(0.08),
                size: 160)),

        Column(children: [
          // ── App bar ──────────────────────────────────────
          _DarkAppBar(
            onRefresh: () => ref.invalidate(driverDashboardProvider),
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),

          // ── Body ─────────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorBody(
                  error: e.toString().replaceFirst('Exception: ', ''),
                  onRetry: () =>
                      ref.invalidate(driverDashboardProvider)),
              data: (dash) => FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _HomeBody(dash: dash),
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
  final VoidCallback onRefresh, onLogout;
  const _DarkAppBar(
      {required this.onRefresh, required this.onLogout});

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
        child: const Icon(Icons.directions_bus_rounded,
            size: 18, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('RidePulse',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Driver portal',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
      const Spacer(),
      _IconBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
      const SizedBox(width: 4),
      _IconBtn(icon: Icons.logout_rounded, onTap: onLogout),
    ]),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Icon(icon,
          size: 16, color: Colors.white.withOpacity(0.6)),
    ),
  );
}

// ── Home body ─────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final DriverDashboardModel dash;
  const _HomeBody({required this.dash});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [

      // ── Greeting ────────────────────────────────────────
      _GreetingRow(dash: dash),
      const SizedBox(height: 20),

      // ── Today's duty card ────────────────────────────────
      _TodayDutyCard(dash: dash),
      const SizedBox(height: 16),

      // ── Stats row ────────────────────────────────────────
      Row(children: [
        _StatCard(
          label: 'Duty Days',
          value: '${dash.dutyDaysThisMonth}',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF38BDF8),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Welfare',
          value: 'LKR ${dash.welfareThisMonth.toStringAsFixed(0)}',
          icon: Icons.volunteer_activism_rounded,
          color: const Color(0xFF4ADE80),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Balance',
          value:
              'LKR ${dash.totalWelfareBalance.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFFC084FC),
        ),
      ]),

      const SizedBox(height: 24),

      // ── Active features ──────────────────────────────────
      _SectionLabel('My Features'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          _ActiveTile(
            icon: Icons.calendar_month_rounded,
            label: 'Duty Roster',
            subtitle: 'View assignments',
            color: const Color(0xFF38BDF8),
            onTap: () => context.go('/driver/roster')),
          _ActiveTile(
            icon: Icons.payments_rounded,
            label: 'My Income',
            subtitle: 'Salary & earnings',
            color: const Color(0xFF4ADE80),
            onTap: () => context.go('/driver/income')),
          _ActiveTile(
            icon: Icons.volunteer_activism_rounded,
            label: 'Welfare',
            subtitle: 'Monthly balance',
            color: const Color(0xFFC084FC),
            onTap: () => context.go('/driver/welfare')),
          _ActiveTile(
            icon: Icons.play_circle_rounded,
            label: 'Trip',
            subtitle: 'Start / stop trip',
            color: const Color(0xFF34D399),
            onTap: () => context.go('/driver/trip')),
        ],
      ),

      const SizedBox(height: 24),

      // ── Coming soon ──────────────────────────────────────
      Row(children: [
        _SectionLabel('Coming Soon'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFB923C).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFFB923C).withOpacity(0.3)),
          ),
          child: const Text('In Development',
              style: TextStyle(
                  color: Color(0xFFFB923C),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _ComingSoonTile(
          icon: Icons.warning_amber_rounded,
          label: 'Emergency Alert',
          subtitle: 'SOS & incidents',
          color: const Color(0xFFF87171))),
        const SizedBox(width: 12),
        Expanded(child: _ComingSoonTile(
          icon: Icons.badge_rounded,
          label: 'License & Health',
          subtitle: 'Records & renewals',
          color: const Color(0xFFFBBF24))),
      ]),
    ]),
  );
}

// ── Greeting row ──────────────────────────────────────────────

class _GreetingRow extends StatelessWidget {
  final DriverDashboardModel dash;
  const _GreetingRow({required this.dash});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          dash.driverName.isNotEmpty
              ? dash.driverName[0].toUpperCase() : 'D',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
      ),
    ),
    const SizedBox(width: 14),
    Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Text('Hello, ${dash.driverName}!',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3)),
      const SizedBox(height: 2),
      Text('ID: ${dash.employeeId}',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12)),
    ])),
  ]);
}

// ── Today's duty card ─────────────────────────────────────────

class _TodayDutyCard extends StatelessWidget {
  final DriverDashboardModel dash;
  const _TodayDutyCard({required this.dash});

  @override
  Widget build(BuildContext context) {
    final roster  = dash.todayRoster;
    final trip    = dash.activeTrip;
    final isActive = trip?.isInProgress == true;

    // No duty
    if (roster == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_busy_rounded,
                color: Colors.white.withOpacity(0.25), size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('No Duty Today',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 2),
            Text('Check back tomorrow',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12)),
          ]),
        ]),
      );
    }

    final gradColors = isActive
        ? [const Color(0xFF064E3B), const Color(0xFF059669)]
        : [const Color(0xFF1A3A8A), const Color(0xFF1D5ED8)];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: (isActive
                    ? const Color(0xFF059669)
                    : const Color(0xFF1A56DB))
                .withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_bus_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(roster.busNumber,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (isActive) ...[
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(isActive ? 'DRIVING' : 'TODAY',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
            ]),
          ),
        ]),

        const SizedBox(height: 12),
        Text(roster.routeName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.location_on_outlined,
              color: Colors.white.withOpacity(0.6), size: 13),
          const SizedBox(width: 4),
          Text('${roster.startLocation} → ${roster.endLocation}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12)),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          Icon(Icons.access_time_rounded,
              color: Colors.white.withOpacity(0.6), size: 13),
          const SizedBox(width: 4),
          Text('${roster.shiftStart} – ${roster.shiftEnd}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12)),
          const Spacer(),
          Icon(Icons.event_seat_outlined,
              color: Colors.white.withOpacity(0.6), size: 13),
          const SizedBox(width: 4),
          Text('Cap: ${roster.busCapacity}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12)),
        ]),

        if (isActive) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.go('/driver/trip'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Icon(Icons.open_in_new_rounded,
                    size: 15, color: Colors.white),
                const SizedBox(width: 7),
                const Text('Manage Active Trip',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 9,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Active tile ───────────────────────────────────────────────

class _ActiveTile extends StatefulWidget {
  final IconData     icon;
  final String       label, subtitle;
  final Color        color;
  final VoidCallback onTap;
  const _ActiveTile({
    required this.icon, required this.label,
    required this.subtitle, required this.color,
    required this.onTap,
  });
  @override
  State<_ActiveTile> createState() => _ActiveTileState();
}

class _ActiveTileState extends State<_ActiveTile> {
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
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.color.withOpacity(0.22)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon,
                color: widget.color, size: 18),
          ),
          Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
            Text(widget.label,
                style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(widget.subtitle,
                style: TextStyle(
                    color: widget.color.withOpacity(0.55),
                    fontSize: 10)),
          ]),
        ]),
      ),
    ),
  );
}

// ── Coming soon tile ──────────────────────────────────────────

class _ComingSoonTile extends StatelessWidget {
  final IconData icon;
  final String   label, subtitle;
  final Color    color;
  const _ComingSoonTile({
    required this.icon, required this.label,
    required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showComingSoonDialog(context, label),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withOpacity(0.07),
            style: BorderStyle.solid),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Stack(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: Colors.white.withOpacity(0.2),
                size: 18),
          ),
          Positioned(
            right: 0, top: 0,
            child: Container(
              width: 14, height: 14,
              decoration: const BoxDecoration(
                  color: Color(0xFFFB923C),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded,
                  color: Colors.white, size: 8),
            ),
          ),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.18),
                  fontSize: 10)),
        ]),
      ]),
    ),
  );

  void _showComingSoonDialog(
      BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF131C2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFB923C).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFB923C)
                        .withOpacity(0.25)),
              ),
              child: const Icon(
                  Icons.construction_rounded,
                  color: Color(0xFFFB923C), size: 30),
            ),
            const SizedBox(height: 18),
            Text(feature,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
                '$feature is currently under development '
                'and will be available in a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    height: 1.5)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity, height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A56DB),
                      Color(0xFF0EA5E9)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Got it',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
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

class _ErrorBody extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorBody(
      {required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(Icons.cloud_off_rounded,
              color: Colors.white.withOpacity(0.25), size: 28),
        ),
        const SizedBox(height: 16),
        Text('Could not load dashboard',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 6),
        Text(error,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13)),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min,
                children: [
              const Icon(Icons.refresh_rounded,
                  size: 16, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    ),
  );
}