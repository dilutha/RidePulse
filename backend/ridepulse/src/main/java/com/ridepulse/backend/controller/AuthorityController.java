package com.ridepulse.controller;


import com.ridepulse.dto.*;
import com.ridepulse.service.AuthorityService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/authority")
@RequiredArgsConstructor
public class AuthorityController {

    private final AuthorityService authorityService;  // Abstraction: interface only

    // ── Dashboard ─────────────────────────────────────────────

    /**
     * GET /api/v1/authority/dashboard/stats
     * System-wide stats: buses, staff, owners, complaints.
     */
    @GetMapping("/dashboard/stats")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<AuthorityDashboardDTO> getDashboardStats() {
        return ResponseEntity.ok(authorityService.getDashboard());
    }

    // ── Buses ─────────────────────────────────────────────────

    /**
     * GET /api/v1/authority/buses
     * All buses across all owners with live GPS + crowd status.
     */
    @GetMapping("/buses")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<AuthorityBusDTO>> getAllBuses() {
        return ResponseEntity.ok(authorityService.getAllBuses());
    }

    // ── Staff ─────────────────────────────────────────────────

    /**
     * GET /api/v1/authority/staff/drivers
     */
    @GetMapping("/staff/drivers")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<AuthorityStaffDTO>> getAllDrivers() {
        return ResponseEntity.ok(authorityService.getAllDrivers());
    }

    /**
     * GET /api/v1/authority/staff/conductors
     */
    @GetMapping("/staff/conductors")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<AuthorityStaffDTO>> getAllConductors() {
        return ResponseEntity.ok(authorityService.getAllConductors());
    }

    // ── Bus Owners ────────────────────────────────────────────

    /**
     * GET /api/v1/authority/owners
     * All registered bus owners with fleet + staff summary.
     */
    @GetMapping("/owners")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<AuthorityOwnerDTO>> getAllOwners() {
        return ResponseEntity.ok(authorityService.getAllOwners());
    }

    // ── Fare Management ───────────────────────────────────────

    /**
     * GET /api/v1/authority/fares
     * Fare configuration for all active routes.
     */
    @GetMapping("/fares")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<FareConfigDTO>> getAllFares() {
        return ResponseEntity.ok(authorityService.getAllFareConfigs());
    }

    /**
     * GET /api/v1/authority/fares/{routeId}
     * Fare config for a specific route with preview table.
     */
    @GetMapping("/fares/{routeId}")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<FareConfigDTO> getFare(
            @PathVariable Integer routeId) {
        return ResponseEntity.ok(authorityService.getFareConfig(routeId));
    }

    /**
     * PATCH /api/v1/authority/fares
     * Body: { "routeId": 3, "baseFare": 45.00 }
     * Authority sets new base fare. Rules:
     *   - Minimum: LKR 30
     *   - Maximum: LKR 2422
     *   - Conductors issue tickets at baseFare + (stops × 8), clamped to [30, 2422]
     */
    @PatchMapping("/fares")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<FareConfigDTO> updateFare(
            @Valid @RequestBody UpdateFareRequest request) {
        return ResponseEntity.ok(authorityService.updateFare(request));
    }
}
