# 🚀 Quick Feature Implementation Guides

## Table of Contents
1. [Input Validation Service](#1-input-validation-service) - Start here! ⭐
2. [Error Recovery with Retry Logic](#2-error-recovery-with-retry-logic) - Critical fix
3. [Data Export Service](#3-data-export-service) - User-requested feature
4. [Push Notifications](#4-push-notifications) - High engagement feature

---

## 1. Input Validation Service

**File:** `lib/services/validation_service.dart`  
**Time:** 30 minutes

This service prevents invalid data from entering your system.

```dart
// lib/services/validation_service.dart

class ValidationService {
  /// Validate confidence score (0.0 to 1.0)
  static bool isValidConfidence(double value) {
    return value >= 0.0 && value <= 1.0;
  }

  /// Validate disease label
  static bool isValidLabel(String label) {
    if (label.isEmpty) return false;
    if (label.length > 100) return false;
    // Check for invalid characters
    return RegExp(r'^[a-zA-Z0-9\s\-_()]+$').hasMatch(label);
  }

  /// Validate URL format
  static bool isValidServerURL(String url) {
    try {
      Uri.parse(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate API key format
  static bool isValidAPIKey(String key) {
    return key.isNotEmpty && key.length > 10;
  }

  /// Validate timestamp
  static bool isValidTimestamp(String timestamp) {
    try {
      DateTime.parse(timestamp);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate HTTP status code
  static bool isSuccessful(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  /// Validate response body is not empty
  static bool isValidResponse(dynamic response) {
    if (response == null) return false;
    if (response is String && response.isEmpty) return false;
    return true;
  }
}
```

### Usage Example:

```dart
// In detection_service.dart, update fetchDetections:
static Future<List<NormalizedDetection>> fetchDetections() async {
  try {
    final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
    
    // ✨ NEW: Validate server URL
    if (!ValidationService.isValidServerURL(serverUrl)) {
      print('❌ Invalid server URL: $serverUrl');
      return [];
    }
    
    final response = await http.get(
      Uri.parse("$serverUrl/latest_detection"),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded["status"] == "no_data") {
        return [];
      }

      final label = decoded["label"] ?? "Unknown";
      final confidence = decoded["confidence"]?.toDouble() ?? 0.0;

      // ✨ NEW: Validate detection data
      if (!ValidationService.isValidLabel(label)) {
        print('❌ Invalid label: $label');
        return [];
      }

      if (!ValidationService.isValidConfidence(confidence)) {
        print('❌ Invalid confidence: $confidence');
        return [];
      }

      final detection = NormalizedDetection(
        label: label,
        confidence: confidence,
        time: decoded["timestamp"] ?? "",
      );

      return [detection];
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print("❌ Fetch Error: $e");
    return [];
  }
}
```

---

## 2. Error Recovery with Retry Logic

**File:** `lib/services/http_service.dart` (NEW)  
**Time:** 1 hour

This prevents your app from failing due to temporary network issues.

```dart
// lib/services/http_service.dart

import 'package:http/http.dart' as http;

class HttpService {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);

  /// GET request with automatic retry on failure
  static Future<http.Response> getWithRetry(
    Uri url, {
    int retries = maxRetries,
    Duration delay = baseDelay,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('📡 GET request (attempt $attempt/$retries): $url');
        
        final response = await http
            .get(url)
            .timeout(timeout, onTimeout: () {
          throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
        });

        if (response.statusCode == 200) {
          print('✅ Success on attempt $attempt');
          return response;
        }

        // Retry on server errors (5xx) or rate limit (429)
        if (response.statusCode >= 500 || response.statusCode == 429) {
          print('⚠️ Server error (${response.statusCode}), retrying...');
          if (attempt < retries) {
            await Future.delayed(delay * attempt); // Exponential backoff
          }
          continue;
        }

        // Don't retry on client errors (4xx except 429)
        print('❌ Client error (${response.statusCode}), not retrying');
        return response;
      } on TimeoutException catch (e) {
        print('⏱️ Timeout on attempt $attempt: $e');
        if (attempt == retries) rethrow;
        if (attempt < retries) {
          await Future.delayed(delay * attempt);
        }
      } catch (e) {
        print('❌ Error on attempt $attempt: $e');
        if (attempt == retries) rethrow;
        if (attempt < retries) {
          await Future.delayed(delay * attempt);
        }
      }
    }

    throw Exception('Failed after $retries attempts');
  }

  /// POST request with automatic retry on failure
  static Future<http.Response> postWithRetry(
    Uri url, {
    required String body,
    Map<String, String>? headers,
    int retries = maxRetries,
    Duration delay = baseDelay,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('📡 POST request (attempt $attempt/$retries): $url');
        
        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(timeout, onTimeout: () {
          throw TimeoutException('Request timeout after ${timeout.inSeconds}s');
        });

        if (response.statusCode == 200) {
          print('✅ Success on attempt $attempt');
          return response;
        }

        // Retry on server errors (5xx) or rate limit (429)
        if (response.statusCode >= 500 || response.statusCode == 429) {
          print('⚠️ Server error (${response.statusCode}), retrying...');
          if (attempt < retries) {
            await Future.delayed(delay * attempt); // Exponential backoff
          }
          continue;
        }

        print('❌ Client error (${response.statusCode}), not retrying');
        return response;
      } on TimeoutException catch (e) {
        print('⏱️ Timeout on attempt $attempt: $e');
        if (attempt == retries) rethrow;
        if (attempt < retries) {
          await Future.delayed(delay * attempt);
        }
      } catch (e) {
        print('❌ Error on attempt $attempt: $e');
        if (attempt == retries) rethrow;
        if (attempt < retries) {
          await Future.delayed(delay * attempt);
        }
      }
    }

    throw Exception('Failed after $retries attempts');
  }
}

// TimeoutException
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
```

### Usage in Detection Service:

```dart
// Update detection_service.dart to use HttpService
import 'services/http_service.dart';

static Future<List<NormalizedDetection>> fetchDetections() async {
  try {
    final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
    
    // ✨ Use HttpService with automatic retry
    final response = await HttpService.getWithRetry(
      Uri.parse("$serverUrl/latest_detection"),
      retries: 3,
      timeout: const Duration(seconds: 15),
    );

    // ... rest of the code
  } catch (e) {
    print("❌ Fetch Error: $e");
    return [];
  }
}
```

---

## 3. Data Export Service

**File:** `lib/services/export_service.dart`  
**Time:** 2 hours  
**Dependencies:** Add to `pubspec.yaml`:
```yaml
csv: ^5.1.0
intl: ^0.19.0
path_provider: ^2.1.0
share_plus: ^7.0.0
```

This lets users download their detection history.

```dart
// lib/services/export_service.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// Export detections as CSV file
  static Future<String> exportAsCSV(List<Map<String, dynamic>> detections) async {
    try {
      // Build CSV data
      List<List<String>> csvData = [
        // Header
        ['ID', 'Disease', 'Confidence (%)', 'Solution', 'Date/Time'],
      ];

      // Add detection rows
      for (var detection in detections) {
        csvData.add([
          detection['id'].toString(),
          detection['label'] ?? 'Unknown',
          ((detection['confidence'] ?? 0.0) * 100).toStringAsFixed(1),
          detection['solution'] ?? 'N/A',
          _formatDate(detection['timestamp']),
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Save to file
      final fileName = 'agrisense_detections_${_getTimestamp()}.csv';
      final file = await _saveFile(fileName, csv);

      print('✅ CSV exported: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ CSV export error: $e');
      return '';
    }
  }

  /// Export detections as JSON file
  static Future<String> exportAsJSON(List<Map<String, dynamic>> detections) async {
    try {
      final jsonData = {
        'exported_at': DateTime.now().toIso8601String(),
        'total_detections': detections.length,
        'detections': detections,
      };

      final jsonString = _prettyPrintJson(jsonData);
      final fileName = 'agrisense_detections_${_getTimestamp()}.json';
      final file = await _saveFile(fileName, jsonString);

      print('✅ JSON exported: ${file.path}');
      return file.path;
    } catch (e) {
      print('❌ JSON export error: $e');
      return '';
    }
  }

  /// Share exported file
  static Future<void> shareFile(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'AgriSense Detection History - $fileName',
      );

      print('✅ File shared');
    } catch (e) {
      print('❌ Share error: $e');
    }
  }

  /// Private helper: Save file to documents directory
  static Future<File> _saveFile(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    return await file.writeAsString(content);
  }

  /// Private helper: Format timestamp
  static String _formatDate(dynamic timestamp) {
    try {
      final dt = DateTime.parse(timestamp.toString());
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (e) {
      return timestamp.toString();
    }
  }

  /// Private helper: Get current timestamp for filename
  static String _getTimestamp() {
    return DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
  }

  /// Private helper: Pretty print JSON
  static String _prettyPrintJson(Map<String, dynamic> data) {
    return JsonEncoder.withIndent('  ').convert(data);
  }
}

// Import for JSON
import 'dart:convert';

// Export button example for HistoryPage:
/*
FloatingActionButton(
  onPressed: () async {
    final detections = await supabaseService.getDetectionHistory();
    final filePath = await ExportService.exportAsCSV(detections);
    if (filePath.isNotEmpty) {
      await ExportService.shareFile(filePath);
    }
  },
  child: const Icon(Icons.download),
)
*/
```

---

## 4. Push Notifications

**File:** `lib/services/notification_service.dart`  
**Time:** 2-3 hours  
**Dependencies:** Add to `pubspec.yaml`:
```yaml
firebase_messaging: ^14.0.0
firebase_core: ^2.0.0
```

This alerts users to important disease detections.

```dart
// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request notification permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ Notification permission denied');
        return;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      print('✅ FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (must be static)
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification tap
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      _isInitialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Notification init error: $e');
    }
  }

  /// Send local notification when disease detected
  static Future<void> notifyDiseaseDetected({
    required String diseaseName,
    required double confidence,
  }) async {
    final title = 'Disease Detected! 🚨';
    final body = '$diseaseName detected with ${(confidence * 100).toStringAsFixed(0)}% confidence';

    // Show in-app notification
    print('📢 $title\n$body');

    // In production, integrate with local_notifications package:
    // await _flutterLocalNotificationsPlugin.show(
    //   diseaseName.hashCode,
    //   title,
    //   body,
    //   notificationDetails,
    // );
  }

  /// Handle foreground message
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground message: ${message.notification?.title}');
    print('   Body: ${message.notification?.body}');

    // Update UI or trigger action
    // Example: Show snackbar or update dashboard
  }

  /// Handle background message (must be static)
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📬 Background message: ${message.notification?.title}');
    // Handle in background (e.g., update database, log analytics)
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');
    // Navigate to relevant page (e.g., History page)
  }

  /// Get FCM token (for sending notifications)
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
```

### Integration in Main App:

```dart
// In main.dart, update main():
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing code ...

  // Initialize notifications
  await NotificationService().initialize();

  runApp(...);
}

// In detection_manager.dart, notify when disease detected:
Future<void> _pollOnce() async {
  // ... existing code ...

  if (detection.confidence > 0.01) {
    // ✨ Send notification
    if (detection.confidence > 0.7) {
      await NotificationService.notifyDiseaseDetected(
        diseaseName: detection.label,
        confidence: detection.confidence,
      );
    }

    // ... rest of the code ...
  }
}
```

---

## Summary: What to Implement First

**Week 1:**
1. ✅ Validation Service (30 min)
2. ✅ Error Recovery Service (1 hour)
3. ✅ Add error handling to all API calls (1 hour)

**Week 2:**
4. ✅ Data Export Service (2 hours)
5. ✅ Push Notifications (2-3 hours)

**Week 3+:**
6. Statistics Dashboard
7. Offline Caching
8. Multi-farm support

These implementations will make your app **more reliable, user-friendly, and professional**.

---

**Questions?** Check the implementation guides above or review the complete feature roadmap in `PROJECT_COMPLETE_STATUS_AND_ROADMAP.md`
