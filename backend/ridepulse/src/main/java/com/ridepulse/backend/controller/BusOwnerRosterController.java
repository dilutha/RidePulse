package com.ridepulse.backend.controller;

import com.ridepulse.backend.config.CustomUserDetails;
import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.service.DutyRosterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/bus-owner/roster")
@RequiredArgsConstructor
public class BusOwnerRosterController {

    private final DutyRosterService rosterService;

    /**
     * GET /api/v1/bus-owner/roster?from=2025-01-01&to=2025-01-31
     * All rosters for all buses owned by this owner in date range.
     */
    @GetMapping
    @PreAuthorize("hasRole('bus_owner')")
    public ResponseEntity<List<RosterDetailDTO>> getRosters(
            @RequestParam String from,
            @RequestParam String to,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                rosterService.getRostersByOwner(user.getOwnerId(), from, to));
    }

    /**
     * GET /api/v1/bus-owner/roster/bus/{busId}?from=...&to=...
     * Rosters for a specific bus.
     */
    @GetMapping("/bus/{busId}")
    @PreAuthorize("hasRole('bus_owner')")
    public ResponseEntity<List<RosterDetailDTO>> getRostersByBus(
            @PathVariable Integer busId,
            @RequestParam String from,
            @RequestParam String to,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                rosterService.getRostersByBus(busId, user.getOwnerId(), from, to));
    }

    /**
     * POST /api/v1/bus-owner/roster
     * Body: { staffId, busId, dutyDate, shiftStart, shiftEnd }
     * Creates a new duty roster entry.
     */
    @PostMapping
    @PreAuthorize("hasRole('bus_owner')")
    public ResponseEntity<RosterDetailDTO> createRoster(
            @Valid @RequestBody CreateRosterRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(rosterService.createRoster(request, user.getOwnerId()));
    }

    /**
     * PATCH /api/v1/bus-owner/roster/{rosterId}
     * Update shift time or date.
     */
    @PatchMapping("/{rosterId}")
    @PreAuthorize("hasRole('bus_owner')")
    public ResponseEntity<RosterDetailDTO> updateRoster(
            @PathVariable Integer rosterId,
            @Valid @RequestBody UpdateRosterRequest request,
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(
                rosterService.updateRoster(rosterId, request, user.getOwnerId()));
    }

    /**
     * DELETE /api/v1/bus-owner/roster/{rosterId}
     * Delete a scheduled (not active) roster entry.
     */
    @DeleteMapping("/{rosterId}")
    @PreAuthorize("hasRole('bus_owner')")
    public ResponseEntity<Void> deleteRoster(
            @PathVariable Integer rosterId,
            @AuthenticationPrincipal CustomUserDetails user) {
        rosterService.deleteRoster(rosterId, user.getOwnerId());
        return ResponseEntity.noContent().build();
    }
}
