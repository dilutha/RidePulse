package com.ridepulse.backend.controller;

import com.ridepulse.backend.model.User;
import com.ridepulse.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * UserController
 * Handles user CRUD operations.
 * Authentication is handled in AuthController.
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;

    /**
     * CREATE - Register new user
     */
    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {

        User createdUser = userService.createUser(user);

        return new ResponseEntity<>(createdUser, HttpStatus.CREATED);
    }

    /**
     * READ - Get user by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable UUID id) {

        return userService.getUserById(id)
                .map(user -> ResponseEntity.ok(user))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * READ - Get all users
     */
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {

        return ResponseEntity.ok(userService.getAllUsers());
    }

    /**
     * UPDATE - Update user
     */
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(
            @PathVariable UUID id,
            @RequestBody User user
    ) {

        User updatedUser = userService.updateUser(id, user);

        return ResponseEntity.ok(updatedUser);
    }

    /**
     * DELETE - Delete user
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable UUID id) {

        userService.deleteUser(id);

        return ResponseEntity.noContent().build();
    }
}