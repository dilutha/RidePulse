package com.ridepulse.backend.dto.auth;

// ============================================================
// RegisterStaffRequest.java — UPDATED
// ADD: ownerId field so public registration links staff to owner
// ============================================================

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class RegisterStaffRequest {

    @NotBlank
    private String fullName;

    @Email @NotBlank
    private String email;

    @NotBlank
    private String phone;

    @NotBlank @Size(min = 8)
    private String password;

    @NotBlank
    @Pattern(regexp = "driver|conductor",
            message = "staffType must be 'driver' or 'conductor'")
    private String staffType;

    @NotBlank
    private String employeeId;

    // FIX: was @NotNull — changed to nullable with default in service
    private LocalDate dateOfJoining;

    private String    licenseNumber;   // Required only for driver
    private LocalDate licenseExpiry;   // Required only for driver
    private BigDecimal baseSalary;
    private Integer   busId;           // Optional: assign to bus immediately

    // NEW FIELD: Bus owner's ID — used when endpoint is called publicly
    // (without a bus_owner JWT token). The Flutter app sends this explicitly.
    private Integer ownerId;
}
