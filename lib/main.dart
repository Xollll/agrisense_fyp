import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pages/settings_page.dart';
import 'theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'history_page.dart';
import 'theme/theme_service.dart';
import 'widgets/app_bar.dart';
import 'detection_service.dart';
import 'gemini_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/detection_manager.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedTheme = await ThemeService.loadThemeMode();

  await Supabase.initialize(
    url: 'https://iwbftcnzcuhdapjxrlhe.supabase.co',
    anonKey: 'sb_publishable_kKNvrSZqF98IAPkKGW_fdg_GqttByHO',
  );

  // Start background auto-processing
  final detectionManager = DetectionManager();
  detectionManager.startPolling(const Duration(seconds: 10));

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          ThemeProvider()..toggleTheme(savedTheme == ThemeMode.dark),
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

// -------------------------------------------------------------
// DASHBOARD PAGE (MODERNIZED)
// -------------------------------------------------------------
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<NormalizedDetection> currentDetections = [];
  String geminiText = "Waiting for AI analysis...";
  String? lastDiseaseLabel;

  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();

    _detectionTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => fetchDetections(),
    );
  }

  Future<void> fetchDetections() async {
    final data = await DetectionService.fetchDetections();
    setState(() => currentDetections = data);

    if (data.isNotEmpty && data.first.label != lastDiseaseLabel) {
      lastDiseaseLabel = data.first.label;
      final ai = await GeminiService.generateGeminiRecommendation(data.first);

      setState(() => geminiText = ai);
    }
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
    
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CAMERA STREAM CARD (Modern)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 280,
                              width: double.infinity,
                              child: MJPEGStream(
                                url: "http://192.168.8.6:5000/video_feed",
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.circle,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "LIVE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // DETECTIONS SECTION
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Detections",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,

                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: currentDetections.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No detections yet",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: currentDetections.map((d) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade50,
                                          Colors.green.shade100,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.local_florist,
                                            color: Colors.green.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            d.label,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.onSurface,

                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.green.shade400,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // AI RECOMMENDATIONS SECTION
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "AI Recommendations",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,

                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade50,
                            Colors.yellow.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb,
                                    color: Colors.orange.shade600,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "AI Insight",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              geminiText,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,

                              ),
                            ),
                          ],
                        ),
                      ),
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

// -------------------------------------------------------------
// MJPEG STREAM WIDGET
// -------------------------------------------------------------
class MJPEGStream extends StatefulWidget {
  final String url;
  const MJPEGStream({super.key, required this.url});

  @override
  State<MJPEGStream> createState() => _MJPEGStreamState();
}

class _MJPEGStreamState extends State<MJPEGStream> {
  Uint8List? _currentFrame;
  StreamSubscription<List<int>>? _subscription;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  void _startStream() async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.url));
      final response = await client.send(request);

      List<int> buffer = [];

      _subscription = response.stream.listen((chunk) {
        buffer.addAll(chunk);

        while (true) {
          int start = buffer.indexOf(0xFF);
          if (start != -1 &&
              start + 1 < buffer.length &&
              buffer[start + 1] == 0xD8) {
            int end = buffer.indexOf(0xFF, start + 2);
            while (end != -1 && end + 1 < buffer.length) {
              if (buffer[end + 1] == 0xD9) {
                try {
                  _currentFrame = Uint8List.fromList(
                    buffer.sublist(start, end + 2),
                  );
                  if (mounted) setState(() {});
                } catch (_) {}
                buffer = buffer.sublist(end + 2);
                break;
              } else {
                end = buffer.indexOf(0xFF, end + 1);
              }
            }
            break;
          } else {
            break;
          }
        }
      });
    } catch (e) {
      print("MJPEG error: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _currentFrame == null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  "Connecting to camera...",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        : Image.memory(
            _currentFrame!,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          );
  }
}



