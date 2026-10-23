"""
NexRide Backend - Database Engine & Session Factory
Uses SQLAlchemy 2.x with connection pooling.
"""
from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import get_settings

settings = get_settings()

# ── Engine ────────────────────────────────────────────────────────────────────
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,       # reconnect on stale connections
    pool_size=10,
    max_overflow=20,
    echo=False,               # set True to log SQL queries during dev
)

# ── Session Factory ───────────────────────────────────────────────────────────
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


# ── Base Class for ORM Models ─────────────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependency Injection Helper ───────────────────────────────────────────────
def get_db():
    """
    FastAPI dependency that yields a DB session and always closes it.
    Usage:  db: Session = Depends(get_db)
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
