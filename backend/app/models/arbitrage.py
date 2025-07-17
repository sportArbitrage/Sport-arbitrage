from sqlalchemy import Column, String, Float, Boolean, Integer, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
import sqlalchemy as sa
from datetime import datetime

from app.models.base import Base

class ArbitrageOpportunity(Base):
    # Match details
    home_team = Column(String, nullable=False)
    away_team = Column(String, nullable=False)
    league = Column(String)
    start_time = Column(DateTime, nullable=False)
    
    # Arbitrage details
    market_type = Column(String, nullable=False)  # e.g., "1X2" or "Over/Under 2.5"
    bookmakers = Column(JSON, nullable=False)  # List of bookmakers involved
    odds = Column(JSON, nullable=False)  # Dictionary of outcomes and their odds
    
    # Profit details
    arbitrage_percentage = Column(Float, nullable=False)  # e.g., 2.5%
    is_active = Column(Boolean, default=True)
    
    # Calculated stake distribution
    stake_distribution = Column(JSON, nullable=False)  # Dictionary of outcomes and stake amounts
    total_stake = Column(Float, nullable=False)
    expected_profit = Column(Float, nullable=False)
    
    # Timestamps
    detected_at = Column(DateTime, default=datetime.utcnow)
    last_verified_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    notifications = relationship("UserNotification", back_populates="arbitrage_opportunity", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Arbitrage {self.home_team} vs {self.away_team} ({self.arbitrage_percentage}%)>"

class UserNotification(Base):
    user_id = Column(Integer, ForeignKey("user.id"), nullable=False)
    arbitrage_id = Column(Integer, ForeignKey("arbitrageopportunity.id"), nullable=False)
    is_read = Column(Boolean, default=False)
    delivered_via = Column(JSON)  # List of channels: "in_app", "push", "email"
    
    # Relationships
    arbitrage_opportunity = relationship("ArbitrageOpportunity", back_populates="notifications")
    
    def __repr__(self):
        return f"<Notification for user {self.user_id} about arbitrage {self.arbitrage_id}>" 