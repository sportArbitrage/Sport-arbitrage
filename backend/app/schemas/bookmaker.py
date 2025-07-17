from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from enum import Enum
from datetime import datetime

class SportType(str, Enum):
    FOOTBALL = "football"
    BASKETBALL = "basketball"
    TENNIS = "tennis"
    OTHER = "other"

class MarketType(str, Enum):
    WIN_1 = "1"           # Home win
    DRAW_X = "X"          # Draw
    WIN_2 = "2"           # Away win
    OVER = "over"         # Over
    UNDER = "under"       # Under

# Bookmaker Schemas
class BookmakerBase(BaseModel):
    name: str
    url: str
    logo_url: Optional[str] = None
    is_active: bool = True

class BookmakerCreate(BookmakerBase):
    pass

class BookmakerUpdate(BaseModel):
    url: Optional[str] = None
    logo_url: Optional[str] = None
    is_active: Optional[bool] = None
    last_scraped: Optional[datetime] = None

class Bookmaker(BookmakerBase):
    id: int
    last_scraped: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# Event Schemas
class EventBase(BaseModel):
    external_id: str
    bookmaker_id: int
    sport_type: SportType = SportType.FOOTBALL
    home_team: str
    away_team: str
    league: Optional[str] = None
    start_time: datetime
    is_live: bool = False

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    home_team: Optional[str] = None
    away_team: Optional[str] = None
    league: Optional[str] = None
    start_time: Optional[datetime] = None
    is_live: Optional[bool] = None

class Event(EventBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class EventWithMarkets(Event):
    markets: List["Market"] = []

    class Config:
        orm_mode = True

# Market Schemas
class MarketBase(BaseModel):
    event_id: int
    market_type: MarketType
    market_params: Optional[str] = None

class MarketCreate(MarketBase):
    pass

class MarketUpdate(BaseModel):
    market_params: Optional[str] = None

class Market(MarketBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class MarketWithOdds(Market):
    odds: List["Odds"] = []

    class Config:
        orm_mode = True

# Odds Schemas
class OddsBase(BaseModel):
    market_id: int
    value: float
    timestamp: datetime = datetime.utcnow()

class OddsCreate(OddsBase):
    pass

class OddsUpdate(BaseModel):
    value: Optional[float] = None

class Odds(OddsBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# Update forward references
MarketWithOdds.update_forward_refs()
EventWithMarkets.update_forward_refs() 