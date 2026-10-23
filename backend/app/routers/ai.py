"""
NexRide Backend - AI Prediction Router
Provides ETA, crowd level, and smart route suggestion endpoints
using simple scikit-learn models (rule-based for MVP, trainable later).
"""
import math
import random
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import Bus, Route
from app.services.eta_service import calculate_eta
from app.services.route_optimizer import optimize_routes
from app.schemas import (
    CrowdPredictionRequest,
    CrowdPredictionResponse,
    ETAPredictionRequest,
    ETAPredictionResponse,
    RouteOut,
    SmartRouteRequest,
    SmartRouteResponse,
)

router = APIRouter(prefix="/ai", tags=["AI Predictions"])


# ─────────────────────────────────────────────────────────────────────────────
# POST /ai/predict-eta
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/predict-eta", response_model=ETAPredictionResponse)
def predict_eta(
    payload: ETAPredictionRequest,
    db: Session = Depends(get_db),
):
    """
    Estimate bus ETA using smart ETA service:
    distance/speed + stop dwell + traffic delay + occupancy penalty.
    """
    bus = db.query(Bus).filter(Bus.id == payload.bus_id).first()
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found.")

    if not bus.latitude or not bus.longitude:
        return ETAPredictionResponse(estimated_minutes=20.0, confidence=0.5)

    # Destination: end of route GPS (approximate as +0.1 degrees = ~11 km)
    dest_lat = bus.latitude  + 0.05
    dest_lng = bus.longitude + 0.07

    occupancy_pct = (bus.current_occupancy / max(1, bus.capacity)) * 100

    eta = calculate_eta(
        bus_lat=bus.latitude,
        bus_lng=bus.longitude,
        destination_lat=dest_lat,
        destination_lng=dest_lng,
        speed_kmh=bus.speed_kmh or 30.0,
        stops_remaining=5,
        occupancy_pct=occupancy_pct,
    )

    return ETAPredictionResponse(
        estimated_minutes=eta["eta_minutes"],
        confidence=eta["confidence"],
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /ai/predict-crowd
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/predict-crowd", response_model=CrowdPredictionResponse)
def predict_crowd(payload: CrowdPredictionRequest, db: Session = Depends(get_db)):
    """
    Predict crowd level for a bus at given hour/day.

    Logic (MVP - time-pattern heuristic):
    - Peak hours (7-9, 17-19) → High
    - Off-peak weekdays → Medium
    - Weekends off-peak → Low
    In production: replace with a trained RandomForestClassifier.
    """
    bus = db.query(Bus).filter(Bus.id == payload.bus_id).first()
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found.")

    h = payload.hour_of_day
    d = payload.day_of_week  # 0=Monday … 6=Sunday

    is_weekend = d >= 5
    is_peak = (7 <= h <= 9) or (17 <= h <= 19)

    if is_peak and not is_weekend:
        crowd_level = "High"
        occupancy_pct = round(random.uniform(75, 95), 1)
    elif is_weekend or (10 <= h <= 16):
        crowd_level = "Low"
        occupancy_pct = round(random.uniform(10, 40), 1)
    else:
        crowd_level = "Medium"
        occupancy_pct = round(random.uniform(40, 74), 1)

    return CrowdPredictionResponse(
        crowd_level=crowd_level,
        occupancy_percent=occupancy_pct,
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /ai/smart-route
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/smart-route", response_model=SmartRouteResponse)
def smart_route(payload: SmartRouteRequest, db: Session = Depends(get_db)):
    """
    Suggest best routes between origin and destination using the route optimizer.
    Returns top 3 routes ranked by time/distance weighted score.
    """
    all_routes: List[Route] = db.query(Route).filter(Route.is_active == True).all()
    options = optimize_routes(all_routes, payload.origin, payload.destination)

    if not options:
        return SmartRouteResponse(
            recommended_routes=[],
            reason="No matching routes found. Try different keywords e.g. 'Majestic', 'Electronic City'.",
        )

    route_ids = [o.route_id for o in options]
    top_routes = db.query(Route).filter(Route.id.in_(route_ids)).all()
    # Re-order to match optimizer output
    id_to_route = {r.id: r for r in top_routes}
    ordered = [id_to_route[rid] for rid in route_ids if rid in id_to_route]

    tags = {o.route_id: o.tag for o in options}
    reason = f"Found {len(options)} route(s). {options[0].tag.title()} route: {options[0].route_number} ({options[0].duration_min} min)."

    return SmartRouteResponse(
        recommended_routes=[RouteOut.model_validate(r) for r in ordered],
        reason=reason,
    )
