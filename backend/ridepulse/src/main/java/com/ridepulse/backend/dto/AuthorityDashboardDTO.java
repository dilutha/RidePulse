package com.ridepulse.dto;



import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;


@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthorityDashboardDTO {
    // Complaints (already fetched via complaintService)
    private Integer totalComplaints;
    private Integer openComplaints;
    private Integer resolvedComplaints;

    // Fleet
    private Integer totalBuses;
    private Integer activeBuses;
    private Integer busesOnTrip;

    // Staff
    private Integer totalDrivers;
    private Integer totalConductors;

    // Owners
    private Integer totalBusOwners;

    // Routes
    private Integer totalRoutes;
}

