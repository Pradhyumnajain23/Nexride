"""
NexRide Backend - Authentication Router
Endpoints: /register, /login, /send-otp, /verify-otp, /forgot-password, /reset-password
"""
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import create_access_token, hash_password, verify_password
from app.models import User
from app.schemas import (
    ForgotPasswordRequest,
    LoginRequest,
    OTPRequest,
    OTPVerifyRequest,
    RegisterRequest,
    RegisterResponse,
    ResetPasswordRequest,
    TokenResponse,
    UserOut,
)
from app.services.otp_service import (
    generate_otp,
    save_otp,
    send_otp_email,
    verify_otp,
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/register
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    """
    Register a new user. Sends OTP to the provided email for verification.
    """
    # Check if email already exists
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    # Create user (unverified)
    new_user = User(
        name=payload.name,
        email=payload.email,
        phone=payload.phone,
        hashed_password=hash_password(payload.password),
        is_verified=False,
    )
    db.add(new_user)
    db.commit()

    # Generate and send OTP
    otp = generate_otp()
    save_otp(db, payload.email, otp)
    email_sent = send_otp_email(payload.email, otp, purpose="verification")

    if not email_sent:
        # User created but email failed - still return success (OTP can be resent)
        print(f"[WARN] OTP email failed for {payload.email}")

    return RegisterResponse(
        message="Account created! Please verify your email with the OTP sent.",
        email=payload.email,
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/verify-otp
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/verify-otp")
def verify_email_otp(payload: OTPVerifyRequest, db: Session = Depends(get_db)):
    """
    Verify the OTP sent to the user's email.
    Marks the user as verified on success.
    """
    is_valid = verify_otp(db, payload.email, payload.otp)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OTP.",
        )

    # Mark user verified
    user = db.query(User).filter(User.email == payload.email).first()
    if user:
        user.is_verified = True
        db.commit()

    return {"message": "Email verified successfully! You can now log in."}


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/login
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    """
    Login with email and password. Returns JWT access token.
    """
    user = db.query(User).filter(User.email == payload.email).first()

    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    if not user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email before logging in.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated.",
        )

    token = create_access_token(data={"sub": str(user.id)})
    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserOut.model_validate(user),
    )


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/resend-otp
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/resend-otp")
def resend_otp(payload: OTPRequest, db: Session = Depends(get_db)):
    """Resend OTP to the given email (rate limiting not implemented here)."""
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    otp = generate_otp()
    save_otp(db, payload.email, otp)
    send_otp_email(payload.email, otp, purpose="verification")
    return {"message": "OTP resent. Please check your email."}


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/forgot-password
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/forgot-password")
def forgot_password(payload: ForgotPasswordRequest, db: Session = Depends(get_db)):
    """Sends a password-reset OTP to the user's email."""
    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        # Security: don't reveal if email exists
        return {"message": "If this email is registered, a reset OTP has been sent."}

    otp = generate_otp()
    save_otp(db, payload.email, otp)
    send_otp_email(payload.email, otp, purpose="password reset")
    return {"message": "If this email is registered, a reset OTP has been sent."}


# ─────────────────────────────────────────────────────────────────────────────
# POST /auth/reset-password
# ─────────────────────────────────────────────────────────────────────────────
@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    """Resets password after OTP verification."""
    is_valid = verify_otp(db, payload.email, payload.otp)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP.")

    user = db.query(User).filter(User.email == payload.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    user.hashed_password = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password reset successfully. Please log in."}
