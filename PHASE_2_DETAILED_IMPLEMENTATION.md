# 📱 PHASE 2-5 IMPLEMENTATION ROADMAP

## Quick Navigation
- [Phase 2: Farmer Features (20-25 hours)](#phase-2-farmer-features)
- [Phase 3: Advanced AI (25-30 hours)](#phase-3-advanced-ai)
- [Phase 4: Scaling & B2B (20-25 hours)](#phase-4-scaling--b2b)
- [Phase 5: IoT Integration (30-40 hours)](#phase-5-iot-integration)

---

## PHASE 2: FARMER FEATURES

### ⏱️ Timeline: Weeks 3-4
### 💾 Effort: 20-25 hours
### 🎯 Goal: Add practical features farmers actually need

---

## Feature 1️⃣: PUSH NOTIFICATIONS

### Why This Feature?
- **Problem**: Farmers might miss critical alerts
- **Solution**: Send push notifications for disease detection
- **Value**: Farmers get immediate alerts even when app is closed
- **Time**: 4 hours
- **FYP Value**: ⭐⭐⭐ Shows user engagement

### Implementation (Firebase Cloud Messaging)

**Step 1: Add dependencies to pubspec.yaml**

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0
  flutter_local_notifications: ^16.1.0
```

**Step 2: Create notification service**

File: `lib/services/notification_service.dart`

```dart
// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    _firebaseMessaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      cardinality: AndroidNotificationChannelImportance.high,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Get device token for sending notifications
    final token = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $token');
    await _saveFCMToken(token ?? '');

    print('✅ Notification service initialized');
  }

  /// Handle notifications when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground notification: ${message.notification?.title}');

    _showLocalNotification(
      title: message.notification?.title ?? 'AgriSense Alert',
      body: message.notification?.body ?? 'New detection',
      payload: message.data['detection_id'] ?? '',
    );
  }

  /// Handle notifications when app is closed/background
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Background notification: ${message.notification?.title}');
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'disease_alerts',
      'Disease Alerts',
      channelDescription: 'Notifications for detected plant diseases',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  /// Send disease alert notification
  Future<void> sendDiseaseAlert({
    required String diseaseName,
    required double confidence,
    required String recommendation,
  }) async {
    // This would be called from your backend
    // Firebase Cloud Functions would handle the actual delivery

    await _showLocalNotification(
      title: '🚨 Disease Detected!',
      body: '$diseaseName detected (${(confidence * 100).toStringAsFixed(0)}%)',
      payload: diseaseName,
    );

    print('📢 Disease alert sent: $diseaseName');
  }

  /// Save FCM token to Supabase for future notifications
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Get saved FCM token
  Future<String?> getFCMToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
```

**Step 3: Use in DetectionManager**

```dart
// In lib/services/detection_manager.dart

class DetectionManager {
  final NotificationService _notifications = NotificationService();

  Future<void> _pollOnce() async {
    // ... existing code ...

    // After generating recommendation:
    if (detection.confidence >= 0.7) {
      // High confidence disease detection - send alert
      await _notifications.sendDiseaseAlert(
        diseaseName: detection.label,
        confidence: detection.confidence,
        recommendation: solution,
      );
    }
  }
}
```

---

## Feature 2️⃣: DATA EXPORT (CSV & PDF)

### Why This Feature?
- **Problem**: Farmers can't share or backup their data
- **Solution**: Export detection history as CSV or PDF
- **Value**: Farmers can share with consultants or for record-keeping
- **Time**: 4 hours
- **FYP Value**: ⭐⭐⭐ Shows data management capability

### Implementation

**Step 1: Add dependencies**

```yaml
dependencies:
  csv: ^6.0.0
  pdf: ^3.10.0
  path_provider: ^2.1.1
  share_plus: ^7.2.0
```

**Step 2: Create export service**

File: `lib/services/export_service.dart`

```dart
// lib/services/export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/supabase_service.dart';

class ExportService {
  static final SupabaseService _supabase = SupabaseService();

  /// Export detections as CSV
  static Future<bool> exportToCSV() async {
    try {
      print('📤 Exporting to CSV...');

      // Get all detections
      final detections = await _supabase.getDetectionHistory();
      if (detections.isEmpty) {
        print('❌ No data to export');
        return false;
      }

      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        ['Date', 'Disease', 'Confidence', 'Recommendation'],
        ...detections.map((d) => [
          d['timestamp'] ?? 'N/A',
          d['label'] ?? 'Unknown',
          '${((d['confidence'] as num).toDouble() * 100).toStringAsFixed(1)}%',
          d['solution'] ?? 'No recommendation',
        ]),
      ];

      // Convert to CSV
      final csv = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filename =
          'agrisense_detections_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv);

      print('✅ CSV exported: ${file.path}');

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AgriSense Detection Report',
      );

      return true;
    } catch (e) {
      print('❌ CSV export error: $e');
      return false;
    }
  }

  /// Export detections as PDF
  static Future<bool> exportToPDF() async {
    try {
      print('📤 Exporting to PDF...');

      // Get all detections
      final detections = await _supabase.getDetectionHistory();
      if (detections.isEmpty) {
        print('❌ No data to export');
        return false;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add title page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'AgriSense Detection Report',
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Generated: ${DateTime.now().toString()}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total Detections: ${detections.length}',
                style: const pw.TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Add detections table
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            children: [
              pw.Text(
                'Detection History',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Disease',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Confidence',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...detections.take(50).map((d) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(d['timestamp'] ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(d['label'] ?? 'Unknown'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${((d['confidence'] as num).toDouble() * 100).toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      );

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filename =
          'agrisense_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF exported: ${file.path}');

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AgriSense Detection Report',
      );

      return true;
    } catch (e) {
      print('❌ PDF export error: $e');
      return false;
    }
  }

  /// Export as JSON (for data portability)
  static Future<bool> exportToJSON() async {
    try {
      print('📤 Exporting to JSON...');

      final detections = await _supabase.getDetectionHistory();
      if (detections.isEmpty) {
        print('❌ No data to export');
        return false;
      }

      final jsonContent = {
        'exported_at': DateTime.now().toIso8601String(),
        'detection_count': detections.length,
        'detections': detections,
      };

      final directory = await getApplicationDocumentsDirectory();
      final filename =
          'agrisense_data_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$filename');
      await file.writeAsString(jsonEncode(jsonContent));

      print('✅ JSON exported: ${file.path}');

      await Share.shareXFiles([XFile(file.path)]);
      return true;
    } catch (e) {
      print('❌ JSON export error: $e');
      return false;
    }
  }
}
```

**Step 3: Add export buttons to History Page**

```dart
// In lib/history_page.dart, add to app bar:

actions: [
  PopupMenuButton<String>(
    onSelected: (value) {
      if (value == 'csv') {
        ExportService.exportToCSV();
      } else if (value == 'pdf') {
        ExportService.exportToPDF();
      } else if (value == 'json') {
        ExportService.exportToJSON();
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'csv', child: Text('Export as CSV')),
      const PopupMenuItem(value: 'pdf', child: Text('Export as PDF')),
      const PopupMenuItem(value: 'json', child: Text('Export as JSON')),
    ],
    child: const Icon(Icons.download),
  ),
],
```

---

## Feature 3️⃣: STATISTICS DASHBOARD

### Why This Feature?
- **Problem**: Farmers can't see trends or patterns
- **Solution**: Add charts showing disease frequency, confidence trends, etc.
- **Value**: Farmers can plan better based on historical data
- **Time**: 8 hours
- **FYP Value**: ⭐⭐⭐⭐ Data visualization + analytics

### Implementation

**Step 1: Add dependencies**

```yaml
dependencies:
  fl_chart: ^0.65.0
  intl: ^0.19.0
```

**Step 2: Create statistics service**

File: `lib/services/statistics_service.dart`

```dart
// lib/services/statistics_service.dart
import '../services/supabase_service.dart';

class StatisticsService {
  static final SupabaseService _supabase = SupabaseService();

  /// Get disease frequency (top diseases detected)
  static Future<Map<String, int>> getDiseaseFrequency() async {
    final detections = await _supabase.getDetectionHistory();
    final frequency = <String, int>{};

    for (var d in detections) {
      final label = (d['label'] ?? 'Unknown') as String;
      frequency[label] = (frequency[label] ?? 0) + 1;
    }

    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get average confidence by disease
  static Future<Map<String, double>> getAverageConfidence() async {
    final detections = await _supabase.getDetectionHistory();
    final byDisease = <String, List<double>>{};

    for (var d in detections) {
      final label = (d['label'] ?? 'Unknown') as String;
      final confidence = (d['confidence'] as num).toDouble();
      byDisease.putIfAbsent(label, () => []).add(confidence);
    }

    final averages = <String, double>{};
    for (var entry in byDisease.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      averages[entry.key] = avg;
    }

    return averages;
  }

  /// Get daily detection count (last 30 days)
  static Future<Map<String, int>> getDailyDetections() async {
    final detections = await _supabase.getDetectionHistory();
    final daily = <String, int>{};

    for (var d in detections) {
      try {
        final timestamp = d['timestamp'] as String;
        final date = DateTime.parse(timestamp);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        daily[dateKey] = (daily[dateKey] ?? 0) + 1;
      } catch (e) {
        print('Error parsing timestamp: $e');
      }
    }

    return SplayTreeMap.from(daily);
  }

  /// Get health score (0-100)
  /// Based on: No diseases = 100, diseases with low confidence increase score
  static Future<int> getHealthScore() async {
    final detections = await _supabase.getDetectionHistory();
    if (detections.isEmpty) return 100; // Perfect health if no detections

    // Calculate weighted score based on diseases and their confidence
    int score = 100;
    for (var d in detections) {
      final confidence = (d['confidence'] as num).toDouble();
      final label = (d['label'] ?? '').toString().toLowerCase();

      // Only count actual diseases, not "healthy" labels
      if (!label.contains('healthy') && !label.contains('normal')) {
        // Reduce score by (confidence * 20), max -20 per disease
        score -= (confidence * 20).toInt();
      }
    }

    return score.clamp(0, 100);
  }

  /// Get summary statistics
  static Future<Map<String, dynamic>> getSummary() async {
    final detections = await _supabase.getDetectionHistory();
    final frequency = await getDiseaseFrequency();
    final healthScore = await getHealthScore();

    return {
      'totalDetections': detections.length,
      'topDisease': frequency.isNotEmpty ? frequency.entries.first.key : 'None',
      'healthScore': healthScore,
      'uniqueDiseases': frequency.length,
      'lastDetection': detections.isNotEmpty
          ? detections.first['timestamp']
          : 'Never',
    };
  }
}
```

**Step 3: Create Statistics Page**

File: `lib/pages/statistics_page.dart`

```dart
// lib/pages/statistics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';
import '../widgets/app_bar.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(
        title: "Statistics",
        subtitle: "Monitor your farm health",
        icon: Icons.analytics,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Score Card
          FutureBuilder<int>(
            future: StatisticsService.getHealthScore(),
            builder: (context, snapshot) {
              final healthScore = snapshot.data ?? 0;
              return _buildHealthScoreCard(healthScore);
            },
          ),
          const SizedBox(height: 24),

          // Summary Stats
          FutureBuilder<Map<String, dynamic>>(
            future: StatisticsService.getSummary(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final summary = snapshot.data!;
              return _buildSummaryStats(summary);
            },
          ),
          const SizedBox(height: 24),

          // Disease Frequency Chart
          FutureBuilder<Map<String, int>>(
            future: StatisticsService.getDiseaseFrequency(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No data yet'),
                );
              }
              return _buildDiseaseChart(snapshot.data!);
            },
          ),
          const SizedBox(height: 24),

          // Confidence Trend
          FutureBuilder<Map<String, double>>(
            future: StatisticsService.getAverageConfidence(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildConfidenceChart(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(int score) {
    Color scoreColor;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.deepOrange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Farm Health Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$score/100',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scoreLabel,
              style: TextStyle(fontSize: 18, color: scoreColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              'Total Detections',
              summary['totalDetections'].toString(),
              Icons.bug_report,
            ),
            const Divider(),
            _buildStatRow(
              'Top Disease',
              summary['topDisease'].toString(),
              Icons.local_florist,
            ),
            const Divider(),
            _buildStatRow(
              'Unique Diseases',
              summary['uniqueDiseases'].toString(),
              Icons.category,
            ),
            const Divider(),
            _buildStatRow(
              'Last Detection',
              _formatTime(summary['lastDetection']),
              Icons.schedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseChart(Map<String, int> diseases) {
    final entries = diseases.entries.take(5).toList();
    final maxValue = entries.isNotEmpty ? entries.first.value.toDouble() : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disease Frequency',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    entries.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entries[index].value.toDouble(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  maxY: maxValue + 2,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            entries[value.toInt()].key.substring(0, 3),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceChart(Map<String, double> confidences) {
    final entries = confidences.entries.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average Detection Confidence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(
                    entries.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entries[index].value,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  maxY: 1.0,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            entries[value.toInt()].key.substring(0, 3),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp == 'Never') return 'Never';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return timestamp.toString();
    }
  }
}
```

**Step 4: Add Statistics tab to main navigation**

```dart
// In lib/main.dart, update MainWrapper:

final List<Widget> _pages = [
  DashboardPage(),
  StatisticsPage(),      // ADD THIS
  HistoryPage(),
  SettingsPage(),
];

// Update navigation destinations
const [
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: "Dashboard",
  ),
  NavigationDestination(
    icon: Icon(Icons.analytics_outlined),
    selectedIcon: Icon(Icons.analytics),
    label: "Analytics",
  ),
  // ...rest
]
```

---

## Feature 4️⃣: IMAGE GALLERY WITH TIMELINE

### Why This Feature?
- **Problem**: Farmers can't track their detection history with images
- **Solution**: Gallery showing all detected images with timestamps
- **Value**: Visual proof of disease progression
- **Time**: 5 hours
- **FYP Value**: ⭐⭐⭐ Multimedia handling

### Implementation

**Step 1: Add dependencies**

```yaml
dependencies:
  image_picker: ^1.0.0
  image_gallery_saver: ^2.0.0
  cached_network_image: ^3.3.0
```

**Step 2: Create image service**

File: `lib/services/image_service.dart`

```dart
// lib/services/image_service.dart
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Pick image from camera or gallery
  static Future<XFile?> pickImage({
    required ImageSource source,
  }) async {
    try {
      final image = await _picker.pickImage(source: source);
      return image;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Upload image to Supabase storage
  static Future<String?> uploadImage({
    required XFile imageFile,
    required String detectionId,
  }) async {
    try {
      print('📤 Uploading image...');

      final bytes = await imageFile.readAsBytes();
      final path = 'detections/$detectionId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('agrisense-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600'),
      );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('agrisense-images')
          .getPublicUrl(path);

      print('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  /// Get all images for a detection
  static Future<List<String>> getDetectionImages(String detectionId) async {
    try {
      final files = await _supabase.storage
          .from('agrisense-images')
          .list(path: 'detections/$detectionId');

      final urls = <String>[];
      for (var file in files) {
        final url = _supabase.storage
            .from('agrisense-images')
            .getPublicUrl('detections/$detectionId/${file.name}');
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print('❌ Error getting images: $e');
      return [];
    }
  }
}
```

**Step 3: Create gallery page**

File: `lib/pages/gallery_page.dart`

```dart
// lib/pages/gallery_page.dart (simplified)
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, dynamic>>> _detectionsFuture;

  @override
  void initState() {
    super.initState();
    _detectionsFuture = SupabaseService().getDetectionHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Gallery'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _detectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No detections yet'));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final detection = snapshot.data![index];
              return _buildDetectionCard(detection);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for image (would show actual image if uploaded)
          Expanded(
            child: Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detection['label'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${((detection['confidence'] as num).toDouble() * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## PHASE 2 SUMMARY

After Phase 2, you'll have:

✅ **Push Notifications**
- Disease alerts in real-time
- Firebase Cloud Messaging integration
- Local notification handling

✅ **Data Export**
- CSV export for spreadsheet analysis
- PDF export for sharing with consultants
- JSON export for data backup

✅ **Statistics & Analytics**
- Health score calculation
- Disease frequency charts
- Confidence trends
- Historical patterns

✅ **Image Gallery**
- Visual detection history
- Timeline view
- Image storage in Supabase

---

## PHASE 2 CHECKLIST

- [ ] Add Firebase dependencies to pubspec.yaml
- [ ] Create notification service
- [ ] Test push notifications on real device
- [ ] Add export service (CSV/PDF/JSON)
- [ ] Add export buttons to UI
- [ ] Create statistics service
- [ ] Create statistics page with charts
- [ ] Create image service
- [ ] Create gallery page
- [ ] Add gallery to navigation
- [ ] Test all features end-to-end
- [ ] Gather user feedback

---

### Estimated Time: 20-25 hours (2-3 days)

---

## PHASE 3 PREVIEW: Advanced AI Features

Phase 3 includes:
1. **Disease Prediction Model** - Predict disease before it appears
2. **Weather Integration** - Correlate disease with weather patterns
3. **Confidence Explanations** - Show why model thinks it's a disease
4. **Treatment Recommendations** - Specific product/dosage recommendations
5. **Disease Lifecycle Tracking** - Monitor disease progression over time

See separate Phase 3-5 implementation guide for detailed code.

---

END OF PHASE 2 GUIDE
