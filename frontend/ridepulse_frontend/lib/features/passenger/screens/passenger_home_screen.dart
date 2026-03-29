import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});
  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
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
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'Passenger';
    return fullName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final name = _firstName(auth.fullName);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -60, right: -80,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.2),
                size: 320)),
        Positioned(bottom: 60, left: -50,
            child: _Orb(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                size: 240)),
        Positioned(top: size.height * 0.38, left: size.width * 0.52,
            child: _Orb(
                color: const Color(0xFF6330B4).withOpacity(0.1),
                size: 180)),

        Column(children: [
          // ── App bar ────────────────────────────────────
          _DarkAppBar(
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),

          // ── Scrollable body ────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                    // ── Greeting ───────────────────────
                    _GreetingBlock(name: name),
                    const SizedBox(height: 22),

                    // ── Search bar ─────────────────────
                    _SearchBar(
                        onTap: () =>
                            context.go('/passenger/search')),
                    const SizedBox(height: 28),

                    // ── Feature grid ───────────────────
                    _SectionLabel('What do you need?'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _FeatureCard(
                          icon: Icons.search_rounded,
                          label: 'Search Routes',
                          subtitle: 'Find your bus',
                          color: const Color(0xFF38BDF8),
                          onTap: () =>
                              context.go('/passenger/search')),
                        _FeatureCard(
                          icon: Icons.location_on_rounded,
                          label: 'Live Tracking',
                          subtitle: 'Track bus location',
                          color: const Color(0xFF4ADE80),
                          onTap: () =>
                              context.go('/passenger/search')),
                        _FeatureCard(
                          icon: Icons.people_rounded,
                          label: 'Crowd Level',
                          subtitle: 'See how crowded',
                          color: const Color(0xFFFBBF24),
                          onTap: () =>
                              context.go('/passenger/search')),
                        _FeatureCard(
                          icon: Icons.auto_graph_rounded,
                          label: 'Crowd Forecast',
                          subtitle: 'AI prediction',
                          color: const Color(0xFFC084FC),
                          onTap: () =>
                              context.go('/passenger/search')),
                        _FeatureCard(
                          icon: Icons.report_problem_rounded,
                          label: 'My Complaints',
                          subtitle: 'View & track',
                          color: const Color(0xFFF87171),
                          onTap: () => context
                              .go('/passenger/complaints')),
                        _FeatureCard(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Tickets',
                          subtitle: 'Coming soon',
                          color: const Color(0xFF94A3B8),
                          isComingSoon: true,
                          onTap: () => _showComingSoonDialog(
                              context, 'Ticket Booking')),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Dialog helper ─────────────────────────────────────────────

void _showComingSoonDialog(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: const Color(0xFF131C2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFB923C).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      const Color(0xFFFB923C).withOpacity(0.25)),
            ),
            child: const Icon(Icons.construction_rounded,
                color: Color(0xFFFB923C), size: 30),
          ),
          const SizedBox(height: 18),
          Text(feature,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
              '$feature will be available in the next update.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity, height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Got it',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _DarkAppBar extends StatelessWidget {
  final VoidCallback onLogout;
  const _DarkAppBar({required this.onLogout});

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
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_bus_rounded,
            size: 18, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('RidePulse',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('Passenger portal',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: onLogout,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withOpacity(0.09)),
          ),
          child: Icon(Icons.logout_rounded,
              size: 16, color: Colors.white.withOpacity(0.6)),
        ),
      ),
    ]),
  );
}

class _GreetingBlock extends StatelessWidget {
  final String name;
  const _GreetingBlock({required this.name});

  @override
  Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4),
        children: [
          const TextSpan(text: 'Hello, '),
          TextSpan(
            text: name,
            style: const TextStyle(color: Color(0xFF0EA5E9)),
          ),
          const TextSpan(text: '!'),
        ],
      ),
    ),
    const SizedBox(height: 5),
    Text('Where are you going today?',
        style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 14)),
  ]);
}

class _SearchBar extends StatefulWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.search_rounded,
                color: Color(0xFF38BDF8), size: 17),
          ),
          const SizedBox(width: 12),
          Text('Search bus route or destination…',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.28),
                  fontSize: 14)),
          const Spacer(),
          Icon(Icons.tune_rounded,
              size: 18,
              color: Colors.white.withOpacity(0.2)),
        ]),
      ),
    ),
  );
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

class _FeatureCard extends StatefulWidget {
  final IconData     icon;
  final String       label, subtitle;
  final Color        color;
  final bool         isComingSoon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isComingSoon
              ? Colors.white.withOpacity(0.03)
              : widget.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: widget.isComingSoon
                  ? Colors.white.withOpacity(0.07)
                  : widget.color.withOpacity(0.22)),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
          // Icon + optional lock badge
          Stack(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.isComingSoon
                    ? Colors.white.withOpacity(0.05)
                    : widget.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon,
                  color: widget.isComingSoon
                      ? Colors.white.withOpacity(0.2)
                      : widget.color,
                  size: 18),
            ),
            if (widget.isComingSoon)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFB923C),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 8),
                ),
              ),
          ]),

          // Label + subtitle
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(widget.label,
                style: TextStyle(
                    color: widget.isComingSoon
                        ? Colors.white.withOpacity(0.3)
                        : widget.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(widget.subtitle,
                style: TextStyle(
                    color: widget.isComingSoon
                        ? Colors.white.withOpacity(0.18)
                        : widget.color.withOpacity(0.55),
                    fontSize: 10)),
          ]),
        ]),
      ),
    ),
  );
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