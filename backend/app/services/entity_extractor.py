"""
NexRide - Entity Extractor
Pulls source, destination, route number, and bus ID from user messages.
"""
import re


# Common Bengaluru stop names for fuzzy matching hints
_KNOWN_STOPS = [
    "majestic", "kempegowda bus station", "mg road", "brigade road",
    "koramangala", "indiranagar", "whitefield", "electronic city",
    "kr puram", "yeshwanthpur", "banashankari", "jayanagar",
    "hebbal", "silk board", "marathahalli", "bellandur",
    "yelahanka", "kengeri", "rajajinagar", "malleswaram",
    "basavanagudi", "vijayanagar", "btm layout", "hsr layout",
    "sarjapur", "domlur", "richmond circle", "shivajinagar",
    "k r market", "national college", "lalbagh",
]


def _normalize(text: str) -> str:
    return text.lower().strip()


def _extract_from_to(text: str) -> tuple[str | None, str | None]:
    """
    Extract source and destination from patterns like:
    - "from X to Y"
    - "X to Y"
    Returns (source, destination) or (None, None).
    """
    # Pattern: "from <source> to <destination>"
    m = re.search(r"\bfrom\s+(.+?)\s+to\s+(.+?)(?:\s*$|\s*[?.!,])", text, re.IGNORECASE)
    if m:
        return m.group(1).strip(), m.group(2).strip()

    # Simpler: "X to Y" (no "from")
    m = re.search(r"^(.+?)\s+to\s+(.+?)(?:\s*$|\s*[?.!,])", text, re.IGNORECASE)
    if m:
        src = m.group(1).strip()
        dst = m.group(2).strip()
        # Avoid picking up "going to", "how to", etc.
        skip_words = {"how", "going", "want", "need", "bus", "route", "get", "travel"}
        if src.lower() not in skip_words:
            return src, dst

    return None, None


def _extract_route_number(text: str) -> str | None:
    """Extract BMTC-style route numbers: 401A, 500D, 356E, etc."""
    # Pattern: digits optionally followed by uppercase letter(s)
    m = re.search(r"\b(\d{2,4}[A-Z]{0,2})\b", text)
    if m:
        return m.group(1)
    return None


def _extract_bus_id(text: str) -> int | None:
    """Extract a bus numeric ID from texts like 'bus 12' or 'bus id 7'."""
    m = re.search(r"\bbus\s+(?:id\s+)?(\d+)\b", text, re.IGNORECASE)
    if m:
        return int(m.group(1))
    return None


def extract_entities(message: str) -> dict:
    """
    Returns a dict with extracted entities (None if not found):
    {
        "source": str | None,
        "destination": str | None,
        "route_number": str | None,
        "bus_id": int | None,
    }
    """
    text = _normalize(message)
    source, destination = _extract_from_to(text)
    route_number = _extract_route_number(message)  # preserve case for route numbers
    bus_id = _extract_bus_id(text)

    return {
        "source":       source,
        "destination":  destination,
        "route_number": route_number,
        "bus_id":       bus_id,
    }
