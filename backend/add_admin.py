from app.core.database import SessionLocal
from app.models import User

db = SessionLocal()
existing = db.query(User).filter(User.email=='admin@nexride.com').first()
if not existing:
    admin = User(
        name='System Admin', 
        email='admin@nexride.com', 
        phone='1234567890', 
        # Precomputed bcrypt hash for 'admin123'
        hashed_password=b'$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW', 
        is_verified=True, 
        is_active=True, 
        wallet_balance=9999.0
    )
    db.add(admin)
    db.commit()
    print('✅ Admin created: admin@nexride.com / admin123')
else:
    print('ℹ️ Admin already exists: admin@nexride.com / admin123')
db.close()
