package com.ridepulse.backend.controller;

import com.ridepulse.backend.dto.CreateWelfareRecordRequest;
import com.ridepulse.backend.dto.WelfareRecordDTO;
import com.ridepulse.backend.dto.WelfareSummaryDTO;
import com.ridepulse.backend.model.WelfareStatus;
import com.ridepulse.backend.service.WelfareService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Welfare Controller
 *
 * REST API endpoints for welfare management
 */
@RestController
@RequestMapping("/api/welfare")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class WelfareController {

    private final WelfareService welfareService;

    /**
     * Create welfare record
     * POST /api/welfare
     */
    @PostMapping
    public ResponseEntity<WelfareRecordDTO> createWelfareRecord(
            @Valid @RequestBody CreateWelfareRecordRequest request
    ) {
        WelfareRecordDTO record = welfareService.createWelfareRecord(request);
        return new ResponseEntity<>(record, HttpStatus.CREATED);
    }

    /**
     * Get welfare record by ID
     * GET /api/welfare/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<WelfareRecordDTO> getWelfareRecordById(@PathVariable Integer id) {
        WelfareRecordDTO record = welfareService.getWelfareRecordById(id);
        return ResponseEntity.ok(record);
    }

    /**
     * Get welfare records by staff
     * GET /api/welfare/staff/{staffId}
     */
    @GetMapping("/staff/{staffId}")
    public ResponseEntity<List<WelfareRecordDTO>> getWelfareRecordsByStaff(
            @PathVariable UUID staffId
    ) {
        List<WelfareRecordDTO> records = welfareService.getWelfareRecordsByStaff(staffId);
        return ResponseEntity.ok(records);
    }

    /**
     * Get welfare records by bus
     * GET /api/welfare/bus/{busId}
     */
    @GetMapping("/bus/{busId}")
    public ResponseEntity<List<WelfareRecordDTO>> getWelfareRecordsByBus(
            @PathVariable Integer busId
    ) {
        List<WelfareRecordDTO> records = welfareService.getWelfareRecordsByBus(busId);
        return ResponseEntity.ok(records);
    }

    /**
     * Get welfare records by date range
     * GET /api/welfare/date-range?start=2024-01-01&end=2024-01-31
     */
    @GetMapping("/date-range")
    public ResponseEntity<List<WelfareRecordDTO>> getWelfareRecordsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end
    ) {
        List<WelfareRecordDTO> records = welfareService.getWelfareRecordsByDateRange(start, end);
        return ResponseEntity.ok(records);
    }

    /**
     * Get welfare records by status
     * GET /api/welfare/status/{status}
     */
    @GetMapping("/status/{status}")
    public ResponseEntity<List<WelfareRecordDTO>> getWelfareRecordsByStatus(
            @PathVariable WelfareStatus status
    ) {
        List<WelfareRecordDTO> records = welfareService.getWelfareRecordsByStatus(status);
        return ResponseEntity.ok(records);
    }

    /**
     * Get welfare summary for staff
     * GET /api/welfare/staff/{staffId}/summary
     */
    @GetMapping("/staff/{staffId}/summary")
    public ResponseEntity<WelfareSummaryDTO> getWelfareSummary(@PathVariable UUID staffId) {
        WelfareSummaryDTO summary = welfareService.getWelfareSummary(staffId);
        return ResponseEntity.ok(summary);
    }

    /**
     * Approve welfare record
     * PUT /api/welfare/{id}/approve
     */
    @PutMapping("/{id}/approve")
    public ResponseEntity<WelfareRecordDTO> approveWelfareRecord(@PathVariable Integer id) {
        WelfareRecordDTO record = welfareService.approveWelfareRecord(id);
        return ResponseEntity.ok(record);
    }

    /**
     * Reject welfare record
     * PUT /api/welfare/{id}/reject
     */
    @PutMapping("/{id}/reject")
    public ResponseEntity<WelfareRecordDTO> rejectWelfareRecord(@PathVariable Integer id) {
        WelfareRecordDTO record = welfareService.rejectWelfareRecord(id);
        return ResponseEntity.ok(record);
    }

    /**
     * Delete welfare record
     * DELETE /api/welfare/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWelfareRecord(@PathVariable Integer id) {
        welfareService.deleteWelfareRecord(id);
        return ResponseEntity.noContent().build();
    }
}