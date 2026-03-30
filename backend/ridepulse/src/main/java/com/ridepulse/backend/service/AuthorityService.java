package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.*;
import java.util.List;

public interface AuthorityService {

    /** System-wide dashboard stats */
    AuthorityDashboardDTO getDashboard();

    /** All buses across all owners with live GPS + crowd */
    List<AuthorityBusDTO> getAllBuses();

    /** All drivers */
    List<AuthorityStaffDTO> getAllDrivers();

    /** All conductors */
    List<AuthorityStaffDTO> getAllConductors();

    /** All bus owners with fleet summary */
    List<AuthorityOwnerDTO> getAllOwners();

    /** Fare config for all active routes */
    List<FareConfigDTO> getAllFareConfigs();

    /** Fare config for a single route */
    FareConfigDTO getFareConfig(Integer routeId);

    /** Update base fare for a route (authority only) */
    FareConfigDTO updateFare(UpdateFareRequest request);
}


// ============================================================
// AuthorityServiceImpl.java
// OOP Encapsulation: all data aggregation logic hidden here.
//     Polymorphism: fare calculation rules applied uniformly.
// ============================================================
