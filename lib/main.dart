import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/settings_page.dart';
import 'theme/theme_provider.dart';
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
import 'pages/statistics_page.dart';



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

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.light, // set here instead of ThemeData.brightness
  ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    brightness: Brightness.dark, // set here
  ),

        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
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
      page: const StatisticsPage(),
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
    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            // Modern Drawer Header with Enhanced Design
            Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon with Glassmorphism Effect
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // App Title
                  const Text(
                    'AgriSense',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Tagline
                  Text(
                    'Crop Health Monitor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(
                    context,
                    index,
                    _navItems[index],
                  ),
                ),
              ),
            ),

            // Footer with Version
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Text(
                        'Latest release',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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





