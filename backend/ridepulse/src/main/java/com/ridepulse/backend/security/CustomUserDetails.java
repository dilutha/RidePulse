package com.ridepulse.backend.security;

import com.ridepulse.backend.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;

/**
 * CustomUserDetails
 *
 * Adapter that converts the application's User entity
 * into Spring Security's UserDetails format.
 */
@RequiredArgsConstructor
public class CustomUserDetails implements UserDetails {

    private final User user;

    /**
     * Convert user role into Spring Security authority.
     */
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {

        return Collections.singletonList(
                new SimpleGrantedAuthority(user.getRole().name())
        );
    }

    /**
     * Return hashed password stored in database.
     */
    @Override
    public String getPassword() {
        return user.getPasswordHash();
    }

    /**
     * Username used by Spring Security (email in this system).
     */
    @Override
    public String getUsername() {
        return user.getEmail();
    }

    /**
     * Account expiration status.
     */
    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    /**
     * Account lock status.
     */
    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    /**
     * Credential expiration status.
     */
    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    /**
     * Whether the account is active.
     */
    @Override
    public boolean isEnabled() {
        return user.getIsActive();
    }
}