# Smart AI Recommendation System - Dashboard Integration Example

## Finding Your Dashboard File

Your dashboard is likely in one of these files:
- `lib/main.dart` (see `DashboardPage` class)
- `lib/pages/settings_page.dart`
- `lib/pages/statistics_page_redesigned.dart`
- A dedicated `lib/pages/dashboard.dart`

---

## Example 1: Simple Integration in main.dart

If you have a `DashboardPage` class in your main.dart:

```dart
import 'widgets/smart_ai_recommendation_widget.dart';
import 'detection_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  NormalizedDetection? _currentDetection;

  @override
  void initState() {
    super.initState();
    _loadLatestDetection();
  }

  Future<void> _loadLatestDetection() async {
    final detections = await DetectionService.fetchDetections();
    if (detections.isNotEmpty) {
      setState(() => _currentDetection = detections.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Detection Dashboard'),
      ),
      body: _currentDetection != null
          ? ListView(
              children: [
                // Existing detection display
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disease: ${_currentDetection!.label}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Confidence: ${(_currentDetection!.confidence * 100).toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),

                // ✨ ADD THIS: Smart AI Recommendation Widget
                SmartAIRecommendationWidget(
                  detection: _currentDetection!,
                  onRecommendationUpdated: () {
                    print('✅ Recommendation was updated');
                    // Optional: Refresh other UI elements
                    setState(() {});
                  },
                ),

                // Other existing widgets...
              ],
            )
          : const Center(
              child: Text('No detection available. Point camera at a leaf.'),
            ),
    );
  }
}
```

---

## Example 2: Advanced Integration with Real-time Updates

If you want the dashboard to show live updates from the detection manager:

```dart
import 'widgets/smart_ai_recommendation_widget.dart';
import 'detection_service.dart';
import 'services/detection_manager.dart';
import 'package:provider/provider.dart';

class AdvancedDashboardPage extends StatefulWidget {
  const AdvancedDashboardPage({super.key});

  @override
  State<AdvancedDashboardPage> createState() => _AdvancedDashboardPageState();
}

class _AdvancedDashboardPageState extends State<AdvancedDashboardPage> {
  NormalizedDetection? _currentDetection;
  final DetectionManager _manager = DetectionManager();
  late Stream<NormalizedDetection> _detectionStream;

  @override
  void initState() {
    super.initState();
    _setupDetectionStream();
  }

  void _setupDetectionStream() {
    // Create a periodic stream from your detection service
    _detectionStream = Stream.periodic(
      const Duration(seconds: 10),
      (_) => DetectionService.fetchDetections(),
    ).asyncExpand((future) => Stream.fromFuture(future))
        .where((detections) => detections.isNotEmpty)
        .map((detections) => detections.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Detection Dashboard'),
      ),
      body: StreamBuilder<NormalizedDetection>(
        stream: _detectionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No detection available'));
          }

          _currentDetection = snapshot.data!;

          return ListView(
            children: [
              // Detection status card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live Detection: ${_currentDetection!.label}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildConfidenceBar(
                        _currentDetection!.confidence,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(_currentDetection!.confidence * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // ✨ Smart AI Recommendation Widget with manual control
              SmartAIRecommendationWidget(
                detection: _currentDetection!,
                onRecommendationUpdated: () {
                  print('✅ Recommendation updated from AI');
                  // Refresh other parts of UI if needed
                  setState(() {});
                },
              ),

              // Additional info section
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How This Works',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• AI automatically generates recommendations for NEW diseases\n'
                        '• Same disease with different confidence? Uses cached recommendation (saves API quota)\n'
                        '• Want a fresh analysis? Click "Ask AI Again" above\n'
                        '• System respects 10-minute cooldown between automatic calls',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    final percentage = confidence * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence >= 0.7
                  ? Colors.green
                  : confidence >= 0.5
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## Example 3: Integration with Provider Pattern

If you're using the Provider pattern (which you are!):

```dart
import 'widgets/smart_ai_recommendation_widget.dart';
import 'detection_service.dart';
import 'package:provider/provider.dart';

class DashboardPageWithProvider extends StatelessWidget {
  const DashboardPageWithProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: FutureBuilder<List<NormalizedDetection>>(
        future: DetectionService.fetchDetections(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No detection'));
          }

          final detection = snapshot.data!.first;

          return ListView(
            children: [
              // Your existing widgets...

              // ✨ ADD: Smart AI Recommendation
              SmartAIRecommendationWidget(
                detection: detection,
                onRecommendationUpdated: () {
                  // Optionally trigger statistics update
                  Provider.of<StatisticsProvider>(context, listen: false)
                      .loadStatistics();
                },
              ),

              // More widgets...
            ],
          );
        },
      ),
    );
  }
}
```

---

## Example 4: Integration with Conditional Display

Show recommendation widget only when confidence is high enough:

```dart
SmartAIRecommendationWidget(
  detection: _currentDetection!,
  onRecommendationUpdated: () {
    setState(() {});
  },
),

// Only show debugging info in debug mode
if (kDebugMode) ...[
  Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Info',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text('Disease: ${_currentDetection!.label}'),
          Text('Confidence: ${(_currentDetection!.confidence * 100).toStringAsFixed(1)}%'),
          const Divider(),
          Text(
            'Cache Status',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          FutureBuilder<String?>(
            future: Future.value(
              AIRecommendationService.getCachedRecommendation(
                _currentDetection!.label,
              ),
            ),
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData ? 'Cached ✓' : 'Not cached',
                style: TextStyle(
                  color: snapshot.hasData ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
],
```

---

## Widget Customization

### Change Button Text

```dart
// Inside smart_ai_recommendation_widget.dart
ElevatedButton.icon(
  onPressed: _isLoading ? null : _manuallyRequestAI,
  icon: const Icon(Icons.refresh),
  label: const Text('Request Fresh Analysis'),  // Changed text
  // ... rest of code
)
```

### Change Colors

```dart
// Make the button match your app theme
style: ElevatedButton.styleFrom(
  backgroundColor: Theme.of(context).primaryColor,  // Use app primary color
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 12),
),
```

### Hide "Ask AI Again" Button

```dart
// Comment out the button code in smart_ai_recommendation_widget.dart
// ElevatedButton.icon(
//   onPressed: _isLoading ? null : _manuallyRequestAI,
//   ...
// ),
```

### Make Widget Dismissible

```dart
// Wrap the widget
DismissibleWidget(
  key: UniqueKey(),
  onDismissed: (_) {
    // Handle dismissal
  },
  child: SmartAIRecommendationWidget(
    detection: detection,
    onRecommendationUpdated: () {},
  ),
)
```

---

## Complete Working Example

Here's a complete, ready-to-copy dashboard implementation:

```dart
import 'package:flutter/material.dart';
import 'detection_service.dart';
import 'widgets/smart_ai_recommendation_widget.dart';

class CompleteDashboardExample extends StatefulWidget {
  const CompleteDashboardExample({super.key});

  @override
  State<CompleteDashboardExample> createState() =>
      _CompleteDashboardExampleState();
}

class _CompleteDashboardExampleState extends State<CompleteDashboardExample>
    with WidgetsBindingObserver {
  NormalizedDetection? _currentDetection;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetection();
    // Refresh every 10 seconds to match polling
    Future.delayed(const Duration(seconds: 10), _refreshIfMounted);
  }

  Future<void> _loadDetection() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final detections = await DetectionService.fetchDetections();
      if (mounted && detections.isNotEmpty) {
        setState(() {
          _currentDetection = detections.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _refreshIfMounted() {
    if (mounted) {
      _loadDetection();
      Future.delayed(const Duration(seconds: 10), _refreshIfMounted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriSense Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentDetection == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No detection yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point camera at a leaf to start detection',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    // Detection status
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Detection',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentDetection!.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confidence Level',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value:
                                          _currentDetection!.confidence,
                                      minHeight: 12,
                                      backgroundColor:
                                          Colors.grey[300],
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        _currentDetection!.confidence >=
                                                0.7
                                            ? Colors.green
                                            : _currentDetection!
                                                        .confidence >=
                                                    0.5
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_currentDetection!.confidence * 100).toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ✨ Smart AI Recommendation Widget
                    SmartAIRecommendationWidget(
                      detection: _currentDetection!,
                      onRecommendationUpdated: () {
                        print('Recommendation updated');
                      },
                    ),

                    // Info card
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 0,
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '💡 Smart AI Features',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• New diseases get AI analysis automatically\n'
                                '• Same disease = cached recommendation (no API waste)\n'
                                '• Manual "Ask AI Again" for fresh analysis\n'
                                '• 10-minute cooldown prevents rapid API calls',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
```

---

## Testing Your Integration

1. **Build and run** your app
2. **Point at a diseased leaf** - should see recommendation widget
3. **Click "Ask AI Again"** - should generate fresh recommendation
4. **Check console logs** - should see decision engine logs
5. **Wait 10 minutes** - should allow new auto-trigger for same disease

---

## Debugging Tips

If recommendation widget doesn't appear:

1. Check that `_currentDetection` is not null
2. Verify detection confidence >= 0.5
3. Check console for any errors in `AIRecommendationService`

If "Ask AI Again" button doesn't work:

1. Check internet connection
2. Verify `GEMINI_API_KEY` in .env file
3. Check console for API errors

---

**You're all set!** 🚀 The smart AI recommendation system is now integrated.
