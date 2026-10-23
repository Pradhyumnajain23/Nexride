"""
NexRide Backend - Route Router
Search and list transit routes.
"""
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import Route
from app.schemas import RouteOut

router = APIRouter(prefix="/routes", tags=["Routes"])


@router.get("/", response_model=List[RouteOut])
def get_routes(
    search: Optional[str] = Query(None, description="Search by name/origin/destination"),
    db: Session = Depends(get_db),
):
    """Get all active routes, with optional keyword search."""
    query = db.query(Route).filter(Route.is_active == True)
    if search:
        like = f"%{search}%"
        query = query.filter(
            Route.name.like(like)
            | Route.origin.like(like)
            | Route.destination.like(like)
            | Route.route_number.like(like)
        )
    return query.all()


@router.get("/{route_id}", response_model=RouteOut)
def get_route(route_id: int, db: Session = Depends(get_db)):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found.")
    return route
