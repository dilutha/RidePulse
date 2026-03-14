package com.ridepulse.backend.model;

public enum ComplaintCategory {

    DISRUPTIVE_DRIVING("Disruptive or unsafe driving"),
    INCORRECT_CHANGE("Not providing correct ticket change"),
    UNFAIR_PRICING("Unfair ticket pricing"),
    SLOW_DRIVING("Slow driving"),
    FAST_DRIVING("Excessively fast driving"),
    OVERCROWDED("Overcrowded bus"),
    POOR_MAINTENANCE("Poorly maintained bus"),
    RUDE_BEHAVIOR("Rude behavior"),
    OTHER("Other");

    private final String description;

    ComplaintCategory(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}