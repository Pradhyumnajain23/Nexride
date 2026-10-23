"""
NexRide Backend - ORM Models

Defines all database table models using SQLAlchemy 2.x declarative style.
"""
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Boolean, DateTime, Enum, Float, ForeignKey,
    Integer, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


# ─────────────────────────────────────────────────────────────────────────────
# Users
# ─────────────────────────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )

    tickets: Mapped[list["Ticket"]] = relationship(back_populates="user")
    passes: Mapped[list["Pass"]] = relationship(back_populates="user")


# ─────────────────────────────────────────────────────────────────────────────
# OTP Records (temporary storage)
# ─────────────────────────────────────────────────────────────────────────────
class OTPRecord(Base):
    __tablename__ = "otp_records"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(150), index=True)
    otp: Mapped[str] = mapped_column(String(10))
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())


# ─────────────────────────────────────────────────────────────────────────────
# Routes
# ─────────────────────────────────────────────────────────────────────────────
class Route(Base):
    __tablename__ = "routes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    route_number: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(200))
    origin: Mapped[str] = mapped_column(String(150))
    destination: Mapped[str] = mapped_column(String(150))
    distance_km: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    estimated_duration_min: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    fare: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    buses: Mapped[list["Bus"]] = relationship(back_populates="route")
    tickets: Mapped[list["Ticket"]] = relationship(back_populates="route")
    route_stops: Mapped[list["RouteStop"]] = relationship(back_populates="route", order_by="RouteStop.sequence")


# ─────────────────────────────────────────────────────────────────────────────
# Stops
# ─────────────────────────────────────────────────────────────────────────────
class Stop(Base):
    __tablename__ = "stops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    route_stops: Mapped[list["RouteStop"]] = relationship(back_populates="stop")


# ─────────────────────────────────────────────────────────────────────────────
# RouteStops (junction: which stops a route passes through, in order)
# ─────────────────────────────────────────────────────────────────────────────
class RouteStop(Base):
    __tablename__ = "route_stops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    route_id: Mapped[int] = mapped_column(Integer, ForeignKey("routes.id"), index=True)
    stop_id: Mapped[int] = mapped_column(Integer, ForeignKey("stops.id"), index=True)
    sequence: Mapped[int] = mapped_column(Integer)  # order along the route
    distance_from_start_km: Mapped[Optional[float]] = mapped_column(Float, nullable=True)

    route: Mapped["Route"] = relationship(back_populates="route_stops")
    stop: Mapped["Stop"] = relationship(back_populates="route_stops")


# ─────────────────────────────────────────────────────────────────────────────
# Buses
# ─────────────────────────────────────────────────────────────────────────────
class Bus(Base):
    __tablename__ = "buses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    bus_number: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    route_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("routes.id"), nullable=True
    )
    capacity: Mapped[int] = mapped_column(Integer, default=50)
    current_occupancy: Mapped[int] = mapped_column(Integer, default=0)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    speed_kmh: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    status: Mapped[str] = mapped_column(
        Enum("active", "inactive", "maintenance"), default="active"
    )
    last_location_update: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    route: Mapped[Optional["Route"]] = relationship(back_populates="buses")


# ─────────────────────────────────────────────────────────────────────────────
# Tickets
# ─────────────────────────────────────────────────────────────────────────────
class Ticket(Base):
    __tablename__ = "tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"))
    route_id: Mapped[int] = mapped_column(Integer, ForeignKey("routes.id"))
    qr_code: Mapped[str] = mapped_column(String(500), unique=True)
    boarding_stop: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    alighting_stop: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    fare_paid: Mapped[float] = mapped_column(Float)
    is_used: Mapped[bool] = mapped_column(Boolean, default=False)
    status: Mapped[str] = mapped_column(
        Enum("active", "used", "expired", "cancelled"), default="active"
    )
    issued_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    valid_until: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    user: Mapped["User"] = relationship(back_populates="tickets")
    route: Mapped["Route"] = relationship(back_populates="tickets")


# ─────────────────────────────────────────────────────────────────────────────
# Passes (Monthly / Weekly)
# ─────────────────────────────────────────────────────────────────────────────
class Pass(Base):
    __tablename__ = "passes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"))
    pass_type: Mapped[str] = mapped_column(Enum("weekly", "monthly"), default="monthly")
    route_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("routes.id"), nullable=True
    )
    price_paid: Mapped[float] = mapped_column(Float)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    start_date: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    end_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    user: Mapped["User"] = relationship(back_populates="passes")
