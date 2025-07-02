import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoRefresh = true;
  String _currency = 'USD';
  String _refreshInterval = '30';

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'JPY', 'BTC', 'ETH'];
  final List<String> _refreshIntervals = ['10', '30', '60', '300'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.settings,
                size: 32,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Appearance Settings
          _buildSettingsSection(
            context,
            'Appearance',
            Icons.palette,
            [
              _buildSwitchTile(
                'Dark Mode',
                'Enable dark theme',
                _darkMode,
                (value) {
                  setState(() {
                    _darkMode = value;
                  });
                  // TODO: Implement theme switching
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Settings
          _buildSettingsSection(
            context,
            'Notifications',
            Icons.notifications,
            [
              _buildSwitchTile(
                'Push Notifications',
                'Receive price alerts and updates',
                _notifications,
                (value) {
                  setState(() {
                    _notifications = value;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Data Settings
          _buildSettingsSection(
            context,
            'Data & Sync',
            Icons.sync,
            [
              _buildSwitchTile(
                'Auto Refresh',
                'Automatically refresh market data',
                _autoRefresh,
                (value) {
                  setState(() {
                    _autoRefresh = value;
                  });
                },
              ),
              _buildDropdownTile(
                'Refresh Interval',
                'How often to refresh data (seconds)',
                _refreshInterval,
                _refreshIntervals,
                (value) {
                  setState(() {
                    _refreshInterval = value!;
                  });
                },
              ),
              _buildDropdownTile(
                'Default Currency',
                'Primary currency for price display',
                _currency,
                _currencies,
                (value) {
                  setState(() {
                    _currency = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account Settings
          _buildSettingsSection(
            context,
            'Account',
            Icons.account_circle,
            [
              _buildActionTile(
                'Export Portfolio',
                'Download portfolio data as CSV',
                Icons.download,
                () {
                  _showSnackBar('Portfolio export functionality coming soon');
                },
              ),
              _buildActionTile(
                'Import Portfolio',
                'Upload portfolio data from file',
                Icons.upload,
                () {
                  _showSnackBar('Portfolio import functionality coming soon');
                },
              ),
              _buildActionTile(
                'Reset Settings',
                'Restore default settings',
                Icons.restore,
                () {
                  _showResetDialog();
                },
                color: Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSettingsSection(
            context,
            'About',
            Icons.info,
            [
              _buildInfoTile('Version', '1.0.0'),
              _buildInfoTile('Build', '2025.07.02'),
              _buildActionTile(
                'Terms of Service',
                'View terms and conditions',
                Icons.description,
                () {
                  _showSnackBar('Terms of Service coming soon');
                },
              ),
              _buildActionTile(
                'Privacy Policy',
                'View privacy policy',
                Icons.privacy_tip,
                () {
                  _showSnackBar('Privacy Policy coming soon');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(color: color),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _darkMode = false;
                _notifications = true;
                _autoRefresh = true;
                _currency = 'USD';
                _refreshInterval = '30';
              });
              Navigator.of(context).pop();
              _showSnackBar('Settings reset to default values');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
