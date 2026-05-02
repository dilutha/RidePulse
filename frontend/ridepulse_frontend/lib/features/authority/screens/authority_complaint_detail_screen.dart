import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/complaint_models.dart';

class AuthorityComplaintDetailScreen extends ConsumerStatefulWidget {
  final int complaintId;
  const AuthorityComplaintDetailScreen({super.key, required this.complaintId});
  @override
  ConsumerState<AuthorityComplaintDetailScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityComplaintDetailScreen> {
  late Future<ComplaintDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiServiceProvider)
        .getComplaintDetail(widget.complaintId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Complaint Detail'),
      leading: IconButton(icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/authority/complaints'))),
    body: FutureBuilder<ComplaintDetail>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        return _Body(
          detail: snap.data!,
          onDecision: (action, note, feedback) async {
            await ref.read(apiServiceProvider).makeComplaintDecision(
              complaintId: widget.complaintId,
              action: action, resolutionNote: note,
              authorityFeedback: feedback);
            setState(() {
              _future = ref.read(apiServiceProvider)
                  .getComplaintDetail(widget.complaintId);
            });
            ref.invalidate(authorityComplaintsProvider);
            ref.invalidate(complaintStatsProvider);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Decision saved'),
                    backgroundColor: Colors.green));
            }
          });
      },
    ),
  );
}

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

  Color get _sc => switch (widget.detail.status) {
    'resolved'     => const Color(0xFF10B981),
    'rejected'     => const Color(0xFFEF4444),
    'under_review' => const Color(0xFFF59E0B),
    _              => const Color(0xFF6B7280),
  };

  bool get _alreadyDecided =>
      widget.detail.status == 'resolved' ||
      widget.detail.status == 'rejected';

  @override
  void dispose() { _note.dispose(); _feedback.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status badge
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: _sc.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(widget.detail.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(color: _sc, fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Text('Priority: ${widget.detail.priority.toUpperCase()}',
            style: const TextStyle(color: Colors.grey)),
      ]),
      const SizedBox(height: 16),

      // Complaint info card
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Complaint Info', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _row('Passenger', widget.detail.passengerName),
          _row('Phone',     widget.detail.passengerPhone ?? 'N/A'),
          _row('Bus',       widget.detail.busNumber),
          _row('Route',     widget.detail.routeName),
          _row('Category',  widget.detail.category.replaceAll('_', ' ')),
          _row('Filed',     widget.detail.submittedAt),
        ]),
      )),
      const SizedBox(height: 12),

      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.detail.description,
              style: TextStyle(color: Colors.grey.shade800)),
        ]),
      )),

      // If already resolved — show existing feedback
      if (_alreadyDecided && widget.detail.authorityFeedback != null) ...[
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFFF0FDF4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Response to Passenger',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46))),
              const SizedBox(height: 8),
              Text(widget.detail.authorityFeedback!),
            ]),
          ),
        ),
      ],

      // Decision form — only for pending complaints
      if (!_alreadyDecided) ...[
        const SizedBox(height: 20),
        const Text('Make Decision',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Action selector
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'resolve', label: Text('Resolve'),
                icon: Icon(Icons.check_circle_outline, size: 16)),
            ButtonSegment(value: 'review', label: Text('Under Review'),
                icon: Icon(Icons.hourglass_empty, size: 16)),
            ButtonSegment(value: 'reject', label: Text('Reject'),
                icon: Icon(Icons.cancel_outlined, size: 16)),
          ],
          selected: {_action},
          onSelectionChanged: (s) => setState(() => _action = s.first)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _note, maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Internal Resolution Note',
            hintText: 'What corrective action was taken? (not shown to passenger)',
            border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextFormField(
          controller: _feedback, maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Feedback for Passenger *',
            hintText: 'What should the passenger know about the outcome?',
            border: OutlineInputBorder())),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : () async {
              if (_note.text.isEmpty || _feedback.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill both fields'),
                        backgroundColor: Colors.red));
                return;
              }
              setState(() => _loading = true);
              await widget.onDecision(_action, _note.text, _feedback.text);
              setState(() => _loading = false);
            },
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Decision',
                    style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    ]),
  );

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(k,
          style: const TextStyle(color: Colors.grey, fontSize: 13))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 13))),
    ]),
  );
}
