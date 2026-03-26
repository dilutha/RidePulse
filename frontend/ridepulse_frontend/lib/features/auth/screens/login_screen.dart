// ============================================================
// features/auth/screens/login_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _obscure = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authProvider.notifier)
        .login(_email.text.trim(), _pass.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final size  = MediaQuery.of(context).size;
    final isWeb = size.width > 700;

    ref.listen(authProvider, (_, next) {
      if (next.isLoggedIn) {
        final dest = switch (next.role) {
          'bus_owner'  => '/bus-owner/dashboard',
          'driver'     => '/driver/home',
          'conductor'  => '/conductor/home',
          'passenger'  => '/passenger/home',
          'authority'  => '/authority/dashboard',
          _            => '/login',
        };
        context.go(dest);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(
        children: [
          // ── Ambient orbs ──────────────────────────────────
          _Orb(color: const Color(0xFF1A56DB).withOpacity(0.22),
              size: 340, top: -60, left: -80),
          _Orb(color: const Color(0xFF0EA5E9).withOpacity(0.14),
              size: 260, bottom: 40, right: -60),
          _Orb(color: const Color(0xFF6330B4).withOpacity(0.12),
              size: 180,
              top: size.height * 0.45,
              left: size.width * 0.55),

          // ── Content ───────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 0 : 20, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _GlassCard(
                    width: isWeb ? 420 : double.infinity,
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo row
                          Row(children: [
                            _LogoIcon(),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3),
                                  children: [
                                    TextSpan(text: 'Ride'),
                                    TextSpan(text: 'Pulse',
                                        style: TextStyle(
                                            color: Color(0xFF0EA5E9))),
                                  ],
                                )),
                                const SizedBox(height: 2),
                                Text('Transit management platform',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.4))),
                              ],
                            ),
                          ]),

                          const SizedBox(height: 24),
                          Divider(color: Colors.white.withOpacity(0.08),
                              height: 1),
                          const SizedBox(height: 24),

                          // Error banner
                          if (auth.error != null) ...[
                            _ErrorBanner(message: auth.error!),
                            const SizedBox(height: 14),
                          ],

                          // Email
                          _FieldLabel('Email address'),
                          const SizedBox(height: 7),
                          _DarkField(
                            controller: _email,
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email' : null,
                          ),

                          const SizedBox(height: 14),

                          // Password
                          _FieldLabel('Password'),
                          const SizedBox(height: 7),
                          _DarkField(
                            controller: _pass,
                            hint: '••••••••',
                            obscureText: _obscure,
                            prefixIcon: Icons.lock_outline,
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
                                (v == null || v.length < 6)
                                    ? 'Min 6 characters' : null,
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 8)),
                              child: const Text('Forgot password?',
                                  style: TextStyle(
                                      color: Color(0xFF0EA5E9),
                                      fontSize: 12)),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Sign in button
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: _GradientButton(
                              onPressed: auth.isLoading ? null : _login,
                              isLoading: auth.isLoading,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Separator
                          Row(children: [
                            Expanded(child: Divider(
                                color: Colors.white.withOpacity(0.08),
                                height: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              child: Text('New to RidePulse?',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.25))),
                            ),
                            Expanded(child: Divider(
                                color: Colors.white.withOpacity(0.08),
                                height: 1)),
                          ]),

                          const SizedBox(height: 14),
                          Center(
                            child: Text('Create an account as',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.35))),
                          ),
                          const SizedBox(height: 12),

                          // Role chips
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _RoleChip(
                                label: 'Passenger',
                                icon: Icons.person,
                                color: const Color(0xFF4ADE80),
                                onTap: () => context.go('/register/passenger'),
                              ),
                              _RoleChip(
                                label: 'Bus Owner',
                                icon: Icons.business,
                                color: const Color(0xFFFB923C),
                                onTap: () => context.go('/register/bus-owner'),
                              ),
                              _RoleChip(
                                label: 'Authority',
                                icon: Icons.admin_panel_settings,
                                color: const Color(0xFFC084FC),
                                onTap: () => context.go('/register/authority'),
                              ),
                            ],
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

// ── Sub-widgets ────────────────────────────────────────────────

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
          color: color,
        ),
        // Simulated blur via layered opacity containers
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0)],
              stops: const [0.0, 1.0],
            ),
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

class _LogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.directions_bus_rounded,
        color: Colors.white, size: 22),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: Colors.white.withOpacity(0.45),
    ),
  );
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.22),
          fontSize: 14),
      prefixIcon: Icon(prefixIcon, size: 18,
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

class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _GradientButton({this.onPressed, this.isLoading = false});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Sign in',
                      style: TextStyle(
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
            style: TextStyle(color: Colors.red.shade300, fontSize: 13)),
      ),
    ]),
  );
}

class _RoleChip extends StatefulWidget {
  final String    label;
  final IconData  icon;
  final Color     color;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  State<_RoleChip> createState() => _RoleChipState();
}

class _RoleChipState extends State<_RoleChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit:  (_) => setState(() => _hovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_hovered ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 14, color: widget.color),
          const SizedBox(width: 6),
          Text(widget.label,
              style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}