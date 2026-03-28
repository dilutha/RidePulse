package com.ridepulse.backend.service;

// ============================================================
// DutyRosterService.java — interface
// OOP Abstraction: controllers never touch repositories.
//     Polymorphism: bus owner and authority share roster data
//     but authority has edit-all power, owner only edits own.
// ============================================================

import com.ridepulse.backend.dto.*;
import java.util.List;

public interface DutyRosterService {

    // ── Bus Owner operations ──────────────────────────────────
    List<RosterDetailDTO> getRostersByOwner(Integer ownerId, String from, String to);
    List<RosterDetailDTO> getRostersByBus(Integer busId, Integer ownerId,
                                          String from, String to);
    RosterDetailDTO createRoster(CreateRosterRequest request, Integer ownerId);
    RosterDetailDTO updateRoster(Integer rosterId, UpdateRosterRequest request,
                                 Integer ownerId);
    void deleteRoster(Integer rosterId, Integer ownerId);

    // ── Authority operations ──────────────────────────────────
    List<RosterDetailDTO> getAllRosters(String from, String to);
    RosterDetailDTO updateRosterByAuthority(Integer rosterId,
                                            UpdateRosterRequest request);
}