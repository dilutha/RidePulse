package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.config.*;
import com.ridepulse.backend.dto.auth.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.*;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository          userRepo;
    private final BusOwnerRepository      busOwnerRepo;
    private final StaffRepository         staffRepo;
    private final BusRepository           busRepo;
    private final StaffBusAssignmentRepository assignmentRepo;
    private final AuthenticationManager   authManager;
    private final JwtService              jwtService;
    private final PasswordEncoder         passwordEncoder;
    private final CustomUserDetailsService userDetailsService;

    /**
     * Login — shared for ALL roles.
     * OOP Polymorphism: same method handles passenger, driver, conductor,
     *                   bus_owner, and authority via role claim in JWT.
     */
    @Override
    public AuthResponse login(LoginRequest request) {
        // Spring Security handles credential validation
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

        CustomUserDetails userDetails =
                (CustomUserDetails) userDetailsService.loadUserByUsername(request.getEmail());

        String token = jwtService.generateToken(userDetails);

        // Resolve staffId for driver/conductor
        Integer staffId = null;
        if ("driver".equals(userDetails.getRole()) || "conductor".equals(userDetails.getRole())) {
            staffId = staffRepo.findByUserEmail(request.getEmail())
                    .map(Staff::getStaffId).orElse(null);
        }

        return AuthResponse.builder()
                .accessToken(token)
                .role(userDetails.getRole())
                .fullName(loadFullName(request.getEmail()))
                .email(request.getEmail())
                .ownerId(userDetails.getOwnerId())
                .staffId(staffId)
                .build();
    }

    /** Register Passenger — public endpoint */
    @Override
    @Transactional
    public AuthResponse registerPassenger(RegisterPassengerRequest req) {
        validateEmailUnique(req.getEmail());

        User user = createBaseUser(
                req.getFullName(), req.getEmail(), req.getPhone(),
                req.getPassword(), User.UserRole.passenger);

        userRepo.save(user);
        return buildAuthResponse(user, null, null);
    }

    /** Register Bus Owner — public endpoint */
    @Override
    @Transactional
    public AuthResponse registerBusOwner(RegisterBusOwnerRequest req) {
        validateEmailUnique(req.getEmail());

        User user = createBaseUser(
                req.getFullName(), req.getEmail(), req.getPhone(),
                req.getPassword(), User.UserRole.bus_owner);
        userRepo.save(user);

        // Inheritance: BusOwner profile extends User
        BusOwner owner = BusOwner.builder()
                .user(user)
                .businessName(req.getBusinessName())
                .nicNumber(req.getNicNumber())
                .address(req.getAddress())
                .build();
        busOwnerRepo.save(owner);

        return buildAuthResponse(user, owner.getOwnerId(), null);
    }

    /** Register Authority — public endpoint (in production: invite-only) */
    @Override
    @Transactional
    public AuthResponse registerAuthority(RegisterAuthorityRequest req) {
        validateEmailUnique(req.getEmail());

        User user = createBaseUser(
                req.getFullName(), req.getEmail(), req.getPhone(),
                req.getPassword(), User.UserRole.authority);
        userRepo.save(user);

        return buildAuthResponse(user, null, null);
    }

    /**
     * Register Staff (Driver or Conductor) — called by Bus Owner only.
     * OOP Polymorphism: staffType field determines which fields are required
     *                   and how the staff entity is configured.
     */
    // ============================================================
// AuthServiceImpl.java — ONLY THE registerStaff() METHOD CHANGES
// Replace the existing registerStaff() with this version.
// Everything else in the file stays the same.
// ============================================================

// FIND the existing registerStaff() method and REPLACE with:

    @Override
    @Transactional
    public AuthResponse registerStaff(RegisterStaffRequest req, Integer ownerId) {
        validateEmailUnique(req.getEmail());

        // Polymorphism: map staffType string to UserRole enum
        User.UserRole userRole = "driver".equals(req.getStaffType())
                ? User.UserRole.driver
                : User.UserRole.conductor;

        User user = createBaseUser(
                req.getFullName(), req.getEmail(), req.getPhone(),
                req.getPassword(), userRole);
        userRepo.save(user);

        // Resolve the bus owner for direct linking
        // OOP Encapsulation: owner resolution is hidden here
        BusOwner busOwner = null;
        if (ownerId != null) {
            busOwner = busOwnerRepo.findById(ownerId).orElse(null);
        }

        // Build staff profile
        // OOP Polymorphism: licenseNumber/licenseExpiry only populated for driver
        Staff staff = Staff.builder()
                .user(user)
                .busOwner(busOwner)                        // NEW: direct owner link
                .staffType(Staff.StaffType.valueOf(req.getStaffType()))
                .employeeId(req.getEmployeeId())
                .dateOfJoining(req.getDateOfJoining() != null
                        ? req.getDateOfJoining() : LocalDate.now())
                .licenseNumber(req.getLicenseNumber())
                .licenseExpiry(req.getLicenseExpiry())
                .baseSalary(req.getBaseSalary() != null
                        ? req.getBaseSalary() : java.math.BigDecimal.ZERO)
                .isActive(true)
                .build();
        staffRepo.save(staff);

        // Optionally assign to a bus immediately
        if (req.getBusId() != null) {
            Bus bus = busRepo.findById(req.getBusId())
                    .orElseThrow(() -> new RuntimeException("Bus not found"));

            StaffBusAssignment assignment = StaffBusAssignment.builder()
                    .staff(staff)
                    .bus(bus)
                    .assignedDate(LocalDate.now())
                    .isCurrent(true)
                    .build();
            assignmentRepo.save(assignment);
        }

        return buildAuthResponse(user, null, staff.getStaffId());
    }


    // ── Private helpers (Encapsulation: hidden from callers) ──

    private User createBaseUser(String fullName, String email, String phone,
                                String password, User.UserRole role) {
        return User.builder()
                .fullName(fullName)
                .email(email)
                .phone(phone)
                .passwordHash(passwordEncoder.encode(password)) // Encapsulation: raw password encoded
                .role(role)
                .isActive(true)
                .build();
    }

    private void validateEmailUnique(String email) {
        if (userRepo.existsByEmail(email)) {
            throw new RuntimeException("Email already registered: " + email);
        }
    }

    private String loadFullName(String email) {
        return userRepo.findByEmail(email)
                .map(User::getFullName).orElse("");
    }

    private AuthResponse buildAuthResponse(User user, Integer ownerId, Integer staffId) {
        CustomUserDetails details = new CustomUserDetails(user, ownerId, staffId);
        return AuthResponse.builder()
                .accessToken(jwtService.generateToken(details))
                .role(user.getRole().name())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .ownerId(ownerId)
                .staffId(staffId)
                .build();
    }
}


// ============================================================
// FILE: controller/AuthController.java
// REST endpoints for auth — one endpoint per registration type
// OOP Encapsulation: hides service details behind clean HTTP API
// ============================================================
