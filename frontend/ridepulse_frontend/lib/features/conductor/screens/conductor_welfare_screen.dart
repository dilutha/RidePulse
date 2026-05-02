// ============================================================
// features/conductor/screens/conductor_welfare_screen.dart
// Shows monthly welfare breakdown and cumulative balance
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class ConductorWelfareScreen extends ConsumerWidget {
  const ConductorWelfareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync    = ref.watch(conductorDashboardProvider);
    final welfareAsync = ref.watch(conductorWelfareProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('My Welfare'),
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/conductor/home')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Summary card
          dashAsync.when(
            loading: () => const LinearProgressIndicator(),
            error:   (e, _) => const SizedBox.shrink(),
            data: (dash) => _SummaryCard(
                thisMonth:   dash.welfareThisMonth,
                totalBalance: dash.totalWelfareBalance,
                tickets:     dash.ticketsIssuedThisMonth,
                totalFare:   dash.totalFareThisMonth),
          ),
          const SizedBox(height: 16),

          // Info card
          const Card(
            color: Color(0xFFEFF6FF),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF3B82F6), size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                    'Conductor welfare = 2% of bus net profit, '
                        'calculated on the 1st of every month.',
                    style: TextStyle(fontSize: 13))),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // History list
          const Align(alignment: Alignment.centerLeft,
              child: Text('Monthly History',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          const SizedBox(height: 10),

          welfareAsync.when(
            loading: () => const CircularProgressIndicator(),
            error:   (e, _) => Text('Error: $e'),
            data: (list) => list.isEmpty
                ? const Center(child: Text('No welfare records yet',
                style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((w) => _WelfareRow(w: w)).toList()),
          ),
        ]),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double thisMonth, totalBalance, totalFare;
  final int tickets;
  const _SummaryCard({required this.thisMonth, required this.totalBalance,
    required this.tickets, required this.totalFare});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(16)),
    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Welfare Summary',
          style: TextStyle(color: Colors.white70, fontSize: 13)),
      SizedBox(height: 14),
      Row(children: [
        Expanded(child: _Figure('This Month',
            'LKR \${thisMonth.toStringAsFixed(2)}')),
        Expanded(child: _Figure('Total Balance',
            'LKR \${totalBalance.toStringAsFixed(2)}')),
      ]),
      SizedBox(height: 14),
      Divider(color: Colors.white24),
      SizedBox(height: 10),
      Row(children: [
        Expanded(child: _Figure('Tickets Issued', '\$tickets')),
        Expanded(child: _Figure('Fare Collected',
            'LKR \${totalFare.toStringAsFixed(2)}')),
      ]),
    ]),
  );
}

class _Figure extends StatelessWidget {
  final String label, value;
  const _Figure(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
  ]);
}

class _WelfareRow extends StatelessWidget {
  final ConductorWelfareModel w;
  const _WelfareRow({required this.w});
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
          child: const Icon(Icons.volunteer_activism,
              color: Color(0xFF8B5CF6), size: 20)),
      title: Text(w.monthLabel,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Bus: \${w.busNumber}'),
      trailing: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('LKR \${w.welfareAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6))),
            Text('Total: LKR \${w.cumulativeBalance.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
    ),
  );
}
