package com.ridepulse.backend.entity;

// ============================================================
// Staff.java — UPDATED
// Added busOwner field so staff are directly linked to owner.
// OOP Aggregation: Staff belongs to BusOwner directly,
//     independent of bus assignment.
// ============================================================

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "staff")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Staff {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "staff_id")
    private Integer staffId;

    // Inheritance via composition: Staff extends User identity
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", unique = true)
    private User user;

    // NEW: Direct link to bus owner — set at registration time.
    // OOP Aggregation: staff belongs to one owner.
    // This replaces the fragile assignment-based ownership lookup.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id")
    private BusOwner busOwner;

    // Polymorphism: DRIVER and CONDUCTOR are two behaviours of the same entity
    @Enumerated(EnumType.STRING)
    @Column(name = "staff_type", nullable = false, length = 20)
    private StaffType staffType;

    @Column(name = "employee_id", unique = true, nullable = false, length = 50)
    private String employeeId;

    @Column(name = "license_number", length = 50)
    private String licenseNumber;

    @Column(name = "license_expiry")
    private LocalDate licenseExpiry;

    @Column(name = "date_of_joining", nullable = false)
    private LocalDate dateOfJoining;

    @Column(name = "base_salary", precision = 10, scale = 2)
    private BigDecimal baseSalary = BigDecimal.ZERO;

    @Column(name = "is_active")
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    // Polymorphism: each type knows its own welfare rate
    public enum StaffType {
        driver, conductor;

        public BigDecimal getWelfareRate() {
            return switch (this) {
                case driver    -> new BigDecimal("0.03"); // 3%
                case conductor -> new BigDecimal("0.02"); // 2%
            };
        }
    }
}
