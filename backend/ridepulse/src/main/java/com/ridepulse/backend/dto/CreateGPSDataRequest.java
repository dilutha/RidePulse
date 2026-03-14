package com.ridepulse.backend.dto;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Create GPS Data Request DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateGPSDataRequest {

    @NotNull(message = "Bus ID is required")
    private Long busId;

    @NotNull(message = "Latitude is required")
    @DecimalMin(value = "-90.0", message = "Latitude must be >= -90")
    @DecimalMax(value = "90.0", message = "Latitude must be <= 90")
    private Double latitude;

    @NotNull(message = "Longitude is required")
    @DecimalMin(value = "-180.0", message = "Longitude must be >= -180")
    @DecimalMax(value = "180.0", message = "Longitude must be <= 180")
    private Double longitude;

    private LocalDateTime timestamp;

    @DecimalMin(value = "0.0", message = "Speed must be >= 0")
    @DecimalMax(value = "200.0", message = "Speed must be <= 200 km/h")
    private Double speed;

    @DecimalMin(value = "0.0", message = "Heading must be >= 0")
    @DecimalMax(value = "360.0", message = "Heading must be <= 360")
    private Double heading;

    @DecimalMin(value = "0.0", message = "Accuracy must be >= 0")
    private Double accuracy;

    @Min(value = 0, message = "Crowd level must be >= 0")
    @Max(value = 100, message = "Crowd level must be <= 100")
    private Integer crowdLevel;
}