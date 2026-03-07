package com.ridepulse.backend.dto;

import com.ridepulse.backend.model.StaffType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Request DTO for creating welfare record
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateWelfareRecordRequest {

    @NotNull(message = "Bus ID is required")
    private Integer busId;

    @NotNull(message = "Staff ID is required")
    private UUID staffId;

    @NotNull(message = "Record date is required")
    private LocalDate recordDate;

    @NotNull(message = "Daily revenue is required")
    @Positive(message = "Daily revenue must be positive")
    private BigDecimal dailyRevenue;

    @Positive(message = "Fuel cost must be positive")
    private BigDecimal fuelCost;

    @Positive(message = "Maintenance cost must be positive")
    private BigDecimal maintenanceCost;

    @Positive(message = "Wages must be positive")
    private BigDecimal wages;

    @NotNull(message = "Staff type is required")
    private StaffType staffType;
}