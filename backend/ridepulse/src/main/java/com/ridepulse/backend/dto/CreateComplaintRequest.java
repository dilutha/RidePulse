package com.ridepulse.backend.dto;

import com.ridepulse.backend.model.ComplaintCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

/**
 * Request DTO for creating complaint
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateComplaintRequest {

    @NotNull(message = "Passenger ID is required")
    private UUID passengerId;

    private Integer busId;

    private UUID staffId;

    @NotNull(message = "Category is required")
    private ComplaintCategory category;

    @NotBlank(message = "Description is required")
    @Size(min = 10, max = 1000, message = "Description must be between 10 and 1000 characters")
    private String description;

    private String photoUrl;
}