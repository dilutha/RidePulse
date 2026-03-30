package com.ridepulse.backend.repository;

import com.ridepulse.backend.entity.Complaint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * OOP Encapsulation: All complaint queries scoped by caller's role.
 *   Passenger   → sees only their own complaints
 *   Bus Owner   → sees complaints about their buses only
 *   Authority   → sees all complaints system-wide with filters
 */
@Repository
public interface ComplaintRepository extends JpaRepository<Complaint, Integer> {

    // ── Passenger queries ────────────────────────────────────

    // Used by: PassengerComplaintController — list my complaints with feedback
    List<Complaint> findByPassenger_UserIdOrderBySubmittedAtDesc(UUID passengerId);

    // ── Authority queries ────────────────────────────────────

    // Used by: AuthorityComplaintController — all complaints, newest first
    List<Complaint> findAllByOrderBySubmittedAtDesc();

    // Used by: AuthorityComplaintController — filter by status
    List<Complaint> findByStatusOrderBySubmittedAtDesc(String status);

    // Used by: AuthorityComplaintController — filter by category
    List<Complaint> findByCategoryOrderBySubmittedAtDesc(String category);

    // Used by: AuthorityComplaintController — filter by both status + category
    List<Complaint> findByStatusAndCategoryOrderBySubmittedAtDesc(
            String status, String category);

    // Used by: AuthorityComplaintController — complaints assigned to me
    @Query("""
        SELECT c FROM Complaint c
        WHERE c.assignedTo.userId = :authorityUserId
        ORDER BY c.submittedAt DESC
        """)
    List<Complaint> findAssignedToAuthority(
            @Param("authorityUserId") UUID authorityUserId);

    // Used by: AuthorityComplaintController — dashboard stats
    long countByStatus(String status);

    long countByCategory(String category);

    // ── Bus Owner queries ────────────────────────────────────

    // Used by: BusOwnerDashboardServiceImpl — complaints about owner's buses
    @Query("""
        SELECT c FROM Complaint c
        WHERE c.bus.owner.ownerId = :ownerId
        ORDER BY c.submittedAt DESC
        """)
    List<Complaint> findByOwner(@Param("ownerId") Integer ownerId);

    // Used by: BusOwnerDashboardServiceImpl — filtered by status
    @Query("""
        SELECT c FROM Complaint c
        WHERE c.bus.owner.ownerId = :ownerId
          AND (:status = 'all' OR c.status = :status)
        ORDER BY c.submittedAt DESC
        """)
    List<Complaint> findByOwnerAndStatus(
            @Param("ownerId") Integer ownerId,
            @Param("status") String status);

    // Used by: BusOwnerDashboardServiceImpl — badge count
    @Query("""
        SELECT COUNT(c) FROM Complaint c
        WHERE c.bus.owner.ownerId = :ownerId
          AND c.status IN ('submitted', 'under_review')
        """)
    long countOpenComplaintsByOwner(@Param("ownerId") Integer ownerId);


    // Authority dashboard: count complaints by multiple statuses
    @Query("SELECT COUNT(c) FROM Complaint c WHERE c.status IN :statuses")
    long countByStatusIn(@Param("statuses") List<String> statuses);

}
