// ============================================================
// features/authority/screens/authority_owners_screen.dart
// All bus owners with fleet summary
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityOwnersScreen extends ConsumerStatefulWidget {
  const AuthorityOwnersScreen({super.key});
  @override
  ConsumerState<AuthorityOwnersScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityOwnersScreen> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(authorityOwnersProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Bus Owners"),
        actions: [IconButton(icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(authorityOwnersProvider))]),
      body: Column(children: [
        Container(color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search by name, business or NIC...",
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true, fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 16)))),
        const Divider(height: 1),
        Expanded(child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text("Error: \$e")),
          data: (owners) {
            final f = _search.isEmpty ? owners
                : owners.where((o) =>
                    o.fullName.toLowerCase().contains(_search) ||
                    o.businessName.toLowerCase().contains(_search) ||
                    o.nicNumber.toLowerCase().contains(_search)).toList();
            if (f.isEmpty) return const Center(
                child: Text("No owners found",
                    style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: f.length,
              itemBuilder: (_, i) => _OwnerCard(owner: f[i]));
          },
        )),
      ]),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final AuthorityOwner owner;
  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF1E40AF).withOpacity(0.1),
          radius: 20,
          child: Text(owner.fullName[0].toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.bold))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(owner.businessName, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15)),
          Text(owner.fullName, style: TextStyle(
              color: Colors.grey.shade600, fontSize: 13)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("NIC: \${owner.nicNumber}",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11)),
          if (owner.registeredAt != null)
            Text("Since: \${owner.registeredAt!.substring(0, 10)}",
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 10)),
        ]),
      ]),
      const Divider(height: 16),
      Row(children: [
        _Stat("Total Buses",  "\${owner.totalBuses}",
            Icons.directions_bus, const Color(0xFF1E40AF)),
        const SizedBox(width: 16),
        _Stat("Active",       "\${owner.activeBuses}",
            Icons.check_circle_outline, const Color(0xFF059669)),
        const SizedBox(width: 16),
        _Stat("Staff",        "\${owner.totalStaff}",
            Icons.people_outline, const Color(0xFFB45309)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(owner.phone, style: TextStyle(
            color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(width: 16),
        const Icon(Icons.email_outlined, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(owner.email,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            overflow: TextOverflow.ellipsis)),
      ]),
    ])),
  );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    const SizedBox(width: 2),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
  ]);
}
