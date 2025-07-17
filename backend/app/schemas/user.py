from typing import List, Dict, Optional, Any
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr
    is_active: bool = True
    is_admin: bool = False

class UserCreate(UserBase):
    password: str
    firebase_uid: Optional[str] = None

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None
    selected_bookmakers: Optional[List[str]] = None
    total_stake_amount: Optional[float] = None
    min_profit_percentage: Optional[float] = None
    notification_preferences: Optional[Dict[str, bool]] = None
    fcm_token: Optional[str] = None

class UserPreferences(BaseModel):
    selected_bookmakers: List[str] = Field(default=["Bet9ja", "1xBet", "BetKing", "SportyBet", "Betano"])
    total_stake_amount: float = Field(default=10000.0, gt=0)
    min_profit_percentage: float = Field(default=1.0, ge=0)
    notification_preferences: Dict[str, bool] = Field(default={"in_app": True, "push": True, "email": False})

class UserInDB(UserBase):
    id: int
    hashed_password: Optional[str] = None
    firebase_uid: Optional[str] = None
    selected_bookmakers: List[str]
    total_stake_amount: float
    min_profit_percentage: float
    notification_preferences: Dict[str, bool]
    fcm_token: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class User(UserBase):
    id: int
    firebase_uid: Optional[str] = None
    selected_bookmakers: List[str]
    total_stake_amount: float
    min_profit_percentage: float
    notification_preferences: Dict[str, bool]
    fcm_token: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class UserPreferencesUpdate(BaseModel):
    selected_bookmakers: Optional[List[str]] = None
    total_stake_amount: Optional[float] = None
    min_profit_percentage: Optional[float] = None
    notification_preferences: Optional[Dict[str, bool]] = None
    fcm_token: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User

class TokenData(BaseModel):
    email: Optional[str] = None 