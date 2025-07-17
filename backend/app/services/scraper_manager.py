from typing import List, Dict, Any, Optional
from datetime import datetime
import importlib
import logging
from sqlalchemy.orm import Session
from fastapi import Depends

from app.core.database import get_db, SessionLocal
from app.models.bookmaker import Bookmaker, Event
from app.models.arbitrage import ArbitrageOpportunity
from app.services.arbitrage_calculator import find_arbitrage_opportunities

logger = logging.getLogger(__name__)

# Dictionary to map bookmaker names to their scraper modules
BOOKMAKER_SCRAPERS = {
    "Bet9ja": "app.scrapers.bet9ja_scraper",
    "1xBet": "app.scrapers.onexbet_scraper",
    "BetKing": "app.scrapers.betking_scraper",
    "SportyBet": "app.scrapers.sportybet_scraper",
    "Betano": "app.scrapers.betano_scraper"
}

def get_scraper_for_bookmaker(bookmaker_name: str) -> Optional[Any]:
    """
    Dynamically import and return the scraper module for a bookmaker
    """
    scraper_module_name = BOOKMAKER_SCRAPERS.get(bookmaker_name)
    if not scraper_module_name:
        logger.error(f"No scraper module defined for bookmaker: {bookmaker_name}")
        return None
    
    try:
        scraper_module = importlib.import_module(scraper_module_name)
        return scraper_module
    except ImportError as e:
        logger.error(f"Failed to import scraper for {bookmaker_name}: {str(e)}")
        return None

def trigger_scraping_job(bookmaker_id: Optional[int] = None) -> Dict[str, Any]:
    """
    Trigger scraping for one or all bookmakers
    """
    db = SessionLocal()
    try:
        results = {
            "success": True,
            "timestamp": datetime.utcnow(),
            "bookmakers_processed": 0,
            "events_scraped": 0,
            "arbitrage_opportunities_found": 0,
            "errors": []
        }
        
        # Get active bookmakers
        query = db.query(Bookmaker).filter(Bookmaker.is_active == True)
        if bookmaker_id:
            query = query.filter(Bookmaker.id == bookmaker_id)
        
        bookmakers = query.all()
        
        if not bookmakers:
            results["success"] = False
            results["errors"].append("No active bookmakers found")
            return results
        
        all_events = []
        
        # Run scraper for each bookmaker
        for bookmaker in bookmakers:
            try:
                results["bookmakers_processed"] += 1
                scraper = get_scraper_for_bookmaker(bookmaker.name)
                
                if not scraper:
                    results["errors"].append(f"No scraper available for {bookmaker.name}")
                    continue
                
                # Run the scraper
                events_data = scraper.scrape_events()
                
                # Process events
                events_count = 0
                for event_data in events_data:
                    # Add bookmaker information
                    event_data["bookmaker_id"] = bookmaker.id
                    event_data["bookmaker_name"] = bookmaker.name
                    
                    # Add to events list
                    all_events.append(event_data)
                    events_count += 1
                
                # Update bookmaker's last scraped time
                bookmaker.last_scraped = datetime.utcnow()
                db.commit()
                
                # Log results
                logger.info(f"Scraped {events_count} events from {bookmaker.name}")
                results["events_scraped"] += events_count
                
            except Exception as e:
                error_msg = f"Error scraping {bookmaker.name}: {str(e)}"
                logger.error(error_msg)
                results["errors"].append(error_msg)
        
        # Find arbitrage opportunities
        if all_events:
            try:
                opportunities = find_arbitrage_opportunities(all_events)
                results["arbitrage_opportunities_found"] = len(opportunities)
                
                # Save arbitrage opportunities to the database
                if opportunities:
                    for opp in opportunities:
                        # Check if this opportunity already exists
                        # This is a simplified check - in a real system, you'd use more robust matching
                        existing = db.query(ArbitrageOpportunity).filter(
                            ArbitrageOpportunity.home_team == opp["home_team"],
                            ArbitrageOpportunity.away_team == opp["away_team"],
                            ArbitrageOpportunity.market_type == opp["market_type"],
                            ArbitrageOpportunity.is_active == True
                        ).first()
                        
                        if existing:
                            # Update existing opportunity
                            existing.odds = opp["odds"]
                            existing.arbitrage_percentage = opp["arbitrage_percentage"]
                            existing.stake_distribution = opp["stake_distribution"]
                            existing.expected_profit = opp["expected_profit"]
                            existing.last_verified_at = datetime.utcnow()
                        else:
                            # Create new opportunity
                            arb = ArbitrageOpportunity(
                                home_team=opp["home_team"],
                                away_team=opp["away_team"],
                                league=opp["league"],
                                start_time=opp["start_time"],
                                market_type=opp["market_type"],
                                bookmakers=opp["bookmakers"],
                                odds=opp["odds"],
                                arbitrage_percentage=opp["arbitrage_percentage"],
                                stake_distribution=opp["stake_distribution"],
                                total_stake=opp["total_stake"],
                                expected_profit=opp["expected_profit"],
                                is_active=True
                            )
                            db.add(arb)
                    
                    db.commit()
                    
                    # Notify users about new opportunities
                    # This would typically be done via a background task
                    # from app.services.notification_service import notify_users_about_arbitrage
                    # for arb in new_arbitrage_opportunities:
                    #     notify_users_about_arbitrage(db, arb)
            except Exception as e:
                error_msg = f"Error finding arbitrage opportunities: {str(e)}"
                logger.error(error_msg)
                results["errors"].append(error_msg)
        
        return results
        
    finally:
        db.close()

def create_mock_scrapers():
    """
    Create mock scraper modules for each bookmaker if they don't exist
    This is useful for development and testing
    """
    import os
    from app.core.config import settings
    
    scrapers_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scrapers")
    os.makedirs(scrapers_dir, exist_ok=True)
    
    # Create __init__.py if it doesn't exist
    init_file = os.path.join(scrapers_dir, "__init__.py")
    if not os.path.exists(init_file):
        with open(init_file, "w") as f:
            f.write("# Scrapers package\n")
    
    # Template for mock scraper
    mock_scraper_template = '''
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any

def scrape_events() -> List[Dict[str, Any]]:
    """
    Mock scraper for {bookmaker} that generates random football events with odds
    """
    events = []
    
    # Generate some random matches
    teams = [
        ("Manchester United", "Arsenal"),
        ("Liverpool", "Chelsea"),
        ("Tottenham", "Manchester City"),
        ("Newcastle", "Everton"),
        ("Aston Villa", "West Ham"),
        ("Enyimba FC", "Kano Pillars"),
        ("Remo Stars", "Rangers International"),
        ("Sunshine Stars", "Akwa United")
    ]
    
    leagues = ["Premier League", "La Liga", "Bundesliga", "Serie A", "Ligue 1", "NPFL"]
    
    for i in range(5):
        # Random match from the list
        home_team, away_team = random.choice(teams)
        
        # Random start time in the next 48 hours
        hours_ahead = random.randint(1, 48)
        start_time = datetime.utcnow() + timedelta(hours=hours_ahead)
        
        # Create the event
        event = {{
            "home_team": home_team,
            "away_team": away_team,
            "league": random.choice(leagues),
            "start_time": start_time,
            "sport_type": "football",
            "markets": []
        }}
        
        # 1X2 Market
        win_home_odds = round(random.uniform(1.5, 4.0), 2)
        draw_odds = round(random.uniform(2.5, 4.5), 2)
        win_away_odds = round(random.uniform(1.5, 5.0), 2)
        
        market_1x2 = {{
            "market_type": "1X2",
            "odds": [
                {{"outcome": "1", "value": win_home_odds}},
                {{"outcome": "X", "value": draw_odds}},
                {{"outcome": "2", "value": win_away_odds}}
            ]
        }}
        event["markets"].append(market_1x2)
        
        # Over/Under Market
        over_odds = round(random.uniform(1.7, 2.3), 2)
        under_odds = round(random.uniform(1.7, 2.3), 2)
        
        market_ou = {{
            "market_type": "over_under",
            "market_params": "2.5",
            "odds": [
                {{"outcome": "over", "value": over_odds}},
                {{"outcome": "under", "value": under_odds}}
            ]
        }}
        event["markets"].append(market_ou)
        
        events.append(event)
    
    return events
'''
    
    # Create mock scrapers for each bookmaker
    for bookmaker_name, module_path in BOOKMAKER_SCRAPERS.items():
        # Get just the file name from the module path
        file_name = module_path.split('.')[-1] + '.py'
        scraper_file = os.path.join(scrapers_dir, file_name)
        
        # Create file if it doesn't exist
        if not os.path.exists(scraper_file):
            with open(scraper_file, "w") as f:
                f.write(mock_scraper_template.format(bookmaker=bookmaker_name))
            
            print(f"Created mock scraper for {bookmaker_name} at {scraper_file}") 