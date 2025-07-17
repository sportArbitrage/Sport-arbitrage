import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'arbitrage_detail_screen.dart';

class ArbitrageScreen extends StatefulWidget {
  @override
  _ArbitrageScreenState createState() => _ArbitrageScreenState();
}

class _ArbitrageScreenState extends State<ArbitrageScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _opportunities = [];
  bool _isLoading = true;
  String _error = '';
  double _minProfit = 0.5;
  
  @override
  void initState() {
    super.initState();
    _fetchArbitrageOpportunities();
  }
  
  Future<void> _fetchArbitrageOpportunities() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final opportunities = await _apiService.getArbitrageOpportunities(
        minProfit: _minProfit,
      );
      
      setState(() {
        _opportunities = opportunities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load arbitrage opportunities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchArbitrageOpportunities,
      child: Scaffold(
        body: Column(
          children: [
            // Filter controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Profit: ${_minProfit.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _minProfit,
                      min: 0,
                      max: 5,
                      divisions: 50,
                      label: '${_minProfit.toStringAsFixed(1)}%',
                      onChanged: (value) {
                        setState(() {
                          _minProfit = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _fetchArbitrageOpportunities();
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: SpinKitRing(
          color: AppTheme.primaryColor,
          size: 40.0,
          lineWidth: 4,
        ),
      );
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchArbitrageOpportunities,
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_opportunities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                color: Colors.grey,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'No Arbitrage Opportunities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Try lowering the minimum profit percentage or check back later.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _opportunities.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final opportunity = _opportunities[index];
        return _buildArbitrageCard(opportunity);
      },
    );
  }
  
  Widget _buildArbitrageCard(Map<String, dynamic> opportunity) {
    final homeTeam = opportunity['home_team'];
    final awayTeam = opportunity['away_team'];
    final profit = opportunity['arbitrage_percentage'];
    final formattedProfit = profit.toStringAsFixed(2);
    final expectedProfit = opportunity['expected_profit'];
    final marketType = opportunity['market_type'];
    final bookmakers = (opportunity['bookmakers'] as List).join(', ');
    
    // Check if this is an over/under market
    final bool isOverUnderMarket = marketType.toString().toLowerCase().contains('over/under');
    
    // Format the date
    final DateTime startTime = DateTime.parse(opportunity['start_time']);
    final String formattedDate = DateFormat('MMM d, HH:mm').format(startTime);
    
    // Calculate a progress color based on profit percentage
    Color progressColor = AppTheme.successColor;
    if (profit < 1.0) {
      progressColor = AppTheme.primaryColor;
    } else if (profit > 3.0) {
      progressColor = AppTheme.accentColor;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverUnderMarket ? 
          BorderSide(color: AppTheme.accentColor.withOpacity(0.4), width: 1) : 
          BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArbitrageDetailScreen(arbitrageId: opportunity['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teams and match time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$homeTeam vs $awayTeam',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: progressColor, width: 1),
                    ),
                    child: Text(
                      '$formattedProfit% Profit',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress indicator
              LinearPercentIndicator(
                percent: profit / 5.0 > 1.0 ? 1.0 : profit / 5.0,
                lineHeight: 8.0,
                animation: true,
                animationDuration: 1000,
                progressColor: progressColor,
                backgroundColor: Colors.grey[200],
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 16),
              
              // Market Type Display with icon
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: isOverUnderMarket ? 
                    AppTheme.accentColor.withOpacity(0.1) : 
                    AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverUnderMarket ? Icons.trending_up : Icons.sports_soccer,
                      size: 16,
                      color: isOverUnderMarket ? AppTheme.accentColor : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      marketType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverUnderMarket ? AppTheme.accentColor : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Additional info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Profit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '₦${expectedProfit.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookmakers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          bookmakers,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 