package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Bus Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates bus information
 */
@Entity
@Table(name = "buses")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Bus {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "bus_id")
    private Long busId;

    @Column(name = "bus_number", nullable = false, unique = true)
    private String busNumber;

    @Column(name = "owner_id")
    private Long ownerId;

    @Column(name = "route_id")
    private Long routeId;

    @Column(nullable = false)
    private Integer capacity;

    @Column(name = "registration_number", unique = true)
    private String registrationNumber;

    @Column
    private String model;

    @Column(name = "year_manufactured")
    private Integer yearManufactured;

    @Column(name = "has_gps_device")
    private Boolean hasGpsDevice = true;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "current_latitude", precision = 10, scale = 7)
    private Double currentLatitude;

    @Column(name = "current_longitude", precision = 10, scale = 7)
    private Double currentLongitude;

    @Column(name = "last_update")
    private LocalDateTime lastUpdate;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    /**
     * ENCAPSULATION - Business Logic Method
     * Update current location
     */
    public void updateLocation(Double latitude, Double longitude) {
        this.currentLatitude = latitude;
        this.currentLongitude = longitude;
        this.lastUpdate = LocalDateTime.now();
    }

    /**
     * ENCAPSULATION - Business Logic Method
     * Check if GPS data is recent (within last 5 minutes)
     */
    public boolean hasRecentGPSData() {
        if (lastUpdate == null) {
            return false;
        }

        long minutesSinceUpdate = java.time.Duration.between(
                lastUpdate,
                LocalDateTime.now()
        ).toMinutes();

        return minutesSinceUpdate <= 5;
    }
}