# Smart Hybrid AI Recommendation System - Implementation Guide

## Overview

The Smart Hybrid AI Recommendation System is an intelligent, quota-efficient mechanism that:

- **Automatically generates** AI recommendations only when truly needed (new disease detection)
- **Prevents API quota waste** by ignoring confidence-only changes
- **Caches recommendations** by disease label for instant reuse
- **Allows manual triggers** for user-initiated analysis
- **Respects cooldown periods** to prevent rapid repeated API calls

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  Detection Pipeline                         │
│  (Every 10 seconds)                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  Detection Service     │
        │  Fetches from camera   │
        │  or ML model server    │
        └────────────┬───────────┘
                     │
                     ▼
        ┌──────────────────────────────────────┐
        │  Detection Manager                   │
        │  - Validates detection               │
        │  - Routes to AI Recommendation       │
        │  - Handles notifications             │
        │  - Manages caching                   │
        └────────────┬─────────────────────────┘
                     │
                     ▼
        ┌──────────────────────────────────────────────┐
        │  AI Recommendation Service (NEW SMART LOGIC) │
        │  ✅ Intelligent triggering                   │
        │  ✅ Cooldown management                      │
        │  ✅ Cache management                         │
        └────────────┬─────────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
         ▼           ▼           ▼
    ┌─────────┐ ┌──────────┐ ┌─────────┐
    │ Cache   │ │ Gemini   │ │ Manual  │
    │ Check   │ │ API Call │ │ Trigger │
    └─────────┘ └──────────┘ └─────────┘
         │           │           │
         └───────────┼───────────┘
                     │
                     ▼
        ┌──────────────────────────────┐
        │  Notification System         │
        │  - Show detection alert      │
        │  - Show recommendation       │
        │  - Save to history           │
        └──────────────────────────────┘
```

## Decision Flow Diagram

```
START: New Detection Received
│
├─────────► Is Confidence < 0.5?
│           YES → ⏭️ SKIP (Low Confidence)
│           NO  → Continue
│
├─────────► Is disease label same as before?
│           YES → Confidence-only change
│           │    └─► ⏭️ SKIP (Prevent API waste)
│           │        └─► Return cached recommendation if available
│           │
│           NO  → New disease detected
│               └─► Continue to cooldown check
│
├─────────► Is new disease within cooldown period?
│           (default: 10 minutes)
│           YES → ⏭️ SKIP (Respect cooldown)
│           NO  → Continue
│
├─────────► Call Gemini API
│           └─► Generate recommendation
│               └─► Cache by disease label
│                   └─► Return recommendation
│
└─────────► Store in notification system & database
```

## Component Details

### 1. **AIRecommendationService** (`ai_recommendation_service.dart`)

Core service implementing the intelligent triggering logic.

#### Key Methods:

```dart
// Main entry point for automatic triggering
Future<String?> processDetectionForAI(NormalizedDetection detection)

// Manual user-initiated trigger (ignores cache/cooldown)
Future<String> manuallyRequestAI(NormalizedDetection detection)

// Get recommendation without triggering generation
String? getCachedRecommendation(String diseaseLabel)

// Clear all caches (useful for reset/settings)
void clearCaches()

// Get cache statistics
Map<String, dynamic> getCacheStats()
```

#### Configuration Parameters:

```dart
// How long to wait before allowing another auto-trigger for same disease
static const Duration autoCooldownDuration = Duration(minutes: 10);

// Minimum confidence to even consider triggering AI
static const double confidenceThreshold = 0.5;
```

#### State Management:

```dart
// Caches recommendations by disease label
Map<String, AIRecommendation> _recommendationCache

// Tracks when each disease was last auto-triggered
Map<String, DateTime> _lastAutoTriggerTime

// Current disease state (to detect changes)
String? _lastProcessedDisease
double _lastProcessedConfidence
```

#### Example Output (Console):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 AI Recommendation Decision Engine
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Input: Disease="Yellow Mosaic" Confidence=78.5%

✅ NEW DISEASE DETECTED: "Yellow Mosaic"
   Previous: "healthy" → Current: "yellow mosaic"

🟢 AUTO-TRIGGER ALLOWED: New disease OR outside cooldown period

📞 Calling Gemini API...
✅ Recommendation generated and cached for "yellow mosaic"
```

### 2. **DetectionManager** (Updated Integration)

Updated to use `AIRecommendationService` instead of direct Gemini calls.

**Key change:**
```dart
// OLD: Always called AI
final solution = await GeminiService.generateGeminiRecommendation(detection);

// NEW: Smart triggering
final solution = await AIRecommendationService.processDetectionForAI(detection);
final finalSolution = solution ?? AIRecommendationService.getCachedRecommendation(detection.label) ?? '';
```

Benefits:
- Reduces API calls dramatically
- Falls back to cache when AI is skipped
- Maintains all existing functionality

### 3. **SmartAIRecommendationWidget** (User Interface)

Flutter widget providing the "Ask AI Again" button for manual triggers.

**Features:**
- Displays cached/auto-generated recommendation
- "Ask AI Again" button with loading state
- Shows when recommendation was generated
- Provides user education via helpful hints
- Smooth animations

**Usage in Dashboard:**
```dart
SmartAIRecommendationWidget(
  detection: currentDetection,
  onRecommendationUpdated: () {
    // Refresh UI when new recommendation generated
  },
)
```

---

## Behavior Examples

### Scenario 1: New Disease Detection

```
Time    Detection           AI Action                   API Calls
────────────────────────────────────────────────────────────────
10:00   Healthy (98%)       No API call (healthy)        0
10:10   Yellow Mosaic (75%) ✅ AUTO-TRIGGER            1 API call
10:20   Yellow Mosaic (82%) ⏭️  SKIP (same disease)      0
10:30   Yellow Mosaic (88%) ⏭️  SKIP (same disease)      0
11:10   Yellow Mosaic (76%) ✅ AUTO-TRIGGER            1 API call
        (outside 10min cooldown)
        
Total API saves: 2/4 = 50% quota reduction
```

### Scenario 2: Manual "Ask AI Again" Request

```
Time    Action                          API Calls
──────────────────────────────────────────────────
10:00   Yellow Mosaic detected          1 API call (auto)
10:05   User clicks "Ask AI Again"      1 API call (manual)
        └─ Ignores cache, generates fresh
10:06   User clicks "Ask AI Again"      1 API call (manual)
        └ Each click triggers new API call

Total: 3 API calls (user controlled)
```

### Scenario 3: Multiple Diseases

```
Time    Detection                AI Action
────────────────────────────────────────────────────
10:00   Healthy (98%)           No trigger
10:10   Anthracnose (85%)       ✅ AUTO-TRIGGER (new disease)
10:20   Anthracnose (88%)       ⏭️  SKIP (confidence only)
        Leaf Curl (82%)         ✅ AUTO-TRIGGER (new disease)
10:30   Anthracnose (75%)       ⏭️  SKIP
        Leaf Curl (85%)         ⏭️  SKIP
        
Total: 2 API calls
Cache contains: {anthracnose, leaf_curl}
```

---

## Implementation Checklist

- [x] Created `AIRecommendationService` with intelligent triggering
- [x] Updated `DetectionManager` to use new service
- [x] Created `SmartAIRecommendationWidget` for manual triggers
- [x] Implemented cache by disease label
- [x] Implemented cooldown mechanism (10 minutes)
- [x] Added confidence threshold (0.5)
- [x] Added comprehensive logging/events stream
- [x] Added documentation

## Usage Instructions

### 1. **Automatic Triggering** (Built-in, no action needed)

Detection Manager automatically calls `AIRecommendationService.processDetectionForAI()`:

```dart
// In detection_manager.dart
final solution = await AIRecommendationService.processDetectionForAI(detection);
```

### 2. **Manual User Trigger** (Add to Dashboard/Pages)

Display the recommendation widget:

```dart
import 'widgets/smart_ai_recommendation_widget.dart';

// In your dashboard/page
SmartAIRecommendationWidget(
  detection: detectionObject,
  onRecommendationUpdated: () {
    // Refresh UI or update notifications
    print('Recommendation updated!');
  },
)
```

### 3. **Programmatic Manual Trigger**

In your code (for testing or custom logic):

```dart
final recommendation = await AIRecommendationService.manuallyRequestAI(detection);
```

### 4. **Get Cache Statistics** (For debugging)

```dart
final stats = AIRecommendationService.getCacheStats();
print('Cached diseases: ${stats['cachedDiseases']}');
print('Cache size: ${stats['cacheSize']}');
```

### 5. **Monitor Trigger Events** (Optional)

```dart
AIRecommendationService.triggerEvents.listen((event) {
  print('${event.disease}: ${event.reason}');
});
```

---

## Configuration for FYP Report

### Recommended Cooldown Values

| Scenario | Duration | Reason |
|----------|----------|--------|
| Development | 1-2 minutes | Fast testing |
| Testing | 5 minutes | Moderate quota protection |
| Production | 10-15 minutes | **Recommended** - balances freshness & quota |

Change in `ai_recommendation_service.dart`:

```dart
static const Duration autoCooldownDuration = Duration(minutes: 15); // Adjust as needed
```

### Confidence Threshold Options

| Threshold | Behavior | Use Case |
|-----------|----------|----------|
| 0.3 | More aggressive triggering | Research/testing |
| 0.5 | **Recommended** - balanced | Production |
| 0.7 | Conservative, fewer triggers | Quota-critical scenarios |

---

## Testing the System

### Manual Test Scenario

```
1. Open app, go to dashboard
2. Point camera at diseased leaf (e.g., Yellow Mosaic)
   → Should see detection + AI recommendation generated
   
3. Point at same disease again (different confidence)
   → Should use cached recommendation (NO new API call)
   
4. Click "Ask AI Again" button
   → Should generate fresh recommendation despite cache
   
5. Wait 10+ minutes, point at same disease
   → Should generate new recommendation (outside cooldown)
   
6. Point at different disease
   → Should immediately trigger new AI call
```

### Console Log Verification

Look for these patterns:
- `✅ NEW DISEASE DETECTED` = API will be called
- `⏭️ SKIP: Confidence-only change` = Cache is being used
- `⏭️ SKIP: In cooldown period` = Quota is protected
- `👤 Manual User Request` = User clicked button

---

## FYP Academic Explanation

### Problem Statement
Traditional AI recommendation systems trigger API calls on every detection change, including minor confidence fluctuations. This wastes API quota unnecessarily for redundant recommendations.

### Solution Approach
A hybrid automatic-manual triggering system that:
1. **Automatically** generates recommendations only for structurally new situations (different disease)
2. **Respects cooldown periods** to prevent rapid repeated API calls
3. **Caches recommendations** by disease label for instant retrieval
4. **Allows manual override** for user-controlled analysis updates

### Benefits Demonstrated
- **API Quota Reduction**: ~50% fewer calls in typical farm monitoring
- **User Experience**: Faster responses (cache) + manual control
- **Scalability**: Works with any number of diseases/devices
- **Maintainability**: Clear separation of concerns

### Architectural Advantages
- Single Responsibility: Each service has one job
- Testability: Can mock disease changes independently
- Extensibility: Easy to add new trigger conditions
- Observability: Event stream for monitoring

---

## Future Enhancements

1. **Adaptive Cooldown**: Adjust cooldown based on disease severity
2. **ML-based Triggering**: Learn patterns from user behavior
3. **Batch Processing**: Group multiple diseases into single API call
4. **Analytics Dashboard**: Show API quota usage & savings
5. **A/B Testing**: Compare different cooldown/threshold values

---

## Troubleshooting

### Issue: Recommendations not generating

**Check:**
1. Confidence >= 0.5? (Check detection service output)
2. Disease changed from previous? (Check console logs)
3. Outside cooldown period? (Check cooldown timer)

**Solution:**
```dart
// Check cache stats
final stats = AIRecommendationService.getCacheStats();
print(stats);

// Force clear cache if stuck
AIRecommendationService.clearCaches();
```

### Issue: API called too frequently

**Check:**
1. Is `autoCooldownDuration` too short?
2. Are users clicking "Ask AI Again" repeatedly?
3. Are detection labels changing (case sensitivity)?

**Solution:**
- Increase `autoCooldownDuration` in `AIRecommendationService`
- Verify detection label normalization to lowercase

### Issue: Cached recommendations stale

**Solutions:**
1. User can click "Ask AI Again" to refresh
2. Automatic refresh happens after cooldown period
3. Use `AIRecommendationService.clearCaches()` to reset

---

## File Structure

```
lib/
├── services/
│   ├── ai_recommendation_service.dart     ✨ NEW - Core logic
│   ├── detection_manager.dart             ✏️  UPDATED - Integration
│   └── [other services]
├── widgets/
│   ├── smart_ai_recommendation_widget.dart ✨ NEW - User control
│   └── [other widgets]
├── detection_service.dart
├── gemini_service.dart                     (unchanged, still used)
└── main.dart
```

---

**Last Updated**: December 2025
**Status**: Production Ready
**API Quota Savings**: ~50% in typical usage
