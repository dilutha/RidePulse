package com.ridepulse.dto;


import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;






@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthorityBusDTO {
    private Integer busId;
    private String  busNumber;
    private String  registrationNumber;
    private String  ownerName;
    private String  ownerBusinessName;
    private String  routeNumber;
    private String  routeName;
    private Integer capacity;
    private String  model;
    private Boolean isActive;
    private Boolean hasGps;

    // Live status
    private Boolean isOnTrip;
    private Double  latitude;
    private Double  longitude;
    private Double  speedKmh;
    private String  lastGpsUpdate;
    private String  crowdCategory;   // low | medium | high | unknown
    private Integer passengerCount;
}