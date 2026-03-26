package com.ridepulse.backend.service.impl;

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

/**
 * OOP Encapsulation: Implementation is hidden behind the interface.
 * Callers depend on StaffManagementService — not this class.
 */
@Service
@RequiredArgsConstructor
public class StaffManagementServiceImpl implements StaffManagementService {

    // Dependency injection — dependencies are encapsulated
    private final StaffRepository staffRepo;
    private final BusOwnerRepository busOwnerRepo;
    private final StaffBusAssignmentRepository assignmentRepo;
    private final StaffWelfareBalanceRepository welfareRepo;
    private final DutyRosterRepository rosterRepo;
    private final BusRepository busRepo;

    @Override
    public List<StaffProfileDTO> getStaffByOwner(Integer ownerId) {
        // Fetch all staff assigned to any bus owned by this owner
        List<Staff> staffList = staffRepo.findAllByOwnerId(ownerId);

        return staffList.stream()
                .map(staff -> {
                    var assignment = assignmentRepo
                            .findCurrentAssignmentByStaff(staff.getStaffId())
                            .orElse(null);

                    return buildStaffProfileDTO(
                            staff,
                            assignment != null ? assignment.getBus() : null
                    );
                })
                .collect(Collectors.toList());
    }

    @Override
    public StaffProfileDTO getStaffProfile(Integer staffId, Integer ownerId) {
        Staff staff = staffRepo.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        // Security: validate this staff belongs to the requesting owner
        StaffBusAssignment assignment = assignmentRepo
                .findCurrentAssignmentByStaffAndOwner(staffId, ownerId)
                .orElseThrow(() -> new RuntimeException("Staff not assigned to this owner"));

        return buildStaffProfileDTO(staff, assignment.getBus());
    }

    @Override
    @Transactional
    public void toggleStaffStatus(ToggleStaffStatusRequest request, Integer ownerId) {
        Staff staff = staffRepo.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        // Security: confirm this owner manages this staff member
        assignmentRepo.findCurrentAssignmentByStaffAndOwner(request.getStaffId(), ownerId)
                .orElseThrow(() -> new RuntimeException("Not authorized to modify this staff"));

        staff.setIsActive(request.getIsActive());
        staffRepo.save(staff);  // Encapsulation: status change goes through service, not direct DB
    }

    @Override
    @Transactional
    public void updateBaseSalary(UpdateSalaryRequest request, Integer ownerId) {
        Staff staff = staffRepo.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        assignmentRepo.findCurrentAssignmentByStaffAndOwner(request.getStaffId(), ownerId)
                .orElseThrow(() -> new RuntimeException("Not authorized to modify this staff"));

        staff.setBaseSalary(request.getBaseSalary());
        staffRepo.save(staff);
    }

    @Override
    @Transactional
    public void assignStaffToBus(StaffAssignRequest request, Integer ownerId) {
        // Unassign from current bus first (if any)
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

        StaffBusAssignment newAssignment = StaffBusAssignment.builder()
                .staff(staff)
                .bus(bus)
                .assignedDate(request.getAssignedDate())
                .isCurrent(true)
                .build();

        assignmentRepo.save(newAssignment);
    }

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

    // ── Private helper: Encapsulation — DTO construction is hidden here ──
    private StaffProfileDTO buildStaffProfileDTO(Staff staff, Bus bus) {
        YearMonth current = YearMonth.now();

        // Count duty days this month from roster table
        Integer dutyDays = rosterRepo.countDutyDaysForStaffInMonth(
                staff.getStaffId(), current.getMonthValue(), current.getYear());

        // Get welfare balance for this month
        StaffWelfareBalance welfare = welfareRepo
                .findByStaffAndMonth(staff.getStaffId(), current.getMonthValue(), current.getYear())
                .orElse(null);

        return StaffProfileDTO.builder()
                .staffId(staff.getStaffId())
                .fullName(staff.getUser().getFullName())
                .phone(staff.getUser().getPhone())
                .employeeId(staff.getEmployeeId())
                .staffType(staff.getStaffType().name())
                .licenseNumber(staff.getLicenseNumber())
                .licenseExpiry(staff.getLicenseExpiry())
                .dateOfJoining(staff.getDateOfJoining())
                .baseSalary(staff.getBaseSalary())
                .isActive(staff.getIsActive())
                .assignedBusNumber(bus != null ? bus.getBusNumber() : "Unassigned")
                .dutyDaysThisMonth(dutyDays != null ? dutyDays : 0)
                .welfareBalanceThisMonth(welfare != null ? welfare.getWelfareAmount() : java.math.BigDecimal.ZERO)
                .cumulativeWelfareBalance(welfare != null ? welfare.getCumulativeBalance() : java.math.BigDecimal.ZERO)
                .build();
    }
}