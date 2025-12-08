import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_bar.dart';
import '../providers/app_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final appSettings = Provider.of<AppSettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ModernAppBar(
              title: "Settings",
              subtitle: "Customize your experience",
              icon: Icons.settings,
              onMenuPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          SliverToBoxAdapter(
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // ========== APPEARANCE SECTION ==========
                _buildSectionHeader("Appearance"),
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  subtitle: const Text("Enable dark theme"),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  secondary: const Icon(Icons.dark_mode),
                ),
                const Divider(),

                // ========== LIVE DETECTION SECTION ==========
                _buildSectionHeader("Live Detection"),
                SwitchListTile(
                  title: const Text("Live Updates"),
                  subtitle: const Text("Real-time disease detection"),
                  value: appSettings.liveUpdatesEnabled,
                  onChanged: (value) async {
                    await appSettings.toggleLiveUpdates(value);
                    if (!value) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⏸️ Live detection paused')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('▶️ Live detection resumed')),
                        );
                      }
                    }
                  },
                  secondary: const Icon(Icons.play_circle),
                ),
                ListTile(
                  title: const Text("Update Interval"),
                  subtitle: Text("${appSettings.updateIntervalSeconds}s"),
                  trailing: PopupMenuButton<int>(
                    onSelected: (seconds) {
                      appSettings.setUpdateInterval(seconds);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 5, child: Text('5 seconds')),
                      const PopupMenuItem(value: 10, child: Text('10 seconds')),
                      const PopupMenuItem(value: 30, child: Text('30 seconds')),
                      const PopupMenuItem(value: 60, child: Text('1 minute')),
                    ],
                    child: const Icon(Icons.schedule),
                  ),
                ),
                const Divider(),

                // ========== NOTIFICATIONS SECTION ==========
                _buildSectionHeader("Notifications"),
                SwitchListTile(
                  title: const Text("Disease Alerts"),
                  subtitle: const Text("Get notified when diseases are detected"),
                  value: appSettings.notificationsEnabled,
                  onChanged: (value) async {
                    await appSettings.toggleNotifications(value);
                    if (value) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔔 Notifications enabled')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🔕 Notifications disabled')),
                        );
                      }
                    }
                  },
                  secondary: const Icon(Icons.notifications_active),
                ),
                const Divider(),

                // ========== OFFLINE SECTION ==========
                _buildSectionHeader("Offline Mode"),
                SwitchListTile(
                  title: const Text("Use Cached Data"),
                  subtitle: const Text("Access detection history without internet"),
                  value: appSettings.offlineModeEnabled,
                  onChanged: (value) async {
                    await appSettings.toggleOfflineMode(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? '📴 Offline mode enabled' : '📡 Offline mode disabled',
                          ),
                        ),
                      );
                    }
                  },
                  secondary: const Icon(Icons.cloud_off),
                ),
                const Divider(),

                // ========== ABOUT SECTION ==========
                _buildSectionHeader("About"),
                ListTile(
                  title: const Text("App Version"),
                  subtitle: const Text("1.0.0"),
                  trailing: const Icon(Icons.info),
                ),
                ListTile(
                  title: const Text("Help & Support"),
                  onTap: () {
                    _showHelpDialog(context);
                  },
                  trailing: const Icon(Icons.help),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Help & Support"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📡 Live Detection: Monitor crops in real-time"),
              SizedBox(height: 12),
              Text("🔔 Notifications: Get alerts when diseases are detected"),
              SizedBox(height: 12),
              Text("📴 Offline Mode: Access history without internet"),
              SizedBox(height: 12),
              Text("For more help, contact: support@agrisense.app"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}