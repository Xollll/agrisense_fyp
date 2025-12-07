import 'dart:async';
import 'dart:typed_data';
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
  String geminiText = "";
  String? lastDiseaseLabel;
  bool _isLoadingAI = false;
  
  // Persist last detection even after it's gone
  NormalizedDetection? _lastDetectionPersistent;
  bool _isCurrentlyDetected = false;  // Track if disease is currently active

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
    
    setState(() {
      currentDetections = data;
      
      // Update persistent detection tracking
      if (data.isNotEmpty) {
        final newDetection = data.first;
        
        // If this is a NEW disease (different from persistent), clear old AI text
        if (_lastDetectionPersistent != null && 
            _lastDetectionPersistent!.label != newDetection.label) {
          geminiText = "";  // Clear old disease's AI tips
        }
        
        // Disease currently detected
        _lastDetectionPersistent = newDetection;
        _isCurrentlyDetected = true;
      } else {
        // No current detection
        _isCurrentlyDetected = false;
        // If no disease was ever detected, clear everything
        if (_lastDetectionPersistent == null) {
          geminiText = "";
        }
        // If disease disappears but we had one before, keep geminiText for resolved disease
        // Don't clear _lastDetectionPersistent - let user see resolved disease
      }
    });
    
    // Auto-trigger recommendation if diseases changed significantly
    // The hybrid system will:
    // 1. Check if disease/confidence changed
    // 2. If yes: generate new recommendation (cache miss)
    // 3. If no: use cached recommendation (cache hit)
    // 4. Update UI silently
    _autoRequestAIRecommendation();
  }
  
  // User manually requested a fresh recommendation (force refresh)
  Future<void> _requestAIRecommendation() async {
    if (_lastDetectionPersistent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No disease detected. Healthy plant!")),
      );
      return;
    }

    // Use ALL current detections (or persistent if none current)
    final detectionsToAnalyze = currentDetections.isNotEmpty
        ? currentDetections
        : [_lastDetectionPersistent!];

    setState(() => _isLoadingAI = true);

    try {
      // User triggered request = FORCE REFRESH (ignore cache)
      // The hybrid system in GeminiService will:
      // 1. Build smart cache key (includes disease names + rounded confidence)
      // 2. Detect if anything changed significantly
      // 3. If forceRefresh=true, always generate fresh
      // 4. If unchanged and cached, use cache (but user explicitly requested, so refresh)
      final ai = await GeminiService.generateMultipleRecommendation(
          detectionsToAnalyze,
          forceRefresh: true); // User explicitly asked for tips
      
      setState(() {
        geminiText = ai;
        _isLoadingAI = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✓ Recommendation updated")),
      );
    } catch (e) {
      setState(() => _isLoadingAI = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error getting AI recommendation: $e")),
        );
      }
    }
  }

  // Auto-recommendation triggered by detection changes
  // This is called automatically by the detection loop
  // The hybrid system will auto-generate only if disease/confidence changed
  Future<void> _autoRequestAIRecommendation() async {
    if (_lastDetectionPersistent == null) {
      // No disease, skip
      return;
    }

    final detectionsToAnalyze = currentDetections.isNotEmpty
        ? currentDetections
        : [_lastDetectionPersistent!];

    try {
      // Auto-triggered = let hybrid system decide (don't force refresh)
      // The system will:
      // 1. Check if disease/confidence changed significantly
      // 2. If yes: generate new recommendation
      // 3. If no: reuse cached recommendation
      // 4. Either way, update UI without loading spinner
      final ai = await GeminiService.generateMultipleRecommendation(
          detectionsToAnalyze,
          forceRefresh: false); // Auto-triggered, respect cache
      
      // Silently update recommendation if it changed
      if (ai != geminiText) {
        setState(() {
          geminiText = ai;
        });
        print("✓ Auto-recommendation updated: disease/confidence changed");
      }
    } catch (e) {
      print("Auto-recommendation failed: $e");
      // Don't show error to user for auto-requests
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
                                  // Filter out "healthy" detections
                                  if (d.label.toLowerCase() == "healthy") {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade50,
                                          Colors.orange.shade100,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
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
                                            Icons.error_outline,
                                            color: Colors.orange.shade700,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                d.label,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${(d.confidence * 100).toStringAsFixed(0)}% confidence",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.orange.shade400,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Show different content based on detection state
                    if (_lastDetectionPersistent == null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.1),
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
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Plant Status",
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
                                "✅ Your plant looks healthy! No disease detected. Keep up the good care!",
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // AI RECOMMENDATIONS SECTION (Only show when disease detected)
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Get AI Tips",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            // Show count of diseases detected
                                            currentDetections.isEmpty
                                                ? _lastDetectionPersistent!.label
                                                : "${currentDetections.length} issue${currentDetections.length > 1 ? 's' : ''} found",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isCurrentlyDetected
                                          ? Colors.red.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isCurrentlyDetected
                                            ? Colors.red.shade400
                                            : Colors.grey.shade400,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _isCurrentlyDetected ? "🔴 Active" : "⏸️ Resolved",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _isCurrentlyDetected
                                            ? Colors.red.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Show AI recommendation if available
                              if (geminiText.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      geminiText,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              
                              // Show button to request AI recommendation
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoadingAI ? null : _requestAIRecommendation,
                                  icon: _isLoadingAI
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.orange.shade600,
                                            ),
                                          ),
                                        )
                                      : Icon(Icons.auto_awesome, color: Colors.orange.shade600),
                                  label: Text(
                                    _isLoadingAI ? 'Getting Tips...' : 'Ask AI for Tips',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              
                              if (geminiText.isEmpty && !_isLoadingAI)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    _isCurrentlyDetected
                                        ? "⚠️ Disease detected! Click the button to get AI-powered treatment recommendations."
                                        : "ℹ️ Disease was detected earlier. Click the button to review AI-powered recommendations.",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

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



