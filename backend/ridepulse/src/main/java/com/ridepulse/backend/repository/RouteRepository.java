package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.Route;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Route Repository
 */
@Repository
public interface RouteRepository extends JpaRepository<Route, Long> {

    Optional<Route> findByRouteNumber(String routeNumber);

    List<Route> findByIsActiveTrue();

    @Query("SELECT r FROM Route r WHERE r.isActive = true ORDER BY r.routeNumber")
    List<Route> findAllActiveRoutes();
}