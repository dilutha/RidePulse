package com.ridepulse.backend.repository;

import com.ridepulse.backend.entity.Bus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * OOP Abstraction: All bus queries — owner-scoped for security.
 * Encapsulation: owner filtering baked into queries to prevent data leaks.
 * Used by: BusManagementServiceImpl, WelfareServiceImpl, DashboardServiceImpl
 */
@Repository
public interface BusRepository extends JpaRepository<Bus, Integer> {

    // Used by: BusManagementServiceImpl.getBusesByOwner() — owner's active fleet
    List<Bus> findByOwner_OwnerIdAndIsActiveTrueOrderByBusNumber(Integer ownerId);

    // Used by: BusManagementServiceImpl — same but including inactive (for reports)
    List<Bus> findByOwner_OwnerId(Integer ownerId);

    // Used by: WelfareServiceImpl.processMonthlyWelfare() — all active buses
    List<Bus> findByIsActiveTrue();

    // Used by: prediction capacity lookup and demo route flow
    List<Bus> findByRoute_RouteId(Integer routeId);

    // Used by: BusManagementServiceImpl.addBus() — check number uniqueness
    boolean existsByBusNumber(String busNumber);

    // Used by: BusManagementServiceImpl.addBus() — check reg number uniqueness
    boolean existsByRegistrationNumber(String registrationNumber);

    // Used by: BusManagementServiceImpl.findBusOwnedBy() — security check
    Optional<Bus> findByBusIdAndOwner_OwnerId(Integer busId, Integer ownerId);

    // Used by: DashboardServiceImpl — count active buses per owner
    long countByOwner_OwnerIdAndIsActiveTrue(Integer ownerId);

    // Used by: GPS tracking — find bus by number (used by GPS device to report in)
    Optional<Bus> findByBusNumber(String busNumber);
}
