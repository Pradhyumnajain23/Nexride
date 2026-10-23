"""
NexRide Backend - Bus Router
Endpoints for real-time bus data and location updates.
"""
from datetime import datetime, timezone
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import Bus
from app.schemas import BusLocationUpdate, BusOut

router = APIRouter(prefix="/buses", tags=["Buses"])


@router.get("/", response_model=List[BusOut])
def get_all_buses(
    status: Optional[str] = Query(None, description="Filter by status: active/inactive"),
    route_id: Optional[int] = Query(None, description="Filter by route"),
    db: Session = Depends(get_db),
):
    """Get all buses with optional filters."""
    query = db.query(Bus)
    if status:
        query = query.filter(Bus.status == status)
    if route_id:
        query = query.filter(Bus.route_id == route_id)
    return query.all()


@router.get("/nearby", response_model=List[BusOut])
def get_nearby_buses(
    lat: float = Query(..., description="User latitude"),
    lng: float = Query(..., description="User longitude"),
    radius_km: float = Query(2.0, description="Search radius in km"),
    db: Session = Depends(get_db),
):
    """
    Get active buses within radius_km of given coordinates.
    Uses Haversine approximation (simplified for MVP).
    """
    # Approximate degree per km at equator
    lat_delta = radius_km / 111.0
    lng_delta = radius_km / (111.0 * abs(max(0.01, lat)) ** 0.01)

    buses = (
        db.query(Bus)
        .filter(
            Bus.status == "active",
            Bus.latitude.isnot(None),
            Bus.longitude.isnot(None),
            Bus.latitude.between(lat - lat_delta, lat + lat_delta),
            Bus.longitude.between(lng - lng_delta, lng + lng_delta),
        )
        .all()
    )
    return buses


@router.get("/{bus_id}", response_model=BusOut)
def get_bus(bus_id: int, db: Session = Depends(get_db)):
    """Get a single bus by ID."""
    bus = db.query(Bus).filter(Bus.id == bus_id).first()
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found.")
    return bus


@router.patch("/{bus_id}/location")
def update_bus_location(
    bus_id: int,
    payload: BusLocationUpdate,
    db: Session = Depends(get_db),
):
    """
    Update bus GPS position and occupancy (called by bus hardware/driver app).
    In production this would be protected by an API key.
    """
    bus = db.query(Bus).filter(Bus.id == bus_id).first()
    if not bus:
        raise HTTPException(status_code=404, detail="Bus not found.")

    bus.latitude = payload.latitude
    bus.longitude = payload.longitude
    bus.last_location_update = datetime.now(timezone.utc)

    if payload.speed_kmh is not None:
        bus.speed_kmh = payload.speed_kmh
    if payload.current_occupancy is not None:
        bus.current_occupancy = payload.current_occupancy

    db.commit()
    return {"message": "Location updated."}
