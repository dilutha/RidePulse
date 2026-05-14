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

// ── StopDTO ──────────────────────────────────────────────────
// Route stop for boarding/alighting dropdown in issue ticket
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class StopDTO {
    private Integer stopId;
    private String  stopName;
    private Integer stopSequence;
    private Double  latitude;
    private Double  longitude;
}
