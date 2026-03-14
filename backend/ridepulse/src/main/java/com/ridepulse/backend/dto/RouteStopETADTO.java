package com.ridepulse.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Route Stop with ETA DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RouteStopETADTO {

    private Long stopId;
    private String stopName;
    private Integer stopSequence;
    private Double latitude;
    private Double longitude;

    private Double distanceFromBusKm;
    private Integer estimatedArrivalMinutes;
    private String estimatedArrivalTime; // HH:mm format

    private Boolean isPassed; // Whether bus has passed this stop
}