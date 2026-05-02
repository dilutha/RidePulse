package com.ridepulse.backend.controller;

import com.ridepulse.backend.config.CustomUserDetails;
import com.ridepulse.backend.dto.ConductorWelfareDTO;
import com.ridepulse.backend.dto.RosterDetailDTO;
import com.ridepulse.backend.dto.TripStatusDTO;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/driver")
@RequiredArgsConstructor
public class DriverController {

    private final StaffRepository staffRepo;
    private final DutyRosterRepository rosterRepo;
    private final BusTripRepository tripRepo;
    private final TicketRepository ticketRepo;
    private final CrowdLevelRepository crowdRepo;
    private final GpsTrackingRepository gpsRepo;
    private final EmergencyAlertRepository alertRepo;
    private final StaffWelfareBalanceRepository welfareRepo;

    private static final DateTimeFormatter D = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter T = DateTimeFormatter.ofPattern("HH:mm");
    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<Map<String, Object>> dashboard(
            @AuthenticationPrincipal CustomUserDetails user) {
        Staff driver = findDriver(user.getStaffId());
        RosterDetailDTO todayRoster = todayRosters(user.getStaffId()).stream()
                .findFirst()
                .orElse(null);
        TripStatusDTO activeTrip = todayRoster != null
                ? tripRepo.findByBus_BusIdAndStatus(todayRoster.getBusId(), "in_progress")
                    .map(this::toTripStatus)
                    .orElse(null)
                : null;

        int month = LocalDate.now().getMonthValue();
        int year = LocalDate.now().getYear();
        StaffWelfareBalance welfare = welfareRepo
                .findByStaffAndMonth(user.getStaffId(), month, year)
                .orElse(null);
        BigDecimal totalWelfare = welfareRepo
                .findLatestCumulativeBalance(user.getStaffId(), month, year)
                .orElse(BigDecimal.ZERO);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("driverName", driver.getUser().getFullName());
        body.put("employeeId", driver.getEmployeeId());
        body.put("licenseNumber", driver.getLicenseNumber());
        body.put("licenseExpiry", driver.getLicenseExpiry() != null
                ? driver.getLicenseExpiry().toString()
                : null);
        body.put("staffId", driver.getStaffId());
        body.put("todayRoster", todayRoster);
        body.put("activeTrip", activeTrip);
        body.put("dutyDaysThisMonth",
                Optional.ofNullable(rosterRepo.countDutyDaysForStaffInMonth(
                        user.getStaffId(), month, year)).orElse(0));
        body.put("welfareThisMonth", welfare != null
                ? welfare.getWelfareAmount().doubleValue()
                : 0.0);
        body.put("totalWelfareBalance", totalWelfare.doubleValue());
        body.put("activeAlert", activeTrip != null
                ? alertRepo.findByBus_BusIdAndStatus(
                        findTrip(activeTrip.getTripId()).getBus().getBusId(), "active")
                    .stream()
                    .findFirst()
                    .map(this::toAlert)
                    .orElse(null)
                : null);
        return ResponseEntity.ok(body);
    }

    @GetMapping("/roster/today")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<List<RosterDetailDTO>> todayRoster(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(todayRosters(user.getStaffId()));
    }

    @GetMapping("/roster")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<List<RosterDetailDTO>> rosterForDate(
            @RequestParam String date,
            @AuthenticationPrincipal CustomUserDetails user) {
        LocalDate dutyDate = LocalDate.parse(date);
        return ResponseEntity.ok(rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(user.getStaffId(), dutyDate)
                .stream()
                .map(this::toRoster)
                .collect(Collectors.toList()));
    }

    @PostMapping("/trip/start")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<TripStatusDTO> startTrip(
            @RequestBody Map<String, Integer> body,
            @AuthenticationPrincipal CustomUserDetails user) {
        DutyRoster roster = rosterRepo.findById(body.get("rosterId"))
                .orElseThrow(() -> new RuntimeException("Roster not found"));
        if (!roster.getStaff().getStaffId().equals(user.getStaffId())) {
            throw new RuntimeException("Unauthorized: roster not assigned to you");
        }
        tripRepo.findByBus_BusIdAndStatus(roster.getBus().getBusId(), "in_progress")
                .ifPresent(t -> {
                    throw new RuntimeException("A trip is already in progress for this bus");
                });

        BusTrip trip = BusTrip.builder()
                .bus(roster.getBus())
                .route(roster.getRoute())
                .roster(roster)
                .tripStart(LocalDateTime.now())
                .status("in_progress")
                .build();
        tripRepo.save(trip);
        roster.setStatus("active");
        rosterRepo.save(roster);
        return ResponseEntity.status(HttpStatus.CREATED).body(toTripStatus(trip));
    }

    @PostMapping("/trip/{tripId}/stop")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<TripStatusDTO> stopTrip(@PathVariable Integer tripId) {
        BusTrip trip = findTrip(tripId);
        trip.setTripEnd(LocalDateTime.now());
        trip.setStatus("completed");
        tripRepo.save(trip);
        if (trip.getRoster() != null) {
            trip.getRoster().setStatus("completed");
            rosterRepo.save(trip.getRoster());
        }
        return ResponseEntity.ok(toTripStatus(trip));
    }

    @PostMapping("/gps/update")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<Void> updateGps(@RequestBody Map<String, Object> body) {
        BusTrip trip = findTrip(((Number) body.get("tripId")).intValue());
        gpsRepo.save(GpsTracking.builder()
                .bus(trip.getBus())
                .trip(trip)
                .latitude(BigDecimal.valueOf(((Number) body.get("latitude")).doubleValue()))
                .longitude(BigDecimal.valueOf(((Number) body.get("longitude")).doubleValue()))
                .speedKmh(numberOrNull(body.get("speedKmh")))
                .heading(numberOrNull(body.get("heading")))
                .recordedAt(LocalDateTime.now())
                .build());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/emergency/raise")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<Map<String, Object>> raiseEmergency(
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal CustomUserDetails user) {
        Staff driver = findDriver(user.getStaffId());
        BusTrip trip = findTrip(((Number) body.get("tripId")).intValue());
        EmergencyAlert alert = EmergencyAlert.builder()
                .bus(trip.getBus())
                .trip(trip)
                .staff(driver)
                .alertType(String.valueOf(body.get("alertType")))
                .description((String) body.get("description"))
                .latitude(numberOrNull(body.get("latitude")))
                .longitude(numberOrNull(body.get("longitude")))
                .status("active")
                .createdAt(LocalDateTime.now())
                .build();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(toAlert(alertRepo.save(alert)));
    }

    @PostMapping("/emergency/{alertId}/resolve")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<Map<String, Object>> resolveEmergency(
            @PathVariable Integer alertId) {
        EmergencyAlert alert = alertRepo.findById(alertId)
                .orElseThrow(() -> new RuntimeException("Alert not found"));
        alert.setStatus("resolved");
        alert.setResolvedAt(LocalDateTime.now());
        return ResponseEntity.ok(toAlert(alertRepo.save(alert)));
    }

    @GetMapping("/emergency")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<List<Map<String, Object>>> alerts(
            @AuthenticationPrincipal CustomUserDetails user) {
        List<Integer> busIds = todayRosters(user.getStaffId()).stream()
                .map(RosterDetailDTO::getBusId)
                .toList();
        return ResponseEntity.ok(busIds.stream()
                .flatMap(busId -> alertRepo.findByBus_BusIdAndStatus(busId, "active").stream())
                .map(this::toAlert)
                .collect(Collectors.toList()));
    }

    @GetMapping("/welfare")
    @PreAuthorize("hasRole('driver')")
    public ResponseEntity<List<ConductorWelfareDTO>> welfare(
            @AuthenticationPrincipal CustomUserDetails user) {
        return ResponseEntity.ok(welfareRepo
                .findByStaff_StaffIdOrderByBalanceYearDescBalanceMonthDesc(user.getStaffId())
                .stream()
                .map(w -> ConductorWelfareDTO.builder()
                        .month(w.getBalanceMonth())
                        .year(w.getBalanceYear())
                        .welfareAmount(w.getWelfareAmount().doubleValue())
                        .cumulativeBalance(w.getCumulativeBalance().doubleValue())
                        .busNumber(w.getBus().getBusNumber())
                        .build())
                .collect(Collectors.toList()));
    }

    private List<RosterDetailDTO> todayRosters(Integer staffId) {
        return rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(staffId, LocalDate.now())
                .stream()
                .map(this::toRoster)
                .collect(Collectors.toList());
    }

    private Staff findDriver(Integer staffId) {
        Staff staff = staffRepo.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Driver profile not found"));
        if (staff.getStaffType() != Staff.StaffType.driver) {
            throw new RuntimeException("Logged in staff member is not a driver");
        }
        return staff;
    }

    private BusTrip findTrip(Integer tripId) {
        return tripRepo.findById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));
    }

    private RosterDetailDTO toRoster(DutyRoster r) {
        BusTrip activeTrip = tripRepo
                .findByBus_BusIdAndStatus(r.getBus().getBusId(), "in_progress")
                .orElse(null);
        return RosterDetailDTO.builder()
                .rosterId(r.getRosterId())
                .dutyDate(r.getDutyDate().format(D))
                .shiftStart(r.getShiftStart().format(T))
                .shiftEnd(r.getShiftEnd().format(T))
                .status(r.getStatus())
                .busId(r.getBus().getBusId())
                .busNumber(r.getBus().getBusNumber())
                .registrationNumber(r.getBus().getRegistrationNumber())
                .busCapacity(r.getBus().getCapacity())
                .routeId(r.getRoute().getRouteId())
                .routeNumber(r.getRoute().getRouteNumber())
                .routeName(r.getRoute().getRouteName())
                .startLocation(r.getRoute().getStartLocation())
                .endLocation(r.getRoute().getEndLocation())
                .baseFare(r.getRoute().getBaseFare().doubleValue())
                .staffId(r.getStaff().getStaffId())
                .staffName(r.getStaff().getUser().getFullName())
                .staffType(r.getStaff().getStaffType().name())
                .employeeId(r.getStaff().getEmployeeId())
                .activeTripId(activeTrip != null ? activeTrip.getTripId() : null)
                .tripStatus(activeTrip != null ? activeTrip.getStatus() : null)
                .build();
    }

    private TripStatusDTO toTripStatus(BusTrip t) {
        BigDecimal totalFare = ticketRepo.sumFareByTrip(t.getTripId());
        Integer crowdCount = crowdRepo.findLatestByBusId(t.getBus().getBusId())
                .map(CrowdLevel::getPassengerCount)
                .orElse(0);
        return TripStatusDTO.builder()
                .tripId(t.getTripId())
                .busNumber(t.getBus().getBusNumber())
                .routeName(t.getRoute().getRouteName())
                .status(t.getStatus())
                .tripStart(t.getTripStart() != null ? t.getTripStart().format(DT) : null)
                .tripEnd(t.getTripEnd() != null ? t.getTripEnd().format(DT) : null)
                .ticketsIssuedCount(ticketRepo.countByTrip_TripId(t.getTripId()))
                .totalFareCollected(totalFare != null ? totalFare.doubleValue() : 0.0)
                .currentPassengerCount(crowdCount)
                .build();
    }

    private Map<String, Object> toAlert(EmergencyAlert alert) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("alertId", alert.getAlertId());
        body.put("busNumber", alert.getBus().getBusNumber());
        body.put("routeName", alert.getBus().getRoute() != null
                ? alert.getBus().getRoute().getRouteName()
                : "");
        body.put("alertType", alert.getAlertType());
        body.put("description", alert.getDescription());
        body.put("latitude", alert.getLatitude() != null
                ? alert.getLatitude().doubleValue()
                : null);
        body.put("longitude", alert.getLongitude() != null
                ? alert.getLongitude().doubleValue()
                : null);
        body.put("status", alert.getStatus());
        body.put("createdAt", alert.getCreatedAt() != null
                ? alert.getCreatedAt().format(DT)
                : "");
        return body;
    }

    private BigDecimal numberOrNull(Object value) {
        return value instanceof Number n
                ? BigDecimal.valueOf(n.doubleValue())
                : null;
    }
}
