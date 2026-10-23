import random
from uuid import uuid4
from datetime import datetime, timedelta
from app.core.database import SessionLocal
from app.models import User, Ticket
from app.core.security import hash_password

db = SessionLocal()

dummy_users = [
    {"name": "Aarav Sharma", "email": "aarav.sh@example.com", "phone": "9876543210"},
    {"name": "Diya Patel", "email": "diya.p22@example.com", "phone": "8765432109"},
    {"name": "Rohan Iyer", "email": "rohan.iyer@example.com", "phone": "7654321098"},
    {"name": "Kavya Singh", "email": "kavya.s@example.com", "phone": "6543210987"},
    {"name": "Ananya Reddy", "email": "ananya.r@example.com", "phone": "5432109876"}
]

user_ids = []
print("Seeding dummy users...")
for du in dummy_users:
    exists = db.query(User).filter(User.email == du["email"]).first()
    if not exists:
        u = User(
            name=du["name"],
            email=du["email"],
            phone=du["phone"],
            hashed_password=hash_password("dummy123"),
            is_verified=True,
            is_active=True
        )
        db.add(u)
        db.commit()
        db.refresh(u)
        user_ids.append(u.id)
    else:
        user_ids.append(exists.id)

print("Seeding dummy tickets...")
routes = [1, 2, 3, 4, 5, 6, 7] # Integers for route_id
stops = ["Majestic", "MG Road", "Whitefield", "Koramangala", "Indiranagar", "Silk Board", "Hebbal"]

for i in range(15):
    t = Ticket(
        user_id=random.choice(user_ids),
        route_id=random.choice(routes),
        qr_code=str(uuid4()),
        boarding_stop=random.choice(stops),
        alighting_stop=random.choice(stops),
        fare_paid=random.choice([15.0, 20.0, 25.0, 35.0, 50.0]),
        status="ACTIVE",
        issued_at=datetime.utcnow() - timedelta(minutes=random.randint(5, 300)),
        valid_until=datetime.utcnow() + timedelta(hours=2)
    )
    db.add(t)

db.commit()
db.close()
print("✅ Dummy Users and Tickets successfully integrated into database!")
