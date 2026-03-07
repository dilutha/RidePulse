package com.ridepulse.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * WelfareRecord Entity
 *
 * ENCAPSULATION (OOP Concept):
 * Encapsulates welfare calculation and tracking logic
 *
 * Tracks daily welfare contributions for drivers and conductors
 */
@Entity
@Table(name = "welfare_records")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
public class WelfareRecord extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "record_id")
    private Integer recordId;

    /**
     * ASSOCIATION (OOP Concept):
     * WelfareRecord belongs to a Bus
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bus_id", nullable = false)
    private Bus bus;

    /**
     * ASSOCIATION:
     * WelfareRecord belongs to a Staff member (Driver or Conductor)
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "staff_id", nullable = false)
    private Staff staff;

    @Column(name = "record_date", nullable = false)
    private LocalDate recordDate;

    @Column(name = "daily_revenue", precision = 10, scale = 2, nullable = false)
    private BigDecimal dailyRevenue;

    @Column(name = "fuel_cost", precision = 10, scale = 2)
    private BigDecimal fuelCost;

    @Column(name = "maintenance_cost", precision = 10, scale = 2)
    private BigDecimal maintenanceCost;

    @Column(name = "wages", precision = 10, scale = 2)
    private BigDecimal wages;

    @Column(name = "total_expenses", precision = 10, scale = 2)
    private BigDecimal totalExpenses;

    @Column(name = "daily_profit", precision = 10, scale = 2)
    private BigDecimal dailyProfit;

    @Column(name = "welfare_percentage", precision = 5, scale = 2)
    private BigDecimal welfarePercentage;

    @Column(name = "welfare_amount", precision = 10, scale = 2)
    private BigDecimal welfareAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "staff_type")
    private StaffType staffType;

    @Column(name = "status")
    @Enumerated(EnumType.STRING)
    private WelfareStatus status = WelfareStatus.PENDING;

    /**
     * ENCAPSULATION - Business Logic Method:
     * Calculates welfare automatically
     *
     * Driver: 5% of profit
     * Conductor: 3% of profit
     */
    public void calculateWelfare() {
        // Calculate total expenses
        this.totalExpenses = BigDecimal.ZERO;

        if (this.fuelCost != null) {
            this.totalExpenses = this.totalExpenses.add(this.fuelCost);
        }
        if (this.maintenanceCost != null) {
            this.totalExpenses = this.totalExpenses.add(this.maintenanceCost);
        }
        if (this.wages != null) {
            this.totalExpenses = this.totalExpenses.add(this.wages);
        }

        // Calculate profit
        this.dailyProfit = this.dailyRevenue.subtract(this.totalExpenses);

        // Set welfare percentage based on staff type
        if (this.staffType == StaffType.DRIVER) {
            this.welfarePercentage = new BigDecimal("5.00"); // 5%
        } else if (this.staffType == StaffType.CONDUCTOR) {
            this.welfarePercentage = new BigDecimal("3.00"); // 3%
        }

        // Calculate welfare amount
        if (this.dailyProfit.compareTo(BigDecimal.ZERO) > 0) {
            this.welfareAmount = this.dailyProfit
                    .multiply(this.welfarePercentage)
                    .divide(new BigDecimal("100"), 2, BigDecimal.ROUND_HALF_UP);
        } else {
            this.welfareAmount = BigDecimal.ZERO;
        }
    }

    /**
     * ENCAPSULATION - Business Logic:
     * Approve welfare record
     */
    public void approve() {
        this.status = WelfareStatus.APPROVED;
    }

    public void reject() {
        this.status = WelfareStatus.REJECTED;
    }
}