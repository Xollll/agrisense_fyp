# History Page - Developer Quick Reference

## 🎯 Quick Start

The History Page is fully implemented with all modern features. Here's what you need to know:

---

## 📊 Severity Classification System

### How It Works
The system uses **both label AND confidence** to determine severity:

```dart
SeverityType classifySeverity(String label, double confidence)
```

### Classification Rules

| Label | Confidence | Severity | Badge Color |
|-------|-----------|----------|-------------|
| Healthy/Normal/Good | Any | Healthy | 🟢 Green |
| Disease | ≥ 0.80 | Critical | 🔴 Red |
| Disease | 0.50-0.79 | Warning | 🟡 Yellow |
| Disease | < 0.50 | Low Risk | 🟢 Green |

### Story Messages
Each severity level has a user-friendly message:
- **Healthy**: "Your plant looks healthy. No action needed."
- **Critical**: "Severe disease detected. Immediate action recommended."
- **Warning**: "Early symptoms detected. Monitor closely."
- **Low Risk**: "Minor symptoms detected. Monitor casually."

---

## 🎨 Color Reference

### Severity Colors
```dart
SeverityType.healthy    → #10B981 (Green)
SeverityType.low        → #10B981 (Green)
SeverityType.warning    → #F59E0B (Yellow/Amber)
SeverityType.critical   → #DC2626 (Red)
```

### Confidence Colors
```dart
confidence ≥ 0.8        → #06B6D4 (Strong Blue)
confidence ≥ 0.6        → #0EA5E9 (Moderate Blue)
confidence ≥ 0.4        → #F59E0B (Weak Amber)
confidence < 0.4        → #EF4444 (Very Weak Red)
```

---

## 📱 UI Components

### Card Structure
```
┌─────────────────────────────────────┐
│ Title               Date  [Badge]   │
├─────────────────────────────────────┤
│ Story text...                       │
│                                     │
│ Diagnosis Confidence: 85%           │
│ [████████░░░░]                      │
│                                     │
│ Recommended Action                  │
│ First 2-3 lines of text...          │
│ [View Full Recommendation]          │
│                                     │
│ → Tap for details                   │
└─────────────────────────────────────┘
```

### Details Modal Sections
1. **Header** - Title, Date, Severity Badge
2. **Story** - User-friendly explanation
3. **Plant Health Status** - Icon + Health indicator
4. **Diagnosis Confidence** - Progress bar + percentage
5. **Recommended Action** - Full recommendation text
6. **Detection Details** - Table with Disease, Status, Severity, Date

### Recommendation Modal
- Full recommendation text in scrollable container
- Clean formatting with proper line height
- Close button in header

---

## 🔍 Filtering & Search

### Current Filter Options
```dart
final filters = ['All', 'Healthy', 'Low Risk', 'Warning', 'Critical'];
```

### Search Behavior
- Real-time search as user types
- Case-insensitive matching
- Searches disease/label name
- Clear button to reset

### Sort Options
```dart
final sorts = ['Newest', 'Oldest', 'Confidence'];
```

---

## 📅 Time Period Grouping

### Auto-Grouping Logic
```
Today        → Entries from today
This Week    → Entries from last 7 days
This Month   → Entries from last 30 days
Older        → Entries older than 30 days
```

### Expand/Collapse States
```dart
bool _expandedToday = true;        // Expanded by default
bool _expandedThisWeek = true;     // Expanded by default
bool _expandedThisMonth = true;    // Expanded by default
bool _expandedOlder = false;       // Collapsed by default
```

---

## 🔧 Key Helper Functions

### Classification
```dart
// Main severity function
SeverityType classifySeverity(String label, double confidence)

// Get badge color
Color _getSeverityColor(SeverityType severity)

// Get badge label text
String _getSeverityLabel(SeverityType severity)

// Get story explanation
String _getSeverityStory(String label, SeverityType severity)
```

### Confidence Display
```dart
// Color based on confidence level
Color _getDiagnosisConfidenceColor(double confidence)
```

### Health Status
```dart
// Color for health indicator
Color _getHealthStatusColor(String label)

// Status label text
String _getHealthStatusLabel(String label)
```

### Recommendations
```dart
// Preview recommendation (2-3 lines)
String _getTruncatedSolution(String fullSolution, {int lines = 3})

// Show full recommendation in modal
void _showFullRecommendationModal(BuildContext context)
```

---

## 📝 Data Structure

### Detection Item Fields
```dart
{
  'label': String,           // Disease/status name
  'confidence': double,      // 0.0 - 1.0
  'timestamp': String,       // ISO 8601 format
  'solution': String,        // Full recommendation text
  // ... other fields
}
```

### Grouped Detections
```dart
Map<String, List<Map<String, dynamic>>> {
  'Today': [...],
  'This Week': [...],
  'This Month': [...],
  'Older': [...]
}
```

---

## 🎨 Dark Mode Support

All colors automatically adapt to theme:
```dart
final isDarkMode = Theme.of(context).brightness == Brightness.dark;

// Background adapts
isDarkMode ? Colors.grey.shade900 : Colors.white

// Text color adapts
isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700
```

---

## 🚀 Common Tasks

### Add New Severity Level
1. Add to `SeverityType` enum
2. Update `classifySeverity()` logic
3. Update `_getSeverityColor()` switch
4. Update `_getSeverityLabel()` switch
5. Update `_getSeverityStory()` switch
6. Add to filter chips (if user-selectable)

### Change Confidence Thresholds
Edit the classification logic in `classifySeverity()`:
```dart
if (confidence >= 0.80) return SeverityType.critical;  // Change 0.80
if (confidence >= 0.50) return SeverityType.warning;   // Change 0.50
```

### Modify Story Text
Update `_getSeverityStory()` function:
```dart
String _getSeverityStory(String label, SeverityType severity) {
  switch (severity) {
    case SeverityType.critical:
      return 'Your custom message here';  // Change this
    // ...
  }
}
```

### Adjust Recommendation Preview Lines
```dart
// In _DetectionCard.build()
final truncatedSolution = _getTruncatedSolution(solution, lines: 2);  // Change lines
```

---

## 📊 Stats Bar

Shows quick overview at top:
- **Detections**: Total count of filtered items
- **Found**: Unique disease count

---

## 🔄 Data Flow

```
1. User opens History Page
   ↓
2. FutureBuilder fetches from Supabase
   ↓
3. _filterDetections() applies:
   - Severity filter
   - Search query
   - Sort order
   ↓
4. _groupDetectionsByDate() organizes by time
   ↓
5. _buildDateSection() renders each group
   ↓
6. _DetectionCard renders each item
   ↓
7. User interactions:
   - Tap card → _showDetailsModal()
   - Click "View Full" → _showFullRecommendationModal()
   - Expand/collapse section
   - Change filter/sort/search
```

---

## ⚠️ Important Notes

1. **Healthy Status**: Always shows as "Healthy" severity regardless of confidence score
2. **Confidence Display**: Shown as a separate progress bar (diagnostic confidence)
3. **Timestamp Format**: Expected as ISO 8601 (with or without 'T')
4. **Empty States**: Handled gracefully with appropriate messages
5. **Dark Mode**: Full support with automatic color adaptation

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Detections not showing | Check Supabase connection and data format |
| Wrong severity badge | Verify label and confidence values |
| Timestamp parsing error | Ensure timestamp is ISO 8601 format |
| Modal not appearing | Check BuildContext is available |
| Colors not changing in dark mode | Verify isDarkMode variable is set correctly |

---

## 📞 Questions?

Refer to the full `HISTORY_PAGE_REDESIGN_SUMMARY.md` for comprehensive documentation.

---

**Status:** ✅ Ready for Use
**Last Updated:** Current Session
**Code Quality:** Production Ready
