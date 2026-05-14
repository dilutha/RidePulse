# ============================================================
# predict_service/feature_builder.py
# OOP Encapsulation: all feature engineering logic is private.
#     Callers only call build_features() with simple inputs.
# OOP Abstraction: hides the complexity of lag calculation,
#     rolling means, and feature encoding from the API layer.
# ============================================================
import numpy as np
import pandas as pd
import logging
from datetime import datetime, date, time
from typing import Optional
from sqlalchemy import create_engine, text
from config import (
    DATABASE_URL,
    PEAK_MORNING_START, PEAK_MORNING_END,
    PEAK_EVENING_START, PEAK_EVENING_END,
)

logger = logging.getLogger(__name__)

# ── Encoding maps (must match training encoding) ─────────────
# OOP Encapsulation: encoding knowledge lives here, not scattered
WEATHER_ENCODING = {
    "clear":  0,
    "cloudy": 1,
    "rainy":  2,
    "stormy": 3,
}

TRAFFIC_ENCODING = {
    "low":    0,
    "medium": 1,
    "high":   2,
}

# Sri Lanka public holiday dates (extend as needed)
SRI_LANKA_HOLIDAYS_2025 = {
    date(2025, 1, 1),   # New Year
    date(2025, 2, 4),   # Independence Day
    date(2025, 4, 13),  # Sinhala & Tamil New Year
    date(2025, 4, 14),  # Sinhala & Tamil New Year
    date(2025, 5, 1),   # Labour Day
    date(2025, 12, 25), # Christmas
}

# DB engine — shared across requests (Encapsulation: hidden from callers)
_engine = None


def _get_engine():
    """Lazy singleton DB engine."""
    global _engine
    if _engine is None:
        _engine = create_engine(DATABASE_URL, pool_size=5, max_overflow=2)
    return _engine


# ─────────────────────────────────────────────────────────────
# Public API — callers only use build_features()
# ─────────────────────────────────────────────────────────────

def build_features(
    route_id:     int,
    target_dt:    datetime,
    weather:      str  = "clear",
    rain:         float = 0.0,
    traffic_level: str  = "medium",
    location:     str  = "",
) -> np.ndarray:
    """
    Builds the full 16-feature input vector for the LSTM model.

    Features (in order, matching training):
      hour, day_of_week, is_weekend, is_peak_hour,
      route_id, location,
      weather, rain,
      traffic_level,
      is_holiday,
      lag_1, lag_2, lag_3,
      rolling_mean_3, rolling_mean_5,
      rain_peak

    OOP Abstraction: caller passes simple human-readable inputs;
    this function handles all encoding and DB queries internally.

    Returns:
        np.ndarray shape (16,) — ready for model.predict()
    """
    # ── Time features ─────────────────────────────────────────
    hour        = target_dt.hour
    day_of_week = target_dt.weekday()          # 0=Mon … 6=Sun
    is_weekend  = 1 if day_of_week >= 5 else 0
    is_peak_hour = _is_peak(hour)

    # ── Route / location ──────────────────────────────────────
    # Demo-friendly stop encoding. Training used a numeric location feature;
    # keep the feature position stable while letting selected stops vary output.
    location_enc = _encode_location(location, route_id)

    # ── Weather ───────────────────────────────────────────────
    weather_enc = WEATHER_ENCODING.get(weather.lower(), 0)
    rain_val    = float(rain)

    # ── Traffic ───────────────────────────────────────────────
    traffic_enc = TRAFFIC_ENCODING.get(traffic_level.lower(), 1)

    # ── Calendar ─────────────────────────────────────────────
    is_holiday = 1 if target_dt.date() in SRI_LANKA_HOLIDAYS_2025 else 0

    # ── Historical lag features (from DB) ────────────────────
    lag_1, lag_2, lag_3, rolling_mean_3, rolling_mean_5 = \
        _fetch_lag_features(route_id, target_dt)

    # ── Derived feature ───────────────────────────────────────
    rain_peak = rain_val * is_peak_hour

    # ── Assemble in training order ────────────────────────────
    features = np.array([
        hour, day_of_week, is_weekend, is_peak_hour,
        route_id, location_enc,
        weather_enc, rain_val,
        traffic_enc,
        is_holiday,
        lag_1, lag_2, lag_3,
        rolling_mean_3, rolling_mean_5,
        rain_peak,
    ], dtype=np.float32)

    logger.debug(f"Features for route={route_id} dt={target_dt}: {features}")
    return features


# ─────────────────────────────────────────────────────────────
# Private helpers (Encapsulation)
# ─────────────────────────────────────────────────────────────

def _is_peak(hour: int) -> int:
    """Returns 1 if the hour is a peak commute hour."""
    morning_peak = PEAK_MORNING_START <= hour <= PEAK_MORNING_END
    evening_peak = PEAK_EVENING_START <= hour <= PEAK_EVENING_END
    return 1 if (morning_peak or evening_peak) else 0


def _encode_location(location: str, route_id: int) -> int:
    if not location:
        return route_id % 10
    return sum(ord(ch) for ch in location.lower()) % 10


def _fetch_lag_features(
    route_id: int,
    target_dt: datetime,
) -> tuple[float, float, float, float, float]:
    """
    Queries the last N crowd readings for this route from crowd_levels table.
    Returns (lag_1, lag_2, lag_3, rolling_mean_3, rolling_mean_5).

    OOP Encapsulation: all SQL is hidden here — callers get plain floats.
    Falls back to route capacity defaults if no historical data exists.
    """
    try:
        sql = text("""
            SELECT
                c.passenger_count,
                c.bus_capacity,
                c.recorded_at
            FROM crowd_levels c
            JOIN bus_trips t   ON c.trip_id  = t.trip_id
            JOIN routes   r    ON t.route_id = r.route_id
            WHERE r.route_id = :route_id
              AND c.recorded_at < :before_dt
            ORDER BY c.recorded_at DESC
            LIMIT 10
        """)

        with _get_engine().connect() as conn:
            result = conn.execute(sql, {
                "route_id": route_id,
                "before_dt": target_dt,
            })
            rows = result.fetchall()

        if not rows:
            # No historical data — return neutral defaults
            logger.warning(
                f"No historical crowd data for route {route_id}. "
                "Using defaults."
            )
            return 30.0, 30.0, 30.0, 30.0, 30.0

        # Convert to percentage of capacity
        pct_readings = [
            (r[0] / r[1] * 100) if r[1] > 0 else 30.0
            for r in rows
        ]

        # Pad if fewer than 5 readings
        while len(pct_readings) < 5:
            pct_readings.append(pct_readings[-1])

        lag_1 = pct_readings[0]
        lag_2 = pct_readings[1]
        lag_3 = pct_readings[2]
        rolling_mean_3 = float(np.mean(pct_readings[:3]))
        rolling_mean_5 = float(np.mean(pct_readings[:5]))

        return lag_1, lag_2, lag_3, rolling_mean_3, rolling_mean_5

    except Exception as e:
        logger.error(f"Failed to fetch lag features: {e}")
        return 30.0, 30.0, 30.0, 30.0, 30.0
