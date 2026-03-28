// ============================================================
// features/authority/screens/authority_dashboard_screen.dart
// Full system overview for Transport Authority
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityDashboardScreen extends ConsumerWidget {
  const AuthorityDashboardScreen({super.key});

  @override
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
    );
  }
}

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
      ]),
    ),
  );
}

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
