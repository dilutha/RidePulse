package com.ridepulse.dto;


import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;





@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthorityStaffDTO {
    private Integer staffId;
    private String  fullName;
    private String  email;
    private String  phone;
    private String  employeeId;
    private String  staffType;        // driver | conductor
    private String  licenseNumber;    // driver only
    private String  assignedBusNumber;
    private String  ownerName;
    private String  ownerBusinessName;
    private Boolean isActive;
    private String  dateOfJoining;
}