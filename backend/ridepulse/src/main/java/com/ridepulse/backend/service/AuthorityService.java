package com.ridepulse.service;

import com.ridepulse.dto.*;
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
package com.ridepulse.service.impl;

import com.ridepulse.dto.*;
import com.ridepulse.entity.*;
import com.ridepulse.repository.*;
import com.ridepulse.service.AuthorityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthorityServiceImpl implements AuthorityService {

    // Encapsulation: all dependencies private
    private final BusRepository         busRepo;
    private final BusOwnerRepository    ownerRepo;
    private final StaffRepository       staffRepo;
    private final RouteRepository       routeRepo;
    private final RouteStopRepository   stopRepo;
    private final GpsTrackingRepository gpsRepo;
    private final CrowdLevelRepository  crowdRepo;
    private final BusTripRepository     tripRepo;
    private final StaffBusAssignmentRepository assignmentRepo;
    private final ComplaintRepository   complaintRepo;

    // Sri Lanka NTPS fare rules (OOP Encapsulation: constants here)
    private static final BigDecimal MIN_FARE     = new BigDecimal("30.00");
    private static final BigDecimal MAX_FARE     = new BigDecimal("2422.00");
    private static final BigDecimal FARE_PER_STOP = new BigDecimal("8.00");

    private static final DateTimeFormatter DT =
        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // ── Dashboard ────────────────────────────────────────────

    @Override
    public AuthorityDashboardDTO getDashboard() {
        long totalBuses    = busRepo.count();
        long activeBuses   = busRepo.findByIsActiveTrue().size();
        long busesOnTrip   = tripRepo.countByStatus("in_progress");
        long totalDrivers  = staffRepo.countByStaffType(Staff.StaffType.driver);
        long totalCond     = staffRepo.countByStaffType(Staff.StaffType.conductor);
        long totalOwners   = ownerRepo.count();
        long totalRoutes   = routeRepo.count();
        long totalComp     = complaintRepo.count();
        long openComp      = complaintRepo.countByStatusIn(
            List.of("submitted", "under_review"));
        long resolvedComp  = complaintRepo.countByStatus("resolved");

        return AuthorityDashboardDTO.builder()
            .totalComplaints((int) totalComp)
            .openComplaints((int) openComp)
            .resolvedComplaints((int) resolvedComp)
            .totalBuses((int) totalBuses)
            .activeBuses((int) activeBuses)
            .busesOnTrip((int) busesOnTrip)
            .totalDrivers((int) totalDrivers)
            .totalConductors((int) totalCond)
            .totalBusOwners((int) totalOwners)
            .totalRoutes((int) totalRoutes)
            .build();
    }

    // ── Buses ─────────────────────────────────────────────────

    /**
     * Returns all buses with live GPS and crowd data.
     * OOP Abstraction: callers get one flat DTO per bus.
     */
    @Override
    public List<AuthorityBusDTO> getAllBuses() {
        return busRepo.findAll().stream()
            .map(this::toBusDTO)
            .collect(Collectors.toList());
    }

    // ── Staff ─────────────────────────────────────────────────

    @Override
    public List<AuthorityStaffDTO> getAllDrivers() {
        return staffRepo.findByStaffType(Staff.StaffType.driver)
            .stream().map(this::toStaffDTO).collect(Collectors.toList());
    }

    @Override
    public List<AuthorityStaffDTO> getAllConductors() {
        return staffRepo.findByStaffType(Staff.StaffType.conductor)
            .stream().map(this::toStaffDTO).collect(Collectors.toList());
    }

    // ── Owners ────────────────────────────────────────────────

    @Override
    public List<AuthorityOwnerDTO> getAllOwners() {
        return ownerRepo.findAll().stream()
            .map(this::toOwnerDTO)
            .collect(Collectors.toList());
    }

    // ── Fare Management ───────────────────────────────────────

    @Override
    public List<FareConfigDTO> getAllFareConfigs() {
        return routeRepo.findByIsActiveTrueOrderByRouteNumber()
            .stream().map(this::toFareConfigDTO).collect(Collectors.toList());
    }

    @Override
    public FareConfigDTO getFareConfig(Integer routeId) {
        Route route = routeRepo.findById(routeId)
            .orElseThrow(() -> new RuntimeException("Route not found: " + routeId));
        return toFareConfigDTO(route);
    }

    /**
     * Updates base fare for a route.
     * OOP Encapsulation: validation rules (min/max) enforced here.
     * The conductor's calculateFare() reads Route.baseFare at issue time.
     */
    @Override
    @Transactional
    public FareConfigDTO updateFare(UpdateFareRequest req) {
        Route route = routeRepo.findById(req.getRouteId())
            .orElseThrow(() -> new RuntimeException("Route not found"));

        BigDecimal fare = req.getBaseFare();

        // Enforce national fare bounds
        if (fare.compareTo(MIN_FARE) < 0)
            throw new RuntimeException(
                "Fare cannot be less than minimum LKR " + MIN_FARE);
        if (fare.compareTo(MAX_FARE) > 0)
            throw new RuntimeException(
                "Fare cannot exceed maximum LKR " + MAX_FARE);

        route.setBaseFare(fare);
        routeRepo.save(route);

        return toFareConfigDTO(route);
    }

    // ── Private helpers (Encapsulation) ──────────────────────

    private AuthorityBusDTO toBusDTO(Bus bus) {
        GpsTracking gps = gpsRepo.findLatestByBusId(bus.getBusId()).orElse(null);
        CrowdLevel crowd = crowdRepo.findLatestByBusId(bus.getBusId()).orElse(null);
        boolean onTrip = tripRepo.findByBus_BusIdAndStatus(
            bus.getBusId(), "in_progress").isPresent();

        return AuthorityBusDTO.builder()
            .busId(bus.getBusId())
            .busNumber(bus.getBusNumber())
            .registrationNumber(bus.getRegistrationNumber())
            .ownerName(bus.getOwner() != null
                ? bus.getOwner().getUser().getFullName() : "N/A")
            .ownerBusinessName(bus.getOwner() != null
                ? bus.getOwner().getBusinessName() : "N/A")
            .routeNumber(bus.getRoute() != null
                ? bus.getRoute().getRouteNumber() : "N/A")
            .routeName(bus.getRoute() != null
                ? bus.getRoute().getRouteName() : "N/A")
            .capacity(bus.getCapacity())
            .model(bus.getModel())
            .isActive(bus.getIsActive())
            .hasGps(bus.getHasGps())
            .isOnTrip(onTrip)
            .latitude(gps != null ? gps.getLatitude().doubleValue() : null)
            .longitude(gps != null ? gps.getLongitude().doubleValue() : null)
            .speedKmh(gps != null && gps.getSpeedKmh() != null
                ? gps.getSpeedKmh().doubleValue() : null)
            .lastGpsUpdate(gps != null && gps.getRecordedAt() != null
                ? gps.getRecordedAt().format(DT) : "No GPS data")
            .crowdCategory(crowd != null ? crowd.getCrowdCategory() : "unknown")
            .passengerCount(crowd != null ? crowd.getPassengerCount() : 0)
            .build();
    }

    private AuthorityStaffDTO toStaffDTO(Staff s) {
        StaffBusAssignment assignment = assignmentRepo
            .findCurrentAssignmentByStaff(s.getStaffId()).orElse(null);

        String ownerName     = null;
        String ownerBusiness = null;
        if (assignment != null && assignment.getBus().getOwner() != null) {
            ownerName     = assignment.getBus().getOwner().getUser().getFullName();
            ownerBusiness = assignment.getBus().getOwner().getBusinessName();
        } else if (s.getBusOwner() != null) {
            ownerName     = s.getBusOwner().getUser().getFullName();
            ownerBusiness = s.getBusOwner().getBusinessName();
        }

        return AuthorityStaffDTO.builder()
            .staffId(s.getStaffId())
            .fullName(s.getUser().getFullName())
            .email(s.getUser().getEmail())
            .phone(s.getUser().getPhone())
            .employeeId(s.getEmployeeId())
            .staffType(s.getStaffType().name())
            .licenseNumber(s.getLicenseNumber())
            .assignedBusNumber(assignment != null
                ? assignment.getBus().getBusNumber() : "Unassigned")
            .ownerName(ownerName)
            .ownerBusinessName(ownerBusiness)
            .isActive(s.getIsActive())
            .dateOfJoining(s.getDateOfJoining() != null
                ? s.getDateOfJoining().toString() : null)
            .build();
    }

    private AuthorityOwnerDTO toOwnerDTO(BusOwner o) {
        List<Bus> buses = busRepo.findByOwner_OwnerId(o.getOwnerId());
        long activeBuses = buses.stream().filter(b -> Boolean.TRUE.equals(b.getIsActive())).count();
        long staffCount  = staffRepo.findByBusOwner_OwnerId(o.getOwnerId()).size();

        return AuthorityOwnerDTO.builder()
            .ownerId(o.getOwnerId())
            .fullName(o.getUser().getFullName())
            .email(o.getUser().getEmail())
            .phone(o.getUser().getPhone())
            .businessName(o.getBusinessName())
            .nicNumber(o.getNicNumber())
            .address(o.getAddress())
            .totalBuses((int) buses.size())
            .activeBuses((int) activeBuses)
            .totalStaff((int) staffCount)
            .registeredAt(o.getCreatedAt() != null
                ? o.getCreatedAt().format(DT) : null)
            .build();
    }

    /**
     * Builds fare config DTO with preview table.
     * OOP Polymorphism: fare = baseFare + (stops-1) * 8, clamped to [30, 2422].
     */
    private FareConfigDTO toFareConfigDTO(Route route) {
        int totalStops = stopRepo
            .findByRoute_RouteIdOrderByStopSequence(route.getRouteId()).size();

        // Build preview: 1 stop, 5 stops, 10, 15, 20, all stops
        List<FareConfigDTO.StopFarePreview> preview = new ArrayList<>();
        int[] sampleStops = {1, 5, 10, 15, 20, Math.max(1, totalStops - 1)};
        for (int stops : sampleStops) {
            if (stops > 0 && stops < totalStops) {
                double fare = computeFare(route.getBaseFare().doubleValue(), stops);
                preview.add(new FareConfigDTO.StopFarePreview(stops, fare));
            }
        }
        // Remove duplicates
        preview = preview.stream()
            .filter(p -> preview.stream()
                .noneMatch(q -> q != p && q.getStopCount().equals(p.getStopCount())))
            .collect(Collectors.toList());

        return FareConfigDTO.builder()
            .routeId(route.getRouteId())
            .routeNumber(route.getRouteNumber())
            .routeName(route.getRouteName())
            .startLocation(route.getStartLocation())
            .endLocation(route.getEndLocation())
            .totalStops(totalStops)
            .minimumFare(MIN_FARE.doubleValue())
            .farePerStop(FARE_PER_STOP.doubleValue())
            .maximumFare(MAX_FARE.doubleValue())
            .currentBaseFare(route.getBaseFare().doubleValue())
            .farePreview(preview)
            .build();
    }

    /**
     * Fare formula: baseFare + (stopCount - 1) * 8, clamped [30, 2422].
     * Encapsulation: formula is private — callers just call computeFare().
     */
    private double computeFare(double baseFare, int stopCount) {
        double fare = baseFare + (stopCount - 1) * 8.0;
        fare = Math.max(30.0, Math.min(2422.0, fare));
        return Math.round(fare * 100.0) / 100.0;
    }
}
