package com.ridepulse.backend.repository;

// ============================================================
// StaffRepository.java — UPDATED
// Added findByBusOwner_OwnerId() using the direct owner FK.
// This replaces the join-through-assignments query so unassigned
// staff still appear in the bus owner's staff list.
// ============================================================

import com.ridepulse.backend.entity.Staff;
import com.ridepulse.backend.entity.Staff.StaffType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface StaffRepository extends JpaRepository<Staff, Integer> {

    // Used by: CustomUserDetailsService — look up staff by their user account
    Optional<Staff> findByUser_UserId(UUID userId);

    // Used by: various services — look up staff by email
    @Query("SELECT s FROM Staff s WHERE s.user.email = :email")
    Optional<Staff> findByUserEmail(@Param("email") String email);

    // NEW: Uses direct owner_id FK — returns ALL staff under this owner
    // including those not yet assigned to a bus.
    // OOP Encapsulation: query details hidden from callers.
    List<Staff> findByBusOwner_OwnerId(Integer ownerId);

    // NEW: Filter by type via direct owner FK
    List<Staff> findByBusOwner_OwnerIdAndStaffType(
            Integer ownerId, StaffType staffType);

    // LEGACY: kept for backward compatibility — uses join through assignments
    // Note: only returns staff WITH a current bus assignment
    @Query("""
        SELECT DISTINCT s FROM Staff s
        JOIN StaffBusAssignment a ON a.staff = s
        JOIN Bus b ON a.bus = b
        WHERE b.owner.ownerId = :ownerId
          AND a.isCurrent = true
        ORDER BY s.staffType, s.user.fullName
        """)
    List<Staff> findAllByOwnerId(@Param("ownerId") Integer ownerId);

    // Used by: validation — prevent duplicate employee IDs
    boolean existsByEmployeeId(String employeeId);
}
