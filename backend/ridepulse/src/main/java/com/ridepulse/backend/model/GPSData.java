package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * GPSData Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates GPS tracking data for buses
 * All fields are private with getters/setters
 *
 * ABSTRACTION (OOP Concept):
 * Represents GPS data as a high-level entity
 * Hides complex GPS calculation details
 */
@Entity
@Table(name = "gps_data", indexes = {
        @Index(name = "idx_bus_timestamp", columnList = "bus_id, timestamp"),
        @Index(name = "idx_timestamp", columnList = "timestamp")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GPSData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "gps_id")
    private Long gpsId;

    @Column(name = "bus_id", nullable = false)
    private Long busId;

    @Column(nullable = false, precision = 10, scale = 7)
    private Double latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private Double longitude;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Column(precision = 5, scale = 2)
    private Double speed; // km/h

    @Column(precision = 5, scale = 2)
    private Double heading; // degrees (0-360)

    @Column(precision = 6, scale = 2)
    private Double accuracy; // meters

    @Column(name = "crowd_level")
    private Integer crowdLevel; // percentage (0-100)

    @Column(name = "is_deviation")
    private Boolean isDeviation = false;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (timestamp == null) {
            timestamp = LocalDateTime.now();
        }
    }

    /**
     * ENCAPSULATION - Business Logic Method
     * Calculate distance to another GPS point using Haversine formula
     */
    public double calculateDistanceTo(Double targetLat, Double targetLng) {
        final int EARTH_RADIUS = 6371; // Radius in kilometers

        double latDistance = Math.toRadians(targetLat - this.latitude);
        double lngDistance = Math.toRadians(targetLng - this.longitude);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(this.latitude))
                * Math.cos(Math.toRadians(targetLat))
                * Math.sin(lngDistance / 2) * Math.sin(lngDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS * c; // Distance in kilometers
    }

    /**
     * ENCAPSULATION - Business Logic Method
     * Validate GPS coordinates
     */
    public boolean isValidCoordinates() {
        return latitude != null && longitude != null
                && latitude >= -90 && latitude <= 90
                && longitude >= -180 && longitude <= 180;
    }

    /**
     * ENCAPSULATION - Business Logic Method
     * Calculate speed from previous GPS point
     */
    public Double calculateSpeed(GPSData previousPoint) {
        if (previousPoint == null) {
            return 0.0;
        }

        double distance = calculateDistanceTo(
                previousPoint.getLatitude(),
                previousPoint.getLongitude()
        );

        long timeDiffSeconds = java.time.Duration.between(
                previousPoint.getTimestamp(),
                this.timestamp
        ).getSeconds();

        if (timeDiffSeconds == 0) {
            return 0.0;
        }

        // Convert to km/h
        double speedKmh = (distance / timeDiffSeconds) * 3600;

        return Math.round(speedKmh * 100.0) / 100.0;
    }
}