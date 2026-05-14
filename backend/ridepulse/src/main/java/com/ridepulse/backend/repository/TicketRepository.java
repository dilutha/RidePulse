package com.ridepulse.backend.repository;

import com.ridepulse.backend.entity.Ticket;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.math.BigDecimal;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

/**
 * OOP Encapsulation: Ticket lookup — QR validation and revenue aggregation.
 * Used by: TicketService, RevenueServiceImpl
 */
@Repository
public interface TicketRepository extends JpaRepository<Ticket, Long> {

    // Used by: ConductorApp — scan and validate a QR code
    Optional<Ticket> findByQrCode(String qrCode);

    // Used by: PassengerApp — view my tickets
    java.util.List<Ticket> findByPassenger_UserIdOrderByIssuedAtDesc(UUID passengerId);

    // Used by: RevenueServiceImpl — total revenue for a bus on a specific date
    @Query("""
        SELECT COALESCE(SUM(t.fareAmount), 0) FROM Ticket t
        WHERE t.trip.bus.busId = :busId
          AND CAST(t.issuedAt AS date) = :date
          AND t.ticketStatus IN ('used', 'active')
        """)
    java.math.BigDecimal sumRevenueForBusOnDate(
            @Param("busId") Integer busId,
            @Param("date") LocalDate date);

    // Used by: RevenueServiceImpl / WelfareServiceImpl — monthly revenue for a bus
    @Query("""
        SELECT COALESCE(SUM(t.fareAmount), 0) FROM Ticket t
        WHERE t.trip.bus.busId = :busId
          AND MONTH(t.issuedAt) = :month
          AND YEAR(t.issuedAt) = :year
          AND t.ticketStatus IN ('used', 'active')
        """)
    java.math.BigDecimal sumRevenueForBusInMonth(
            @Param("busId") Integer busId,
            @Param("month") Integer month,
            @Param("year") Integer year);

    // Used by: RevenueServiceImpl — count tickets sold for a bus on a date
    @Query("""
        SELECT COUNT(t) FROM Ticket t
        WHERE t.trip.bus.busId = :busId
          AND CAST(t.issuedAt AS date) = :date
        """)
    Integer countTicketsForBusOnDate(
            @Param("busId") Integer busId,
            @Param("date") LocalDate date);

    // Used by: ConductorApp — check if ticket number already exists
    boolean existsByTicketNumber(String ticketNumber);


    // Used by: ConductorServiceImpl.getTripTickets()
    List<Ticket> findByTrip_TripIdOrderByIssuedAtDesc(Integer tripId);

    // Used by: ConductorServiceImpl.toTripStatusDTO() — ticket count per trip
    @Query("SELECT COUNT(t) FROM Ticket t WHERE t.trip.tripId = :tripId")
    int countByTrip_TripId(@Param("tripId") Integer tripId);

    int countByTrip_TripIdAndTicketStatus(Integer tripId, String ticketStatus);

    // Used by: ConductorServiceImpl.toTripStatusDTO() — total fare collected in trip
    @Query("SELECT COALESCE(SUM(t.fareAmount), 0) FROM Ticket t " +
            "WHERE t.trip.tripId = :tripId AND t.ticketStatus IN ('active','used')")
    BigDecimal sumFareByTrip(@Param("tripId") Integer tripId);

    // Used by: ConductorServiceImpl.getDashboard() — tickets issued this month by staff
    @Query("""
            SELECT COUNT(t) FROM Ticket t
            WHERE t.conductor.staffId = :staffId
              AND MONTH(t.issuedAt) = :month
              AND YEAR(t.issuedAt) = :year
            """)
    int countByStaffAndMonth(
            @Param("staffId") Integer staffId,
            @Param("month")   Integer month,
            @Param("year")    Integer year);

    // Used by: ConductorServiceImpl.getDashboard() — total fare this month by staff
    @Query("""
            SELECT COALESCE(SUM(t.fareAmount), 0) FROM Ticket t
            WHERE t.conductor.staffId = :staffId
              AND MONTH(t.issuedAt) = :month
              AND YEAR(t.issuedAt) = :year
              AND t.ticketStatus IN ('active', 'used')
            """)
    BigDecimal sumFareByStaffAndMonth(
            @Param("staffId") Integer staffId,
            @Param("month")   Integer month,
            @Param("year")    Integer year);
}

