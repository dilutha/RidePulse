package com.ridepulse.backend.dto;

import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor @Builder

public class StopFarePreview {
        private Integer stopCount;
        private Double  fare;
}
