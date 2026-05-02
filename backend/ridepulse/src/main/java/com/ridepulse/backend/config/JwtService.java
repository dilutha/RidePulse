package com.ridepulse.backend.config;

// ============================================================
// JwtService.java — UPDATED
//
// ADDED: extractOwnerId(), extractStaffId(), extractUserId(),
//        extractFullName() so JwtAuthFilter can build
//        CustomUserDetails directly from claims with no DB hit.
//
// OOP Encapsulation: all token crypto is private.
//     Callers only use the public extract* methods.
// ============================================================

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class JwtService {

    @Value("${app.jwt.secret}")
    private String jwtSecret;

    @Value("${app.jwt.expiration-ms}")
    private long jwtExpirationMs;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    /**
     * Generates a JWT embedding all fields needed to rebuild the principal
     * on subsequent requests — without touching the database.
     */
    public String generateToken(CustomUserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role",     userDetails.getRole());
        claims.put("userId",   userDetails.getUserId().toString());
        claims.put("fullName", userDetails.getFullName());
        claims.put("ownerId",  userDetails.getOwnerId());  // null for non-owners
        claims.put("staffId",  userDetails.getStaffId());  // null for non-staff

        return Jwts.builder()
                .claims(claims)
                .subject(userDetails.getUsername())        // email
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtExpirationMs))
                .signWith(getSigningKey())
                .compact();
    }

    // ── Claim extractors (Encapsulation: parsing is private) ─────────────

    public String extractEmail(String token) {
        return extractAllClaims(token).getSubject();
    }

    public String extractRole(String token) {
        return extractAllClaims(token).get("role", String.class);
    }

    public String extractFullName(String token) {
        return extractAllClaims(token).get("fullName", String.class);
    }

    public UUID extractUserId(String token) {
        String raw = extractAllClaims(token).get("userId", String.class);
        return raw != null ? UUID.fromString(raw) : null;
    }

    public Integer extractOwnerId(String token) {
        Object raw = extractAllClaims(token).get("ownerId");
        if (raw == null) return null;
        return raw instanceof Integer ? (Integer) raw : ((Number) raw).intValue();
    }

    public Integer extractStaffId(String token) {
        Object raw = extractAllClaims(token).get("staffId");
        if (raw == null) return null;
        return raw instanceof Integer ? (Integer) raw : ((Number) raw).intValue();
    }

    public boolean isTokenValid(String token, String email) {
        final String tokenEmail = extractEmail(token);
        return tokenEmail != null
                && tokenEmail.equals(email)
                && !isTokenExpired(token);
    }

    // Keep backward-compatible overload for any callers passing CustomUserDetails
    public boolean isTokenValid(String token, CustomUserDetails userDetails) {
        return isTokenValid(token, userDetails.getUsername());
    }

    private boolean isTokenExpired(String token) {
        return extractAllClaims(token).getExpiration().before(new Date());
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
