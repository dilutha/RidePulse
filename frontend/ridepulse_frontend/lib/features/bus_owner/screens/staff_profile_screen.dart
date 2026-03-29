import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/bus_models.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  final int staffId;
  const StaffProfileScreen({super.key, required this.staffId});
  @override
  ConsumerState<StaffProfileScreen> createState() =>
      _StaffProfileScreenState();
}

class _StaffProfileScreenState
    extends ConsumerState<StaffProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<StaffModel>> _future;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiServiceProvider).getStaff();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1220),
    body: Stack(children: [
      Positioned(top: -50, right: -60,
          child: _Orb(
              color: const Color(0xFF38BDF8).withOpacity(0.12),
              size: 280)),
      Positioned(bottom: 60, left: -40,
          child: _Orb(
              color: const Color(0xFF1A56DB).withOpacity(0.12),
              size: 220)),

      Column(children: [
        _DarkAppBar(
            onBack: () => context.go('/bus-owner/staff')),

        Expanded(
          child: FutureBuilder<List<StaffModel>>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const _LoadingState();
              final staff = snap.data?.firstWhere(
                  (s) => s.staffId == widget.staffId,
                  orElse: () => throw Exception('Not found'));
              if (staff == null)
                return const _NotFoundState();
              _fadeCtrl.forward();
              return FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _Body(staff: staff),
                ),
              );
            },
          ),
        ),
      ]),
    ]),
  );
}

// ── App bar ───────────────────────────────────────────────────

class _DarkAppBar extends StatelessWidget {
  final VoidCallback onBack;
  const _DarkAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: onBack,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.7)),
        ),
      ),
      const SizedBox(width: 4),
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.badge_rounded,
            size: 17, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Staff Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        Text('View & manage',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Body ──────────────────────────────────────────────────────

class _Body extends ConsumerStatefulWidget {
  final StaffModel staff;
  const _Body({required this.staff});
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _salaryCtrl = TextEditingController();
  bool    _editing  = false;
  bool    _saving   = false;
  String? _saveError;

  bool get _isDriver => widget.staff.staffType == 'driver';

  Color get _roleColor => _isDriver
      ? const Color(0xFF38BDF8)
      : const Color(0xFFC084FC);

  IconData get _roleIcon => _isDriver
      ? Icons.drive_eta_rounded
      : Icons.confirmation_number_rounded;

  @override
  void initState() {
    super.initState();
    _salaryCtrl.text =
        widget.staff.baseSalary.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.staff;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(children: [

        // ── Avatar + name ────────────────────────────
        _AvatarBlock(staff: s, color: _roleColor, icon: _roleIcon),
        const SizedBox(height: 28),

        // ── Info card ─────────────────────────────────
        _SectionLabel('Details'),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(children: [
            _InfoRow(label: 'Phone',       value: s.phone,
                icon: Icons.phone_rounded),
            _InfoRow(label: 'Employee ID', value: s.employeeId,
                icon: Icons.badge_rounded),
            _InfoRow(label: 'Bus',         value: s.assignedBusNumber,
                icon: Icons.directions_bus_rounded),
            _InfoRow(label: 'Duty Days',
                value: '${s.dutyDaysThisMonth} this month',
                icon: Icons.calendar_today_rounded),
            if (s.licenseNumber != null)
              _InfoRow(label: 'License',
                  value: s.licenseNumber!,
                  icon: Icons.credit_card_rounded,
                  isLast: true)
            else
              const SizedBox.shrink(),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Welfare card ──────────────────────────────
        _SectionLabel('Welfare Balance'),
        const SizedBox(height: 10),
        _GlassCard(
          accentColor: const Color(0xFF4ADE80),
          child: Column(children: [
            _WelfareRow(
              label: 'This month',
              value: 'LKR ${s.welfareBalanceThisMonth.toStringAsFixed(2)}',
              color: const Color(0xFF4ADE80),
            ),
            Divider(height: 16,
                color: Colors.white.withOpacity(0.06)),
            _WelfareRow(
              label: 'Total accumulated',
              value: 'LKR ${s.cumulativeWelfareBalance.toStringAsFixed(2)}',
              color: const Color(0xFF4ADE80),
              isBold: true,
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Salary card ───────────────────────────────
        _SectionLabel('Base Salary'),
        const SizedBox(height: 10),
        _GlassCard(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_rounded,
                    size: 14, color: Color(0xFFFBBF24)),
              ),
              const SizedBox(width: 10),
              const Text('Monthly Salary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _salaryCtrl,
                  enabled: _editing,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      color: _editing
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: 'LKR ',
                    prefixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(
                        _editing ? 0.06 : 0.03),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1))),
                    disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.06))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF0EA5E9), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _editing
                  ? _SaveBtn(
                      isLoading: _saving,
                      onTap: () async {
                        setState(() {
                          _saving   = true;
                          _saveError = null;
                        });
                        try {
                          await ref
                              .read(apiServiceProvider)
                              .updateSalary(s.staffId,
                                  double.parse(_salaryCtrl.text));
                          setState(() => _editing = false);
                          if (mounted) _showToast(
                              context, 'Salary updated');
                        } catch (e) {
                          setState(() => _saveError = e
                              .toString()
                              .replaceFirst('Exception: ', ''));
                        } finally {
                          setState(() => _saving = false);
                        }
                      },
                    )
                  : _EditBtn(
                      onTap: () =>
                          setState(() => _editing = true)),
            ]),
            if (_saveError != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: _saveError!),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Avatar block ──────────────────────────────────────────────

class _AvatarBlock extends StatelessWidget {
  final StaffModel staff;
  final Color      color;
  final IconData   icon;
  const _AvatarBlock({
    required this.staff, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Center(
        child: Text(
          staff.fullName[0].toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 30,
              fontWeight: FontWeight.w700),
        ),
      ),
    ),
    const SizedBox(height: 12),
    Text(staff.fullName,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3)),
    const SizedBox(height: 6),
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(staff.staffType.toUpperCase(),
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ]),
    ),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: staff.isActive
            ? const Color(0xFF4ADE80).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: staff.isActive
              ? const Color(0xFF4ADE80).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        staff.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
            color: staff.isActive
                ? const Color(0xFF4ADE80)
                : Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700)),
    ),
  ]);
}

// ── Info row ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final bool     isLast;
  const _InfoRow({
    required this.label, required this.value,
    required this.icon,  this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Icon(icon, size: 15,
            color: Colors.white.withOpacity(0.25)),
        const SizedBox(width: 10),
        SizedBox(
          width: 96,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    ),
    if (!isLast)
      Divider(height: 1, color: Colors.white.withOpacity(0.05)),
  ]);
}

// ── Welfare row ───────────────────────────────────────────────

class _WelfareRow extends StatelessWidget {
  final String label, value;
  final Color  color;
  final bool   isBold;
  const _WelfareRow({
    required this.label, required this.value,
    required this.color, this.isBold = false,
  });

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: isBold
                    ? FontWeight.w700 : FontWeight.w600,
                fontSize: isBold ? 15 : 13)),
      ]);
}

// ── Action buttons ────────────────────────────────────────────

class _EditBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EditBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.edit_rounded,
            size: 14, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text('Edit',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    ),
  );
}

class _SaveBtn extends StatefulWidget {
  final bool         isLoading;
  final VoidCallback onTap;
  const _SaveBtn({required this.isLoading, required this.onTap});
  @override
  State<_SaveBtn> createState() => _SaveBtnState();
}

class _SaveBtnState extends State<_SaveBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      if (!widget.isLoading) widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.isLoading
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
      ),
    ),
  );
}

// ── Shared utilities ──────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: accentColor != null
          ? accentColor!.withOpacity(0.05)
          : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: accentColor != null
              ? accentColor!.withOpacity(0.18)
              : Colors.white.withOpacity(0.08)),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Row(children: [
      Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Colors.white.withOpacity(0.3))),
      const SizedBox(width: 10),
      Expanded(child: Divider(
          color: Colors.white.withOpacity(0.08), height: 1)),
    ]),
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
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 26, height: 26,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.4),
              strokeWidth: 2)),
      const SizedBox(height: 12),
      Text('Loading profile...',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13)),
    ]),
  );
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.person_off_rounded,
          size: 40, color: Colors.white.withOpacity(0.2)),
      const SizedBox(height: 12),
      Text('Staff not found',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14)),
    ]),
  );
}

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded,
            color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Text(message,
            style: const TextStyle(
                color: Colors.white, fontSize: 13)),
      ]),
      backgroundColor: const Color(0xFF14532D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ),
  );
}