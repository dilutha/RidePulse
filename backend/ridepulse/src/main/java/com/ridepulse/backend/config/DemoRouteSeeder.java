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

        List<StopSeed> stops = List.of(
                new StopSeed("Fort", 1, "6.93440000", "79.84280000"),
                new StopSeed("Maradana", 2, "6.92710000", "79.86120000"),
                new StopSeed("Borella", 3, "6.91470000", "79.87780000"),
                new StopSeed("Peliyagoda", 4, "6.96030000", "79.88300000"),
                new StopSeed("Dematagoda", 5, "6.93770000", "79.87860000"),
                new StopSeed("Kiribathgoda", 6, "6.97900000", "79.92970000")
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
