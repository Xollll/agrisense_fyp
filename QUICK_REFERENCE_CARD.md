# 🎯 AgriSense Quick Reference Card

## API Endpoints Reference

### Detection Server (from `.env`)
```
Server: DETECTION_SERVER_URL = http://192.168.8.6:5000

GET /latest_detection
  Response: { "label": "Early Leaf Spot", "confidence": 0.85, "timestamp": "..." }

GET /video_feed
  Response: MJPEG stream (used in LiveStreamWidget)
```

### Gemini API (from `.env`)
```
Endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent
Key: GEMINI_API_KEY from .env
Model: gemini-2.0-flash
Usage: Generates disease recommendations

Example Request:
{
  "contents": [{
    "parts": [{"text": "Detected Early Leaf Spot. What should I do?"}]
  }]
}

Response: {"candidates": [{"content": {"parts": [{"text": "...recommendation..."}]}}]}
```

### Supabase API (from `.env`)
```
URL: SUPABASE_URL from .env
Key: SUPABASE_ANON_KEY from .env
Table: detections

Columns:
- id (auto)
- label (disease name)
- confidence (0-1 score)
- solution (AI recommendation)
- timestamp (ISO 8601)
```

---

## Environment Variables

### Required in `.env`
```properties
GEMINI_API_KEY=your_key_here
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
DETECTION_SERVER_URL=http://192.168.8.6:5000
```

### How to Load
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// In main():
await dotenv.load(fileName: ".env");

// In code:
final apiKey = dotenv.env['GEMINI_API_KEY'];
```

---

## Key Classes & Methods

### DetectionService
```dart
// Fetch latest detection from server
Future<List<NormalizedDetection>> fetchDetections()

// NormalizedDetection object
class NormalizedDetection {
  final String label;
  final double confidence;
  final String? time;
}
```

### GeminiService
```dart
// Generate recommendation for single detection
Future<String> generateGeminiRecommendation(NormalizedDetection detection)

// Generate unified recommendation for multiple detections
Future<String> generateMultipleRecommendation(List<NormalizedDetection> detections)

// Features: Smart caching, multi-disease support, confidence-based filtering
```

### SupabaseService (Singleton)
```dart
// Save detection to database
Future<bool> saveDetection({
  required String label,
  required double confidence,
  required String solution,
  String? timestamp,
})

// Get detection history
Future<List<Map<String, dynamic>>> getDetectionHistory()

// Singleton access
final supabaseService = SupabaseService();
```

### DetectionManager
```dart
// Start background polling every 10 seconds
void startPolling(Duration interval)

// Stop polling
void stopPolling()

// Automatically: Fetch detection → Generate recommendation → Save to DB
```

---

## Widget Hierarchy

```
MainWrapper (with BottomNavigationBar)
├── DashboardPage
│   ├── ModernAppBar
│   ├── LiveStreamWidget (shows video stream)
│   └── AIRecommendationWidget (shows recommendations)
├── HistoryPage
│   └── FutureBuilder (loads detection history)
└── SettingsPage
    └── Theme toggle, etc.
```

---

## Common Tasks

### Add a New Detection Field
```dart
// 1. Update schema in Supabase (add column to detections table)
// 2. Update NormalizedDetection class
class NormalizedDetection {
  final String label;
  final double confidence;
  final String? time;
  final String? newField; // ADD THIS
}

// 3. Update DetectionService.fetchDetections()
final detection = NormalizedDetection(
  label: decoded["label"] ?? "Unknown",
  confidence: decoded["confidence"]?.toDouble() ?? 0.0,
  time: decoded["timestamp"] ?? "",
  newField: decoded["newField"], // ADD THIS
);

// 4. Update SupabaseService.saveDetection()
final res = await _client.from('detections').insert({
  'label': label,
  'confidence': confidence,
  'solution': solution,
  'timestamp': ts,
  'newField': newField, // ADD THIS
})
```

### Change Detection Server URL
```dart
// Just update .env file:
DETECTION_SERVER_URL=http://new-ip:port

// Code automatically uses it via:
final serverUrl = dotenv.env['DETECTION_SERVER_URL'] ?? 'http://192.168.8.6:5000';
```

### Add Error Handling to API Call
```dart
// Pattern used throughout:
try {
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    // Process response
  } else {
    print("❌ HTTP Error: ${response.statusCode}");
    return fallbackValue; // Return safe default
  }
} catch (e) {
  print("❌ Error: $e");
  return fallbackValue; // Return safe default
}
```

---

## File Locations Quick Guide

| What | Where |
|------|-------|
| API calls to detection server | `lib/detection_service.dart` |
| AI recommendations | `lib/gemini_service.dart` |
| Database operations | `lib/services/supabase_service.dart` |
| Background processing | `lib/services/detection_manager.dart` |
| Dashboard UI | `lib/main.dart` (DashboardPage class) |
| History page | `lib/history_page.dart` |
| Settings page | `lib/pages/settings_page.dart` |
| Live stream widget | `lib/widgets/live_stream_widget.dart` |
| Recommendation widget | `lib/widgets/ai_recommendation_widget.dart` |
| Theme settings | `lib/theme/theme_provider.dart` |
| Secrets & config | `.env` (not committed) |

---

## Debug Checklist

```
❌ App crashes on startup?
  → Check .env file exists with all 4 required keys
  → Check pubspec.yaml has flutter_dotenv ^5.1.0
  → Run: flutter pub get

❌ Can't connect to detection server?
  → Check DETECTION_SERVER_URL in .env
  → Verify server is running: ping {SERVER_URL}
  → Check network/firewall isn't blocking port 5000

❌ Gemini API error?
  → Check GEMINI_API_KEY in .env is valid
  → Check API is enabled in Google Cloud Console
  → Check API key has necessary permissions

❌ Supabase queries fail?
  → Check SUPABASE_URL and SUPABASE_ANON_KEY in .env
  → Check 'detections' table exists in Supabase
  → Check RLS (Row Level Security) policies allow access

❌ History page shows nothing?
  → Check SupabaseService singleton is initialized
  → Check detections are actually being saved
  → Check browser console for errors: flutter doctor -v

❌ Recommendations take forever?
  → Check Gemini API rate limits (may have quota)
  → Check smart cache is working (should reuse recommendations)
  → Check network latency to generativelanguage.googleapis.com
```

---

## Performance Tips

### Current Optimizations ✅
- Smart caching of AI recommendations (rounds confidence to 10%)
- Singleton pattern for database (prevents duplicate connections)
- Background polling (doesn't block UI)
- MJPEG stream directly from server (no local processing)

### Potential Improvements
- Add SharedPreferences cache for offline access
- Implement request timeout to prevent hanging
- Add exponential backoff retry for failed requests
- Batch database inserts if multiple detections at once
- Use CDN for model/assets if needed

---

## Testing Checklist

Before deploying:
- [ ] Test with detection server offline (error handling)
- [ ] Test with slow network (timeout handling)
- [ ] Test with invalid detection data (validation)
- [ ] Test with no internet (graceful degradation)
- [ ] Test theme switching (light/dark mode)
- [ ] Test history page loading (caching works)
- [ ] Test multiple detections in quick succession
- [ ] Check no crashes in logs
- [ ] Check no hardcoded secrets remain
- [ ] Verify .env is not in git

---

## Security Reminders

🔐 **NEVER:**
- ❌ Hardcode API keys
- ❌ Hardcode server URLs
- ❌ Commit .env file
- ❌ Share API keys in code comments
- ❌ Log sensitive information

✅ **ALWAYS:**
- ✅ Use environment variables
- ✅ Add sensitive files to .gitignore
- ✅ Validate input data
- ✅ Handle errors gracefully
- ✅ Log safely (no credentials)

---

## Useful Commands

```bash
# Load environment and run
flutter run

# Check for compile errors
flutter analyze

# Format code
dart format lib/

# Check dependencies
flutter pub get

# Build APK for testing
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios
```

---

## Quick Links

- **Gemini API Docs:** https://ai.google.dev/docs
- **Supabase Docs:** https://supabase.com/docs
- **Flutter Dotenv:** https://pub.dev/packages/flutter_dotenv
- **HTTP Package:** https://pub.dev/packages/http
- **Provider Package:** https://pub.dev/packages/provider

---

**Last Updated:** 2024  
**Project:** AgriSense FYP  
**Status:** Production-Ready MVP ✅
