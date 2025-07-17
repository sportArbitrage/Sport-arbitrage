from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Any, Optional
from datetime import datetime, timedelta

from app.core.database import get_db
from app.models.user import User
from app.models.bookmaker import Bookmaker, Event, Market, Odds
from app.schemas.bookmaker import (
    Bookmaker as BookmakerSchema,
    BookmakerCreate,
    BookmakerUpdate,
    Event as EventSchema,
    EventWithMarkets,
    Market as MarketSchema,
    MarketWithOdds,
    Odds as OddsSchema,
    SportType,
)
from app.auth.jwt import get_current_active_user, get_admin_user

router = APIRouter()

# Bookmaker endpoints
@router.get("/", response_model=List[BookmakerSchema])
async def get_bookmakers(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get all bookmakers
    """
    bookmakers = db.query(Bookmaker).offset(skip).limit(limit).all()
    return bookmakers

@router.get("/{bookmaker_id}", response_model=BookmakerSchema)
async def get_bookmaker(
    bookmaker_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get a specific bookmaker by ID
    """
    bookmaker = db.query(Bookmaker).filter(Bookmaker.id == bookmaker_id).first()
    if not bookmaker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmaker not found"
        )
    return bookmaker

@router.post("/", response_model=BookmakerSchema)
async def create_bookmaker(
    bookmaker_in: BookmakerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Create a new bookmaker (admin only)
    """
    bookmaker = Bookmaker(**bookmaker_in.dict())
    db.add(bookmaker)
    db.commit()
    db.refresh(bookmaker)
    return bookmaker

@router.put("/{bookmaker_id}", response_model=BookmakerSchema)
async def update_bookmaker(
    bookmaker_id: int,
    bookmaker_in: BookmakerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Update a bookmaker (admin only)
    """
    bookmaker = db.query(Bookmaker).filter(Bookmaker.id == bookmaker_id).first()
    if not bookmaker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Bookmaker not found"
        )
    
    update_data = bookmaker_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(bookmaker, field, value)
    
    db.commit()
    db.refresh(bookmaker)
    return bookmaker

# Event endpoints
@router.get("/events", response_model=List[EventSchema])
async def get_events(
    bookmaker_id: Optional[int] = None,
    sport_type: Optional[SportType] = None,
    upcoming_only: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get all events with optional filters
    """
    query = db.query(Event)
    
    if bookmaker_id:
        query = query.filter(Event.bookmaker_id == bookmaker_id)
    
    if sport_type:
        query = query.filter(Event.sport_type == sport_type)
    
    if upcoming_only:
        now = datetime.utcnow()
        query = query.filter(Event.start_time > now)
    
    events = query.offset(skip).limit(limit).all()
    return events

@router.get("/events/{event_id}", response_model=EventWithMarkets)
async def get_event(
    event_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get a specific event with its markets
    """
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Event not found"
        )
    return event

# Market endpoints
@router.get("/markets/{market_id}", response_model=MarketWithOdds)
async def get_market_with_odds(
    market_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get a specific market with its odds
    """
    market = db.query(Market).filter(Market.id == market_id).first()
    if not market:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Market not found"
        )
    return market 