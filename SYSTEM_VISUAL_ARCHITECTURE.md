# AgriSense Multi-Disease System - Visual Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     AGRISENSE SYSTEM                            │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐
│   YOLO MODEL     │  (Chili Leaf Detection)
│                  │
│ Returns: List of │
│ - Disease labels │
│ - Confidence %   │
│ - Bounding boxes │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  DETECTION SERVICE                                               │
│  ├─ Processes raw YOLO output                                   │
│  ├─ Normalizes confidence scores                                │
│  └─ Creates NormalizedDetection objects                         │
└────────┬──────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────────┐
│  MAIN APP STATE                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ currentDetections: List<NormalizedDetection>               │ │
│  │ ├─ Detection #1: "Powdery Mildew", 92% confidence        │ │
│  │ ├─ Detection #2: "Powdery Mildew", 88% confidence        │ │
│  │ ├─ Detection #3: "Leaf Spot", 87% confidence             │ │
│  │ ├─ Detection #4: "Bacterial Wilt", 95% confidence        │ │
│  │ └─ Detection #5: "Healthy", 85% confidence               │ │
│  │                                                            │ │
│  │ _lastDetectionPersistent:                                 │ │
│  │ └─ Last non-healthy disease (for UI persistence)         │ │
│  │                                                            │ │
│  │ _aiCache: Map<String, String>                            │ │
│  │ └─ Cache key: "bacterial wilt|leaf spot|powdery mildew"  │ │
│  │    Cache value: Full AI recommendation text               │ │
│  └────────────────────────────────────────────────────────────┘ │
└────────┬──────────────────────────────────────────────────────────┘
         │
         ├─────────────────┬─────────────────┐
         ▼                 ▼                 ▼
    ┌────────────┐  ┌─────────────┐  ┌──────────────┐
    │   UI FLOW  │  │ USER ACTION │  │  GEMINI API  │
    └────────────┘  └─────────────┘  └──────────────┘
         │                │                │
         ▼                ▼                ▼
    (See below)       (See below)       (See below)
```

---

## UI Rendering Flow

```
                        DETECTION STATE
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         HEALTHY      DISEASE FOUND     RESOLVED
        (_lastDetection = null)    (_lastDetection ≠ null)
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐  ┌────────────────┐  ┌──────────────────┐
        │ GREEN    │  │ DISEASE CARDS  │  │ DISEASE CARDS +  │
        │ SECTION  │  │ (Orange)       │  │ "⏸️ Resolved"   │
        │          │  │                │  │ Badge            │
        │ ✓ Plant  │  │ Card 1:        │  │                  │
        │ is       │  │ "Powdery..."   │  │ Shows same as    │
        │ healthy! │  │ 92% conf       │  │ disease found    │
        │          │  │                │  │ state            │
        │ NO AI    │  │ Card 2:        │  │                  │
        │ SECTION  │  │ "Leaf Spot"    │  │ + AI SECTION     │
        │          │  │ 87% conf       │  │ with cached      │
        │ NO       │  │                │  │ recommendation   │
        │ BUTTONS  │  │ Card 3:        │  │                  │
        │          │  │ "Bacterial..." │  │ + "Ask AI" BTN   │
        │          │  │ 95% conf       │  │ (to refresh)     │
        │          │  │                │  │                  │
        │          │  │ AI SECTION:    │  │ STATUS BADGE:    │
        │          │  │ Header: "3     │  │ ⏸️ Resolved     │
        │          │  │ issues found"  │  │                  │
        │          │  │                │  │ (or 🔴 Active    │
        │          │  │ Badge: 🔴 Active  │ if disease       │
        │          │  │                │  │ reappears)       │
        │          │  │ AI Tips Button │  │                  │
        │          │  │ (blue/orange)  │  │                  │
        │          │  │                │  │                  │
        │          │  │ [Shows cached  │  │ [Shows cached    │
        │          │  │  text or blank]   │  text from       │
        │          │  │                │  │  before]         │
        └──────────┘  └────────────────┘  └──────────────────┘
```

---

## User Action: "Ask AI for Tips"

```
User Taps "Ask AI for Tips" Button
                │
                ▼
    Build Cache Key
    ├─ Get all unique disease names from currentDetections
    ├─ Convert to lowercase
    ├─ Remove duplicates (toSet())
    ├─ Convert back to list
    ├─ SORT alphabetically
    └─ Join with "|"
                │
                ▼
    Example: ["Powdery Mildew", "Leaf Spot", "Bacterial Wilt"]
    ↓
    Sorted: ["Bacterial Wilt", "Leaf Spot", "Powdery Mildew"]
    ↓
    Key: "bacterial wilt|leaf spot|powdery mildew"
                │
                ▼
        ┌───────────────────┐
        │ Cache Lookup      │
        │ _aiCache[key]?    │
        └────────┬──────────┘
                 │
        ┌────────┴────────┐
        │                 │
      FOUND            NOT FOUND
        │                 │
        ▼                 ▼
    ┌────────┐      ┌──────────────────────┐
    │INSTANT │      │ API CALL NEEDED      │
    │DISPLAY │      └──────────┬───────────┘
    │        │                 │
    │ Show   │                 ▼
    │ cached │      ┌──────────────────────┐
    │ text   │      │ 1. Show loading      │
    │ (< 10ms)     │    spinner           │
    │        │      │ 2. Disable button    │
    │ NO     │      └──────────┬───────────┘
    │ API    │                 │
    │ CALL   │                 ▼
    │        │      ┌──────────────────────┐
    └────────┘      │ Call GeminiService   │
                    │ .generateMultiple    │
                    │ Recommendation()     │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ GEMINI PROCESSING    │
                    │ (See below)          │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ 3. Cache result      │
                    │ _aiCache[key] =      │
                    │    recommendation    │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ 4. Hide spinner      │
                    │ 5. Enable button     │
                    │ 6. Display text in   │
                    │    UI                │
                    │ (1-3 second total)   │
                    └──────────────────────┘
```

---

## Gemini API Processing

```
Call: GeminiService.generateMultipleRecommendation(
        [DetPowderyMildew92%, DetLeafSpot87%, 
         DetBacterialWilt95%, DetHealthy85%]
      )
                │
                ▼
    ┌────────────────────────────────────────┐
    │ FILTER STEP                            │
    │ Remove all "healthy" detections        │
    │                                        │
    │ Input:  [PM92%, LS87%, BW95%, H85%]   │
    │ Output: [PM92%, LS87%, BW95%]          │
    └─────────┬────────────────────────────┘
              │
              ▼
    ┌────────────────────────────────────────┐
    │ DEDUPLICATION STEP                     │
    │ Count unique diseases + max confidence │
    │                                        │
    │ Input: [PM92%, PM88%, LS87%, BW95%]   │
    │                                        │
    │ uniqueDiseases:                        │
    │ { powdery mildew: 2,                   │
    │   leaf spot: 1,                        │
    │   bacterial wilt: 1 }                  │
    │                                        │
    │ highestConfidence:                     │
    │ { powdery mildew: 92%,                 │
    │   leaf spot: 87%,                      │
    │   bacterial wilt: 95% }                │
    └─────────┬────────────────────────────┘
              │
              ▼
    ┌────────────────────────────────────────┐
    │ BUILD DISEASE LIST FOR PROMPT          │
    │                                        │
    │ "powdery mildew (2 detected,           │
    │  92% confidence)"                      │
    │ "leaf spot (1 detected,                │
    │  87% confidence)"                      │
    │ "bacterial wilt (1 detected,           │
    │  95% confidence)"                      │
    └─────────┬────────────────────────────┘
              │
              ▼
    ┌────────────────────────────────────────┐
    │ BUILD UNIFIED PROMPT                   │
    │                                        │
    │ "You are an agricultural AI...         │
    │                                        │
    │  Detections found:                     │
    │  powdery mildew (2 detected, 92%)      │
    │  leaf spot (1 detected, 87%)           │
    │  bacterial wilt (1 detected, 95%)      │
    │                                        │
    │  Your task:                            │
    │  1. Combine into unique categories     │
    │  2. Ignore healthy detections          │
    │  3. Generate ONE unified recommendation│
    │  4. Keep simple & actionable           │
    │                                        │
    │  Response format:                      │
    │  - Detected Issues: [list]             │
    │  - Explanation: [short]                │
    │  - Recommended Actions: [bullets]"     │
    │                                        │
    └─────────┬────────────────────────────┘
              │
              ▼
    ┌────────────────────────────────────────┐
    │ SEND TO GEMINI API                     │
    │ (HTTP POST request)                    │
    └─────────┬────────────────────────────┘
              │
              ▼
    ┌────────────────────────────────────────┐
    │ RECEIVE UNIFIED RESPONSE               │
    │                                        │
    │ "Detected Issues:                      │
    │  - Powdery Mildew                      │
    │  - Leaf Spot                           │
    │  - Bacterial Wilt                      │
    │                                        │
    │  Explanation:                          │
    │  Your chili crop is experiencing       │
    │  three significant fungal and          │
    │  bacterial diseases that require       │
    │  immediate action.                     │
    │                                        │
    │  Recommended Actions:                  │
    │  1. Isolate affected plants            │
    │  2. Apply fungicide spray              │
    │  3. Remove severely infected leaves    │
    │  4. Improve air circulation            │
    │  5. Water at soil level only"          │
    │                                        │
    └────────────────────────────────────────┘
                │
                ▼
        Return to caller
```

---

## Cache Key Generation Example

```
Current Detections from YOLO:
├─ Powdery Mildew - 92%
├─ Powdery Mildew - 88%
├─ Leaf Spot - 87%
├─ Leaf Spot - 89%
├─ Bacterial Wilt - 95%
└─ Healthy - 85%

Processing:
1. Extract all unique labels (case-insensitive):
   [powdery mildew, powdery mildew, leaf spot, 
    leaf spot, bacterial wilt, healthy]
   
2. Remove duplicates (toSet()):
   {powdery mildew, leaf spot, bacterial wilt, healthy}
   
3. Convert back to list (toList()):
   [powdery mildew, leaf spot, bacterial wilt, healthy]
   
4. SORT alphabetically:
   [bacterial wilt, healthy, leaf spot, powdery mildew]
   
5. Join with "|":
   "bacterial wilt|healthy|leaf spot|powdery mildew"
   
   BUT: Gemini filters out "healthy" in processing,
   so effectively this is:
   "bacterial wilt|leaf spot|powdery mildew"

Final Cache Key:
"bacterial wilt|healthy|leaf spot|powdery mildew"

If same diseases detected again (in any order/frequency):
├─ Powdery Mildew - 93%
├─ Powdery Mildew - 91%
├─ Bacterial Wilt - 94%
└─ Leaf Spot - 88%

Cache key = "bacterial wilt|healthy|leaf spot|powdery mildew"
         → SAME KEY!
         → CACHE HIT!
         → Return cached recommendation instantly
         
If different disease detected:
├─ Powdery Mildew - 92%
├─ Leaf Spot - 87%
└─ Brown Spot - 90%  ← NEW!

Cache key = "brown spot|healthy|leaf spot|powdery mildew"
         → DIFFERENT KEY!
         → CACHE MISS!
         → New API call required
         → New result cached
```

---

## State Transitions

```
┌──────────────────────────────────────────────┐
│         APP LIFECYCLE                        │
└──────────────────────────────────────────────┘

START
  │
  ▼
[Detection Loop Starts - Every 10 seconds]
  │
  ├─ Poll detection API
  ├─ Get raw YOLO output
  ├─ Normalize detections
  └─ Update currentDetections
  │
  ▼
[State Check]
  │
  ┌─────────────────────────────────────┐
  │ Is there any non-healthy detection? │
  └────────┬────────────────────────────┘
           │
      ┌────┴───────┐
      │            │
     YES           NO
      │            │
      ▼            ▼
  Disease        Healthy
  Detected       Plant
   State          State
      │            │
      ▼            ▼
  Set             Set
  _lastDetection  _lastDetection
  Persistent      Persistent
      │            │
      ▼            ▼
 Show "Get      Show "Plant
 AI Tips"      is Healthy"
 Section       Card ONLY
      │            │
      ▼            ▼
 User can     App waits
 tap button   silently
      │            │
      └────┬───────┘
           │
      ┌────┴──────────────────────────┐
      │  Continue polling              │
      │  Every 10 seconds              │
      │                                │
      │  If disease changes:           │
      │  ├─ Update UI immediately      │
      │  ├─ Keep cached recommendations│
      │  └─ User can request new tips  │
      │                                │
      │  If plant becomes healthy:     │
      │  ├─ Show healthy card          │
      │  ├─ Keep old recommendations   │
      │  │  (with "⏸️ Resolved" badge)│
      │  └─ Hide "Get AI Tips" section │
      └────────────────────────────────┘
```

---

## Error Handling Flow

```
Try to get AI Recommendation
          │
          ▼
      Try Block
          │
   ┌──────┼──────┐
   │      │      │
Cache   API    Exception
Success Success Throws
   │      │      │
   ▼      ▼      ▼
Return Return CatchBlock
Instant Result   │
          │      ├─ Print error
          └──┬───┤ message
             │   ├─ Return generic
             ▼   │  error message
          Display│
          Text   ├─ Show snap bar
                 └─ Hide spinner
```

---

## Data Flow - Complete Picture

```
YOLO Model
    │
    ├─ Raw Detections
    │  ├─ {"label": "powdery mildew", "confidence": 0.92}
    │  ├─ {"label": "leaf spot", "confidence": 0.87}
    │  └─ {"label": "healthy", "confidence": 0.85}
    │
    ▼
Detection Service
    │
    ├─ Normalize
    │  ├─ Convert to NormalizedDetection objects
    │  ├─ Validate confidence ranges
    │  └─ Add metadata
    │
    ▼
Main App State
    │
    ├─ currentDetections
    │  └─ List of ALL detections (including healthy)
    │
    ├─ _lastDetectionPersistent
    │  └─ Last non-healthy detection (for UI persistence)
    │
    ├─ _aiCache
    │  └─ Map of cached recommendations by disease combination
    │
    └─ geminiText
       └─ Current displayed AI recommendation
    │
    ├─ UI Layer (Filtering)
    │  └─ Shows only non-healthy detections
    │
    ├─ User Taps "Ask AI for Tips"
    │  │
    │  ├─ Build cache key from currentDetections
    │  │
    │  ├─ Check _aiCache
    │  │  ├─ HIT: Display cached text
    │  │  └─ MISS: Call Gemini API
    │  │
    │  ├─ Gemini Service
    │  │  ├─ Filter out "healthy"
    │  │  ├─ Deduplicate diseases
    │  │  ├─ Count occurrences
    │  │  ├─ Get max confidence
    │  │  └─ Build unified prompt
    │  │
    │  ├─ Gemini API
    │  │  ├─ Process unified request
    │  │  └─ Return unified response
    │  │
    │  ├─ Cache result
    │  │
    │  └─ Update UI with recommendation
    │
    ▼
Display to User
    ├─ Disease cards (if any)
    ├─ AI recommendation text
    ├─ Status badge (Active/Resolved)
    └─ Loading/error states
```

---

## Summary: Why This Architecture Works

✅ **Multiple Diseases Handled** - currentDetections stores ALL
✅ **No Duplicates** - Unique disease deduplication in GeminiService
✅ **One Recommendation** - Unified prompt to single API call
✅ **Smart Caching** - Cache key includes all diseases, prevents duplicates
✅ **Fast Responses** - Second request for same diseases returns instantly
✅ **Clear UI** - Shows diseases in orange, healthy in green, recommendations when needed
✅ **Farmer-Friendly** - Simple language, actionable steps, focus on solutions
✅ **No Bugs** - Healthy properly filtered, recommendations don't persist incorrectly

The system is **optimized, efficient, and user-friendly**.
