package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.AuthResponse;
import com.ridepulse.backend.dto.LoginRequest;
import com.ridepulse.backend.dto.RegisterRequest;
import com.ridepulse.backend.model.User;
import com.ridepulse.backend.model.UserRole;
import com.ridepulse.backend.repository.UserRepository;
import com.ridepulse.backend.service.AuthService;
import com.ridepulse.backend.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Authentication service implementation.
 * Handles user registration, login, and token generation.
 */

@Service
@RequiredArgsConstructor
@Transactional
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    /**
     * Register a new user
     */
    @Override
    public AuthResponse register(RegisterRequest request) {

        // Check if email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        // Create new user entity
        User user = new User();
        user.setFullName(request.getFullName());
        user.setEmail(request.getEmail());
        user.setPhone(request.getPhone());

        // Encrypt password using BCrypt
        String hashedPassword = passwordEncoder.encode(request.getPassword());
        user.setPasswordHash(hashedPassword);

        // Convert role string to enum
        try {
            user.setRole(UserRole.valueOf(request.getRole().toUpperCase()));
        } catch (IllegalArgumentException e) {
            throw new RuntimeException("Invalid role: " + request.getRole());
        }

        user.setIsActive(true);

        // Save user in database
        User savedUser = userRepository.save(user);

        // Generate JWT token
        String token = jwtUtil.generateToken(
                savedUser.getEmail(),
                savedUser.getRole().name()
        );

        // Return response
        return new AuthResponse(
                savedUser.getUserId(),
                savedUser.getEmail(),
                savedUser.getFullName(),
                savedUser.getRole().name(),
                token
        );
    }

    /**
     * Login user
     */
    @Override
    public AuthResponse login(LoginRequest request) {

        try {

            // Authenticate user with Spring Security
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getEmail(),
                            request.getPassword()
                    )
            );

            // Fetch user from database
            User user = userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Check if account is active
            if (!Boolean.TRUE.equals(user.getIsActive())) {
                throw new RuntimeException("Account is inactive");
            }

            // Generate JWT token
            String token = jwtUtil.generateToken(
                    user.getEmail(),
                    user.getRole().name()
            );

            // Return authentication response
            return new AuthResponse(
                    user.getUserId(),
                    user.getEmail(),
                    user.getFullName(),
                    user.getRole().name(),
                    token
            );

        } catch (Exception e) {

            // Print real error in console for debugging
            e.printStackTrace();

            throw new RuntimeException("Invalid email or password");
        }
    }

    /**
     * Logout user
     * For JWT, logout is usually handled client-side
     */
    @Override
    public void logout(String token) {
        System.out.println("User logged out");
    }
}