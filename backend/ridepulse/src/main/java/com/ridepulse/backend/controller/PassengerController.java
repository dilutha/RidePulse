package com.ridepulse.backend.controller;


import com.ridepulse.backend.dto.*;
import com.ridepulse.backend.service.PassengerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/passenger")
@RequiredArgsConstructor
public class PassengerController {

    private final PassengerService passengerService;  // Abstraction: interface only

    // ── Route Search ──────────────────────────────────────────

    /**
     * GET /api/v1/passenger/routes/search?q=Negombo
     * Search routes by number, name, start, or end location.
     * Public — no login required.
     */
    @GetMapping("/routes/search")
    public ResponseEntity<List<RouteSearchResultDTO>> searchRoutes(
            @RequestParam(required = false) String q) {
        return ResponseEntity.ok(passengerService.searchRoutes(q));
    }

    /**
     * GET /api/v1/passenger/routes
     * Browse all active routes.
     * Public — no login required.
     */
    @GetMapping("/routes")
    public ResponseEntity<List<RouteSearchResultDTO>> getAllRoutes() {
        return ResponseEntity.ok(passengerService.getAllRoutes());
    }

    // ── Active Buses on Route ─────────────────────────────────

    /**
     * GET /api/v1/passenger/routes/{routeId}/buses
     * Returns all buses currently in-progress on this route
     * with their live GPS location and crowd level.
     * Public — no login required.
     */
    @GetMapping("/routes/{routeId}/buses")
    public ResponseEntity<List<ActiveBusDTO>> getActiveBuses(
            @PathVariable Integer routeId) {
        return ResponseEntity.ok(
            passengerService.getActiveBusesOnRoute(routeId));
    }

    // ── Single Bus Live Detail ────────────────────────────────

    /**
     * GET /api/v1/passenger/buses/{busId}/live
     * Full live detail for one bus: GPS position, crowd level,
     * route stops (for map polyline), trip context.
     * Public — no login required.
     */
    @GetMapping("/buses/{busId}/live")
    public ResponseEntity<BusLiveDetailDTO> getBusLive(
            @PathVariable Integer busId) {
        return ResponseEntity.ok(
            passengerService.getBusLiveDetail(busId));
    }

    // ── Crowd Prediction ──────────────────────────────────────

    /**
     * GET /api/v1/passenger/routes/{routeId}/predictions?date=2025-01-15
     * Returns LSTM crowd predictions for the route on a given date.
     * If no prediction data exists yet (LSTM not trained),
     * returns { hasData: false } — Flutter shows "Coming Soon" UI.
     * Public — no login required.
     */
    @GetMapping("/routes/{routeId}/predictions")
    public ResponseEntity<RoutePredictionScheduleDTO> getCrowdPredictions(
            @PathVariable Integer routeId,
            @RequestParam(required = false) String date) {
        return ResponseEntity.ok(
            passengerService.getCrowdPredictions(routeId, date));
    }

    @GetMapping("/routes/{routeId}/stops")
    public ResponseEntity<List<StopDTO>> getRouteStops(
            @PathVariable Integer routeId) {
        return ResponseEntity.ok(passengerService.getRouteStops(routeId));
    }

    @PostMapping("/routes/{routeId}/predictions/single")
    public ResponseEntity<CrowdPredictionDTO> getSingleCrowdPrediction(
            @PathVariable Integer routeId,
            @RequestBody(required = false) java.util.Map<String, String> body) {
        return ResponseEntity.ok(passengerService.getSingleCrowdPrediction(
            routeId,
            body != null ? body.get("date") : null,
            body != null ? body.get("time") : null,
            body != null ? body.get("location") : null));
    }
}
