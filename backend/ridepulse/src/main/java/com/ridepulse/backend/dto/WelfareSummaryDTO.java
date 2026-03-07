package com.ridepulse.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Welfare Summary DTO
 * Shows total welfare accumulated
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WelfareSummaryDTO {

    private UUID staffId;
    private String staffName;
    private String employeeId;
    private BigDecimal totalWelfareAmount;
    private BigDecimal pendingWelfareAmount;
    private BigDecimal approvedWelfareAmount;
    private BigDecimal paidWelfareAmount;
    private Integer totalRecords;
}