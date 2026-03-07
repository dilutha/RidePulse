package com.ridepulse.backend.service;

import com.ridepulse.backend.dto.CreateWelfareRecordRequest;
import com.ridepulse.backend.dto.WelfareRecordDTO;
import com.ridepulse.backend.dto.WelfareSummaryDTO;
import com.ridepulse.backend.model.WelfareStatus;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Welfare Service Interface
 *
 * ABSTRACTION (OOP Concept):
 * Defines contract for welfare management operations
 */
public interface WelfareService {

    WelfareRecordDTO createWelfareRecord(CreateWelfareRecordRequest request);

    WelfareRecordDTO getWelfareRecordById(Integer recordId);

    List<WelfareRecordDTO> getWelfareRecordsByStaff(UUID staffId);

    List<WelfareRecordDTO> getWelfareRecordsByBus(Integer busId);

    List<WelfareRecordDTO> getWelfareRecordsByDateRange(LocalDate startDate, LocalDate endDate);

    List<WelfareRecordDTO> getWelfareRecordsByStatus(WelfareStatus status);

    WelfareSummaryDTO getWelfareSummary(UUID staffId);

    WelfareRecordDTO approveWelfareRecord(Integer recordId);

    WelfareRecordDTO rejectWelfareRecord(Integer recordId);

    void deleteWelfareRecord(Integer recordId);
}