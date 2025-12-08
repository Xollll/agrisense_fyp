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
// MAIN WRAPPER WITH BUBBLE NAVIGATION
// -------------------------------------------------------------
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    StatisticsPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Padding(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
  child: Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      borderRadius: BorderRadius.circular(26),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.12,
          ),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: NavigationBar(
        height: 66,
        backgroundColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
        elevation: 0,
        animationDuration: const Duration(milliseconds: 300),

        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: "Statistics",
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: "History",
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    ),
  ),
),


    );
  }
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





