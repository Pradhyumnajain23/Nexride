"""
NexRide - Smart ETA Service
Calculates bus ETA with traffic awareness. Modular — swap rule-based for ML later.
"""
import math
from datetime import datetime, timezone


PEAK_HOURS = [(7, 9), (17, 19)]   # morning + evening rush
STOP_DWELL_MIN = 0.7               # avg seconds at each stop


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Straight-line distance in km between two GPS coordinates."""
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _traffic_delay(hour: int) -> float:
    """Returns additional delay in minutes based on time of day."""
    for start, end in PEAK_HOURS:
        if start <= hour <= end:
            return 7.0   # peak → heavy traffic
    if 22 <= hour or hour < 6:
        return 0.5       # night → no traffic
    return 2.0           # off-peak → mild traffic


def _traffic_factor_label(hour: int) -> str:
    for start, end in PEAK_HOURS:
        if start <= hour <= end:
            return "heavy"
    if 22 <= hour or hour < 6:
        return "none"
    return "mild"


def calculate_eta(
    bus_lat: float,
    bus_lng: float,
    destination_lat: float,
    destination_lng: float,
    speed_kmh: float = 30.0,
    stops_remaining: int = 5,
    occupancy_pct: float = 50.0,
    hour_override: int | None = None,
) -> dict:
    """
    Smart ETA calculation.

    Returns:
        {
          "eta_minutes": float,
          "distance_km": float,
          "traffic": str,
          "confidence": float
        }
    """
    hour = hour_override if hour_override is not None else datetime.now(timezone.utc).hour

    # Convert UTC hour to IST (UTC+5:30)
    ist_hour = (hour + 5) % 24

    distance_km = _haversine_km(bus_lat, bus_lng, destination_lat, destination_lng)

    # Guard: if GPS coordinates are nonsensical fall back to 5km
    if distance_km < 0.01:
        distance_km = 5.0

    effective_speed = max(5.0, speed_kmh)

    travel_time   = (distance_km / effective_speed) * 60          # minutes
    stop_delay    = stops_remaining * STOP_DWELL_MIN              # minutes
    traffic_delay = _traffic_delay(ist_hour)                       # minutes

    # Occupancy penalty: full bus boards/alights slower
    occ_penalty = (occupancy_pct / 100) * 2.0

    eta = round(travel_time + stop_delay + traffic_delay + occ_penalty, 1)

    # Confidence degrades with more unknowns
    confidence = round(max(0.45, 0.95 - (stops_remaining * 0.03) - (occupancy_pct / 400)), 2)

    return {
        "eta_minutes":  eta,
        "distance_km":  round(distance_km, 2),
        "traffic":      _traffic_factor_label(ist_hour),
        "confidence":   confidence,
    }
