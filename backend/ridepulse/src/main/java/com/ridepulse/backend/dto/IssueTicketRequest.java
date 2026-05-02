package com.ridepulse.backend.dto;

// ============================================================
// CONDUCTOR MODULE — ALL DTOs
// OOP Encapsulation: each DTO exposes only what the conductor
//     app needs, hiding internal entity relationships.
// ============================================================

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;


// ── IssueTicketRequest ───────────────────────────────────────
// Sent by conductor when issuing a ticket to a passenger
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class IssueTicketRequest {

    @NotNull(message = "Trip ID is required")
    private Integer tripId;

    @NotNull(message = "Route ID is required")
    private Integer routeId;

    // Boarding stop — conductor selects from route stop list
    @NotNull(message = "Boarding stop is required")
    private Integer boardingStopId;

    // Alighting stop — passenger tells conductor
    @NotNull(message = "Alighting stop is required")
    private Integer alightingStopId;

    // Payment method — cash default
    @Pattern(regexp = "cash|digital", message = "Payment method must be cash or digital")
    private String paymentMethod = "cash";

    @Min(value = 1, message = "Ticket count must be at least 1")
    @Max(value = 50, message = "Ticket count is too high for one issue action")
    private Integer ticketCount = 1;

    // Optional: link ticket to registered passenger
    private String passengerUserId;  // UUID string, null for walk-in passengers
}
