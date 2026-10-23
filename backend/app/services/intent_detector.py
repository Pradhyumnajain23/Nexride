"""
NexRide - Intent Detection Engine
Classifies user messages into transport intents using keyword matching.
"""
import re

# ── Intent keyword maps ───────────────────────────────────────────────────────

_ROUTE_SEARCH_KEYWORDS = [
    "how to go", "how do i go", "how can i go", "route from", "route to",
    "bus from", "bus to", "which bus", "get from", "travel from",
    "going from", "directions", "way to reach", "how to reach",
    "path from", "journey from", "commute", "how to get to",
]

_BUS_TRACKING_KEYWORDS = [
    "where is bus", "where is the bus", "track bus", "bus location",
    "current location", "location of bus", "bus number", "bus status",
    "live location", "where is route", "where is my bus",
]

_ETA_KEYWORDS = [
    "when will", "how long", "how much time", "eta", "arrival time",
    "expected time", "will it arrive", "time to reach", "minutes away",
    "how many minutes", "time for bus", "when is bus",
]

_TICKET_BOOKING_KEYWORDS = [
    "book ticket", "buy ticket", "purchase ticket", "ticket from",
    "book a ticket", "need a ticket", "get ticket", "issue ticket",
    "book bus", "reserve seat",
]

_GREETING_KEYWORDS = [
    "hi", "hello", "hey", "good morning", "good afternoon", "good evening",
    "help", "what can you do", "what do you do", "what are you",
    "who are you", "start", "begin",
]


INTENT_PRIORITY = [
    "ticket_booking",
    "bus_tracking",
    "eta_query",
    "route_search",
    "greeting",
    "general_query",
]


def detect_intent(message: str) -> str:
    """
    Returns the detected intent string.

    Priority order: ticket_booking > bus_tracking > eta_query > route_search > greeting > general_query
    """
    text = message.lower().strip()

    def matches(keywords: list[str]) -> bool:
        return any(kw in text for kw in keywords)

    if matches(_TICKET_BOOKING_KEYWORDS):
        return "ticket_booking"
    if matches(_BUS_TRACKING_KEYWORDS):
        return "bus_tracking"
    if matches(_ETA_KEYWORDS):
        return "eta_query"
    if matches(_ROUTE_SEARCH_KEYWORDS):
        return "route_search"
    if matches(_GREETING_KEYWORDS):
        return "greeting"

    # Fallback: if message contains "from ... to ..." pattern, treat as route search
    if re.search(r"\bfrom\b.{1,40}\bto\b", text):
        return "route_search"

    return "general_query"
