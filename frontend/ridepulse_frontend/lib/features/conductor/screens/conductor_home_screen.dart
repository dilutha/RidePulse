import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class ConductorHomeScreen extends ConsumerStatefulWidget {
  const ConductorHomeScreen({super.key});
  @override
  ConsumerState<ConductorHomeScreen> createState() =>
      _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends ConsumerState<ConductorHomeScreen>
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
    final async = ref.watch(conductorDashboardProvider);
    final size  = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs — amber/orange tint for conductor identity
        Positioned(top: -50, right: -70,
            child: _Orb(
                color: const Color(0xFFFB923C).withOpacity(0.14),
                size: 300)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.15),
                size: 240)),
        Positioned(top: size.height * 0.42, left: size.width * 0.52,
            child: _Orb(
                color: const Color(0xFFFBBF24).withOpacity(0.07),
                size: 180)),

        Column(children: [
          // ── App bar ──────────────────────────────────────
          _DarkAppBar(
            onRefresh: () =>
                ref.invalidate(conductorDashboardProvider),
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
                  error: e.toString()
                      .replaceFirst('Exception: ', ''),
                  onRetry: () =>
                      ref.invalidate(conductorDashboardProvider)),
              data: (dashboard) => FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _DashboardBody(dashboard: dashboard),
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
            colors: [Color(0xFFB45309), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.confirmation_number_rounded,
            size: 17, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Conductor Panel',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('RidePulse',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
      const Spacer(),
      _IconBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
      const SizedBox(width: 6),
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

// ── Dashboard body ────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final ConductorDashboardModel dashboard;
  const _DashboardBody({required this.dashboard});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [

      // ── Greeting ───────────────────────────────────────
      _GreetingRow(dashboard: dashboard),
      const SizedBox(height: 20),

      // ── Today's duty card ──────────────────────────────
      _TodayDutyCard(dashboard: dashboard),
      const SizedBox(height: 16),

      // ── Stats row ──────────────────────────────────────
      Row(children: [
        _StatCard(
          label: 'Duty Days',
          value: '${dashboard.dutyDaysThisMonth}',
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF38BDF8),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Tickets',
          value: '${dashboard.ticketsIssuedThisMonth}',
          icon: Icons.confirmation_number_rounded,
          color: const Color(0xFF4ADE80),
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Welfare',
          value:
              'LKR ${dashboard.welfareThisMonth.toStringAsFixed(0)}',
          icon: Icons.volunteer_activism_rounded,
          color: const Color(0xFFC084FC),
        ),
      ]),

      const SizedBox(height: 24),

      // ── Quick actions ──────────────────────────────────
      _SectionLabel('Quick Actions'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _ActionCard(
            icon: Icons.play_circle_rounded,
            label: 'Start / Stop Trip',
            color: const Color(0xFF4ADE80),
            onTap: () => context.go('/conductor/trip')),
          _ActionCard(
            icon: Icons.confirmation_number_rounded,
            label: 'Issue Ticket',
            color: const Color(0xFF38BDF8),
            enabled:
                dashboard.activeTrip?.isInProgress == true,
            onTap: () =>
                context.go('/conductor/ticket/issue')),
          _ActionCard(
            icon: Icons.calendar_month_rounded,
            label: 'My Roster',
            color: const Color(0xFFFBBF24),
            onTap: () => context.go('/conductor/roster')),
          _ActionCard(
            icon: Icons.volunteer_activism_rounded,
            label: 'Welfare',
            color: const Color(0xFFC084FC),
            onTap: () => context.go('/conductor/welfare')),
        ],
      ),
    ]),
  );
}

// ── Greeting ──────────────────────────────────────────────────

class _GreetingRow extends StatelessWidget {
  final ConductorDashboardModel dashboard;
  const _GreetingRow({required this.dashboard});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          dashboard.conductorName.isNotEmpty
              ? dashboard.conductorName[0].toUpperCase()
              : 'C',
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
      Text('Hello, ${dashboard.conductorName}!',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3)),
      const SizedBox(height: 2),
      Text('ID: ${dashboard.employeeId}',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12)),
    ])),
  ]);
}

// ── Today's duty card ─────────────────────────────────────────

class _TodayDutyCard extends StatelessWidget {
  final ConductorDashboardModel dashboard;
  const _TodayDutyCard({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final roster   = dashboard.todayRoster;
    final trip     = dashboard.activeTrip;
    final isLive   = trip?.isInProgress == true;

    if (roster == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.08)),
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
            Text('No roster assignment for today',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12)),
          ]),
        ]),
      );
    }

    final gradColors = isLive
        ? [const Color(0xFF064E3B), const Color(0xFF059669)]
        : [const Color(0xFF78350F), const Color(0xFFB45309)];

    final accentColor = isLive
        ? const Color(0xFF059669)
        : const Color(0xFFFB923C);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Bus + status badge
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
              if (isLive) ...[
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(isLive ? 'LIVE' : roster.status.toUpperCase(),
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
        const SizedBox(height: 5),
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
          if (trip != null) ...[
            const Spacer(),
            Icon(Icons.confirmation_number_rounded,
                color: Colors.white.withOpacity(0.6), size: 13),
            const SizedBox(width: 4),
            Text('Tickets: ${trip.ticketsIssuedCount}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12)),
          ],
        ]),

        if (isLive) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.go('/conductor/trip'),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
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
      padding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: 10),
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

// ── Action card ───────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;
  final bool         enabled;
  const _ActionCard({
    required this.icon,  required this.label,
    required this.color, required this.onTap,
    this.enabled = true,
  });
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled
        ? (_) => setState(() => _pressed = true) : null,
    onTapUp: widget.enabled
        ? (_) {
            setState(() => _pressed = false);
            widget.onTap();
          }
        : null,
    onTapCancel: widget.enabled
        ? () => setState(() => _pressed = false) : null,
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.color.withOpacity(0.22)),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(widget.icon,
                  color: widget.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
        ),
      ),
    ),
  );
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
            color: Colors.red.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.red.withOpacity(0.2)),
          ),
          child: Icon(Icons.error_outline_rounded,
              color: Colors.red.shade300, size: 28),
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
                colors: [
                  Color(0xFFB45309),
                  Color(0xFFFB923C)
                ],
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