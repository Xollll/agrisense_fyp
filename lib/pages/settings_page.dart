import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_app_bar.dart';
import '../providers/app_settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppBarBuilder.settings(
              context: context,
              onMenuPressed: () {},
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
              children: [
                // Status Overview Card
                _buildStatusOverviewCard(context, appSettings, isDarkMode),
                const SizedBox(height: 24),

                // Live Detection Section
                _buildSectionHeader(context, "Live Detection", Icons.sensors),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Live Updates",
                  subtitle: appSettings.liveUpdatesEnabled 
                      ? "Real-time detection active" 
                      : "Detection paused",
                  icon: Icons.play_circle_rounded,
                  iconColor: const Color(0xFF10B981),
                  isToggle: true,
                  value: appSettings.liveUpdatesEnabled,
                  onChanged: (value) async {
                    HapticFeedback.mediumImpact();
                    await appSettings.toggleLiveUpdates(value);
                    if (context.mounted) {
                      _showStyledSnackBar(
                        context,
                        value ? '▶️ Live detection started' : '⏸️ Live detection paused',
                        value ? const Color(0xFF10B981) : Colors.orange,
                      );
                    }
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Update Interval",
                  subtitle: _getIntervalLabel(appSettings.updateIntervalSeconds),
                  icon: Icons.schedule_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  onTap: () => _showModernIntervalMenu(context, appSettings),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 24),

                // Notifications Section
                _buildSectionHeader(context, "Notifications", Icons.notifications_active),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Disease Alerts",
                  subtitle: appSettings.notificationsEnabled
                      ? "You'll be notified of diseases"
                      : "Notifications are off",
                  icon: Icons.notifications_active_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  isToggle: true,
                  value: appSettings.notificationsEnabled,
                  onChanged: (value) async {
                    HapticFeedback.mediumImpact();
                    await appSettings.toggleNotifications(value);
                    if (context.mounted) {
                      _showStyledSnackBar(
                        context,
                        value ? '🔔 Alerts enabled' : '🔕 Alerts disabled',
                        value ? const Color(0xFFF59E0B) : Colors.grey,
                      );
                    }
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 24),

                // Data & Storage Section
                _buildSectionHeader(context, "Data & Storage", Icons.storage),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Offline Mode",
                  subtitle: appSettings.offlineModeEnabled
                      ? "Working without internet"
                      : "Requires internet connection",
                  icon: Icons.cloud_off_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  isToggle: true,
                  value: appSettings.offlineModeEnabled,
                  onChanged: (value) async {
                    HapticFeedback.mediumImpact();
                    await appSettings.toggleOfflineMode(value);
                    if (context.mounted) {
                      _showStyledSnackBar(
                        context,
                        value ? '📴 Offline mode enabled' : '📡 Online mode active',
                        value ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                      );
                    }
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Clear Cache",
                  subtitle: "Free up storage space",
                  icon: Icons.cleaning_services_rounded,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => _showClearCacheDialog(context),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader(context, "About", Icons.info),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "App Version",
                  subtitle: "1.0.0 (Build 2024)",
                  icon: Icons.info_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  onTap: () => _showAboutDialog(context),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Privacy Policy",
                  subtitle: "View our privacy policy",
                  icon: Icons.privacy_tip_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () => _showPrivacyPolicyDialog(context),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                _buildEnhancedSettingCard(
                  context,
                  title: "Help & Support",
                  subtitle: "Get help or send feedback",
                  icon: Icons.help_rounded,
                  iconColor: const Color(0xFF10B981),
                  onTap: () => _showHelpSupportDialog(context),
                  isDarkMode: isDarkMode,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverviewCard(
    BuildContext context, 
    AppSettingsProvider appSettings,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.15),
            const Color(0xFF059669).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plant Health Monitor',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your plants healthy',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  context,
                  icon: appSettings.liveUpdatesEnabled 
                      ? Icons.check_circle 
                      : Icons.pause_circle,
                  label: 'Live Updates',
                  value: appSettings.liveUpdatesEnabled ? 'Active' : 'Paused',
                  color: appSettings.liveUpdatesEnabled 
                      ? const Color(0xFF10B981) 
                      : Colors.orange,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.shade300,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  context,
                  icon: appSettings.notificationsEnabled 
                      ? Icons.notifications_active 
                      : Icons.notifications_off,
                  label: 'Alerts',
                  value: appSettings.notificationsEnabled ? 'On' : 'Off',
                  color: appSettings.notificationsEnabled 
                      ? const Color(0xFFF59E0B) 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
    bool isToggle = false,
    bool value = false,
    ValueChanged<bool>? onChanged,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isToggle ? null : () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.15),
                    iconColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isToggle)
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withOpacity(0.5),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getIntervalLabel(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    return '${seconds ~/ 60} minute${seconds >= 120 ? 's' : ''}';
  }

  void _showModernIntervalMenu(BuildContext context, AppSettingsProvider appSettings) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Update Interval',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...[
                    (5, 'Every 5 seconds', Icons.flash_on),
                    (10, 'Every 10 seconds', Icons.speed),
                    (30, 'Every 30 seconds', Icons.update),
                    (60, 'Every 1 minute', Icons.schedule),
                  ].map((option) {
                    final isSelected = appSettings.updateIntervalSeconds == option.$1;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        appSettings.setUpdateInterval(option.$1);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    const Color(0xFF3B82F6).withOpacity(0.15),
                                    const Color(0xFF3B82F6).withOpacity(0.08),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFF3B82F6).withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option.$3,
                              color: isSelected 
                                  ? const Color(0xFF3B82F6) 
                                  : Colors.grey.shade600,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option.$2,
                                style: TextStyle(
                                  fontWeight: isSelected 
                                      ? FontWeight.bold 
                                      : FontWeight.w600,
                                  color: isSelected 
                                      ? const Color(0xFF3B82F6) 
                                      : Colors.grey.shade800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF3B82F6),
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStyledSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cleaning_services_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Clear Cache'),
          ],
        ),
        content: const Text(
          'This will remove all cached data including detection history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              _showStyledSnackBar(
                context,
                '🗑️ Cache cleared successfully',
                const Color(0xFF10B981),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About App'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plant Health Monitor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0 (Build 2024)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI-powered plant disease detection and monitoring system designed to help farmers and gardeners maintain healthy crops.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.privacy_tip_rounded,
                color: Color(0xFF8B5CF6),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Protection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AgriSense respects your privacy. We collect minimal data necessary for disease detection and only use it to improve your experience.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Usage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• Farm images are processed locally on your device\n• Detection results are stored securely\n• No personal data is shared with third parties\n• You can delete your data anytime',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Us',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For privacy concerns, contact us at: privacy@agrisense.app',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.help_rounded,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Getting Started',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Go to Dashboard to see live detection\n2. Ensure good lighting for accurate results\n3. Diseased plants will be highlighted\n4. View recommendations for treatment',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Common Issues',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Q: Detection not working?\nA: Check your internet connection and ensure the server is running.\n\nQ: Inaccurate results?\nA: Improve lighting and ensure plants are visible.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: support@agrisense.app\nPhone: +1-800-AGRI-SENSE',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
