from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import date
from ..core.database import get_db
from ..models import User, Route, Bus, Ticket

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/stats")
def get_dashboard_stats(db: Session = Depends(get_db)):
    # Total Users
    total_users = db.query(User).count()
    
    # Active Routes
    active_routes = db.query(Route).filter(Route.is_active == True).count()
    
    # Active Buses
    active_buses = db.query(Bus).count()
    
    # Tickets Today
    today_str = date.today().isoformat()
    # Simple prefix match for 'YYYY-MM-DD' from isoformat datetime string like '2026-04-24T...'
    # If the column is timestamp string, using startswith is robust
    tickets_today = db.query(Ticket).filter(Ticket.issued_at.like(f"{today_str}%")).count()
    
    # Fallback to total tickets if testing/demo has mostly old dates
    total_tickets = db.query(Ticket).count()

    return {
        "users": total_users,
        "routes": active_routes,
        "buses": active_buses,
        "tickets_today": tickets_today,
        "total_tickets": total_tickets
    }

@router.get("/users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.created_at.desc()).all()
    
    return [
        {
            "id": str(u.id),
            "name": u.name,
            "email": u.email,
            "phone": u.phone,
            "wallet_balance": getattr(u, 'wallet_balance', 0.0),
            "is_verified": u.is_verified,
            "is_active": getattr(u, 'is_active', True),
            "created_at": getattr(u, 'created_at', datetime.utcnow())
        } for u in users
    ]

@router.get("/tickets")
def get_all_tickets(db: Session = Depends(get_db)):
    """Fetch recent tickets across the entire system."""
    tickets = db.query(Ticket).order_by(Ticket.issued_at.desc()).limit(50).all()
    
    return [
        {
            "id": str(t.id),
            "user_id": str(t.user_id),
            "route_id": str(getattr(t, 'route_id', 'N/A')),
            "origin_stop": getattr(t, 'boarding_stop', 'Unknown'),
            "destination_stop": getattr(t, 'alighting_stop', 'Unknown'),
            "fare": float(getattr(t, 'fare_paid', 0.0)),
            "status": getattr(t, 'status', 'ACTIVE'),
            "issued_at": getattr(t, 'issued_at', datetime.utcnow()),
            "qr_data": getattr(t, 'qr_code', '')
        } for t in tickets
    ]
