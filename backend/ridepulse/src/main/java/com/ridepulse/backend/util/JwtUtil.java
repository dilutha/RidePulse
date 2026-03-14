package com.ridepulse.backend.util;

import com.ridepulse.backend.config.JwtProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.SignatureAlgorithm;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * JWT Utility Class
 *
 * Handles:
 * - Token generation
 * - Token validation
 * - Claim extraction
 *
 * Uses configuration from JwtProperties.
 */
@Component
@RequiredArgsConstructor
public class JwtUtil {

    private final JwtProperties jwtProperties;

    // =========================================================
    // TOKEN GENERATION
    // =========================================================

    public String generateToken(String username) {
        return createToken(new HashMap<>(), username);
    }

    public String generateToken(String username, String role) {

        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);

        return createToken(claims, username);
    }

    private String createToken(Map<String, Object> claims, String subject) {

        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + jwtProperties.getExpiration()))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    // =========================================================
    // TOKEN VALIDATION
    // =========================================================

    public boolean validateToken(String token, String username) {

        final String extractedUsername = extractUsername(token);

        return extractedUsername.equals(username) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {

        return extractExpiration(token).before(new Date());
    }

    // =========================================================
    // CLAIM EXTRACTION
    // =========================================================

    public String extractUsername(String token) {

        return extractClaim(token, Claims::getSubject);
    }

    public String extractRole(String token) {

        return extractClaim(token, claims -> claims.get("role", String.class));
    }

    public Date extractExpiration(String token) {

        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> resolver) {

        final Claims claims = extractAllClaims(token);

        return resolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {

        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    // =========================================================
    // SIGNING KEY
    // =========================================================

    private SecretKey getSigningKey() {

        return Keys.hmacShaKeyFor(
                jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8)
        );
    }
}