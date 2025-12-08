import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/modern_card.dart';
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
                _buildSectionHeader(context, "Appearance"),
                _buildModernSettingTile(
                  context,
                  title: "Dark Mode",
                  subtitle: "Enable dark theme",
                  icon: Icons.dark_mode_rounded,
                  isToggle: true,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
                const SizedBox(height: 16),

                // ========== LIVE DETECTION SECTION ==========
                _buildSectionHeader(context, "Live Detection"),
                _buildModernSettingTile(
                  context,
                  title: "Live Updates",
                  subtitle: "Real-time disease detection",
                  icon: Icons.play_circle_rounded,
                  isToggle: true,
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
                ),
                const SizedBox(height: 12),
                _buildModernSettingTile(
                  context,
                  title: "Update Interval",
                  subtitle: "${appSettings.updateIntervalSeconds}s",
                  icon: Icons.schedule_rounded,
                  onTap: () => _showIntervalMenu(context, appSettings),
                ),
                const SizedBox(height: 16),

                // ========== NOTIFICATIONS SECTION ==========
                _buildSectionHeader(context, "Notifications"),
                _buildModernSettingTile(
                  context,
                  title: "Disease Alerts",
                  subtitle: "Get notified when diseases are detected",
                  icon: Icons.notifications_active_rounded,
                  isToggle: true,
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
                ),
                const SizedBox(height: 16),

                // ========== OFFLINE SECTION ==========
                _buildSectionHeader(context, "Offline Mode"),
                _buildModernSettingTile(
                  context,
                  title: "Use Cached Data",
                  subtitle: "Access detection history without internet",
                  icon: Icons.cloud_off_rounded,
                  isToggle: true,
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
                ),
                const SizedBox(height: 16),

                // ========== ABOUT SECTION ==========
                _buildSectionHeader(context, "About"),
                _buildModernSettingTile(
                  context,
                  title: "App Version",
                  subtitle: "1.0.0",
                  icon: Icons.info_rounded,
                ),
                const SizedBox(height: 12),
                _buildModernSettingTile(
                  context,
                  title: "Help & Support",
                  subtitle: "Get help and support",
                  icon: Icons.help_rounded,
                  onTap: () => _showHelpDialog(context),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _buildModernSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool isToggle = false,
    bool value = false,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return ModernCard(
      onTap: isToggle ? null : onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isToggle)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
              ),
            )
          else
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
        ],
      ),
    );
  }

  void _showIntervalMenu(BuildContext context, AppSettingsProvider appSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Interval"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('5 seconds'),
              onTap: () {
                appSettings.setUpdateInterval(5);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('10 seconds'),
              onTap: () {
                appSettings.setUpdateInterval(10);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 seconds'),
              onTap: () {
                appSettings.setUpdateInterval(30);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1 minute'),
              onTap: () {
                appSettings.setUpdateInterval(60);
                Navigator.pop(context);
              },
            ),
          ],
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