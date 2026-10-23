"""
NexRide Backend - Application Settings
Reads configuration from .env file using pydantic-settings.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
from urllib.parse import quote_plus


class Settings(BaseSettings):
    # ── Database ──────────────────────────────────────
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_NAME: str = "nexride"
    DB_USER: str = "root"
    DB_PASSWORD: str = ""

    # ── JWT ───────────────────────────────────────────
    SECRET_KEY: str = "change_me_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # ── Gmail SMTP ────────────────────────────────────
    SMTP_EMAIL: str = ""
    SMTP_PASSWORD: str = ""

    # ── OTP ───────────────────────────────────────────────────────────────────
    OTP_EXPIRE_MINUTES: int = 10

    # ── Gemini API (response formatting) ──────────────────────────────────────
    GEMINI_API_KEY: str = ""

    @property
    def DATABASE_URL(self) -> str:
        # URL-encode password so special chars like @ don't break the connection string
        encoded_password = quote_plus(self.DB_PASSWORD)
        return (
            f"mysql+pymysql://{self.DB_USER}:{encoded_password}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    """Returns a cached Settings instance (singleton pattern)."""
    return Settings()
