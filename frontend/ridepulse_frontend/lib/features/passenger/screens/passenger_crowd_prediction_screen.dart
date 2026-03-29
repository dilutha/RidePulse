import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/passenger_models.dart';

class PassengerCrowdPredictionScreen extends ConsumerStatefulWidget {
  final int routeId;
  const PassengerCrowdPredictionScreen(
      {super.key, required this.routeId});
  @override
  ConsumerState<PassengerCrowdPredictionScreen> createState() =>
      _State();
}

class _State extends ConsumerState<PassengerCrowdPredictionScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  String get _dateStr =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, "0")}-'
      '${_selectedDate.day.toString().padLeft(2, "0")}';

  bool get _isToday =>
      _selectedDate.year  == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day   == DateTime.now().day;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fadeCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final predAsync = ref.watch(crowdPredictionProvider(
        (routeId: widget.routeId, date: _dateStr)));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFFC084FC).withOpacity(0.14),
                size: 280)),
        Positioned(bottom: 60, left: -40,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.12),
                size: 200)),

        Column(children: [
          // ── App bar ────────────────────────────────────
          _DarkAppBar(onBack: () => Navigator.pop(context)),

          // ── Date selector ──────────────────────────────
          _DateSelector(
            dateStr:  _selectedDate,
            isToday:  _isToday,
            onPrev:   () => _changeDate(-1),
            onNext:   () => _changeDate(1),
          ),

          // ── Content ────────────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: predAsync.when(
                loading: () => const _LoadingState(),
                error: (e, _) => _ErrorState(
                    message: e.toString()
                        .replaceFirst('Exception: ', '')),
                data: (schedule) => schedule.hasData
                    ? _PredictionChart(schedule: schedule)
                    : _ComingSoon(routeName: schedule.routeName),
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
  final VoidCallback onBack;
  const _DarkAppBar({required this.onBack});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      GestureDetector(
        onTap: onBack,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.7)),
        ),
      ),
      const SizedBox(width: 4),
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFC084FC).withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFFC084FC).withOpacity(0.3)),
        ),
        child: const Icon(Icons.auto_graph_rounded,
            size: 17, color: Color(0xFFC084FC)),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Crowd Forecast',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        Text('AI predictions',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Date selector ─────────────────────────────────────────────

class _DateSelector extends StatelessWidget {
  final DateTime _date;
  final bool     isToday;
  final VoidCallback onPrev, onNext;

  const _DateSelector({
    required DateTime dateStr,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  }) : _date = dateStr;

  String get _label {
    final d = _date;
    final months = [
      '', 'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dayName = days[d.weekday - 1];
    return '$dayName, ${months[d.month]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      border: Border(
          bottom: BorderSide(
              color: Colors.white.withOpacity(0.07))),
    ),
    child: Row(children: [
      _NavBtn(icon: Icons.chevron_left_rounded, onTap: onPrev),
      Expanded(
        child: Column(children: [
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF0EA5E9)
                        .withOpacity(0.3)),
              ),
              child: const Text('TODAY',
                  style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8)),
            ),
          Text(_label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              textAlign: TextAlign.center),
        ]),
      ),
      _NavBtn(icon: Icons.chevron_right_rounded, onTap: onNext),
    ]),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withOpacity(0.09)),
      ),
      child: Icon(icon,
          size: 18, color: Colors.white.withOpacity(0.6)),
    ),
  );
}

// ── Coming soon ───────────────────────────────────────────────

class _ComingSoon extends StatelessWidget {
  final String routeName;
  const _ComingSoon({required this.routeName});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
    child: Column(children: [
      // Icon
      Container(
        width: 88, height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFC084FC).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
              color: const Color(0xFFC084FC).withOpacity(0.25)),
        ),
        child: const Icon(Icons.auto_graph_rounded,
            size: 42, color: Color(0xFFC084FC)),
      ),
      const SizedBox(height: 22),

      const Text('Crowd Prediction',
          style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text('Coming Soon for $routeName',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14)),

      const SizedBox(height: 24),

      // Features card
      _GlassCard(
        accentColor: const Color(0xFFC084FC),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFC084FC).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.list_alt_rounded,
                  size: 15, color: Color(0xFFC084FC)),
            ),
            const SizedBox(width: 10),
            const Text('What this will show',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          _FeatureItem(
              'AI-powered crowd predictions by time slot'),
          _FeatureItem('Best time to board for low crowds'),
          _FeatureItem('Historical crowd patterns'),
          _FeatureItem('Confidence score per prediction'),
        ]),
      ),

      const SizedBox(height: 18),

      // Training badge
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFB923C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFFB923C).withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule_rounded,
              color: Color(0xFFFB923C), size: 15),
          const SizedBox(width: 6),
          Text('LSTM model training in progress',
              style: TextStyle(
                  color: const Color(0xFFFB923C),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ]),
      ),
    ]),
  );
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFC084FC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.check_rounded,
            size: 12, color: Color(0xFFC084FC)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13)),
      ),
    ]),
  );
}

// ── Real prediction chart ─────────────────────────────────────

class _PredictionChart extends StatelessWidget {
  final RoutePredictionSchedule schedule;
  const _PredictionChart({required this.schedule});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    children: [
      // Route info banner
      _GlassCard(
        accentColor: const Color(0xFFC084FC),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFC084FC).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_graph_rounded,
                size: 18, color: Color(0xFFC084FC)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(schedule.routeName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text('AI predictions for ${schedule.date}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Slot rows
      ...schedule.slots.map((slot) => _SlotCard(slot: slot)),
    ],
  );
}

class _SlotCard extends StatelessWidget {
  final CrowdPredictionSlot slot;
  const _SlotCard({required this.slot});

  Color get _color => switch (slot.predictedCategory) {
    'low'    => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFBBF24),
    'high'   => const Color(0xFFF87171),
    _        => const Color(0xFF94A3B8),
  };

  IconData get _icon => switch (slot.predictedCategory) {
    'low'    => Icons.sentiment_satisfied_rounded,
    'medium' => Icons.sentiment_neutral_rounded,
    'high'   => Icons.sentiment_very_dissatisfied_rounded,
    _        => Icons.help_outline_rounded,
  };

  String get _label => switch (slot.predictedCategory) {
    'low'    => 'Low crowd',
    'medium' => 'Moderate',
    'high'   => 'Very crowded',
    _        => 'Unknown',
  };

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(children: [
      // Time
      SizedBox(
        width: 52,
        child: Text(slot.timeSlot,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
      const SizedBox(width: 12),

      // Bar + label
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Custom bar track
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.06)),
              FractionallySizedBox(
                widthFactor: slot.predictedPercentage / 100,
                child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(6),
                    )),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Icon(_icon, size: 13, color: _color),
            const SizedBox(width: 5),
            Text(_label,
                style: TextStyle(
                    color: _color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
                '${slot.predictedPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
        ]),
      ),

      // Confidence
      if (slot.confidenceScore != null) ...[
        const SizedBox(width: 12),
        Column(children: [
          Text(
            '${(slot.confidenceScore! * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
          Text('conf.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 9)),
        ]),
      ],
    ]),
  );
}

// ── Shared utilities ──────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  const _GlassCard({required this.child, this.accentColor});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: accentColor != null
          ? accentColor!.withOpacity(0.05)
          : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: accentColor != null
              ? accentColor!.withOpacity(0.18)
              : Colors.white.withOpacity(0.09)),
    ),
    child: child,
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
      Text('Loading predictions...',
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
        Text('Failed to load predictions',
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 12)),
      ]),
    ),
  );
}