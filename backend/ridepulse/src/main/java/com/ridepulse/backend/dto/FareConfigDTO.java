package com.ridepulse.dto;


import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;




@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class FareConfigDTO {
    private Integer routeId;
    private String  routeNumber;
    private String  routeName;
    private String  startLocation;
    private String  endLocation;
    private Integer totalStops;
    private Double  minimumFare;         // LKR 30 (national minimum)
    private Double  farePerStop;         // LKR 8 per stop increment
    private Double  maximumFare;         // LKR 2422 (national maximum)
    private Double  currentBaseFare;     // stored in Route.baseFare
    private String  updatedAt;
    // Computed sample fares for preview
    private List<StopFarePreview> farePreview;
}

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public static class StopFarePreview {
    private Integer stopCount;
    private Double  fare;
}
