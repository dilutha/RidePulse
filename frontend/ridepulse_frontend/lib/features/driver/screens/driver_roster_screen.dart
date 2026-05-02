// ============================================================
// features/driver/screens/driver_roster_screen.dart
// Full duty roster with date picker + monthly stats tab
// OOP Encapsulation: date formatting and tab state private.
//     Polymorphism: tab view shows different data per selection.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class DriverRosterScreen extends ConsumerStatefulWidget {
  const DriverRosterScreen({super.key});
  @override
  ConsumerState<DriverRosterScreen> createState() =>
      _DriverRosterScreenState();
}

class _DriverRosterScreenState extends ConsumerState<DriverRosterScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  String get _dateStr {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final n = DateTime.now();
    return _selectedDate.year == n.year &&
        _selectedDate.month == n.month &&
        _selectedDate.day == n.day;
  }

  String get _displayDate {
    if (_isToday) return 'Today';
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[_selectedDate.month]} '
        '${_selectedDate.day}, ${_selectedDate.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate:  DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF))),
        child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = _isToday
        ? ref.watch(driverRosterTodayProvider)
        : ref.watch(FutureProvider.autoDispose((r) =>
            r.read(apiServiceProvider).getDriverRosterForDate(_dateStr)));

    final dashAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Duty Roster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver/home')),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF1E40AF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1E40AF),
          tabs: const [
            Tab(icon: Icon(Icons.today, size: 18), text: 'Daily View'),
            Tab(icon: Icon(Icons.bar_chart, size: 18),
                text: 'This Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tab 1: Daily View ──────────────────────────────
          Column(children: [
            // Date navigator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 10),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1)))),
                Expanded(child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Icon(Icons.calendar_today,
                          size: 15, color: Color(0xFF1E40AF)),
                      const SizedBox(width: 6),
                      Text(_displayDate,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1E40AF))),
                    ]),
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.add(const Duration(days: 1)))),
              ]),
            ),
            const Divider(height: 1),

            // Roster list
            Expanded(child: rosterAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: _ErrMsg(e.toString())),
              data: (rosters) => rosters.isEmpty
                  ? _EmptyDay(isToday: _isToday)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rosters.length,
                      itemBuilder: (_, i) =>
                          _RosterCard(roster: rosters[i])),
            )),
          ]),

          // ── Tab 2: Monthly Stats ───────────────────────────
          dashAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: _ErrMsg(e.toString())),
            data: (dash) => _MonthlyStats(dash: dash),
          ),
        ],
      ),
    );
  }
}

// ── Roster Card ───────────────────────────────────────────────

class _RosterCard extends StatelessWidget {
  final RosterModel roster;
  const _RosterCard({required this.roster});

  Color get _statusColor => switch (roster.status) {
    'active'    => const Color(0xFF059669),
    'completed' => const Color(0xFF6B7280),
    'cancelled' => const Color(0xFFDC2626),
    _           => const Color(0xFFD97706),
  };

  IconData get _statusIcon => switch (roster.status) {
    'active'    => Icons.play_circle,
    'completed' => Icons.check_circle,
    'cancelled' => Icons.cancel,
    _           => Icons.schedule,
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row: status + shift time
        Row(children: [
          Icon(_statusIcon, color: _statusColor, size: 18),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(roster.status.toUpperCase(),
                style: TextStyle(
                    color: _statusColor, fontSize: 11,
                    fontWeight: FontWeight.w700))),
          const Spacer(),
          Row(children: [
            const Icon(Icons.access_time,
                size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${roster.shiftStart} – ${roster.shiftEnd}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 14),

        // Bus info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_bus,
                  color: Color(0xFF1E40AF), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(roster.busNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(roster.registrationNumber,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Capacity',
                  style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text('${roster.busCapacity} seats',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Route info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.route,
                  size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${roster.routeNumber} — ${roster.routeName}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 24),
              const Icon(Icons.trip_origin,
                  size: 12, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Text(roster.startLocation,
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 12)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const SizedBox(width: 24),
              const Icon(Icons.place,
                  size: 12, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text(roster.endLocation,
                  style: TextStyle(
                      color: Colors.grey.shade700, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const SizedBox(width: 24),
              const Icon(Icons.payments_outlined,
                  size: 12, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Base fare: LKR ${roster.baseFare.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ]),
          ]),
        ),

        // Active trip indicator
        if (roster.hasTripActive) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.3))),
            child: const Row(children: [
              Icon(Icons.circle, color: Color(0xFF059669), size: 8),
              SizedBox(width: 8),
              Text('Trip in progress',
                  style: TextStyle(
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ]),
          ),
        ],
      ]),
    ),
  );
}

// ── Monthly Stats Tab ─────────────────────────────────────────

class _MonthlyStats extends StatelessWidget {
  final dynamic dash;
  const _MonthlyStats({required this.dash});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['', 'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Month header
        Row(children: [
          const Icon(Icons.calendar_month,
              color: Color(0xFF1E40AF), size: 20),
          const SizedBox(width: 8),
          Text('${months[now.month]} ${now.year}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 16),

        // Stats grid
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _StatCard('Duty Days', '${dash.dutyDaysThisMonth}',
                Icons.event_available_outlined,
                const Color(0xFF3B82F6)),
            _StatCard('Welfare Earned',
                'LKR ${dash.welfareThisMonth.toStringAsFixed(0)}',
                Icons.volunteer_activism_outlined,
                const Color(0xFF10B981)),
            _StatCard('Total Balance',
                'LKR ${dash.totalWelfareBalance.toStringAsFixed(0)}',
                Icons.account_balance_wallet_outlined,
                const Color(0xFF8B5CF6)),
            const _StatCard('Welfare Rate', '3% net profit',
                Icons.percent_outlined,
                Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 20),

        // License summary
        if (dash.licenseNumber != null) ...[
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.credit_card_outlined,
                    color: Color(0xFF1E40AF), size: 18),
                SizedBox(width: 8),
                Text('Driver Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const Divider(height: 20),
              _DetailRow('Employee ID', dash.employeeId),
              _DetailRow('License No.', dash.licenseNumber ?? 'N/A'),
              _DetailRow('License Expiry',
                  dash.licenseExpiry ?? 'N/A'),
            ]),
          )),
        ],
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2))),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const Spacer(),
      Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14, color: color),
          overflow: TextOverflow.ellipsis),
      Text(label, style: const TextStyle(
          color: Colors.grey, fontSize: 11)),
    ]),
  );
}

class _DetailRow extends StatelessWidget {
  final String k, v;
  const _DetailRow(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 110,
          child: Text(k, style: const TextStyle(
              color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}

// ── Helpers ───────────────────────────────────────────────────

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  const _EmptyDay({required this.isToday});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          isToday ? Icons.free_breakfast_outlined : Icons.event_busy,
          size: 60, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(
          isToday ? 'No duty today' : 'No roster for this date',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500,
              color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          isToday
              ? 'Enjoy your day off!'
              : 'Try a different date',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]),
    ),
  );
}

class _ErrMsg extends StatelessWidget {
  final String msg;
  const _ErrMsg(this.msg);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 40),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center),
    ]),
  );
}
