from app.core.database import SessionLocal
from app.models import User
from app.core.security import hash_password

db = SessionLocal()
existing = db.query(User).filter(User.email=='admin@nexride.com').first()

try:
    print("Hashing password...")
    hashed = hash_password('123456')
    if not existing:
        admin = User(name='System Admin', email='admin@nexride.com', phone='1234567890', hashed_password=hashed, is_verified=True, is_active=True)
        db.add(admin)
        db.commit()
        print('✅ Admin created with password 123456')
    else:
        existing.hashed_password = hashed
        existing.is_verified = True
        db.commit()
        print('✅ Admin password updated to 123456 and verified!')
except Exception as e:
    print(f"Error: {e}")
finally:
    db.close()
