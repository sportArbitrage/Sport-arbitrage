import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import 'arbitrage/arbitrage_screen.dart';
import 'calculator/calculator_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  late final List<Widget> _screens;
  
  final List<String> _titles = [
    'Arbitrage Opportunities',
    'Arbitrage Calculator',
    'Notifications',
    'Profile',
  ];
  
  @override
  void initState() {
    super.initState();
    _screens = [
      ArbitrageScreen(),
      CalculatorScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 2)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // Refresh the current screen data
                if (_currentIndex == 0) {
                  // Refresh arbitrage opportunities
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refreshing arbitrage opportunities...')),
                  );
                } else if (_currentIndex == 2) {
                  // Refresh notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refreshing notifications...')),
                  );
                }
              },
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Arbitrage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 