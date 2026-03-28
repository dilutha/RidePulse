package com.ridepulse.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UpdateRosterRequest {
    private String dutyDate;
    private String shiftStart;
    private String shiftEnd;
    @Pattern(regexp = "scheduled|active|completed|cancelled")
    private String status;
}
