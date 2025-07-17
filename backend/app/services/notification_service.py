from typing import List, Dict, Any, Optional
from datetime import datetime
from sqlalchemy.orm import Session
import logging

from app.models.user import User
from app.models.arbitrage import ArbitrageOpportunity, UserNotification
from app.core.firebase import send_push_notification, send_multicast_notification

logger = logging.getLogger(__name__)

def format_arbitrage_message(arbitrage: ArbitrageOpportunity) -> Dict[str, str]:
    """
    Format a user-friendly notification message for an arbitrage opportunity
    """
    profit_percentage = round(arbitrage.arbitrage_percentage, 2)
    expected_profit = round(arbitrage.expected_profit, 2)
    
    title = f"New Arbitrage: {profit_percentage}% profit!"
    body = (
        f"{arbitrage.home_team} vs {arbitrage.away_team}: "
        f"₦{expected_profit} profit on ₦{int(arbitrage.total_stake)} stake"
    )
    
    return {
        "title": title,
        "body": body
    }

def create_user_notification(
    db: Session,
    user: User,
    arbitrage: ArbitrageOpportunity,
    channels: List[str] = ["in_app"]
) -> UserNotification:
    """
    Create a user notification in the database
    """
    notification = UserNotification(
        user_id=user.id,
        arbitrage_id=arbitrage.id,
        is_read=False,
        delivered_via=channels
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    return notification

def send_user_notification(
    db: Session,
    user: User,
    arbitrage: ArbitrageOpportunity
) -> bool:
    """
    Send a notification to a user about an arbitrage opportunity
    """
    channels = []
    success = False
    
    # Check user preferences
    user_prefs = user.notification_preferences or {"in_app": True, "push": False, "email": False}
    
    # Create in-app notification
    if user_prefs.get("in_app", True):
        channels.append("in_app")
        success = True
    
    # Send push notification if enabled and FCM token exists
    if user_prefs.get("push", False) and user.fcm_token:
        message = format_arbitrage_message(arbitrage)
        
        # Add arbitrage data for the app to use
        data = {
            "arbitrage_id": str(arbitrage.id),
            "profit_percentage": str(round(arbitrage.arbitrage_percentage, 2)),
            "match": f"{arbitrage.home_team} vs {arbitrage.away_team}",
            "notification_type": "arbitrage"
        }
        
        push_success = send_push_notification(
            user.fcm_token,
            message["title"],
            message["body"],
            data
        )
        
        if push_success:
            channels.append("push")
            success = True
    
    # Create notification record if at least one channel was successful
    if success and channels:
        create_user_notification(db, user, arbitrage, channels)
    
    return success

def notify_users_about_arbitrage(
    db: Session,
    arbitrage: ArbitrageOpportunity,
    min_profit_threshold: Optional[float] = None
) -> Dict[str, Any]:
    """
    Notify all eligible users about a new arbitrage opportunity
    """
    results = {"total_users": 0, "notified_users": 0, "failed": 0}
    
    # Get all active users
    query = db.query(User).filter(User.is_active == True)
    
    # Apply profit threshold filter if specified
    if min_profit_threshold is not None:
        query = query.filter(User.min_profit_percentage <= arbitrage.arbitrage_percentage)
    
    # Get users with FCM tokens for batch push notification
    push_users = []
    push_tokens = []
    
    for user in query.all():
        results["total_users"] += 1
        
        # Check if the user's selected bookmakers match the arbitrage
        if user.selected_bookmakers and not any(bm in user.selected_bookmakers for bm in arbitrage.bookmakers):
            continue
        
        # Add to push notification batch if eligible
        user_prefs = user.notification_preferences or {}
        if user_prefs.get("push", False) and user.fcm_token:
            push_users.append(user)
            push_tokens.append(user.fcm_token)
        
        # Send individual notification (creates in-app notification)
        try:
            success = send_user_notification(db, user, arbitrage)
            if success:
                results["notified_users"] += 1
            else:
                results["failed"] += 1
        except Exception as e:
            logger.error(f"Failed to notify user {user.id}: {str(e)}")
            results["failed"] += 1
    
    # Send batch push notification if multiple users
    if push_tokens and len(push_tokens) > 1:
        try:
            message = format_arbitrage_message(arbitrage)
            data = {
                "arbitrage_id": str(arbitrage.id),
                "profit_percentage": str(round(arbitrage.arbitrage_percentage, 2)),
                "match": f"{arbitrage.home_team} vs {arbitrage.away_team}",
                "notification_type": "arbitrage"
            }
            
            send_multicast_notification(push_tokens, message["title"], message["body"], data)
        except Exception as e:
            logger.error(f"Failed to send multicast push notification: {str(e)}")
    
    return results 