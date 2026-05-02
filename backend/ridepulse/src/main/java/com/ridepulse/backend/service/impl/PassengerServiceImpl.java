package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.entity.*;
import com.ridepulse.backend.prediction.LstmPredictionClient;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.PassengerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PassengerServiceImpl implements PassengerService {

    // Encapsulation: all repos private
    private final RouteRepository     routeRepo;
    private final RouteStopRepository stopRepo;
    private final BusTripRepository   tripRepo;
    private final GpsTrackingRepository gpsRepo;
    private final CrowdLevelRepository  crowdRepo;
    private final CrowdPredictionRepository predictionRepo;
    private final BusRepository       busRepo;
    private final LstmPredictionClient lstmClient;

    private static final DateTimeFormatter DT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // ── Search ────────────────────────────────────────────────

    /**
     * Searches active routes by route number OR route name.
     * OOP Encapsulation: query logic stays in service — not in controller.
     */
    @Override
    public List<RouteSearchResultDTO> searchRoutes(String query) {
        return routeRepo.findByIsActiveTrueOrderByRouteNumber()
            .stream()
            .filter(r -> query == null || query.isBlank()
                || r.getRouteNumber().toLowerCase().contains(query.toLowerCase())
                || r.getRouteName().toLowerCase().contains(query.toLowerCase())
                || r.getStartLocation().toLowerCase().contains(query.toLowerCase())
                || r.getEndLocation().toLowerCase().contains(query.toLowerCase()))
            .map(r -> toRouteSearchResult(r))
            .collect(Collectors.toList());
    }

    @Override
    public List<RouteSearchResultDTO> getAllRoutes() {
        return routeRepo.findByIsActiveTrueOrderByRouteNumber()
            .stream()
            .map(r -> toRouteSearchResult(r))
            .collect(Collectors.toList());
    }

    // ── Active buses on a route ───────────────────────────────

    /**
     * Returns all buses currently running on a route with live GPS + crowd.
     * OOP Abstraction: joins GpsTracking + CrowdLevel behind one DTO.
     */
    @Override
    public List<ActiveBusDTO> getActiveBusesOnRoute(Integer routeId) {
        return tripRepo.findActiveTripsByRoute(routeId)
            .stream()
            .map(trip -> buildActiveBusDTO(trip))
            .collect(Collectors.toList());
    }

    // ── Single bus live detail ────────────────────────────────

    @Override
    public BusLiveDetailDTO getBusLiveDetail(Integer busId) {
        Bus bus = busRepo.findById(busId)
            .orElseThrow(() -> new RuntimeException("Bus not found: " + busId));

        // Latest GPS point
        GpsTracking gps = gpsRepo.findLatestByBusId(busId).orElse(null);

        // Latest crowd level
        CrowdLevel crowd = crowdRepo.findLatestByBusId(busId).orElse(null);

        // Active trip
        BusTrip trip = tripRepo.findByBus_BusIdAndStatus(busId, "in_progress")
            .orElse(null);

        // Route stops for map polyline
        List<StopDTO> stops = bus.getRoute() != null
            ? stopRepo.findByRoute_RouteIdOrderByStopSequence(bus.getRoute().getRouteId())
                .stream()
                .map(s -> StopDTO.builder()
                    .stopId(s.getStopId())
                    .stopName(s.getStopName())
                    .stopSequence(s.getStopSequence())
                    .build())
                .collect(Collectors.toList())
            : List.of();

        return BusLiveDetailDTO.builder()
            .busId(bus.getBusId())
            .busNumber(bus.getBusNumber())
            .registrationNumber(bus.getRegistrationNumber())
            .capacity(bus.getCapacity())
            .routeId(bus.getRoute() != null ? bus.getRoute().getRouteId() : null)
            .routeName(bus.getRoute() != null ? bus.getRoute().getRouteName() : "N/A")
            .routeNumber(bus.getRoute() != null ? bus.getRoute().getRouteNumber() : "N/A")
            .stops(stops)
            .latitude(gps != null ? gps.getLatitude().doubleValue() : null)
            .longitude(gps != null ? gps.getLongitude().doubleValue() : null)
            .speedKmh(gps != null && gps.getSpeedKmh() != null
                ? gps.getSpeedKmh().doubleValue() : null)
            .heading(gps != null && gps.getHeading() != null
                ? gps.getHeading().doubleValue() : null)
            .lastUpdated(gps != null ? formatAge(gps.getRecordedAt()) : "Unknown")
            .passengerCount(crowd != null ? crowd.getPassengerCount() : 0)
            .capacityPercentage(crowd != null
                ? crowd.getCapacityPercentage().doubleValue() : 0.0)
            .crowdCategory(crowd != null ? crowd.getCrowdCategory() : "unknown")
            .tripId(trip != null ? trip.getTripId() : null)
            .tripStartedAt(trip != null && trip.getTripStart() != null
                ? trip.getTripStart().format(DT) : null)
            .build();
    }

    // ── Crowd Prediction ──────────────────────────────────────

    /**
     * Returns full day crowd prediction schedule for a route.
     * OOP Abstraction: if no LSTM data exists, returns placeholder with message.
     * Polymorphism: isAvailable flag drives UI rendering on the Flutter side.
     */
    @Override
    public RoutePredictionScheduleDTO getCrowdPredictions(
            Integer routeId, String date) {

        Route route = routeRepo.findById(routeId)
            .orElseThrow(() -> new RuntimeException("Route not found: " + routeId));

        LocalDate predDate = date != null
            ? LocalDate.parse(date)
            : LocalDate.now();

        List<CrowdPrediction> predictions =
            predictionRepo.findByRoute_RouteIdAndPredictionDateOrderByTimeSlot(
                routeId, predDate);

        if (predictions.isEmpty()) {
            // LSTM not yet trained — return placeholder
            return RoutePredictionScheduleDTO.builder()
                .routeId(routeId)
                .routeName(route.getRouteName())
                .date(predDate.toString())
                .hasData(false)
                .slots(List.of())
                .build();
        }

        List<CrowdPredictionDTO> slots = predictions.stream()
            .map(p -> CrowdPredictionDTO.builder()
                .routeId(routeId)
                .routeName(route.getRouteName())
                .predictionDate(p.getPredictionDate().toString())
                .timeSlot(p.getTimeSlot().toString())
                .predictedPercentage(p.getPredictedPercentage().doubleValue())
                .predictedCategory(p.getPredictedCategory())
                .confidenceScore(p.getConfidenceScore() != null
                    ? p.getConfidenceScore().doubleValue() : null)
                .modelVersion(p.getModelVersion())
                .isAvailable(true)
                .build())
            .collect(Collectors.toList());

        return RoutePredictionScheduleDTO.builder()
            .routeId(routeId)
            .routeName(route.getRouteName())
            .date(predDate.toString())
            .hasData(true)
            .slots(slots)
            .build();
    }

    @Override
    public CrowdPredictionDTO getSingleCrowdPrediction(
            Integer routeId, String date, String time, String location) {
        Route route = routeRepo.findById(routeId)
            .orElseThrow(() -> new RuntimeException("Route not found: " + routeId));

        boolean validLocation = location == null || location.isBlank()
            || stopRepo.findByRoute_RouteIdOrderByStopSequence(routeId).stream()
                .anyMatch(s -> s.getStopName().equalsIgnoreCase(location));
        if (!validLocation) {
            throw new RuntimeException("Selected location is not a stop on this route");
        }

        int capacity = (int) busRepo.findByRoute_RouteId(routeId).stream()
            .mapToInt(Bus::getCapacity)
            .average()
            .orElse(52);

        String target = (date != null && !date.isBlank() ? date : LocalDate.now().toString())
            + "T"
            + (time != null && !time.isBlank() ? time : "08:00")
            + ":00";

        CrowdPredictionDTO prediction = lstmClient.requestSinglePrediction(
            routeId, route.getRouteName(), target, capacity,
            "clear", 0.0, "medium");

        if (prediction != null) {
            prediction.setMessage(location != null && !location.isBlank()
                ? "Prediction for " + location
                : null);
            return prediction;
        }

        return CrowdPredictionDTO.builder()
            .routeId(routeId)
            .routeName(route.getRouteName())
            .predictionDate(target.substring(0, 10))
            .timeSlot(target.substring(11, 16))
            .predictedPercentage(0.0)
            .predictedCategory("unknown")
            .confidenceScore(0.0)
            .modelVersion("unavailable")
            .isAvailable(false)
            .message("LSTM prediction service is not available")
            .build();
    }

    @Override
    public List<StopDTO> getRouteStops(Integer routeId) {
        return stopRepo.findByRoute_RouteIdOrderByStopSequence(routeId)
            .stream()
            .map(s -> StopDTO.builder()
                .stopId(s.getStopId())
                .stopName(s.getStopName())
                .stopSequence(s.getStopSequence())
                .build())
            .collect(Collectors.toList());
    }

    // ── Private helpers (Encapsulation) ──────────────────────

    private RouteSearchResultDTO toRouteSearchResult(Route r) {
        long activeBuses = tripRepo.findActiveTripsByRoute(r.getRouteId()).size();
        return RouteSearchResultDTO.builder()
            .routeId(r.getRouteId())
            .routeNumber(r.getRouteNumber())
            .routeName(r.getRouteName())
            .startLocation(r.getStartLocation())
            .endLocation(r.getEndLocation())
            .totalDistanceKm(r.getTotalDistanceKm() != null
                ? r.getTotalDistanceKm().doubleValue() : null)
            .baseFare(r.getBaseFare().doubleValue())
            .activeBusCount((int) activeBuses)
            .build();
    }

    private ActiveBusDTO buildActiveBusDTO(BusTrip trip) {
        Bus bus = trip.getBus();

        GpsTracking gps   = gpsRepo.findLatestByBusId(bus.getBusId()).orElse(null);
        CrowdLevel  crowd = crowdRepo.findLatestByBusId(bus.getBusId()).orElse(null);

        return ActiveBusDTO.builder()
            .busId(bus.getBusId())
            .busNumber(bus.getBusNumber())
            .capacity(bus.getCapacity())
            .latitude(gps != null ? gps.getLatitude().doubleValue() : null)
            .longitude(gps != null ? gps.getLongitude().doubleValue() : null)
            .speedKmh(gps != null && gps.getSpeedKmh() != null
                ? gps.getSpeedKmh().doubleValue() : null)
            .lastUpdated(gps != null ? formatAge(gps.getRecordedAt()) : "No GPS data")
            .passengerCount(crowd != null ? crowd.getPassengerCount() : 0)
            .capacityPercentage(crowd != null
                ? crowd.getCapacityPercentage().doubleValue() : 0.0)
            .crowdCategory(crowd != null ? crowd.getCrowdCategory() : "unknown")
            .tripId(trip.getTripId())
            .tripStartedAt(trip.getTripStart() != null
                ? trip.getTripStart().format(DT) : null)
            .build();
    }

    /**
     * Encapsulation: human-readable age string — e.g. "2 mins ago"
     * Polymorphism: output string differs by duration length.
     */
    private String formatAge(LocalDateTime recorded) {
        if (recorded == null) return "Unknown";
        long seconds = Duration.between(recorded, LocalDateTime.now()).toSeconds();
        if (seconds < 60)  return "Just now";
        if (seconds < 3600) return (seconds / 60) + " mins ago";
        return (seconds / 3600) + " hrs ago";
    }
}
