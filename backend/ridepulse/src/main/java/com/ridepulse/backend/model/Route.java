package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Route Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates route information
 */
@Entity
@Table(name = "routes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Route {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "route_id")
    private Long routeId;

    @Column(name = "route_number", unique = true, nullable = false)
    private String routeNumber;

    @Column(name = "route_name", nullable = false)
    private String routeName;

    @Column(name = "start_location", nullable = false)
    private String startLocation;

    @Column(name = "end_location", nullable = false)
    private String endLocation;

    @Column(name = "total_distance_km", precision = 6, scale = 2)
    private BigDecimal totalDistanceKm;

    @Column(name = "estimated_duration_minutes")
    private Integer estimatedDurationMinutes;

    @Column(name = "base_fare", precision = 8, scale = 2, nullable = false)
    private BigDecimal baseFare;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // One-to-many relationship with RouteStop
    @OneToMany(mappedBy = "route", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<RouteStop> stops;

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
     * Calculate ETA in minutes based on distance and average speed
     */
    public Integer calculateETA(Double distanceKm, Double averageSpeedKmh) {
        if (distanceKm == null || averageSpeedKmh == null || averageSpeedKmh == 0) {
            return null;
        }

        double timeHours = distanceKm / averageSpeedKmh;
        return (int) Math.ceil(timeHours * 60); // Convert to minutes
    }
}