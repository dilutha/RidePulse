package com.ridepulse.backend.controller;

import com.ridepulse.backend.dto.ComplaintDTO;
import com.ridepulse.backend.dto.CreateComplaintRequest;
import com.ridepulse.backend.dto.UpdateComplaintRequest;
import com.ridepulse.backend.model.ComplaintCategory;
import com.ridepulse.backend.model.ComplaintStatus;
import com.ridepulse.backend.service.ComplaintService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Complaint Controller
 *
 * REST API endpoints for complaint management
 */
@RestController
@RequestMapping("/api/complaints")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ComplaintController {

    private final ComplaintService complaintService;

    /**
     * Create complaint
     * POST /api/complaints
     */
    @PostMapping
    public ResponseEntity<ComplaintDTO> createComplaint(
            @Valid @RequestBody CreateComplaintRequest request
    ) {
        ComplaintDTO complaint = complaintService.createComplaint(request);
        return new ResponseEntity<>(complaint, HttpStatus.CREATED);
    }

    /**
     * Get complaint by ID
     * GET /api/complaints/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ComplaintDTO> getComplaintById(@PathVariable Integer id) {
        ComplaintDTO complaint = complaintService.getComplaintById(id);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Get complaint by number
     * GET /api/complaints/number/{complaintNumber}
     */
    @GetMapping("/number/{complaintNumber}")
    public ResponseEntity<ComplaintDTO> getComplaintByNumber(
            @PathVariable String complaintNumber
    ) {
        ComplaintDTO complaint = complaintService.getComplaintByNumber(complaintNumber);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Get complaints by passenger
     * GET /api/complaints/passenger/{passengerId}
     */
    @GetMapping("/passenger/{passengerId}")
    public ResponseEntity<List<ComplaintDTO>> getComplaintsByPassenger(
            @PathVariable UUID passengerId
    ) {
        List<ComplaintDTO> complaints = complaintService.getComplaintsByPassenger(passengerId);
        return ResponseEntity.ok(complaints);
    }

    /**
     * Get complaints by bus
     * GET /api/complaints/bus/{busId}
     */
    @GetMapping("/bus/{busId}")
    public ResponseEntity<List<ComplaintDTO>> getComplaintsByBus(@PathVariable Integer busId) {
        List<ComplaintDTO> complaints = complaintService.getComplaintsByBus(busId);
        return ResponseEntity.ok(complaints);
    }

    /**
     * Get complaints by status
     * GET /api/complaints/status/{status}
     */
    @GetMapping("/status/{status}")
    public ResponseEntity<List<ComplaintDTO>> getComplaintsByStatus(
            @PathVariable ComplaintStatus status
    ) {
        List<ComplaintDTO> complaints = complaintService.getComplaintsByStatus(status);
        return ResponseEntity.ok(complaints);
    }

    /**
     * Get complaints by category
     * GET /api/complaints/category/{category}
     */
    @GetMapping("/category/{category}")
    public ResponseEntity<List<ComplaintDTO>> getComplaintsByCategory(
            @PathVariable ComplaintCategory category
    ) {
        List<ComplaintDTO> complaints = complaintService.getComplaintsByCategory(category);
        return ResponseEntity.ok(complaints);
    }

    /**
     * Get all complaints
     * GET /api/complaints
     */
    @GetMapping
    public ResponseEntity<List<ComplaintDTO>> getAllComplaints() {
        List<ComplaintDTO> complaints = complaintService.getAllComplaints();
        return ResponseEntity.ok(complaints);
    }

    /**
     * Get unresolved complaints
     * GET /api/complaints/unresolved
     */
    @GetMapping("/unresolved")
    public ResponseEntity<List<ComplaintDTO>> getUnresolvedComplaints() {
        List<ComplaintDTO> complaints = complaintService.getUnresolvedComplaints();
        return ResponseEntity.ok(complaints);
    }

    /**
     * Update complaint
     * PUT /api/complaints/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<ComplaintDTO> updateComplaint(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateComplaintRequest request
    ) {
        ComplaintDTO complaint = complaintService.updateComplaint(id, request);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Assign complaint to authority
     * PUT /api/complaints/{id}/assign/{authorityId}
     */
    @PutMapping("/{id}/assign/{authorityId}")
    public ResponseEntity<ComplaintDTO> assignComplaint(
            @PathVariable Integer id,
            @PathVariable UUID authorityId
    ) {
        ComplaintDTO complaint = complaintService.assignComplaint(id, authorityId);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Resolve complaint
     * PUT /api/complaints/{id}/resolve
     */
    @PutMapping("/{id}/resolve")
    public ResponseEntity<ComplaintDTO> resolveComplaint(
            @PathVariable Integer id,
            @RequestBody Map<String, String> request
    ) {
        String resolutionNotes = request.get("resolutionNotes");
        ComplaintDTO complaint = complaintService.resolveComplaint(id, resolutionNotes);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Reject complaint
     * PUT /api/complaints/{id}/reject
     */
    @PutMapping("/{id}/reject")
    public ResponseEntity<ComplaintDTO> rejectComplaint(
            @PathVariable Integer id,
            @RequestBody Map<String, String> request
    ) {
        String reason = request.get("reason");
        ComplaintDTO complaint = complaintService.rejectComplaint(id, reason);
        return ResponseEntity.ok(complaint);
    }

    /**
     * Delete complaint
     * DELETE /api/complaints/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteComplaint(@PathVariable Integer id) {
        complaintService.deleteComplaint(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Get complaint statistics
     * GET /api/complaints/statistics
     */
    @GetMapping("/statistics")
    public ResponseEntity<Map<ComplaintCategory, Long>> getComplaintStatistics() {
        Map<ComplaintCategory, Long> statistics = complaintService.getComplaintStatistics();
        return ResponseEntity.ok(statistics);
    }
}