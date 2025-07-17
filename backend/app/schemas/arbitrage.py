from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field
from datetime import datetime

class OddsData(BaseModel):
    bookmaker: str
    outcome: str
    odds: float

class StakeDistribution(BaseModel):
    outcome: str
    bookmaker: str
    odds: float
    stake: float
    potential_return: float

class ArbitrageBase(BaseModel):
    home_team: str
    away_team: str
    league: Optional[str] = None
    start_time: datetime
    market_type: str
    bookmakers: List[str]
    odds: Dict[str, Dict[str, float]]  # {outcome: {bookmaker: odds}}
    arbitrage_percentage: float

class ArbitrageCreate(ArbitrageBase):
    stake_distribution: Dict[str, Dict[str, float]]  # {outcome: {stake: float, bookmaker: str}}
    total_stake: float
    expected_profit: float

class ArbitrageUpdate(BaseModel):
    odds: Optional[Dict[str, Dict[str, float]]] = None
    arbitrage_percentage: Optional[float] = None
    stake_distribution: Optional[Dict[str, Dict[str, float]]] = None
    expected_profit: Optional[float] = None
    is_active: Optional[bool] = None

class Arbitrage(ArbitrageBase):
    id: int
    stake_distribution: Dict[str, Dict[str, float]]
    total_stake: float
    expected_profit: float
    is_active: bool
    detected_at: datetime
    last_verified_at: datetime

    class Config:
        orm_mode = True

class ArbitrageDetail(Arbitrage):
    stake_details: List[StakeDistribution] = []

class NotificationBase(BaseModel):
    user_id: int
    arbitrage_id: int
    is_read: bool = False
    delivered_via: List[str] = []

class NotificationCreate(NotificationBase):
    pass

class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None

class Notification(NotificationBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class NotificationWithArbitrage(Notification):
    arbitrage_opportunity: Arbitrage

    class Config:
        orm_mode = True 