import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ArbitrageDetailScreen extends StatefulWidget {
  final int arbitrageId;

  const ArbitrageDetailScreen({Key? key, required this.arbitrageId})
      : super(key: key);

  @override
  _ArbitrageDetailScreenState createState() => _ArbitrageDetailScreenState();
}

class _ArbitrageDetailScreenState extends State<ArbitrageDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _arbitrage = {};
  List<dynamic> _stakeDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchArbitrageDetails();
  }

  Future<void> _fetchArbitrageDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final arbitrage = await _apiService.getArbitrageOpportunityDetails(
        widget.arbitrageId,
      );

      setState(() {
        _arbitrage = arbitrage;
        _stakeDetails = arbitrage['stake_details'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load arbitrage details: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arbitrage Details'),
      ),
      body: _isLoading
          ? Center(
              child: SpinKitRing(
                color: AppTheme.primaryColor,
                size: 40.0,
                lineWidth: 4,
              ),
            )
          : _error.isNotEmpty
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildErrorView() {
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
              onPressed: _fetchArbitrageDetails,
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final homeTeam = _arbitrage['home_team'];
    final awayTeam = _arbitrage['away_team'];
    final league = _arbitrage['league'] ?? '';
    final profit = _arbitrage['arbitrage_percentage'];
    final formattedProfit = profit.toStringAsFixed(2);
    final expectedProfit = _arbitrage['expected_profit'];
    final marketType = _arbitrage['market_type'];
    final totalStake = _arbitrage['total_stake'];
    final isOverUnderMarket = marketType.toString().toLowerCase().contains('over/under') || 
                             marketType.toString().toLowerCase().contains('over under');
    
    // Format the date
    final DateTime startTime = DateTime.parse(_arbitrage['start_time']);
    final String formattedDate = DateFormat('EEEE, MMM d, y').format(startTime);
    final String formattedTime = DateFormat('HH:mm').format(startTime);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$homeTeam vs $awayTeam',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (league.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  league,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Market Type Display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isOverUnderMarket ? 
                        AppTheme.accentColor.withOpacity(0.15) : 
                        AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOverUnderMarket ? 
                          AppTheme.accentColor.withOpacity(0.5) : 
                          AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Market Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOverUnderMarket ? Icons.trending_up : Icons.sports_soccer,
                              size: 18,
                              color: isOverUnderMarket ? AppTheme.accentColor : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              marketType,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isOverUnderMarket ? AppTheme.accentColor : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem('Total Stake', '₦${totalStake.toStringAsFixed(0)}'),
                      _buildInfoItem('Expected Profit', '₦${expectedProfit.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Profit section
          Text(
            'Profit Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profit percentage
                  CircularPercentIndicator(
                    radius: 70.0,
                    lineWidth: 13.0,
                    animation: true,
                    percent: profit / 100 > 1.0 ? 1.0 : profit / 100,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$formattedProfit%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24.0,
                          ),
                        ),
                        Text(
                          'Profit',
                          style: TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: AppTheme.successColor,
                    backgroundColor: Colors.grey[200]!,
                  ),
                  const SizedBox(height: 16),
                  // Return on investment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfitMetric(
                        'Total Stake',
                        '₦${totalStake.toStringAsFixed(0)}',
                        Icons.attach_money,
                      ),
                      _buildProfitMetric(
                        'Profit Amount',
                        '₦${expectedProfit.toStringAsFixed(2)}',
                        Icons.trending_up,
                      ),
                      _buildProfitMetric(
                        'ROI',
                        '${(expectedProfit / totalStake * 100).toStringAsFixed(2)}%',
                        Icons.percent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stake distribution section
          Text(
            'Stake Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _stakeDetails.isEmpty
              ? Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No stake details available'),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _stakeDetails.length,
                  itemBuilder: (context, index) {
                    final stake = _stakeDetails[index];
                    return _buildStakeCard(stake, isOverUnderMarket);
                  },
                ),
          
          const SizedBox(height: 24),
          
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share functionality not implemented yet')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Share Opportunity',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProfitMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStakeCard(Map<String, dynamic> stake, bool isOverUnderMarket) {
    final outcome = stake['outcome'];
    final bookmaker = stake['bookmaker'];
    final odds = stake['odds'];
    final stakeAmount = stake['stake'];
    final potentialReturn = stake['potential_return'];
    
    // Determine if this is an "Over" outcome
    final bool isOverOutcome = outcome.toString().toLowerCase().contains('over');
    
    // For over/under markets, customize the display
    Color outcomeColor = AppTheme.primaryColor;
    IconData outcomeIcon = Icons.sports_soccer;
    
    if (isOverUnderMarket) {
      outcomeColor = isOverOutcome ? Colors.orange : Colors.blue;
      outcomeIcon = isOverOutcome ? Icons.arrow_upward : Icons.arrow_downward;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverUnderMarket ? BorderSide(
          color: outcomeColor.withOpacity(0.4),
          width: 1,
        ) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                if (isOverUnderMarket)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: outcomeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      outcomeIcon,
                      color: outcomeColor,
                      size: 20,
                    ),
                  ),
                if (isOverUnderMarket)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outcome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isOverUnderMarket ? outcomeColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bookmaker,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Odds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        odds.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stake and Return on a separate row for better visibility
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stake',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '₦${stakeAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Return',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '₦${potentialReturn.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 