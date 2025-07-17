from sqlalchemy import Column, String, Boolean, Float, JSON
import sqlalchemy as sa
from app.models.base import Base

class User(Base):
    email = Column(String, unique=True, index=True, nullable=False)
    firebase_uid = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    
    # User preferences
    selected_bookmakers = Column(JSON, default=lambda: ["Bet9ja", "1xBet", "BetKing", "SportyBet", "Betano"])
    total_stake_amount = Column(Float, default=10000.0)  # Default 10,000 Naira
    min_profit_percentage = Column(Float, default=1.0)   # Default 1% minimum profit
    notification_preferences = Column(JSON, default=lambda: {"in_app": True, "push": True, "email": False})
    fcm_token = Column(String, nullable=True)  # Firebase Cloud Messaging token 