// ============================================================
// features/authority/screens/authority_fare_screen.dart
// Authority sets bus fares per route
// Min: LKR 30 | +8 per stop | Max: LKR 2422
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/authority_models.dart";

class AuthorityFareScreen extends ConsumerStatefulWidget {
  const AuthorityFareScreen({super.key});
  @override
  ConsumerState<AuthorityFareScreen> createState() => _State();
}

class _State extends ConsumerState<AuthorityFareScreen> {
  String _search = "";
  FareConfig? _editing;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(authorityFaresProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Bus Fare Management"),
        actions: [IconButton(icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(authorityFaresProvider))]),
      body: Column(children: [
        // Fare rules banner
        Container(
          color: const Color(0xFF059669).withOpacity(0.05),
          padding: const EdgeInsets.all(14),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFF059669), size: 18),
            SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Sri Lanka NTPS Fare Rules",
                  style: TextStyle(fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46), fontSize: 13)),
              SizedBox(height: 2),
              Text("Minimum: LKR 30  ·  Per additional stop: +LKR 8  ·  Maximum: LKR 2,422",
                  style: TextStyle(color: Color(0xFF065F46), fontSize: 11)),
            ])),
          ])),
        Container(color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search route...",
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true, fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 16)))),
        const Divider(height: 1),
        Expanded(child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => Center(child: Text("Error: \$e")),
          data: (fares) {
            final f = _search.isEmpty ? fares
                : fares.where((r) =>
                    r.routeNumber.toLowerCase().contains(_search) ||
                    r.routeName.toLowerCase().contains(_search)).toList();
            if (f.isEmpty) return const Center(
                child: Text("No routes found",
                    style: TextStyle(color: Colors.grey)));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: f.length,
              itemBuilder: (_, i) => _FareCard(
                fare: f[i],
                onEdit: () => _showEditDialog(context, f[i])));
          },
        )),
      ]),
    );
  }

  void _showEditDialog(BuildContext context, FareConfig fare) {
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => _EditFareDialog(
            fare: fare,
            onSaved: () {
              ref.invalidate(authorityFaresProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Fare updated successfully"),
                      backgroundColor: Colors.green));
            }));
  }
}

class _FareCard extends StatelessWidget {
  final FareConfig fare;
  final VoidCallback onEdit;
  const _FareCard({required this.fare, required this.onEdit});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(fare.routeNumber,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669), fontSize: 11),
              textAlign: TextAlign.center))),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fare.routeName, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
          Text("\${fare.startLocation} → \${fare.endLocation}",
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          Text("\${fare.totalStops} stops",
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("LKR \${fare.currentBaseFare.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669), fontSize: 16)),
          const Text("base fare",
              style: TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ]),
      const Divider(height: 14),
      // Mini fare table
      Row(children: fare.farePreview.take(4).map((p) =>
          Expanded(child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(
                vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6)),
            child: Column(children: [
              Text("\${p.stopCount}s",
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 9)),
              Text("\${p.fare.toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                      fontSize: 12)),
            ])))).toList()),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 15),
          label: const Text("Edit Fare")),
      ]),
    ])),
  );
}

class _EditFareDialog extends ConsumerStatefulWidget {
  final FareConfig fare;
  final VoidCallback onSaved;
  const _EditFareDialog({required this.fare, required this.onSaved});
  @override
  ConsumerState<_EditFareDialog> createState() => _EditState();
}

class _EditState extends ConsumerState<_EditFareDialog> {
  late double _value;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.fare.currentBaseFare;
  }

  double get _previewFare {
    double f = _value;
    return f.clamp(widget.fare.minimumFare, widget.fare.maximumFare);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fare;
    return AlertDialog(
      title: Text("Set Fare — \${f.routeNumber}"),
      content: SizedBox(width: 460, child: Column(
          mainAxisSize: MainAxisSize.min, children: [
        Text(f.routeName, style: TextStyle(
            color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 16),
        // Slider
        Row(children: [
          Text("LKR ${f.minimumFare.toInt()}",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Expanded(child: Slider(
            value: _value,
            min: f.minimumFare, max: f.maximumFare,
            divisions: ((f.maximumFare - f.minimumFare) / 8).round(),
            onChanged: (v) => setState(() => _value = v),
            activeColor: const Color(0xFF059669),
          )),
          Text("LKR ${f.maximumFare.toInt()}",
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
        // Current value display
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12)),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text("Base Fare: ",
                style: TextStyle(fontSize: 14)),
            Text("LKR \${_previewFare.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669), fontSize: 20)),
          ])),
        const SizedBox(height: 12),
        // Sample fare table
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            const Text("Fare Preview by Stop Count",
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [1, 5, 10, 15, 20].map((stops) {
              double fare = _previewFare + (stops - 1) * f.farePerStop;
              fare = fare.clamp(f.minimumFare, f.maximumFare);
              return Expanded(child: Column(children: [
                Text("\$stops stop\${stops == 1 ? "" : "s"}",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 10)),
                Text("\${fare.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669), fontSize: 12)),
              ]));
            }).toList()),
          ])),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(
              color: Colors.red, fontSize: 12)),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() { _loading = true; _error = null; });
            try {
              await ref.read(apiServiceProvider)
                  .updateFare(widget.fare.routeId, _previewFare);
              if (mounted) {
                Navigator.pop(context);
                widget.onSaved();
              }
            } catch (e) {
              setState(() => _error =
                  e.toString().replaceFirst("Exception: ", ""));
            } finally { setState(() => _loading = false); }
          },
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text("Save Fare",
                  style: TextStyle(color: Colors.white))),
      ],
    );
  }
}
