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

@Component
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
                        .routeName("Fort - Kiribathgoda")
                        .startLocation("Fort")
                        .endLocation("Kiribathgoda")
                        .totalDistanceKm(new BigDecimal("12.50"))
                        .baseFare(new BigDecimal("30.00"))
                        .isActive(true)
                        .build()));

        if (!stopRepo.findByRoute_RouteIdOrderByStopSequence(route.getRouteId()).isEmpty()) {
            return;
        }

        List<StopSeed> stops = List.of(
                new StopSeed("Fort", 1, "6.93440000", "79.84280000"),
                new StopSeed("Maradana", 2, "6.92710000", "79.86120000"),
                new StopSeed("Borella", 3, "6.91470000", "79.87780000"),
                new StopSeed("Dematagoda", 4, "6.93770000", "79.87860000"),
                new StopSeed("Peliyagoda", 5, "6.96030000", "79.88300000"),
                new StopSeed("Kiribathgoda", 6, "6.97900000", "79.92970000")
        );

        stops.forEach(s -> stopRepo.save(RouteStop.builder()
                .route(route)
                .stopName(s.name())
                .stopSequence(s.sequence())
                .latitude(new BigDecimal(s.latitude()))
                .longitude(new BigDecimal(s.longitude()))
                .build()));
    }

    private record StopSeed(
            String name,
            Integer sequence,
            String latitude,
            String longitude) {
    }
}
