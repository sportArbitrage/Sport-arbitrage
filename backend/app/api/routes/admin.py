from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Any, Dict
from datetime import datetime, timedelta
import os
import psutil
import logging

from app.core.database import get_db
from app.models.user import User
from app.models.bookmaker import Bookmaker
from app.models.arbitrage import ArbitrageOpportunity
from app.auth.jwt import get_admin_user
from app.services.scraper_manager import trigger_scraping_job

router = APIRouter()

@router.get("/stats", response_model=Dict[str, Any])
async def get_system_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Get system statistics
    """
    # Count active users in the last 30 days
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    active_users_count = db.query(User).filter(User.is_active == True).count()
    
    # Count active arbitrage opportunities
    active_arbs_count = db.query(ArbitrageOpportunity).filter(
        ArbitrageOpportunity.is_active == True
    ).count()
    
    # Count bookmakers with active scraping
    active_bookmakers_count = db.query(Bookmaker).filter(
        Bookmaker.is_active == True,
        Bookmaker.last_scraped > (datetime.utcnow() - timedelta(hours=1))
    ).count()
    
    # System resource usage
    cpu_usage = psutil.cpu_percent(interval=0.5)
    memory_usage = dict(psutil.virtual_memory()._asdict())
    disk_usage = dict(psutil.disk_usage('/')._asdict())
    
    return {
        "timestamp": datetime.utcnow(),
        "users": {
            "total": db.query(User).count(),
            "active": active_users_count,
            "admin": db.query(User).filter(User.is_admin == True).count()
        },
        "arbitrage": {
            "total": db.query(ArbitrageOpportunity).count(),
            "active": active_arbs_count
        },
        "bookmakers": {
            "total": db.query(Bookmaker).count(),
            "active": active_bookmakers_count
        },
        "system": {
            "cpu_percent": cpu_usage,
            "memory": memory_usage,
            "disk": disk_usage
        }
    }

@router.get("/logs", response_model=List[Dict[str, Any]])
async def get_system_logs(
    lines: int = 100,
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Get system logs
    """
    log_entries = []
    log_file = os.getenv("LOG_FILE", "app.log")
    
    try:
        if os.path.exists(log_file):
            with open(log_file, "r") as f:
                # Get last N lines
                log_content = f.readlines()[-lines:]
                
                for line in log_content:
                    try:
                        # Parse log line (format depends on your logging setup)
                        parts = line.strip().split(" ", 3)
                        timestamp_str = f"{parts[0]} {parts[1]}"
                        level = parts[2]
                        message = parts[3] if len(parts) > 3 else ""
                        
                        log_entries.append({
                            "timestamp": timestamp_str,
                            "level": level,
                            "message": message
                        })
                    except Exception:
                        # If parsing fails, just add the raw line
                        log_entries.append({
                            "timestamp": "",
                            "level": "INFO",
                            "message": line.strip()
                        })
    except Exception as e:
        log_entries.append({
            "timestamp": datetime.utcnow().isoformat(),
            "level": "ERROR",
            "message": f"Error reading log file: {str(e)}"
        })
    
    return log_entries

@router.post("/scraping/trigger", response_model=Dict[str, Any])
async def trigger_scraping(
    bookmaker_id: int = None,
    background_tasks: BackgroundTasks = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Trigger scraping job
    """
    if bookmaker_id:
        # Check if bookmaker exists
        bookmaker = db.query(Bookmaker).filter(Bookmaker.id == bookmaker_id).first()
        if not bookmaker:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Bookmaker not found"
            )
        
        # Trigger scraping for specific bookmaker
        if background_tasks:
            background_tasks.add_task(trigger_scraping_job, bookmaker_id)
            return {"message": f"Scraping job for {bookmaker.name} triggered in background"}
        else:
            # Synchronous execution
            result = trigger_scraping_job(bookmaker_id)
            return {"message": f"Scraping job for {bookmaker.name} completed", "result": result}
    else:
        # Trigger scraping for all active bookmakers
        if background_tasks:
            background_tasks.add_task(trigger_scraping_job)
            return {"message": "Scraping job for all active bookmakers triggered in background"}
        else:
            # Synchronous execution
            result = trigger_scraping_job()
            return {"message": "Scraping job for all active bookmakers completed", "result": result}

@router.post("/purge/inactive-arbs", response_model=Dict[str, Any])
async def purge_inactive_arbs(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_admin_user),
) -> Any:
    """
    Purge old inactive arbitrage opportunities
    """
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    # Find old inactive arbs
    old_arbs_query = db.query(ArbitrageOpportunity).filter(
        ArbitrageOpportunity.is_active == False,
        ArbitrageOpportunity.last_verified_at < cutoff_date
    )
    
    count = old_arbs_query.count()
    if count > 0:
        # Delete them
        old_arbs_query.delete(synchronize_session=False)
        db.commit()
        
        return {"message": f"Successfully purged {count} old arbitrage opportunities"}
    else:
        return {"message": "No old arbitrage opportunities to purge"} 