from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

if settings.USE_FIREBASE_DB:
    # Firebase DB setup will be handled separately in firebase.py
    pass
else:
    # SQLAlchemy setup for PostgreSQL
    SQLALCHEMY_DATABASE_URL = settings.SQLALCHEMY_DATABASE_URI
    engine = create_engine(SQLALCHEMY_DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 