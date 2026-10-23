"""
NexRide Backend - Ticket Router
Endpoints for issuing and viewing digital tickets with QR codes.
"""
import uuid
from datetime import datetime, timedelta, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_access_token
from app.models import Route, Ticket, User
from app.schemas import TicketCreateRequest, TicketOut
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/tickets", tags=["Tickets"])
security = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """Dependency: extracts and validates JWT, returns current User."""
    payload = decode_access_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    user = db.query(User).filter(User.id == int(payload["sub"])).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found.")
    return user


@router.post("/", response_model=TicketOut, status_code=201)
def create_ticket(
    payload: TicketCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Issue a new digital ticket for a route.
    Generates a unique QR code string (UUID-based).
    """
    route = db.query(Route).filter(Route.id == payload.route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found.")
    if not route.is_active:
        raise HTTPException(status_code=400, detail="Route is not active.")

    qr_code = f"NEXRIDE-{uuid.uuid4().hex.upper()}"
    valid_until = datetime.now(timezone.utc) + timedelta(hours=24)

    ticket = Ticket(
        user_id=current_user.id,
        route_id=route.id,
        qr_code=qr_code,
        boarding_stop=payload.boarding_stop,
        alighting_stop=payload.alighting_stop,
        fare_paid=route.fare or 0.0,
        valid_until=valid_until,
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    return ticket


@router.get("/my", response_model=List[TicketOut])
def my_tickets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get all tickets for the currently logged-in user."""
    return (
        db.query(Ticket)
        .filter(Ticket.user_id == current_user.id)
        .order_by(Ticket.issued_at.desc())
        .all()
    )


@router.get("/{ticket_id}", response_model=TicketOut)
def get_ticket(
    ticket_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get a specific ticket by ID (only owner can view)."""
    ticket = (
        db.query(Ticket)
        .filter(Ticket.id == ticket_id, Ticket.user_id == current_user.id)
        .first()
    )
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found.")
    return ticket
