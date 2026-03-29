// ============================================================
// features/conductor/screens/conductor_issue_ticket_screen.dart
// Issue ticket with stop dropdowns and QR preview
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/conductor_models.dart';

class ConductorIssueTicketScreen extends ConsumerStatefulWidget {
  const ConductorIssueTicketScreen({super.key});
  @override
  ConsumerState<ConductorIssueTicketScreen> createState() =>
      _ConductorIssueTicketScreenState();
}

class _ConductorIssueTicketScreenState
    extends ConsumerState<ConductorIssueTicketScreen>
    with SingleTickerProviderStateMixin {
  StopModel?   _boarding;
  StopModel?   _alighting;
  String       _paymentMethod = 'cash';
  bool         _loading       = false;
  String?      _error;
  TicketModel? _issuedTicket;

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

  Future<void> _issue(TripModel trip, RosterModel roster) async {
    if (_boarding!.stopId == _alighting!.stopId) {
      setState(() =>
          _error = 'Boarding and alighting stop cannot be the same');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ticket = await ref.read(apiServiceProvider).issueTicket(
        tripId:          trip.tripId,
        routeId:         roster.routeId,
        boardingStopId:  _boarding!.stopId,
        alightingStopId: _alighting!.stopId,
        paymentMethod:   _paymentMethod,
      );
      ref.invalidate(conductorDashboardProvider);
      ref.invalidate(tripTicketsProvider(trip.tripId));
      _fadeCtrl.forward(from: 0);
      setState(() {
        _issuedTicket = ticket;
        _boarding     = null;
        _alighting    = null;
      });
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(conductorDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Stack(children: [
        // Ambient orbs — amber tint for conductor
        Positioned(top: -50, right: -60,
            child: _Orb(
                color: const Color(0xFFFB923C).withOpacity(0.12),
                size: 280)),
        Positioned(bottom: 60, left: -40,
            child: _Orb(
                color: const Color(0xFF4ADE80).withOpacity(0.08),
                size: 220)),

        Column(children: [
          _DarkAppBar(
              onBack: () => context.go('/conductor/trip')),

          Expanded(
            child: dashAsync.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(
                  message: e.toString()
                      .replaceFirst('Exception: ', '')),
              data: (dash) {
                final trip   = dash.activeTrip;
                final roster = dash.todayRoster;

                if (trip == null || !trip.isInProgress) {
                  return const _NoTripState();
                }

                if (_issuedTicket != null) {
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: _TicketIssued(
                      ticket:        _issuedTicket!,
                      onIssueAnother: () {
                        _fadeCtrl.forward(from: 0);
                        setState(() => _issuedTicket = null);
                      },
                    ),
                  );
                }

                final stopsAsync = ref.watch(
                    routeStopsProvider(roster!.routeId));

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 40),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                      // ── Trip banner ──────────────────
                      _TripBanner(trip: trip),
                      const SizedBox(height: 22),

                      // ── Stop selectors ───────────────
                      _SectionLabel('Journey'),
                      const SizedBox(height: 12),
                      stopsAsync.when(
                        loading: () => LinearProgressIndicator(
                            color: const Color(0xFF4ADE80),
                            backgroundColor:
                                Colors.white.withOpacity(0.06)),
                        error: (e, _) => _ErrorBanner(
                            message:
                                'Failed to load stops: $e'),
                        data: (stops) => Column(children: [
                          _DarkDropdown<StopModel>(
                            label: 'Boarding Stop',
                            value: _boarding,
                            items: stops,
                            displayText: (s) => s.stopName,
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFF4ADE80),
                            onChanged: (s) =>
                                setState(() => _boarding = s),
                          ),
                          const SizedBox(height: 12),
                          _DarkDropdown<StopModel>(
                            label: 'Alighting Stop',
                            value: _alighting,
                            items: stops,
                            displayText: (s) => s.stopName,
                            icon: Icons.location_off_rounded,
                            iconColor: const Color(0xFFF87171),
                            onChanged: (s) =>
                                setState(() => _alighting = s),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 20),

                      // ── Payment method ───────────────
                      _SectionLabel('Payment Method'),
                      const SizedBox(height: 12),
                      Row(children: [
                        _PaymentChip(
                          label: 'Cash',
                          icon:  Icons.payments_rounded,
                          color: const Color(0xFF4ADE80),
                          selected: _paymentMethod == 'cash',
                          onTap: () => setState(
                              () => _paymentMethod = 'cash'),
                        ),
                        const SizedBox(width: 10),
                        _PaymentChip(
                          label: 'Digital',
                          icon:  Icons.smartphone_rounded,
                          color: const Color(0xFF38BDF8),
                          selected:
                              _paymentMethod == 'digital',
                          onTap: () => setState(
                              () => _paymentMethod = 'digital'),
                        ),
                      ]),

                      // ── Error ────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: _error!),
                      ],

                      const SizedBox(height: 24),

                      // ── Issue button ─────────────────
                      _IssueButton(
                        isLoading: _loading,
                        enabled: _boarding != null &&
                            _alighting != null &&
                            !_loading,
                        onPressed: () =>
                            _issue(trip, roster!),
                      ),
                    ]),
                  ),
                );
              },
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
          gradient: const LinearGradient(
            colors: [Color(0xFFB45309), Color(0xFFFB923C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.confirmation_number_rounded,
            size: 16, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        const Text('Issue Ticket',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2)),
        Text('Conductor panel',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Trip banner ───────────────────────────────────────────────

class _TripBanner extends StatelessWidget {
  final TripModel trip;
  const _TripBanner({required this.trip});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF4ADE80).withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_bus_rounded,
            size: 18, color: Color(0xFF4ADE80)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(trip.busNumber,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(trip.routeName,
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end,
          children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
                color: Color(0xFF4ADE80),
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text('LIVE',
              style: TextStyle(
                  color: Color(0xFF4ADE80),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 3),
        Text('${trip.ticketsIssuedCount} tickets',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11)),
      ]),
    ]),
  );
}

// ── Payment chip ──────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     selected;
  final VoidCallback onTap;
  const _PaymentChip({
    required this.label, required this.icon,
    required this.color, required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? color.withOpacity(0.12)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected
                ? color.withOpacity(0.4)
                : Colors.white.withOpacity(0.09),
            width: selected ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16,
            color: selected
                ? color : Colors.white.withOpacity(0.3)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: selected
                    ? color : Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    ),
  );
}

// ── Issue button ──────────────────────────────────────────────

class _IssueButton extends StatefulWidget {
  final bool         isLoading, enabled;
  final VoidCallback onPressed;
  const _IssueButton({
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });
  @override
  State<_IssueButton> createState() => _IssueButtonState();
}

class _IssueButtonState extends State<_IssueButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.enabled
        ? (_) => setState(() => _pressed = true) : null,
    onTapUp: widget.enabled
        ? (_) {
            setState(() => _pressed = false);
            widget.onPressed();
          }
        : null,
    onTapCancel: widget.enabled
        ? () => setState(() => _pressed = false) : null,
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: AnimatedOpacity(
        opacity: widget.enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF4ADE80)],
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
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Icon(Icons.confirmation_number_rounded,
                        size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Issue Ticket',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ]),
          ),
        ),
      ),
    ),
  );
}

// ── Ticket issued success screen ──────────────────────────────

class _TicketIssued extends StatelessWidget {
  final TicketModel  ticket;
  final VoidCallback onIssueAnother;
  const _TicketIssued(
      {required this.ticket, required this.onIssueAnother});

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(children: [

          // Success icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF4ADE80).withOpacity(0.3)),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF4ADE80), size: 36),
          ),
          const SizedBox(height: 14),
          const Text('Ticket Issued!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Text('Passenger can scan the QR to verify',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 13)),
          const SizedBox(height: 24),

          // QR + details card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              // QR code — white background for scanner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                    data: ticket.qrCode, size: 180),
              ),
              const SizedBox(height: 16),
              Text(ticket.ticketNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Divider(height: 1,
                  color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 12),
              _TicketRow('From',    ticket.boardingStop),
              _TicketRow('To',      ticket.alightingStop),
              _TicketRow('Fare',
                  'LKR ${ticket.fareAmount.toStringAsFixed(2)}',
                  valueColor: const Color(0xFF4ADE80)),
              _TicketRow('Payment',
                  ticket.paymentMethod.toUpperCase()),
              _TicketRow('Status',
                  ticket.ticketStatus.toUpperCase(),
                  valueColor: const Color(0xFF4ADE80),
                  isLast: true),
            ]),
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(children: [
            Expanded(
              child: _OutlineBtn(
                label: 'Back to Trip',
                icon:  Icons.arrow_back_rounded,
                onTap: () => context.go('/conductor/trip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientBtn(
                label: 'Issue Another',
                icon:  Icons.add_rounded,
                onTap: onIssueAnother,
              ),
            ),
          ]),
        ]),
      );
}

class _TicketRow extends StatelessWidget {
  final String  label, value;
  final Color?  valueColor;
  final bool    isLast;
  const _TicketRow(this.label, this.value,
      {this.valueColor, this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor ??
                    Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ]),
    ),
    if (!isLast)
      Divider(height: 1,
          color: Colors.white.withOpacity(0.05)),
  ]);
}

class _OutlineBtn extends StatefulWidget {
  final String   label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.label, required this.icon, required this.onTap});
  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(widget.icon,
              size: 16, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 7),
          Text(widget.label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}

class _GradientBtn extends StatefulWidget {
  final String   label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientBtn(
      {required this.label, required this.icon, required this.onTap});
  @override
  State<_GradientBtn> createState() => _GradientBtnState();
}

class _GradientBtnState extends State<_GradientBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => _pressed = true),
    onTapUp: (_) {
      setState(() => _pressed = false);
      widget.onTap();
    },
    onTapCancel: () => setState(() => _pressed = false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A56DB), Color(0xFF0EA5E9)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(widget.icon,
              size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(widget.label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ]),
      ),
    ),
  );
}

// ── Shared form widgets ───────────────────────────────────────

class _DarkDropdown<T> extends StatelessWidget {
  final String         label;
  final T?             value;
  final List<T>        items;
  final String Function(T) displayText;
  final IconData       icon;
  final Color          iconColor;
  final ValueChanged<T?> onChanged;
  const _DarkDropdown({
    required this.label,     required this.value,
    required this.items,     required this.displayText,
    required this.icon,      required this.iconColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A2540),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        icon: Icon(Icons.expand_more_rounded,
            color: Colors.white.withOpacity(0.4), size: 20),
        decoration: InputDecoration(
          labelText: '$label *',
          labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: iconColor),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: iconColor, width: 1.5)),
        ),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayText(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ))
            .toList(),
        onChanged: onChanged,
      );
}

// ── Utility widgets ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.3))),
    const SizedBox(width: 10),
    Expanded(child: Divider(
        color: Colors.white.withOpacity(0.08), height: 1)),
  ]);
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded,
          size: 15, color: Colors.red.shade300),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: TextStyle(
              color: Colors.red.shade300, fontSize: 13))),
    ]),
  );
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [color, color.withOpacity(0)]))),
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
      Text('Loading trip...',
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
        Icon(Icons.error_outline_rounded, size: 38,
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

class _NoTripState extends StatelessWidget {
  const _NoTripState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            shape: BoxShape.circle),
        child: Icon(Icons.block_rounded,
            size: 28, color: Colors.white.withOpacity(0.2)),
      ),
      const SizedBox(height: 14),
      Text('No active trip',
          style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Start a trip first to issue tickets',
          style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13)),
    ]),
  );
}