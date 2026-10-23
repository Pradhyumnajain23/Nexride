import urllib.request, json, os

BASE_URL = "http://127.0.0.1:8000"

def req(path, payload=None, token=None, method="POST"):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
            
    data = json.dumps(payload).encode() if payload else None
    request = urllib.request.Request(BASE_URL + path, data=data, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(request) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        print(f"HTTPError {e.code} on {path}: {e.read().decode()}")
        return None

print("=== STARTING TICKET TESTS ===")

# Create test user and token natively
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from app.core.database import SessionLocal
from app.models import User, Route
from app.core.security import create_access_token

db = SessionLocal()
# Create a robust dummy user
u = db.query(User).filter(User.email == "ticket.test@example.com").first()
if not u:
    u = User(name="Ticket Tester", email="ticket.test@example.com", phone="9999999999", hashed_password="dummy", is_verified=True)
    db.add(u)
    db.commit()
    db.refresh(u)
else:
    u.is_verified = True
    db.commit()

# Create JWT token
token = create_access_token(data={"sub": str(u.id)})

# Grab an active route
route = db.query(Route).filter(Route.is_active == True).first()
if not route:
    print("No active routes found to book!")
    exit(1)

print(f"✅ User and JWT acquired. User ID: {u.id}")

res = req("/tickets/", payload={"route_id": route.id, "boarding_stop": "A", "alighting_stop": "B"}, token=token)
if res:
    print("\n✅ TICKET CREATED:")
    print(json.dumps(res, indent=2))

print("\n--- GRABBING ALL MY TICKETS ---")
res2 = req("/tickets/my", token=token, method="GET")
if res2:
    print(f"✅ Found {len(res2)} ticket(s). Latest QR: {res2[0]['qr_code']}")

