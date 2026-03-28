package com.ridepulse.backend.config;

// ============================================================
// CustomUserDetailsService.java — FINAL FIXED VERSION
//
// FIX: Changed .orElseThrow() → .orElse(null) for driver/conductor
// staffId lookup. Previously this threw UsernameNotFoundException
// when the staff record wasn't found, which caused Spring Security
// to reject login with 401 before the JWT was even issued.
//
// With orElse(null), login succeeds and the driver gets a JWT.
// If staffId is null, the controller will give a meaningful error.
//
// OOP Encapsulation: DB resolution hidden here — callers only
//     see the UserDetails contract.
// OOP Polymorphism: role drives which secondary ID is resolved.
// ============================================================

import com.ridepulse.backend.entity.User;
import com.ridepulse.backend.entity.User.UserRole;
import com.ridepulse.backend.repository.BusOwnerRepository;
import com.ridepulse.backend.repository.StaffRepository;
import com.ridepulse.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository     userRepo;
    private final BusOwnerRepository busOwnerRepo;
    private final StaffRepository    staffRepo;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String email)
            throws UsernameNotFoundException {

        // Step 1: load base user
        User user = userRepo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No account: " + email));

        // Step 2: resolve role-specific secondary ID
        // OOP Polymorphism: branch by role
        Integer ownerId = null;
        Integer staffId = null;

        if (user.getRole() == UserRole.bus_owner) {
            ownerId = busOwnerRepo.findByUser(user)
                    .map(o -> o.getOwnerId())
                    .orElseThrow(() -> new UsernameNotFoundException(
                            "Bus owner profile not found: " + email));

        } else if (user.getRole() == UserRole.driver
                || user.getRole() == UserRole.conductor) {

            // FIX: orElse(null) — login never fails due to missing staff record.
            // The role is already correct in User.role, so the JWT will carry
            // ROLE_driver / ROLE_conductor. If staffId is null, the service
            // layer will throw a meaningful 404, not a silent 401.
            staffId = staffRepo.findByUser_UserId(user.getUserId())
                    .map(s -> s.getStaffId())
                    .orElse(null);

            if (staffId == null) {
                log.warn("Staff profile missing for user: {} role: {}",
                        email, user.getRole());
            }
        }

        return new CustomUserDetails(user, ownerId, staffId);
    }
}
