package com.ridepulse.backend.repository;

import com.ridepulse.backend.entity.BusTrip;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * OOP Abstraction: Trip lifecycle queries — hides status filtering.
 * Used by: TicketService, CrowdService, RevenueServiceImpl, GPS tracking
 */
@Repository
public interface BusTripRepository extends JpaRepository<BusTrip, Integer> {

    // Used by: ConductorApp — find the active trip for a bus right now
    Optional<BusTrip> findByBus_BusIdAndStatus(Integer busId, String status);

    // Used by: RevenueServiceImpl — all trips for a bus in a given month
    @Query("""
        SELECT t FROM BusTrip t
        WHERE t.bus.busId = :busId
          AND MONTH(t.tripStart) = :month
          AND YEAR(t.tripStart) = :year
        """)
    List<BusTrip> findByBusAndMonth(
            @Param("busId") Integer busId,
            @Param("month") Integer month,
            @Param("year") Integer year);

    // Used by: PassengerApp — find trips currently in progress for a route
    @Query("""
        SELECT t FROM BusTrip t
        WHERE t.route.routeId = :routeId
          AND t.status = 'in_progress'
        ORDER BY t.tripStart DESC
        """)
    List<BusTrip> findActiveTripsByRoute(@Param("routeId") Integer routeId);

    long countByStatus(String status);
}