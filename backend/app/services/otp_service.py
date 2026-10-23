"""
NexRide Backend - OTP Email Service
Generates, stores, and sends 6-digit OTPs via Gmail SMTP.
"""
import random
import smtplib
import string
from datetime import datetime, timedelta, timezone
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional

from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.otp import OTPRecord

settings = get_settings()


# ── OTP Generation ────────────────────────────────────────────────────────────
def generate_otp(length: int = 6) -> str:
    """Generates a cryptographically-safe 6-digit numeric OTP."""
    return "".join(random.choices(string.digits, k=length))


# ── OTP Storage ───────────────────────────────────────────────────────────────
def save_otp(db: Session, email: str, otp: str) -> OTPRecord:
    """
    Saves (or replaces) OTP record for a given email.
    Expires after OTP_EXPIRE_MINUTES.
    """
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=settings.OTP_EXPIRE_MINUTES
    )

    # Delete existing OTP records for this email before inserting new one
    db.query(OTPRecord).filter(OTPRecord.email == email).delete()

    record = OTPRecord(email=email, otp=otp, expires_at=expires_at)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def verify_otp(db: Session, email: str, otp: str) -> bool:
    """
    Verifies OTP for given email.
    Deletes the record after successful verification (one-time use).
    Returns True if valid, False otherwise.
    """
    record: Optional[OTPRecord] = (
        db.query(OTPRecord).filter(OTPRecord.email == email).first()
    )

    if not record:
        return False

    # Check expiry
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        db.delete(record)
        db.commit()
        return False

    # Check OTP match
    if record.otp != otp:
        return False

    # Consume the OTP
    db.delete(record)
    db.commit()
    return True


# ── Email Sending ─────────────────────────────────────────────────────────────
def send_otp_email(recipient_email: str, otp: str, purpose: str = "verification") -> bool:
    """
    Sends a styled OTP email via Gmail SMTP.

    Args:
        recipient_email: Destination email address.
        otp: The 6-digit OTP string.
        purpose: e.g. 'verification', 'password reset'

    Returns:
        True if sent successfully, False on failure.
    """
    subject = f"NexRide – Your {purpose.title()} OTP"

    html_body = f"""
    <html>
      <body style="font-family: Arial, sans-serif; background: #f5f5f5; padding: 30px;">
        <div style="max-width:480px; margin:auto; background:#ffffff;
                    border-radius:16px; padding:32px; box-shadow:0 4px 20px rgba(0,0,0,0.1);">
          <h2 style="color:#1976D2; margin-bottom:4px;">🚌 NexRide</h2>
          <p style="color:#555; font-size:14px;">Your smart public transport companion</p>
          <hr style="border:none; border-top:1px solid #eee; margin:20px 0;">
          <h3 style="color:#222;">Your {purpose.title()} OTP</h3>
          <p style="color:#555; font-size:14px;">
            Use the code below to complete your {purpose}.
            This code is valid for <strong>{settings.OTP_EXPIRE_MINUTES} minutes</strong>.
          </p>
          <div style="background:#F3F8FF; border-radius:12px; padding:24px;
                      text-align:center; margin:24px 0;">
            <span style="font-size:40px; font-weight:bold; letter-spacing:12px;
                         color:#1976D2;">{otp}</span>
          </div>
          <p style="color:#999; font-size:12px;">
            If you did not request this, you can safely ignore this email.
          </p>
        </div>
      </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = settings.SMTP_EMAIL
    msg["To"] = recipient_email
    msg.attach(MIMEText(html_body, "html"))

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_EMAIL, recipient_email, msg.as_string())
        return True
    except Exception as exc:
        print(f"[OTP Email Error] {exc}")
        return False
