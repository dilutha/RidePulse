package com.ridepulse.backend.prediction;

import com.ridepulse.backend.entity.CrowdPrediction;
import com.ridepulse.backend.entity.Route;
import com.ridepulse.backend.repository.BusRepository;
import com.ridepulse.backend.repository.CrowdPredictionRepository;
import com.ridepulse.backend.repository.RouteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PredictionSchedulerService {

    // Encapsulation: all dependencies private
    private final LstmPredictionClient  lstmClient;
    private final RouteRepository       routeRepo;
    private final BusRepository         busRepo;
    private final CrowdPredictionRepository predictionRepo;

    /**
     * Runs every day at 00:30 — generates predictions for TODAY.
     * cron: second minute hour day month weekday
     * OOP Abstraction: callers never know predictions are
     * pre-generated; they just query crowd_predictions table.
     */
    @Scheduled(cron = "0 30 0 * * *")
    @Transactional
    public void generateDailyPredictions() {
        String today = LocalDate.now().toString();
        log.info("=== Generating crowd predictions for {} ===", today);
        generatePredictionsForDate(today, "clear", 0.0, "medium");
    }

    /**
     * Also runs at 06:00 to refresh with actual morning weather.
     * Polymorphism: same method, different weather context.
     */
    @Scheduled(cron = "0 0 6 * * *")
    @Transactional
    public void refreshMorningPredictions() {
        String today = LocalDate.now().toString();
        log.info("Refreshing morning predictions for {}", today);
        // In production: fetch actual weather from weather API here
        generatePredictionsForDate(today, "clear", 0.0, "medium");
    }

    /**
     * Manual trigger — called by AuthorityController
     * so admins can regenerate predictions on demand.
     */
    @Transactional
    public void generatePredictionsForDate(
            String date,
            String weather,
            Double rain,
            String trafficLevel) {

        // Step 1: Check LSTM service is up
        if (!lstmClient.isServiceHealthy()) {
            log.warn("LSTM service not healthy — aborting prediction job.");
            return;
        }

        // Step 2: Get all active routes
        List<Route> routes = routeRepo.findByIsActiveTrueOrderByRouteNumber();
        List<Integer> routeIds = routes.stream()
                .map(Route::getRouteId)
                .collect(Collectors.toList());

        if (routeIds.isEmpty()) {
            log.info("No active routes found.");
            return;
        }

        // Step 3: Build capacity map (route_id → average bus capacity on that route)
        // OOP Encapsulation: capacity lookup hidden in private method
        Map<String, Integer> capacities = buildCapacityMap(routes);

        // Step 4: Call Python LSTM service
        log.info("Requesting batch predictions: {} routes, date={}",
                routeIds.size(), date);
        LstmBatchResponse response = lstmClient.requestBatchPredictions(
                routeIds, capacities, date, weather, rain, trafficLevel);

        if (response == null) {
            log.error("Batch prediction request failed — no data to store.");
            return;
        }

        // Step 5: Persist results — upsert by (route_id, date, time_slot)
        int saved = 0;
        int errors = 0;

        for (LstmScheduleResponse schedule : response.getSchedules()) {
            LocalDate predDate = LocalDate.parse(schedule.getDate());

            // Delete stale predictions for this route+date before re-inserting
            predictionRepo.deleteByRoute_RouteIdAndPredictionDate(
                    schedule.getRouteId(), predDate);

            for (LstmSlot slot : schedule.getSlots()) {
                try {
                    Route route = routeRepo.findById(schedule.getRouteId())
                            .orElse(null);
                    if (route == null) continue;

                    CrowdPrediction prediction = CrowdPrediction.builder()
                            .route(route)
                            .predictionDate(predDate)
                            .timeSlot(LocalTime.parse(slot.getTimeSlot()))
                            .predictedPercentage(
                                    BigDecimal.valueOf(slot.getPredictedPercentage()))
                            .predictedCategory(slot.getPredictedCategory())
                            .confidenceScore(
                                    BigDecimal.valueOf(slot.getConfidenceScore()))
                            .modelVersion(slot.getModelVersion())
                            .build();

                    predictionRepo.save(prediction);
                    saved++;

                } catch (Exception e) {
                    log.error("Failed to save prediction slot {}: {}",
                            slot.getTimeSlot(), e.getMessage());
                    errors++;
                }
            }
        }

        log.info("=== Prediction job complete: {} saved, {} errors ===",
                saved, errors);
    }

    // ── Private helpers (Encapsulation) ──────────────────────

    /**
     * Builds route_id → bus capacity map.
     * Uses average capacity of all buses on each route.
     * Defaults to 52 if no buses found.
     */
    private Map<String, Integer> buildCapacityMap(List<Route> routes) {
        Map<String, Integer> map = new HashMap<>();
        for (Route route : routes) {
            List<com.ridepulse.backend.entity.Bus> buses =
                    busRepo.findByRoute_RouteId(route.getRouteId());
            int avgCapacity = buses.isEmpty() ? 52
                    : (int) buses.stream()
                    .mapToInt(com.ridepulse.backend.entity.Bus::getCapacity)
                    .average()
                    .orElse(52);
            map.put(String.valueOf(route.getRouteId()), avgCapacity);
        }
        return map;
    }
}
