package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Complaint Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates complaint management logic
 */
@Entity
@Table(name = "complaints")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class Complaint extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "complaint_id")
    private Integer complaintId;

    @Column(name = "complaint_number", unique = true, nullable = false)
    private String complaintNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "passenger_id")
    private User passenger;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bus_id")
    private Bus bus;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_id")
    private Staff staff;

    @Enumerated(EnumType.STRING)
    private ComplaintCategory category;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    private String photoUrl;

    @Enumerated(EnumType.STRING)
    private ComplaintPriority priority = ComplaintPriority.MEDIUM;

    @Enumerated(EnumType.STRING)
    private ComplaintStatus status = ComplaintStatus.SUBMITTED;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    private User assignedTo;

    private String resolutionNotes;

    private LocalDateTime submittedAt;

    private LocalDateTime resolvedAt;

    @PrePersist
    protected void onCreate() {
        super.onCreate();
        this.submittedAt = LocalDateTime.now();

        if (this.complaintNumber == null) {
            this.complaintNumber = "CMP-" + System.currentTimeMillis();
        }
    }

    public void assignTo(User authority) {
        this.assignedTo = authority;
        this.status = ComplaintStatus.UNDER_REVIEW;
    }

    public void resolve(String resolutionNotes) {
        this.resolutionNotes = resolutionNotes;
        this.status = ComplaintStatus.RESOLVED;
        this.resolvedAt = LocalDateTime.now();
    }

    public void close() {
        this.status = ComplaintStatus.CLOSED;
    }

    public void reject(String reason) {
        this.resolutionNotes = reason;
        this.status = ComplaintStatus.REJECTED;
        this.resolvedAt = LocalDateTime.now();
    }
}