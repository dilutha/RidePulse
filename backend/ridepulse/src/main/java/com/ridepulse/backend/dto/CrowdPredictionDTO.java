package com.ridepulse.backend.dto;


import lombok.*;
import java.util.List;



// ── CrowdPredictionDTO ───────────────────────────────────────
// LSTM prediction for a route at a given date/time slot
// OOP Abstraction: hides model internals — passenger sees simple result
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CrowdPredictionDTO {
    private Integer routeId;
    private String  routeName;
    private String  predictionDate;
    private String  timeSlot;             // e.g. "08:00"
    private Double  predictedCount;
    private Double  predictedPercentage;
    private String  predictedCategory;    // low | medium | high
    private Double  confidenceScore;      // 0.0 – 1.0
    private String  modelVersion;
    private Boolean isAvailable;          // false = no prediction yet (LSTM not trained)
    private String  message;              // shown when isAvailable=false
}
