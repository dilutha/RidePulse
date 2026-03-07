package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.ComplaintDTO;
import com.ridepulse.backend.dto.CreateComplaintRequest;
import com.ridepulse.backend.dto.UpdateComplaintRequest;
import com.ridepulse.backend.model.*;
import com.ridepulse.backend.repository.*;
import com.ridepulse.backend.service.ComplaintService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Complaint Service Implementation
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates complaint management business logic
 */
@Service
@RequiredArgsConstructor
@Transactional
public class ComplaintServiceImpl implements ComplaintService {

    private final ComplaintRepository complaintRepository;
    private final UserRepository userRepository;
    private final BusRepository busRepository;
    private final StaffRepository staffRepository;

    @Override
    public ComplaintDTO createComplaint(CreateComplaintRequest request) {
        // Validate passenger exists
        User passenger = userRepository.findById(request.getPassengerId())
                .orElseThrow(() -> new RuntimeException("Passenger not found"));

        // Create new complaint
        Complaint complaint = new Complaint();
        complaint.setPassenger(passenger);
        complaint.setCategory(request.getCategory());
        complaint.setDescription(request.getDescription());
        complaint.setPhotoUrl(request.getPhotoUrl());

        // Set bus if provided
        if (request.getBusId() != null) {
            Bus bus = busRepository.findById(request.getBusId())
                    .orElseThrow(() -> new RuntimeException("Bus not found"));
            complaint.setBus(bus);
        }

        // Set staff if provided
        if (request.getStaffId() != null) {
            Staff staff = staffRepository.findById(request.getStaffId())
                    .orElseThrow(() -> new RuntimeException("Staff not found"));
            complaint.setStaff(staff);
        }

        // Auto-assign priority based on category
        complaint.setPriority(determinePriority(request.getCategory()));

        // Save to database
        Complaint saved = complaintRepository.save(complaint);

        return convertToDTO(saved);
    }

    @Override
    public ComplaintDTO getComplaintById(Integer complaintId) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        return convertToDTO(complaint);
    }

    @Override
    public ComplaintDTO getComplaintByNumber(String complaintNumber) {
        Complaint complaint = complaintRepository.findByComplaintNumber(complaintNumber)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        return convertToDTO(complaint);
    }

    @Override
    public List<ComplaintDTO> getComplaintsByPassenger(UUID passengerId) {
        return complaintRepository.findByPassengerUserIdOrderBySubmittedAtDesc(passengerId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getComplaintsByBus(Integer busId) {
        return complaintRepository.findByBusBusIdOrderBySubmittedAtDesc(busId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getComplaintsByStatus(ComplaintStatus status) {
        return complaintRepository.findByStatusOrderBySubmittedAtDesc(status)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getComplaintsByCategory(ComplaintCategory category) {
        return complaintRepository.findByCategoryOrderBySubmittedAtDesc(category)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getComplaintsAssignedTo(UUID authorityId) {
        return complaintRepository.findByAssignedToUserIdOrderBySubmittedAtDesc(authorityId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getAllComplaints() {
        return complaintRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ComplaintDTO> getUnresolvedComplaints() {
        return complaintRepository.findUnresolvedComplaints()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public ComplaintDTO updateComplaint(Integer complaintId, UpdateComplaintRequest request) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        if (request.getStatus() != null) {
            complaint.setStatus(request.getStatus());
        }

        if (request.getPriority() != null) {
            complaint.setPriority(request.getPriority());
        }

        if (request.getAssignedTo() != null) {
            User authority = userRepository.findById(request.getAssignedTo())
                    .orElseThrow(() -> new RuntimeException("Authority user not found"));
            complaint.assignTo(authority);
        }

        if (request.getResolutionNotes() != null) {
            complaint.setResolutionNotes(request.getResolutionNotes());
        }

        Complaint updated = complaintRepository.save(complaint);

        return convertToDTO(updated);
    }

    @Override
    public ComplaintDTO assignComplaint(Integer complaintId, UUID authorityId) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        User authority = userRepository.findById(authorityId)
                .orElseThrow(() -> new RuntimeException("Authority user not found"));

        complaint.assignTo(authority);
        Complaint updated = complaintRepository.save(complaint);

        return convertToDTO(updated);
    }

    @Override
    public ComplaintDTO resolveComplaint(Integer complaintId, String resolutionNotes) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        complaint.resolve(resolutionNotes);
        Complaint updated = complaintRepository.save(complaint);

        return convertToDTO(updated);
    }

    @Override
    public ComplaintDTO rejectComplaint(Integer complaintId, String reason) {
        Complaint complaint = complaintRepository.findById(complaintId)
                .orElseThrow(() -> new RuntimeException("Complaint not found"));

        complaint.reject(reason);
        Complaint updated = complaintRepository.save(complaint);

        return convertToDTO(updated);
    }

    @Override
    public void deleteComplaint(Integer complaintId) {
        complaintRepository.deleteById(complaintId);
    }

    @Override
    public Map<ComplaintCategory, Long> getComplaintStatistics() {
        List<Object[]> stats = complaintRepository.getComplaintStatisticsByCategory();

        Map<ComplaintCategory, Long> result = new HashMap<>();
        for (Object[] stat : stats) {
            result.put((ComplaintCategory) stat[0], (Long) stat[1]);
        }

        return result;
    }

    /**
     * ENCAPSULATION - Private helper methods
     */

    private ComplaintPriority determinePriority(ComplaintCategory category) {
        return switch (category) {
            case DISRUPTIVE_DRIVING, FAST_DRIVING -> ComplaintPriority.HIGH;
            case POOR_MAINTENANCE, OVERCROWDED -> ComplaintPriority.MEDIUM;
            default -> ComplaintPriority.LOW;
        };
    }

    private ComplaintDTO convertToDTO(Complaint complaint) {
        ComplaintDTO dto = new ComplaintDTO();
        dto.setComplaintId(complaint.getComplaintId());
        dto.setComplaintNumber(complaint.getComplaintNumber());

        if (complaint.getPassenger() != null) {
            dto.setPassengerId(complaint.getPassenger().getUserId());
            dto.setPassengerName(complaint.getPassenger().getFullName());
            dto.setPassengerEmail(complaint.getPassenger().getEmail());
        }

        if (complaint.getBus() != null) {
            dto.setBusId(complaint.getBus().getBusId());
            dto.setBusNumber(complaint.getBus().getBusNumber());
        }

        if (complaint.getStaff() != null) {
            dto.setStaffId(complaint.getStaff().getUserId());
            dto.setStaffName(complaint.getStaff().getFullName());
        }

        dto.setCategory(complaint.getCategory());
        dto.setCategoryDescription(complaint.getCategory().getDescription());
        dto.setDescription(complaint.getDescription());
        dto.setPhotoUrl(complaint.getPhotoUrl());
        dto.setPriority(complaint.getPriority());
        dto.setStatus(complaint.getStatus());

        if (complaint.getAssignedTo() != null) {
            dto.setAssignedToId(complaint.getAssignedTo().getUserId());
            dto.setAssignedToName(complaint.getAssignedTo().getFullName());
        }

        dto.setResolutionNotes(complaint.getResolutionNotes());
        dto.setSubmittedAt(complaint.getSubmittedAt());
        dto.setResolvedAt(complaint.getResolvedAt());

        return dto;
    }
}