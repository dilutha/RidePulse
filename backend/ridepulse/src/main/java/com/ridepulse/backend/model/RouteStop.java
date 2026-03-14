package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;

/**
 * RouteStop Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates bus stop information for a route
 */
@Entity
@Table(name = "route_stops", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"route_id", "stop_sequence"})
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteStop {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "stop_id")
    private Long stopId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id", nullable = false)
    private Route route;

    @Column(name = "stop_name", nullable = false)
    private String stopName;

    @Column(name = "stop_sequence", nullable = false)
    private Integer stopSequence;

    @Column(nullable = false, precision = 10, scale = 7)
    private Double latitude;

    @Column(nullable = false, precision = 10, scale = 7)
    private Double longitude;

    @Column(name = "distance_from_start_km", precision = 6, scale = 2)
    private BigDecimal distanceFromStartKm;

    /**
     * ENCAPSULATION - Business Logic Method
     * Calculate distance to GPS point
     */
    public double calculateDistanceTo(Double lat, Double lng) {
        final int EARTH_RADIUS = 6371; // km

        double latDistance = Math.toRadians(lat - this.latitude);
        double lngDistance = Math.toRadians(lng - this.longitude);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(this.latitude))
                * Math.cos(Math.toRadians(lat))
                * Math.sin(lngDistance / 2) * Math.sin(lngDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return EARTH_RADIUS * c;
    }
}