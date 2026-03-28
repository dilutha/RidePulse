// ============================================================
// features/authority/screens/authority_route_optimization_screen.dart
// Coming Soon placeholder
// ============================================================
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class AuthorityRouteOptimizationScreen extends StatelessWidget {
  const AuthorityRouteOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(title: const Text("Route Optimization")),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                shape: BoxShape.circle),
            child: const Icon(Icons.route,
                size: 64, color: Color(0xFF7C3AED))),
          const SizedBox(height: 28),
          const Text("Route Optimization",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("AI-powered route optimization for public buses.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 24),
          // Feature list
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.15))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Planned Features:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              ...[
                "Optimal stop placement using passenger demand data",
                "Frequency suggestions based on crowd predictions",
                "Overlap detection between competing routes",
                "Carbon footprint reduction analysis",
                "Real-time detour recommendations",
              ].map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF7C3AED), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f,
                      style: const TextStyle(fontSize: 13))),
                ]))),
            ])),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.construction_outlined,
                  color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text("Coming Soon — In Development",
                  style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ])),
        ]),
      ),
    ),
  );
}
