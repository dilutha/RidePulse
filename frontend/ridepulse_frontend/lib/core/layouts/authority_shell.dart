// ============================================================
// core/layouts/authority_shell.dart
// Web sidebar shell for Transport Authority
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AuthorityShell extends ConsumerWidget {
  final Widget child;
  const AuthorityShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final loc  = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(children: [
        SizedBox(
          width: 220,
          child: Container(
            color: const Color(0xFF1E1B4B),
            child: Column(children: [
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      color: Color(0xFFA78BFA), size: 26),
                  SizedBox(width: 10),
                  Text('Authority',
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
              const Divider(color: Color(0xFF312E81), height: 1),
              const SizedBox(height: 8),
              _item(context, Icons.dashboard_outlined,
                  'Dashboard',   '/authority/dashboard',   loc),
              _item(context, Icons.report_problem_outlined,
                  'Complaints',  '/authority/complaints',  loc),
              _item(context, Icons.route_outlined,
                    'Route Optimization',
                    '/authority/route-optimization', loc),
              const Spacer(),
              const Divider(color: Color(0xFF312E81), height: 1),
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
        Expanded(
          child: Container(color: const Color(0xFFF8FAFC), child: child),
        ),
      ]),
    );
  }

  Widget _item(BuildContext ctx, IconData icon, String label,
      String route, String loc) {
    final active = loc.startsWith(route);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2D2A6E) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: active
                ? const Color(0xFFA78BFA)
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
