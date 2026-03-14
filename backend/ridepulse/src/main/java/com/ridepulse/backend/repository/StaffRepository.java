package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.Staff;
import com.ridepulse.backend.model.StaffType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Staff Repository
 */
@Repository
public interface StaffRepository extends JpaRepository<Staff, UUID> {

    Optional<Staff> findByEmployeeId(String employeeId);

    Optional<Staff> findByUserId(UUID userId);

    List<Staff> findByStaffType(StaffType staffType);

    List<Staff> findByIsActiveTrue();

    boolean existsByEmployeeId(String employeeId);
}