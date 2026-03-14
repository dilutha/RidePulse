package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.ComplaintDTO;
import com.ridepulse.backend.dto.CreateComplaintRequest;
import com.ridepulse.backend.dto.UpdateComplaintRequest;
import com.ridepulse.backend.model.ComplaintCategory;
import com.ridepulse.backend.model.ComplaintStatus;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Complaint Service Interface
 */
public interface ComplaintService {

    ComplaintDTO createComplaint(CreateComplaintRequest request);

    ComplaintDTO getComplaintById(Integer complaintId);

    ComplaintDTO getComplaintByNumber(String complaintNumber);

    List<ComplaintDTO> getComplaintsByPassenger(UUID passengerId);

    List<ComplaintDTO> getComplaintsByBus(Integer busId);

    List<ComplaintDTO> getComplaintsByStatus(ComplaintStatus status);

    List<ComplaintDTO> getComplaintsByCategory(ComplaintCategory category);

    List<ComplaintDTO> getComplaintsAssignedTo(UUID authorityId);

    List<ComplaintDTO> getAllComplaints();

    List<ComplaintDTO> getUnresolvedComplaints();

    ComplaintDTO updateComplaint(Integer complaintId, UpdateComplaintRequest request);

    ComplaintDTO assignComplaint(Integer complaintId, UUID authorityId);

    ComplaintDTO resolveComplaint(Integer complaintId, String resolutionNotes);

    ComplaintDTO rejectComplaint(Integer complaintId, String reason);

    void deleteComplaint(Integer complaintId);

    Map<ComplaintCategory, Long> getComplaintStatistics();
}