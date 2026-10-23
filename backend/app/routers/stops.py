"""
NexRide Backend - Stops Router
Endpoints for bus stops and route-specific stop sequences.
"""
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.core.database import get_db
from app.models import Stop, RouteStop, Route

router = APIRouter(prefix="/stops", tags=["Stops"])


class StopOut(BaseModel):
    id:        int
    name:      str
    latitude:  float | None
    longitude: float | None

    model_config = {"from_attributes": True}


class RouteStopOut(BaseModel):
    sequence:              int
    stop:                  StopOut
    distance_from_start_km: float | None

    model_config = {"from_attributes": True}


@router.get("/", response_model=List[StopOut])
def get_all_stops(db: Session = Depends(get_db)):
    """Return all bus stops."""
    return db.query(Stop).order_by(Stop.name).all()


@router.get("/route/{route_id}", response_model=List[RouteStopOut])
def get_stops_for_route(route_id: int, db: Session = Depends(get_db)):
    """Return all stops for a specific route, in sequence order."""
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found.")

    route_stops = (
        db.query(RouteStop)
        .filter(RouteStop.route_id == route_id)
        .order_by(RouteStop.sequence)
        .all()
    )
    return route_stops
