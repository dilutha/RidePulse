package com.ridepulse.backend.dto;

import com.ridepulse.backend.model.ComplaintPriority;
import com.ridepulse.backend.model.ComplaintStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

/**
 * Request DTO for updating complaint
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateComplaintRequest {

    private ComplaintStatus status;
    private ComplaintPriority priority;
    private UUID assignedTo;
    private String resolutionNotes;
}