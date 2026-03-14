package com.ridepulse.backend.security;

import com.ridepulse.backend.config.JwtProperties;
import com.ridepulse.backend.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * JWT Authentication Filter
 *
 * This filter intercepts every request and checks for a valid JWT token.
 * If a valid token is found, it authenticates the user and sets the
 * authentication in Spring Security's SecurityContext.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final JwtProperties jwtProperties;
    private final CustomUserDetailsService userDetailsService;

    /**
     * Runs once per request.
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // Read Authorization header
        final String authHeader = request.getHeader(jwtProperties.getHeaderString());

        String jwt = null;
        String username = null;

        // If no Authorization header → skip filter
        if (authHeader == null || !authHeader.startsWith(jwtProperties.getTokenPrefix())) {
            filterChain.doFilter(request, response);
            return;
        }

        try {

            // Extract token from header
            jwt = authHeader.substring(jwtProperties.getTokenPrefix().length());

            // Extract username (email)
            username = jwtUtil.extractUsername(jwt);

        } catch (Exception e) {

            // Token parsing failed (expired, malformed, etc.)
            logger.warn("Invalid JWT token: " + e.getMessage());
        }

        // Authenticate user if token is valid and not already authenticated
        if (username != null &&
                SecurityContextHolder.getContext().getAuthentication() == null) {

            UserDetails userDetails =
                    userDetailsService.loadUserByUsername(username);

            if (jwtUtil.validateToken(jwt, userDetails.getUsername())) {

                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                authToken.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                SecurityContextHolder.getContext().setAuthentication(authToken);

                logger.debug("JWT authentication successful for user: " + username);
            }
        }

        // Continue filter chain
        filterChain.doFilter(request, response);
    }
}