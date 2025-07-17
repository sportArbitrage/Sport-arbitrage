import random
from datetime import datetime, timedelta
from typing import List, Dict, Any

def scrape_events() -> List[Dict[str, Any]]:
    """
    Mock scraper for Bet9ja that generates random football events with odds
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
        event = {
            "home_team": home_team,
            "away_team": away_team,
            "league": random.choice(leagues),
            "start_time": start_time,
            "sport_type": "football",
            "markets": []
        }
        
        # 1X2 Market
        win_home_odds = round(random.uniform(1.5, 4.0), 2)
        draw_odds = round(random.uniform(2.5, 4.5), 2)
        win_away_odds = round(random.uniform(1.5, 5.0), 2)
        
        market_1x2 = {
            "market_type": "1X2",
            "odds": [
                {"outcome": "1", "value": win_home_odds},
                {"outcome": "X", "value": draw_odds},
                {"outcome": "2", "value": win_away_odds}
            ]
        }
        event["markets"].append(market_1x2)
        
        # Over/Under Market
        over_odds = round(random.uniform(1.7, 2.3), 2)
        under_odds = round(random.uniform(1.7, 2.3), 2)
        
        market_ou = {
            "market_type": "over_under",
            "market_params": "2.5",
            "odds": [
                {"outcome": "over", "value": over_odds},
                {"outcome": "under", "value": under_odds}
            ]
        }
        event["markets"].append(market_ou)
        
        events.append(event)
    
    return events 