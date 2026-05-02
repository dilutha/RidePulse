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

class _State extends ConsumerState<AuthorityComplaintListScreen> {
  String? _status;
  String? _category;

  static const _statuses   = ['submitted', 'under_review', 'resolved', 'rejected'];
  static const _categories = ['crowding', 'driver_behavior', 'delay', 'cleanliness', 'safety', 'other'];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(authorityComplaintsProvider(
        (status: _status, category: _category)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('All Complaints')),
      body: Column(children: [
        // Status filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            FilterChip(
              label: const Text('All'),
              selected: _status == null,
              onSelected: (_) => setState(() => _status = null)),
            const SizedBox(width: 8),
            ..._statuses.map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(s.replaceAll('_', ' ')),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = _status == s ? null : s),
                selectedColor: const Color(0xFF7C3AED).withOpacity(0.15)))),
          ]),
        ),
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: _categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(c.replaceAll('_', ' ')),
              selected: _category == c,
              onSelected: (_) => setState(() => _category = _category == c ? null : c),
              selectedColor: const Color(0xFF7C3AED).withOpacity(0.15)),
          )).toList()),
        ),
        const Divider(height: 1),
        Expanded(child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text('Error: $e')),
          data: (list) => list.isEmpty
              ? const Center(child: Text('No complaints found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ComplaintCard(
                      c: list[i],
                      onTap: () => context.go('/authority/complaints/${list[i].complaintId}'))),
        )),
      ]),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintSummary c;
  final VoidCallback onTap;
  const _ComplaintCard({required this.c, required this.onTap});

  Color get _sc => switch (c.status) {
    'resolved'     => const Color(0xFF10B981),
    'rejected'     => const Color(0xFFEF4444),
    'under_review' => const Color(0xFFF59E0B),
    _              => const Color(0xFF6B7280),
  };

  Color get _pc => switch (c.priority) {
    'high'   => const Color(0xFFEF4444),
    'medium' => const Color(0xFFF59E0B),
    _        => const Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _sc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(c.status.replaceAll('_', ' '),
                  style: TextStyle(color: _sc, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _pc.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(c.priority.toUpperCase(),
                  style: TextStyle(color: _pc, fontSize: 10, fontWeight: FontWeight.w700))),
            const Spacer(),
            Text(c.category.replaceAll('_', ' '),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Text('${c.passengerName} · Bus: ${c.busNumber}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          Text(c.submittedAt, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ]),
      ),
    ),
  );
}
