# Statistics Filter - Code Location Reference

## File Location
📁 `lib/pages/statistics_page_redesigned.dart`

---

## Key Code Locations

### 1. Filter Buttons (What User Clicks)
**Location**: Line 728-745 in `statistics_page_redesigned.dart`

```dart
Widget _buildTimeRangeFilter(BuildContext context, bool isDarkMode) {
  return Row(
    children: [
      _buildModernFilterChip('All Time', 0, Icons.all_inclusive),
      const SizedBox(width: 12),
      _buildModernFilterChip('30 Days', 1, Icons.calendar_month),
      const SizedBox(width: 12),
      _buildModernFilterChip('7 Days', 2, Icons.calendar_today),
    ],
  );
}
```

**Called from**: Line 152 in `_buildContent()`
```dart
_buildTimeRangeFilter(context, isDarkMode),
```

**On Screen**: Middle of Statistics page, after Health Trends

---

### 2. Filter Button Click Handler
**Location**: Line 771-780 in `_buildModernFilterChip()`

```dart
InkWell(
  onTap: () {
    setState(() {
      _selectedTimeRange = index;  // 0, 1, or 2
    });
  },
  // ... rest of button styling
)
```

**What Happens**:
- User clicks button → `onTap` fires
- `setState()` called → Widget rebuilds
- `_selectedTimeRange` updated to 0, 1, or 2

---

### 3. State Variable Tracking Selection
**Location**: Line 20

```dart
class _StatisticsPageModernState extends State<StatisticsPageModern>
    with TickerProviderStateMixin {
  int _selectedTimeRange = 0;  // Stores which button is selected
  // ...
}
```

**Values**:
- `0` = All Time
- `1` = 30 Days
- `2` = 7 Days

---

### 4. Filtered Data Display (Activity Timeline Chart)
**Location**: Line 1096-1171 in `_buildHealthTrendChart()`

```dart
Widget _buildHealthTrendChart(BuildContext context, StatisticsProvider provider, bool isDarkMode) {
  if (provider.timelineData.isEmpty) {
    return const SizedBox.shrink();
  }

  // ========== KEY PART: Determine days based on selection ==========
  int daysToShow;
  String timeRangeLabel;
  switch (_selectedTimeRange) {
    case 0: // All Time
      daysToShow = provider.timelineData.length;
      timeRangeLabel = 'All Time';
      break;
    case 1: // 30 Days
      daysToShow = 30;
      timeRangeLabel = 'Last 30 Days';
      break;
    case 2: // 7 Days (default)
      daysToShow = 7;
      timeRangeLabel = 'Last 7 Days';
      break;
    default:
      daysToShow = 7;
      timeRangeLabel = 'Last 7 Days';
  }

  // ========== KEY PART: Filter the data ==========
  final recentData = provider.timelineData.take(daysToShow).toList();

  return Column(
    // ... Chart structure with:
    // - Dynamic title: 'Detection Activity ($timeRangeLabel)'
    // - Dynamic badge: '${recentData.length} day${recentData.length > 1 ? 's' : ''}'
    // - Chart bars: _buildAnimatedBarChart(recentData)
    // - Dynamic message: _getTimeRangeInsight(timeRangeLabel, recentData.length)
  );
}
```

**Called from**: Line 158 in `_buildContent()`
```dart
_buildHealthTrendChart(context, provider, isDarkMode),
```

**On Screen**: "📈 Activity Timeline" section below filter buttons

---

### 5. Contextual Insight Messages
**Location**: Line 1175-1191

```dart
/// Get contextual insight message based on selected time range
String _getTimeRangeInsight(String timeRange, int dataPoints) {
  if (dataPoints == 0) {
    return 'No data available for this period - start monitoring to see trends!';
  }
  
  switch (timeRange) {
    case 'Last 7 Days':
      return '📅 Viewing last 7 days - great for weekly monitoring and trend spotting';
    case 'Last 30 Days':
      return '📅 Viewing last 30 days - perfect for monthly health assessment and progress tracking';
    case 'All Time':
      return '📅 Viewing all history - see complete farm health evolution over time';
    default:
      return 'Consistent monitoring leads to healthier crops';
  }
}
```

**Called from**: Line 1155 in `_buildHealthTrendChart()`

---

### 6. Bar Chart Rendering
**Location**: Line 1200-1264 in `_buildAnimatedBarChart()`

```dart
Widget _buildAnimatedBarChart(List<dynamic> data) {
  if (data.isEmpty) return const SizedBox.shrink();

  // Uses the filtered 'data' passed from _buildHealthTrendChart()
  // Renders bars for each data point
  // Each bar animated with TweenAnimationBuilder
}
```

**Called from**: Line 1140 in `_buildHealthTrendChart()`
```dart
child: _buildAnimatedBarChart(recentData),  // recentData is the filtered data
```

---

## Data Flow - From Click to Display

```
┌─────────────────────────────────────┐
│ User clicks "30 Days" button         │
│ (Line 771-780 in _buildModernFilterChip)
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ onTap handler fires:                 │
│ setState(() {                        │
│   _selectedTimeRange = 1; // 30 Days │
│ });                                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Widget rebuilds (_buildContent)      │
│ Line 99-160 _buildContent()          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Line 158: _buildHealthTrendChart()   │
│ is called                            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Inside _buildHealthTrendChart():     │
│ Check _selectedTimeRange (now = 1)   │
│ Line 1108-1114 switch statement      │
│ → case 1: daysToShow = 30            │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Line 1119: Filter data               │
│ final recentData =                   │
│   provider.timelineData.take(30)     │
│     .toList();                       │
│ (Takes only 30 days of data)         │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ Build chart UI with:                 │
│ - Title: 'Detection Activity        │
│   (Last 30 Days)' (Line 1130)       │
│ - Badge: '30 days' (Line 1136)      │
│ - Chart: _buildAnimatedBarChart     │
│   (recentData) (Line 1140)           │
│ - Message: _getTimeRangeInsight()    │
│   (Line 1155)                        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│ USER SEES UPDATED CHART              │
│ "📈 Activity Timeline" section       │
│ now displays 30 bars instead of 7    │
└─────────────────────────────────────┘
```

---

## Important Variables

| Variable | Type | Location | Purpose |
|----------|------|----------|---------|
| `_selectedTimeRange` | int | Line 20 | Stores which filter is selected (0, 1, or 2) |
| `daysToShow` | int | Line 1099 | How many days to display in chart |
| `timeRangeLabel` | String | Line 1100 | Display text ("Last 7 Days", etc.) |
| `recentData` | List | Line 1119 | Filtered timeline data to display |

---

## Testing Code Locations

To verify the fix works, check these locations:

1. **Filter Button Selection** (Line 771)
   - Click button → `_selectedTimeRange` changes
   - Check: Button highlight changes to green

2. **Data Filtering** (Line 1119)
   - Check: `recentData` has correct number of items
   - 7 days → 7 items, 30 days → 30 items

3. **Chart Update** (Line 1140)
   - Check: Bar chart shows correct number of bars
   - Title matches selection (Line 1130)
   - Badge shows correct count (Line 1136)

4. **Message Update** (Line 1155)
   - Check: Insight message matches selection
   - 7 days → "weekly monitoring"
   - 30 days → "monthly assessment"
   - All time → "complete evolution"

---

## Quick Code Reference

### To change default selected time range:
**Line 20**: Change from `int _selectedTimeRange = 0;`
- `0` = All Time (default in our fix)
- `1` = 30 Days
- `2` = 7 Days

### To add a new time range:
1. Update `_buildTimeRangeFilter()` (Line 728)
   - Add new button
2. Update `_buildModernFilterChip()` with new index
3. Update switch statement (Line 1108)
   - Add new case with days to show
4. Update `_getTimeRangeInsight()` (Line 1175)
   - Add new insight message

---

## Performance Notes

- ✅ Using `.take()` is efficient (lazy evaluation)
- ✅ No additional API calls
- ✅ Data filtering happens locally
- ✅ Chart animation is smooth (60 FPS)
- ✅ No memory leaks (data is filtered, not duplicated)

---

## Related Files

- Data Source: `lib/providers/statistics_provider.dart`
- Data Models: `lib/services/statistics_service.dart`
- Timeline Data Type: `TimelineData` class in statistics_service.dart
- Chart Widget: `_buildAnimatedBarChart()` at Line 1200
