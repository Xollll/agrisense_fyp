# 🔧 History Page - Developer Reference

## Quick Overview

**File:** `lib/history_page.dart`

**State Variables Added:**
```dart
String _searchQuery = '';           // Search functionality
String _sortBy = 'Newest';         // Sort preference
bool _expandedToday = true;        // Section state
bool _expandedThisWeek = true;
bool _expandedThisMonth = true;
bool _expandedOlder = false;       // Default collapsed
```

**New Methods:**
- `_filterDetections()` - Apply filter + search + sort
- `_groupDetectionsByDate()` - Group items by date
- `_getDiseaseCountSummary()` - Get unique disease count
- `_buildDateSection()` - Render collapsible section

---

## Method Documentation

### `_filterDetections(List<Map<String, dynamic>> items)`

**Purpose:** Apply filter, search, and sort to detections

**Logic:**
1. Copy items to new list
2. Filter by confidence level (if not 'All')
3. Filter by search query (case-insensitive)
4. Sort by selected option
5. Return filtered & sorted list

**Parameters:**
- `items`: Raw detection list

**Returns:** Filtered, searched, and sorted list

**Example:**
```dart
final filtered = _filterDetections(detections);
// Returns detections matching all criteria
```

---

### `_groupDetectionsByDate(List<Map<String, dynamic>> items)`

**Purpose:** Group detections into date buckets

**Date Boundaries:**
- **Today:** Same calendar day as now
- **This Week:** Last 7 days
- **This Month:** Last 30 days
- **Older:** Everything else

**Parameters:**
- `items`: Detection list to group

**Returns:** 
```dart
Map<String, List<Map<String, dynamic>>> {
  'Today': [detection1, detection2],
  'This Week': [...],
  'This Month': [...],
  'Older': [...]
}
```

**Example:**
```dart
final grouped = _groupDetectionsByDate(detections);
grouped['Today']     // 2 detections today
grouped['This Week'] // 8 detections this week
```

---

### `_getDiseaseCountSummary(List<Map<String, dynamic>> items)`

**Purpose:** Get count of unique diseases

**Logic:**
1. Extract unique disease labels
2. Ignore "healthy" label
3. Return formatted string

**Parameters:**
- `items`: Detection list

**Returns:** Formatted string like "5 diseases" or "1 disease"

**Example:**
```dart
final summary = _getDiseaseCountSummary(detections);
// Returns: "5 diseases" or "1 disease"
```

---

### `_buildDateSection(BuildContext, String, List, bool, Function)`

**Purpose:** Render a collapsible timeline section

**Parameters:**
- `context`: Build context
- `title`: Section title ("Today", "This Week", etc.)
- `items`: Detections in this section
- `isExpanded`: Current expansion state
- `onExpandChanged`: Callback to toggle expansion

**Renders:**
```
┌─ Section Header ─┐
│ 📅 Today     (2) │ ← Tap to toggle
└─────────────────┘
    ↓ if expanded
┌─────────────────┐
│ Detection Card1 │
│ Detection Card2 │
└─────────────────┘
```

**Example:**
```dart
_buildDateSection(
  context,
  'Today',
  detections,
  _expandedToday,
  (value) => setState(() => _expandedToday = value),
)
```

---

## UI Components

### Quick Stats Bar
```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).primaryColor.withOpacity(0.08),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).primaryColor.withOpacity(0.15),
    ),
  ),
  // Shows: [Count] | [Disease Summary]
)
```

### Search Bar
```dart
TextField(
  onChanged: (value) => setState(() => _searchQuery = value),
  decoration: InputDecoration(
    hintText: 'Search disease...',
    prefixIcon: Icon(Icons.search),
    suffixIcon: _searchQuery.isNotEmpty ? Icon(Icons.clear) : null,
  ),
)
```

### Filter & Sort Row
```dart
Row(
  children: [
    // Filter chips (All, Healthy, Warning, Critical)
    Expanded(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filterChips),
    )),
    // Sort dropdown (Newest, Oldest, Confidence)
    DropdownButton<String>(value: _sortBy, items: [...]),
  ],
)
```

### Section Header
```dart
Container(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Icon(Icons.calendar_today),
        Text(title),
        Badge('${items.length}'),
      ]),
      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
    ],
  ),
)
```

---

## State Management Flow

```
User Input
    ↓
setState() triggered
    ↓
_filterDetections() called
    ↓
_groupDetectionsByDate() called
    ↓
_buildDateSection() for each group
    ↓
UI Updated
```

---

## Filter Logic

### By Confidence Level
```dart
if (_selectedFilter == 'Healthy') {
  return confidence >= 0.75;  // 75% or higher
}
if (_selectedFilter == 'Warning') {
  return confidence >= 0.5 && confidence < 0.75;  // 50-75%
}
if (_selectedFilter == 'Critical') {
  return confidence < 0.5;  // Below 50%
}
```

### By Search Query
```dart
final label = (item['label'] ?? '').toString().toLowerCase();
return label.contains(_searchQuery.toLowerCase());
```

### By Sort Order
```dart
if (_sortBy == 'Newest') {
  // Sort by timestamp descending
}
if (_sortBy == 'Oldest') {
  // Sort by timestamp ascending
}
if (_sortBy == 'Confidence') {
  // Sort by confidence descending (highest first)
}
```

---

## Date Parsing

```dart
// Raw timestamp format: "2025-12-08T14:30:45"
final timestamp = item['timestamp'] as String?;

// Extract date only
final dateStr = timestamp.contains('T') 
  ? timestamp.split('T')[0]  // "2025-12-08"
  : timestamp;

// Parse to DateTime
final itemDate = DateTime.parse(dateStr);

// Compare with boundaries
if (itemDate == today) { ... }
if (itemDate.isAfter(weekAgo)) { ... }
```

---

## Performance Considerations

### Optimization Tips
1. **Filtering is fast** - Only iterates once per change
2. **Grouping is fast** - Simple date comparisons
3. **Rendering is efficient** - Only expanded sections render cards
4. **State updates are batched** - Single setState() call

### For Large Datasets (100+)
- Collapsible sections help
- Only expanded sections rebuild
- Cards use reusable _DetectionCard widget
- ListView handles scrolling efficiently

### No Pagination Needed
- Timeline grouping inherently paginates
- Collapsed sections hide items
- Good UX without complex pagination

---

## Testing Checklist

```
□ Search by disease name works
□ Filter chips work (All, Healthy, Warning, Critical)
□ Sort options work (Newest, Oldest, Confidence)
□ Sections expand/collapse smoothly
□ Sections default to correct state
  - Today: expanded
  - This Week: expanded
  - This Month: expanded
  - Older: collapsed
□ Quick stats bar updates correctly
□ Cards display full details on tap
□ No performance issues with 50+ items
□ Mobile layout looks good
□ Dark mode works correctly
□ Edge cases:
  - Empty search results
  - All items filtered out
  - Single item in section
  - No detections at all
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Search not working | Check `_searchQuery` state update |
| Filter not applying | Verify confidence level boundaries |
| Sections not collapsing | Check `onExpandChanged` callback |
| Cards not showing | Verify `isExpanded` state |
| Wrong date grouping | Check DateTime parsing |
| Performance lag | Collapse older sections by default |

---

## Extension Points

### Future Enhancements
1. **Disease Trend Chart**
   - Add pie chart showing disease distribution
   - Location: Above Quick Stats Bar

2. **Advanced Export**
   - Add export button (CSV, PDF)
   - Uses filtered data

3. **Bulk Actions**
   - Delete, archive detections
   - Multi-select functionality

4. **Custom Date Range**
   - Allow filtering by specific dates
   - Date picker widget

5. **Disease Severity Indicator**
   - Add visual severity rating
   - Color code by severity level

---

## Code Quality

**Current:**
- ✅ No lint errors
- ✅ All methods have clear purpose
- ✅ State variables well-named
- ✅ Comments explain complex logic
- ✅ Follows Flutter best practices

**Maintainability:**
- Easy to understand flow
- Methods are focused and single-responsibility
- State changes are clear
- Widget tree is well-organized

---

## Summary

The History Page Timeline View is:
- **Simple** - Easy to understand
- **Efficient** - Good performance
- **Scalable** - Works with 50+ items
- **Maintainable** - Clear code structure
- **Extensible** - Easy to add features
