import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../utils/theme.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String _error = '';
  Map<String, dynamic>? _result;

  final List<Map<String, dynamic>> _oddsInputs = [
    {'bookmaker': '', 'outcome': '', 'odds': null},
    {'bookmaker': '', 'outcome': '', 'odds': null},
  ];

  final _totalStakeController = TextEditingController(text: '10000');
  String _selectedMarketType = '1X2';
  String? _goalLineValue;
  
  // Market types available in the calculator
  final List<String> _marketTypes = ['1X2', 'Over/Under', 'Double Chance', 'BTTS'];
  // Goal line values for Over/Under markets
  final List<String> _goalLineValues = ['0.5', '1.5', '2.5', '3.5', '4.5'];

  @override
  void dispose() {
    _totalStakeController.dispose();
    super.dispose();
  }

  void _addNewOddsInput() {
    setState(() {
      _oddsInputs.add({'bookmaker': '', 'outcome': '', 'odds': null});
    });
  }

  void _removeOddsInput(int index) {
    if (_oddsInputs.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('At least 2 odds are required for arbitrage')),
      );
      return;
    }

    setState(() {
      _oddsInputs.removeAt(index);
    });
  }
  
  void _updateOutcomeSuggestions() {
    // Update outcome suggestions based on selected market type
    if (_selectedMarketType == '1X2') {
      setState(() {
        // Clear existing outcomes and add standard 1X2 outcomes
        if (_oddsInputs.length < 3) {
          while (_oddsInputs.length < 3) {
            _oddsInputs.add({'bookmaker': '', 'outcome': '', 'odds': null});
          }
        }
        _oddsInputs[0]['outcome'] = 'Home Win (1)';
        _oddsInputs[1]['outcome'] = 'Draw (X)';
        _oddsInputs[2]['outcome'] = 'Away Win (2)';
      });
    } else if (_selectedMarketType == 'Over/Under') {
      setState(() {
        // Reset to just two outcomes for over/under
        if (_oddsInputs.length > 2) {
          _oddsInputs.length = 2;
        }
        _oddsInputs[0]['outcome'] = 'Over ${_goalLineValue ?? '2.5'}';
        _oddsInputs[1]['outcome'] = 'Under ${_goalLineValue ?? '2.5'}';
      });
    } else if (_selectedMarketType == 'Double Chance') {
      setState(() {
        if (_oddsInputs.length < 3) {
          while (_oddsInputs.length < 3) {
            _oddsInputs.add({'bookmaker': '', 'outcome': '', 'odds': null});
          }
        }
        _oddsInputs[0]['outcome'] = '1X';
        _oddsInputs[1]['outcome'] = '12';
        _oddsInputs[2]['outcome'] = 'X2';
      });
    } else if (_selectedMarketType == 'BTTS') {
      setState(() {
        if (_oddsInputs.length > 2) {
          _oddsInputs.length = 2;
        }
        _oddsInputs[0]['outcome'] = 'Yes';
        _oddsInputs[1]['outcome'] = 'No';
      });
    }
  }

  Future<void> _calculateArbitrage() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Save form values
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
      _error = '';
      _result = null;
    });

    try {
      double totalStake = double.parse(_totalStakeController.text);
      
      // Prepare odds data with market type information
      final List<Map<String, dynamic>> oddsData = _oddsInputs.map((input) {
        Map<String, dynamic> data = {
          'bookmaker': input['bookmaker'],
          'outcome': input['outcome'],
          'odds': input['odds']
        };
        
        // Add market information for Over/Under markets
        if (_selectedMarketType == 'Over/Under' && _goalLineValue != null) {
          data['market_type'] = 'over_under';
          data['market_params'] = _goalLineValue;
        }
        
        return data;
      }).toList();

      final result = await _apiService.calculateArbitrage(
        oddsData,
        totalStake: totalStake,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arbitrage Calculator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter odds from different bookmakers to calculate arbitrage',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Total stake input
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Stake (₦)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _totalStakeController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter total amount to stake',
                          prefixText: '₦ ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a stake amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Stake must be greater than zero';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Market type selector
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      DropdownButtonFormField<String>(
                        value: _selectedMarketType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select market type',
                        ),
                        items: _marketTypes.map((market) {
                          return DropdownMenuItem<String>(
                            value: market,
                            child: Text(market),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null && value != _selectedMarketType) {
                            setState(() {
                              _selectedMarketType = value;
                              // Reset goal line value if switching away from Over/Under
                              if (value != 'Over/Under') {
                                _goalLineValue = null;
                              } else {
                                _goalLineValue = '2.5'; // Default
                              }
                              _updateOutcomeSuggestions();
                            });
                          }
                        },
                      ),
                      
                      // Goal line value selector (only for Over/Under)
                      if (_selectedMarketType == 'Over/Under') ...[
                        const SizedBox(height: 16),
                        Text(
                          'Goal Line',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _goalLineValue ?? _goalLineValues[2], // Default to 2.5
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Select goal line',
                          ),
                          items: _goalLineValues.map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _goalLineValue = value;
                                _updateOutcomeSuggestions();
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Odds inputs
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Odds Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // List of odds inputs
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _oddsInputs.length,
                        separatorBuilder: (context, index) => const Divider(height: 32),
                        itemBuilder: (context, index) => _buildOddsInputRow(index),
                      ),

                      const SizedBox(height: 16),

                      // Add more button
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _addNewOddsInput,
                          icon: Icon(Icons.add),
                          label: Text('Add Another Outcome'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Calculate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _calculateArbitrage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? SpinKitRing(
                          color: Colors.white,
                          size: 20.0,
                          lineWidth: 2,
                        )
                      : Text(
                          'Calculate Arbitrage',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Results section
              if (_result != null) ...[
                const SizedBox(height: 32),
                _buildResults(_result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOddsInputRow(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              // Bookmaker input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Bookmaker',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Bet9ja',
                ),
                onSaved: (value) {
                  _oddsInputs[index]['bookmaker'] = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Outcome input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Outcome',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Home Win',
                ),
                initialValue: _oddsInputs[index]['outcome'],
                onSaved: (value) {
                  _oddsInputs[index]['outcome'] = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Odds input
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Odds',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2.5',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    _oddsInputs[index]['odds'] = double.parse(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid odds';
                  }
                  if (double.parse(value) <= 1.0) {
                    return 'Must be > 1.0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _removeOddsInput(index),
          icon: Icon(Icons.delete, color: Colors.red),
          tooltip: 'Remove',
        ),
      ],
    );
  }

  Widget _buildResults(Map<String, dynamic> result) {
    final arbitragePercentage = result['arbitrage_percentage'] as double;
    final isArbitrage = arbitragePercentage > 0;
    final stakeDetails = result['stake_details'] as List<dynamic>;
    final marketType = result['market_type'] as String? ?? _selectedMarketType;
    
    return Card(
      elevation: 3,
      color: isArbitrage ? AppTheme.successColor.withOpacity(0.1) : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isArbitrage ? Icons.check_circle : Icons.cancel,
                  color: isArbitrage ? AppTheme.successColor : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isArbitrage
                        ? 'Arbitrage Opportunity Found!'
                        : 'No Arbitrage Opportunity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isArbitrage ? AppTheme.successColor : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Market type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Market Type:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  marketType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Arbitrage percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Arbitrage Percentage:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${arbitragePercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isArbitrage ? AppTheme.successColor : Colors.red,
                  ),
                ),
              ],
            ),
            
            if (isArbitrage) ...[
              const Divider(height: 32),
              Text(
                'Recommended Stakes:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Stake details table
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: stakeDetails.length,
                itemBuilder: (context, index) {
                  final detail = stakeDetails[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${detail['outcome']} (${detail['bookmaker']})',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Odds: ${detail['odds'].toStringAsFixed(2)}'),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₦${detail['stake'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Return: ₦${detail['potential_return'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const Divider(height: 32),
              
              // Expected profit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expected Profit:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₦${result['expected_profit'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 