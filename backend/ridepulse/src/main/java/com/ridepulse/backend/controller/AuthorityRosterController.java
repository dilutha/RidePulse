package com.ridepulse.backend.controller;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.service.DutyRosterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/authority/roster")
@RequiredArgsConstructor
public class AuthorityRosterController {

    private final DutyRosterService rosterService;

    /**
     * GET /api/v1/authority/roster?from=2025-01-01&to=2025-01-31
     * View all rosters across all owners.
     */
    @GetMapping
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<List<RosterDetailDTO>> getAllRosters(
            @RequestParam String from,
            @RequestParam String to) {
        return ResponseEntity.ok(rosterService.getAllRosters(from, to));
    }

    /**
     * PATCH /api/v1/authority/roster/{rosterId}
     * Authority can update any roster — status, times.
     */
    @PatchMapping("/{rosterId}")
    @PreAuthorize("hasRole('authority')")
    public ResponseEntity<RosterDetailDTO> updateRoster(
            @PathVariable Integer rosterId,
            @Valid @RequestBody UpdateRosterRequest request) {
        return ResponseEntity.ok(
                rosterService.updateRosterByAuthority(rosterId, request));
    }
}
