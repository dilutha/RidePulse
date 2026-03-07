package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

/**
 * Staff Entity
 *
 * INHERITANCE (OOP Concept):
 * Staff extends User
 */
@Entity
@Table(name = "staff")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@DiscriminatorValue("STAFF")
public class Staff extends User {

    @Column(name = "employee_id", unique = true, nullable = false)
    private String employeeId;

    @Column(name = "staff_type", nullable = false)
    @Enumerated(EnumType.STRING)
    private StaffType staffType;

    @Column(name = "date_of_joining")
    private LocalDate dateOfJoining;

    @Column(name = "license_number")
    private String licenseNumber;

    @Column(name = "license_expiry")
    private LocalDate licenseExpiry;

    @Column(name = "is_active")
    private Boolean isActive = true;
}