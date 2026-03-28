// ============================================================
// features/authority/screens/authority_prediction_screen.dart
// Authority can trigger LSTM prediction generation manually
// and see prediction status across all routes.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';

class AuthorityPredictionScreen extends ConsumerStatefulWidget {
  const AuthorityPredictionScreen({super.key});
  @override
  ConsumerState<AuthorityPredictionScreen> createState() =>
      _AuthorityPredictionScreenState();
}

class _AuthorityPredictionScreenState
    extends ConsumerState<AuthorityPredictionScreen>
    with SingleTickerProviderStateMixin {
  bool    _generating  = false;
  String? _lastMessage;
  String  _weather     = 'clear';
  double  _rain        = 0.0;
  String  _traffic     = 'medium';

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  static const _weathers = ['clear', 'cloudy', 'rainy', 'stormy'];
  static const _traffics  = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  IconData _weatherIcon(String w) => switch (w) {
    'clear'  => Icons.wb_sunny_rounded,
    'cloudy' => Icons.cloud_rounded,
    'rainy'  => Icons.water_drop_rounded,
    'stormy' => Icons.thunderstorm_rounded,
    _        => Icons.wb_sunny_rounded,
  };

  Color _weatherColor(String w) => switch (w) {
    'clear'  => const Color(0xFFFBBF24),
    'cloudy' => const Color(0xFF94A3B8),
    'rainy'  => const Color(0xFF38BDF8),
    'stormy' => const Color(0xFFC084FC),
    _        => const Color(0xFFFBBF24),
  };

  Color _trafficColor(String t) => switch (t) {
    'low'    => const Color(0xFF4ADE80),
    'medium' => const Color(0xFFFBBF24),
    'high'   => const Color(0xFFF87171),
    _        => const Color(0xFF94A3B8),
  };

  Future<void> _generateToday() async {
    setState(() { _generating = true; _lastMessage = null; });
    try {
      await ref.read(apiServiceProvider).generateTodayPredictions(
        weather:      _weather,
        rain:         _rain,
        trafficLevel: _traffic,
      );
      setState(() =>
          _lastMessage = 'Prediction generation started for today. '
              'Results will appear in 1–2 minutes.');
    } catch (e) {
      setState(() =>
          _lastMessage =
              'Error: ${e.toString().replaceFirst("Exception: ", "")}');
    } finally {
      setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs
        Positioned(top: -50, right: -70,
            child: _Orb(
                color: const Color(0xFF1A56DB).withOpacity(0.18),
                size: 300)),
        Positioned(bottom: 60, left: -40,
            child: _Orb(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                size: 220)),
        Positioned(top: size.height * 0.5, left: size.width * 0.55,
            child: _Orb(
                color: const Color(0xFF6330B4).withOpacity(0.09),
                size: 160)),

        Column(children: [
          // ── App bar ────────────────────────────────────
          _DarkAppBar(
            title: 'Crowd Prediction',
            subtitle: 'LSTM management',
            icon: Icons.auto_graph_rounded,
            onBack: () => context.go('/authority/dashboard'),
          ),

          // ── Scrollable body ────────────────────────────
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                    // ── Model status ────────────────────
                    _SectionLabel('Model Status'),
                    const SizedBox(height: 12),
                    _GlassCard(
                      accentColor: const Color(0xFF0EA5E9),
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                        _CardHeader(
                          title: 'LSTM Model',
                          icon: Icons.memory_rounded,
                          color: const Color(0xFF0EA5E9),
                        ),
                        const SizedBox(height: 16),
                        _AccuracyBadge(accuracy: '66.58%'),
                        const SizedBox(height: 16),
                        _InfoRow('Model',    'lstm_crowd_model.h5'),
                        _InfoRow('Version',  'lstm_v1.0'),
                        _InfoRow('MAE',      '4.02 passengers'),
                        _InfoRow('Schedule',
                            'Auto-generates daily at 00:30'),
                        _InfoRow('Slots',
                            '36 per route (every 30 min)',
                            isLast: true),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Manual generation ───────────────
                    _SectionLabel('Manual Generation'),
                    const SizedBox(height: 4),
                    Text(
                        'Override auto-schedule with current conditions',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12)),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                        // Weather chips
                        _FieldLabel('Weather Condition'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _weathers.map((w) {
                            final sel   = _weather == w;
                            final color = _weatherColor(w);
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _weather = w),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? color.withOpacity(0.12)
                                      : Colors.white
                                          .withOpacity(0.04),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                      color: sel
                                          ? color.withOpacity(0.4)
                                          : Colors.white
                                              .withOpacity(0.09),
                                      width: sel ? 1.5 : 1),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  Icon(_weatherIcon(w),
                                      size: 14,
                                      color: sel
                                          ? color
                                          : Colors.white
                                              .withOpacity(0.3)),
                                  const SizedBox(width: 6),
                                  Text(w,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: sel
                                              ? color
                                              : Colors.white
                                                  .withOpacity(
                                                      0.35))),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        Divider(height: 1,
                            color:
                                Colors.white.withOpacity(0.07)),
                        const SizedBox(height: 16),

                        // Rain slider
                        Row(children: [
                          _FieldLabel('Rain Intensity'),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF38BDF8)
                                      .withOpacity(0.25)),
                            ),
                            child: Text(
                                _rain.toStringAsFixed(1),
                                style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor:
                                const Color(0xFF38BDF8),
                            inactiveTrackColor:
                                Colors.white.withOpacity(0.08),
                            thumbColor: const Color(0xFF38BDF8),
                            overlayColor: const Color(0xFF38BDF8)
                                .withOpacity(0.1),
                            trackHeight: 4,
                            thumbShape:
                                const RoundSliderThumbShape(
                                    enabledThumbRadius: 7),
                          ),
                          child: Slider(
                            value: _rain,
                            min: 0.0, max: 1.0, divisions: 10,
                            onChanged: (v) =>
                                setState(() => _rain = v),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Divider(height: 1,
                            color:
                                Colors.white.withOpacity(0.07)),
                        const SizedBox(height: 16),

                        // Traffic selector
                        _FieldLabel('Traffic Level'),
                        const SizedBox(height: 10),
                        Row(
                          children: _traffics.map((t) {
                            final sel   = _traffic == t;
                            final color = _trafficColor(t);
                            final isLast = t == _traffics.last;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _traffic = t),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 150),
                                  margin: EdgeInsets.only(
                                      right: isLast ? 0 : 8),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? color.withOpacity(0.12)
                                        : Colors.white
                                            .withOpacity(0.04),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: sel
                                            ? color.withOpacity(0.4)
                                            : Colors.white
                                                .withOpacity(0.09),
                                        width: sel ? 1.5 : 1),
                                  ),
                                  child: Column(children: [
                                    Icon(Icons.traffic_rounded,
                                        size: 16,
                                        color: sel
                                            ? color
                                            : Colors.white
                                                .withOpacity(0.25)),
                                    const SizedBox(height: 4),
                                    Text(
                                        t[0].toUpperCase() +
                                            t.substring(1),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: sel
                                                ? color
                                                : Colors.white
                                                    .withOpacity(
                                                        0.3))),
                                  ]),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // Status message
                        if (_lastMessage != null) ...[
                          _StatusMessage(message: _lastMessage!),
                          const SizedBox(height: 14),
                        ],

                        // Generate button
                        _GenerateButton(
                          isGenerating: _generating,
                          onPressed:
                              _generating ? null : _generateToday,
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Architecture card ───────────────
                    _SectionLabel('Integration Architecture'),
                    const SizedBox(height: 12),
                    _GlassCard(
                      child: Column(children: [
                        _ArchStep(num: '1',
                            text:
                                'Spring Boot collects route data + DB lag features',
                            isLast: false),
                        _ArchStep(num: '2',
                            text:
                                'Calls Python FastAPI on :8000/predict/batch',
                            isLast: false),
                        _ArchStep(num: '3',
                            text:
                                'LSTM runs 36 predictions per route',
                            isLast: false),
                        _ArchStep(num: '4',
                            text:
                                'Results stored in crowd_predictions table',
                            isLast: false),
                        _ArchStep(num: '5',
                            text:
                                'Passenger app reads predictions by route + time',
                            isLast: true),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _DarkAppBar extends StatelessWidget {
  final String     title, subtitle;
  final IconData   icon;
  final VoidCallback onBack;
  const _DarkAppBar({
    required this.title, required this.subtitle,
    required this.icon,  required this.onBack,
  });

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
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

class _AccuracyBadge extends StatelessWidget {
  final String accuracy;
  const _AccuracyBadge({required this.accuracy});

  @override
  Widget build(BuildContext context) => Container(
    padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF4ADE80).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insights_rounded,
            size: 16, color: Color(0xFF4ADE80)),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('Model Accuracy',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        Text(accuracy,
            style: const TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('LIVE',
            style: TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
    ]),
  );
}

class _StatusMessage extends StatelessWidget {
  final String message;
  const _StatusMessage({required this.message});

  bool get _isError => message.startsWith('Error');

  @override
  Widget build(BuildContext context) {
    final color =
        _isError ? const Color(0xFFF87171) : const Color(0xFF4ADE80);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(
          _isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 15, color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: TextStyle(color: color, fontSize: 13)),
        ),
      ]),
    );
  }
}

class _GenerateButton extends StatefulWidget {
  final bool isGenerating;
  final VoidCallback? onPressed;
  const _GenerateButton(
      {required this.isGenerating, required this.onPressed});

  @override
  State<_GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends State<_GenerateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onPressed?.call();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: widget.onPressed == null ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: widget.isGenerating
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2)),
                    const SizedBox(width: 10),
                    const Text('Generating predictions…',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ])
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_graph_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text("Generate Today's Predictions",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ]),
          ),
        ),
      ),
    ),
  );
}

class _ArchStep extends StatelessWidget {
  final String num, text;
  final bool   isLast;
  const _ArchStep(
      {required this.num,
      required this.text,
      required this.isLast});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4)),
        ),
      ]),
    ),
    if (!isLast)
      Divider(height: 1,
          color: Colors.white.withOpacity(0.05)),
  ]);
}

// ── Shared ────────────────────────────────────────────────────

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
          ? accentColor!.withOpacity(0.04)
          : Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: accentColor != null
              ? accentColor!.withOpacity(0.15)
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
      required this.color});

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
  final String label, value;
  final bool   isLast;
  const _InfoRow(this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ]),
    ),
    if (!isLast)
      Divider(height: 1,
          color: Colors.white.withOpacity(0.05)),
  ]);
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
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3));
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