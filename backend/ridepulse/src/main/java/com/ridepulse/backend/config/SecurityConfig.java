package com.ridepulse.backend.config;

// ============================================================
// SecurityConfig.java — FIXED VERSION
//
// Fixes applied:
//   1. OPTIONS preflight allowed — Flutter (Chrome) sends OPTIONS
//      before every POST. Without this, the browser gets 403 on
//      the preflight and never sends the actual request.
//
//   2. AuthenticationEntryPoint added — returns 401 for missing/
//      invalid JWT instead of 403. Separates "not logged in" (401)
//      from "logged in but wrong role" (403) clearly.
//
//   3. Passenger routes added to permitAll — public bus/route data
//      readable without login.
//
// OOP Encapsulation: all security config in one place, private beans.
// ============================================================

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.*;
import org.springframework.http.*;
import org.springframework.security.authentication.*;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.*;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity          // enables @PreAuthorize on controller methods
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter            jwtAuthFilter;
    private final CustomUserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Stateless API — disable CSRF (JWT handles security)
                .csrf(csrf -> csrf.disable())

                // CORS — allow Flutter web app (Chrome) requests
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // No sessions — every request must carry a JWT
                .sessionManagement(s ->
                        s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // ── Authorization rules ───────────────────────────────────
                .authorizeHttpRequests(auth -> auth

                        // FIX 1: Allow ALL OPTIONS preflight requests without auth.
                        // Flutter (Chrome) sends OPTIONS before every POST/PUT/PATCH.
                        // Without this line, every mutation request gets 403.
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // Public auth endpoints
                        .requestMatchers(
                                "/api/v1/auth/login",
                                "/api/v1/auth/register/passenger",
                                "/api/v1/auth/register/bus-owner",
                                "/api/v1/auth/register/authority",
                                "/api/v1/auth/register/staff",
                                "/api/v1/auth/refresh"
                        ).permitAll()

                        // Public passenger data — no login needed to view buses
                        .requestMatchers(HttpMethod.GET,
                                "/api/v1/passenger/routes",
                                "/api/v1/passenger/routes/**",
                                "/api/v1/passenger/buses/**",
                                "/api/v1/routes",
                                "/api/v1/routes/**"
                        ).permitAll()

                        // Everything else requires a valid JWT
                        .anyRequest().authenticated()
                )

                // FIX 2: Return 401 (not 403) for missing/invalid JWT.
                // This makes it clear that the user needs to log in,
                // rather than falsely implying they're forbidden.
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(
                                new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))

                .authenticationProvider(authenticationProvider())
                .addFilterBefore(jwtAuthFilter,
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    // ── Beans ─────────────────────────────────────────────────

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /**
     * CORS — allows Flutter web (Chrome) to call the Spring Boot API.
     * OOP Encapsulation: CORS details hidden in this private method.
     *
     * Using setAllowedOriginPatterns("*") instead of setAllowedOrigins("*")
     * is required when setAllowCredentials(true) is set.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of(
                "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);  // cache preflight for 1 hour

        UrlBasedCorsConfigurationSource source =
                new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
