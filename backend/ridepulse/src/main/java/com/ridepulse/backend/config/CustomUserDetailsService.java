package com.ridepulse.backend.config;

// ============================================================
// CustomUserDetailsService.java — UPDATED
//
// This service is now called ONLY at login (by AuthenticationManager)
// and NOT on every request (JwtAuthFilter now uses claims directly).
//
// The orElseThrow → orElse(null) fix is still applied here so that
// login itself doesn't fail if the staff record is temporarily missing.
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

        User user = userRepo.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "No account: " + email));

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
            staffId = staffRepo.findByUser_UserId(user.getUserId())
                    .map(s -> s.getStaffId())
                    .orElse(null);

            if (staffId == null) {
                log.warn("Staff profile missing for: {} ({})",
                        email, user.getRole());
            }
        }

        return new CustomUserDetails(user, ownerId, staffId);
    }
}
