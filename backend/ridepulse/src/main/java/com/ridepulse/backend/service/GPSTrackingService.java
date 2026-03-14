package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.model.GPSData;

import java.time.LocalDateTime;
import java.util.List;

/**
 * GPS Tracking Service Interface
 *
 * ABSTRACTION (OOP Concept):
 * Defines contract for GPS tracking operations
 */
public interface GPSTrackingService {

    /**
     * Record new GPS data point
     */
    GPSDataDTO recordGPSData(CreateGPSDataRequest request);

    /**
     * Get latest GPS data for a bus
     */
    GPSDataDTO getLatestGPSData(Long busId);

    /**
     * Get GPS history for a bus
     */
    List<GPSDataDTO> getGPSHistory(Long busId, int limit);

    /**
     * Get GPS data within time range
     */
    List<GPSDataDTO> getGPSDataInTimeRange(
            Long busId,
            LocalDateTime startTime,
            LocalDateTime endTime
    );

    /**
     * Get all active bus locations
     */
    List<BusLocationDTO> getAllActiveBusLocations();

    /**
     * Get bus locations for a specific route
     */
    List<BusLocationDTO> getBusLocationsByRoute(Long routeId);

    /**
     * Calculate ETA for route stops
     */
    List<RouteStopETADTO> calculateETAForStops(Long busId);

    /**
     * Check for route deviations
     */
    boolean checkForDeviation(Long busId, Long routeId);

    /**
     * Get average speed for a bus
     */
    Double getAverageSpeed(Long busId, int minutes);
}