# 🔄 Hybrid Recommendation System - Implementation Guide

## Overview

The AgriSense system now implements a **hybrid auto-generation + smart caching** recommendation system that:

1. **Auto-generates** recommendations when disease/confidence changes significantly
2. **Caches intelligently** using disease combination + rounded confidence as key
3. **Respects user requests** with force-refresh when farmer manually asks
4. **Returns unified recommendations** for all detected diseases

---

## 🎯 How It Works

### System Architecture

```
YOLO Detection Loop (Every 700ms)
        ↓
   Detects: [PM 92%, LS 87%, H85%]
        ↓
  Filter "healthy"
        ↓
   Detections: [PM 92%, LS 87%]
        ↓
  Build Smart Cache Key
  "leaf spot:0.9|powdery mildew:0.9"
  (rounded to 10% increments)
        ↓
        ┌─────────────────┐
        │  Check Cache    │
        └────────┬────────┘
                 │
        ┌────────┴────────┐
        │                 │
      HIT              MISS OR FORCE
        │              REFRESH
        ↓                 ↓
   Return          Generate Fresh
   Cached          Recommendation
   Text            (API Call)
        │                 │
        └────────┬────────┘
                 ↓
           Update UI
```

### Two Modes of Operation

#### Mode 1: **Auto-Generation** (Detection Loop)
```dart
// Called every 700ms when detections change
_autoRequestAIRecommendation()
  └─ forceRefresh: false  // Respect cache

Logic:
1. Build smart cache key (disease names + rounded confidence)
2. Check if key matches last key
   ├─ Same key? → Use cached recommendation
   └─ Different key? → Generate new recommendation
3. Update UI silently (no loading spinner)
```

**When Used:**
- Runs automatically in detection loop
- Every 700ms, detections are checked
- If disease/confidence changes significantly, new recommendation auto-generated
- If no change, cached recommendation reused

**Example:**
```
Time 1: Detects "Powdery Mildew 92%, Leaf Spot 87%"
        Cache key: "leaf spot:0.9|powdery mildew:0.9"
        Not in cache → API call → Generate recommendation
        Store in cache
        
Time 2: Detects "Powdery Mildew 91%, Leaf Spot 88%"
        Cache key: "leaf spot:0.9|powdery mildew:0.9" (same after rounding!)
        Cache HIT → Return cached recommendation instantly
        No API call
        
Time 3: Detects "Powdery Mildew 92%, Leaf Spot 87%, Bacterial Wilt 95%"
        Cache key: "bacterial wilt:1.0|leaf spot:0.9|powdery mildew:0.9" (DIFFERENT!)
        Cache MISS → API call → Generate new recommendation
        Store in new cache entry
```

#### Mode 2: **User-Triggered Refresh** (Manual Button)
```dart
// Called when farmer taps "Ask AI for Tips" button
_requestAIRecommendation()
  └─ forceRefresh: true  // Always generate fresh

Logic:
1. Show loading spinner
2. Call AI service with forceRefresh=true
3. AI service ignores cache, generates fresh recommendation
4. Store in cache for next time
5. Update UI and show confirmation snap bar
```

**When Used:**
- When farmer explicitly taps "Ask AI for Tips" button
- Always generates fresh recommendation
- Shows loading spinner and confirmation message
- Useful if farmer wants to double-check or farm situation changed

---

## 💾 Smart Cache Key System

### How Cache Key Is Built

```dart
// Input: Multiple detections
[
  NormalizedDetection("Powdery Mildew", 0.923),
  NormalizedDetection("Leaf Spot", 0.871),
  NormalizedDetection("Healthy", 0.85)
]

// Step 1: Filter "healthy"
[
  NormalizedDetection("Powdery Mildew", 0.923),
  NormalizedDetection("Leaf Spot", 0.871)
]

// Step 2: Get unique diseases + highest confidence
uniqueDiseases = {
  "powdery mildew": 1 (count)
  "leaf spot": 1 (count)
}

highestConfidence = {
  "powdery mildew": 0.923
  "leaf spot": 0.871
}

// Step 3: Round confidence to nearest 10%
// 0.923 → 0.9 (rounded)
// 0.871 → 0.9 (rounded)

// Step 4: Sort disease names alphabetically
["leaf spot", "powdery mildew"]

// Step 5: Build key with format: "disease:confidence|disease:confidence"
"leaf spot:0.9|powdery mildew:0.9"

FINAL CACHE KEY
```

### Why Round Confidence?

**Problem Without Rounding:**
```
Time 1: Powdery Mildew 92.3% → Key: "powdery mildew:0.923"
Time 2: Powdery Mildew 92.1% → Key: "powdery mildew:0.921" (DIFFERENT!)
Result: Cache miss even though confidence barely changed!
```

**Solution With 10% Rounding:**
```
Time 1: Powdery Mildew 92.3% → 0.9 → Key: "powdery mildew:0.9"
Time 2: Powdery Mildew 92.1% → 0.9 → Key: "powdery mildew:0.9" (SAME!)
Result: Cache hit! Avoids unnecessary API calls for tiny fluctuations.
```

### Cache Behavior Matrix

| Scenario | Cache Key | Result | API Call |
|----------|-----------|--------|----------|
| PM 92% + LS 87% (first time) | leaf spot:0.9\|powdery mildew:0.9 | MISS | ✅ Yes |
| PM 92% + LS 87% (same diseases) | leaf spot:0.9\|powdery mildew:0.9 | HIT | ❌ No |
| PM 91% + LS 88% (tiny change) | leaf spot:0.9\|powdery mildew:0.9 | HIT | ❌ No |
| PM 92% + LS 87% + BW 95% (new disease) | bacterial wilt:1.0\|leaf spot:0.9\|powdery mildew:0.9 | MISS | ✅ Yes |
| BW 95% only (disease resolved) | bacterial wilt:1.0 | MISS | ✅ Yes |

---

## 🔌 Code Integration Points

### In main.dart

#### Detection Loop (Auto-Generation)
```dart
Future<void> fetchDetections() async {
  final data = await DetectionService.fetchDetections();
  
  setState(() {
    currentDetections = data;
    // ... update UI ...
  });
  
  // Auto-trigger recommendation if diseases changed
  _autoRequestAIRecommendation();  // ← Calls hybrid system
}
```

#### Manual Button Handler (Force Refresh)
```dart
Future<void> _requestAIRecommendation() async {
  // ... show loading spinner ...
  
  final ai = await GeminiService.generateMultipleRecommendation(
    detectionsToAnalyze,
    forceRefresh: true  // ← User explicitly requested
  );
  
  // ... update UI and show confirmation ...
}
```

#### Auto-Recommendation Method
```dart
Future<void> _autoRequestAIRecommendation() async {
  // ... no loading spinner, silent update ...
  
  final ai = await GeminiService.generateMultipleRecommendation(
    detectionsToAnalyze,
    forceRefresh: false  // ← Respect cache
  );
  
  // Update UI only if recommendation changed
}
```

### In gemini_service.dart

#### Cache Key Building
```dart
static String _buildSmartCacheKey(
    Map<String, int> uniqueDiseases,
    Map<String, double> highestConfidence) {
  // Sort by disease name (consistent key)
  // Round confidence to 0.1 (10% increments)
  // Return: "disease1:conf|disease2:conf|..."
}
```

#### Hybrid Logic
```dart
static Future<String> generateMultipleRecommendation(
    List<NormalizedDetection> detections,
    {bool forceRefresh = false}) async {
  
  // Build smart cache key
  final smartCacheKey = _buildSmartCacheKey(...);
  
  // Determine if fresh generation needed
  bool shouldGenerateFresh = 
    forceRefresh ||                          // User forced refresh
    smartCacheKey != _lastCacheKey ||        // Disease/confidence changed
    !_recommendationCache.containsKey(...);  // Not in cache
  
  if (!shouldGenerateFresh && cached) {
    return _recommendationCache[smartCacheKey]!;  // Cache HIT
  }
  
  // Cache MISS: Generate new recommendation
  final recommendation = callGeminiAPI(...);
  _recommendationCache[smartCacheKey] = recommendation;
  _lastCacheKey = smartCacheKey;
  
  return recommendation;
}
```

---

## 📊 User Experience Flow

### Scenario 1: Disease Detection → Auto-Recommendation

```
User opens app
        ↓
Detection loop starts (every 700ms)
        ↓
YOLO detects: Powdery Mildew 92%, Leaf Spot 87%
        ↓
Auto-recommendation triggered
├─ Build cache key: "leaf spot:0.9|powdery mildew:0.9"
├─ Not in cache (first time)
├─ Call Gemini API
├─ Receive: "Your chili has powdery mildew and leaf spot..."
├─ Cache it
└─ Update UI (no loading spinner, silent update)
        ↓
UI shows: Disease cards + AI recommendation
        ↓
User sees fully populated screen immediately!
```

### Scenario 2: Same Disease Detected Again

```
Previous: Powdery Mildew 92%, Leaf Spot 87% (cached)
        ↓
New detection: Powdery Mildew 91%, Leaf Spot 88%
        ↓
Auto-recommendation triggered
├─ Build cache key: "leaf spot:0.9|powdery mildew:0.9" (same!)
├─ Found in cache
├─ Return cached recommendation
└─ Update UI instantly
        ↓
UI shows same recommendation (instant)
        ↓
No API call wasted!
```

### Scenario 3: User Manually Taps "Ask AI for Tips"

```
Current state: Powdery Mildew 92%, Leaf Spot 87% (already cached)
        ↓
User taps "Ask AI for Tips" button
        ↓
Show loading spinner
        ↓
Call AI with forceRefresh=true
├─ Ignores cache
├─ Generates fresh recommendation
├─ Store in cache
└─ Return fresh recommendation
        ↓
Hide loading spinner
        ↓
Show confirmation: "✓ Recommendation updated"
        ↓
User gets fresh insight!
```

### Scenario 4: New Disease Appears

```
Previous: Powdery Mildew 92%, Leaf Spot 87% (cached)
        ↓
New detection: PM 92%, LS 87%, Bacterial Wilt 95%
        ↓
Auto-recommendation triggered
├─ Build cache key: "bacterial wilt:1.0|leaf spot:0.9|powdery mildew:0.9"
├─ Different key! (new disease added)
├─ Not in cache (cache miss)
├─ Call Gemini API with 3 diseases
├─ Receive unified recommendation for all 3
├─ Cache new result
└─ Update UI with new recommendation
        ↓
UI shows: 3 disease cards + New unified recommendation
        ↓
Farmer immediately sees how to handle all 3!
```

---

## 🔍 Debug Output

The system prints useful debug messages:

```
Auto-detection triggered:
  ⚠ Cache MISS: Generating new recommendation
  Current key: leaf spot:0.9|powdery mildew:0.9
  Last key: null
  ✓ Recommendation cached for key: leaf spot:0.9|powdery mildew:0.9

Next detection (same diseases):
  ✓ Cache HIT: Using cached recommendation for [leaf spot:0.9|powdery mildew:0.9]

New disease detected:
  ⚠ Cache MISS: Generating new recommendation
  Current key: bacterial wilt:1.0|leaf spot:0.9|powdery mildew:0.9
  Last key: leaf spot:0.9|powdery mildew:0.9
  ✓ Recommendation cached for key: bacterial wilt:1.0|leaf spot:0.9|powdery mildew:0.9

User forces refresh:
  ⚠ Cache MISS or FORCE REFRESH: Generating new recommendation
  (User explicitly requested, ignoring cache)
```

---

## ✨ Benefits of Hybrid System

| Benefit | How It Works |
|---------|---|
| **Fast Auto-Updates** | New diseases auto-detected and handled |
| **Efficient Caching** | Minor confidence changes don't trigger API |
| **User Control** | Farmer can force fresh at any time |
| **No Wasted Calls** | Same diseases = instant cache hit |
| **Unified Approach** | All diseases in one recommendation |
| **Silent Updates** | Auto-changes don't interrupt user |
| **Confidence aware** | 10% rounding prevents jitter |
| **Smart Keys** | Disease names + confidence = unique identity |

---

## 🧪 Test Scenarios

### Test 1: Auto-Generate on New Disease
```
1. Open app
2. Wait for YOLO detection
3. Observe: AI recommendation auto-appears
   Expected: No loading spinner, recommendation just shows up
```

### Test 2: Cache Hit on Same Disease
```
1. Disease detected and recommendation shown
2. Wait 5 seconds (keep same disease visible)
3. Check console for "Cache HIT" message
   Expected: No API call made, instant response
```

### Test 3: Cache Miss on New Disease
```
1. Powdery Mildew detected and cached
2. New disease appears (Leaf Spot)
3. Check console for "Cache MISS" message
   Expected: API call made, new recommendation
```

### Test 4: Force Refresh Works
```
1. Recommendation showing
2. Tap "Ask AI for Tips" button
3. Observe loading spinner
4. Check console for "FORCE REFRESH" message
5. New recommendation appears
   Expected: Fresh recommendation despite cache
```

### Test 5: Confidence Rounding
```
1. Disease detected at 92% confidence
2. Confidence drops to 88% (same 0.9 bucket)
3. Check console for "Cache HIT"
   Expected: No API call (confidence in same 10% bucket)
4. Confidence drops to 78% (different 0.8 bucket)
5. Check console for "Cache MISS"
   Expected: API call triggered (confidence bucket changed)
```

---

## 🔧 Customization Options

### Change Rounding Granularity
To round to 20% instead of 10%:
```dart
// In _buildSmartCacheKey:
final confidenceRounded = (confidence * 5).round() / 5;  // 5 = 100/20
```

### Change Auto-Check Interval
Currently every 700ms:
```dart
// In initState:
const Duration(milliseconds: 700)  // Change this
```

### Disable Caching Completely
Set all `forceRefresh: true`:
```dart
// In _autoRequestAIRecommendation:
forceRefresh: true  // Force API call every time
```

### Disable Auto-Generation
Remove the call:
```dart
// In fetchDetections:
// _autoRequestAIRecommendation();  // Commented out
```

---

## 📈 Performance Characteristics

| Operation | Time | Notes |
|-----------|------|-------|
| Build cache key | < 1ms | String concatenation |
| Cache lookup | < 1ms | HashMap lookup |
| Cache hit response | < 10ms | Return cached string |
| Cache miss (API call) | 1-3 sec | Depends on Gemini |
| Confidence rounding | < 0.1ms | Math operation |
| Total auto-update (hit) | < 10ms | Invisible to user |
| Total auto-update (miss) | 1-3 sec | Auto-background call |
| Total manual update (forced) | 1-3 sec | Shown with spinner |

---

## 🎓 Key Concepts

### Smart Cache Key
A string that represents a disease combination's unique state:
- Includes disease names (what diseases)
- Includes rounded confidence (how confident)
- Sorted for consistency
- Changes when disease/confidence changes significantly

### 10% Confidence Rounding
Prevents cache misses from tiny confidence fluctuations:
- 92% and 91% both round to 0.9
- Same cache key = cache hit
- Saves API calls for minor variations
- Still detects real changes (92% → 78% = different bucket)

### Auto vs. Manual
- **Auto:** Background, respect cache, silent updates
- **Manual:** User-triggered, force refresh, show loading spinner

### Unified Recommendation
All diseases in one recommendation:
- Single API call for all
- One action plan addressing all issues
- No conflicting advice
- Efficient and clear

---

## 📝 Summary

The **hybrid recommendation system**:

✅ **Auto-generates** when disease/confidence changes  
✅ **Caches smartly** with disease + rounded confidence key  
✅ **Respects user requests** with force-refresh option  
✅ **Generates unified** recommendations for all diseases  
✅ **Avoids waste** by skipping API for minor fluctuations  
✅ **Provides instant** updates to users  

Perfect for small-scale farmers who need **quick, smart recommendations** without overwhelming API calls or confusing multiple responses.
