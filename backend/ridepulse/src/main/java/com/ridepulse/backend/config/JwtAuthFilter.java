package com.ridepulse.backend.config;

// ============================================================
// JwtAuthFilter.java — UPDATED (THE KEY FIX)
//
// ROOT CAUSE OF DRIVER 401:
//   The old filter called userDetailsService.loadUserByUsername(email)
//   on EVERY request. This hit the database. If the Staff record
//   lookup threw UsernameNotFoundException (due to orElseThrow),
//   Spring Security returned 401 silently.
//
// FIX:
//   Build CustomUserDetails directly from JWT claims — NO DB query.
//   The JWT already contains role, userId, fullName, ownerId, staffId.
//   Token signature verification proves authenticity; no DB needed.
//
// OOP Encapsulation: filter logic is self-contained here.
// OOP Abstraction:   downstream controllers receive a fully-populated
//                    CustomUserDetails via @AuthenticationPrincipal.
// ============================================================

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.NonNull;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    // NOTE: CustomUserDetailsService is no longer needed here —
    // we build the principal from JWT claims, not from the DB.

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest  request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain         filterChain
    ) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        // No token → continue unauthenticated (public endpoints still work)
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);

        try {
            // Step 1: Extract email (subject) from JWT
            final String email = jwtService.extractEmail(jwt);

            if (email == null || SecurityContextHolder.getContext()
                    .getAuthentication() != null) {
                filterChain.doFilter(request, response);
                return;
            }

            // Step 2: Validate token (signature + expiry) using just email
            if (!jwtService.isTokenValid(jwt, email)) {
                log.warn("Invalid or expired JWT for: {}", email);
                filterChain.doFilter(request, response);
                return;
            }

            // Step 3: Build principal directly from JWT claims — NO DB QUERY
            // OOP Abstraction: all claims extraction is encapsulated in JwtService
            String  role     = jwtService.extractRole(jwt);
            String  fullName = jwtService.extractFullName(jwt);
            UUID    userId   = jwtService.extractUserId(jwt);
            Integer ownerId  = jwtService.extractOwnerId(jwt);
            Integer staffId  = jwtService.extractStaffId(jwt);

            if (role == null) {
                log.warn("JWT missing role claim for: {}", email);
                filterChain.doFilter(request, response);
                return;
            }

            // Step 4: Create principal using the claims-based constructor
            // This is the fix — no UserDetailsService.loadUserByUsername() call
            CustomUserDetails principal = new CustomUserDetails(
                    userId, email, fullName, role, ownerId, staffId);

            // Step 5: Set authentication in SecurityContext
            UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(
                            principal,
                            null,
                            principal.getAuthorities()); // e.g. [ROLE_driver]

            authToken.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request));

            SecurityContextHolder.getContext().setAuthentication(authToken);

            log.debug("Authenticated: {} role={} staffId={}",
                    email, role, staffId);

        } catch (Exception e) {
            // Any JWT parsing error → continue unauthenticated
            // Spring Security will return 401 for protected endpoints
            log.warn("JWT processing failed: {}", e.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
