import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile header
              Center(
                child: Column(
                  children: [
                    // Profile image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      backgroundImage: user?.photoUrl != null 
                          ? NetworkImage(user!.photoUrl!) 
                          : null,
                      child: user?.photoUrl == null 
                          ? Icon(Icons.person, size: 50, color: AppTheme.primaryColor) 
                          : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // User name
                    Text(
                      user?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // User email
                    Text(
                      user?.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // Account settings section
              _buildSectionHeader(context, 'Account Settings'),
              
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // Navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit Profile - Coming Soon')),
                  );
                },
              ),
              
              _buildSettingItem(
                context,
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Navigate to change password screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Change Password - Coming Soon')),
                  );
                },
              ),
              
              // App settings section
              _buildSectionHeader(context, 'App Settings'),
              
              _buildSwitchItem(
                context,
                icon: isDarkTheme ? Icons.dark_mode : Icons.light_mode,
                title: 'Dark Mode',
                value: isDarkTheme,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  // TODO: Implement theme switching
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Theme switching - Coming Soon')),
                  );
                },
              ),
              
              _buildSwitchItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  // TODO: Implement notification toggle
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
                  );
                },
              ),
              
              // Bookmaker settings section
              _buildSectionHeader(context, 'Bookmaker Settings'),
              
              _buildSettingItem(
                context,
                icon: Icons.sports_soccer_outlined,
                title: 'Select Bookmakers',
                onTap: () {
                  // Navigate to bookmaker selection screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bookmaker Selection - Coming Soon')),
                  );
                },
              ),
              
              // Arbitrage settings section
              _buildSectionHeader(context, 'Arbitrage Settings'),
              
              _buildSettingItem(
                context,
                icon: Icons.money,
                title: 'Set Default Stake',
                onTap: () {
                  // Navigate to stake settings screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stake Settings - Coming Soon')),
                  );
                },
              ),
              
              _buildSettingItem(
                context,
                icon: Icons.percent,
                title: 'Set Minimum Profit %',
                onTap: () {
                  // Navigate to profit settings screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Profit Settings - Coming Soon')),
                  );
                },
              ),
              
              // About section
              _buildSectionHeader(context, 'About'),
              
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: 'About Us',
                onTap: () {
                  // Navigate to about screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('About Us - Coming Soon')),
                  );
                },
              ),
              
              _buildSettingItem(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  // Navigate to help screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Help & Support - Coming Soon')),
                  );
                },
              ),
              
              // Logout button
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  icon: Icon(Icons.logout),
                  label: Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
  
  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
} 