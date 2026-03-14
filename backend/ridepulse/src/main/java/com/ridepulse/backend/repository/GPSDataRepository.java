package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.GPSData;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * GPSData Repository
 *
 * DATA ACCESS LAYER (OOP Concept):
 * Abstracts database operations for GPS data
 */
@Repository
public interface GPSDataRepository extends JpaRepository<GPSData, Long> {

    /**
     * Get latest GPS data for a bus
     */
    @Query("SELECT g FROM GPSData g WHERE g.busId = :busId " +
            "ORDER BY g.timestamp DESC LIMIT 1")
    Optional<GPSData> findLatestByBusId(@Param("busId") Long busId);

    /**
     * Get GPS data for a bus within time range
     */
    @Query("SELECT g FROM GPSData g WHERE g.busId = :busId " +
            "AND g.timestamp BETWEEN :startTime AND :endTime " +
            "ORDER BY g.timestamp DESC")
    List<GPSData> findByBusIdAndTimestampBetween(
            @Param("busId") Long busId,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime
    );

    /**
     * Get GPS history for a bus (last N records)
     */
    @Query("SELECT g FROM GPSData g WHERE g.busId = :busId " +
            "ORDER BY g.timestamp DESC LIMIT :limit")
    List<GPSData> findLatestNByBusId(
            @Param("busId") Long busId,
            @Param("limit") int limit
    );

    /**
     * Get all buses with GPS data updated in last N minutes
     */
    @Query("SELECT DISTINCT g.busId FROM GPSData g " +
            "WHERE g.timestamp >= :since")
    List<Long> findActiveBusesSince(@Param("since") LocalDateTime since);

    /**
     * Get GPS data with deviations
     */
    @Query("SELECT g FROM GPSData g WHERE g.isDeviation = true " +
            "AND g.timestamp >= :since ORDER BY g.timestamp DESC")
    List<GPSData> findDeviationsSince(@Param("since") LocalDateTime since);

    /**
     * Delete old GPS data (cleanup)
     */
    @Query("DELETE FROM GPSData g WHERE g.timestamp < :before")
    void deleteOldData(@Param("before") LocalDateTime before);

    /**
     * Get average speed for a bus
     */
    @Query("SELECT AVG(g.speed) FROM GPSData g " +
            "WHERE g.busId = :busId AND g.speed IS NOT NULL " +
            "AND g.timestamp >= :since")
    Double findAverageSpeedByBusIdSince(
            @Param("busId") Long busId,
            @Param("since") LocalDateTime since
    );
}