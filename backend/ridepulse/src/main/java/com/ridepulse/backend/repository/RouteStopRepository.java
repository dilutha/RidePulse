package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.RouteStop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * RouteStop Repository
 */
@Repository
public interface RouteStopRepository extends JpaRepository<RouteStop, Long> {

    @Query("SELECT rs FROM RouteStop rs WHERE rs.route.routeId = :routeId " +
            "ORDER BY rs.stopSequence")
    List<RouteStop> findByRouteIdOrderByStopSequence(@Param("routeId") Long routeId);

    @Query("SELECT rs FROM RouteStop rs WHERE rs.route.routeId = :routeId " +
            "AND rs.stopSequence = :sequence")
    RouteStop findByRouteIdAndStopSequence(
            @Param("routeId") Long routeId,
            @Param("sequence") Integer sequence
    );
}