"""
NexRide Backend - Pydantic Schemas
Request & Response validation models for all API endpoints.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


# ─────────────────────────────────────────────────────────────────────────────
# AUTH SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, example="Arjun Kumar")
    email: EmailStr = Field(..., example="arjun@example.com")
    phone: Optional[str] = Field(None, example="+919876543210")
    password: str = Field(..., min_length=6, example="SecurePass@123")


class RegisterResponse(BaseModel):
    message: str
    email: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"


class OTPRequest(BaseModel):
    email: EmailStr


class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6, example="123456")


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6)


# ─────────────────────────────────────────────────────────────────────────────
# USER SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class UserOut(BaseModel):
    id: int
    name: str
    email: str
    phone: Optional[str]
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ─────────────────────────────────────────────────────────────────────────────
# BUS SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class BusOut(BaseModel):
    id: int
    bus_number: str
    route_id: Optional[int]
    capacity: int
    current_occupancy: int
    latitude: Optional[float]
    longitude: Optional[float]
    speed_kmh: Optional[float]
    status: str
    last_location_update: Optional[datetime]

    model_config = {"from_attributes": True}


class BusLocationUpdate(BaseModel):
    latitude: float
    longitude: float
    speed_kmh: Optional[float] = None
    current_occupancy: Optional[int] = None


# ─────────────────────────────────────────────────────────────────────────────
# ROUTE SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class RouteOut(BaseModel):
    id: int
    route_number: str
    name: str
    origin: str
    destination: str
    distance_km: Optional[float]
    estimated_duration_min: Optional[int]
    fare: Optional[float]
    is_active: bool

    model_config = {"from_attributes": True}


# ─────────────────────────────────────────────────────────────────────────────
# TICKET SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class TicketCreateRequest(BaseModel):
    route_id: int
    boarding_stop: Optional[str] = None
    alighting_stop: Optional[str] = None


class TicketOut(BaseModel):
    id: int
    route_id: int
    qr_code: str
    boarding_stop: Optional[str]
    alighting_stop: Optional[str]
    fare_paid: float
    status: str
    issued_at: datetime
    valid_until: Optional[datetime]

    model_config = {"from_attributes": True}


# ─────────────────────────────────────────────────────────────────────────────
# AI SCHEMAS
# ─────────────────────────────────────────────────────────────────────────────
class ETAPredictionRequest(BaseModel):
    bus_id: int
    stop_name: str


class ETAPredictionResponse(BaseModel):
    estimated_minutes: float
    confidence: float


class CrowdPredictionRequest(BaseModel):
    bus_id: int
    hour_of_day: int
    day_of_week: int


class CrowdPredictionResponse(BaseModel):
    crowd_level: str   # "Low" | "Medium" | "High"
    occupancy_percent: float


class SmartRouteRequest(BaseModel):
    origin: str
    destination: str


class SmartRouteResponse(BaseModel):
    recommended_routes: list[RouteOut]
    reason: str


# Forward ref update
TokenResponse.model_rebuild()
