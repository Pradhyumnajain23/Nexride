"""
NexRide Backend - Application Entry Point
FastAPI app with CORS, routers, and auto table creation on startup.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.database import engine, Base
from app.routers import auth, buses, routes, tickets, ai, stops, chat, admin


# ─────────────────────────────────────────────────────────────────────────────
# Lifespan: runs on startup and shutdown
# ─────────────────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables if they don't exist (auto-migrate for dev)
    Base.metadata.create_all(bind=engine)
    print("[OK] Database tables ready.")
    yield
    print("[--] NexRide backend shutting down.")


# ─────────────────────────────────────────────────────────────────────────────
# App Instance
# ─────────────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="NexRide API",
    description="AI-powered public transport system backend",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)


# ─────────────────────────────────────────────────────────────────────────────
# CORS (allow Flutter app to call the API)
# ─────────────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # restrict to your domain in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────────────────────────────────────
# Routers
# ─────────────────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(buses.router)
app.include_router(routes.router)
app.include_router(tickets.router)
app.include_router(ai.router)
app.include_router(stops.router)
app.include_router(chat.router)
app.include_router(admin.router)


# ─────────────────────────────────────────────────────────────────────────────
# Health Check
# ─────────────────────────────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "app": "NexRide API", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}
