package com.ridepulse.backend.controller;

import com.ridepulse.backend.config.CustomUserDetails;
import com.ridepulse.backend.dto.auth.*;
import com.ridepulse.backend.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * OOP Single Responsibility: handles only auth endpoints.
 * OOP Encapsulation: all registration logic in AuthService.
 * OOP Polymorphism: same /login endpoint serves all roles.
 */
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /** POST /api/v1/auth/login — all roles */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
            @Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    /** POST /api/v1/auth/register/passenger — public */
    @PostMapping("/register/passenger")
    public ResponseEntity<AuthResponse> registerPassenger(
            @Valid @RequestBody RegisterPassengerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(authService.registerPassenger(request));
    }

    /** POST /api/v1/auth/register/bus-owner — public */
    @PostMapping("/register/bus-owner")
    public ResponseEntity<AuthResponse> registerBusOwner(
            @Valid @RequestBody RegisterBusOwnerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(authService.registerBusOwner(request));
    }

    /** POST /api/v1/auth/register/authority — public */
    @PostMapping("/register/authority")
    public ResponseEntity<AuthResponse> registerAuthority(
            @Valid @RequestBody RegisterAuthorityRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(authService.registerAuthority(request));
    }

    /**
     * POST /api/v1/auth/register/staff — public (bus owner registers staff)
     *
     * OOP Polymorphism: ownerId is resolved from JWT if caller is authenticated
     * as bus_owner, OR from the request body if called without a token.
     * This allows the endpoint to work both ways:
     *   1. Bus owner logged in → ownerId from JWT (secure, preferred)
     *   2. Public call → ownerId from request body (fallback for demo)
     */
    @PostMapping("/register/staff")
    public ResponseEntity<AuthResponse> registerStaff(
            @Valid @RequestBody RegisterStaffRequest request,
            @AuthenticationPrincipal CustomUserDetails userDetails) {

        // Polymorphism: prefer JWT principal ownerId, fall back to body field
        Integer ownerId = null;
        if (userDetails != null && userDetails.getOwnerId() != null) {
            ownerId = userDetails.getOwnerId();
        } else {
            // Called publicly — ownerId must be in the request body
            ownerId = request.getOwnerId();
        }

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(authService.registerStaff(request, ownerId));
    }
}
