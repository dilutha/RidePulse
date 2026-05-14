package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.BusOwnerDashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BusOwnerDashboardServiceImpl implements BusOwnerDashboardService {

    // All dependencies injected — Encapsulation: callers never see these repos
    private final BusOwnerRepository             ownerRepo;
    private final BusRepository                  busRepo;
    private final StaffBusAssignmentRepository   assignmentRepo;
    private final GpsTrackingRepository          gpsRepo;
    private final CrowdLevelRepository           crowdRepo;
    private final ComplaintRepository            complaintRepo;
    private final MonthlyRevenueSummaryRepository monthlyRepo;
    private final DailyRevenueRepository         dailyRevenueRepo;

    /**
     * OOP Abstraction: returns a complete dashboard DTO in one call.
     * Internally aggregates 6 data sources — the controller knows nothing about this.
     */
    @Override
    @Transactional(readOnly = true)
    public BusOwnerDashboardDTO getDashboard(Integer ownerId) {
        log.debug("Loading bus-owner dashboard for ownerId={}", ownerId);
        BusOwner owner = ownerRepo.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("Owner not found"));

        YearMonth now   = YearMonth.now();
        int month       = now.getMonthValue();
        int year        = now.getYear();

        // Fetch all active buses for this owner
        List<Bus> buses = busRepo.findByOwner_OwnerIdAndIsActiveTrueOrderByBusNumber(ownerId);

        // Build one card per bus — Aggregation: each card composes multiple sources
        List<BusDashboardCardDTO> busCards = buses.stream()
                .map(bus -> buildBusCard(bus, month, year))
                .collect(Collectors.toList());

        // Combined totals across all buses — Abstraction: hides summing logic
        BigDecimal totalGross  = dailyRevenueRepo.sumGrossRevenueByOwnerAndMonth(ownerId, month, year);
        BigDecimal totalNet    = monthlyRepo.sumNetProfitByOwnerAndMonth(ownerId, month, year);
        BigDecimal driverWelf  = monthlyRepo.sumDriverWelfareByOwnerAndMonth(ownerId, month, year);
        BigDecimal condWelf    = monthlyRepo.sumConductorWelfareByOwnerAndMonth(ownerId, month, year);
        long openComplaints    = complaintRepo.countOpenComplaintsByOwner(ownerId);

        // Count active staff across all buses
        long totalStaff  = assignmentRepo.findCurrentAssignmentsByOwner(ownerId).size();
        long activeStaff = assignmentRepo.findCurrentAssignmentsByOwner(ownerId).stream()
                .filter(a -> Boolean.TRUE.equals(a.getStaff().getIsActive()))
                .count();

        return BusOwnerDashboardDTO.builder()
                .ownerName(owner.getUser().getFullName())
                .businessName(owner.getBusinessName())
                .totalBuses(buses.size())
                .activeBuses(buses.size())                         // already filtered to active
                .totalStaff((int) totalStaff)
                .activeStaff((int) activeStaff)
                .totalMonthGrossRevenue(nullSafe(totalGross))
                .totalMonthNetProfit(nullSafe(totalNet))
                .totalDriverWelfare(nullSafe(driverWelf))
                .totalConductorWelfare(nullSafe(condWelf))
                .totalOpenComplaints((int) openComplaints)
                .buses(busCards)
                .build();
    }

    /**
     * Returns all complaints for buses owned by this owner.
     * Polymorphism: "all" status returns every complaint; specific status filters.
     */
    @Override
    @Transactional(readOnly = true)
    public List<ComplaintSummaryDTO> getComplaints(Integer ownerId, String status) {
        List<Complaint> complaints = "all".equalsIgnoreCase(status)
                ? complaintRepo.findByOwner(ownerId)
                : complaintRepo.findByOwnerAndStatus(ownerId, status);

        return complaints.stream()
                .map(this::toComplaintSummaryDTO)
                .collect(Collectors.toList());
    }

    /**
     * Returns latest GPS coordinate for every bus this owner has.
     * Used by Flutter live map screen.
     */
    @Override
    @Transactional(readOnly = true)
    public List<BusLocationDTO> getLiveBusLocations(Integer ownerId) {
        return gpsRepo.findLatestLocationForAllBusesOfOwner(ownerId).stream()
                .map(g -> {
                    // Resolve latest crowd level for this bus
                    String crowdCat = crowdRepo.findLatestByBusId(g.getBus().getBusId())
                            .map(CrowdLevel::getCrowdCategory)
                            .orElse("unknown");

                    return BusLocationDTO.builder()
                            .busId(g.getBus().getBusId())
                            .busNumber(g.getBus().getBusNumber())
                            .latitude(g.getLatitude().doubleValue())
                            .longitude(g.getLongitude().doubleValue())
                            .speedKmh(g.getSpeedKmh() != null
                                    ? g.getSpeedKmh().doubleValue() : null)
                            .crowdCategory(crowdCat)
                            .recordedAt(g.getRecordedAt()
                                    .format(DateTimeFormatter.ofPattern("HH:mm:ss")))
                            .build();
                })
                .collect(Collectors.toList());
    }

    // ── Private helpers (Encapsulation: hidden from all callers) ──────────

    /**
     * Builds a single bus card for the dashboard.
     * OOP Aggregation: card pulls from GPS, crowd, revenue, staff, complaints.
     */
    private BusDashboardCardDTO buildBusCard(Bus bus, int month, int year) {
        Integer busId = bus.getBusId();

        // Latest GPS location
        GpsTracking gps = gpsRepo.findLatestByBusId(busId).orElse(null);

        // Latest crowd reading
        CrowdLevel crowd = crowdRepo.findLatestByBusId(busId).orElse(null);

        // This month's revenue summary
        MonthlyRevenueSummary rev = monthlyRepo
                .findByBus_BusIdAndSummaryMonthAndSummaryYear(busId, month, year)
                .orElse(null);

        // Open complaints for this bus
        long openComplaints = complaintRepo.findByOwnerAndStatus(
                        bus.getOwner().getOwnerId(), "submitted").stream()
                .filter(c -> c.getBus() != null
                        && c.getBus().getBusId().equals(busId))
                .count();

        // Assigned driver and conductor — Polymorphism: same assignmentRepo, filtered by type
        List<StaffBusAssignment> assignments =
                assignmentRepo.findCurrentAssignmentsByBus(busId);

        String driverName = assignments.stream()
                .filter(a -> a.getStaff().getStaffType() == Staff.StaffType.driver)
                .findFirst()
                .map(a -> a.getStaff().getUser().getFullName())
                .orElse("Unassigned");

        String conductorName = assignments.stream()
                .filter(a -> a.getStaff().getStaffType() == Staff.StaffType.conductor)
                .findFirst()
                .map(a -> a.getStaff().getUser().getFullName())
                .orElse("Unassigned");

        return BusDashboardCardDTO.builder()
                .busId(busId)
                .busNumber(bus.getBusNumber())
                .registrationNumber(bus.getRegistrationNumber())
                .routeName(bus.getRoute() != null ? bus.getRoute().getRouteName() : "No route")
                .isActive(bus.getIsActive())
                .capacity(bus.getCapacity())
                // Live data
                .currentLatitude(gps != null ? gps.getLatitude().doubleValue() : null)
                .currentLongitude(gps != null ? gps.getLongitude().doubleValue() : null)
                .crowdCategory(crowd != null ? crowd.getCrowdCategory() : "unknown")
                .currentPassengerCount(crowd != null ? crowd.getPassengerCount() : 0)
                // Month financials
                .monthGrossRevenue(rev != null ? rev.getGrossRevenue() : BigDecimal.ZERO)
                .monthNetProfit(rev != null ? rev.getNetProfit() : BigDecimal.ZERO)
                .openComplaintsCount((int) openComplaints)
                // Staff
                .assignedDriverName(driverName)
                .assignedConductorName(conductorName)
                .build();
    }

    private ComplaintSummaryDTO toComplaintSummaryDTO(Complaint c) {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        return ComplaintSummaryDTO.builder()
                .complaintId(c.getComplaintId())
                .passengerName(c.getPassenger().getFullName())
                .busNumber(c.getBus() != null ? c.getBus().getBusNumber() : "Unknown")
                .category(c.getCategory())
                .description(c.getDescription())
                .photoUrl(c.getPhotoUrl())
                .priority(c.getPriority())
                .status(c.getStatus())
                .submittedAt(c.getSubmittedAt().format(fmt))
                .resolvedAt(c.getResolvedAt() != null
                        ? c.getResolvedAt().format(fmt) : null)
                .build();
    }

    // Encapsulation: null-safety helper is private
    private BigDecimal nullSafe(BigDecimal val) {
        return val != null ? val : BigDecimal.ZERO;
    }
}
