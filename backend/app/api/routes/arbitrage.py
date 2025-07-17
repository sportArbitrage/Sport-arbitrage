from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Any, Optional
from datetime import datetime, timedelta

from app.core.database import get_db
from app.models.user import User
from app.models.arbitrage import ArbitrageOpportunity, UserNotification
from app.schemas.arbitrage import (
    Arbitrage,
    ArbitrageDetail,
    Notification,
    NotificationWithArbitrage,
    NotificationUpdate,
)
from app.auth.jwt import get_current_active_user
from app.core.firebase import send_push_notification

router = APIRouter()

@router.get("/opportunities", response_model=List[Arbitrage])
async def get_arbitrage_opportunities(
    active_only: bool = True,
    min_profit: Optional[float] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get all arbitrage opportunities
    """
    query = db.query(ArbitrageOpportunity)
    
    # Apply user preferences for bookmakers
    if current_user.selected_bookmakers:
        # This is a bit complex because we're filtering JSON array fields
        # We need to ensure that all bookmakers in an arb opportunity are in the user's selected list
        # This simplified version just checks if any of the user's bookmakers are in the arbitrage
        # A more advanced implementation might need a custom SQL query or filter
        # query = query.filter(ArbitrageOpportunity.bookmakers.overlap(current_user.selected_bookmakers))
        pass
    
    if active_only:
        query = query.filter(ArbitrageOpportunity.is_active == True)
    
    # Apply minimum profit filter - either from request or user preferences
    profit_threshold = min_profit if min_profit is not None else current_user.min_profit_percentage
    if profit_threshold is not None and profit_threshold > 0:
        query = query.filter(ArbitrageOpportunity.arbitrage_percentage >= profit_threshold)
    
    # Order by profit percentage (highest first)
    query = query.order_by(ArbitrageOpportunity.arbitrage_percentage.desc())
    
    opportunities = query.offset(skip).limit(limit).all()
    return opportunities

@router.get("/opportunities/{opportunity_id}", response_model=ArbitrageDetail)
async def get_arbitrage_opportunity(
    opportunity_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get detailed information about a specific arbitrage opportunity
    """
    opportunity = db.query(ArbitrageOpportunity).filter(ArbitrageOpportunity.id == opportunity_id).first()
    if not opportunity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Arbitrage opportunity not found"
        )
    
    # Create detailed response with stake distribution
    result = ArbitrageDetail.from_orm(opportunity)
    
    # Convert the raw stake distribution from DB into the structured format
    stake_details = []
    for outcome, details in opportunity.stake_distribution.items():
        bookmaker = details.get("bookmaker", "")
        odds_value = opportunity.odds.get(outcome, {}).get(bookmaker, 0.0)
        stake = details.get("stake", 0.0)
        
        stake_details.append({
            "outcome": outcome,
            "bookmaker": bookmaker,
            "odds": odds_value,
            "stake": stake,
            "potential_return": stake * odds_value
        })
    
    result.stake_details = stake_details
    return result

@router.get("/notifications", response_model=List[NotificationWithArbitrage])
async def get_user_notifications(
    unread_only: bool = False,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Get the current user's notifications
    """
    query = db.query(UserNotification).filter(UserNotification.user_id == current_user.id)
    
    if unread_only:
        query = query.filter(UserNotification.is_read == False)
    
    # Order by newest first
    query = query.order_by(UserNotification.created_at.desc())
    
    notifications = query.offset(skip).limit(limit).all()
    return notifications

@router.put("/notifications/{notification_id}", response_model=Notification)
async def update_notification(
    notification_id: int,
    notification_in: NotificationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Update a notification (mark as read/unread)
    """
    notification = db.query(UserNotification).filter(
        UserNotification.id == notification_id,
        UserNotification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    update_data = notification_in.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(notification, field, value)
    
    db.commit()
    db.refresh(notification)
    return notification

@router.put("/notifications/read-all", response_model=dict)
async def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Mark all notifications as read
    """
    db.query(UserNotification).filter(
        UserNotification.user_id == current_user.id,
        UserNotification.is_read == False
    ).update({"is_read": True})
    
    db.commit()
    return {"message": "All notifications marked as read"}

@router.post("/calculate", response_model=ArbitrageDetail)
async def calculate_arbitrage(
    odds_data: List[dict],
    total_stake: Optional[float] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> Any:
    """
    Calculate arbitrage for provided odds without saving
    """
    # Import arbitrage calculator here to avoid circular imports
    from app.services.arbitrage_calculator import calculate_arbitrage, calculate_stakes
    
    # Process the odds data to ensure market information is properly handled
    market_type = "Custom"
    market_params = None
    
    # Extract market type and parameters if present in the first item
    if odds_data and len(odds_data) > 0:
        first_odd = odds_data[0]
        if 'market_type' in first_odd:
            market_type = first_odd['market_type']
        if 'market_params' in first_odd and first_odd['market_params']:
            market_params = first_odd['market_params']
    
    # Format market type for display
    display_market = market_type
    if market_params and market_type.lower() == 'over_under':
        display_market = f"Over/Under {market_params}"
    elif market_params:
        display_market = f"{market_type} {market_params}"
    
    # Calculate if arbitrage exists
    arbitrage_exists, arbitrage_percentage = calculate_arbitrage(odds_data)
    
    if not arbitrage_exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No arbitrage opportunity exists with these odds"
        )
    
    # Use user's default stake if not provided
    stake = total_stake if total_stake is not None else current_user.total_stake_amount
    
    # Calculate optimal stake distribution
    stake_distribution, expected_profit = calculate_stakes(odds_data, stake, arbitrage_percentage)
    
    # Create response object (not saving to DB)
    response = {
        "id": 0,  # Placeholder
        "home_team": "Custom Calculation",
        "away_team": "Manual Entry",
        "start_time": datetime.utcnow() + timedelta(hours=1),
        "market_type": display_market,
        "bookmakers": list(set(odd["bookmaker"] for odd in odds_data)),
        "odds": {odd["outcome"]: {odd["bookmaker"]: odd["odds"]} for odd in odds_data},
        "arbitrage_percentage": arbitrage_percentage,
        "is_active": True,
        "stake_distribution": stake_distribution,
        "total_stake": stake,
        "expected_profit": expected_profit,
        "detected_at": datetime.utcnow(),
        "last_verified_at": datetime.utcnow(),
        "stake_details": []
    }
    
    # Add stake details with enhanced formatting for over/under markets
    for outcome, details in stake_distribution.items():
        bookmaker = details.get("bookmaker", "")
        odds_value = next((odd["odds"] for odd in odds_data if odd["outcome"] == outcome and odd["bookmaker"] == bookmaker), 0)
        stake_amount = details.get("stake", 0)
        
        # Format outcome for over/under markets
        display_outcome = outcome
        if market_type.lower() == 'over_under' and market_params:
            if outcome.lower() == 'over' or 'over' in outcome.lower():
                display_outcome = f"Over {market_params}"
            elif outcome.lower() == 'under' or 'under' in outcome.lower():
                display_outcome = f"Under {market_params}"
        
        response["stake_details"].append({
            "outcome": display_outcome,
            "bookmaker": bookmaker,
            "odds": odds_value,
            "stake": stake_amount,
            "potential_return": stake_amount * odds_value
        })
    
    return response 