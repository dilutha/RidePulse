package com.ridepulse.backend.service;

import com.ridepulse.backend.model.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * UserService Interface
 *
 * Handles user management operations.
 * Authentication is handled separately in AuthService.
 */
public interface UserService {

    User createUser(User user);

    Optional<User> getUserById(UUID userId);

    Optional<User> getUserByEmail(String email);

    List<User> getAllUsers();

    User updateUser(UUID userId, User user);

    void deleteUser(UUID userId);
}