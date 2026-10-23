"""
NexRide - Chatbot Orchestrator Service
Flow: Intent → Entity → Backend Logic → Structured Data → Gemini → Human-like reply

Architecture:
- Backend logic drives ALL decisions (route lookup, ETA calc, bus tracking)
- Gemini (gemini-2.0-flash) ONLY formats the final structured data into natural language
- If GEMINI_API_KEY is not set → graceful fallback to friendly template responses
"""
from __future__ import annotations
from sqlalchemy.orm import Session

from app.models import Bus, Route
from app.services.route_optimizer import optimize_routes
from app.services.eta_service import calculate_eta
from app.core.config import get_settings


# ── Gemini formatter ──────────────────────────────────────────────────────────

_SYSTEM_PROMPT = (
    "You are NexRide, a warm and helpful Bengaluru bus assistant. "
    "You receive structured transport data and must turn it into a SHORT, "
    "natural, human-like message (2-3 sentences max). "
    "\nStrict rules:\n"
    "- Sound like a friendly local, NOT a robot or API\n"
    "- Keep ALL numbers (route numbers, times, fares, km) exactly as given\n"
    "- Add 1 relevant emoji at the end\n"
    "- NEVER say 'structured data', 'backend', 'API', or 'based on the data'\n"
    "- If multiple route options exist, mention the best first, hint at others naturally\n"
    "- Keep it under 60 words"
)


def _gemini_format(structured_text: str, user_message: str) -> str | None:
    """
    Format structured backend data into human-like response using Gemini.
    Returns None if API key missing or call fails (caller uses template fallback).
    """
    api_key = get_settings().GEMINI_API_KEY.strip()
    if not api_key:
        return None

    try:
        import google.generativeai as genai  # lazy import
        genai.configure(api_key=api_key)

        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            system_instruction=_SYSTEM_PROMPT,
        )

        prompt = (
            f"User asked: \"{user_message}\"\n\n"
            f"Backend data to format:\n{structured_text}\n\n"
            "Write a natural, friendly reply:"
        )

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                max_output_tokens=120,
                temperature=0.65,
            ),
        )
        return response.text.strip()

    except Exception:
        return None   # graceful fallback


def _polish(raw: str, user_message: str) -> str:
    """Try Gemini polish; fall back to template response if unavailable."""
    polished = _gemini_format(raw, user_message)
    return polished if polished else raw


# ── Intent handlers (backend logic → structured text) ────────────────────────

def _handle_route_search(entities: dict, db: Session, user_msg: str) -> str:
    src = (entities.get("source") or "").strip()
    dst = (entities.get("destination") or "").strip()

    if not src or not dst:
        return (
            "I'd love to help! Tell me your starting point and destination. "
            "For example: 'How to go from Majestic to Electronic City?' 😊"
        )

    routes = db.query(Route).filter(Route.is_active == True).all()
    options = optimize_routes(routes, src, dst)

    if not options:
        return (
            f"Hmm, I couldn't find a direct route from {src} to {dst}. "
            "Try nearby landmarks like 'Majestic' or 'MG Road', "
            "or browse the Routes tab! 🗺️"
        )

    structured = f"Routes from {src} to {dst}:\n"
    for opt in options:
        structured += (
            f"- Route {opt.route_number} ({opt.name}): "
            f"{opt.duration_min} min, {opt.distance_km:.1f} km, "
            f"fare ₹{opt.fare:.0f} [{opt.tag}]\n"
        )

    return _polish(structured, user_msg)


def _handle_bus_tracking(entities: dict, db: Session, user_msg: str) -> str:
    bus_id    = entities.get("bus_id")
    route_num = entities.get("route_number")

    bus: Bus | None = None
    if bus_id:
        bus = db.query(Bus).filter(Bus.id == bus_id).first()
    elif route_num:
        route = db.query(Route).filter(
            Route.route_number.ilike(route_num)).first()
        if route:
            bus = db.query(Bus).filter(
                Bus.route_id == route.id, Bus.status == "active").first()

    if not bus:
        hint = route_num or (f"ID {bus_id}" if bus_id else "that bus")
        return (
            f"I couldn't find an active bus for {hint} right now. "
            "It might be off-route or resting. Check the live map in the Track tab! 🗺️"
        )

    occ_pct = (bus.current_occupancy / max(1, bus.capacity)) * 100
    crowd   = "crowded" if occ_pct > 70 else ("moderate" if occ_pct > 40 else "spacious")

    eta_str = ""
    if bus.latitude and bus.longitude:
        eta = calculate_eta(
            bus_lat=bus.latitude, bus_lng=bus.longitude,
            destination_lat=bus.latitude + 0.05,
            destination_lng=bus.longitude + 0.05,
            speed_kmh=bus.speed_kmh or 30.0,
            occupancy_pct=occ_pct,
        )
        eta_str = f", ETA ~{eta['eta_minutes']} min, {eta['traffic']} traffic"

    route_str = f"on Route {bus.route.route_number}" if bus.route else ""
    structured = (
        f"Bus {bus.bus_number} {route_str}: "
        f"speed {bus.speed_kmh or '?'} km/h{eta_str}, "
        f"capacity {bus.current_occupancy}/{bus.capacity} ({crowd}), "
        f"status: {bus.status}"
    )
    return _polish(structured, user_msg)


def _handle_eta_query(entities: dict, db: Session, user_msg: str) -> str:
    route_num = entities.get("route_number")

    bus: Bus | None = None
    if route_num:
        route = db.query(Route).filter(
            Route.route_number.ilike(route_num)).first()
        if route:
            bus = db.query(Bus).filter(
                Bus.route_id == route.id, Bus.status == "active",
                Bus.latitude.isnot(None)).first()

    if not bus:
        bus = db.query(Bus).filter(
            Bus.status == "active", Bus.latitude.isnot(None)).first()

    if not bus or not bus.latitude:
        return (
            "I need a valid bus or route to estimate the ETA. "
            "Try: 'When will bus 401A arrive?' ⏱️"
        )

    occ_pct = (bus.current_occupancy / max(1, bus.capacity)) * 100
    eta = calculate_eta(
        bus_lat=bus.latitude, bus_lng=bus.longitude,
        destination_lat=bus.latitude + 0.05,
        destination_lng=bus.longitude + 0.05,
        speed_kmh=bus.speed_kmh or 30.0,
        occupancy_pct=occ_pct,
    )
    route_str = f" (Route {bus.route.route_number})" if bus.route else ""
    structured = (
        f"Bus {bus.bus_number}{route_str}: "
        f"ETA {eta['eta_minutes']} minutes, "
        f"distance ~{eta['distance_km']} km, "
        f"traffic: {eta['traffic']}, "
        f"confidence: {int(eta['confidence'] * 100)}%"
    )
    return _polish(structured, user_msg)


def _handle_ticket_booking(entities: dict, db: Session, user_msg: str) -> str:
    src = (entities.get("source") or "").strip()
    dst = (entities.get("destination") or "").strip()

    if src and dst:
        routes = db.query(Route).filter(Route.is_active == True).all()
        options = optimize_routes(routes, src, dst)
        if options:
            opt = options[0]
            structured = (
                f"Best route for ticket from {src} to {dst}: "
                f"Route {opt.route_number}, fare ₹{opt.fare:.0f}, "
                f"duration {opt.duration_min} min. "
                "Purchase in the Tickets tab."
            )
            return _polish(structured, user_msg)

    return (
        "To book a ticket, head to the **Tickets** tab — pick your route, "
        "pay, and get a QR code instantly! 🎫\n\n"
        "Or tell me your source and destination and I'll find the best route!"
    )


def _handle_greeting() -> str:
    return (
        "👋 Hey! I'm your NexRide Assistant — your smart Bengaluru bus buddy!\n\n"
        "Here's what I can help with:\n"
        "🗺️ **Find routes** — 'How to go from Majestic to Whitefield?'\n"
        "🚌 **Track buses** — 'Where is bus 401A?'\n"
        "⏱️ **Get ETA** — 'When will route 500D arrive?'\n"
        "🎫 **Book tickets** — 'Book from MG Road to Electronic City'\n\n"
        "What do you need? 😊"
    )


def _handle_general() -> str:
    return (
        "Hmm, I didn't quite catch that! I'm best at helping with Bengaluru buses. 🚌\n\n"
        "Try asking:\n"
        "• 'Route from Koramangala to Whitefield'\n"
        "• 'Where is bus 401A?'\n"
        "• 'Book ticket from Majestic to Electronic City'\n"
        "• 'ETA for route 500D?'"
    )


# ── Main orchestrator ─────────────────────────────────────────────────────────

def process_message(intent: str, entities: dict, user_message: str, db: Session) -> str:
    """
    Routes intent → handler → structured backend data → Gemini polish → reply.
    """
    if intent == "route_search":
        return _handle_route_search(entities, db, user_message)
    elif intent == "bus_tracking":
        return _handle_bus_tracking(entities, db, user_message)
    elif intent == "eta_query":
        return _handle_eta_query(entities, db, user_message)
    elif intent == "ticket_booking":
        return _handle_ticket_booking(entities, db, user_message)
    elif intent == "greeting":
        return _handle_greeting()
    else:
        return _handle_general()
