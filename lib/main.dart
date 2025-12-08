import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/settings_page.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'history_page.dart';
import 'theme/theme_service.dart';
import 'widgets/app_bar.dart';
import 'detection_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/detection_manager.dart';
import 'services/local_cache_service.dart';
import 'services/sync_service.dart';
import 'providers/app_settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'widgets/live_stream_widget.dart';
import 'widgets/ai_recommendation_widget.dart';
import 'pages/statistics_page_redesigned.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  print('✅ Environment variables loaded');
  print('   SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  print('   SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');

  final savedTheme = await ThemeService.loadThemeMode();

  // Initialize Supabase with credentials from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://iwbftcnzcuhdapjxrlhe.supabase.co',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_kKNvrSZqF98IAPkKGW_fdg_GqttByHO',
  );
  print('✅ Supabase initialized');

  // ✅ PHASE 1: Initialize local cache service
  await LocalCacheService.initialize();
  print('✅ Local cache initialized');

  // ✅ PHASE 1: Initialize sync service
  final syncService = SyncService();
  await syncService.initialize();
  print('✅ Sync service initialized');

  // ✅ PHASE 1: Initialize app settings
  final appSettings = AppSettingsProvider();
  await appSettings.initialize();
  print('✅ App settings initialized');

  // Start background auto-processing
  final detectionManager = DetectionManager();
  detectionManager.startPolling(
    const Duration(seconds: 10),
    appSettings, // Pass settings to manager
  );
  print('✅ Detection polling started');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              ThemeProvider()..toggleTheme(savedTheme == ThemeMode.dark),
        ),
        ChangeNotifierProvider(
          create: (_) => appSettings,
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsProvider(),
        ),
      ],
      child: const AgriSenseApp(),
    ),
  );
}


class AgriSenseApp extends StatelessWidget {
  const AgriSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriSense AI Monitor',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      home: const MainWrapper(),
    );
  }
}

// -------------------------------------------------------------
// MAIN WRAPPER WITH MINIMALIST DRAWER NAVIGATION
// Modern UI with navigation drawer instead of bottom nav
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _navItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      page: const DashboardPage(),
    ),
    NavigationItem(
      title: 'Statistics',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      page: const StatisticsPageRedesigned(),
    ),
    NavigationItem(
      title: 'History',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      page: const HistoryPage(),
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      page: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildModernDrawer(context),
      body: _navItems[_selectedIndex].page,
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // ============= ENHANCED HEADER WITH USER PROFILE =============
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon + Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AgriSense',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                ],
              ),
            ),

            // ============= MAIN NAVIGATION ITEMS =============
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  // Navigation Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'NAVIGATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...List.generate(
                    _navItems.length,
                    (index) => _buildNavItem(
                      context,
                      index,
                      _navItems[index],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerActionItem(
                    context,
                    icon: Icons.brightness_4_outlined,
                    title: 'Dark Mode',
                    subtitle: themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                    onTap: () {
                      themeProvider.toggleTheme(!themeProvider.isDarkMode);
                    },
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeColor: Colors.green.shade600,
                    ),
                  ),
                  _buildDrawerActionItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About AgriSense',
                    subtitle: 'Version & Credits',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  _buildDrawerActionItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'Documentation & FAQs',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                  _buildDrawerActionItem(
                    context,
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    subtitle: 'Report issues & suggestions',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your feedback! We appreciate it.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // ============= FOOTER SECTION =============
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All systems operational',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last sync: Just now',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green.shade600,
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

  // ============= HELPER: BUILD DRAWER ACTION ITEM =============
  Widget _buildDrawerActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing else const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============= HELPER: SHOW ABOUT DIALOG =============
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About AgriSense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AgriSense AI Monitor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Version: 1.0.0',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'An intelligent crop health monitoring system powered by AI. Detect diseases in real-time and get AI-powered treatment recommendations.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Features:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const Text('• Real-time disease detection'),
              const Text('• AI-powered recommendations'),
              const Text('• Historical data tracking'),
              const Text('• Statistics & analytics'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============= HELPER: SHOW HELP DIALOG =============
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpSection(context, 'Getting Started', [
                  'Open the live stream to view your farm',
                  'Wait for the AI to detect diseases automatically',
                  'View recommendations when diseases are found',
                ]),
                const SizedBox(height: 16),
                _buildHelpSection(context, 'Using Statistics', [
                  'Go to Statistics tab to view trends',
                  'Check historical detection data',
                  'Export data for further analysis',
                ]),
                const SizedBox(height: 16),
                _buildHelpSection(context, 'Tips', [
                  'Ensure good lighting for accurate detection',
                  'Check History tab for past detections',
                  'Enable notifications for alerts',
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============= HELPER: BUILD HELP SECTION =============
  Widget _buildHelpSection(BuildContext context, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: Colors.green.shade600),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    NavigationItem item,
  ) {
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.shade600.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
                  color: Colors.green.shade400.withOpacity(0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.shade600.withOpacity(0.25)
                  : Colors.grey.shade200.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
              size: 24,
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15,
              color: isSelected
                  ? Colors.green.shade900
                  : Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.green.shade600,
                )
              : null,
          onTap: () {
            setState(() => _selectedIndex = index);
            Navigator.pop(context); // Close drawer
          },
        ),
      ),
    );
  }
}

// Navigation Item Model
class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}

// =============================================================
// DASHBOARD PAGE (REFACTORED)
// Orchestrates: LiveStreamWidget + AIRecommendationWidget
// Manages: Detection polling, persistent state, widget composition
// =============================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<NormalizedDetection> _currentDetections = [];
  NormalizedDetection? _lastDetectionPersistent;
  bool _isCurrentlyDetected = false;
  Timer? _detectionTimer;

  late GlobalKey _aiRecommendationWidgetKey;

  @override
  void initState() {
    super.initState();
    _aiRecommendationWidgetKey = GlobalKey();
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _fetchDetections(),
    );
  }

  Future<void> _fetchDetections() async {
    final data = await DetectionService.fetchDetections();

    setState(() {
      _currentDetections = data;

      if (data.isNotEmpty) {
        _lastDetectionPersistent = data.first;
        _isCurrentlyDetected = true;
      } else {
        _isCurrentlyDetected = false;
      }
    });

    // Trigger auto-recommendation update
    if (mounted) {
      final state = _aiRecommendationWidgetKey.currentState as dynamic;
      state?.triggerAutoRecommendation();
    }
  }

  void _onDiseaseCleared() {
    // Called when disease disappears from persistent state
    // Can be used for analytics or other cleanup
    print("Disease cleared");
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverToBoxAdapter(
            child: ModernAppBar(
              title: "AgriSense Monitor",
              subtitle: "Real-time Chili Crop Health",
              icon: Icons.agriculture,
              onMenuPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Stream + Detections
                    LiveStreamWidget(
                      detections: _currentDetections,
                      streamUrl: "${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}/video_feed",
                    ),
                    const SizedBox(height: 28),

                    // AI Recommendations
                    AIRecommendationWidget(
                      key: _aiRecommendationWidgetKey,
                      currentDetections: _currentDetections,
                      lastDetectionPersistent: _lastDetectionPersistent,
                      isCurrentlyDetected: _isCurrentlyDetected,
                      onDiseaseCleared: _onDiseaseCleared,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}





