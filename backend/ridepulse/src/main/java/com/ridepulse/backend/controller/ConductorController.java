package com.ridepulse.backend.controller;

// ============================================================
// ConductorController.java
// OOP Encapsulation: clean HTTP API, all logic in ConductorService.
//     Single Responsibility: only conductor endpoints here.
//     Polymorphism: @PreAuthorize restricts to conductor role only.
// ============================================================

import com.ridepulse.backend.config.CustomUserDetails;
import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.BusTrip;
import com.ridepulse.backend.entity.GpsTracking;
import com.ridepulse.backend.repository.BusTripRepository;
import com.ridepulse.backend.repository.GpsTrackingRepository;
import com.ridepulse.backend.service.ConductorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/conductor")
@RequiredArgsConstructor
public class ConductorController {

    // Abstraction: depends on interface only
    private final ConductorService conductorService;
    private final BusTripRepository tripRepo;
    private final GpsTrackingRepository gpsRepo;

    // ── Dashboard ─────────────────────────────────────────────

    /**
     * GET /api/v1/conductor/dashboard
     * Returns everything needed for conductor home screen:
     * today's roster, active trip, month stats, welfare balance.
     */
    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<ConductorDashboardDTO> getDashboard(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getDashboard(user.getStaffId()));
    }

    // ── Roster ────────────────────────────────────────────────

    /**
     * GET /api/v1/conductor/roster/today
     * Returns today's duty assignment: bus, route, shift times.
     */
    @GetMapping("/roster/today")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<List<RosterDetailDTO>> getTodayRoster(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getTodayRosters(user.getStaffId()));
    }

    /**
     * GET /api/v1/conductor/roster?date=2025-01-15
     * Returns roster for a specific date.
     */
    @GetMapping("/roster")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<List<RosterDetailDTO>> getRosterForDate(
            @RequestParam String date,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getRostersForDate(user.getStaffId(), date));
    }

    // ── Trip Lifecycle ────────────────────────────────────────

    /**
     * POST /api/v1/conductor/trip/start
     * Body: { "rosterId": 5 }
     * Conductor starts the trip for their assigned bus.
     * Creates BusTrip record and marks roster active.
     */
    @PostMapping("/trip/start")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TripStatusDTO> startTrip(
            @RequestBody Map<String, Integer> body,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                conductorService.startTrip(body.get("rosterId"), user.getStaffId()));
    }

    /**
     * POST /api/v1/conductor/trip/{tripId}/stop
     * Ends the active trip — marks completed.
     */
    @PostMapping("/trip/{tripId}/stop")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TripStatusDTO> stopTrip(
            @PathVariable Integer tripId,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.stopTrip(tripId, user.getStaffId()));
    }

    /**
     * GET /api/v1/conductor/trip/active
     * Returns the currently in-progress trip.
     */
    @GetMapping("/trip/active")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TripStatusDTO> getActiveTrip(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getActiveTrip(user.getStaffId()));
    }

    /**
     * GET /api/v1/conductor/trip/{tripId}/tickets
     * Lists all tickets issued in a specific trip.
     */
    @GetMapping("/trip/{tripId}/tickets")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<List<TicketDTO>> getTripTickets(
            @PathVariable Integer tripId,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getTripTickets(tripId, user.getStaffId()));
    }

    // ── Ticketing ─────────────────────────────────────────────

    /**
     * POST /api/v1/conductor/ticket/issue
     * Body: { tripId, routeId, boardingStopId, alightingStopId,
     *         paymentMethod, passengerUserId? }
     * Issues a new ticket — fare calculated automatically.
     * Returns ticket with QR code payload.
     */
    @PostMapping("/ticket/issue")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TicketDTO> issueTicket(
            @Valid @RequestBody IssueTicketRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                conductorService.issueTicket(request, user.getStaffId()));
    }

    /**
     * POST /api/v1/conductor/ticket/validate
     * Body: { "qrCode": "TKT-20250115-00042-A1B2C3D4" }
     * Scans and validates a passenger ticket.
     * Marks ticket status = "used".
     */
    @PostMapping("/ticket/validate")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TicketDTO> validateTicket(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.validateTicket(body.get("qrCode"), user.getStaffId()));
    }

    // ── Crowd Level ───────────────────────────────────────────

    /**
     * POST /api/v1/conductor/crowd/update
     * Body: { "tripId": 3, "passengerCount": 28 }
     * Conductor manually updates passenger count on the bus.
     */
    @PostMapping("/crowd/update")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<TripStatusDTO> updateCrowd(
            @Valid @RequestBody CrowdUpdateRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.updateCrowdLevel(request, user.getStaffId()));
    }

    /**
     * POST /api/v1/conductor/gps/update
     * Body: { tripId, latitude, longitude, speedKmh?, heading? }
     * Lets the conductor app publish bus location when the conductor starts
     * the route, so passengers and owners can see the live bus position.
     */
    @PostMapping("/gps/update")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<Void> updateGps(@RequestBody Map<String, Object> body) {
        BusTrip trip = tripRepo.findById(((Number) body.get("tripId")).intValue())
                .orElseThrow(() -> new RuntimeException("Trip not found"));
        gpsRepo.save(GpsTracking.builder()
                .bus(trip.getBus())
                .trip(trip)
                .latitude(BigDecimal.valueOf(((Number) body.get("latitude")).doubleValue()))
                .longitude(BigDecimal.valueOf(((Number) body.get("longitude")).doubleValue()))
                .speedKmh(numberOrNull(body.get("speedKmh")))
                .heading(numberOrNull(body.get("heading")))
                .recordedAt(LocalDateTime.now())
                .build());
        return ResponseEntity.noContent().build();
    }

    // ── Route Stops ───────────────────────────────────────────

    /**
     * GET /api/v1/conductor/route/{routeId}/stops
     * Returns ordered stop list for boarding/alighting dropdowns.
     */
    @GetMapping("/route/{routeId}/stops")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<List<StopDTO>> getRouteStops(
            @PathVariable Integer routeId) {
        return ResponseEntity.ok(
                conductorService.getRouteStops(routeId));
    }

    // ── Welfare ───────────────────────────────────────────────

    /**
     * GET /api/v1/conductor/welfare
     * Returns conductor's welfare balance history per month.
     */
    @GetMapping("/welfare")
    @PreAuthorize("hasRole('conductor')")
    public ResponseEntity<List<ConductorWelfareDTO>> getWelfare(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                conductorService.getWelfareHistory(user.getStaffId()));
    }

    private BigDecimal numberOrNull(Object value) {
        return value instanceof Number n
                ? BigDecimal.valueOf(n.doubleValue())
                : null;
    }
}
