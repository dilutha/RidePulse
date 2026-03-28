package com.ridepulse.backend.dto;

import jakarta.validation.constraints.*;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class RosterDetailDTO {
    private Integer rosterId;
    private String  dutyDate;
    private String  shiftStart;
    private String  shiftEnd;
    private String  status;          // scheduled | active | completed | cancelled

    // Assigned bus info
    private Integer busId;
    private String  busNumber;
    private String  registrationNumber;
    private Integer busCapacity;

    // Assigned route info
    private Integer routeId;
    private String  routeNumber;
    private String  routeName;
    private String  startLocation;
    private String  endLocation;
    private Double  baseFare;

    private String  staffName;
    private String  staffType;
    private String  employeeId;
    private Integer staffId;

    // Active trip (null if no trip started yet)
    private Integer activeTripId;
    private String  tripStatus;// in_progress | completed | null
}
