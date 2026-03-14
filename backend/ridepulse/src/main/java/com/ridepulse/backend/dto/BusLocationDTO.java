package com.ridepulse.backend.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Bus Location DTO
 *
 * Simplified DTO for displaying bus locations on map
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BusLocationDTO {

    private Long busId;
    private String busNumber;
    private Long routeId;
    private String routeNumber;
    private String routeName;

    private Double latitude;
    private Double longitude;
    private Double speed;
    private Double heading;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime lastUpdate;

    private Integer crowdLevel;
    private String status; // "moving", "stopped", "offline"
    private Boolean hasRecentData;
}