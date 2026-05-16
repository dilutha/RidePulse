// ============================================================
// ConductorServiceImpl.java
// OOP Encapsulation: all conductor business logic hidden here.
//     Polymorphism: fare calculation uses stop sequence position.
// ============================================================
package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.ConductorService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConductorServiceImpl implements ConductorService {

    // Encapsulation: all dependencies injected, private
    private final StaffRepository              staffRepo;
    private final DutyRosterRepository         rosterRepo;
    private final BusTripRepository            tripRepo;
    private final TicketRepository             ticketRepo;
    private final RouteStopRepository          stopRepo;
    private final CrowdLevelRepository         crowdRepo;
    private final StaffWelfareBalanceRepository welfareRepo;
    private final UserRepository               userRepo;

    private static final DateTimeFormatter DT  = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final DateTimeFormatter D   = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    private static final DateTimeFormatter T   = DateTimeFormatter.ofPattern("HH:mm");

    // ── Dashboard ────────────────────────────────────────────

    /**
     * OOP Abstraction: returns complete home screen data in one call.
     * Composes roster, active trip, month stats, and welfare.
     */
    @Override
    public ConductorDashboardDTO getDashboard(Integer staffId) {
        Staff staff = findStaff(staffId);

        // Today's rosters
        List<RosterDetailDTO> todayRosters = getTodayRosters(staffId);
        RosterDetailDTO todayRoster = todayRosters.isEmpty() ? null : todayRosters.get(0);

        // Active trip
        TripStatusDTO activeTrip = null;
        if (todayRoster != null && todayRoster.getBusId() != null) {
            activeTrip = tripRepo
                    .findByBus_BusIdAndStatus(todayRoster.getBusId(), "in_progress")
                    .map(t -> toTripStatusDTO(t, staffId))
                    .orElse(null);
        }

        // Monthly stats
        int month = LocalDate.now().getMonthValue();
        int year  = LocalDate.now().getYear();
        Integer dutyDays = rosterRepo.countDutyDaysForStaffInMonth(staffId, month, year);

        // Ticket stats this month
        int ticketsThisMonth = ticketRepo.countByStaffAndMonth(staffId, month, year);
        BigDecimal fareThisMonth = ticketRepo.sumFareByStaffAndMonth(staffId, month, year);

        // Welfare
        StaffWelfareBalance welfare = welfareRepo
                .findByStaffAndMonth(staffId, month, year)
                .orElse(null);
        BigDecimal totalWelfare = welfareRepo
                .findLatestCumulativeBalance(staffId, month, year)
                .orElse(BigDecimal.ZERO);

        return ConductorDashboardDTO.builder()
                .conductorName(staff.getUser().getFullName())
                .employeeId(staff.getEmployeeId())
                .staffId(staffId)
                .todayRoster(todayRoster)
                .activeTrip(activeTrip)
                .dutyDaysThisMonth(dutyDays != null ? dutyDays : 0)
                .ticketsIssuedThisMonth(ticketsThisMonth)
                .totalFareThisMonth(fareThisMonth != null ? fareThisMonth.doubleValue() : 0.0)
                .welfareThisMonth(welfare != null ? welfare.getWelfareAmount().doubleValue() : 0.0)
                .totalWelfareBalance(totalWelfare.doubleValue())
                .build();
    }

    // ── Roster ───────────────────────────────────────────────

    @Override
    public List<RosterDetailDTO> getTodayRosters(Integer staffId) {
        return rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(staffId, LocalDate.now())
                .stream()
                .map(r -> toRosterDTO(r, staffId))
                .collect(Collectors.toList());
    }

    @Override
    public List<RosterDetailDTO> getRostersForDate(Integer staffId, String date) {
        LocalDate ld = LocalDate.parse(date);
        return rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(staffId, ld)
                .stream()
                .map(r -> toRosterDTO(r, staffId))
                .collect(Collectors.toList());
    }

    // ── Trip Lifecycle ────────────────────────────────────────

    /**
     * Starts a trip for the given roster entry.
     * OOP Encapsulation: creates BusTrip entity and marks roster active.
     */
    @Override
    @Transactional
    public TripStatusDTO startTrip(Integer rosterId, Integer staffId) {
        DutyRoster roster = rosterRepo.findById(rosterId)
                .orElseThrow(() -> new RuntimeException("Roster not found"));

        // Security: verify this roster belongs to this conductor
        if (!roster.getStaff().getStaffId().equals(staffId)) {
            throw new RuntimeException("Unauthorized: roster not assigned to you");
        }

        // Check no trip already in progress for this bus
        tripRepo.findByBus_BusIdAndStatus(roster.getBus().getBusId(), "in_progress")
                .ifPresent(t -> { throw new RuntimeException("A trip is already in progress for this bus"); });

        // Create the trip
        BusTrip trip = BusTrip.builder()
                .bus(roster.getBus())
                .route(roster.getRoute())
                .roster(roster)
                .tripStart(LocalDateTime.now())
                .status("in_progress")
                .build();
        tripRepo.save(trip);

        saveCrowdSnapshot(trip, 0);

        // Mark roster active
        roster.setStatus("active");
        rosterRepo.save(roster);

        log.info("Trip started: tripId={}, bus={}, conductor={}",
                trip.getTripId(), roster.getBus().getBusNumber(), staffId);

        return toTripStatusDTO(trip, staffId);
    }

    /**
     * Ends the active trip.
     * OOP Polymorphism: status transitions in_progress → completed.
     */
    @Override
    @Transactional
    public TripStatusDTO stopTrip(Integer tripId, Integer staffId) {
        BusTrip trip = tripRepo.findById(tripId)
                .orElseThrow(() -> new RuntimeException("Trip not found"));

        if (!"in_progress".equals(trip.getStatus())) {
            throw new RuntimeException("Trip is not in progress");
        }

        trip.setTripEnd(LocalDateTime.now());
        trip.setStatus("completed");
        tripRepo.save(trip);

        // Mark roster completed
        if (trip.getRoster() != null) {
            trip.getRoster().setStatus("completed");
            rosterRepo.save(trip.getRoster());
        }

        log.info("Trip completed: tripId={}, bus={}", tripId,
                trip.getBus().getBusNumber());

        return toTripStatusDTO(trip, staffId);
    }

    @Override
    public TripStatusDTO getActiveTrip(Integer staffId) {
        // Find today's roster → get active trip for that bus
        return rosterRepo
                .findByStaff_StaffIdAndDutyDateOrderByShiftStart(staffId, LocalDate.now())
                .stream()
                .findFirst()
                .flatMap(r -> tripRepo.findByBus_BusIdAndStatus(
                        r.getBus().getBusId(), "in_progress"))
                .map(t -> toTripStatusDTO(t, staffId))
                .orElseThrow(() -> new RuntimeException("No active trip found"));
    }

    // ── Ticketing ─────────────────────────────────────────────

    /**
     * Issues a ticket.
     * OOP Encapsulation: fare calculation, QR generation, and ticket
     *     number generation are all private — callers just call issueTicket().
     * OOP Polymorphism: fare scales proportionally by stop distance.
     */
    @Override
    @Transactional
    public TicketDTO issueTicket(IssueTicketRequest req, Integer staffId) {
        Staff conductor = findStaff(staffId);

        BusTrip trip = tripRepo.findById(req.getTripId())
                .orElseThrow(() -> new RuntimeException("Trip not found"));

        if (!"in_progress".equals(trip.getStatus())) {
            throw new RuntimeException("Cannot issue ticket — trip is not active");
        }
        if (trip.getRoster() == null || trip.getRoster().getStaff() == null
                || !trip.getRoster().getStaff().getStaffId().equals(staffId)) {
            throw new RuntimeException("Unauthorized: trip not assigned to you");
        }

        RouteStop boarding  = stopRepo.findById(req.getBoardingStopId())
                .orElseThrow(() -> new RuntimeException("Boarding stop not found"));
        RouteStop alighting = stopRepo.findById(req.getAlightingStopId())
                .orElseThrow(() -> new RuntimeException("Alighting stop not found"));
        if (!boarding.getRoute().getRouteId().equals(trip.getRoute().getRouteId())
                || !alighting.getRoute().getRouteId().equals(trip.getRoute().getRouteId())) {
            throw new RuntimeException("Selected stops do not belong to this route");
        }

        // Polymorphism: fare calculated by stop sequence distance
        BigDecimal fare = calculateFare(
                trip.getRoute(), boarding, alighting);

        // Resolve optional passenger
        User passenger = null;
        if (req.getPassengerUserId() != null && !req.getPassengerUserId().isBlank()) {
            passenger = userRepo.findById(UUID.fromString(req.getPassengerUserId()))
                    .orElse(null);
        }

        int ticketCount = req.getTicketCount() != null ? req.getTicketCount() : 1;
        Ticket ticket = null;
        for (int i = 0; i < ticketCount; i++) {
            String ticketNumber = generateTicketNumber();
            String qrCode       = generateQrCode(ticketNumber);

            ticket = Ticket.builder()
                    .ticketNumber(ticketNumber)
                    .qrCode(qrCode)
                    .trip(trip)
                    .passenger(passenger)
                    .conductor(conductor)
                    .route(trip.getRoute())
                    .boardingStop(boarding)
                    .alightingStop(alighting)
                    .fareAmount(fare)
                    .paymentMethod(req.getPaymentMethod() != null ? req.getPaymentMethod() : "cash")
                    .ticketStatus("active")
                    .issuedAt(LocalDateTime.now())
                    .build();

            ticketRepo.save(ticket);
        }
        int livePassengerCount = ticketRepo.countByTrip_TripIdAndTicketStatus(
                trip.getTripId(), "active");
        saveCrowdSnapshot(trip, livePassengerCount);
        log.info("Tickets issued: count={} fareEach={} trip={}", ticketCount, fare, trip.getTripId());

        return toTicketDTO(ticket);
    }

    @Override
    public List<TicketDTO> getTripTickets(Integer tripId, Integer staffId) {
        return ticketRepo.findByTrip_TripIdOrderByIssuedAtDesc(tripId)
                .stream()
                .map(this::toTicketDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public TicketDTO validateTicket(String qrCode, Integer staffId) {
        Ticket ticket = ticketRepo.findByQrCode(qrCode)
                .orElseThrow(() -> new RuntimeException("Ticket not found"));

        if ("used".equals(ticket.getTicketStatus())) {
            throw new RuntimeException("Ticket already used");
        }
        if ("expired".equals(ticket.getTicketStatus())) {
            throw new RuntimeException("Ticket has expired");
        }

        ticket.setIsValidated(true);
        ticket.setValidatedAt(LocalDateTime.now());
        ticket.setTicketStatus("used");
        ticketRepo.save(ticket);

        if (ticket.getTrip() != null && "in_progress".equals(ticket.getTrip().getStatus())) {
            int livePassengerCount = ticketRepo.countByTrip_TripIdAndTicketStatus(
                    ticket.getTrip().getTripId(), "active");
            saveCrowdSnapshot(ticket.getTrip(), livePassengerCount);
        }

        return toTicketDTO(ticket);
    }

    // ── Crowd Level ───────────────────────────────────────────

    @Override
    @Transactional
    public TripStatusDTO updateCrowdLevel(CrowdUpdateRequest req, Integer staffId) {
        throw new RuntimeException("Manual crowd input is disabled. Crowd is calculated from active issued tickets.");
    }

    // ── Route Stops ───────────────────────────────────────────

    @Override
    public List<StopDTO> getRouteStops(Integer routeId) {
        return stopRepo.findByRoute_RouteIdOrderByStopSequence(routeId)
                .stream()
                .map(s -> StopDTO.builder()
                        .stopId(s.getStopId())
                        .stopName(s.getStopName())
                        .stopSequence(s.getStopSequence())
                        .latitude(s.getLatitude() != null ? s.getLatitude().doubleValue() : null)
                        .longitude(s.getLongitude() != null ? s.getLongitude().doubleValue() : null)
                        .build())
                .collect(Collectors.toList());
    }

    // ── Welfare ───────────────────────────────────────────────

    @Override
    public List<ConductorWelfareDTO> getWelfareHistory(Integer staffId) {
        return welfareRepo.findByStaff_StaffIdOrderByBalanceYearDescBalanceMonthDesc(staffId)
                .stream()
                .map(w -> ConductorWelfareDTO.builder()
                        .month(w.getBalanceMonth())
                        .year(w.getBalanceYear())
                        .welfareAmount(w.getWelfareAmount().doubleValue())
                        .cumulativeBalance(w.getCumulativeBalance().doubleValue())
                        .busNumber(w.getBus().getBusNumber())
                        .build())
                .collect(Collectors.toList());
    }

    // ── Private helpers (Encapsulation) ──────────────────────

    private Staff findStaff(Integer staffId) {
        return staffRepo.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Staff not found: " + staffId));
    }


    /**
     * Calculates ticket fare using Sri Lanka NTPS fare rules.
     * OOP Encapsulation: all fare logic is hidden here.
     * OOP Polymorphism: result changes based on stop count.
     *
     * Formula: fare = baseFare + (stopsBetween - 1) × 8
     * Bounds:  minimum LKR 30, maximum LKR 2422
     */
    private BigDecimal calculateFare(Route route, RouteStop boarding,
                                     RouteStop alighting) {
        // National fare constants (Encapsulation: defined here, not scattered)
        final BigDecimal MIN_FARE      = new BigDecimal("30.00");
        final BigDecimal MAX_FARE      = new BigDecimal("2422.00");
        final BigDecimal FARE_PER_STOP = new BigDecimal("8.00");

        int stopsBetween = Math.abs(
                alighting.getStopSequence() - boarding.getStopSequence());

        if (stopsBetween == 0) return MIN_FARE;  // same stop = minimum

        // Fare = baseFare + (stops - 1) × 8
        BigDecimal fare = route.getBaseFare()
                .add(FARE_PER_STOP.multiply(BigDecimal.valueOf(stopsBetween - 1)));

        // Clamp to national bounds
        if (fare.compareTo(MIN_FARE) < 0) fare = MIN_FARE;
        if (fare.compareTo(MAX_FARE) > 0) fare = MAX_FARE;

        return fare.setScale(2, RoundingMode.HALF_UP);
    }


    private String generateTicketNumber() {
        String ticketNumber;
        do {
            String date = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
            String suffix = String.format("%05d", System.currentTimeMillis() % 100000);
            String nonce = UUID.randomUUID().toString().substring(0, 4).toUpperCase();
            ticketNumber = "TKT-" + date + "-" + suffix + "-" + nonce;
        } while (ticketRepo.existsByTicketNumber(ticketNumber));
        return ticketNumber;
    }

    private String generateQrCode(String ticketNumber) {
        // QR payload: ticketNumber + timestamp UUID fragment
        return ticketNumber + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private void saveCrowdSnapshot(BusTrip trip, int passengerCount) {
        int capacity = trip.getBus().getCapacity() != null ? trip.getBus().getCapacity() : 52;
        capacity = Math.max(1, capacity);
        int safeCount = Math.max(0, Math.min(passengerCount, capacity));
        crowdRepo.save(CrowdLevel.builder()
                .bus(trip.getBus())
                .trip(trip)
                .passengerCount(safeCount)
                .busCapacity(capacity)
                .build());
    }

    private RosterDetailDTO toRosterDTO(DutyRoster r, Integer staffId) {
        // Find active trip for this bus
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
                .activeTripId(activeTrip != null ? activeTrip.getTripId() : null)
                .tripStatus(activeTrip != null ? activeTrip.getStatus() : null)
                .build();
    }

    private TripStatusDTO toTripStatusDTO(BusTrip t, Integer staffId) {
        int ticketCount = ticketRepo.countByTrip_TripId(t.getTripId());
        BigDecimal totalFare = ticketRepo.sumFareByTrip(t.getTripId());

        // Latest crowd level for this trip
        Integer crowdCount = crowdRepo.findLatestByBusId(t.getBus().getBusId())
                .map(CrowdLevel::getPassengerCount)
                .orElse(0);

        return TripStatusDTO.builder()
                .tripId(t.getTripId())
                .busNumber(t.getBus().getBusNumber())
                .routeName(t.getRoute().getRouteName())
                .status(t.getStatus())
                .tripStart(t.getTripStart() != null ? t.getTripStart().format(DT) : null)
                .tripEnd(t.getTripEnd()   != null ? t.getTripEnd().format(DT)   : null)
                .ticketsIssuedCount(ticketCount)
                .totalFareCollected(totalFare != null ? totalFare.doubleValue() : 0.0)
                .currentPassengerCount(crowdCount)
                .build();
    }

    private TicketDTO toTicketDTO(Ticket t) {
        return TicketDTO.builder()
                .ticketId(t.getTicketId())
                .ticketNumber(t.getTicketNumber())
                .qrCode(t.getQrCode())
                .boardingStop(t.getBoardingStop() != null
                        ? t.getBoardingStop().getStopName() : "")
                .alightingStop(t.getAlightingStop() != null
                        ? t.getAlightingStop().getStopName() : "")
                .fareAmount(t.getFareAmount().doubleValue())
                .paymentMethod(t.getPaymentMethod())
                .ticketStatus(t.getTicketStatus())
                .issuedAt(t.getIssuedAt() != null ? t.getIssuedAt().format(DT) : null)
                .build();
    }
}
