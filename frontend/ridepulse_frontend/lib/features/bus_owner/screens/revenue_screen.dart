import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/bus_models.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});
  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen>
    with SingleTickerProviderStateMixin {
  int _month = DateTime.now().month;
  int _year  = DateTime.now().year;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  bool get _isCurrentMonth =>
      _month == DateTime.now().month && _year == DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _changeMonth(int m, int y) {
    setState(() { _month = m; _year = y; });
    _fadeCtrl.forward(from: 0);
  }

  void _showFuelDialog() {
    final busId  = TextEditingController();
    final amount = TextEditingController();
    String? error;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: const Color(0xFF131C2E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header
              Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFB923C).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded,
                      size: 17, color: Color(0xFFFB923C)),
                ),
                const SizedBox(width: 12),
                const Text('Record Fuel Expense',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14,
                        color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _DarkField(
                  controller: busId,
                  label: 'Bus ID',
                  hint: 'Enter bus ID',
                  keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _DarkField(
                  controller: amount,
                  label: 'Amount (LKR)',
                  hint: 'e.g. 12500.00',
                  keyboard: TextInputType.number),

              if (error != null) ...[
                const SizedBox(height: 10),
                _ErrorBanner(message: error!),
              ],

              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _GradientBtn(
                    label: 'Save',
                    onPressed: () async {
                      try {
                        await ref.read(apiServiceProvider)
                            .recordFuelExpense(
                              busId:  int.parse(busId.text),
                              date:   DateTime.now()
                                  .toIso8601String()
                                  .split('T')[0],
                              amount: double.parse(amount.text));
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDlg(() => error =
                            e.toString()
                                .replaceFirst('Exception: ', ''));
                      }
                    },
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(
        monthlyRevenueProvider((month: _month, year: _year)));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFF4ADE80).withOpacity(0.1),
                size: 280)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.14),
                size: 220)),

        Column(children: [
          // ── App bar ──────────────────────────────────
          _DarkAppBar(onFuel: _showFuelDialog),

          // ── Month picker ─────────────────────────────
          _MonthPicker(
            month:     _months[_month - 1],
            year:      _year,
            isCurrent: _isCurrentMonth,
            onPrev: () => _month > 1
                ? _changeMonth(_month - 1, _year)
                : _changeMonth(12, _year - 1),
            onNext: () => _month < 12
                ? _changeMonth(_month + 1, _year)
                : _changeMonth(1, _year + 1),
          ),

          // ── Content ──────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _FormulaCard(),
                  const SizedBox(height: 22),

                  _SectionLabel('Bus Revenue'),
                  const SizedBox(height: 12),

                  revenueAsync.when(
                    loading: () => const _LoadingState(),
                    error: (e, _) => _ErrorState(
                        message: e.toString()
                            .replaceFirst('Exception: ', '')),
                    data: (list) => list.isEmpty
                        ? const _EmptyState()
                        : Column(
                            children: list
                                .map((r) => _RevenueCard(r: r))
                                .toList()),
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
  final VoidCallback onFuel;
  const _DarkAppBar({required this.onFuel});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 12, bottom: 10),
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
        child: const Icon(Icons.bar_chart_rounded,
            size: 18, color: Color(0xFF4ADE80)),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Revenue & Expenses',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Monthly breakdown',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
      const Spacer(),
      // Fuel button
      GestureDetector(
        onTap: onFuel,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFB923C).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFFB923C).withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_gas_station_rounded,
                size: 14, color: Color(0xFFFB923C)),
            const SizedBox(width: 6),
            const Text('Fuel',
                style: TextStyle(
                    color: Color(0xFFFB923C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
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
    required this.onPrev,  required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
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
  final IconData icon; final VoidCallback onTap;
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
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Icon(icon,
          size: 18, color: Colors.white.withOpacity(0.6)),
    ),
  );
}

// ── Formula card ──────────────────────────────────────────────

class _FormulaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
      Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.functions_rounded,
              size: 15, color: Color(0xFF0EA5E9)),
        ),
        const SizedBox(width: 10),
        const Text('Net Profit Formula',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      _FormulaRow('Gross Revenue', isIncome: true),
      _FormulaRow('− Fuel Expenses',        isDeduct: true),
      _FormulaRow('− Maintenance (fixed)',   isDeduct: true),
      _FormulaRow('− Staff Base Salaries',   isDeduct: true),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1,
            color: Colors.white.withOpacity(0.08)),
      ),
      _FormulaRow('= Net Profit', isBold: true),
      const SizedBox(height: 8),
      _FormulaRow('Driver Welfare  = Net × 3%',
          color: const Color(0xFF4ADE80)),
      _FormulaRow('Conductor Welfare = Net × 2%',
          color: const Color(0xFF4ADE80)),
    ]),
  );
}

class _FormulaRow extends StatelessWidget {
  final String text;
  final bool   isIncome, isDeduct, isBold;
  final Color? color;
  const _FormulaRow(this.text, {
    this.isIncome = false,
    this.isDeduct = false,
    this.isBold   = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color
        ?? (isIncome ? Colors.white.withOpacity(0.7)
            : isDeduct ? const Color(0xFFF87171).withOpacity(0.8)
            : isBold   ? Colors.white
            : Colors.white.withOpacity(0.5));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(text,
          style: TextStyle(
              color: c,
              fontSize: 13,
              fontWeight: isBold
                  ? FontWeight.w700 : FontWeight.w400)),
    );
  }
}

// ── Revenue card ──────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  final MonthlyRevenueModel r;
  const _RevenueCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final isProfit = r.netProfit >= 0;
    final profitColor = isProfit
        ? const Color(0xFF4ADE80)
        : const Color(0xFFF87171);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.busNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const Spacer(),
            // Net profit badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: profitColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: profitColor.withOpacity(0.3)),
              ),
              child: Text(
                '${isProfit ? "+" : ""}LKR ${r.netProfit.toStringAsFixed(0)}',
                style: TextStyle(
                    color: profitColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        Divider(height: 1, color: Colors.white.withOpacity(0.06)),

        // Breakdown rows
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(children: [
            _Row('Gross Revenue',
                'LKR ${r.grossRevenue.toStringAsFixed(2)}',
                valueColor: Colors.white.withOpacity(0.8)),
            _Row('Fuel Cost',
                '− LKR ${r.totalFuelCost.toStringAsFixed(2)}',
                valueColor: const Color(0xFFF87171).withOpacity(0.8)),
            _Row('Maintenance',
                '− LKR ${r.maintenanceCost.toStringAsFixed(2)}',
                valueColor: const Color(0xFFF87171).withOpacity(0.8)),
            _Row('Staff Salaries',
                '− LKR ${r.totalStaffSalaries.toStringAsFixed(2)}',
                valueColor: const Color(0xFFF87171).withOpacity(0.8)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1,
                  color: Colors.white.withOpacity(0.06)),
            ),
            _Row('Net Profit',
                'LKR ${r.netProfit.toStringAsFixed(2)}',
                isBold: true,
                valueColor: profitColor),
            const SizedBox(height: 8),
            _Row('Driver Welfare',
                'LKR ${r.driverWelfareAmount.toStringAsFixed(2)}',
                valueColor: const Color(0xFFC084FC)),
            _Row('Conductor Welfare',
                'LKR ${r.conductorWelfareAmount.toStringAsFixed(2)}',
                valueColor: const Color(0xFFC084FC)),
          ]),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool   isBold;
  const _Row(this.label, this.value,
      {this.valueColor, this.isBold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(
                  isBold ? 0.6 : 0.4),
              fontSize: 13)),
      Text(value,
          style: TextStyle(
              color: valueColor ?? Colors.white.withOpacity(0.7),
              fontWeight: isBold
                  ? FontWeight.w700 : FontWeight.w600,
              fontSize: isBold ? 14 : 13)),
    ]),
  );
}

// ── Shared form widgets ───────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType keyboard;
  const _DarkField({
    required this.controller, required this.label,
    required this.hint,
    this.keyboard = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboard,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.4), fontSize: 13),
      hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.18), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF0EA5E9), width: 1.5)),
    ),
  );
}

class _GradientBtn extends StatefulWidget {
  final String label; final VoidCallback onPressed;
  const _GradientBtn(
      {required this.label, required this.onPressed});
  @override
  State<_GradientBtn> createState() => _GradientBtnState();
}

class _GradientBtnState extends State<_GradientBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onPressed();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded,
          size: 14, color: Colors.red.shade300),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: TextStyle(
              color: Colors.red.shade300, fontSize: 12))),
    ]),
  );
}

// ── Utility ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.3))),
    const SizedBox(width: 10),
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color, color.withOpacity(0)]))),
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
        Text('Loading revenue data...',
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
        Icon(Icons.error_outline_rounded, size: 36,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load revenue',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center,
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
              shape: BoxShape.circle),
          child: Icon(Icons.bar_chart_rounded, size: 26,
              color: Colors.white.withOpacity(0.2)),
        ),
        const SizedBox(height: 12),
        Text('No revenue data for this period',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Try a different month',
            style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12)),
      ]),
    ),
  );
}