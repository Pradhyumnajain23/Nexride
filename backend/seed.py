"""
NexRide - BMTC Realistic Seed Script
Populates the database with realistic Bengaluru BMTC routes, stops, and buses.
Run: python seed.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from app.core.database import SessionLocal, engine, Base
from app.models import Route, Bus, Stop, RouteStop  # noqa

# Create all tables (safe — uses CREATE TABLE IF NOT EXISTS)
Base.metadata.create_all(bind=engine)

db = SessionLocal()


# ── 1. BMTC-Style Routes ───────────────────────────────────────────────────────

routes_data = [
    {
        "route_number": "401A",
        "name": "Majestic ↔ Electronic City Phase 1",
        "origin": "Majestic",
        "destination": "Electronic City",
        "distance_km": 26.8,
        "estimated_duration_min": 65,
        "fare": 55.0,
    },
    {
        "route_number": "500D",
        "name": "Majestic ↔ Whitefield",
        "origin": "Majestic",
        "destination": "Whitefield",
        "distance_km": 22.5,
        "estimated_duration_min": 55,
        "fare": 45.0,
    },
    {
        "route_number": "356E",
        "name": "KR Puram ↔ MG Road",
        "origin": "KR Puram",
        "destination": "MG Road",
        "distance_km": 14.3,
        "estimated_duration_min": 40,
        "fare": 30.0,
    },
    {
        "route_number": "600B",
        "name": "Yeshwanthpur ↔ Koramangala",
        "origin": "Yeshwanthpur",
        "destination": "Koramangala",
        "distance_km": 18.6,
        "estimated_duration_min": 50,
        "fare": 40.0,
    },
    {
        "route_number": "201C",
        "name": "Hebbal ↔ Banashankari",
        "origin": "Hebbal",
        "destination": "Banashankari",
        "distance_km": 20.2,
        "estimated_duration_min": 52,
        "fare": 42.0,
    },
    {
        "route_number": "333G",
        "name": "Majestic ↔ Marathahalli",
        "origin": "Majestic",
        "destination": "Marathahalli",
        "distance_km": 19.4,
        "estimated_duration_min": 48,
        "fare": 38.0,
    },
    {
        "route_number": "215K",
        "name": "Kengeri ↔ MG Road",
        "origin": "Kengeri",
        "destination": "MG Road",
        "distance_km": 24.1,
        "estimated_duration_min": 60,
        "fare": 50.0,
    },
    {
        "route_number": "117F",
        "name": "Yelahanka ↔ Majestic",
        "origin": "Yelahanka",
        "destination": "Majestic",
        "distance_km": 16.9,
        "estimated_duration_min": 45,
        "fare": 35.0,
    },
    {
        "route_number": "502B",
        "name": "BTM Layout ↔ Whitefield",
        "origin": "BTM Layout",
        "destination": "Whitefield",
        "distance_km": 23.3,
        "estimated_duration_min": 58,
        "fare": 48.0,
    },
    {
        "route_number": "284N",
        "name": "Jayanagar ↔ Indiranagar",
        "origin": "Jayanagar",
        "destination": "Indiranagar",
        "distance_km": 10.8,
        "estimated_duration_min": 30,
        "fare": 22.0,
    },
]

route_objs = {}
for data in routes_data:
    existing = db.query(Route).filter(Route.route_number == data["route_number"]).first()
    if not existing:
        r = Route(**data)
        db.add(r)
        db.flush()
        route_objs[data["route_number"]] = r
    else:
        route_objs[data["route_number"]] = existing

db.commit()
print(f"✅ Routes: {len(routes_data)} seeded")


# ── 2. BMTC Stops (Real Bengaluru coordinates) ────────────────────────────────

stops_data = [
    {"name": "Majestic",               "latitude": 12.9775, "longitude": 77.5713},
    {"name": "KR Market",              "latitude": 12.9649, "longitude": 77.5769},
    {"name": "Silk Board",             "latitude": 12.9172, "longitude": 77.6234},
    {"name": "Electronic City",        "latitude": 12.8399, "longitude": 77.6770},
    {"name": "MG Road",                "latitude": 12.9756, "longitude": 77.6097},
    {"name": "Whitefield",             "latitude": 12.9698, "longitude": 77.7500},
    {"name": "KR Puram",               "latitude": 13.0090, "longitude": 77.6923},
    {"name": "Yeshwanthpur",           "latitude": 13.0259, "longitude": 77.5475},
    {"name": "Koramangala",            "latitude": 12.9352, "longitude": 77.6245},
    {"name": "Hebbal",                 "latitude": 13.0359, "longitude": 77.5970},
    {"name": "Banashankari",           "latitude": 12.9255, "longitude": 77.5519},
    {"name": "Marathahalli",           "latitude": 12.9591, "longitude": 77.7012},
    {"name": "Kengeri",                "latitude": 12.9095, "longitude": 77.4826},
    {"name": "Yelahanka",              "latitude": 13.1006, "longitude": 77.5963},
    {"name": "BTM Layout",             "latitude": 12.9165, "longitude": 77.6101},
    {"name": "Jayanagar",              "latitude": 12.9293, "longitude": 77.5826},
    {"name": "Indiranagar",            "latitude": 12.9784, "longitude": 77.6408},
    {"name": "Shivajinagar",           "latitude": 12.9848, "longitude": 77.5979},
    {"name": "Domlur",                 "latitude": 12.9610, "longitude": 77.6387},
    {"name": "Richmond Circle",        "latitude": 12.9612, "longitude": 77.5960},
    {"name": "Lalbagh",                "latitude": 12.9500, "longitude": 77.5845},
    {"name": "National College",       "latitude": 12.9344, "longitude": 77.5756},
    {"name": "HSR Layout",             "latitude": 12.9116, "longitude": 77.6389},
    {"name": "Sarjapur Road",          "latitude": 12.9002, "longitude": 77.6762},
    {"name": "Brigade Road",           "latitude": 12.9737, "longitude": 77.6090},
]

stop_objs = {}
for data in stops_data:
    existing = db.query(Stop).filter(Stop.name == data["name"]).first()
    if not existing:
        s = Stop(**data)
        db.add(s)
        db.flush()
        stop_objs[data["name"]] = s
    else:
        stop_objs[data["name"]] = existing

db.commit()
print(f"✅ Stops: {len(stops_data)} seeded")


# ── 3. Route → Stops mapping ──────────────────────────────────────────────────

route_stop_map = {
    "401A": [
        ("Majestic", 0, 0.0),
        ("Lalbagh", 1, 4.2),
        ("Jayanagar", 2, 7.8),
        ("BTM Layout", 3, 11.5),
        ("Silk Board", 4, 15.2),
        ("HSR Layout", 5, 18.7),
        ("Sarjapur Road", 6, 22.1),
        ("Electronic City", 7, 26.8),
    ],
    "500D": [
        ("Majestic", 0, 0.0),
        ("Shivajinagar", 1, 3.5),
        ("MG Road", 2, 5.8),
        ("Brigade Road", 3, 6.9),
        ("Domlur", 4, 10.2),
        ("Indiranagar", 5, 13.4),
        ("Marathahalli", 6, 18.6),
        ("Whitefield", 7, 22.5),
    ],
    "356E": [
        ("KR Puram", 0, 0.0),
        ("Indiranagar", 1, 5.8),
        ("Domlur", 2, 8.2),
        ("Brigade Road", 3, 11.5),
        ("MG Road", 4, 14.3),
    ],
    "600B": [
        ("Yeshwanthpur", 0, 0.0),
        ("Majestic", 1, 4.8),
        ("Richmond Circle", 2, 9.3),
        ("Lalbagh", 3, 12.1),
        ("BTM Layout", 4, 15.4),
        ("Koramangala", 5, 18.6),
    ],
    "201C": [
        ("Hebbal", 0, 0.0),
        ("Yeshwanthpur", 1, 4.1),
        ("Majestic", 2, 7.9),
        ("Lalbagh", 3, 12.0),
        ("Jayanagar", 4, 15.2),
        ("National College", 5, 17.8),
        ("Banashankari", 6, 20.2),
    ],
    "333G": [
        ("Majestic", 0, 0.0),
        ("Shivajinagar", 1, 3.8),
        ("Indiranagar", 2, 8.5),
        ("Domlur", 3, 11.2),
        ("Marathahalli", 4, 19.4),
    ],
    "215K": [
        ("Kengeri", 0, 0.0),
        ("Banashankari", 1, 5.3),
        ("National College", 2, 9.8),
        ("Lalbagh", 3, 14.2),
        ("Richmond Circle", 4, 18.5),
        ("MG Road", 5, 24.1),
    ],
    "117F": [
        ("Yelahanka", 0, 0.0),
        ("Hebbal", 1, 5.2),
        ("Yeshwanthpur", 2, 10.4),
        ("Majestic", 3, 16.9),
    ],
    "502B": [
        ("BTM Layout", 0, 0.0),
        ("Koramangala", 1, 3.2),
        ("HSR Layout", 2, 6.5),
        ("Sarjapur Road", 3, 10.8),
        ("Marathahalli", 4, 16.9),
        ("Whitefield", 5, 23.3),
    ],
    "284N": [
        ("Jayanagar", 0, 0.0),
        ("Lalbagh", 1, 2.3),
        ("Richmond Circle", 2, 4.6),
        ("MG Road", 3, 7.1),
        ("Brigade Road", 4, 7.9),
        ("Domlur", 5, 9.2),
        ("Indiranagar", 6, 10.8),
    ],
}

rs_count = 0
for rnum, stops in route_stop_map.items():
    route = route_objs.get(rnum)
    if not route:
        continue
    for stop_name, seq, dist in stops:
        sobj = stop_objs.get(stop_name)
        if not sobj:
            continue
        exists = db.query(RouteStop).filter(
            RouteStop.route_id == route.id,
            RouteStop.stop_id  == sobj.id,
        ).first()
        if not exists:
            db.add(RouteStop(
                route_id=route.id,
                stop_id=sobj.id,
                sequence=seq,
                distance_from_start_km=dist,
            ))
            rs_count += 1

db.commit()
print(f"✅ RouteStops: {rs_count} links seeded")


# ── 4. Buses (15 buses with real Bengaluru GPS positions) ─────────────────────

def _route(num): return route_objs.get(num)

buses_data = [
    # 401A buses
    {"bus_number": "KA-01-F-4011", "route": "401A", "capacity": 55, "occupancy": 42, "lat": 12.9255, "lng": 77.5519, "speed": 28.0},
    {"bus_number": "KA-01-F-4012", "route": "401A", "capacity": 55, "occupancy": 18, "lat": 12.9172, "lng": 77.6234, "speed": 35.0},
    # 500D buses
    {"bus_number": "KA-02-G-5001", "route": "500D", "capacity": 60, "occupancy": 35, "lat": 12.9784, "lng": 77.6408, "speed": 32.0},
    {"bus_number": "KA-02-G-5002", "route": "500D", "capacity": 60, "occupancy": 52, "lat": 12.9591, "lng": 77.7012, "speed": 25.0},
    # 356E buses
    {"bus_number": "KA-03-H-3561", "route": "356E", "capacity": 50, "occupancy": 12, "lat": 13.0090, "lng": 77.6923, "speed": 40.0},
    # 600B buses
    {"bus_number": "KA-04-J-6001", "route": "600B", "capacity": 55, "occupancy": 44, "lat": 13.0259, "lng": 77.5475, "speed": 22.0},
    {"bus_number": "KA-04-J-6002", "route": "600B", "capacity": 55, "occupancy": 26, "lat": 12.9352, "lng": 77.6245, "speed": 30.0},
    # 201C bus
    {"bus_number": "KA-05-K-2011", "route": "201C", "capacity": 50, "occupancy": 38, "lat": 13.0359, "lng": 77.5970, "speed": 27.0},
    # 333G bus
    {"bus_number": "KA-06-L-3331", "route": "333G", "capacity": 50, "occupancy": 21, "lat": 12.9848, "lng": 77.5979, "speed": 35.0},
    # 215K bus
    {"bus_number": "KA-07-M-2151", "route": "215K", "capacity": 55, "occupancy": 48, "lat": 12.9095, "lng": 77.4826, "speed": 20.0},
    # 117F bus
    {"bus_number": "KA-08-N-1171", "route": "117F", "capacity": 50, "occupancy": 15, "lat": 13.1006, "lng": 77.5963, "speed": 38.0},
    # 502B bus
    {"bus_number": "KA-09-P-5021", "route": "502B", "capacity": 55, "occupancy": 33, "lat": 12.9165, "lng": 77.6101, "speed": 29.0},
    # 284N buses
    {"bus_number": "KA-10-Q-2841", "route": "284N", "capacity": 45, "occupancy": 22, "lat": 12.9293, "lng": 77.5826, "speed": 33.0},
    {"bus_number": "KA-10-Q-2842", "route": "284N", "capacity": 45, "occupancy": 40, "lat": 12.9784, "lng": 77.6408, "speed": 24.0},
    # Maintenance bus (inactive)
    {"bus_number": "KA-11-R-9999", "route": "401A", "capacity": 50, "occupancy": 0,  "lat": 12.9775, "lng": 77.5713, "speed": 0.0, "status": "maintenance"},
]

bus_count = 0
for d in buses_data:
    if not db.query(Bus).filter(Bus.bus_number == d["bus_number"]).first():
        r = _route(d["route"])
        db.add(Bus(
            bus_number=d["bus_number"],
            route_id=r.id if r else None,
            capacity=d["capacity"],
            current_occupancy=d["occupancy"],
            latitude=d["lat"],
            longitude=d["lng"],
            speed_kmh=d["speed"],
            status=d.get("status", "active"),
        ))
        bus_count += 1

db.commit()
db.close()

print(f"✅ Buses: {bus_count} seeded")
print("\n🎉 Seed complete!")
print(f"   Routes:     {len(routes_data)}")
print(f"   Stops:      {len(stops_data)}")
print(f"   RouteStops: {rs_count}")
print(f"   Buses:      {bus_count}")
