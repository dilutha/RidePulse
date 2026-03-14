package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.Bus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Bus Repository
 */
@Repository
public interface BusRepository extends JpaRepository<Bus, Long> {

    Optional<Bus> findByBusNumber(String busNumber);

    List<Bus> findByRouteId(Long routeId);

    List<Bus> findByIsActiveTrue();

    @Query("SELECT b FROM Bus b WHERE b.routeId = :routeId AND b.isActive = true")
    List<Bus> findActiveByRouteId(@Param("routeId") Long routeId);

    @Query("SELECT b FROM Bus b WHERE b.hasGpsDevice = true AND b.isActive = true")
    List<Bus> findAllWithGPS();
}