// ============================================================
// features/driver/screens/driver_emergency_screen.dart
// Raise and manage emergency alerts
// ============================================================
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/services/api_service.dart";
import "../../../core/models/driver_models.dart";

class DriverEmergencyScreen extends ConsumerStatefulWidget {
  const DriverEmergencyScreen({super.key});
  @override
  ConsumerState<DriverEmergencyScreen> createState() =>
      _DriverEmergencyScreenState();
}

class _DriverEmergencyScreenState
    extends ConsumerState<DriverEmergencyScreen> {
  String   _alertType = "breakdown";
  final    _descCtrl  = TextEditingController();
  bool     _loading   = false;
  String?  _error;

  static const _types = [
    ("accident",  "Accident",   Icons.car_crash_outlined,     Color(0xFFEF4444)),
    ("breakdown", "Breakdown",  Icons.car_repair,             Color(0xFFF97316)),
    ("medical",   "Medical",    Icons.local_hospital_outlined, Color(0xFFEF4444)),
    ("security",  "Security",   Icons.security,               Color(0xFF8B5CF6)),
    ("other",     "Other",      Icons.warning_amber_outlined,  Color(0xFF6B7280)),
  ];

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }

  Future<void> _raise(int tripId) async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).raiseEmergencyAlert(
        tripId:    tripId,
        alertType: _alertType,
        description: _descCtrl.text.isEmpty ? null : _descCtrl.text,
      );
      ref.invalidate(driverDashboardProvider);
      ref.invalidate(driverAlertsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency alert sent to authority"),
              backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally { setState(() => _loading = false); }
  }

  Future<void> _resolve(int alertId) async {
    setState(() { _loading = true; });
    try {
      await ref.read(apiServiceProvider).resolveEmergencyAlert(alertId);
      ref.invalidate(driverDashboardProvider);
      ref.invalidate(driverAlertsProvider);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst("Exception: ", ""));
    } finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync   = ref.watch(driverDashboardProvider);
    final alertsAsync = ref.watch(driverAlertsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Emergency Alert"),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go("/driver/home")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Active alert card
          dashAsync.when(
            loading: () => const SizedBox.shrink(),
            error:   (e, _) => const SizedBox.shrink(),
            data: (dash) {
              if (dash.activeAlert == null) return const SizedBox.shrink();
              return _ActiveAlertCard(
                alert: dash.activeAlert!,
                onResolve: () => _resolve(dash.activeAlert!.alertId),
                loading: _loading);
            },
          ),

          // Raise new alert — only if trip active and no active alert
          dashAsync.when(
            loading: () => const CircularProgressIndicator(),
            error:   (e, _) => const Text("Error: \$e"),
            data: (dash) {
              if (dash.activeAlert != null) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                            "Resolve the active alert before raising a new one.")),
                      ]),
                    ),
                  ),
                );
              }

              if (dash.activeTrip == null) {
                return Card(
                  color: Colors.grey.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                          "Start a trip first before raising an emergency alert.")),
                    ]),
                  ),
                );
              }

              return _RaiseForm(
                alertType:  _alertType,
                descCtrl:   _descCtrl,
                loading:    _loading,
                error:      _error,
                types:      _types,
                onTypeChanged: (t) => setState(() => _alertType = t),
                onRaise: () => _raise(dash.activeTrip!.tripId),
              );
            },
          ),

          const SizedBox(height: 24),

          // Alert history
          const Text("Alert History",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 10),
          alertsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => const Text("Error: \$e"),
            data: (alerts) => alerts.isEmpty
                ? const Center(child: Text("No alerts raised",
                    style: TextStyle(color: Colors.grey)))
                : Column(children: alerts.map((a) => _AlertHistoryRow(a: a)).toList()),
          ),
        ]),
      ),
    );
  }
}

class _ActiveAlertCard extends StatelessWidget {
  final EmergencyAlertModel alert;
  final VoidCallback onResolve;
  final bool loading;
  const _ActiveAlertCard({required this.alert,
      required this.onResolve, required this.loading});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.warning_rounded, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text("ACTIVE EMERGENCY", style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold,
            letterSpacing: 1)),
      ]),
      const SizedBox(height: 10),
      Text(alert.alertType.toUpperCase(),
          style: const TextStyle(color: Colors.white,
              fontSize: 18, fontWeight: FontWeight.bold)),
      if (alert.description != null) ...[
        const SizedBox(height: 4),
        Text(alert.description!, style: const TextStyle(color: Colors.white70)),
      ],
      const SizedBox(height: 4),
      const Text("Bus: \${alert.busNumber}  ·  Raised: \${alert.createdAt}",
          style: TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white)),
          onPressed: loading ? null : onResolve,
          child: loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Mark as Resolved"),
        ),
      ),
    ]),
  );
}

class _RaiseForm extends StatelessWidget {
  final String alertType;
  final TextEditingController descCtrl;
  final bool loading;
  final String? error;
  final List types;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onRaise;
  const _RaiseForm({required this.alertType, required this.descCtrl,
      required this.loading, this.error, required this.types,
      required this.onTypeChanged, required this.onRaise});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Raise Emergency Alert",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 14),
      const Text("Alert Type", style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: types.map<Widget>((t) {
        final selected = alertType == t.$1;
        return ChoiceChip(
          label: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(t.$3, size: 14,
                color: selected ? Colors.white : t.$4),
            const SizedBox(width: 4),
            Text(t.$2),
          ]),
          selected: selected,
          onSelected: (_) => onTypeChanged(t.$1),
          selectedColor: t.$4,
          labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87),
        );
      }).toList()),
      const SizedBox(height: 14),
      TextField(
        controller: descCtrl, maxLines: 3,
        decoration: const InputDecoration(
          labelText: "Description (optional)",
          hintText: "Describe the emergency…",
          border: OutlineInputBorder()),
      ),
      if (error != null) ...[
        const SizedBox(height: 8),
        Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444)),
          onPressed: loading ? null : onRaise,
          icon: loading
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.warning_amber_rounded, size: 20),
          label: const Text("RAISE EMERGENCY ALERT",
              style: TextStyle(fontSize: 15)),
        ),
      ),
    ])),
  );
}

class _AlertHistoryRow extends StatelessWidget {
  final EmergencyAlertModel a;
  const _AlertHistoryRow({required this.a});
  Color get _c => a.isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981);
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: _c),
      title: Text(a.alertType.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text("\${a.busNumber}  ·  \${a.createdAt}"),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20)),
        child: Text(a.status,
            style: TextStyle(color: _c, fontWeight: FontWeight.w600,
                fontSize: 11)),
      ),
    ),
  );
}
