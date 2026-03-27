import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/complaint_models.dart';

class AuthorityComplaintDetailScreen extends ConsumerStatefulWidget {
  final int complaintId;
  const AuthorityComplaintDetailScreen(
      {super.key, required this.complaintId});
  @override
  ConsumerState<AuthorityComplaintDetailScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityComplaintDetailScreen> {
  late Future<ComplaintDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = ref
        .read(apiServiceProvider)
        .getComplaintDetail(widget.complaintId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        appBar: _DarkAppBar(
          title: 'Complaint #${widget.complaintId}',
          onBack: () => context.go('/authority/complaints'),
        ),
        body: FutureBuilder<ComplaintDetail>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const _LoadingState();
            if (snap.hasError)
              return _ErrorState(message: snap.error.toString());
            return _Body(
              detail: snap.data!,
              onDecision: (action, note, feedback) async {
                await ref.read(apiServiceProvider).makeComplaintDecision(
                    complaintId: widget.complaintId,
                    action: action,
                    resolutionNote: note,
                    authorityFeedback: feedback);
                setState(() {
                  _future = ref
                      .read(apiServiceProvider)
                      .getComplaintDetail(widget.complaintId);
                });
                ref.invalidate(authorityComplaintsProvider);
                ref.invalidate(complaintStatsProvider);
                if (mounted) {
                  _showToast(context, 'Decision saved successfully',
                      isError: false);
                }
              },
            );
          },
        ),
      );
}

// ── AppBar ────────────────────────────────────────────────────

class _DarkAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  const _DarkAppBar({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => Container(
        height: 64 + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Row(children: [
          const SizedBox(width: 8),
          _BackButton(onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2)),
          ),
        ]),
      );
}

// ── Body ──────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final ComplaintDetail detail;
  final Future<void> Function(String, String, String) onDecision;
  const _Body({required this.detail, required this.onDecision});
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _note     = TextEditingController();
  final _feedback = TextEditingController();
  String _action  = 'resolve';
  bool   _loading = false;

  @override
  void dispose() {
    _note.dispose();
    _feedback.dispose();
    super.dispose();
  }

  // Status theming
  Color get _statusColor => switch (widget.detail.status) {
    'resolved'     => const Color(0xFF4ADE80),
    'rejected'     => const Color(0xFFF87171),
    'under_review' => const Color(0xFFFBBF24),
    _              => const Color(0xFF94A3B8),
  };

  IconData get _statusIcon => switch (widget.detail.status) {
    'resolved'     => Icons.check_circle_rounded,
    'rejected'     => Icons.cancel_rounded,
    'under_review' => Icons.hourglass_bottom_rounded,
    _              => Icons.inbox_rounded,
  };

  Color get _priorityColor => switch (widget.detail.priority) {
    'high'   => const Color(0xFFF87171),
    'medium' => const Color(0xFFFBBF24),
    _        => const Color(0xFF94A3B8),
  };

  Color get _actionColor => switch (_action) {
    'resolve' => const Color(0xFF4ADE80),
    'reject'  => const Color(0xFFF87171),
    _         => const Color(0xFFFBBF24),
  };

  bool get _alreadyDecided =>
      widget.detail.status == 'resolved' ||
      widget.detail.status == 'rejected';

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // Ambient orbs
      Positioned(top: -40, right: -60,
          child: _Orb(color: _statusColor.withOpacity(0.1), size: 220)),
      Positioned(bottom: 60, left: -40,
          child: _Orb(color: const Color(0xFF1A56DB).withOpacity(0.12), size: 180)),

      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Status + priority row ─────────────────────────
          Row(children: [
            _StatusBadge(
              label: widget.detail.status.replaceAll('_', ' '),
              color: _statusColor,
              icon: _statusIcon,
            ),
            const SizedBox(width: 8),
            _PriorityBadge(
              label: widget.detail.priority,
              color: _priorityColor,
            ),
          ]),
          const SizedBox(height: 20),

          // ── Complaint info card ───────────────────────────
          _GlassCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CardHeader(
                  title: 'Complaint Info',
                  icon: Icons.info_outline_rounded),
              const SizedBox(height: 16),
              _InfoRow(label: 'Passenger',
                  value: widget.detail.passengerName,
                  icon: Icons.person_outline),
              _InfoRow(label: 'Phone',
                  value: widget.detail.passengerPhone ?? 'N/A',
                  icon: Icons.phone_outlined),
              _InfoRow(label: 'Bus',
                  value: widget.detail.busNumber,
                  icon: Icons.directions_bus_rounded),
              _InfoRow(label: 'Route',
                  value: widget.detail.routeName,
                  icon: Icons.route_rounded),
              _InfoRow(label: 'Category',
                  value: widget.detail.category.replaceAll('_', ' '),
                  icon: Icons.category_outlined),
              _InfoRow(label: 'Filed',
                  value: widget.detail.submittedAt,
                  icon: Icons.calendar_today_outlined,
                  isLast: true),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Description card ──────────────────────────────
          _GlassCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CardHeader(
                  title: 'Description',
                  icon: Icons.description_outlined),
              const SizedBox(height: 12),
              Text(widget.detail.description,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.6)),
            ]),
          ),

          // ── Existing feedback ─────────────────────────────
          if (_alreadyDecided &&
              widget.detail.authorityFeedback != null) ...[
            const SizedBox(height: 12),
            _GlassCard(
              accentColor: const Color(0xFF4ADE80),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _CardHeader(
                    title: 'Your Response to Passenger',
                    icon: Icons.mark_email_read_outlined,
                    color: const Color(0xFF4ADE80)),
                const SizedBox(height: 12),
                Text(widget.detail.authorityFeedback!,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.6)),
              ]),
            ),
          ],

          // ── Decision form ─────────────────────────────────
          if (!_alreadyDecided) ...[
            const SizedBox(height: 24),
            _SectionLabel('Make a Decision'),
            const SizedBox(height: 14),

            // Action selector
            _ActionSelector(
              value: _action,
              onChanged: (v) => setState(() => _action = v),
            ),
            const SizedBox(height: 16),

            _DarkTextArea(
              controller: _note,
              label: 'Internal Resolution Note',
              hint: 'What corrective action was taken? (not shown to passenger)',
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 12),

            _DarkTextArea(
              controller: _feedback,
              label: 'Feedback for Passenger',
              hint: 'What should the passenger know about this outcome?',
              icon: Icons.chat_bubble_outline_rounded,
              required: true,
            ),
            const SizedBox(height: 24),

            _SubmitButton(
              action: _action,
              color: _actionColor,
              isLoading: _loading,
              onPressed: () async {
                if (_note.text.isEmpty || _feedback.text.isEmpty) {
                  _showToast(context, 'Please fill both fields',
                      isError: true);
                  return;
                }
                setState(() => _loading = true);
                await widget.onDecision(
                    _action, _note.text, _feedback.text);
                setState(() => _loading = false);
              },
            ),
          ],
        ]),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    ),
  );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Icon(Icons.arrow_back_ios_new_rounded,
          size: 15, color: Colors.white.withOpacity(0.7)),
    ),
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: accentColor != null
          ? accentColor!.withOpacity(0.06)
          : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: accentColor != null
              ? accentColor!.withOpacity(0.2)
              : Colors.white.withOpacity(0.09)),
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String   title;
  final IconData icon;
  final Color    color;
  const _CardHeader(
      {required this.title,
      required this.icon,
      this.color = const Color(0xFF0EA5E9)});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: color),
    ),
    const SizedBox(width: 10),
    Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final bool     isLast;
  const _InfoRow(
      {required this.label,
      required this.value,
      required this.icon,
      this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.white.withOpacity(0.25)),
        const SizedBox(width: 10),
        SizedBox(
          width: 82,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.35))),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    ),
    if (!isLast)
      Divider(height: 1, color: Colors.white.withOpacity(0.06)),
  ]);
}

class _StatusBadge extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData icon;
  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 6),
      Text(label.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
    ]),
  );
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Text(label.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5)),
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
    Expanded(
        child: Divider(
            color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _ActionSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ActionSelector(
      {required this.value, required this.onChanged});

  static const _options = [
    (value: 'resolve', label: 'Resolve',
        icon: Icons.check_circle_outline, color: Color(0xFF4ADE80)),
    (value: 'review', label: 'Under Review',
        icon: Icons.hourglass_bottom_rounded, color: Color(0xFFFBBF24)),
    (value: 'reject', label: 'Reject',
        icon: Icons.cancel_outlined, color: Color(0xFFF87171)),
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: _options.map((o) {
      final selected = value == o.value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(o.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(
                right: o.value != 'reject' ? 8 : 0),
            padding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? o.color.withOpacity(0.12)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected
                      ? o.color.withOpacity(0.4)
                      : Colors.white.withOpacity(0.09),
                  width: selected ? 1.5 : 1),
            ),
            child: Column(children: [
              Icon(o.icon,
                  size: 18,
                  color: selected
                      ? o.color
                      : Colors.white.withOpacity(0.3)),
              const SizedBox(height: 5),
              Text(o.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? o.color
                          : Colors.white.withOpacity(0.3))),
            ]),
          ),
        ),
      );
    }).toList(),
  );
}

class _DarkTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String   label, hint;
  final IconData icon;
  final bool     required;
  const _DarkTextArea({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: 3,
    style: TextStyle(
        color: Colors.white.withOpacity(0.85), fontSize: 14),
    decoration: InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.4), fontSize: 13),
      floatingLabelStyle: TextStyle(
          color: Colors.white.withOpacity(0.55), fontSize: 12),
      hintText: hint,
      hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2), fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Icon(icon, size: 18,
            color: Colors.white.withOpacity(0.3)),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
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

class _SubmitButton extends StatefulWidget {
  final String   action;
  final Color    color;
  final bool     isLoading;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.action, required this.color,
    required this.isLoading, required this.onPressed,
  });

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  String get _label => switch (widget.action) {
    'resolve' => 'Submit & Resolve',
    'reject'  => 'Submit & Reject',
    _         => 'Submit & Mark Under Review',
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      if (!widget.isLoading) widget.onPressed();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A56DB), widget.color],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.send_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(_label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ]),
        ),
      ),
    ),
  );
}

// ── States ────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(width: 32, height: 32,
          child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.5), strokeWidth: 2)),
      const SizedBox(height: 16),
      Text('Loading complaint...',
          style: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 14)),
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
            size: 44, color: Colors.red.shade300.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text('Something went wrong',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(message.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3), fontSize: 13)),
      ]),
    ),
  );
}

// ── Toast helper ──────────────────────────────────────────────

void _showToast(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white, size: 16,
        ),
        const SizedBox(width: 8),
        Text(message,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
      backgroundColor:
          isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ),
  );
}