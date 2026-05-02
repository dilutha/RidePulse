// ============================================================
// features/driver/screens/driver_income_screen.dart
// Shows driver monthly income: base salary + welfare = total
// OOP Encapsulation: income calculation logic is in the model.
//     Abstraction: one screen shows full earnings picture.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/driver_models.dart';
import '../../../core/models/conductor_models.dart';

class DriverIncomeScreen extends ConsumerWidget {
  const DriverIncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync    = ref.watch(driverDashboardProvider);
    final welfareAsync = ref.watch(driverWelfareProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('My Income'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver/home')),
      ),
      body: dashAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (dash) => _Body(dash: dash, welfareAsync: welfareAsync),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DriverDashboardModel dash;
  final AsyncValue<List<ConductorWelfareModel>> welfareAsync;
  const _Body({required this.dash, required this.welfareAsync});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── This month summary hero card ─────────────────────
      _ThisMonthCard(dash: dash),
      const SizedBox(height: 16),

      // ── Income breakdown card ─────────────────────────────
      _BreakdownCard(dash: dash),
      const SizedBox(height: 16),

      // ── Info note about salary ────────────────────────────
      Card(
        color: const Color(0xFFF0FDF4),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF059669), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('About Your Income',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46))),
                const SizedBox(height: 4),
                Text(
                  'Your total income = Base Salary + Welfare (3% of bus net profit). '
                  'Welfare is credited automatically on the 1st of each month. '
                  'Contact your bus owner for salary adjustments.',
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 12,
                      height: 1.5)),
              ])),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // ── Monthly history ───────────────────────────────────
      const Text('Monthly Welfare History',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 12),

      welfareAsync.when(
        loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator())),
        error:   (e, _) => _ErrCard(e.toString()),
        data: (list) => list.isEmpty
            ? _EmptyHistory()
            : Column(
                children: list.asMap().entries.map((entry) =>
                    _HistoryRow(
                        w: entry.value,
                        isLatest: entry.key == 0)).toList()),
      ),
    ]),
  );
}

// ── This Month Hero Card ──────────────────────────────────────

class _ThisMonthCard extends StatelessWidget {
  final DriverDashboardModel dash;
  const _ThisMonthCard({required this.dash});

  // Encapsulation: total income computed here
  double get _total => dash.welfareThisMonth;
  // Note: baseSalary would be added when backend exposes it.
  // For now welfare is shown as the variable component.

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['', 'January', 'February', 'March', 'April', 'May',
      'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${months[now.month]} ${now.year}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('Current Month',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Text('Welfare Earned',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 4),
        Text('LKR ${dash.welfareThisMonth.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _HeroStat('Duty Days',
              '${dash.dutyDaysThisMonth}', Icons.calendar_today_outlined),
          _HeroStat('Total Balance',
              'LKR ${dash.totalWelfareBalance.toStringAsFixed(0)}',
              Icons.account_balance_wallet_outlined),
          const _HeroStat('Rate', '3% of net profit',
              Icons.percent_outlined),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _HeroStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: Colors.white60, size: 16),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600, fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(
          color: Colors.white60, fontSize: 10),
          textAlign: TextAlign.center),
    ]),
  );
}

// ── Breakdown Card ────────────────────────────────────────────

class _BreakdownCard extends StatelessWidget {
  final DriverDashboardModel dash;
  const _BreakdownCard({required this.dash});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.receipt_long_outlined,
              color: Color(0xFF1E40AF), size: 20),
          SizedBox(width: 8),
          Text('This Month Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),

        // Salary row — placeholder until API exposes it
        const _BreakRow(
          icon: Icons.work_outline,
          label: 'Base Salary',
          value: 'Set by Bus Owner',
          color: Color(0xFF3B82F6),
          isPlaceholder: true),
        const Divider(height: 20),

        // Welfare row
        _BreakRow(
          icon: Icons.volunteer_activism_outlined,
          label: 'Welfare (3% net profit)',
          value: 'LKR ${dash.welfareThisMonth.toStringAsFixed(2)}',
          color: const Color(0xFF10B981)),
        const Divider(height: 20),

        // Duty days
        _BreakRow(
          icon: Icons.event_available_outlined,
          label: 'Duty Days This Month',
          value: '${dash.dutyDaysThisMonth} days',
          color: const Color(0xFFF59E0B)),
        const Divider(height: 20),

        // Total welfare balance
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.savings_outlined,
                color: Color(0xFF059669), size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Total Welfare Balance',
                style: TextStyle(fontWeight: FontWeight.w600))),
            Text('LKR ${dash.totalWelfareBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669), fontSize: 15)),
          ]),
        ),
      ]),
    ),
  );
}

class _BreakRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool isPlaceholder;
  const _BreakRow({required this.icon, required this.label,
      required this.value, required this.color,
      this.isPlaceholder = false});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 18)),
    const SizedBox(width: 12),
    Expanded(child: Text(label,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500))),
    isPlaceholder
        ? Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6)),
            child: Text(value,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)))
        : Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold,
                fontSize: 13)),
  ]);
}

// ── Monthly History Row ───────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final ConductorWelfareModel w;
  final bool isLatest;
  const _HistoryRow({required this.w, required this.isLatest});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        // Month badge
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_monthShort(w.month),
                style: const TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${w.year}'.substring(2),
                style: const TextStyle(
                    color: Color(0xFF1E40AF), fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(w.monthLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isLatest) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Latest',
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10, fontWeight: FontWeight.w600))),
            ],
          ]),
          const SizedBox(height: 2),
          Text('Bus: ${w.busNumber}',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('LKR ${w.welfareAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF), fontSize: 14)),
          Text('Bal: LKR ${w.cumulativeBalance.toStringAsFixed(0)}',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ]),
    ),
  );

  static const _shorts = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _monthShort(int m) => m >= 1 && m <= 12 ? _shorts[m] : '?';
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    alignment: Alignment.center,
    child: Column(children: [
      Icon(Icons.history_toggle_off_outlined,
          size: 52, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Text('No income records yet',
          style: TextStyle(color: Colors.grey.shade500)),
      const SizedBox(height: 4),
      Text('Welfare is credited on the 1st of each month',
          style: TextStyle(
              color: Colors.grey.shade400, fontSize: 12)),
    ]),
  );
}

class _ErrCard extends StatelessWidget {
  final String msg;
  const _ErrCard(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10)),
    child: Text(msg, style: const TextStyle(color: Colors.red)),
  );
}
