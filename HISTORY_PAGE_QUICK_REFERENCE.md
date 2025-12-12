# History Page - Quick Reference Card

## 🎯 One-Page Cheat Sheet

### Severity Classification at a Glance

```
INPUT: label (string) + confidence (0.0-1.0)
↓
CLASSIFICATION:
  if label = "healthy/normal/good" → HEALTHY (green)
  else if confidence ≥ 0.80 → CRITICAL (red)
  else if confidence ≥ 0.50 → WARNING (yellow)
  else → LOW RISK (green)
↓
OUTPUT: SeverityType + Color + Label + Story
```

---

### Color Quick Reference

| Severity | Color | Hex | RGB |
|----------|-------|-----|-----|
| Healthy | Green | #10B981 | rgb(16, 185, 129) |
| Low Risk | Green | #10B981 | rgb(16, 185, 129) |
| Warning | Amber | #F59E0B | rgb(245, 158, 11) |
| Critical | Red | #DC2626 | rgb(220, 38, 38) |

---

### Confidence Thresholds

```
< 0.50    → Low Risk (Green)
0.50-0.79 → Warning (Amber)
≥ 0.80    → Critical (Red)
```

---

### Story Messages

```
HEALTHY:     "Your plant looks healthy. No action needed."
CRITICAL:    "Severe disease detected. Immediate action recommended."
WARNING:     "Early symptoms detected. Monitor closely."
LOW RISK:    "Minor symptoms detected. Monitor casually."
```

---

### Time Period Grouping

```
TODAY        Today's detections
THIS WEEK    Last 7 days
THIS MONTH   Last 30 days
OLDER        Older than 30 days
```

---

### Filter Options

```
All       → Show everything
Healthy   → Only green "Healthy" badge
Low Risk  → Only green "Low Risk" badge
Warning   → Only yellow "Warning" badge
Critical  → Only red "Critical" badge
```

---

### Key Functions

```dart
// Classify severity
classifySeverity(String label, double confidence)
  → SeverityType

// Get badge color
_getSeverityColor(SeverityType severity)
  → Color

// Get badge text
_getSeverityLabel(SeverityType severity)
  → String ("Healthy", "Low Risk", "Warning", "Critical")

// Get story text
_getSeverityStory(String label, SeverityType severity)
  → String

// Truncate recommendation (2-3 lines)
_getTruncatedSolution(String solution, {int lines = 3})
  → String
```

---

### UI Layout Breakdown

```
CARD:
┌─ Header (Title + Date + Badge) ─────┐
├─ Story Text ─────────────────────────┤
├─ Diagnosis Confidence Bar + % ───────┤
├─ Recommendation Preview (2-3 lines) ─┤
└─ Tap Hint + Arrow ────────────────────┘

MODAL:
├─ Header (Close Button)
├─ Title + Date + Severity Badge
├─ Story Text
├─ Plant Health Status (Icon + Text)
├─ Diagnosis Confidence (Bar + %)
├─ Full Recommendation
├─ Detection Details (Table)
└─ [End of scrollable content]

RECOMMENDATION MODAL:
├─ Header: "Full Recommendation" + Close
├─ Full Text (scrollable)
└─ Padding + Bottom spacing
```

---

### State Variables

```dart
_selectedFilter       // Current filter ("All", "Healthy", etc.)
_searchQuery          // Search text
_sortBy               // Sort order ("Newest", "Oldest", "Confidence")
_expandedToday        // Section expanded state (bool)
_expandedThisWeek     // Section expanded state (bool)
_expandedThisMonth    // Section expanded state (bool)
_expandedOlder        // Section expanded state (bool)
```

---

### Important Conversions

```dart
// Confidence to percentage
(confidence * 100).toStringAsFixed(0)  // "85%"
(confidence * 100).toStringAsFixed(1)  // "85.2%"

// Timestamp parsing
timestamp.contains('T') ? timestamp.split('T')[0] : timestamp
// Result: "2024-01-15"

// Confidence as number
double confidence = (item['confidence'] is num)
    ? (item['confidence'] as num).toDouble()
    : double.tryParse('${item['confidence']}') ?? 0.0;
```

---

### Widget Tree

```
HistoryPage (StatefulWidget)
  └─ _HistoryPageState (State)
      └─ Scaffold
          ├─ CustomScrollView (Sliver)
          │   ├─ SliverToBoxAdapter (AppBar)
          │   └─ SliverFillRemaining
          │       └─ FutureBuilder
          │           ├─ [Loading State]
          │           ├─ [Empty State]
          │           └─ Column
          │               ├─ Quick Stats Bar
          │               ├─ Search & Filter Section
          │               └─ SingleChildScrollView
          │                   └─ Column
          │                       ├─ _buildDateSection() x4
          │                       │   └─ _DetectionCard() x N
          │                       ├─ _DetectionCard
          │                       │   ├─ GestureDetector
          │                       │   │   └─ Container (Card)
          │                       │   │       └─ Column
          │                       │   │           ├─ Header Row
          │                       │   │           ├─ Story Text
          │                       │   │           ├─ Confidence Bar
          │                       │   │           └─ Recommendation
          │                       │   ├─ _showDetailsModal()
          │                       │   │   └─ ModalBottomSheet
          │                       │   └─ _showFullRecommendationModal()
          │                       │       └─ ModalBottomSheet
```

---

### Common Patterns

#### Filter Data
```dart
filteredDetections = _filterDetections(detections);
// Applies: severity filter + search + sort
```

#### Group Data
```dart
groupedDetections = _groupDetectionsByDate(filteredDetections);
// Returns: Map<String, List> with 4 groups
```

#### Classify Severity
```dart
final severity = classifySeverity(label, confidence);
final color = _getSeverityColor(severity);
final text = _getSeverityLabel(severity);
final story = _getSeverityStory(label, severity);
```

#### Update State
```dart
setState(() {
  _selectedFilter = 'Critical';
  _sortBy = 'Confidence';
  _expandedToday = true;
});
```

---

### Dark Mode Check

```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

// Use for colors:
isDarkMode ? Colors.grey.shade900 : Colors.white
isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700
```

---

### Error Handling Patterns

```dart
// Date parsing
try {
  final dateStr = timestamp.contains('T') 
      ? timestamp.split('T')[0] 
      : timestamp;
  final itemDate = DateTime.parse(dateStr);
} catch (e) {
  grouped['Older']!.add(item);  // Default to Older
}

// Null safety
(item['confidence'] is num)
    ? (item['confidence'] as num).toDouble()
    : double.tryParse('${item['confidence']}') ?? 0.0

// Empty string check
if (label.isEmpty) return 'Unknown';
if (solution.isEmpty) return 'No recommendation available';
```

---

### Typography Styles

```dart
// Headings
Theme.of(context).textTheme.headlineSmall    // 24px, bold
Theme.of(context).textTheme.titleLarge       // 20px, bold

// Body text
Theme.of(context).textTheme.bodySmall        // 12px
Theme.of(context).textTheme.bodyMedium       // 14px

// Labels
Theme.of(context).textTheme.labelSmall       // 11px
Theme.of(context).textTheme.labelLarge       // 14px
```

---

### Spacing Constants

```
4px    - Icon size, thin dividers
6px    - Badge padding (vertical)
8px    - Section gaps
10px   - Badge padding (horizontal), button padding
12px   - Card gaps, modal gaps
14px   - Card/modal padding
16px   - Main padding
24px   - Large gaps
```

---

### Testing Quick Checklist

```
✓ Healthy classification
✓ Critical classification (high confidence)
✓ Warning classification (medium confidence)
✓ Low Risk classification (low confidence)
✓ Filter all options work
✓ Search case-insensitive
✓ Sort orders work
✓ Group counts correct
✓ Modals open/close
✓ Dark mode colors correct
✓ No null pointer exceptions
✓ Performance acceptable
```

---

### Deployment Checklist

```
□ Code review approved
□ All tests pass
□ No errors or warnings
□ Tested on 3+ devices
□ Dark mode verified
□ Landscape tested
□ QA approved
```

---

### Debugging Tips

```
1. Check classification:
   print('Severity: ${classifySeverity(label, confidence)}');

2. Check filter state:
   print('Selected: $_selectedFilter, Search: $_searchQuery, Sort: $_sortBy');

3. Check grouped data:
   print('Grouped: ${_groupDetectionsByDate(filtered).keys}');

4. Check BuildContext:
   assert(context != null, 'BuildContext required');

5. Check data format:
   print('Label: $label, Confidence: $confidence (${confidence.runtimeType})');
```

---

**Print This Page! 📄**
Keep it handy during development and debugging.

**Last Updated:** Current Session  
**Status:** ✅ Production Ready
