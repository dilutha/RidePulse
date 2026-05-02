package com.ridepulse.backend.config;

// ============================================================
// CustomUserDetails.java — UPDATED
//
// ADDED: Second constructor that accepts raw field values.
//        Used by JwtAuthFilter to build the principal directly
//        from JWT claims — NO database query on every request.
//
// OOP Encapsulation: security-relevant fields are private final.
// OOP Polymorphism:  getAuthorities() builds role-specific
//                    Spring authority at runtime.
// OOP Abstraction:   Spring Security only ever sees UserDetails.
// ============================================================

import com.ridepulse.backend.entity.User;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Getter
public class CustomUserDetails implements UserDetails {

    // Encapsulation: all fields private final
    private final UUID    userId;
    private final String  email;
    private final String  passwordHash;
    private final String  fullName;
    private final String  role;
    private final boolean active;
    private final Integer ownerId;
    private final Integer staffId;

    // ── Constructor 1: from User entity (used at login & registration) ─

    public CustomUserDetails(User user, Integer ownerId, Integer staffId) {
        this.userId       = user.getUserId();
        this.email        = user.getEmail();
        this.passwordHash = user.getPasswordHash();
        this.fullName     = user.getFullName();
        this.role         = user.getRole().name();
        this.active       = Boolean.TRUE.equals(user.getIsActive());
        this.ownerId      = ownerId;
        this.staffId      = staffId;
    }

    // ── Constructor 2: from JWT claims (used by JwtAuthFilter) ──────────
    //
    // OOP Abstraction: JwtAuthFilter calls this instead of hitting the DB.
    // The JWT already carries all necessary identity information, so no
    // repository call is needed on every authenticated request.
    // This is the correct stateless JWT pattern.
    //
    // passwordHash is blank because JWT auth never checks the password.
    // active = true because an issued JWT means the user was active at login.

    public CustomUserDetails(UUID userId, String email, String fullName,
                             String role, Integer ownerId, Integer staffId) {
        this.userId       = userId;
        this.email        = email;
        this.passwordHash = "";       // not needed — JWT is already validated
        this.fullName     = fullName != null ? fullName : "";
        this.role         = role.toLowerCase();
        this.active       = true;     // JWT was issued → was active at login time
        this.ownerId      = ownerId;
        this.staffId      = staffId;
    }

    // ── UserDetails contract ─────────────────────────────────────────────

    /**
     * Polymorphism: "driver" → SimpleGrantedAuthority("ROLE_driver")
     * This is what @PreAuthorize("hasRole('driver')") checks against.
     */
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }

    @Override public String getPassword()   { return passwordHash; }
    @Override public String getUsername()   { return email; }

    @Override public boolean isAccountNonExpired()     { return true;   }
    @Override public boolean isAccountNonLocked()      { return active; }
    @Override public boolean isCredentialsNonExpired() { return true;   }
    @Override public boolean isEnabled()               { return active; }

    // ── Convenience helpers ───────────────────────────────────────────────
    public boolean isBusOwner()  { return "bus_owner".equals(role);  }
    public boolean isStaff()     { return "driver".equals(role) || "conductor".equals(role); }
    public boolean isPassenger() { return "passenger".equals(role);  }
    public boolean isAuthority() { return "authority".equals(role);  }
}
