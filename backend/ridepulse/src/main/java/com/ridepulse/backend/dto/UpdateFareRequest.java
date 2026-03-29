package com.ridepulse.dto;


import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;


@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateFareRequest {
    @NotNull(message = "Route ID is required")
    private Integer routeId;

    @NotNull @DecimalMin("30.00") @DecimalMax("2422.00")
    private java.math.BigDecimal baseFare;
}