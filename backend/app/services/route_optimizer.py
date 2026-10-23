"""
NexRide - Route Optimization Engine
Scores routes by time, distance, and transfers — returns top 2–3 options.
"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class RouteOption:
    route_id: int
    route_number: str
    name: str
    origin: str
    destination: str
    distance_km: float
    duration_min: int
    fare: float
    tag: str           # "fastest" | "shortest" | "least_transfers"
    score: float


def optimize_routes(
    routes: list,
    origin_query: str,
    destination_query: str,
    time_weight: float = 0.6,
    distance_weight: float = 0.4,
) -> list[RouteOption]:
    """
    Score and rank routes for a given origin→destination query.

    Scoring: score = time_weight * norm_time + distance_weight * norm_distance
    Lower score is better.

    Returns a list of RouteOption sorted by score (best first), max 3.
    """
    origin_lower = origin_query.lower().strip()
    dest_lower   = destination_query.lower().strip()

    # ── Step 1: Relevance filtering ───────────────────────────────────────────
    candidates = []
    for r in routes:
        if not r.is_active:
            continue
        match_score = 0

        # Exact or partial origin match
        if origin_lower in r.origin.lower():
            match_score += 3
        elif any(tok in r.origin.lower() for tok in origin_lower.split()):
            match_score += 1

        # Exact or partial destination match
        if dest_lower in r.destination.lower():
            match_score += 3
        elif any(tok in r.destination.lower() for tok in dest_lower.split()):
            match_score += 1

        # Route name contains either
        if origin_lower in r.name.lower() or dest_lower in r.name.lower():
            match_score += 1

        if match_score > 0:
            candidates.append((match_score, r))

    if not candidates:
        return []

    # Sort by match quality descending, take top 5 for scoring
    candidates.sort(key=lambda x: x[0], reverse=True)
    top_candidates = [r for _, r in candidates[:5]]

    # ── Step 2: Normalise metrics ─────────────────────────────────────────────
    durations  = [r.estimated_duration_min or 30 for r in top_candidates]
    distances  = [r.distance_km or 10.0 for r in top_candidates]

    max_dur    = max(durations) or 1
    max_dist   = max(distances) or 1

    # ── Step 3: Score + rank ──────────────────────────────────────────────────
    scored = []
    for r in top_candidates:
        dur  = r.estimated_duration_min or 30
        dist = r.distance_km or 10.0
        score = (time_weight * dur / max_dur) + (distance_weight * dist / max_dist)
        scored.append((score, r))

    scored.sort(key=lambda x: x[0])

    # ── Step 4: Tag top results ───────────────────────────────────────────────
    options = []
    by_time = sorted(scored, key=lambda x: x[1].estimated_duration_min or 999)
    by_dist = sorted(scored, key=lambda x: x[1].distance_km or 999)

    tags_assigned = {}
    if by_time:
        tags_assigned[by_time[0][1].id] = "fastest"
    if by_dist and by_dist[0][1].id not in tags_assigned:
        tags_assigned[by_dist[0][1].id] = "shortest"

    for score, r in scored[:3]:
        tag = tags_assigned.get(r.id, "alternate")
        options.append(RouteOption(
            route_id=r.id,
            route_number=r.route_number,
            name=r.name,
            origin=r.origin,
            destination=r.destination,
            distance_km=r.distance_km or 0.0,
            duration_min=r.estimated_duration_min or 0,
            fare=r.fare or 0.0,
            tag=tag,
            score=round(score, 3),
        ))

    return options
