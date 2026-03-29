import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/complaint_models.dart';

final _busOwnerComplaintsProvider = FutureProvider.autoDispose
    .family<List<ComplaintSummary>, String>((ref, status) async {
  return ref
      .read(apiServiceProvider)
      .getBusOwnerComplaints(status: status);
});

class BusOwnerComplaintsScreen extends ConsumerStatefulWidget {
  const BusOwnerComplaintsScreen({super.key});
  @override
  ConsumerState<BusOwnerComplaintsScreen> createState() => _State();
}

class _State extends ConsumerState<BusOwnerComplaintsScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'all';

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _statuses = [
    'all', 'submitted', 'under_review', 'resolved', 'rejected'
  ];

  static Color _statusColor(String s) => switch (s) {
    'resolved'     => const Color(0xFF4ADE80),
    'rejected'     => const Color(0xFFF87171),
    'under_review' => const Color(0xFFFBBF24),
    'submitted'    => const Color(0xFF94A3B8),
    _              => const Color(0xFF0EA5E9),
  };

  static IconData _statusIcon(String s) => switch (s) {
    'resolved'     => Icons.check_circle_rounded,
    'rejected'     => Icons.cancel_rounded,
    'under_review' => Icons.hourglass_bottom_rounded,
    'submitted'    => Icons.inbox_rounded,
    _              => Icons.filter_list_rounded,
  };

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

  void _setStatus(String s) {
    setState(() => _status = s);
    _fadeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_busOwnerComplaintsProvider(_status));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFFFB923C).withOpacity(0.13),
                size: 280)),
        Positioned(bottom: 60, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.14),
                size: 220)),

        Column(children: [
          // ── App bar ────────────────────────────────────
          _DarkAppBar(),

          // ── Filter chips ───────────────────────────────
          _FilterRow(
            statuses:  _statuses,
            selected:  _status,
            colorOf:   _statusColor,
            iconOf:    _statusIcon,
            onSelect:  _setStatus,
          ),

          // ── List ───────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: async.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(
                    message: e.toString()
                        .replaceFirst('Exception: ', '')),
                data: (list) => list.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            16, 14, 16, 32),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            _ComplaintCard(c: list[i]),
                      ),
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
          gradient: const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.report_problem_rounded,
            size: 17, color: Colors.white),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Complaints',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        Text('About your buses',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Filter row ────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final List<String> statuses;
  final String       selected;
  final Color  Function(String) colorOf;
  final IconData Function(String) iconOf;
  final ValueChanged<String>    onSelect;
  const _FilterRow({
    required this.statuses, required this.selected,
    required this.colorOf,  required this.iconOf,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      border: Border(
          bottom: BorderSide(
              color: Colors.white.withOpacity(0.07))),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: statuses.map((s) {
          final sel   = selected == s;
          final color = colorOf(s);
          final icon  = iconOf(s);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel
                          ? color.withOpacity(0.4)
                          : Colors.white.withOpacity(0.09),
                      width: sel ? 1.5 : 1),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  if (sel) ...[
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 5),
                  ],
                  Text(s.replaceAll('_', ' '),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? color
                              : Colors.white.withOpacity(0.4))),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

// ── Complaint card ────────────────────────────────────────────

class _ComplaintCard extends StatefulWidget {
  final ComplaintSummary c;
  const _ComplaintCard({required this.c});
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

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

            // Top row: name + status badge
            Row(children: [
              Expanded(
                child: Text(c.passengerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              _MiniTag(
                  label: c.status.replaceAll('_', ' '),
                  color: _sc,
                  icon: _si),
            ]),

            const SizedBox(height: 6),

            // Bus + category
            Row(children: [
              Icon(Icons.directions_bus_rounded,
                  size: 13,
                  color: Colors.white.withOpacity(0.25)),
              const SizedBox(width: 4),
              Text(c.busNumber,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Text('  ·  ',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2))),
              Icon(Icons.category_outlined,
                  size: 12,
                  color: Colors.white.withOpacity(0.25)),
              const SizedBox(width: 4),
              Text(c.category.replaceAll('_', ' '),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12)),
            ]),

            const SizedBox(height: 10),

            // Description
            Text(c.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    height: 1.5)),

            const SizedBox(height: 10),

            // Footer: timestamp
            Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 12,
                  color: Colors.white.withOpacity(0.2)),
              const SizedBox(width: 4),
              Text(c.submittedAt,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String    label;
  final Color     color;
  final IconData? icon;
  const _MiniTag(
      {required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
  final Color color; final double size;
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
      SizedBox(width: 26, height: 26,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.4),
              strokeWidth: 2)),
      const SizedBox(height: 12),
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
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: 38,
            color: Colors.red.shade300.withOpacity(0.5)),
        const SizedBox(height: 10),
        Text('Failed to load',
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
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle),
        child: Icon(Icons.inbox_rounded,
            size: 28, color: Colors.white.withOpacity(0.2)),
      ),
      const SizedBox(height: 12),
      Text('No complaints found',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text('Try a different filter',
          style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12)),
    ]),
  );
}