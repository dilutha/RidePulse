package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.model.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.GPSTrackingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * GPS Tracking Service Implementation
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates GPS tracking business logic
 *
 * SINGLE RESPONSIBILITY (SOLID):
 * Handles only GPS tracking operations
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class GPSTrackingServiceImpl implements GPSTrackingService {

    private final GPSDataRepository gpsDataRepository;
    private final BusRepository busRepository;
    private final RouteRepository routeRepository;
    private final RouteStopRepository routeStopRepository;

    private static final double DEVIATION_THRESHOLD_KM = 0.5; // 500 meters
    private static final double DEFAULT_AVERAGE_SPEED = 40.0; // km/h

    /**
     * Record new GPS data point
     *
     * POLYMORPHISM: Overloaded method behavior based on input
     */
    @Override
    public GPSDataDTO recordGPSData(CreateGPSDataRequest request) {
        log.info("Recording GPS data for bus ID: {}", request.getBusId());

        // Validate bus exists
        Bus bus = busRepository.findById(request.getBusId())
                .orElseThrow(() -> new RuntimeException("Bus not found with ID: " + request.getBusId()));

        // Create GPS data entity
        GPSData gpsData = new GPSData();
        gpsData.setBusId(request.getBusId());
        gpsData.setLatitude(request.getLatitude());
        gpsData.setLongitude(request.getLongitude());
        gpsData.setTimestamp(request.getTimestamp() != null
                ? request.getTimestamp()
                : LocalDateTime.now());
        gpsData.setSpeed(request.getSpeed());
        gpsData.setHeading(request.getHeading());
        gpsData.setAccuracy(request.getAccuracy());
        gpsData.setCrowdLevel(request.getCrowdLevel());

        // Validate coordinates
        if (!gpsData.isValidCoordinates()) {
            throw new RuntimeException("Invalid GPS coordinates");
        }

        // Calculate speed if not provided
        if (gpsData.getSpeed() == null) {
            Optional<GPSData> previousData = gpsDataRepository.findLatestByBusId(bus.getBusId());
            if (previousData.isPresent()) {
                Double calculatedSpeed = gpsData.calculateSpeed(previousData.get());
                gpsData.setSpeed(calculatedSpeed);
            }
        }

        // Check for route deviation
        if (bus.getRouteId() != null) {
            boolean isDeviation = checkForDeviation(bus.getBusId(), bus.getRouteId());
            gpsData.setIsDeviation(isDeviation);
        }

        // Save GPS data
        GPSData savedData = gpsDataRepository.save(gpsData);

        // Update bus current location
        bus.updateLocation(savedData.getLatitude(), savedData.getLongitude());
        busRepository.save(bus);

        log.info("GPS data recorded successfully for bus: {}", bus.getBusNumber());

        return convertToDTO(savedData, bus);
    }

    /**
     * Get latest GPS data for a bus
     */
    @Override
    @Transactional(readOnly = true)
    public GPSDataDTO getLatestGPSData(Long busId) {
        Bus bus = busRepository.findById(busId)
                .orElseThrow(() -> new RuntimeException("Bus not found"));

        GPSData gpsData = gpsDataRepository.findLatestByBusId(busId)
                .orElseThrow(() -> new RuntimeException("No GPS data found for bus"));

        return convertToDTO(gpsData, bus);
    }

    /**
     * Get GPS history for a bus
     */
    @Override
    @Transactional(readOnly = true)
    public List<GPSDataDTO> getGPSHistory(Long busId, int limit) {
        Bus bus = busRepository.findById(busId)
                .orElseThrow(() -> new RuntimeException("Bus not found"));

        List<GPSData> history = gpsDataRepository.findLatestNByBusId(busId, limit);

        return history.stream()
                .map(gps -> convertToDTO(gps, bus))
                .collect(Collectors.toList());
    }

    /**
     * Get GPS data within time range
     */
    @Override
    @Transactional(readOnly = true)
    public List<GPSDataDTO> getGPSDataInTimeRange(
            Long busId,
            LocalDateTime startTime,
            LocalDateTime endTime) {

        Bus bus = busRepository.findById(busId)
                .orElseThrow(() -> new RuntimeException("Bus not found"));

        List<GPSData> dataList = gpsDataRepository.findByBusIdAndTimestampBetween(
                busId, startTime, endTime
        );

        return dataList.stream()
                .map(gps -> convertToDTO(gps, bus))
                .collect(Collectors.toList());
    }

    /**
     * Get all active bus locations
     */
    @Override
    @Transactional(readOnly = true)
    public List<BusLocationDTO> getAllActiveBusLocations() {
        List<Bus> activeBuses = busRepository.findAllWithGPS();
        List<BusLocationDTO> locations = new ArrayList<>();

        for (Bus bus : activeBuses) {
            Optional<GPSData> latestGPS = gpsDataRepository.findLatestByBusId(bus.getBusId());

            if (latestGPS.isPresent()) {
                locations.add(convertToBusLocationDTO(bus, latestGPS.get()));
            }
        }

        return locations;
    }

    /**
     * Get bus locations for a specific route
     */
    @Override
    @Transactional(readOnly = true)
    public List<BusLocationDTO> getBusLocationsByRoute(Long routeId) {
        List<Bus> buses = busRepository.findActiveByRouteId(routeId);
        List<BusLocationDTO> locations = new ArrayList<>();

        for (Bus bus : buses) {
            Optional<GPSData> latestGPS = gpsDataRepository.findLatestByBusId(bus.getBusId());

            if (latestGPS.isPresent()) {
                locations.add(convertToBusLocationDTO(bus, latestGPS.get()));
            }
        }

        return locations;
    }

    /**
     * Calculate ETA for route stops
     *
     * BUSINESS LOGIC: Complex ETA calculation
     */
    @Override
    @Transactional(readOnly = true)
    public List<RouteStopETADTO> calculateETAForStops(Long busId) {
        Bus bus = busRepository.findById(busId)
                .orElseThrow(() -> new RuntimeException("Bus not found"));

        if (bus.getRouteId() == null) {
            throw new RuntimeException("Bus is not assigned to a route");
        }

        GPSData currentLocation = gpsDataRepository.findLatestByBusId(busId)
                .orElseThrow(() -> new RuntimeException("No GPS data available"));

        List<RouteStop> stops = routeStopRepository.findByRouteIdOrderByStopSequence(
                bus.getRouteId()
        );

        // Get average speed (use recent data or default)
        Double avgSpeed = getAverageSpeed(busId, 30);
        if (avgSpeed == null || avgSpeed < 5.0) {
            avgSpeed = DEFAULT_AVERAGE_SPEED;
        }

        List<RouteStopETADTO> etaList = new ArrayList<>();
        LocalDateTime currentTime = LocalDateTime.now();

        for (RouteStop stop : stops) {
            double distanceKm = currentLocation.calculateDistanceTo(
                    stop.getLatitude(),
                    stop.getLongitude()
            );

            // Calculate ETA in minutes
            int etaMinutes = (int) Math.ceil((distanceKm / avgSpeed) * 60);

            // Calculate estimated arrival time
            LocalDateTime arrivalTime = currentTime.plusMinutes(etaMinutes);
            String arrivalTimeStr = arrivalTime.toLocalTime()
                    .format(DateTimeFormatter.ofPattern("HH:mm"));

            RouteStopETADTO dto = RouteStopETADTO.builder()
                    .stopId(stop.getStopId())
                    .stopName(stop.getStopName())
                    .stopSequence(stop.getStopSequence())
                    .latitude(stop.getLatitude())
                    .longitude(stop.getLongitude())
                    .distanceFromBusKm(Math.round(distanceKm * 100.0) / 100.0)
                    .estimatedArrivalMinutes(etaMinutes)
                    .estimatedArrivalTime(arrivalTimeStr)
                    .isPassed(false) // TODO: Implement logic to track passed stops
                    .build();

            etaList.add(dto);
        }

        return etaList;
    }

    /**
     * Check for route deviations
     *
     * BUSINESS LOGIC: Deviation detection algorithm
     */
    @Override
    @Transactional(readOnly = true)
    public boolean checkForDeviation(Long busId, Long routeId) {
        Optional<GPSData> latestGPS = gpsDataRepository.findLatestByBusId(busId);

        if (latestGPS.isEmpty()) {
            return false;
        }

        GPSData currentLocation = latestGPS.get();
        List<RouteStop> stops = routeStopRepository.findByRouteIdOrderByStopSequence(routeId);

        if (stops.isEmpty()) {
            return false;
        }

        // Find minimum distance to any stop
        double minDistance = stops.stream()
                .mapToDouble(stop -> currentLocation.calculateDistanceTo(
                        stop.getLatitude(),
                        stop.getLongitude()
                ))
                .min()
                .orElse(Double.MAX_VALUE);

        // Check if bus is too far from route
        boolean isDeviation = minDistance > DEVIATION_THRESHOLD_KM;

        if (isDeviation) {
            log.warn("Route deviation detected for bus ID: {}. Distance: {} km",
                    busId, minDistance);
        }

        return isDeviation;
    }

    /**
     * Get average speed for a bus
     */
    @Override
    @Transactional(readOnly = true)
    public Double getAverageSpeed(Long busId, int minutes) {
        LocalDateTime since = LocalDateTime.now().minusMinutes(minutes);
        return gpsDataRepository.findAverageSpeedByBusIdSince(busId, since);
    }

    /**
     * ENCAPSULATION - Private helper method
     * Convert entity to DTO
     */
    private GPSDataDTO convertToDTO(GPSData gpsData, Bus bus) {
        String status = determineStatus(gpsData, bus);

        return GPSDataDTO.builder()
                .gpsId(gpsData.getGpsId())
                .busId(gpsData.getBusId())
                .busNumber(bus.getBusNumber())
                .latitude(gpsData.getLatitude())
                .longitude(gpsData.getLongitude())
                .timestamp(gpsData.getTimestamp())
                .speed(gpsData.getSpeed())
                .heading(gpsData.getHeading())
                .accuracy(gpsData.getAccuracy())
                .crowdLevel(gpsData.getCrowdLevel())
                .isDeviation(gpsData.getIsDeviation())
                .status(status)
                .build();
    }

    /**
     * Convert to Bus Location DTO
     */
    private BusLocationDTO convertToBusLocationDTO(Bus bus, GPSData gpsData) {
        Route route = null;
        if (bus.getRouteId() != null) {
            route = routeRepository.findById(bus.getRouteId()).orElse(null);
        }

        String status = determineMovementStatus(gpsData);

        return BusLocationDTO.builder()
                .busId(bus.getBusId())
                .busNumber(bus.getBusNumber())
                .routeId(bus.getRouteId())
                .routeNumber(route != null ? route.getRouteNumber() : null)
                .routeName(route != null ? route.getRouteName() : null)
                .latitude(gpsData.getLatitude())
                .longitude(gpsData.getLongitude())
                .speed(gpsData.getSpeed())
                .heading(gpsData.getHeading())
                .lastUpdate(gpsData.getTimestamp())
                .crowdLevel(gpsData.getCrowdLevel())
                .status(status)
                .hasRecentData(bus.hasRecentGPSData())
                .build();
    }

    /**
     * Determine bus status
     */
    private String determineStatus(GPSData gpsData, Bus bus) {
        if (!bus.hasRecentGPSData()) {
            return "inactive";
        }

        if (gpsData.getIsDeviation() != null && gpsData.getIsDeviation()) {
            return "deviation";
        }

        return "active";
    }

    /**
     * Determine movement status
     */
    private String determineMovementStatus(GPSData gpsData) {
        long minutesSinceUpdate = java.time.Duration.between(
                gpsData.getTimestamp(),
                LocalDateTime.now()
        ).toMinutes();

        if (minutesSinceUpdate > 5) {
            return "offline";
        }

        if (gpsData.getSpeed() != null && gpsData.getSpeed() < 5.0) {
            return "stopped";
        }

        return "moving";
    }
}