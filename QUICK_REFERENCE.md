# Quick Reference Guide

## 📁 New File Locations

```
lib/widgets/
├── live_stream_widget.dart          ✨ NEW
├── ai_recommendation_widget.dart    ✨ NEW
└── mjpeg_stream.dart                ✨ NEW
```

## 🎯 What Each Widget Does

### LiveStreamWidget
**Location:** `lib/widgets/live_stream_widget.dart`

**Purpose:** Display camera stream + detection results

**Constructor:**
```dart
LiveStreamWidget({
  required List<NormalizedDetection> detections,
  required String streamUrl,
})
```

**Usage in DashboardPage:**
```dart
LiveStreamWidget(
  detections: _currentDetections,
  streamUrl: "http://192.168.8.6:5000/video_feed",
)
```

**What it displays:**
- MJPEG live stream with "LIVE" badge
- Detection cards (disease name + confidence)
- "No detections yet" message when empty

**What it DOES NOT do:**
- ❌ Call AI APIs
- ❌ Manage any state except the passed props
- ❌ Handle button clicks

---

### AIRecommendationWidget
**Location:** `lib/widgets/ai_recommendation_widget.dart`

**Purpose:** Manage AI recommendations with hybrid logic

**Constructor:**
```dart
AIRecommendationWidget({
  required List<NormalizedDetection> currentDetections,
  required NormalizedDetection? lastDetectionPersistent,
  required bool isCurrentlyDetected,
  required VoidCallback onDiseaseCleared,
})
```

**Usage in DashboardPage:**
```dart
AIRecommendationWidget(
  key: _aiRecommendationWidgetKey,  // Important for calling triggerAutoRecommendation
  currentDetections: _currentDetections,
  lastDetectionPersistent: _lastDetectionPersistent,
  isCurrentlyDetected: _isCurrentlyDetected,
  onDiseaseCleared: _onDiseaseCleared,
)
```

**Key Methods:**
```dart
// Called automatically when disease/confidence changes
Future<void> triggerAutoRecommendation()

// Called when user clicks button (manual refresh)
Future<void> _requestAIRecommendation()
```

**What it displays:**
- Health message (if no disease detected)
- AI recommendation UI (if disease detected)
  - Status badge (🔴 Active / ⏸️ Resolved)
  - Recommendation text (if available)
  - "Ask AI for Tips" button
  - Helper text

**What it DOES:**
- ✅ Calls GeminiService
- ✅ Manages recommendation state (_geminiText, _isLoadingAI)
- ✅ Handles auto-recommendations (respects cache)
- ✅ Handles manual refresh (force fresh)
- ✅ Shows loading spinner during requests

---

### MJPEGStream
**Location:** `lib/widgets/mjpeg_stream.dart`

**Purpose:** Display MJPEG video stream

**Constructor:**
```dart
MJPEGStream({
  required String url,
})
```

**What it does:**
- Connects to MJPEG stream
- Parses JPEG frames from stream
- Displays current frame
- Shows loading spinner while connecting

**Never called directly from DashboardPage** - it's used by LiveStreamWidget

---

## 🔗 How They Connect

```
DashboardPage
    │
    ├─ _fetchDetections()
    │   │
    │   ├─ setState()
    │   │   └─ rebuilds LiveStreamWidget with new detections
    │   │
    │   └─ triggerAutoRecommendation()
    │       └─ AIRecommendationWidget calls GeminiService if needed
    │
    ├─ LiveStreamWidget                  ← Displays current detections
    │   └─ MJPEGStream                   ← Shows camera feed
    │
    └─ AIRecommendationWidget           ← Manages AI recommendations
```

## 🔄 Data Flow Example

**When a disease is detected:**
```
1. DetectionService returns new disease
2. DashboardPage's _fetchDetections():
   - Updates _currentDetections = [newDisease]
   - Updates _lastDetectionPersistent = newDisease
   - setState() → rebuilds
3. LiveStreamWidget receives new detections
   - Shows detection card (name + confidence)
4. AIRecommendationWidget:
   - Detects disease via didUpdateWidget
   - Clears old _geminiText (if was different disease)
   - Calls triggerAutoRecommendation()
   - GeminiService checks cache:
     - If cache miss (disease changed): generates new tips
     - If cache hit (same disease): uses cached tips
5. UI updates silently (no spinner)
```

## 🎛️ How to Customize

### Change stream URL
```dart
// In DashboardPage.build()
LiveStreamWidget(
  detections: _currentDetections,
  streamUrl: "http://YOUR-IP:PORT/video_feed",  // ← Change here
)
```

### Add custom UI to stream
```dart
// Modify LiveStreamWidget build() method
// Add overlays, buttons, etc.
```

### Customize recommendation card
```dart
// Modify AIRecommendationWidget build() method
// Change colors, spacing, text, etc.
```

### Change detection polling interval
```dart
// In DashboardPage.initState()
_detectionTimer = Timer.periodic(
  const Duration(milliseconds: 700),  // ← Change here (default: 700ms)
  (_) => _fetchDetections(),
);
```

## 🧪 Testing Example

### Test LiveStreamWidget
```dart
testWidgets('LiveStreamWidget displays detections', (WidgetTester tester) async {
  final detections = [
    NormalizedDetection(
      label: 'Leaf Spot',
      confidence: 0.95,
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LiveStreamWidget(
          detections: detections,
          streamUrl: "http://test:5000/video_feed",
        ),
      ),
    ),
  );

  // Verify detection card is shown
  expect(find.text('Leaf Spot'), findsOneWidget);
  expect(find.text('95% confidence'), findsOneWidget);
});
```

### Test AIRecommendationWidget
```dart
testWidgets('AIRecommendationWidget shows health message', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AIRecommendationWidget(
          currentDetections: [],
          lastDetectionPersistent: null,
          isCurrentlyDetected: false,
          onDiseaseCleared: () {},
        ),
      ),
    ),
  );

  // Verify health message
  expect(find.text('Plant Status'), findsOneWidget);
  expect(find.text('Your plant looks healthy!'), findsOneWidget);
});
```

## 🚀 Running Your App

**The app works exactly as before:**
```bash
flutter run
```

All imports are handled automatically. No additional setup needed!

## 🐛 If Something Breaks

**File not found error:**
```
Undefined name 'LiveStreamWidget'
```
✅ Solution: Check import in main.dart
```dart
import 'widgets/live_stream_widget.dart';
```

**Method not found error:**
```
The method 'triggerAutoRecommendation' isn't defined
```
✅ Solution: Make sure you're using GlobalKey properly:
```dart
final state = _aiRecommendationWidgetKey.currentState as dynamic;
state?.triggerAutoRecommendation();
```

**Type mismatch error:**
```
'DashboardPage' expect type X but got Y
```
✅ Solution: Verify constructor parameters match exactly

## 📚 File Overview Table

| File | Lines | Responsibility | State |
|------|-------|-----------------|-------|
| main.dart | 276 | App + DashboardPage | StatefulWidget |
| live_stream_widget.dart | 180 | Camera + detections UI | StatelessWidget |
| ai_recommendation_widget.dart | 350 | AI logic + recommendations | StatefulWidget |
| mjpeg_stream.dart | 80 | MJPEG stream parsing | StatefulWidget |

## 🎓 Key Concepts

### Why separate widgets?

1. **Single Responsibility Principle**
   - Each widget does one thing well
   - Easier to understand and maintain

2. **Testability**
   - Can test each widget in isolation
   - Mock dependencies easily

3. **Reusability**
   - Use LiveStreamWidget in other pages
   - Use AIRecommendationWidget for multiple detections
   - Mix and match widgets as needed

4. **Scalability**
   - Add more detection types? Just pass more data
   - Add more AI features? Add to AIRecommendationWidget
   - Add new pages? Import and reuse widgets

## 💡 Pro Tips

### Tip 1: Reuse widgets
```dart
// In a details modal
showModalBottomSheet(
  context: context,
  builder: (ctx) => LiveStreamWidget(
    detections: [selectedDetection],
    streamUrl: streamUrl,
  ),
);
```

### Tip 2: Customize with parameters
```dart
// Future enhancement: add optional properties
class LiveStreamWidget extends StatelessWidget {
  final List<NormalizedDetection> detections;
  final String streamUrl;
  final Color? badgeColor;  // ← Add custom options
  final bool showConfidence;  // ← Add custom options
  
  const LiveStreamWidget({...});
}
```

### Tip 3: Add analytics
```dart
// In AIRecommendationWidget
void _requestAIRecommendation() async {
  analytics.logEvent('ai_tips_requested');  // ← Track usage
  // ... rest of method
}
```

### Tip 4: Cache recommendations locally
```dart
// Save recommendations to local storage
final prefs = await SharedPreferences.getInstance();
prefs.setString('last_recommendation_$disease', ai);
```

---

**Questions? Check the full REFACTORING_COMPLETE.md file!** 📖
