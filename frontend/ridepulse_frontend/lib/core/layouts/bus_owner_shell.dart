// ============================================================
// core/layouts/bus_owner_shell.dart
// Web sidebar shell for Bus Owner — persistent navigation
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class BusOwnerShell extends ConsumerWidget {
  final Widget child;
  const BusOwnerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final loc  = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(children: [
        // ── Sidebar ──────────────────────────────────────────
        SizedBox(
          width: 220,
          child: Container(
            color: const Color(0xFF0F172A),
            child: Column(children: [
              const SizedBox(height: 24),
              // Brand
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.directions_bus_rounded,
                      color: Color(0xFF3B82F6), size: 26),
                  SizedBox(width: 10),
                  Text('RidePulse',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(auth.fullName ?? '',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1E293B), height: 1),
              const SizedBox(height: 8),
              _item(context, Icons.dashboard_outlined,       'Dashboard',  '/bus-owner/dashboard',  loc),
              _item(context, Icons.directions_bus_outlined,  'My Buses',   '/bus-owner/buses',       loc),
              _item(context, Icons.people_outline,           'Staff',      '/bus-owner/staff',       loc),
              _item(context, Icons.event_note_outlined,       'Duty Roster','/bus-owner/roster',      loc),
              _item(context, Icons.location_on_outlined,     'Live Map',   '/bus-owner/live-map',    loc),
              _item(context, Icons.bar_chart_outlined,       'Revenue',    '/bus-owner/revenue',     loc),
              _item(context, Icons.volunteer_activism_outlined,'Welfare',  '/bus-owner/welfare',     loc),
              _item(context, Icons.report_problem_outlined,  'Complaints', '/bus-owner/complaints',  loc),
              const Spacer(),
              const Divider(color: Color(0xFF1E293B), height: 1),
              ListTile(
                leading: const Icon(Icons.logout,
                    color: Color(0xFF94A3B8), size: 20),
                title: const Text('Logout',
                    style: TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 14)),
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        // ── Main content ─────────────────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: child,
          ),
        ),
      ]),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label,
      String route, String loc) {
    final active = loc == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E3A5F) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: active
                ? const Color(0xFF3B82F6)
                : const Color(0xFF64748B),
            size: 20),
        title: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal)),
        dense: true,
        onTap: () => ctx.go(route),
      ),
    );
  }
}
