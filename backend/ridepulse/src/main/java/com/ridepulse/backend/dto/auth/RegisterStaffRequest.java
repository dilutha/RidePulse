package com.ridepulse.backend.dto.auth;

// ============================================================
// RegisterStaffRequest.java — FIXED VERSION
//
// Fix: dateOfJoining changed from @NotNull to @Nullable (optional).
// Flutter never sends this field — Spring's @Valid was returning 400
// which the error filter was surfacing as 403.
//
// The backend now defaults to LocalDate.now() when omitted
// (already handled in AuthServiceImpl.registerStaff()).
// ============================================================

import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
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

    // FIX: was @NotNull — now optional.
    // Flutter does not send this field.
    // AuthServiceImpl defaults to LocalDate.now() when null.
    private LocalDate dateOfJoining;        // nullable — defaults to today

    // Driver-only fields (null for conductor)
    private String    licenseNumber;
    private LocalDate licenseExpiry;

    private BigDecimal baseSalary;

    // Optional: assign to bus immediately at registration
    private Integer busId;
}
