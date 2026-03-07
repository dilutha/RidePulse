package com.ridepulse.backend.service.impl;

import com.ridepulse.backend.dto.CreateWelfareRecordRequest;
import com.ridepulse.backend.dto.WelfareRecordDTO;
import com.ridepulse.backend.dto.WelfareSummaryDTO;
import com.ridepulse.backend.model.*;
import com.ridepulse.backend.repository.BusRepository;
import com.ridepulse.backend.repository.StaffRepository;
import com.ridepulse.backend.repository.WelfareRecordRepository;
import com.ridepulse.backend.service.WelfareService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class WelfareServiceImpl implements WelfareService {

    private final WelfareRecordRepository welfareRecordRepository;
    private final StaffRepository staffRepository;
    private final BusRepository busRepository;

    /**
     * Create welfare record
     */
    @Override
    public WelfareRecordDTO createWelfareRecord(CreateWelfareRecordRequest request) {

        Staff staff = staffRepository.findById(request.getStaffId())
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        Bus bus = busRepository.findById(request.getBusId())
                .orElseThrow(() -> new RuntimeException("Bus not found"));

        welfareRecordRepository
                .findByStaffUserIdAndRecordDate(request.getStaffId(), request.getRecordDate())
                .ifPresent(existing -> {
                    throw new RuntimeException("Welfare record already exists for this date");
                });

        WelfareRecord welfareRecord = new WelfareRecord();
        welfareRecord.setBus(bus);
        welfareRecord.setStaff(staff);
        welfareRecord.setRecordDate(request.getRecordDate());
        welfareRecord.setDailyRevenue(request.getDailyRevenue());
        welfareRecord.setFuelCost(request.getFuelCost());
        welfareRecord.setMaintenanceCost(request.getMaintenanceCost());
        welfareRecord.setWages(request.getWages());
        welfareRecord.setStaffType(request.getStaffType());

        welfareRecord.calculateWelfare();

        WelfareRecord saved = welfareRecordRepository.save(welfareRecord);

        return convertToDTO(saved);
    }

    @Override
    public WelfareRecordDTO getWelfareRecordById(Integer recordId) {
        WelfareRecord record = welfareRecordRepository.findById(recordId)
                .orElseThrow(() -> new RuntimeException("Welfare record not found"));

        return convertToDTO(record);
    }

    @Override
    public List<WelfareRecordDTO> getWelfareRecordsByStaff(UUID staffId) {

        return welfareRecordRepository
                .findByStaffUserIdOrderByRecordDateDesc(staffId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<WelfareRecordDTO> getWelfareRecordsByBus(Integer busId) {

        return welfareRecordRepository
                .findByBusBusIdOrderByRecordDateDesc(busId)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<WelfareRecordDTO> getWelfareRecordsByDateRange(LocalDate startDate, LocalDate endDate) {

        return welfareRecordRepository
                .findByRecordDateBetween(startDate, endDate)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<WelfareRecordDTO> getWelfareRecordsByStatus(WelfareStatus status) {

        return welfareRecordRepository
                .findByStatusOrderByRecordDateDesc(status)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Welfare summary for staff
     */
    @Override
    public WelfareSummaryDTO getWelfareSummary(UUID staffId) {

        Staff staff = staffRepository.findById(staffId)
                .orElseThrow(() -> new RuntimeException("Staff not found"));

        List<WelfareRecord> records =
                welfareRecordRepository.findByStaffUserIdOrderByRecordDateDesc(staffId);

        BigDecimal totalWelfare =
                welfareRecordRepository.calculateTotalWelfare(staffId);

        BigDecimal pending = records.stream()
                .filter(r -> r.getStatus() == WelfareStatus.PENDING)
                .map(WelfareRecord::getWelfareAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal approved = records.stream()
                .filter(r -> r.getStatus() == WelfareStatus.APPROVED)
                .map(WelfareRecord::getWelfareAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal paid = records.stream()
                .filter(r -> r.getStatus() == WelfareStatus.PAID)
                .map(WelfareRecord::getWelfareAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        WelfareSummaryDTO summary = new WelfareSummaryDTO();
        summary.setStaffId(staff.getUserId());
        summary.setStaffName(staff.getFullName());
        summary.setEmployeeId(staff.getEmployeeId());
        summary.setTotalWelfareAmount(totalWelfare != null ? totalWelfare : BigDecimal.ZERO);
        summary.setPendingWelfareAmount(pending);
        summary.setApprovedWelfareAmount(approved);
        summary.setPaidWelfareAmount(paid);
        summary.setTotalRecords(records.size());

        return summary;
    }

    @Override
    public WelfareRecordDTO approveWelfareRecord(Integer recordId) {

        WelfareRecord record = welfareRecordRepository.findById(recordId)
                .orElseThrow(() -> new RuntimeException("Welfare record not found"));

        record.approve();

        WelfareRecord updated = welfareRecordRepository.save(record);

        return convertToDTO(updated);
    }

    @Override
    public WelfareRecordDTO rejectWelfareRecord(Integer recordId) {

        WelfareRecord record = welfareRecordRepository.findById(recordId)
                .orElseThrow(() -> new RuntimeException("Welfare record not found"));

        record.reject();

        WelfareRecord updated = welfareRecordRepository.save(record);

        return convertToDTO(updated);
    }

    @Override
    public void deleteWelfareRecord(Integer recordId) {
        welfareRecordRepository.deleteById(recordId);
    }

    /**
     * Convert entity → DTO
     */
    private WelfareRecordDTO convertToDTO(WelfareRecord record) {

        WelfareRecordDTO dto = new WelfareRecordDTO();

        dto.setRecordId(record.getRecordId());
        dto.setBusId(record.getBus().getBusId());
        dto.setBusNumber(record.getBus().getBusNumber());

        dto.setStaffId(record.getStaff().getUserId());
        dto.setStaffName(record.getStaff().getFullName());
        dto.setEmployeeId(record.getStaff().getEmployeeId());

        dto.setRecordDate(record.getRecordDate());
        dto.setDailyRevenue(record.getDailyRevenue());
        dto.setFuelCost(record.getFuelCost());
        dto.setMaintenanceCost(record.getMaintenanceCost());
        dto.setWages(record.getWages());

        dto.setTotalExpenses(record.getTotalExpenses());
        dto.setDailyProfit(record.getDailyProfit());

        dto.setWelfarePercentage(record.getWelfarePercentage());
        dto.setWelfareAmount(record.getWelfareAmount());

        dto.setStaffType(record.getStaffType());
        dto.setStatus(record.getStatus());

        return dto;
    }
}