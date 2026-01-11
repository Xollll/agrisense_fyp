# Database Update Flow - Disease Detection + Recommendation

## Overview
Two-step process: Disease detection saves immediately, recommendation updates the same record.

---

## How It Works Now

### Step 1️⃣: Disease Detected (Automatic)
```
Camera detects disease → Immediately saved to database
├─ label: "Powdery Mildew"
├─ confidence: 0.87
├─ solution: "" (empty)
├─ timestamp: 2026-01-11T10:30:00Z
└─ id: 123
```

**Where it happens:**
- File: `lib/services/detection_manager.dart`
- Method: `_pollOnce()` → saves via `SupabaseService.saveDetection()`
- When: Every 10 seconds (polling)
- Database action: **INSERT** new record

---

### Step 2️⃣: User Clicks "Get Recommendation"
```
User taps recommendation button → Updates SAME record
├─ id: 123 (same as step 1)
├─ label: "Powdery Mildew" (unchanged)
├─ confidence: 0.87 (unchanged)
├─ solution: "Apply fungicide XYZ..." (UPDATED)
└─ updated_at: 2026-01-11T10:35:00Z (new timestamp)
```

**Where it happens:**
- File: `lib/widgets/ai_recommendation_widget.dart`
- Method: `_requestAIRecommendation()`
- When: User manually clicks "Get Recommendation" button
- Database action: **UPDATE** existing record (finds last detection by label)

---

## Code Changes

### 1. SupabaseService - New Method
**File:** `lib/services/supabase_service.dart`

```dart
Future<bool> updateLastDetectionWithRecommendation({
  required String label,
  required String recommendation,
}) async {
  // Find the most recent detection for this disease
  // Update its 'solution' field with the recommendation
  // Add 'updated_at' timestamp
}
```

### 2. AIRecommendationWidget - Updated Logic
**File:** `lib/widgets/ai_recommendation_widget.dart`

Changed from:
```dart
// OLD: Creates new record
await supabase.saveDetection(
  label: diseaseLabel,
  confidence: confidence,
  solution: ai,  // Creates duplicate!
  timestamp: now,
);
```

To:
```dart
// NEW: Updates existing record
await supabase.updateLastDetectionWithRecommendation(
  label: diseaseLabel,
  recommendation: ai,
);
```

---

## Database Schema Requirements

Your `detections` table should have:
```sql
CREATE TABLE detections (
  id BIGINT PRIMARY KEY,
  label VARCHAR,
  confidence FLOAT,
  solution VARCHAR,
  timestamp TIMESTAMP,
  updated_at TIMESTAMP,  -- NEW: Add this if not present
  ...
);
```

**Note:** If your table doesn't have `updated_at`, the code will still work but won't record when the recommendation was added.

---

## Benefits

✅ **No duplicate records** - One disease = one database record
✅ **Cleaner history** - View all detections without duplicates
✅ **Tracking updates** - Know when recommendation was added via `updated_at`
✅ **Better statistics** - Accurate count of unique disease detections
✅ **Efficient** - One UPDATE query instead of INSERT + duplicate

---

## Example Timeline

```
Time    Event                              Database Action
─────────────────────────────────────────────────────────
10:30   Disease detected (87% confidence)  INSERT id=123
10:32   Disease still showing (88%)        No action (<10% change)
10:35   User clicks recommendation         UPDATE id=123 (add solution)
10:36   Same disease (90%)                 No action (already has solution)
10:40   Disease cleared                    No action
```

---

## Testing

### Test Case 1: Basic Flow
1. Point camera at diseased plant
2. Wait for notification (detection saved)
3. Check database → record created with empty `solution`
4. Click "Get Recommendation"
5. Check database → SAME record updated with recommendation in `solution` field

### Test Case 2: Multiple Diseases
1. Detect Disease A → saves as id=1
2. Detect Disease B → saves as id=2
3. Click recommendation for Disease A → updates id=1 only
4. Check database → id=1 has solution, id=2 still empty

### Test Case 3: Same Disease Detected Again Later
1. Detect Disease A (confidence 45%) → saves as id=1
2. Move camera away (detection clears)
3. Detect Disease A again (confidence 50%) → saves as id=2 (NEW record)
4. Click recommendation for Disease A → updates id=2 (latest one)
5. Check database → Both records exist, id=2 has solution

---

## Files Modified

```
✅ lib/services/supabase_service.dart (added updateLastDetectionWithRecommendation)
✅ lib/widgets/ai_recommendation_widget.dart (changed saveDetection to updateLastDetectionWithRecommendation)
```

---

## No Breaking Changes
All existing code continues to work. The change is completely backward compatible.
