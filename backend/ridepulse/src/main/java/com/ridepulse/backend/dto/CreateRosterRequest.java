package com.ridepulse.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

// ── CreateRosterRequest ──────────────────────────────────────
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateRosterRequest {
    @NotNull  private Integer staffId;
    @NotNull  private Integer busId;
    @NotBlank private String  dutyDate;    // "YYYY-MM-DD"
    @NotBlank private String  shiftStart;  // "HH:MM"
    @NotBlank private String  shiftEnd;    // "HH:MM"
}