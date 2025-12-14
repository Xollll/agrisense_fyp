import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/settings_page.dart';
import 'pages/history_page.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'theme/theme_service.dart';
import 'widgets/enhanced_app_bar.dart';
import 'widgets/floating_menu_button.dart';
import 'detection_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/detection_manager.dart';
import 'services/local_cache_service.dart';
import 'services/sync_service.dart';
import 'providers/app_settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/notification_provider.dart';
import 'widgets/live_stream_widget.dart';
import 'widgets/ai_recommendation_widget.dart';
import 'pages/statistics_page_redesigned.dart';
import 'package:http/http.dart' as http;
import 'screens/splash_screen.dart';
import 'screens/notification_list_page.dart';
import 'services/notification_service.dart';



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

  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  print('✅ Notification service initialized');

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

  // Initialize notification provider
  final notificationProvider = NotificationProvider();
  print('✅ Notification provider initialized');

  // Start background auto-processing
  final detectionManager = DetectionManager();
  detectionManager.setNotificationProvider(notificationProvider);
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
        ChangeNotifierProvider.value(
          value: notificationProvider,
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
      routes: {
        '/notifications': (context) => const NotificationListPage(),
      },
      home: const SplashScreenWrapper(),
    );
  }
}

/// Wrapper to show splash screen and then navigate to main app
class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navigateToHome();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _navigateToHome() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LivelyAgricultureSplashScreen();
  }
}

// -------------------------------------------------------------
// MAIN WRAPPER WITH FLOATING MENU NAVIGATION
// Modern UI with beautiful floating action menu
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

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
      page: const StatisticsPageModern(),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Page content
          _navItems[_selectedIndex].page,

          // Floating menu button
          FloatingMenuButton(
            currentIndex: _selectedIndex,
            items: _navItems
                .map(
                  (item) => MenuItemConfig(
                    title: item.title,
                    icon: item.icon,
                    selectedIcon: item.selectedIcon,
                  ),
                )
                .toList(),
            quickActions: [
              QuickActionConfig(
                label: 'Dark Mode',
                icon: themeProvider.isDarkMode
                    ? Icons.brightness_7_rounded
                    : Icons.brightness_4_rounded,
                color: Colors.amber,
                onTap: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              ),
              QuickActionConfig(
                label: 'About',
                icon: Icons.info_outline_rounded,
                color: Colors.blue,
                onTap: () => _showAboutDialog(context),
              ),
              QuickActionConfig(
                label: 'Help',
                icon: Icons.help_outline_rounded,
                color: Colors.green,
                onTap: () => _showHelpDialog(context),
              ),
            ],
            onItemSelected: (index) {
              setState(() => _selectedIndex = index);
            },
          ),
        ],
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
  Timer? _serverCheckTimer;
  bool _isServerOnline = false;
  String _streamUrl = "${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}/video_feed";

  late GlobalKey _aiRecommendationWidgetKey;

  @override
  void initState() {
    super.initState();
    _aiRecommendationWidgetKey = GlobalKey();
    
    // Detection polling (unchanged)
    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _fetchDetections(),
    );
    
    // Server health check - detect when server starts/stops
    _serverCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkServerHealth(),
    );
    
    // Initial server check
    _checkServerHealth();
  }

  /// Check if Flask server is online
  Future<void> _checkServerHealth() async {
    final baseUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
    try {
      final response = await http.head(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 2));
      
      final isOnline = response.statusCode == 200;
      
      // If server status changed, trigger stream restart
      if (isOnline != _isServerOnline && mounted) {
        setState(() {
          _isServerOnline = isOnline;
        });
        
        // Force stream URL change to trigger didUpdateWidget
        if (isOnline) {
          print('✅ Server is online - triggering stream restart');
          _restartStream();
        } else {
          print('❌ Server is offline - stream will show last frame');
        }
      }
    } catch (e) {
      // Server unreachable
      if (_isServerOnline && mounted) {
        print('❌ Server health check failed: $e');
        setState(() {
          _isServerOnline = false;
        });
      }
    }
  }

  /// Force stream to restart by toggling URL
  void _restartStream() {
    if (mounted) {
      setState(() {
        // Temporarily change URL to empty to reset stream
        _streamUrl = '';
      });
      
      // After a short delay, restore the actual URL
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _streamUrl = "${dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000'}/video_feed";
          });
        }
      });
    }
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

    // ✅ ANTI-REDUNDANCY: Do NOT auto-trigger recommendations
    // Only user-triggered actions (button clicks) should call Gemini API
    // Background polling only updates UI state, no API calls
  }

  void _onDiseaseCleared() {
    // Called when disease disappears from persistent state
    // Can be used for analytics or other cleanup
    print("Disease cleared");
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _serverCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Status Indicators
          SliverToBoxAdapter(
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return AppBarBuilder.dashboard(
                  context: context,
                  onMenuPressed: () {
                    // Menu button removed - floating menu is now the primary navigation
                  },
                  notificationCount: notificationProvider.unreadCount,
                );
              },
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Stream + Detections
                    LiveStreamWidget(
                      detections: _currentDetections,
                      streamUrl: _streamUrl,
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





