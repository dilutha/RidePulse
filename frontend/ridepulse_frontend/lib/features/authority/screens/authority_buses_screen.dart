// ============================================================
// features/authority/screens/authority_buses_screen.dart
// All buses with live GPS, crowd, owner and route info
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityBusesScreen extends ConsumerStatefulWidget {
  const AuthorityBusesScreen({super.key});
  @override
  ConsumerState<AuthorityBusesScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityBusesScreen> {
  String _search = "";
  String _filter = "all";  // all | active | on_trip

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(authorityBusesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("All Buses"),
          actions: [IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(authorityBusesProvider))]),
      body: Column(children: [
        // Search + filter bar
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search bus, owner, route...",
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true, fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              _chip("All",     "all"),
              const SizedBox(width: 8),
              _chip("Active",  "active"),
              const SizedBox(width: 8),
              _chip("On Trip", "on_trip"),
            ]),
          ])),
        const Divider(height: 1),
        Expanded(child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text("Error: \$e")),
          data: (buses) {
            final filtered = buses.where((b) {
              if (_filter == "active"  && !b.isActive) return false;
              if (_filter == "on_trip" && !b.isOnTrip) return false;
              if (_search.isNotEmpty) {
                return b.busNumber.toLowerCase().contains(_search) ||
                    b.ownerName.toLowerCase().contains(_search) ||
                    b.routeName.toLowerCase().contains(_search) ||
                    b.registrationNumber.toLowerCase().contains(_search);
              }
              return true;
            }).toList();

            if (filtered.isEmpty) return const Center(
                child: Text("No buses found",
                    style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _BusCard(bus: filtered[i]));
          },
        )),
      ]),
    );
  }

  Widget _chip(String label, String val) => GestureDetector(
    onTap: () => setState(() => _filter = val),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: _filter == val
              ? const Color(0xFF1E40AF)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
          color: _filter == val ? Colors.white : Colors.grey.shade700,
          fontSize: 12, fontWeight: FontWeight.w600))));
}

class _BusCard extends StatelessWidget {
  final AuthorityBus bus;
  const _BusCard({required this.bus});

  Color get _crowd => switch (bus.crowdCategory) {
    "low"    => const Color(0xFF059669),
    "medium" => const Color(0xFFD97706),
    "high"   => const Color(0xFFDC2626),
    _        => Colors.grey,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFF1E40AF),
              borderRadius: BorderRadius.circular(8)),
          child: Text(bus.busNumber, style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 10),
        Text(bus.registrationNumber, style: TextStyle(
            color: Colors.grey.shade600, fontSize: 12)),
        const Spacer(),
        if (bus.isOnTrip)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, color: Color(0xFF059669), size: 8),
              SizedBox(width: 4),
              Text("ON TRIP", style: TextStyle(
                  color: Color(0xFF059669), fontSize: 10,
                  fontWeight: FontWeight.w700)),
            ])),
        if (!bus.isActive)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20)),
            child: const Text("INACTIVE", style: TextStyle(
                color: Colors.grey, fontSize: 10,
                fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 10),
      // Owner + Route
      Row(children: [
        const Icon(Icons.business_outlined, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(
            "\${bus.ownerBusinessName} (\${bus.ownerName})",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            overflow: TextOverflow.ellipsis)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        const Icon(Icons.route, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(
            "\${bus.routeNumber} — \${bus.routeName}",
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis)),
      ]),
      const Divider(height: 16),
      // Live status row
      Row(children: [
        Icon(Icons.people_outline, size: 13, color: _crowd),
        const SizedBox(width: 4),
        Text("\${bus.passengerCount}/\${bus.capacity}  ·  "
            "\${bus.crowdCategory}",
            style: TextStyle(color: _crowd, fontSize: 12,
                fontWeight: FontWeight.w500)),
        const Spacer(),
        const Icon(Icons.gps_fixed, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Text(bus.lastGpsUpdate,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        if (bus.speedKmh != null) ...[
          const SizedBox(width: 8),
          Text("\${bus.speedKmh!.toStringAsFixed(0)} km/h",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ]),
    ])),
  );
}
