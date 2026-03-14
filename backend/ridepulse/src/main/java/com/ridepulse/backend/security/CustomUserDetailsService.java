package com.ridepulse.backend.security;

import com.ridepulse.backend.model.User;
import com.ridepulse.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

/**
 * CustomUserDetailsService
 *
 * Responsible for loading user data from the database
 * and converting it into Spring Security's UserDetails object.
 *
 * This class is used by Spring Security during authentication.
 */
@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    /**
     * Loads user from database by email (used as username).
     *
     * @param email user's login email
     * @return UserDetails object used by Spring Security
     * @throws UsernameNotFoundException if user does not exist
     */
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() ->
                        new UsernameNotFoundException(
                                "User not found with email: " + email
                        )
                );

        // Convert database User entity → Spring Security UserDetails
        return new CustomUserDetails(user);
    }
}