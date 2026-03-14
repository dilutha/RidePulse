package com.ridepulse.backend.repository;

import com.ridepulse.backend.model.Complaint;
import com.ridepulse.backend.model.ComplaintCategory;
import com.ridepulse.backend.model.ComplaintStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Complaint Repository
 */
@Repository
public interface ComplaintRepository extends JpaRepository<Complaint, Integer> {

    // Find complaint by complaint number
    Optional<Complaint> findByComplaintNumber(String complaintNumber);

    // Find complaints by passenger
    List<Complaint> findByPassengerUserIdOrderBySubmittedAtDesc(UUID passengerId);

    // Find complaints by bus
    List<Complaint> findByBusBusIdOrderBySubmittedAtDesc(Integer busId);

    // Find complaints by status
    List<Complaint> findByStatusOrderBySubmittedAtDesc(ComplaintStatus status);

    // Find complaints by category
    List<Complaint> findByCategoryOrderBySubmittedAtDesc(ComplaintCategory category);

    // Find complaints assigned to authority
    List<Complaint> findByAssignedToUserIdOrderBySubmittedAtDesc(UUID authorityId);

    // Find complaints by date range
    List<Complaint> findBySubmittedAtBetweenOrderBySubmittedAtDesc(
            LocalDateTime startDate,
            LocalDateTime endDate
    );

    // Count complaints by status
    Long countByStatus(ComplaintStatus status);

    // Count complaints by category
    Long countByCategory(ComplaintCategory category);

    // Get unresolved complaints
    @Query("SELECT c FROM Complaint c WHERE c.status IN ('SUBMITTED', 'UNDER_REVIEW') " +
            "ORDER BY c.priority DESC, c.submittedAt ASC")
    List<Complaint> findUnresolvedComplaints();

    // Get complaint statistics by category
    @Query("SELECT c.category, COUNT(c) FROM Complaint c GROUP BY c.category")
    List<Object[]> getComplaintStatisticsByCategory();
}