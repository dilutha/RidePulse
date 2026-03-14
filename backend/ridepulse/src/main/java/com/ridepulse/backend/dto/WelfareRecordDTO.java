package com.ridepulse.backend.dto;

import com.ridepulse.backend.model.StaffType;
import com.ridepulse.backend.model.WelfareStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * WelfareRecord DTO
 *
 * ENCAPSULATION (OOP Concept):
 * Separates internal model from external API
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WelfareRecordDTO {

    private Integer recordId;
    private Integer busId;
    private String busNumber;
    private UUID staffId;
    private String staffName;
    private String employeeId;
    private LocalDate recordDate;
    private BigDecimal dailyRevenue;
    private BigDecimal fuelCost;
    private BigDecimal maintenanceCost;
    private BigDecimal wages;
    private BigDecimal totalExpenses;
    private BigDecimal dailyProfit;
    private BigDecimal welfarePercentage;
    private BigDecimal welfareAmount;
    private StaffType staffType;
    private WelfareStatus status;
}