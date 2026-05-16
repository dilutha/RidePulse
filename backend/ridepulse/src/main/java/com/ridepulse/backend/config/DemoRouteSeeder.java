package com.ridepulse.backend.config;

import com.ridepulse.backend.entity.Route;
import com.ridepulse.backend.entity.RouteStop;
import com.ridepulse.backend.repository.RouteRepository;
import com.ridepulse.backend.repository.RouteStopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

//@Component
@RequiredArgsConstructor
public class DemoRouteSeeder implements ApplicationRunner {

    private final RouteRepository routeRepo;
    private final RouteStopRepository stopRepo;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        Route route = routeRepo.findByRouteNumber("138")
                .orElseGet(() -> routeRepo.save(Route.builder()
                        .routeNumber("138")
                        .routeName("Colombo Fort - Homagama")
                        .startLocation("Colombo Fort")
                        .endLocation("Homagama")
                        .totalDistanceKm(new BigDecimal("22.50"))
                        .baseFare(new BigDecimal("30.00"))
                        .isActive(true)
                        .build()));

        route.setRouteName("Colombo Fort - Homagama");
        route.setStartLocation("Colombo Fort");
        route.setEndLocation("Homagama");
        route.setTotalDistanceKm(new BigDecimal("22.50"));
        route.setBaseFare(new BigDecimal("30.00"));
        route.setIsActive(true);
        routeRepo.save(route);

        List<StopSeed> stops = List.of(
                new StopSeed("Colombo Fort", 1, "6.93440000", "79.84280000"),
                new StopSeed("Nugegoda", 2, "6.87210000", "79.88900000"),
                new StopSeed("Maharagama", 3, "6.84800000", "79.92650000"),
                new StopSeed("Homagama", 4, "6.84050000", "80.00240000")
        );

        List<RouteStop> existing = stopRepo.findByRoute_RouteIdOrderByStopSequence(route.getRouteId());
        for (int i = 0; i < existing.size(); i++) {
            existing.get(i).setStopSequence(100 + i);
        }
        stopRepo.saveAll(existing);
        stopRepo.flush();

        stops.forEach(s -> {
            RouteStop stop = existing.stream()
                    .filter(e -> e.getStopName().equalsIgnoreCase(s.name()))
                    .findFirst()
                    .orElseGet(() -> RouteStop.builder()
                            .route(route)
                            .stopName(s.name())
                            .build());
            stop.setStopSequence(s.sequence());
            stop.setLatitude(new BigDecimal(s.latitude()));
            stop.setLongitude(new BigDecimal(s.longitude()));
            stopRepo.save(stop);
        });
    }

    private record StopSeed(
            String name,
            Integer sequence,
            String latitude,
            String longitude) {
    }
}
