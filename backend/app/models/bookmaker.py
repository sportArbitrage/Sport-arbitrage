from sqlalchemy import Column, String, Float, Boolean, Integer, ForeignKey, DateTime, Enum
from sqlalchemy.orm import relationship
import sqlalchemy as sa
from datetime import datetime
import enum

from app.models.base import Base

class SportType(str, enum.Enum):
    FOOTBALL = "football"
    BASKETBALL = "basketball"
    TENNIS = "tennis"
    OTHER = "other"

class MarketType(str, enum.Enum):
    WIN_1 = "1"           # Home win
    DRAW_X = "X"          # Draw
    WIN_2 = "2"           # Away win
    OVER = "over"         # Over
    UNDER = "under"       # Under

class Bookmaker(Base):
    name = Column(String, nullable=False, unique=True)
    url = Column(String, nullable=False)
    logo_url = Column(String)
    is_active = Column(Boolean, default=True)
    last_scraped = Column(DateTime)
    
    # Relationships
    events = relationship("Event", back_populates="bookmaker")
    
    def __repr__(self):
        return f"<Bookmaker {self.name}>"

class Event(Base):
    external_id = Column(String, nullable=False)
    bookmaker_id = Column(Integer, ForeignKey("bookmaker.id"), nullable=False)
    sport_type = Column(Enum(SportType), default=SportType.FOOTBALL)
    home_team = Column(String, nullable=False)
    away_team = Column(String, nullable=False)
    league = Column(String)
    start_time = Column(DateTime, nullable=False)
    is_live = Column(Boolean, default=False)
    
    # Relationships
    bookmaker = relationship("Bookmaker", back_populates="events")
    markets = relationship("Market", back_populates="event", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Event {self.home_team} vs {self.away_team}>"

class Market(Base):
    event_id = Column(Integer, ForeignKey("event.id"), nullable=False)
    market_type = Column(Enum(MarketType), nullable=False)
    market_params = Column(String, nullable=True)  # E.g. "2.5" for Over/Under
    
    # Relationships
    event = relationship("Event", back_populates="markets")
    odds = relationship("Odds", back_populates="market", cascade="all, delete-orphan")
    
    def __repr__(self):
        params = f" {self.market_params}" if self.market_params else ""
        return f"<Market {self.market_type}{params}>"

class Odds(Base):
    market_id = Column(Integer, ForeignKey("market.id"), nullable=False)
    value = Column(Float, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    market = relationship("Market", back_populates="odds")
    
    def __repr__(self):
        return f"<Odds {self.value}>" 