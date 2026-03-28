package com.ridepulse.backend.service.impl;

// ============================================================
// StaffManagementServiceImpl.java — COMPLETE FIXED VERSION
// Changes:
//   1. getStaffByOwner() now uses direct owner FK query
//      so unassigned staff appear in the list.
//   2. toggleStaffStatus() and updateBaseSalary() now accept
//      unassigned staff (removed strict assignment check).
//   3. buildStaffProfileDTO() already handles null bus.
// OOP Encapsulation: all business logic hidden behind interface.
// OOP Polymorphism: null bus handled gracefully throughout.
// ============================================================

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.StaffManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StaffManagementServiceImpl implements StaffManagementService {

    private final StaffRepository              staffRepo;
    private final BusOwnerRepository           busOwnerRepo;
    private final StaffBusAssignmentRepository assignmentRepo;
    private final StaffWelfareBalanceRepository welfareRepo;
    private final DutyRosterRepository          rosterRepo;
    private final BusRepository                busRepo;

    // ── Get all staff ─────────────────────────────────────────

    /**
     * Returns ALL staff under this owner — assigned OR unassigned.
     * OOP Abstraction: callers don't know how ownership is determined.
     *
     * FIX: previously only returned staff with a StaffBusAssignment.
     *      Now uses direct busOwner FK on Staff entity.
     */
    @Override
    public List<StaffProfileDTO> getStaffByOwner(Integer ownerId) {
        // PRIMARY path: use direct owner FK (includes unassigned staff)
        List<Staff> allStaff = staffRepo.findByBusOwner_OwnerId(ownerId);

        return allStaff.stream()
                .map(staff -> {
                    // Find current bus assignment if any — null = unassigned
                    Bus bus = assignmentRepo
                            .findCurrentAssignmentByStaff(staff.getStaffId())
                            .map(a -> a.getBus())
                            .orElse(null);
                    return buildStaffProfileDTO(staff, bus);
                })
                .collect(Collectors.toList());
    }

    // ── Get single staff profile ──────────────────────────────

    @Override
    public StaffProfileDTO getStaffProfile(Integer staffId, Integer ownerId) {
        Staff staff = staffRepo.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        // Security: verify this staff belongs to this owner
        // Check via direct FK first (faster), fall back to assignment check
        boolean ownerMatches = staff.getBusOwner() != null
                && staff.getBusOwner().getOwnerId().equals(ownerId);

        if (!ownerMatches) {
            // Fall back: check via bus assignment
            assignmentRepo.findCurrentAssignmentByStaffAndOwner(staffId, ownerId)
                    .orElseThrow(() -> new RuntimeException(
                            "Staff not found under this owner"));
        }

        Bus bus = assignmentRepo
                .findCurrentAssignmentByStaff(staffId)
                .map(StaffBusAssignment::getBus)
                .orElse(null);

        return buildStaffProfileDTO(staff, bus);
    }

    // ── Toggle status ─────────────────────────────────────────

    @Override
    @Transactional
    public void toggleStaffStatus(ToggleStaffStatusRequest request,
                                  Integer ownerId) {
        Staff staff = staffRepo.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        // Security: verify ownership (direct FK or assignment)
        verifyOwnership(staff, request.getStaffId(), ownerId);

        staff.setIsActive(request.getIsActive());
        staffRepo.save(staff);
    }

    // ── Update salary ─────────────────────────────────────────

    @Override
    @Transactional
    public void updateBaseSalary(UpdateSalaryRequest request,
                                 Integer ownerId) {
        Staff staff = staffRepo.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        verifyOwnership(staff, request.getStaffId(), ownerId);

        staff.setBaseSalary(request.getBaseSalary());
        staffRepo.save(staff);
    }

    // ── Assign staff to bus ───────────────────────────────────

    @Override
    @Transactional
    public void assignStaffToBus(StaffAssignRequest request,
                                 Integer ownerId) {
        // Close existing assignment if any
        assignmentRepo.findCurrentAssignmentByStaff(request.getStaffId())
                .ifPresent(a -> {
                    a.setIsCurrent(false);
                    a.setUnassignedDate(LocalDate.now());
                    assignmentRepo.save(a);
                });

        Bus bus = busRepo.findById(request.getBusId())
                .orElseThrow(() -> new RuntimeException("Bus not found"));
        Staff staff = staffRepo.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        StaffBusAssignment assignment = StaffBusAssignment.builder()
                .staff(staff)
                .bus(bus)
                .assignedDate(request.getAssignedDate())
                .isCurrent(true)
                .build();
        assignmentRepo.save(assignment);
    }

    // ── Unassign staff from bus ───────────────────────────────

    @Override
    @Transactional
    public void unassignStaff(Integer staffId, Integer ownerId) {
        StaffBusAssignment assignment =
                assignmentRepo.findCurrentAssignmentByStaffAndOwner(staffId, ownerId)
                        .orElseThrow(() -> new RuntimeException("Assignment not found"));

        assignment.setIsCurrent(false);
        assignment.setUnassignedDate(LocalDate.now());
        assignmentRepo.save(assignment);
    }

    // ── Private helpers (Encapsulation) ──────────────────────

    /**
     * Verifies the requesting owner has authority over this staff member.
     * OOP Encapsulation: security check hidden from callers.
     */
    private void verifyOwnership(Staff staff, Integer staffId,
                                 Integer ownerId) {
        boolean directMatch = staff.getBusOwner() != null
                && staff.getBusOwner().getOwnerId().equals(ownerId);

        if (!directMatch) {
            // Fall back to assignment-based check
            assignmentRepo.findCurrentAssignmentByStaffAndOwner(staffId, ownerId)
                    .orElseThrow(() -> new RuntimeException(
                            "Not authorized to modify this staff member"));
        }
    }

    /**
     * Builds a StaffProfileDTO.
     * OOP Polymorphism: bus parameter may be null for unassigned staff —
     *     handled gracefully throughout.
     */
    private StaffProfileDTO buildStaffProfileDTO(Staff staff, Bus bus) {
        YearMonth current = YearMonth.now();

        Integer dutyDays = rosterRepo.countDutyDaysForStaffInMonth(
                staff.getStaffId(), current.getMonthValue(), current.getYear());

        StaffWelfareBalance welfare = welfareRepo
                .findByStaffAndMonth(
                        staff.getStaffId(),
                        current.getMonthValue(),
                        current.getYear())
                .orElse(null);

        return StaffProfileDTO.builder()
                .staffId(staff.getStaffId())
                .fullName(staff.getUser().getFullName())
                .phone(staff.getUser().getPhone())
                .employeeId(staff.getEmployeeId())
                .staffType(staff.getStaffType().name())
                .licenseNumber(staff.getLicenseNumber())
                .baseSalary(staff.getBaseSalary())
                .isActive(staff.getIsActive())
                // Null-safe bus fields
                .assignedBusNumber(
                        bus != null ? bus.getBusNumber() : "Unassigned")
                .dutyDaysThisMonth(dutyDays != null ? dutyDays : 0)
                .welfareBalanceThisMonth(
                        welfare != null
                                ? welfare.getWelfareAmount()
                                : java.math.BigDecimal.ZERO)
                .cumulativeWelfareBalance(
                        welfare != null
                                ? welfare.getCumulativeBalance()
                                : java.math.BigDecimal.ZERO)
                .build();
    }
}
