// ============================================================
// features/authority/screens/authority_dashboard_screen.dart
// Full system overview for Transport Authority
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityDashboardScreen extends ConsumerStatefulWidget {
  const AuthorityDashboardScreen({super.key});
  @override
  ConsumerState<AuthorityDashboardScreen> createState() =>
      _AuthorityDashboardScreenState();
}

class _AuthorityDashboardScreenState
    extends ConsumerState<AuthorityDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
<<<<<<< Updated upstream
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(authorityDashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(authorityDashboardStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Authority Dashboard",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Transport Authority System Overview",
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 22),

            statsAsync.when(
              loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator())),
              error: (e, _) => _ErrCard(e.toString()),
              data: (s) => Column(children: [
                // Fleet row
                _SectionTitle("Fleet Overview"),
                const SizedBox(height: 10),
                Row(children: [
                  _BigStat("Total Buses",   "${s.totalBuses}",
                      Icons.directions_bus_outlined, const Color(0xFF1E40AF),
                      onTap: () => context.go("/authority/buses")),
                  const SizedBox(width: 12),
                  _BigStat("Active Buses",  "${s.activeBuses}",
                      Icons.check_circle_outline, const Color(0xFF059669)),
                  const SizedBox(width: 12),
                  _BigStat("On Trip Now",   "${s.busesOnTrip}",
                      Icons.play_circle_outline, const Color(0xFF7C3AED)),
                ]),
                const SizedBox(height: 16),

                // Staff row
                _SectionTitle("Staff"),
                const SizedBox(height: 10),
                Row(children: [
                  _BigStat("Drivers",     "${s.totalDrivers}",
                      Icons.drive_eta_outlined, const Color(0xFF0369A1),
                      onTap: () => context.go("/authority/staff")),
                  const SizedBox(width: 12),
                  _BigStat("Conductors", "${s.totalConductors}",
                      Icons.person_outlined, const Color(0xFFB45309)),
                  const SizedBox(width: 12),
                  _BigStat("Bus Owners", "${s.totalBusOwners}",
                      Icons.business_outlined, const Color(0xFF6B7280),
                      onTap: () => context.go("/authority/owners")),
                ]),
                const SizedBox(height: 16),

                // Complaints row
                _SectionTitle("Complaints"),
                const SizedBox(height: 10),
                Row(children: [
                  _BigStat("Total",    "${s.totalComplaints}",
                      Icons.report_problem_outlined, Colors.grey,
                      onTap: () => context.go("/authority/complaints")),
                  const SizedBox(width: 12),
                  _BigStat("Open",     "${s.openComplaints}",
                      Icons.pending_outlined, const Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  _BigStat("Resolved", "${s.resolvedComplaints}",
                      Icons.check_circle_outlined, const Color(0xFF059669)),
                ]),
                const SizedBox(height: 20),

                // Quick actions
                _SectionTitle("Quick Actions"),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10, mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                  children: [
                    _QuickAction("Buses",
                        Icons.directions_bus,
                        const Color(0xFF1E40AF),
                        () => context.go("/authority/buses")),
                    _QuickAction("Staff",
                        Icons.people,
                        const Color(0xFF0369A1),
                        () => context.go("/authority/staff")),
                    _QuickAction("Owners",
                        Icons.business,
                        const Color(0xFF6B7280),
                        () => context.go("/authority/owners")),
                    _QuickAction("Complaints",
                        Icons.report_problem,
                        const Color(0xFFD97706),
                        () => context.go("/authority/complaints")),
                    _QuickAction("Bus Fares",
                        Icons.payments,
                        const Color(0xFF059669),
                        () => context.go("/authority/fares")),
                    _QuickAction("Route Opt.",
                        Icons.route,
                        const Color(0xFF7C3AED),
                        () => context.go("/authority/route-optimization")),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      ),
=======
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
  Widget build(BuildContext context, ) {
    final statsAsync = ref.watch(complaintStatsProvider);
    final size       = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -70,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.2), size: 300)),
        Positioned(bottom: 60, left: -50,
            child: _Orb(
                color: const Color(0xFF0EA5E9).withOpacity(0.1), size: 220)),
        Positioned(top: size.height * 0.45, left: size.width * 0.5,
            child: _Orb(
                color: const Color(0xFF6330B4).withOpacity(0.1), size: 160)),

        // Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ── Header ───────────────────────────────────
                  _DashHeader(),
                  const SizedBox(height: 28),

                  statsAsync.when(
                    loading: () => const _LoadingState(),
                    error:   (e, _) => _ErrorState(message: e.toString()),
                    data: (stats) => _DashContent(
                      stats: stats,
                      onViewAll: () =>
                          context.go('/authority/complaints'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
>>>>>>> Stashed changes
    );
  }
}

<<<<<<< Updated upstream
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
          color: Color(0xFF374151)));
}

class _BigStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _BigStat(this.label, this.value, this.icon, this.color,
      {this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: color)),
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 10)),
        ]),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w500)),
=======
// ── Header ────────────────────────────────────────────────────

class _DashHeader extends StatelessWidget {
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.admin_panel_settings_rounded,
          color: Colors.white, size: 22),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Authority Dashboard',
          style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3)),
      Text('Complaints overview',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 13)),
    ]),
  ]);
}

// ── Main data content ─────────────────────────────────────────

class _DashContent extends StatelessWidget {
  final ComplaintStats stats;
  final VoidCallback   onViewAll;
  const _DashContent({required this.stats, required this.onViewAll});

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    // ── Section label ─────────────────────────────────────
    _SectionLabel('Overview'),
    const SizedBox(height: 12),

    // ── Stat grid ─────────────────────────────────────────
    // Row 1: Total + Submitted
    Row(children: [
      Expanded(child: _StatCard(
        label: 'Total',
        value: stats.totalComplaints.toString(),
        icon: Icons.inbox_rounded,
        color: const Color(0xFF0EA5E9),
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        label: 'Submitted',
        value: stats.submitted.toString(),
        icon: Icons.mark_email_unread_rounded,
        color: const Color(0xFF94A3B8),
      )),
    ]),
    const SizedBox(height: 10),
    // Row 2: Under Review + Resolved + Rejected
    Row(children: [
      Expanded(child: _StatCard(
        label: 'Under Review',
        value: stats.underReview.toString(),
        icon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFFFBBF24),
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        label: 'Resolved',
        value: stats.resolved.toString(),
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF4ADE80),
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        label: 'Rejected',
        value: stats.rejected.toString(),
        icon: Icons.cancel_rounded,
        color: const Color(0xFFF87171),
      )),
    ]),

    const SizedBox(height: 28),

    // ── Category breakdown ────────────────────────────────
    _SectionLabel('By Category'),
    const SizedBox(height: 14),

    _GlassCard(child: Column(children: [
      _CatBar('Safety',          stats.safetyCount,
          stats.totalComplaints, const Color(0xFFF87171),
          Icons.warning_rounded),
      _CatBar('Driver Behavior', stats.driverBehaviorCount,
          stats.totalComplaints, const Color(0xFFFBBF24),
          Icons.person_rounded),
      _CatBar('Delay',           stats.delayCount,
          stats.totalComplaints, const Color(0xFF38BDF8),
          Icons.schedule_rounded),
      _CatBar('Crowding',        stats.crowdingCount,
          stats.totalComplaints, const Color(0xFFC084FC),
          Icons.people_rounded),
      _CatBar('Cleanliness',     stats.cleanlinessCount,
          stats.totalComplaints, const Color(0xFF4ADE80),
          Icons.cleaning_services_rounded),
      _CatBar('Other',           stats.otherCount,
          stats.totalComplaints, const Color(0xFF94A3B8),
          Icons.more_horiz_rounded,
          isLast: true),
    ])),

    const SizedBox(height: 28),

    // ── CTA button ────────────────────────────────────────
    _ViewAllButton(onTap: onViewAll),
  ]);
}

// ── Stat card ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String   label, value;
  final Color    color;
  final IconData icon;
  const _StatCard({
    required this.label, required this.value,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        Icon(Icons.trending_up_rounded,
            size: 14, color: color.withOpacity(0.4)),
      ]),
      const SizedBox(height: 10),
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Category bar ──────────────────────────────────────────────

class _CatBar extends StatelessWidget {
  final String   label;
  final int      count, total;
  final Color    color;
  final IconData icon;
  final bool     isLast;

  const _CatBar(this.label, this.count, this.total,
      this.color, this.icon, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          // Icon
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          // Label
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          // Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(children: [
                // Track
                Container(
                    height: 6,
                    color: Colors.white.withOpacity(0.06)),
                // Fill — animated
                FractionallySizedBox(
                  widthFactor: pct,
                  child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      )),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // Count
          SizedBox(
            width: 28,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      if (!isLast)
        Divider(height: 1, color: Colors.white.withOpacity(0.05)),
    ]);
  }
}

// ── View all button ───────────────────────────────────────────

class _ViewAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});
  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
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
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Icon(Icons.list_alt_rounded,
              size: 18, color: Colors.white),
          const SizedBox(width: 10),
          const Text('View All Complaints',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1)),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Shared utility widgets
// ═══════════════════════════════════════════════════════════════

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.09)),
    ),
    child: child,
  );
}

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
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: Center(
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
>>>>>>> Stashed changes
      ]),
    ),
  );
}

<<<<<<< Updated upstream
class _ErrCard extends StatelessWidget {
  final String msg;
  const _ErrCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10)),
    child: Text(msg, style: const TextStyle(color: Colors.red)));
}
=======
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load stats',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 12)),
      ]),
    ),
  );
}
>>>>>>> Stashed changes
