from typing import List, Dict, Tuple, Optional, Any
import logging

logger = logging.getLogger(__name__)

def calculate_arbitrage(odds_data: List[Dict[str, Any]]) -> Tuple[bool, float]:
    """
    Calculate if arbitrage exists given a list of odds
    
    Args:
        odds_data: List of dictionaries with 'bookmaker', 'outcome', and 'odds' keys
    
    Returns:
        Tuple of (arbitrage_exists, arbitrage_percentage)
    """
    if not odds_data or len(odds_data) < 2:
        return False, 0.0
    
    # Group odds by outcome to find the best odds for each outcome
    outcomes = {}
    for odd in odds_data:
        outcome = odd['outcome']
        odds_value = odd['odds']
        bookmaker = odd['bookmaker']
        
        if outcome not in outcomes or odds_value > outcomes[outcome]['odds']:
            outcomes[outcome] = {
                'odds': odds_value,
                'bookmaker': bookmaker
            }
    
    # Calculate arbitrage percentage
    # Formula: arbitrage_percentage = (1 - sum(1/odds_i)) * 100
    sum_reciprocal = sum(1 / outcome['odds'] for outcome in outcomes.values())
    arbitrage_percentage = (1 - sum_reciprocal) * 100
    
    # Arbitrage exists if the percentage is positive
    return arbitrage_percentage > 0, arbitrage_percentage

def calculate_stakes(odds_data: List[Dict[str, Any]], total_stake: float, arbitrage_percentage: float = None) -> Tuple[Dict[str, Dict[str, Any]], float]:
    """
    Calculate optimal stake distribution for arbitrage
    
    Args:
        odds_data: List of dictionaries with 'bookmaker', 'outcome', and 'odds' keys
        total_stake: Total amount to stake
        arbitrage_percentage: Optional pre-calculated arbitrage percentage
    
    Returns:
        Tuple of (stake_distribution, expected_profit)
    """
    # First, verify if arbitrage exists
    if arbitrage_percentage is None:
        arb_exists, arbitrage_percentage = calculate_arbitrage(odds_data)
        if not arb_exists:
            return {}, 0.0
    
    # Group odds by outcome to find the best odds for each outcome
    best_odds = {}
    for odd in odds_data:
        outcome = odd['outcome']
        odds_value = odd['odds']
        bookmaker = odd['bookmaker']
        
        if outcome not in best_odds or odds_value > best_odds[outcome]['odds']:
            best_odds[outcome] = {
                'odds': odds_value,
                'bookmaker': bookmaker
            }
    
    # Calculate sum of reciprocals
    sum_reciprocal = sum(1 / outcome['odds'] for outcome in best_odds.values())
    
    # Calculate stake distribution
    # Formula for each outcome: stake_i = (total_stake * (1/odds_i)) / sum(1/odds_i)
    stake_distribution = {}
    for outcome, data in best_odds.items():
        odds = data['odds']
        bookmaker = data['bookmaker']
        
        # Calculate stake for this outcome
        stake = (total_stake * (1 / odds)) / sum_reciprocal
        
        stake_distribution[outcome] = {
            'stake': round(stake, 2),
            'bookmaker': bookmaker,
            'odds': odds
        }
    
    # Calculate expected profit
    # Formula: expected_profit = total_stake * arbitrage_percentage / 100
    expected_profit = total_stake * (arbitrage_percentage / 100)
    
    return stake_distribution, round(expected_profit, 2)

def find_arbitrage_opportunities(
    events_data: List[Dict[str, Any]], 
    min_profit_percentage: float = 0.5
) -> List[Dict[str, Any]]:
    """
    Find arbitrage opportunities across different bookmakers for the same event
    
    Args:
        events_data: List of events with odds from different bookmakers
        min_profit_percentage: Minimum profit percentage to consider as opportunity
    
    Returns:
        List of arbitrage opportunities
    """
    opportunities = []
    
    # Group events by match (home_team + away_team + start_time are the key)
    matches = {}
    for event in events_data:
        match_key = f"{event['home_team']}|{event['away_team']}|{event['start_time'].isoformat()}"
        
        if match_key not in matches:
            matches[match_key] = {
                'home_team': event['home_team'],
                'away_team': event['away_team'],
                'league': event.get('league', ''),
                'start_time': event['start_time'],
                'odds': []
            }
        
        # Add odds data for this event
        for market in event.get('markets', []):
            market_type = market['market_type']
            market_params = market.get('market_params')
            
            for odd in market.get('odds', []):
                # Convert to standard format
                matches[match_key]['odds'].append({
                    'bookmaker': event['bookmaker_name'],
                    'outcome': f"{market_type}:{odd['outcome']}",
                    'odds': odd['value'],
                    'market_params': market_params
                })
    
    # Process each match to find arbitrage opportunities
    for match_key, match_data in matches.items():
        # Group odds by market type and params
        markets = {}
        
        for odd in match_data['odds']:
            outcome_parts = odd['outcome'].split(':')
            if len(outcome_parts) != 2:
                continue
            
            market_type = outcome_parts[0]
            outcome = outcome_parts[1]
            market_params = odd.get('market_params')
            
            # Create market key that includes parameters (e.g., "over_under:2.5")
            market_key = f"{market_type}"
            if market_params:
                market_key += f":{market_params}"
            
            if market_key not in markets:
                markets[market_key] = []
            
            markets[market_key].append({
                'bookmaker': odd['bookmaker'],
                'outcome': outcome,
                'odds': odd['odds']
            })
        
        # Check for arbitrage in each market
        for market_key, market_odds in markets.items():
            arb_exists, arb_percentage = calculate_arbitrage(market_odds)
            
            if arb_exists and arb_percentage >= min_profit_percentage:
                # Get market type and params
                market_parts = market_key.split(':')
                market_type = market_parts[0]
                market_params = market_parts[1] if len(market_parts) > 1 else None
                
                # Format market type for display
                display_market = market_type
                if market_params:
                    # For over/under markets, use a more readable format
                    if market_type.lower() == 'over_under':
                        display_market = f"Over/Under {market_params}"
                    else:
                        display_market += f" {market_params}"
                
                # Create arbitrage opportunity
                bookmakers = list(set(odd['bookmaker'] for odd in market_odds))
                
                # Group odds by outcome
                odds_by_outcome = {}
                for odd in market_odds:
                    outcome = odd['outcome']
                    if outcome not in odds_by_outcome:
                        odds_by_outcome[outcome] = {}
                    
                    odds_by_outcome[outcome][odd['bookmaker']] = odd['odds']
                
                # Calculate stakes for a default stake amount of 10,000
                default_stake = 10000
                stake_distribution, expected_profit = calculate_stakes(market_odds, default_stake, arb_percentage)
                
                # Enhanced stake details for over/under markets
                stake_details = []
                for outcome, details in stake_distribution.items():
                    bookmaker = details.get("bookmaker", "")
                    odds_value = details.get("odds", 0.0)
                    stake_amount = details.get("stake", 0.0)
                    potential_return = stake_amount * odds_value
                    
                    # Format outcome for display, particularly for over/under markets
                    display_outcome = outcome
                    if market_type.lower() == 'over_under' and market_params:
                        if outcome.lower() == 'over':
                            display_outcome = f"Over {market_params}"
                        elif outcome.lower() == 'under':
                            display_outcome = f"Under {market_params}"
                    
                    stake_details.append({
                        "outcome": display_outcome,
                        "bookmaker": bookmaker,
                        "odds": odds_value,
                        "stake": stake_amount,
                        "potential_return": potential_return
                    })
                
                opportunity = {
                    'home_team': match_data['home_team'],
                    'away_team': match_data['away_team'],
                    'league': match_data['league'],
                    'start_time': match_data['start_time'],
                    'market_type': display_market,
                    'bookmakers': bookmakers,
                    'odds': odds_by_outcome,
                    'arbitrage_percentage': arb_percentage,
                    'stake_distribution': stake_distribution,
                    'stake_details': stake_details,  # Add the enhanced stake details
                    'total_stake': default_stake,
                    'expected_profit': expected_profit
                }
                
                opportunities.append(opportunity)
    
    # Sort opportunities by profit percentage (descending)
    opportunities.sort(key=lambda x: x['arbitrage_percentage'], reverse=True)
    
    return opportunities 