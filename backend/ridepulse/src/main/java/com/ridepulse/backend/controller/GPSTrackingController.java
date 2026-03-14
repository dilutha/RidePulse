package com.ridepulse.backend.controller;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.service.GPSTrackingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * GPS Tracking Controller
 *
 * PRESENTATION LAYER (OOP Concept):
 * Handles HTTP requests for GPS tracking
 *
 * REST API ENDPOINTS:
 * - POST /api/gps - Record GPS data
 * - GET /api/gps/bus/{busId}/latest - Get latest GPS data
 * - GET /api/gps/bus/{busId}/history - Get GPS history
 * - GET /api/gps/buses/active - Get all active bus locations
 * - GET /api/gps/route/{routeId}/buses - Get buses on route
 * - GET /api/gps/bus/{busId}/eta - Get ETA for stops
 */
@RestController
@RequestMapping("/api/gps")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class GPSTrackingController {

    private final GPSTrackingService gpsTrackingService;

    /**
     * Record GPS data
     *
     * POST /api/gps
     */
    @PostMapping
    public ResponseEntity<GPSDataDTO> recordGPSData(
            @Valid @RequestBody CreateGPSDataRequest request) {

        log.info("Received GPS data for bus ID: {}", request.getBusId());

        GPSDataDTO result = gpsTrackingService.recordGPSData(request);

        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * Get latest GPS data for a bus
     *
     * GET /api/gps/bus/{busId}/latest
     */
    @GetMapping("/bus/{busId}/latest")
    public ResponseEntity<GPSDataDTO> getLatestGPSData(@PathVariable Long busId) {

        GPSDataDTO result = gpsTrackingService.getLatestGPSData(busId);

        return ResponseEntity.ok(result);
    }

    /**
     * Get GPS history for a bus
     *
     * GET /api/gps/bus/{busId}/history?limit=50
     */
    @GetMapping("/bus/{busId}/history")
    public ResponseEntity<List<GPSDataDTO>> getGPSHistory(
            @PathVariable Long busId,
            @RequestParam(defaultValue = "50") int limit) {

        List<GPSDataDTO> history = gpsTrackingService.getGPSHistory(busId, limit);

        return ResponseEntity.ok(history);
    }

    /**
     * Get GPS data within time range
     *
     * GET /api/gps/bus/{busId}/range?start=2024-02-15T08:00:00&end=2024-02-15T18:00:00
     */
    @GetMapping("/bus/{busId}/range")
    public ResponseEntity<List<GPSDataDTO>> getGPSDataInRange(
            @PathVariable Long busId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {

        List<GPSDataDTO> data = gpsTrackingService.getGPSDataInTimeRange(busId, start, end);

        return ResponseEntity.ok(data);
    }

    /**
     * Get all active bus locations
     *
     * GET /api/gps/buses/active
     */
    @GetMapping("/buses/active")
    public ResponseEntity<List<BusLocationDTO>> getAllActiveBusLocations() {

        List<BusLocationDTO> locations = gpsTrackingService.getAllActiveBusLocations();

        return ResponseEntity.ok(locations);
    }

    /**
     * Get bus locations for a specific route
     *
     * GET /api/gps/route/{routeId}/buses
     */
    @GetMapping("/route/{routeId}/buses")
    public ResponseEntity<List<BusLocationDTO>> getBusLocationsByRoute(
            @PathVariable Long routeId) {

        List<BusLocationDTO> locations = gpsTrackingService.getBusLocationsByRoute(routeId);

        return ResponseEntity.ok(locations);
    }

    /**
     * Get ETA for route stops
     *
     * GET /api/gps/bus/{busId}/eta
     */
    @GetMapping("/bus/{busId}/eta")
    public ResponseEntity<List<RouteStopETADTO>> calculateETA(@PathVariable Long busId) {

        List<RouteStopETADTO> etaList = gpsTrackingService.calculateETAForStops(busId);

        return ResponseEntity.ok(etaList);
    }

    /**
     * Check for route deviation
     *
     * GET /api/gps/bus/{busId}/route/{routeId}/deviation
     */
    @GetMapping("/bus/{busId}/route/{routeId}/deviation")
    public ResponseEntity<Boolean> checkDeviation(
            @PathVariable Long busId,
            @PathVariable Long routeId) {

        boolean hasDeviation = gpsTrackingService.checkForDeviation(busId, routeId);

        return ResponseEntity.ok(hasDeviation);
    }

    /**
     * Get average speed
     *
     * GET /api/gps/bus/{busId}/speed?minutes=30
     */
    @GetMapping("/bus/{busId}/speed")
    public ResponseEntity<Double> getAverageSpeed(
            @PathVariable Long busId,
            @RequestParam(defaultValue = "30") int minutes) {

        Double avgSpeed = gpsTrackingService.getAverageSpeed(busId, minutes);

        return ResponseEntity.ok(avgSpeed != null ? avgSpeed : 0.0);
    }
}