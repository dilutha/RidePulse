import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/bus_models.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});
  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _panelExpanded = false;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
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
    final async   = ref.watch(busLocationsProvider);
    final isWide  = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: async.when(
        loading: () => const _LoadingState(),
        error:   (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(busLocationsProvider),
        ),
        data: (locations) => FadeTransition(
          opacity: _fadeAnim,
          child: isWide
              ? _WideLayout(
                  locations:     locations,
                  selectedIndex: _selectedIndex,
                  onSelect:      (i) => setState(() => _selectedIndex = i),
                  onRefresh:     () => ref.invalidate(busLocationsProvider),
                )
              : _NarrowLayout(
                  locations:    locations,
                  expanded:     _panelExpanded,
                  onToggle:     () =>
                      setState(() => _panelExpanded = !_panelExpanded),
                  onRefresh:    () => ref.invalidate(busLocationsProvider),
                ),
        ),
      ),
    );
  }
}

// ── Wide layout (tablet/web) ──────────────────────────────────

class _WideLayout extends StatelessWidget {
  final List<BusLocationModel> locations;
  final int?         selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onRefresh;
  const _WideLayout({
    required this.locations, required this.selectedIndex,
    required this.onSelect,  required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    // Map
    Expanded(
      flex: 3,
      child: Stack(children: [
        _MapWidget(locations: locations, selectedIndex: selectedIndex),
        Positioned(top: 0, left: 0, right: 0,
          child: _MapTopBar(
            count:     locations.length,
            onRefresh: onRefresh,
          ),
        ),
      ]),
    ),

    // Side panel
    Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1626),
        border: Border(
            left: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        // Panel header
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus_rounded,
                    size: 14, color: Color(0xFF4ADE80)),
              ),
              const SizedBox(width: 10),
              Text('Fleet',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${locations.length}',
                    style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
        Divider(height: 1, color: Colors.white.withOpacity(0.07)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: locations.length,
            itemBuilder: (_, i) => _BusListTile(
              loc:      locations[i],
              selected: selectedIndex == i,
              onTap:    () {},
            ),
          ),
        ),
      ]),
    ),
  ]);
}

// ── Narrow layout (mobile) ────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final List<BusLocationModel> locations;
  final bool         expanded;
  final VoidCallback onToggle, onRefresh;
  const _NarrowLayout({
    required this.locations, required this.expanded,
    required this.onToggle,  required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) => Stack(children: [
    // Full-screen map
    _MapWidget(locations: locations, selectedIndex: null),

    // Top bar over map
    Positioned(top: 0, left: 0, right: 0,
      child: _MapTopBar(
          count: locations.length, onRefresh: onRefresh),
    ),

    // Bottom sheet panel
    Positioned(bottom: 0, left: 0, right: 0,
      child: _BottomPanel(
        locations: locations,
        expanded:  expanded,
        onToggle:  onToggle,
      ),
    ),
  ]);
}

// ── Map widget ────────────────────────────────────────────────

class _MapWidget extends StatelessWidget {
  final List<BusLocationModel> locations;
  final int? selectedIndex;
  const _MapWidget(
      {required this.locations, required this.selectedIndex});

  @override
  Widget build(BuildContext context) => FlutterMap(
    options: const MapOptions(
        initialCenter: LatLng(6.9271, 79.8612),
        initialZoom: 12),
    children: [
      TileLayer(
        urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.ridepulse.app'),
      MarkerLayer(
        markers: locations.asMap().entries.map((e) => Marker(
          point: LatLng(e.value.latitude, e.value.longitude),
          width: 70, height: 70,
          child: _BusPin(
              loc:      e.value,
              selected: selectedIndex == e.key),
        )).toList(),
      ),
    ],
  );
}

// ── Map top bar ───────────────────────────────────────────────

class _MapTopBar extends StatelessWidget {
  final int          count;
  final VoidCallback onRefresh;
  const _MapTopBar({required this.count, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12, right: 12, bottom: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0B1220).withOpacity(0.9),
          Colors.transparent,
        ],
      ),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220).withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7, height: 7,
            decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          const Text('Live',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('$count buses',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12)),
        ]),
      ),
      const Spacer(),
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1220).withOpacity(0.85),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(Icons.refresh_rounded,
              size: 17, color: Colors.white.withOpacity(0.7)),
        ),
      ),
    ]),
  );
}

// ── Bottom panel (mobile) ─────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final List<BusLocationModel> locations;
  final bool         expanded;
  final VoidCallback onToggle;
  const _BottomPanel({
    required this.locations,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeInOut,
    height: expanded ? 320 : 72,
    decoration: BoxDecoration(
      color: const Color(0xFF0D1626),
      borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20)),
      border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1))),
    ),
    child: Column(children: [
      // Handle + header
      GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Fleet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${locations.length}',
                  style: const TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              color: Colors.white.withOpacity(0.4), size: 20),
          ]),
        ),
      ),
      if (expanded) ...[
        Divider(height: 1, color: Colors.white.withOpacity(0.07)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: locations.length,
            itemBuilder: (_, i) => _BusListTile(
                loc: locations[i], selected: false, onTap: () {}),
          ),
        ),
      ],
    ]),
  );
}

// ── Bus list tile ─────────────────────────────────────────────

class _BusListTile extends StatefulWidget {
  final BusLocationModel loc;
  final bool             selected;
  final VoidCallback     onTap;
  const _BusListTile(
      {required this.loc, required this.selected, required this.onTap});
  @override
  State<_BusListTile> createState() => _BusListTileState();
}

class _BusListTileState extends State<_BusListTile> {
  bool _pressed = false;

  Color get _color => switch (widget.loc.crowdCategory) {
    'low'    => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFBBF24),
    'high'   => const Color(0xFFF87171),
    _        => const Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 3),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.selected
              ? _color.withOpacity(0.1)
              : _pressed
                  ? Colors.white.withOpacity(0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: widget.selected
                  ? _color.withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Row(children: [
          // Crowd dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(loc.busNumber,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              '${loc.speedKmh?.toStringAsFixed(0) ?? "0"} km/h  ·  ${loc.recordedAt}',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10)),
          ])),
          Icon(Icons.chevron_right_rounded,
              size: 15,
              color: Colors.white.withOpacity(0.2)),
        ]),
      ),
    );
  }
}

// ── Bus map pin ───────────────────────────────────────────────

class _BusPin extends StatelessWidget {
  final BusLocationModel loc;
  final bool             selected;
  const _BusPin({required this.loc, required this.selected});

  Color get _color => switch (loc.crowdCategory) {
    'low'    => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFBBF24),
    'high'   => const Color(0xFFF87171),
    _        => const Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) => Column(
      mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
              color: _color.withOpacity(0.45),
              blurRadius: selected ? 12 : 6,
              spreadRadius: selected ? 2 : 0),
        ],
      ),
      child: Text(loc.busNumber,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800)),
    ),
    Icon(Icons.directions_bus_rounded,
        color: _color, size: selected ? 28 : 24),
  ]);
}

// ── Utility widgets ───────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0B1220),
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 26, height: 26,
            child: CircularProgressIndicator(
                color: Color(0xFF0EA5E9), strokeWidth: 2)),
        SizedBox(height: 12),
        Text('Loading live locations...',
            style: TextStyle(
                color: Color(0xFF64748B), fontSize: 13)),
      ]),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  const _ErrorState(
      {required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1220),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(Icons.map_outlined,
                size: 26,
                color: Colors.white.withOpacity(0.25)),
          ),
          const SizedBox(height: 16),
          const Text('Could not load map data',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1A56DB), Color(0xFF0EA5E9)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min,
                  children: [
                const Icon(Icons.refresh_rounded,
                    size: 16, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Retry',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
    ),
  );
}