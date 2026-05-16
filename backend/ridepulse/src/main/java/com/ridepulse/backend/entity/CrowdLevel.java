package com.ridepulse.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "crowd_levels")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CrowdLevel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "crowd_id")
    private Long crowdId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bus_id", nullable = false)
    private Bus bus;

    // Optional: null if recorded outside a formal trip
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id")
    private BusTrip trip;

    @Column(name = "passenger_count", nullable = false)
    private Integer passengerCount;

    // Stored separately — needed for dashboard card
    @Column(name = "bus_capacity", nullable = false)
    private Integer busCapacity;

    // Derived: (passengerCount / busCapacity) * 100 — stored for fast reads
    @Column(name = "capacity_percentage", nullable = false, precision = 5, scale = 2)
    private BigDecimal capacityPercentage;

    // Polymorphism: category drives color coding in Flutter UI
    @Column(name = "crowd_category", nullable = false, length = 10)
    private String crowdCategory;  // low | medium | high

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt = LocalDateTime.now();

    /**
     * OOP Encapsulation: category derivation logic lives in the entity,
     * not scattered across services.
     * Call this before saving to auto-set crowdCategory.
     */
    @PrePersist
    @PreUpdate
    public void deriveCategory() {
        if (busCapacity > 0) {
            double pct = (double) passengerCount / busCapacity * 100;
            this.capacityPercentage = BigDecimal.valueOf(pct)
                    .setScale(2, java.math.RoundingMode.HALF_UP);
            this.crowdCategory = pct >= 100 ? "full"
                    : pct <= 30 ? "low"
                    : pct <= 70 ? "medium"
                    : "high";
        }
    }
}
