// ============================================================
// features/auth/screens/register_screen.dart
// OOP Polymorphism: type param drives which fields + endpoint
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String type; // passenger | bus_owner | authority | staff
  const RegisterScreen({super.key, required this.type});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _form        = GlobalKey<FormState>();
  final _name        = TextEditingController();
  final _email       = TextEditingController();
  final _phone       = TextEditingController();
  final _pass        = TextEditingController();
  final _bizName     = TextEditingController();
  final _nic         = TextEditingController();
  final _address     = TextEditingController();
  final _designation = TextEditingController();
  final _empId       = TextEditingController();
  final _license     = TextEditingController();
  final _salary      = TextEditingController();
  String _staffType  = 'driver';
  bool   _loading    = false;
  bool   _obscure    = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in [
      _name, _email, _phone, _pass, _bizName, _nic,
      _address, _designation, _empId, _license, _salary
    ]) c.dispose();
    super.dispose();
  }

  // ── Role meta ───────────────────────────────────────────────
  String get _title => switch (widget.type) {
    'passenger' => 'Create Passenger Account',
    'bus_owner' => 'Register as Bus Owner',
    'authority' => 'Authority Registration',
    'staff'     => 'Register Staff Member',
    _           => 'Register',
  };

  IconData get _titleIcon => switch (widget.type) {
    'passenger' => Icons.person_rounded,
    'bus_owner' => Icons.business_rounded,
    'authority' => Icons.admin_panel_settings_rounded,
    'staff'     => Icons.badge_rounded,
    _           => Icons.person_add_rounded,
  };

  Color get _accentColor => switch (widget.type) {
    'passenger' => const Color(0xFF4ADE80),
    'bus_owner' => const Color(0xFFFB923C),
    'authority' => const Color(0xFFC084FC),
    'staff'     => const Color(0xFF38BDF8),
    _           => const Color(0xFF0EA5E9),
  };

  // ── Submit ───────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final svc = ref.read(authServiceProvider);
      switch (widget.type) {
        case 'passenger':
          final r = await svc.registerPassenger(
            fullName: _name.text, email: _email.text,
            phone: _phone.text,   password: _pass.text);
          await svc.saveSession(r);
        case 'bus_owner':
          final r = await svc.registerBusOwner(
            fullName: _name.text, email: _email.text,
            phone: _phone.text,   password: _pass.text,
            businessName: _bizName.text, nicNumber: _nic.text,
            address: _address.text);
          await svc.saveSession(r);
        case 'authority':
          final r = await svc.registerAuthority(
            fullName: _name.text, email: _email.text,
            phone: _phone.text,   password: _pass.text,
            designation: _designation.text);
          await svc.saveSession(r);
        case 'staff':
          await svc.registerStaff(
            fullName: _name.text, email: _email.text,
            phone: _phone.text,   password: _pass.text,
            staffType: _staffType, employeeId: _empId.text,
            licenseNumber: _license.text.isEmpty ? null : _license.text,
            baseSalary: double.tryParse(_salary.text));
          if (mounted) context.go('/bus-owner/staff');
          return;
      }
      if (mounted) {
        await ref.read(authProvider.notifier)
            .login(_email.text, _pass.text);
      }
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size  = MediaQuery.of(context).size;
    final isWeb = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          // Ambient orbs
          _Orb(color: _accentColor.withOpacity(0.15),
              size: 320, top: -60, left: -80),
          _Orb(color: const Color(0xFF1A56DB).withOpacity(0.18),
              size: 260, bottom: 40, right: -60),
          _Orb(color: const Color(0xFF0EA5E9).withOpacity(0.1),
              size: 200,
              top: size.height * 0.4,
              left: size.width * 0.6),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 0 : 20, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _GlassCard(
                    width: isWeb ? 500 : double.infinity,
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back + header
                          Row(
                            children: [
                              _BackButton(onTap: () => context.go('/login')),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _Header(
                            title: _title,
                            icon: _titleIcon,
                            accentColor: _accentColor,
                          ),
                          const SizedBox(height: 28),

                          // ── Common fields ───────────────────
                          _SectionLabel('Personal Info'),
                          const SizedBox(height: 12),
                          _DarkField(controller: _name,
                              label: 'Full Name',
                              icon: Icons.person_outline),
                          const SizedBox(height: 12),
                          _DarkField(controller: _email,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email' : null),
                          const SizedBox(height: 12),
                          _DarkField(controller: _phone,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboard: TextInputType.phone),
                          const SizedBox(height: 12),
                          _DarkField(
                            controller: _pass,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                                color: Colors.white.withOpacity(0.35),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 8)
                                    ? 'Min 8 characters' : null,
                          ),

                          // ── Bus owner extras ─────────────────
                          if (widget.type == 'bus_owner') ...[
                            const SizedBox(height: 24),
                            _SectionLabel('Business Details'),
                            const SizedBox(height: 12),
                            _DarkField(controller: _bizName,
                                label: 'Business Name',
                                icon: Icons.business_rounded),
                            const SizedBox(height: 12),
                            _DarkField(controller: _nic,
                                label: 'NIC Number',
                                icon: Icons.badge_outlined),
                            const SizedBox(height: 12),
                            _DarkField(controller: _address,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                required: false,
                                maxLines: 2),
                          ],

                          // ── Authority extras ─────────────────
                          if (widget.type == 'authority') ...[
                            const SizedBox(height: 24),
                            _SectionLabel('Authority Details'),
                            const SizedBox(height: 12),
                            _DarkField(controller: _designation,
                                label: 'Designation / Title',
                                icon: Icons.work_outline),
                          ],

                          // ── Staff extras ──────────────────────
                          if (widget.type == 'staff') ...[
                            const SizedBox(height: 24),
                            _SectionLabel('Staff Details'),
                            const SizedBox(height: 12),
                            _StaffTypeSelector(
                              value: _staffType,
                              onChanged: (v) =>
                                  setState(() => _staffType = v),
                            ),
                            const SizedBox(height: 12),
                            _DarkField(controller: _empId,
                                label: 'Employee ID',
                                icon: Icons.badge_rounded),
                            if (_staffType == 'driver') ...[
                              const SizedBox(height: 12),
                              _DarkField(controller: _license,
                                  label: 'License Number',
                                  icon: Icons.credit_card,
                                  required: false),
                            ],
                            const SizedBox(height: 12),
                            _DarkField(controller: _salary,
                                label: 'Base Salary (LKR)',
                                icon: Icons.attach_money,
                                keyboard: TextInputType.number,
                                required: false),
                          ],

                          // ── Error ────────────────────────────
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: _error!),
                          ],

                          const SizedBox(height: 24),

                          // ── Submit ───────────────────────────
                          _GradientButton(
                            label: widget.type == 'staff'
                                ? 'Register Staff' : 'Create Account',
                            accentColor: _accentColor,
                            isLoading: _loading,
                            onPressed: _loading ? null : _submit,
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.35)),
                                  children: [
                                    const TextSpan(
                                        text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                          color: _accentColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets (shared with login_screen.dart where possible)
// ═══════════════════════════════════════════════════════════════

class _Orb extends StatelessWidget {
  final Color  color;
  final double size;
  final double? top, bottom, left, right;
  const _Orb({required this.color, required this.size,
      this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) => Positioned(
    top: top, bottom: bottom, left: left, right: right,
    child: IgnorePointer(
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    ),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  const _GlassCard({required this.child, required this.width});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: child,
  );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.arrow_back_ios_new_rounded,
            size: 13, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 6),
        Text('Back',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6))),
      ]),
    ),
  );
}

class _Header extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    accentColor;
  const _Header({required this.title, required this.icon,
      required this.accentColor});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Icon(icon, color: accentColor, size: 22),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3)),
    ),
  ]);
}

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

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool required;
  final int maxLines;
  final TextInputType keyboard;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.required = true,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    maxLines: obscureText ? 1 : maxLines,
    keyboardType: keyboard,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    validator: validator ??
        (required
            ? (v) => (v == null || v.trim().isEmpty)
                ? '$label is required' : null
            : null),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.4), fontSize: 14),
      floatingLabelStyle: TextStyle(
          color: Colors.white.withOpacity(0.55), fontSize: 12),
      prefixIcon: Icon(icon, size: 18,
          color: Colors.white.withOpacity(0.35)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color(0xFF0EA5E9), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: Colors.red.shade400.withOpacity(0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      errorStyle: TextStyle(color: Colors.red.shade300, fontSize: 12),
    ),
  );
}

class _StaffTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StaffTypeSelector(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Column(children: [
      _StaffTile(
        staffValue: 'driver',
        groupValue: value,
        label: 'Driver',
        subtitle: 'Operates the bus',
        icon: Icons.directions_bus_rounded,
        color: const Color(0xFF38BDF8),
        onChanged: onChanged,
        isFirst: true,
      ),
      Divider(height: 1, color: Colors.white.withOpacity(0.08)),
      _StaffTile(
        staffValue: 'conductor',
        groupValue: value,
        label: 'Conductor',
        subtitle: 'Manages passengers & fares',
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFFA78BFA),
        onChanged: onChanged,
        isFirst: false,
      ),
    ]),
  );
}

class _StaffTile extends StatelessWidget {
  final String staffValue, groupValue, label, subtitle;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;
  final bool isFirst;

  const _StaffTile({
    required this.staffValue, required this.groupValue,
    required this.label, required this.subtitle,
    required this.icon, required this.color,
    required this.onChanged, required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final selected = staffValue == groupValue;
    return GestureDetector(
      onTap: () => onChanged(staffValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isFirst ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18,
                color: selected
                    ? color : Colors.white.withOpacity(0.3)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12)),
            ],
          )),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected
                      ? color : Colors.white.withOpacity(0.2),
                  width: selected ? 5 : 1.5),
              color: Colors.transparent,
            ),
          ),
        ]),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GradientButton({
    required this.label, required this.accentColor,
    this.isLoading = false, this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onPressed?.call();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: widget.onPressed == null ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A56DB),
                widget.accentColor,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(widget.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2)),
          ),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade300, size: 15),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style: TextStyle(
                color: Colors.red.shade300, fontSize: 13)),
      ),
    ]),
  );
}