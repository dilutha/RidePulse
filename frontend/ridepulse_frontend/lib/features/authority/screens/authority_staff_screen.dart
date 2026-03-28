// ============================================================
// features/authority/screens/authority_staff_screen.dart
// All drivers and conductors with tabs
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityStaffScreen extends ConsumerStatefulWidget {
  const AuthorityStaffScreen({super.key});
  @override
  ConsumerState<AuthorityStaffScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityStaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = "";

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: const Text("Staff Directory"),
      bottom: TabBar(controller: _tab,
        labelColor: const Color(0xFF1E40AF),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF1E40AF),
        tabs: const [
          Tab(icon: Icon(Icons.drive_eta, size: 17), text: "Drivers"),
          Tab(icon: Icon(Icons.person, size: 17), text: "Conductors"),
        ]),
    ),
    body: Column(children: [
      Container(color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: "Search by name, ID or bus...",
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true, fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16)))),
      const Divider(height: 1),
      Expanded(child: TabBarView(controller: _tab, children: [
        _StaffList(
            provider: authorityDriversProvider,
            search: _search,
            color: const Color(0xFF1E40AF)),
        _StaffList(
            provider: authorityConductorsProvider,
            search: _search,
            color: const Color(0xFFB45309)),
      ])),
    ]),
  );
}

class _StaffList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<AuthorityStaff>>> provider;
  final String search;
  final Color color;
  const _StaffList({required this.provider, required this.search,
      required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:   (e, _) => Center(child: Text("Error: \$e")),
      data: (list) {
        final filtered = search.isEmpty ? list
            : list.where((s) =>
                s.fullName.toLowerCase().contains(search) ||
                s.employeeId.toLowerCase().contains(search) ||
                (s.assignedBusNumber?.toLowerCase().contains(search) ?? false) ||
                (s.ownerName?.toLowerCase().contains(search) ?? false))
            .toList();

        if (filtered.isEmpty) return const Center(
            child: Text("No staff found",
                style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _StaffCard(s: filtered[i], color: color));
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  final AuthorityStaff s;
  final Color color;
  const _StaffCard({required this.s, required this.color});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
      CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Text(s.fullName.isNotEmpty
            ? s.fullName[0].toUpperCase() : "?",
            style: TextStyle(color: color,
                fontWeight: FontWeight.bold))),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(s.fullName, style: const TextStyle(
              fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          if (!s.isActive)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text("Inactive", style: TextStyle(
                  color: Colors.red, fontSize: 10))),
        ]),
        Text("ID: \${s.employeeId}  ·  \${s.phone}",
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12)),
        if (s.ownerBusinessName != null)
          Text("Owner: \${s.ownerBusinessName}",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: (s.assignedBusNumber != null &&
                          s.assignedBusNumber != "Unassigned")
                  ? color.withOpacity(0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: Text(
              s.assignedBusNumber ?? "Unassigned",
              style: TextStyle(
                  color: (s.assignedBusNumber != null &&
                              s.assignedBusNumber != "Unassigned")
                      ? color : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 11))),
        if (s.licenseNumber != null) ...[
          const SizedBox(height: 4),
          Text(s.licenseNumber!,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 10)),
        ],
      ]),
    ])),
  );
}
