package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.*;
import java.util.List;

public interface PassengerService {

    /** Search routes by number or name — partial match */
    List<RouteSearchResultDTO> searchRoutes(String query);

    /** Get all active routes (for browse/explore screen) */
    List<RouteSearchResultDTO> getAllRoutes();

    /** Active buses currently running on a route with live location + crowd */
    List<ActiveBusDTO> getActiveBusesOnRoute(Integer routeId);

    /** Full live detail for one bus — location + crowd + route stops */
    BusLiveDetailDTO getBusLiveDetail(Integer busId);

    /** Crowd prediction for a route on a given date (full day) */
    RoutePredictionScheduleDTO getCrowdPredictions(Integer routeId, String date);

    /** On-demand LSTM prediction for selected route/time/location */
    CrowdPredictionDTO getSingleCrowdPrediction(
            Integer routeId, String date, String time, String location);

    /** Public route stops for passenger prediction input */
    List<StopDTO> getRouteStops(Integer routeId);
}
