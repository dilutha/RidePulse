import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

class WelfareScreen extends ConsumerStatefulWidget {
  const WelfareScreen({super.key});
  @override
  ConsumerState<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends ConsumerState<WelfareScreen>
    with SingleTickerProviderStateMixin {
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() => _month > 1 ? _month-- : (_month = 12, _year--));
    _fadeCtrl.forward(from: 0);
  }

  void _nextMonth() {
    setState(() => _month < 12 ? _month++ : (_month = 1, _year++));
    _fadeCtrl.forward(from: 0);
  }

  bool get _isCurrentMonth =>
      _month == DateTime.now().month && _year == DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
        welfareProvider((month: _month, year: _year)));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFF4ADE80).withOpacity(0.1),
                size: 280)),
        Positioned(bottom: 60, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.14),
                size: 220)),

        Column(children: [
          // ── App bar ────────────────────────────────────
          _DarkAppBar(),

          // ── Month picker ───────────────────────────────
          _MonthPicker(
            month:    _months[_month - 1],
            year:     _year,
            isCurrent: _isCurrentMonth,
            onPrev:   _prevMonth,
            onNext:   _nextMonth,
          ),

          // ── Content ────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  // Info card
                  _InfoCard(),
                  const SizedBox(height: 20),

                  // Staff welfare list
                  _SectionLabel('Staff Welfare'),
                  const SizedBox(height: 12),

                  async.when(
                    loading: () => const _LoadingState(),
                    error: (e, _) => _ErrorState(
                        message: e.toString()
                            .replaceFirst('Exception: ', '')),
                    data: (list) => list.isEmpty
                        ? const _EmptyState()
                        : Column(
                            children: list.map((s) =>
                                _WelfareCard(staff: s)).toList()),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── App bar ───────────────────────────────────────────────────

class _DarkAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF4ADE80).withOpacity(0.3)),
        ),
        child: const Icon(Icons.volunteer_activism_rounded,
            size: 17, color: Color(0xFF4ADE80)),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Staff Welfare',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Monthly welfare balance',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Month picker ──────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final String   month;
  final int      year;
  final bool     isCurrent;
  final VoidCallback onPrev, onNext;
  const _MonthPicker({
    required this.month, required this.year,
    required this.isCurrent,
    required this.onPrev, required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom: BorderSide(
              color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
      Expanded(
        child: Column(children: [
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF4ADE80).withOpacity(0.3)),
              ),
              child: const Text('CURRENT',
                  style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
            ),
          Text('$month $year',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ]),
      ),
      _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
    ]),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withOpacity(0.09)),
      ),
      child: Icon(icon,
          size: 18, color: Colors.white.withOpacity(0.6)),
    ),
  );
}

// ── Info card ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF4ADE80).withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.18)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.info_outline_rounded,
            size: 15, color: Color(0xFF4ADE80)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Welfare is auto-calculated on the 1st of each month. '
          'Drivers receive 3%, Conductors 2% of net profit.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              height: 1.5),
        ),
      ),
    ]),
  );
}

// ── Welfare card ──────────────────────────────────────────────

class _WelfareCard extends StatelessWidget {
  final dynamic staff;
  const _WelfareCard({required this.staff});

  bool   get _isDriver => staff.staffType == 'driver';
  Color  get _color    => _isDriver
      ? const Color(0xFF38BDF8) : const Color(0xFFC084FC);
  IconData get _icon   => _isDriver
      ? Icons.drive_eta_rounded : Icons.confirmation_number_rounded;
  String get _rate     => _isDriver ? '3%' : '2%';

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(children: [
      // Avatar
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color.withOpacity(0.25)),
        ),
        child: Icon(_icon, color: _color, size: 20),
      ),
      const SizedBox(width: 12),

      // Name + type
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(staff.fullName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 4),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _color.withOpacity(0.25)),
            ),
            child: Text(staff.staffType.toUpperCase(),
                style: TextStyle(
                    color: _color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3)),
          ),
          const SizedBox(width: 6),
          Text('Rate: $_rate',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11)),
        ]),
      ])),

      // Welfare amounts
      Column(crossAxisAlignment: CrossAxisAlignment.end,
          children: [
        Text(
          'LKR ${staff.welfareBalanceThisMonth.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Color(0xFF4ADE80),
              fontWeight: FontWeight.w700,
              fontSize: 13)),
        const SizedBox(height: 3),
        Text(
          'Total: LKR ${staff.cumulativeWelfareBalance.toStringAsFixed(0)}',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11)),
      ]),
    ]),
  );
}

// ── Shared utilities ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.3))),
    const SizedBox(width: 10),
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _Orb extends StatelessWidget {
  final Color  color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color, color.withOpacity(0)]),
      ),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 26, height: 26,
            child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.4),
                strokeWidth: 2)),
        const SizedBox(height: 12),
        Text('Loading welfare data...',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13)),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 38,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 12)),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.volunteer_activism_rounded,
              size: 26,
              color: Colors.white.withOpacity(0.2)),
        ),
        const SizedBox(height: 12),
        Text('No welfare data for this period',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Try a different month',
            style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12)),
      ]),
    ),
  );
}