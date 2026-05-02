// ============================================================
// features/driver/screens/driver_welfare_screen.dart
// Shows monthly welfare breakdown (3% net profit)
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";

class DriverWelfareScreen extends ConsumerWidget {
  const DriverWelfareScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync    = ref.watch(driverDashboardProvider);
    final welfareAsync = ref.watch(driverWelfareProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("My Welfare"),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go("/driver/home")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          dashAsync.when(
            loading: () => const LinearProgressIndicator(),
            error:   (e, _) => const SizedBox.shrink(),
            data: (dash) => _SummaryCard(
              thisMonth:   dash.welfareThisMonth,
              totalBalance: dash.totalWelfareBalance,
              dutyDays:    dash.dutyDaysThisMonth),
          ),
          const SizedBox(height: 14),
          const Card(color: Color(0xFFEFF6FF),
            child: Padding(padding: EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF1E40AF), size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  "Driver welfare = 3% of bus net profit, "
                  "calculated on the 1st of every month.",
                  style: TextStyle(fontSize: 13))),
              ]))),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft,
              child: Text("Monthly History",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          const SizedBox(height: 10),
          welfareAsync.when(
            loading: () => const CircularProgressIndicator(),
            error:   (e, _) => const Text("Error: \$e"),
            data: (list) => list.isEmpty
                ? const Center(child: Text("No welfare records yet",
                    style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((w) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1E40AF),
                          child: Icon(Icons.volunteer_activism,
                              color: Colors.white, size: 18)),
                      title: Text(w.monthLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Bus: \${w.busNumber}"),
                      trailing: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("LKR \${w.welfareAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF))),
                          Text("Total: LKR \${w.cumulativeBalance.toStringAsFixed(0)}",
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ]),
                    ))).toList()),
          ),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double thisMonth, totalBalance;
  final int dutyDays;
  const _SummaryCard({required this.thisMonth, required this.totalBalance,
      required this.dutyDays});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(16)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Welfare Summary (Driver — 3%)",
          style: TextStyle(color: Colors.white70, fontSize: 13)),
      SizedBox(height: 14),
      Row(children: [
        _Fig("This Month", "LKR \${thisMonth.toStringAsFixed(2)}"),
        _Fig("Total Balance", "LKR \${totalBalance.toStringAsFixed(2)}"),
        _Fig("Duty Days", "\$dutyDays days"),
      ]),
    ]),
  );
}

class _Fig extends StatelessWidget {
  final String label, value;
  const _Fig(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
  ]));
}
