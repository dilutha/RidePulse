package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.model.User;
import com.ridepulse.backend.repository.UserRepository;
import com.ridepulse.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * UserService Implementation
 *
 * Handles user management business logic.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    /**
     * Create user with BCrypt encrypted password.
     */
    @Override
    public User createUser(User user) {

        if (userRepository.existsByEmail(user.getEmail())) {
            throw new RuntimeException("Email already exists");
        }

        // Encrypt password before saving
        String encryptedPassword = passwordEncoder.encode(user.getPasswordHash());
        user.setPasswordHash(encryptedPassword);

        user.setIsActive(true);

        return userRepository.save(user);
    }

    @Override
    public Optional<User> getUserById(UUID userId) {

        return userRepository.findById(userId);
    }

    @Override
    public Optional<User> getUserByEmail(String email) {

        return userRepository.findByEmail(email);
    }

    @Override
    public List<User> getAllUsers() {

        return userRepository.findAll();
    }

    /**
     * Update user details.
     */
    @Override
    public User updateUser(UUID userId, User updatedUser) {

        return userRepository.findById(userId)
                .map(existingUser -> {

                    existingUser.setFullName(updatedUser.getFullName());
                    existingUser.setPhone(updatedUser.getPhone());

                    // Update password if provided
                    if (updatedUser.getPasswordHash() != null &&
                            !updatedUser.getPasswordHash().isEmpty()) {

                        String encryptedPassword =
                                passwordEncoder.encode(updatedUser.getPasswordHash());

                        existingUser.setPasswordHash(encryptedPassword);
                    }

                    return userRepository.save(existingUser);

                })
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @Override
    public void deleteUser(UUID userId) {

        if (!userRepository.existsById(userId)) {
            throw new RuntimeException("User not found");
        }

        userRepository.deleteById(userId);
    }
}