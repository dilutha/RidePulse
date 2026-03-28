package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.DutyRosterService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DutyRosterServiceImpl implements DutyRosterService {

    private final DutyRosterRepository rosterRepo;
    private final StaffRepository      staffRepo;
    private final BusRepository        busRepo;
    private final RouteRepository      routeRepo;
    private final BusOwnerRepository   ownerRepo;

    private static final DateTimeFormatter D = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter T = DateTimeFormatter.ofPattern("HH:mm");

    // ── Bus Owner ─────────────────────────────────────────────

    @Override
    public List<RosterDetailDTO> getRostersByOwner(Integer ownerId,
                                                   String from, String to) {
        LocalDate fromDate = LocalDate.parse(from);
        LocalDate toDate   = LocalDate.parse(to);

        // Get all buses under this owner, then fetch rosters for each
        return busRepo.findByOwner_OwnerId(ownerId).stream()
                .flatMap(bus -> rosterRepo
                        .findByBusAndDateRange(bus.getBusId(), fromDate, toDate)
                        .stream())
                .map(this::toDTO)
                .sorted((a, b) -> a.getDutyDate().compareTo(b.getDutyDate()))
                .collect(Collectors.toList());
    }

    @Override
    public List<RosterDetailDTO> getRostersByBus(Integer busId, Integer ownerId,
                                                 String from, String to) {
        // Security: verify bus belongs to owner
        busRepo.findByBusIdAndOwner_OwnerId(busId, ownerId)
                .orElseThrow(() -> new RuntimeException("Bus not found under your account"));

        return rosterRepo.findByBusAndDateRange(
                        busId, LocalDate.parse(from), LocalDate.parse(to))
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    /**
     * Creates a duty roster entry for a staff member on a bus.
     * OOP Encapsulation: validation and entity assembly hidden here.
     */
    @Override
    @Transactional
    public RosterDetailDTO createRoster(CreateRosterRequest req,
                                        Integer ownerId) {
        // Verify bus belongs to owner
        Bus bus = busRepo.findByBusIdAndOwner_OwnerId(req.getBusId(), ownerId)
                .orElseThrow(() -> new RuntimeException(
                        "Bus not found under your account"));

        Staff staff = staffRepo.findById(req.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        // Prevent duplicate roster for same staff on same date
        boolean alreadyScheduled = rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(
                        req.getStaffId(), LocalDate.parse(req.getDutyDate()))
                .stream()
                .anyMatch(r -> r.getBus().getBusId().equals(req.getBusId()));

        if (alreadyScheduled) {
            throw new RuntimeException(
                    "This staff member is already scheduled on this bus for that date");
        }

        DutyRoster roster = DutyRoster.builder()
                .staff(staff)
                .bus(bus)
                .route(bus.getRoute())   // route inherited from bus
                .dutyDate(LocalDate.parse(req.getDutyDate()))
                .shiftStart(LocalTime.parse(req.getShiftStart()))
                .shiftEnd(LocalTime.parse(req.getShiftEnd()))
                .status("scheduled")
                .build();

        return toDTO(rosterRepo.save(roster));
    }

    @Override
    @Transactional
    public RosterDetailDTO updateRoster(Integer rosterId,
                                        UpdateRosterRequest req,
                                        Integer ownerId) {
        DutyRoster roster = rosterRepo.findById(rosterId)
                .orElseThrow(() -> new RuntimeException("Roster not found"));

        // Security: verify this roster's bus belongs to owner
        if (!roster.getBus().getOwner().getOwnerId().equals(ownerId)) {
            throw new RuntimeException("Unauthorized");
        }

        applyUpdates(roster, req);
        return toDTO(rosterRepo.save(roster));
    }

    @Override
    @Transactional
    public void deleteRoster(Integer rosterId, Integer ownerId) {
        DutyRoster roster = rosterRepo.findById(rosterId)
                .orElseThrow(() -> new RuntimeException("Roster not found"));

        if (!roster.getBus().getOwner().getOwnerId().equals(ownerId)) {
            throw new RuntimeException("Unauthorized");
        }

        if ("active".equals(roster.getStatus())) {
            throw new RuntimeException(
                    "Cannot delete an active roster. Stop the trip first.");
        }

        rosterRepo.delete(roster);
    }

    // ── Authority ─────────────────────────────────────────────

    @Override
    public List<RosterDetailDTO> getAllRosters(String from, String to) {
        LocalDate fromDate = LocalDate.parse(from);
        LocalDate toDate   = LocalDate.parse(to);

        // Authority sees all rosters across all buses
        return busRepo.findAll().stream()
                .flatMap(bus -> rosterRepo
                        .findByBusAndDateRange(bus.getBusId(), fromDate, toDate)
                        .stream())
                .map(this::toDTO)
                .sorted((a, b) -> a.getDutyDate().compareTo(b.getDutyDate()))
                .collect(Collectors.toList());
    }

    /**
     * Authority can update any roster — including changing status.
     * OOP Polymorphism: authority version skips ownership check.
     */
    @Override
    @Transactional
    public RosterDetailDTO updateRosterByAuthority(Integer rosterId,
                                                   UpdateRosterRequest req) {
        DutyRoster roster = rosterRepo.findById(rosterId)
                .orElseThrow(() -> new RuntimeException("Roster not found"));
        applyUpdates(roster, req);
        return toDTO(rosterRepo.save(roster));
    }

    // ── Private helpers ───────────────────────────────────────

    private void applyUpdates(DutyRoster roster, UpdateRosterRequest req) {
        if (req.getShiftStart() != null)
            roster.setShiftStart(LocalTime.parse(req.getShiftStart()));
        if (req.getShiftEnd() != null)
            roster.setShiftEnd(LocalTime.parse(req.getShiftEnd()));
        if (req.getDutyDate() != null)
            roster.setDutyDate(LocalDate.parse(req.getDutyDate()));
        if (req.getStatus() != null)
            roster.setStatus(req.getStatus());
    }

    private RosterDetailDTO toDTO(DutyRoster r) {

        return RosterDetailDTO.builder()
                .rosterId(r.getRosterId())
                .dutyDate(r.getDutyDate().format(D))
                .shiftStart(r.getShiftStart().format(T))
                .shiftEnd(r.getShiftEnd().format(T))
                .status(r.getStatus() != null ? r.getStatus() : "scheduled")
                // Staff
                .staffId(r.getStaff().getStaffId())
                .staffName(r.getStaff().getUser().getFullName())
                .staffType(r.getStaff().getStaffType().name())
                .employeeId(r.getStaff().getEmployeeId())
                // Bus
                .busId(r.getBus().getBusId())
                .busNumber(r.getBus().getBusNumber())
                .registrationNumber(r.getBus().getRegistrationNumber())
                .busCapacity(r.getBus().getCapacity())
                // Route
                .routeId(r.getRoute() != null ? r.getRoute().getRouteId() : null)
                .routeNumber(r.getRoute() != null ? r.getRoute().getRouteNumber() : "N/A")
                .routeName(r.getRoute() != null ? r.getRoute().getRouteName() : "N/A")
                .startLocation(r.getRoute() != null ? r.getRoute().getStartLocation() : "")
                .endLocation(r.getRoute() != null ? r.getRoute().getEndLocation() : "")
                .baseFare(r.getRoute() != null ? r.getRoute().getBaseFare().doubleValue() : 0)
                .activeTripId(null)
                .tripStatus(null)
                .build();
    }
}
