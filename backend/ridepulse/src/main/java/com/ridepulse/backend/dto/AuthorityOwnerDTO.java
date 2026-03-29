package com.ridepulse.dto;


import lombok.*;
import jakarta.validation.constraints.*;
import java.util.List;



@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class AuthorityOwnerDTO {
    private Integer ownerId;
    private String  fullName;
    private String  email;
    private String  phone;
    private String  businessName;
    private String  nicNumber;
    private String  address;
    private Integer totalBuses;
    private Integer activeBuses;
    private Integer totalStaff;
    private String  registeredAt;
}