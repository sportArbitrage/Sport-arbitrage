import logging
from sqlalchemy.orm import Session
import os
from datetime import datetime

from app.core.database import get_db, SessionLocal, engine
from app.models.base import Base
from app.models.user import User
from app.models.bookmaker import Bookmaker
from app.auth.jwt import get_password_hash
from app.services.scraper_manager import create_mock_scrapers

logger = logging.getLogger(__name__)

# List of bookmakers to create
BOOKMAKERS = [
    {
        "name": "Bet9ja",
        "url": "https://web.bet9ja.com",
        "logo_url": "https://assets.bet9ja.com/img/bet9ja-logo.png",
    },
    {
        "name": "1xBet",
        "url": "https://1xbet.ng",
        "logo_url": "https://1xbet.ng/img/1xbet-logo.png",
    },
    {
        "name": "BetKing",
        "url": "https://betking.com",
        "logo_url": "https://betking.com/img/logo.png",
    },
    {
        "name": "SportyBet",
        "url": "https://sportybet.com",
        "logo_url": "https://sportybet.com/img/sportybet-logo.png",
    },
    {
        "name": "Betano",
        "url": "https://betano.com",
        "logo_url": "https://betano.com/img/betano-logo.png",
    }
]

def create_first_admin(db: Session) -> None:
    """
    Create the first admin user if it doesn't exist
    """
    admin_email = os.getenv("ADMIN_EMAIL", "admin@example.com")
    admin_password = os.getenv("ADMIN_PASSWORD", "admin123")
    
    # Check if admin user already exists
    admin = db.query(User).filter(User.email == admin_email).first()
    if admin:
        logger.info(f"Admin user {admin_email} already exists")
        return admin
    
    # Create admin user
    admin_user = User(
        email=admin_email,
        hashed_password=get_password_hash(admin_password),
        is_active=True,
        is_admin=True,
    )
    
    db.add(admin_user)
    db.commit()
    db.refresh(admin_user)
    logger.info(f"Created admin user: {admin_email}")
    
    return admin_user

def create_bookmakers(db: Session) -> None:
    """
    Create bookmakers if they don't exist
    """
    for bookmaker_data in BOOKMAKERS:
        bookmaker = db.query(Bookmaker).filter(Bookmaker.name == bookmaker_data["name"]).first()
        if not bookmaker:
            bookmaker = Bookmaker(**bookmaker_data)
            db.add(bookmaker)
            logger.info(f"Created bookmaker: {bookmaker_data['name']}")
    
    db.commit()

def init_db() -> None:
    """
    Initialize the database with tables and seed data
    """
    try:
        # Create all tables
        Base.metadata.create_all(bind=engine)
        logger.info("Created database tables")
        
        # Create mock scrapers
        create_mock_scrapers()
        logger.info("Created mock scrapers")
        
        # Create seed data
        db = SessionLocal()
        try:
            create_first_admin(db)
            create_bookmakers(db)
        finally:
            db.close()
    
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        raise

if __name__ == "__main__":
    # Run database initialization when script is executed directly
    logging.basicConfig(level=logging.INFO)
    logger.info("Initializing database")
    init_db()
    logger.info("Database initialization completed") 