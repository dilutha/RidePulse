package com.ridepulse.backend.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * GPS Data DTO
 *
 * DATA TRANSFER OBJECT (OOP Pattern):
 * Transfers GPS data between layers
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GPSDataDTO {

    private Long gpsId;
    private Long busId;
    private String busNumber;
    private Double latitude;
    private Double longitude;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime timestamp;

    private Double speed;
    private Double heading;
    private Double accuracy;
    private Integer crowdLevel;
    private Boolean isDeviation;

    // Additional computed fields
    private String status; // "active", "inactive", "delayed"
    private Integer eta; // Estimated time to next stop (minutes)
}