package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.WelfareRecord;
import com.ridepulse.backend.model.WelfareStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WelfareRecordRepository extends JpaRepository<WelfareRecord, Integer> {

    // Find welfare records by staff
    List<WelfareRecord> findByStaffUserIdOrderByRecordDateDesc(UUID staffId);

    // Find welfare records by bus
    List<WelfareRecord> findByBusBusIdOrderByRecordDateDesc(Integer busId);

    // Find welfare records by date range
    List<WelfareRecord> findByRecordDateBetween(LocalDate startDate, LocalDate endDate);

    // Find welfare records by status
    List<WelfareRecord> findByStatus(WelfareStatus status);

    // Find welfare record for specific staff on specific date
    Optional<WelfareRecord> findByStaffUserIdAndRecordDate(UUID staffId, LocalDate recordDate);

    // Calculate total welfare amount for a staff member
    @Query("SELECT SUM(w.welfareAmount) FROM WelfareRecord w WHERE w.staff.userId = :staffId")
    BigDecimal calculateTotalWelfare(@Param("staffId") UUID staffId);

    // Calculate total welfare within date range
    @Query("SELECT SUM(w.welfareAmount) FROM WelfareRecord w " +
            "WHERE w.staff.userId = :staffId " +
            "AND w.recordDate BETWEEN :startDate AND :endDate")
    BigDecimal calculateTotalWelfareByDateRange(
            @Param("staffId") UUID staffId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    // Get pending welfare records
    List<WelfareRecord> findByStatusOrderByRecordDateDesc(WelfareStatus status);
}