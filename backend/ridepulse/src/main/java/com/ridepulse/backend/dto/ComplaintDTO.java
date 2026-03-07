package com.ridepulse.backend.dto;

import com.ridepulse.backend.model.ComplaintCategory;
import com.ridepulse.backend.model.ComplaintPriority;
import com.ridepulse.backend.model.ComplaintStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Complaint DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ComplaintDTO {

    private Integer complaintId;
    private String complaintNumber;
    private UUID passengerId;
    private String passengerName;
    private String passengerEmail;
    private Integer busId;
    private String busNumber;
    private UUID staffId;
    private String staffName;
    private ComplaintCategory category;
    private String categoryDescription;
    private String description;
    private String photoUrl;
    private ComplaintPriority priority;
    private ComplaintStatus status;
    private UUID assignedToId;
    private String assignedToName;
    private String resolutionNotes;
    private LocalDateTime submittedAt;
    private LocalDateTime resolvedAt;
}