package com.ridepulse.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * JWT Configuration Properties
 *
 * This class binds values from application.properties or application.yml
 * using the prefix "jwt".
 *
 * Example configuration:
 *
 * jwt.secret=your-secret-key
 * jwt.expiration=86400000
 * jwt.token-prefix=Bearer
 * jwt.header-string=Authorization
 */
@Configuration
@ConfigurationProperties(prefix = "jwt")
@Getter
@Setter
public class JwtProperties {

    /**
     * Secret key used to sign JWT tokens.
     * Should be long and random.
     */
    private String secret;

    /**
     * Token expiration time in milliseconds.
     * Example: 86400000 = 24 hours
     */
    private long expiration;

    /**
     * Token prefix used in Authorization header.
     * Example: "Bearer "
     */
    private String tokenPrefix;

    /**
     * Header used to carry the JWT token.
     */
    private String headerString;
}