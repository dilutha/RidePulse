import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/complaint_models.dart';

class AuthorityComplaintListScreen extends ConsumerStatefulWidget {
  const AuthorityComplaintListScreen({super.key});
  @override
  ConsumerState<AuthorityComplaintListScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityComplaintListScreen>
    with SingleTickerProviderStateMixin {
  String? _status;
  String? _category;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _statuses = [
    'submitted', 'under_review', 'resolved', 'rejected'
  ];
  static const _categories = [
    'crowding', 'driver_behavior', 'delay',
    'cleanliness', 'safety', 'other'
  ];

  static Color _statusColor(String s) => switch (s) {
    'resolved'     => const Color(0xFF4ADE80),
    'rejected'     => const Color(0xFFF87171),
    'under_review' => const Color(0xFFFBBF24),
    _              => const Color(0xFF94A3B8),
  };

  static IconData _statusIcon(String s) => switch (s) {
    'resolved'     => Icons.check_circle_rounded,
    'rejected'     => Icons.cancel_rounded,
    'under_review' => Icons.hourglass_bottom_rounded,
    _              => Icons.inbox_rounded,
  };

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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(authorityComplaintsProvider(
        (status: _status, category: _category)));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -40, right: -60,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.18),
                size: 280)),
        Positioned(bottom: 80, left: -40,
            child: _Orb(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                size: 200)),

        Column(children: [
          // ── Custom AppBar ─────────────────────────────────
          _AppHeader(),

          // ── Status filter row ─────────────────────────────
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(children: [
                  _FilterPill(
                    label: 'All',
                    selected: _status == null,
                    color: const Color(0xFF0EA5E9),
                    onTap: () => setState(() => _status = null),
                  ),
                  const SizedBox(width: 8),
                  ..._statuses.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterPill(
                      label: s.replaceAll('_', ' '),
                      selected: _status == s,
                      color: _statusColor(s),
                      icon: _statusIcon(s),
                      onTap: () => setState(() =>
                          _status = _status == s ? null : s),
                    ),
                  )),
                ]),
              ),

              // ── Category filter row ───────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(children: _categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterPill(
                    label: c.replaceAll('_', ' '),
                    selected: _category == c,
                    color: const Color(0xFFC084FC),
                    small: true,
                    onTap: () => setState(() =>
                        _category = _category == c ? null : c),
                  ),
                )).toList()),
              ),

              Divider(height: 1,
                  color: Colors.white.withOpacity(0.07)),
            ]),
          ),

          // ── List ──────────────────────────────────────────
          Expanded(child: async.when(
            loading: () => const _LoadingState(),
            error: (e, _) => _ErrorState(message: e.toString()),
            data: (list) {
              if (list.isEmpty) return const _EmptyState();
              return FadeTransition(
                opacity: _fadeAnim,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ComplaintCard(
                    c: list[i],
                    onTap: () => context.go(
                        '/authority/complaints/${list[i].complaintId}'),
                  ),
                ),
              );
            },
          )),
        ]),
      ]),
    );
  }
}

// ── App header ────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20, right: 20, bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A56DB).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF1A56DB).withOpacity(0.3)),
        ),
        child: const Icon(Icons.inbox_rounded,
            size: 18, color: Color(0xFF0EA5E9)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Text('All Complaints',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          Text('Authority dashboard',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12)),
        ]),
      ),
    ]),
  );
}

// ── Filter pill ───────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String    label;
  final bool      selected;
  final Color     color;
  final IconData? icon;
  final bool      small;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 12,
          vertical: small ? 5 : 7),
      decoration: BoxDecoration(
        color: selected
            ? color.withOpacity(0.12)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected
                ? color.withOpacity(0.4)
                : Colors.white.withOpacity(0.09),
            width: selected ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null && selected) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontSize: small ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? color
                    : Colors.white.withOpacity(0.4))),
      ]),
    ),
  );
}

// ── Complaint card ────────────────────────────────────────────

class _ComplaintCard extends StatefulWidget {
  final ComplaintSummary c;
  final VoidCallback     onTap;
  const _ComplaintCard({required this.c, required this.onTap});

  @override
  State<_ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<_ComplaintCard> {
  bool _pressed = false;

  Color get _sc => switch (widget.c.status) {
    'resolved'     => const Color(0xFF4ADE80),
    'rejected'     => const Color(0xFFF87171),
    'under_review' => const Color(0xFFFBBF24),
    _              => const Color(0xFF94A3B8),
  };

  IconData get _si => switch (widget.c.status) {
    'resolved'     => Icons.check_circle_rounded,
    'rejected'     => Icons.cancel_rounded,
    'under_review' => Icons.hourglass_bottom_rounded,
    _              => Icons.inbox_rounded,
  };

  Color get _pc => switch (widget.c.priority) {
    'high'   => const Color(0xFFF87171),
    'medium' => const Color(0xFFFBBF24),
    _        => const Color(0xFF94A3B8),
  };

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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Status + priority + category
            Row(children: [
              _MiniTag(
                  label: widget.c.status.replaceAll('_', ' '),
                  color: _sc, icon: _si),
              const SizedBox(width: 6),
              _MiniTag(label: widget.c.priority, color: _pc),
              const Spacer(),
              Text(widget.c.category.replaceAll('_', ' '),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11)),
            ]),

            const SizedBox(height: 10),

            // Passenger + bus
            Row(children: [
              Icon(Icons.person_outline,
                  size: 14,
                  color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 5),
              Text(widget.c.passengerName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text('  ·  ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2))),
              Icon(Icons.directions_bus_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 4),
              Text(widget.c.busNumber,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13)),
            ]),

            const SizedBox(height: 8),

            // Description snippet
            Text(widget.c.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    height: 1.5)),

            const SizedBox(height: 10),

            // Footer: date + chevron
            Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 12,
                  color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 4),
              Text(widget.c.submittedAt,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 11)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.2)),
            ]),
          ]),
        ),
      ),
    ),
  );
}

class _MiniTag extends StatelessWidget {
  final String    label;
  final Color     color;
  final IconData? icon;
  const _MiniTag(
      {required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
      ],
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3)),
    ]),
  );
}

// ── Utility widgets ───────────────────────────────────────────

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
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 28, height: 28,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.4),
              strokeWidth: 2)),
      const SizedBox(height: 14),
      Text('Loading complaints...',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 13)),
    ]),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 40,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message.replaceFirst('Exception: ', ''),
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
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.inbox_rounded,
            size: 28,
            color: Colors.white.withOpacity(0.2)),
      ),
      const SizedBox(height: 14),
      Text('No complaints found',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Try adjusting your filters',
          style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12)),
    ]),
  );
}