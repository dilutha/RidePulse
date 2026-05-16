package com.ridepulse.backend.prediction;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ridepulse.backend.dto.CrowdPredictionDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.ResourceAccessException;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class LstmPredictionClient {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    // Injected from application.yml — Encapsulation: URL not hardcoded
    @Value("${lstm.service.url:http://localhost:8000}")
    private String lstmServiceUrl;

    @Value("${lstm.service.enabled:true}")
    private boolean enabled;

    /**
     * Calls /health on Python service — Spring Boot checks this
     * before attempting predictions.
     */
    public boolean isServiceHealthy() {
        if (!enabled) return false;
        try {
            ResponseEntity<String> res = restTemplate.getForEntity(
                    lstmServiceUrl + "/health", String.class);
            return res.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.warn("LSTM service health check failed: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Calls /predict/batch — generates full-day predictions for all routes.
     * OOP Abstraction: returns typed LstmBatchResponse, hiding HTTP.
     * Returns null if service unavailable.
     */
    public LstmBatchResponse requestBatchPredictions(
            List<Integer> routeIds,
            Map<String, Integer> busCapacities,
            String date,
            String weather,
            Double rain,
            String trafficLevel) {

        if (!enabled) {
            log.info("LSTM service disabled — skipping predictions.");
            return null;
        }

        LstmBatchRequest request = LstmBatchRequest.builder()
                .routeIds(routeIds)
                .busCapacities(busCapacities)
                .date(date)
                .weather(weather)
                .rain(rain)
                .trafficLevel(trafficLevel)
                .build();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<LstmBatchResponse> res = restTemplate.exchange(
                    lstmServiceUrl + "/predict/batch",
                    HttpMethod.POST,
                    new HttpEntity<>(request, headers),
                    LstmBatchResponse.class
            );
            log.info("LSTM batch prediction received: {} slots",
                    res.getBody() != null
                            ? res.getBody().getTotalPredictions() : 0);
            return res.getBody();

        } catch (ResourceAccessException e) {
            log.error("LSTM service unreachable at {}: {}",
                    lstmServiceUrl, e.getMessage());
            return null;
        } catch (Exception e) {
            log.error("LSTM batch prediction call failed: {}", e.getMessage(), e);
            return null;
        }
    }

    public CrowdPredictionDTO requestSinglePrediction(
            Integer routeId,
            String routeName,
            String targetDateTime,
            Integer busCapacity,
            String weather,
            Double rain,
            String trafficLevel,
            String location) {

        if (!enabled) {
            log.info("LSTM service disabled — skipping single prediction.");
            return null;
        }

        Map<String, Object> request = Map.of(
                "route_id", routeId,
                "target_datetime", targetDateTime,
                "bus_capacity", busCapacity,
                "weather", weather,
                "rain", rain,
                "traffic_level", trafficLevel,
                "location", location != null ? location : ""
        );

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            log.info("LSTM single prediction request: {}",
                    objectMapper.writeValueAsString(request));
            ResponseEntity<Map> res = restTemplate.exchange(
                    lstmServiceUrl + "/predict/single",
                    HttpMethod.POST,
                    new HttpEntity<>(request, headers),
                    Map.class
            );
            Map<?, ?> body = res.getBody();
            if (body == null) return null;

            return CrowdPredictionDTO.builder()
                    .routeId(routeId)
                    .routeName(routeName)
                    .predictionDate(String.valueOf(body.get("prediction_date")))
                    .timeSlot(String.valueOf(body.get("time_slot")))
                    .predictedCount(asDouble(body.get("predicted_count")))
                    .predictedPercentage(asDouble(body.get("predicted_percentage")))
                    .predictedCategory(String.valueOf(body.get("predicted_category")))
                    .confidenceScore(asDouble(body.get("confidence_score")))
                    .modelVersion(String.valueOf(body.get("model_version")))
                    .isAvailable(true)
                    .build();

        } catch (ResourceAccessException e) {
            log.error("LSTM service unreachable at {}: {}",
                    lstmServiceUrl, e.getMessage());
            return null;
        } catch (Exception e) {
            log.error("LSTM single prediction call failed: {}", e.getMessage(), e);
            return null;
        }
    }

    private Double asDouble(Object value) {
        return value instanceof Number n ? n.doubleValue() : null;
    }
}
