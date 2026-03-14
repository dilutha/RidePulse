package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.AuthResponse;
import com.ridepulse.backend.dto.LoginRequest;
import com.ridepulse.backend.dto.RegisterRequest;

/**
 * ABSTRACTION:
 * Interface defining authentication operations
 */
public interface AuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    void logout(String token);

}

