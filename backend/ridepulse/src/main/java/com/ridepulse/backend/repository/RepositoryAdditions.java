// ── ADD to: StaffRepository.java ────────────────────────────

    // Authority: list all staff by type (no owner filter)
    List<Staff> findByStaffType(Staff.StaffType staffType);

    // Authority + dashboard: count staff by type
    long countByStaffType(Staff.StaffType staffType);


// ── ADD to: BusTripRepository.java ──────────────────────────

    // Authority dashboard: count in-progress trips
    long countByStatus(String status);


// ── ADD to: ComplaintRepository.java ────────────────────────

    // Authority dashboard: count complaints by status
    long countByStatus(String status);

    // Authority dashboard: count complaints by multiple statuses
    @Query("SELECT COUNT(c) FROM Complaint c WHERE c.status IN :statuses")
    long countByStatusIn(@Param("statuses") List<String> statuses);


// ══════════════════════════════════════════════════════════════
// UPDATED FARE CALCULATION — ConductorServiceImpl.calculateFare()
//
// REPLACE the existing calculateFare() method with this version.
// Applies Sri Lanka NTPS rules:
//   Fare = baseFare + (stops - 1) * 8
//   Minimum: LKR 30 | Maximum: LKR 2422
// ══════════════════════════════════════════════════════════════

    /**
     * Calculates ticket fare using Sri Lanka NTPS fare rules.
     * OOP Encapsulation: all fare logic is hidden here.
     * OOP Polymorphism: result changes based on stop count.
     *
     * Formula: fare = baseFare + (stopsBetween - 1) × 8
     * Bounds:  minimum LKR 30, maximum LKR 2422
     */
    private BigDecimal calculateFare(Route route, RouteStop boarding,
                                      RouteStop alighting) {
        // National fare constants (Encapsulation: defined here, not scattered)
        final BigDecimal MIN_FARE      = new BigDecimal("30.00");
        final BigDecimal MAX_FARE      = new BigDecimal("2422.00");
        final BigDecimal FARE_PER_STOP = new BigDecimal("8.00");

        int stopsBetween = Math.abs(
            alighting.getStopSequence() - boarding.getStopSequence());

        if (stopsBetween == 0) return MIN_FARE;  // same stop = minimum

        // Fare = baseFare + (stops - 1) × 8
        BigDecimal fare = route.getBaseFare()
            .add(FARE_PER_STOP.multiply(BigDecimal.valueOf(stopsBetween - 1)));

        // Clamp to national bounds
        if (fare.compareTo(MIN_FARE) < 0) fare = MIN_FARE;
        if (fare.compareTo(MAX_FARE) > 0) fare = MAX_FARE;

        return fare.setScale(2, RoundingMode.HALF_UP);
    }
